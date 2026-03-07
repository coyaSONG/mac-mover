import Foundation
import SharedModels
import Core

public struct WorkspacePromoteResult: Sendable {
    public var stagingDirectoryURL: URL
    public var stagedFiles: [URL]
    public var report: OperationReport

    public init(stagingDirectoryURL: URL, stagedFiles: [URL], report: OperationReport) {
        self.stagingDirectoryURL = stagingDirectoryURL
        self.stagedFiles = stagedFiles
        self.report = report
    }
}

public struct WorkspacePromoteCoordinator {
    private let fileSystem: FileSysteming
    private let manualTaskEngine: ManualTaskEngine

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        manualTaskEngine: ManualTaskEngine = ManualTaskEngine()
    ) {
        self.fileSystem = fileSystem
        self.manualTaskEngine = manualTaskEngine
    }

    public func promote(
        workspace: ConnectedWorkspace,
        environmentSnapshot: EnvironmentSnapshot,
        selections: [DriftItem],
        homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path,
        stagingRoot: URL
    ) throws -> WorkspacePromoteResult {
        try fileSystem.createDirectory(at: stagingRoot)

        var successes: [StepResult] = []
        var failures: [StepResult] = []
        var skipped: [StepResult] = []
        var manualTasks: [ManualTask] = []
        var stagedFiles: [URL] = []

        for selection in selections {
            guard selection.suggestedResolutions.contains(.promote) else {
                continue
            }

            guard selection.category == .dotfiles else {
                skipped.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: "category not yet supported by workspace promote"
                    )
                )
                manualTasks.append(manualTaskEngine.taskForUnsupportedFile(selection.identifier))
                continue
            }

            if SecretPolicy.shouldExclude(path: selection.identifier) {
                skipped.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: "secret policy requires manual transfer"
                    )
                )
                manualTasks.append(manualTaskEngine.taskForExcludedSecret(selection.identifier))
                continue
            }

            guard environmentSnapshot.items.contains(where: { $0.category == selection.category && $0.identifier == selection.identifier }) else {
                skipped.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: "missing local metadata for selected item"
                    )
                )
                continue
            }

            let sourceURL = URL(fileURLWithPath: PathNormalizer.expandTilde(selection.identifier, homeDirectory: homeDirectory))
            let relativePath = PathNormalizer.normalizedDotfileRelativePath(selection.identifier, homeDirectory: homeDirectory)
            let destinationURL = stagingRoot.appendingPathComponent(relativePath)

            do {
                try fileSystem.copyItem(at: sourceURL, to: destinationURL)
                stagedFiles.append(destinationURL)
                successes.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .success,
                        detail: "staged candidate at \(destinationURL.path)"
                    )
                )
            } catch {
                failures.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .failed,
                        detail: error.localizedDescription
                    )
                )
            }
        }

        return WorkspacePromoteResult(
            stagingDirectoryURL: stagingRoot,
            stagedFiles: stagedFiles,
            report: OperationReport(
                title: "Workspace Promote Summary",
                generatedAt: Date(),
                successes: successes,
                failures: failures,
                skipped: skipped,
                warnings: [],
                manualTasks: manualTasks
            )
        )
    }
}
