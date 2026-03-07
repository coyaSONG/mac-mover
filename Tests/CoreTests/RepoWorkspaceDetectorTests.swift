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
}
