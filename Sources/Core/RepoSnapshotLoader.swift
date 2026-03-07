import Foundation
import SharedModels

public struct RepoSnapshotLoader: Sendable {
    private let fileSystem: FileSysteming
    private let dotfileAllowlist: DotfileAllowlist

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        dotfileAllowlist: DotfileAllowlist = DotfileAllowlist()
    ) {
        self.fileSystem = fileSystem
        self.dotfileAllowlist = dotfileAllowlist
    }

    public func load(from workspace: ConnectedWorkspace) throws -> RepoSnapshot {
        let root = URL(fileURLWithPath: workspace.rootPath)
        guard fileSystem.fileExists(at: root) else {
            throw MoverError.invalidWorkspace("Workspace does not exist at \(workspace.rootPath)")
        }

        var items: [WorkspaceItem] = []

        if fileSystem.fileExists(at: root.appendingPathComponent("Brewfile")) {
            let brewfileURL = root.appendingPathComponent("Brewfile")
            let brewfileItems = try parseBrewfile(at: brewfileURL)
            items.append(contentsOf: brewfileItems)
        }

        if fileSystem.fileExists(at: root.appendingPathComponent("mise.toml")) {
            items.append(contentsOf: try parseMiseTools(at: root.appendingPathComponent("mise.toml")))
        }

        if fileSystem.fileExists(at: root.appendingPathComponent(".tool-versions")) {
            items.append(contentsOf: try parseToolVersions(at: root.appendingPathComponent(".tool-versions")))
        }

        items.append(contentsOf: loadVSCodeFiles(at: root))
        items.append(contentsOf: loadChezmoiDotfiles(at: root, workspace: workspace))
        items.append(contentsOf: loadAllowlistedDotfiles(at: root))

        return RepoSnapshot(
            capturedAt: Date(),
            items: items
        )
    }

    private func parseBrewfile(at url: URL) throws -> [WorkspaceItem] {
        let data = try fileSystem.readData(at: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw MoverError.ioFailure("Unable to decode Brewfile at \(url.path)")
        }

        return contents
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
                    return nil
                }

                if let name = parseQuotedValue(prefix: "brew", from: trimmed) {
                    return WorkspaceItem(
                        category: .homebrew,
                        identifier: name,
                        value: .string("brew"),
                        details: ["entryType": .string("brew")]
                    )
                }

                if let name = parseQuotedValue(prefix: "cask", from: trimmed) {
                    return WorkspaceItem(
                        category: .homebrew,
                        identifier: name,
                        value: .string("cask"),
                        details: ["entryType": .string("cask")]
                    )
                }

                if let name = parseQuotedValue(prefix: "tap", from: trimmed) {
                    return WorkspaceItem(
                        category: .homebrew,
                        identifier: name,
                        value: .string("tap"),
                        details: ["entryType": .string("tap")]
                    )
                }

                return nil
            }
    }

    private func parseMiseTools(at url: URL) throws -> [WorkspaceItem] {
        let data = try fileSystem.readData(at: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw MoverError.ioFailure("Unable to decode mise.toml at \(url.path)")
        }

        var items: [WorkspaceItem] = []
        var inToolsSection = false

        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else {
                continue
            }

            if line == "[tools]" {
                inToolsSection = true
                continue
            }

            if line.hasPrefix("[") {
                inToolsSection = false
                continue
            }

            guard inToolsSection, let separator = line.firstIndex(of: "=") else {
                continue
            }

            let tool = line[..<separator].trimmingCharacters(in: .whitespacesAndNewlines)
            let version = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            guard !tool.isEmpty, !version.isEmpty else {
                continue
            }

            items.append(
                WorkspaceItem(
                    category: .toolVersions,
                    identifier: tool,
                    value: .string(version),
                    details: ["source": .string("mise.toml")]
                )
            )
        }

        return items
    }

    private func parseToolVersions(at url: URL) throws -> [WorkspaceItem] {
        let data = try fileSystem.readData(at: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw MoverError.ioFailure("Unable to decode .tool-versions at \(url.path)")
        }

        return contents
            .split(whereSeparator: \.isNewline)
            .compactMap { rawLine in
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty, !line.hasPrefix("#") else {
                    return nil
                }

                let parts = line.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
                guard parts.count == 2 else {
                    return nil
                }

                return WorkspaceItem(
                    category: .toolVersions,
                    identifier: parts[0],
                    value: .string(parts[1]),
                    details: ["source": .string(".tool-versions")]
                )
            }
    }

    private func parseQuotedValue(prefix: String, from line: String) -> String? {
        guard line.hasPrefix(prefix) else {
            return nil
        }

        let segments = line.split(separator: "\"")
        guard segments.count >= 2 else {
            return nil
        }
        return String(segments[1])
    }

    private func loadVSCodeFiles(at root: URL) -> [WorkspaceItem] {
        var items: [WorkspaceItem] = []

        for directory in [".vscode", "vscode"] {
            let baseURL = root.appendingPathComponent(directory)

            let settingsURL = baseURL.appendingPathComponent("settings.json")
            if fileSystem.fileExists(at: settingsURL) {
                items.append(
                    WorkspaceItem(
                        category: .vscode,
                        identifier: "settings.json",
                        value: .string("settings"),
                        details: ["relativePath": .string("\(directory)/settings.json")]
                    )
                )
            }

            let keybindingsURL = baseURL.appendingPathComponent("keybindings.json")
            if fileSystem.fileExists(at: keybindingsURL) {
                items.append(
                    WorkspaceItem(
                        category: .vscode,
                        identifier: "keybindings.json",
                        value: .string("keybindings"),
                        details: ["relativePath": .string("\(directory)/keybindings.json")]
                    )
                )
            }

            let snippetsURL = baseURL.appendingPathComponent("snippets")
            guard fileSystem.fileExists(at: snippetsURL),
                  let snippetFiles = try? fileSystem.listDirectory(at: snippetsURL)
            else {
                continue
            }

            for snippetFile in snippetFiles {
                items.append(
                    WorkspaceItem(
                        category: .vscode,
                        identifier: snippetFile.lastPathComponent,
                        value: .string("snippet"),
                        details: ["relativePath": .string("\(directory)/snippets/\(snippetFile.lastPathComponent)")]
                    )
                )
            }
        }

        return items
    }

    private func loadAllowlistedDotfiles(at root: URL) -> [WorkspaceItem] {
        dotfileAllowlist.paths.compactMap { path in
            let relativePath = PathNormalizer.normalizedDotfileRelativePath(path)
            let fileURL = root.appendingPathComponent(relativePath)
            guard fileSystem.fileExists(at: fileURL) else {
                return nil
            }

            return WorkspaceItem(
                category: .dotfiles,
                identifier: path,
                value: .string(relativePath),
                details: ["relativePath": .string(relativePath)]
            )
        }
    }

    private func loadChezmoiDotfiles(at root: URL, workspace: ConnectedWorkspace) -> [WorkspaceItem] {
        guard workspace.detectedTools.contains(.chezmoi)
            || fileSystem.fileExists(at: root.appendingPathComponent(".chezmoiroot"))
            || fileSystem.fileExists(at: root.appendingPathComponent(".chezmoi.toml"))
        else {
            return []
        }

        return dotfileAllowlist.paths.compactMap { path in
            let targetRelativePath = PathNormalizer.normalizedDotfileRelativePath(path)
            guard let sourceRelativePath = chezmoiSourceRelativePath(for: targetRelativePath, at: root) else {
                return nil
            }

            return WorkspaceItem(
                category: .dotfiles,
                identifier: path,
                value: .string(targetRelativePath),
                details: ["relativePath": .string(sourceRelativePath)]
            )
        }
    }

    private func chezmoiSourceRelativePath(for targetRelativePath: String, at root: URL) -> String? {
        let standardRelativePath = targetRelativePath
            .split(separator: "/", omittingEmptySubsequences: false)
            .enumerated()
            .map { index, component in
                let name = String(component)
                guard name.hasPrefix(".") else {
                    return name
                }

                let transformed = "dot_" + name.dropFirst()
                if index == 0 {
                    return String(transformed)
                }
                return String(transformed)
            }
            .joined(separator: "/")

        let candidates = [
            standardRelativePath,
            "private_" + standardRelativePath
        ]

        return candidates.first { candidate in
            fileSystem.fileExists(at: root.appendingPathComponent(candidate))
        }
    }
}
