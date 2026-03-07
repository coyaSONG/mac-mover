import Foundation
import SharedModels

public struct RepoWorkspaceDetector: Sendable {
    private let fileSystem: FileSysteming
    private let dotfileAllowlist: DotfileAllowlist

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        dotfileAllowlist: DotfileAllowlist = DotfileAllowlist()
    ) {
        self.fileSystem = fileSystem
        self.dotfileAllowlist = dotfileAllowlist
    }

    public func detect(at root: URL) throws -> ConnectedWorkspace {
        guard fileSystem.fileExists(at: root) else {
            throw MoverError.invalidWorkspace("Workspace does not exist at \(root.path)")
        }

        var tools: [WorkspaceTool] = []

        if fileSystem.fileExists(at: root.appendingPathComponent("Brewfile")) {
            tools.append(.homebrew)
        }

        if fileSystem.fileExists(at: root.appendingPathComponent(".chezmoiroot"))
            || fileSystem.fileExists(at: root.appendingPathComponent(".chezmoi.toml")) {
            tools.append(.chezmoi)
        }

        if fileSystem.fileExists(at: root.appendingPathComponent("mise.toml")) {
            tools.append(.mise)
        }

        if fileSystem.fileExists(at: root.appendingPathComponent(".tool-versions")) {
            tools.append(.asdf)
        }

        if fileSystem.fileExists(at: root.appendingPathComponent(".vscode/settings.json"))
            || fileSystem.fileExists(at: root.appendingPathComponent("vscode/settings.json")) {
            tools.append(.vscode)
        }

        if containsAllowlistedDotfiles(at: root) {
            tools.append(.plainDotfiles)
        }

        return ConnectedWorkspace(
            rootPath: root.path,
            detectedTools: tools
        )
    }

    private func containsAllowlistedDotfiles(at root: URL) -> Bool {
        dotfileAllowlist.paths.contains { path in
            let relativePath = PathNormalizer.normalizedDotfileRelativePath(path)
            return fileSystem.fileExists(at: root.appendingPathComponent(relativePath))
        }
    }
}
