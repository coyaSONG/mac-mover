import CryptoKit
import Foundation
import Testing
@testable import SharedModels
@testable import Core

struct DriftEngineTests {
    @Test
    func environmentScannerCollectsHomebrewAndDotfiles() throws {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "list", "--formula"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "list", "--formula"], exitCode: 0, stdout: "git\nwget\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "list", "--cask"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "list", "--cask"], exitCode: 0, stdout: "visual-studio-code\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "tap"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "tap"], exitCode: 0, stdout: "homebrew/cask\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "git"], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--list"], result: .success(.init(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--list"], exitCode: 0, stdout: "user.name=Test User\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["which", "code"], code: 1, stderr: "missing"))),
        ])
        let fileSystem = InMemoryFileSystem(
            files: [
                "/Users/test/.zshrc": Data("export PATH=/opt/homebrew/bin:$PATH\n".utf8)
            ],
            directories: ["/Users/test"]
        )

        let snapshot = EnvironmentScanner(
            runner: runner,
            fileSystem: fileSystem,
            homeDirectory: "/Users/test"
        ).scan()

        #expect(snapshot.items.contains(where: { $0.category == .homebrew && $0.identifier == "git" }))
        #expect(snapshot.items.contains(where: { $0.category == .dotfiles && $0.identifier == "~/.zshrc" }))
        #expect(snapshot.items.contains(where: { $0.category == .gitGlobal && $0.identifier == "user.name" }))
    }

    @Test
    func classifiesMissingExtraAndModifiedItems() {
        let repo = RepoSnapshot(items: [
            WorkspaceItem(category: .homebrew, identifier: "wget", value: .string("brew")),
            WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("repo"))
        ])
        let local = EnvironmentSnapshot(items: [
            WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("local")),
            WorkspaceItem(category: .homebrew, identifier: "git", value: .string("brew"))
        ])

        let drift = DriftEngine().compare(repo: repo, local: local)

        #expect(drift.contains(where: { $0.identifier == "wget" && $0.status == .missing }))
        #expect(drift.contains(where: { $0.identifier == "~/.zshrc" && $0.status == .modified }))
        #expect(drift.contains(where: { $0.identifier == "git" && $0.status == .extra }))
    }

    @Test
    func ignoresNonSemanticDetailDifferencesForMatchingItems() {
        let repo = RepoSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                value: .string(".zshrc"),
                details: ["relativePath": .string(".zshrc")]
            )
        ])
        let local = EnvironmentSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                value: .string(".zshrc"),
                details: ["path": .string("~/.zshrc")]
            )
        ])

        let drift = DriftEngine().compare(repo: repo, local: local)

        #expect(!drift.contains(where: { $0.identifier == "~/.zshrc" && $0.status == .modified }))
    }

    @Test
    func toleratesDuplicateCategoryIdentifierPairs() {
        let repo = RepoSnapshot(items: [
            WorkspaceItem(
                category: .vscode,
                identifier: "settings.json",
                value: .string("settings"),
                details: ["relativePath": .string(".vscode/settings.json")]
            ),
            WorkspaceItem(
                category: .vscode,
                identifier: "settings.json",
                value: .string("settings"),
                details: ["relativePath": .string("vscode/settings.json")]
            )
        ])
        let local = EnvironmentSnapshot(items: [])

        let drift = DriftEngine().compare(repo: repo, local: local)

        #expect(drift.count == 1)
        #expect(drift.first?.identifier == "settings.json")
        #expect(drift.first?.status == .missing)
    }

    @Test
    func classifiesModifiedDotfilesAndVSCodeFilesByContentHash() throws {
        let root = URL(fileURLWithPath: "/tmp/dev-env")
        let homeDirectory = "/Users/test"
        let userDirectory = "\(homeDirectory)/Library/Application Support/Code/User"
        let fileSystem = InMemoryFileSystem(
            files: [
                root.appendingPathComponent(".zshrc").path: Data("export PATH=/repo/bin:$PATH\n".utf8),
                root.appendingPathComponent(".vscode/settings.json").path: Data("{\"editor.fontSize\":14}\n".utf8),
                "\(homeDirectory)/.zshrc": Data("export PATH=/local/bin:$PATH\n".utf8),
                "\(userDirectory)/settings.json": Data("{\"editor.fontSize\":16}\n".utf8)
            ],
            directories: [
                root.path,
                root.appendingPathComponent(".vscode").path,
                homeDirectory,
                userDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: root.path, detectedTools: [.plainDotfiles, .vscode])

        let repo = try RepoSnapshotLoader(fileSystem: fileSystem).load(from: workspace)
        let local = EnvironmentScanner(
            runner: MockCommandRunner(),
            fileSystem: fileSystem,
            homeDirectory: homeDirectory
        ).scan()

        let drift = DriftEngine().compare(repo: repo, local: local)

        #expect(drift.contains(where: { $0.category == .dotfiles && $0.identifier == "~/.zshrc" && $0.status == .modified }))
        #expect(drift.contains(where: { $0.category == .vscode && $0.identifier == "settings.json" && $0.status == .modified }))
    }

    @Test
    func environmentScannerCollectsToolVersionsAndVSCodeSnippets() {
        let homeDirectory = "/Users/test"
        let snippetsDirectory = "\(homeDirectory)/Library/Application Support/Code/User/snippets"
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/usr/bin/env", arguments: ["which", "mise"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "mise"], exitCode: 0, stdout: "/opt/homebrew/bin/mise\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["mise", "current"], result: .success(.init(executable: "/usr/bin/env", arguments: ["mise", "current"], exitCode: 0, stdout: "node 22.1.0\npython 3.12.1\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "asdf"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["which", "asdf"], code: 1, stderr: "missing"))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["which", "code"], code: 1, stderr: "missing")))
        ])
        let snippetContents = "{\"log\":{}}\n"
        let fileSystem = InMemoryFileSystem(
            files: [
                "\(snippetsDirectory)/javascript.json": Data(snippetContents.utf8)
            ],
            directories: [
                homeDirectory,
                "\(homeDirectory)/Library",
                "\(homeDirectory)/Library/Application Support",
                "\(homeDirectory)/Library/Application Support/Code",
                "\(homeDirectory)/Library/Application Support/Code/User",
                snippetsDirectory
            ]
        )

        let snapshot = EnvironmentScanner(
            runner: runner,
            fileSystem: fileSystem,
            homeDirectory: homeDirectory
        ).scan()

        #expect(snapshot.items.contains(where: { $0.category == .toolVersions && $0.identifier == "node" && $0.value == .string("22.1.0") }))
        #expect(snapshot.items.contains(where: { $0.category == .toolVersions && $0.identifier == "python" && $0.value == .string("3.12.1") }))

        let snippet = snapshot.items.first(where: { $0.category == .vscode && $0.identifier == "javascript.json" })
        #expect(snippet?.value == .string(sha256Hex(snippetContents)))
        #expect(snippet?.details["path"] == .string("~/Library/Application Support/Code/User/snippets/javascript.json"))
    }
}

private func sha256Hex(_ string: String) -> String {
    let digest = SHA256.hash(data: Data(string.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
}
