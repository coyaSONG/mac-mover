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
}
