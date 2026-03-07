import Foundation
import SharedModels

public struct EnvironmentScanner: Sendable {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let dotfileAllowlist: DotfileAllowlist
    private let homeDirectory: String

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        fileSystem: FileSysteming = LocalFileSystem(),
        dotfileAllowlist: DotfileAllowlist = DotfileAllowlist(),
        homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.dotfileAllowlist = dotfileAllowlist
        self.homeDirectory = homeDirectory
    }

    public func scan() -> EnvironmentSnapshot {
        var items: [WorkspaceItem] = []
        items.append(contentsOf: scanHomebrew())
        items.append(contentsOf: scanDotfiles())
        items.append(contentsOf: scanGitGlobal())
        items.append(contentsOf: scanVSCode())

        return EnvironmentSnapshot(
            capturedAt: Date(),
            items: items
        )
    }

    private func scanHomebrew() -> [WorkspaceItem] {
        guard runner.commandExists("brew") else {
            return []
        }

        var items: [WorkspaceItem] = []
        items.append(contentsOf: scanHomebrewList(arguments: ["brew", "list", "--formula"], entryType: "brew"))
        items.append(contentsOf: scanHomebrewList(arguments: ["brew", "list", "--cask"], entryType: "cask"))
        items.append(contentsOf: scanHomebrewList(arguments: ["brew", "tap"], entryType: "tap"))
        return items
    }

    private func scanHomebrewList(arguments: [String], entryType: String) -> [WorkspaceItem] {
        guard let output = try? runner.run(executable: "/usr/bin/env", arguments: arguments).stdout else {
            return []
        }

        return output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { name in
                WorkspaceItem(
                    category: .homebrew,
                    identifier: name,
                    value: .string(entryType),
                    details: ["entryType": .string(entryType)]
                )
            }
    }

    private func scanDotfiles() -> [WorkspaceItem] {
        dotfileAllowlist.paths.compactMap { path in
            let absolutePath = PathNormalizer.expandTilde(path, homeDirectory: homeDirectory)
            let url = URL(fileURLWithPath: absolutePath)
            guard fileSystem.fileExists(at: url) else {
                return nil
            }

            return WorkspaceItem(
                category: .dotfiles,
                identifier: path,
                value: .string(PathNormalizer.normalizedDotfileRelativePath(path, homeDirectory: homeDirectory)),
                details: ["path": .string(path)]
            )
        }
    }

    private func scanGitGlobal() -> [WorkspaceItem] {
        guard runner.commandExists("git"),
              let output = try? runner.run(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--list"]).stdout
        else {
            return []
        }

        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> WorkspaceItem? in
                let text = String(line)
                guard let separator = text.firstIndex(of: "=") else {
                    return nil
                }

                let key = String(text[..<separator])
                let value = String(text[text.index(after: separator)...])
                return WorkspaceItem(
                    category: .gitGlobal,
                    identifier: key,
                    value: .string(value),
                    details: [:]
                )
            }
    }

    private func scanVSCode() -> [WorkspaceItem] {
        var items: [WorkspaceItem] = []
        let userDirectory = URL(fileURLWithPath: homeDirectory)
            .appendingPathComponent("Library/Application Support/Code/User")

        let settingsURL = userDirectory.appendingPathComponent("settings.json")
        if fileSystem.fileExists(at: settingsURL) {
            items.append(
                WorkspaceItem(
                    category: .vscode,
                    identifier: "settings.json",
                    value: .string("settings"),
                    details: ["path": .string("~/Library/Application Support/Code/User/settings.json")]
                )
            )
        }

        let keybindingsURL = userDirectory.appendingPathComponent("keybindings.json")
        if fileSystem.fileExists(at: keybindingsURL) {
            items.append(
                WorkspaceItem(
                    category: .vscode,
                    identifier: "keybindings.json",
                    value: .string("keybindings"),
                    details: ["path": .string("~/Library/Application Support/Code/User/keybindings.json")]
                )
            )
        }

        guard runner.commandExists("code"),
              let output = try? runner.run(executable: "/usr/bin/env", arguments: ["code", "--list-extensions", "--show-versions"]).stdout
        else {
            return items
        }

        let extensions = output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { line in
                let parts = line.split(separator: "@", maxSplits: 1).map(String.init)
                let identifier = parts[0]
                let version = parts.count > 1 ? parts[1] : "unknown"
                return WorkspaceItem(
                    category: .vscode,
                    identifier: identifier,
                    value: .string(version),
                    details: ["entryType": .string("extension")]
                )
            }

        items.append(contentsOf: extensions)
        return items
    }
}
