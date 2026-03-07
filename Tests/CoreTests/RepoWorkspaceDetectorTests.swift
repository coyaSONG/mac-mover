import Foundation
import Testing
@testable import SharedModels
@testable import Core

struct RepoWorkspaceDetectorTests {
    @Test
    func detectsChezmoiAndBrewfileInWorkspace() throws {
        let root = URL(fileURLWithPath: "/tmp/dev-env")
        let fileSystem = InMemoryFileSystem(
            files: [
                root.appendingPathComponent("Brewfile").path: Data(),
                root.appendingPathComponent(".chezmoiroot").path: Data()
            ],
            directories: [root.path]
        )

        let workspace = try RepoWorkspaceDetector(fileSystem: fileSystem).detect(at: root)

        #expect(workspace.detectedTools.contains(.chezmoi))
        #expect(workspace.detectedTools.contains(.homebrew))
        #expect(workspace.rootPath == root.path)
    }

    @Test
    func loadsBrewfileAndAllowlistedDotfilesIntoSnapshot() throws {
        let root = URL(fileURLWithPath: "/tmp/dev-env")
        let fileSystem = InMemoryFileSystem(
            files: [
                root.appendingPathComponent("Brewfile").path: Data("""
                tap "homebrew/cask"
                brew "git"
                cask "visual-studio-code"
                """.utf8),
                root.appendingPathComponent(".zshrc").path: Data("export PATH=/opt/homebrew/bin:$PATH\n".utf8),
                root.appendingPathComponent(".config/starship.toml").path: Data("[character]\n".utf8)
            ],
            directories: [
                root.path,
                root.appendingPathComponent(".config").path
            ]
        )
        let workspace = ConnectedWorkspace(
            rootPath: root.path,
            detectedTools: [.homebrew, .plainDotfiles]
        )

        let snapshot = try RepoSnapshotLoader(fileSystem: fileSystem).load(from: workspace)

        #expect(snapshot.items.contains(where: { $0.category == .homebrew && $0.identifier == "git" }))
        #expect(snapshot.items.contains(where: { $0.category == .homebrew && $0.identifier == "visual-studio-code" }))
        #expect(snapshot.items.contains(where: { $0.category == .dotfiles && $0.identifier == "~/.zshrc" }))
        #expect(snapshot.items.contains(where: { $0.category == .dotfiles && $0.identifier == "~/.config/starship.toml" }))
    }

    @Test
    func loadsMiseAndToolVersionsIntoSnapshot() throws {
        let root = URL(fileURLWithPath: "/tmp/dev-env")
        let fileSystem = InMemoryFileSystem(
            files: [
                root.appendingPathComponent("mise.toml").path: Data("""
                [tools]
                node = "22.1.0"
                python = "3.12"
                """.utf8),
                root.appendingPathComponent(".tool-versions").path: Data("""
                ruby 3.3.1
                terraform 1.10.5
                """.utf8)
            ],
            directories: [root.path]
        )
        let workspace = ConnectedWorkspace(
            rootPath: root.path,
            detectedTools: [.mise, .asdf]
        )

        let snapshot = try RepoSnapshotLoader(fileSystem: fileSystem).load(from: workspace)

        #expect(snapshot.items.contains(where: { $0.category == .toolVersions && $0.identifier == "node" && $0.value == .string("22.1.0") }))
        #expect(snapshot.items.contains(where: { $0.category == .toolVersions && $0.identifier == "python" && $0.value == .string("3.12") }))
        #expect(snapshot.items.contains(where: { $0.category == .toolVersions && $0.identifier == "ruby" && $0.value == .string("3.3.1") }))
        #expect(snapshot.items.contains(where: { $0.category == .toolVersions && $0.identifier == "terraform" && $0.value == .string("1.10.5") }))
    }

    @Test
    func loadsVSCodeRepoFilesFromBothDirectoryConventions() throws {
        let root = URL(fileURLWithPath: "/tmp/dev-env")
        let fileSystem = InMemoryFileSystem(
            files: [
                root.appendingPathComponent(".vscode/settings.json").path: Data("{\"editor.fontSize\": 14}\n".utf8),
                root.appendingPathComponent("vscode/keybindings.json").path: Data("[{\"key\":\"cmd+s\"}]\n".utf8),
                root.appendingPathComponent(".vscode/snippets/javascript.json").path: Data("{\"log\":{}}\n".utf8),
                root.appendingPathComponent("vscode/snippets/python.json").path: Data("{\"print\":{}}\n".utf8)
            ],
            directories: [
                root.path,
                root.appendingPathComponent(".vscode").path,
                root.appendingPathComponent(".vscode/snippets").path,
                root.appendingPathComponent("vscode").path,
                root.appendingPathComponent("vscode/snippets").path
            ]
        )
        let workspace = ConnectedWorkspace(
            rootPath: root.path,
            detectedTools: [.vscode]
        )

        let snapshot = try RepoSnapshotLoader(fileSystem: fileSystem).load(from: workspace)

        #expect(snapshot.items.contains(where: { $0.category == .vscode && $0.identifier == "settings.json" && $0.details["relativePath"] == .string(".vscode/settings.json") }))
        #expect(snapshot.items.contains(where: { $0.category == .vscode && $0.identifier == "keybindings.json" && $0.details["relativePath"] == .string("vscode/keybindings.json") }))
        #expect(snapshot.items.contains(where: { $0.category == .vscode && $0.identifier == "javascript.json" && $0.details["relativePath"] == .string(".vscode/snippets/javascript.json") }))
        #expect(snapshot.items.contains(where: { $0.category == .vscode && $0.identifier == "python.json" && $0.details["relativePath"] == .string("vscode/snippets/python.json") }))
    }

    @Test
    func loadsAllowlistedChezmoiDotfilesIntoSnapshot() throws {
        let root = URL(fileURLWithPath: "/tmp/dev-env")
        let fileSystem = InMemoryFileSystem(
            files: [
                root.appendingPathComponent(".chezmoiroot").path: Data(),
                root.appendingPathComponent("dot_zshrc").path: Data("export PATH=/opt/homebrew/bin:$PATH\n".utf8),
                root.appendingPathComponent("private_dot_zprofile").path: Data("eval \"$(mise activate zsh)\"\n".utf8),
                root.appendingPathComponent("dot_config/starship.toml").path: Data("[character]\n".utf8)
            ],
            directories: [
                root.path,
                root.appendingPathComponent("dot_config").path
            ]
        )
        let workspace = ConnectedWorkspace(
            rootPath: root.path,
            detectedTools: [.chezmoi]
        )

        let snapshot = try RepoSnapshotLoader(fileSystem: fileSystem).load(from: workspace)

        let zshrc = snapshot.items.first(where: { $0.category == .dotfiles && $0.identifier == "~/.zshrc" })
        let zprofile = snapshot.items.first(where: { $0.category == .dotfiles && $0.identifier == "~/.zprofile" })
        let starship = snapshot.items.first(where: { $0.category == .dotfiles && $0.identifier == "~/.config/starship.toml" })

        #expect(zshrc?.value == .string(".zshrc"))
        #expect(zshrc?.details["relativePath"] == .string("dot_zshrc"))
        #expect(zprofile?.value == .string(".zprofile"))
        #expect(zprofile?.details["relativePath"] == .string("private_dot_zprofile"))
        #expect(starship?.value == .string(".config/starship.toml"))
        #expect(starship?.details["relativePath"] == .string("dot_config/starship.toml"))
    }
}
