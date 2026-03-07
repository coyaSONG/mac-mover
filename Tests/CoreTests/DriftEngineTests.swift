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
}
