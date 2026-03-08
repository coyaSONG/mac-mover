import Foundation
import Localization
import SharedModels
import Core

public struct WorkspaceApplyResult: Sendable {
    public var report: OperationReport
    public var backupURLs: [URL]

    public init(report: OperationReport, backupURLs: [URL] = []) {
        self.report = report
        self.backupURLs = backupURLs
    }
}

public struct WorkspaceApplyCoordinator {
    private let fileSystem: FileSysteming
    private let fileRestorer: FileRestorer
    private let manualTaskEngine: ManualTaskEngine
    private let locale: Locale?

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        fileRestorer: FileRestorer? = nil,
        manualTaskEngine: ManualTaskEngine = ManualTaskEngine(),
        locale: Locale? = nil
    ) {
        self.fileSystem = fileSystem
        self.fileRestorer = fileRestorer ?? FileRestorer(fileSystem: fileSystem)
        self.manualTaskEngine = manualTaskEngine.locale == locale ? manualTaskEngine : ManualTaskEngine(locale: locale)
        self.locale = locale
    }

    public func apply(
        workspace: ConnectedWorkspace,
        repoSnapshot: RepoSnapshot,
        selections: [DriftItem],
        homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path,
        timestamp: Date = Date()
    ) throws -> WorkspaceApplyResult {
        var successes: [StepResult] = []
        var failures: [StepResult] = []
        var skipped: [StepResult] = []
        var manualTasks: [ManualTask] = []
        var backupURLs: [URL] = []

        for selection in selections {
            guard selection.suggestedResolutions.contains(.apply) else {
                continue
            }

            guard selection.category == .dotfiles else {
                skipped.append(
                    StepResult(
                        id: "workspace.apply.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: L10n.string(.workspaceApplyUnsupportedCategory, locale: locale)
                    )
                )
                manualTasks.append(manualTaskEngine.taskForUnsupportedFile(selection.identifier))
                continue
            }

            if SecretPolicy.shouldExclude(path: selection.identifier) {
                skipped.append(
                    StepResult(
                        id: "workspace.apply.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: L10n.string(.workspaceApplySecretManualTransfer, locale: locale)
                    )
                )
                manualTasks.append(manualTaskEngine.taskForExcludedSecret(selection.identifier))
                continue
            }

            guard let repoItem = repoSnapshot.items.first(where: { $0.category == selection.category && $0.identifier == selection.identifier }),
                  let relativePath = repoItem.details["relativePath"]?.stringValue else {
                skipped.append(
                    StepResult(
                        id: "workspace.apply.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: L10n.string(.workspaceApplyMissingRepoMetadata, locale: locale)
                    )
                )
                continue
            }

            let sourceURL = URL(fileURLWithPath: workspace.rootPath).appendingPathComponent(relativePath)
            let destinationURL = URL(fileURLWithPath: PathNormalizer.expandTilde(selection.identifier, homeDirectory: homeDirectory))

            do {
                if fileSystem.fileExists(at: destinationURL) {
                    manualTasks.append(manualTaskEngine.taskForOverwriteConfirmation(selection.identifier))
                }

                if let backupURL = try fileRestorer.restoreFile(from: sourceURL, to: destinationURL, timestamp: timestamp) {
                    backupURLs.append(backupURL)
                }

                successes.append(
                    StepResult(
                        id: "workspace.apply.\(selection.identifier)",
                        title: selection.identifier,
                        status: .success,
                        detail: L10n.string(.workspaceApplyAppliedFromWorkspace, locale: locale)
                    )
                )
            } catch {
                failures.append(
                    StepResult(
                        id: "workspace.apply.\(selection.identifier)",
                        title: selection.identifier,
                        status: .failed,
                        detail: error.localizedDescription
                    )
                )
            }
        }

        return WorkspaceApplyResult(
            report: OperationReport(
                title: L10n.string(.reportWorkspaceApplySummaryTitle, locale: locale),
                generatedAt: timestamp,
                successes: successes,
                failures: failures,
                skipped: skipped,
                warnings: [],
                manualTasks: manualTasks
            ),
            backupURLs: backupURLs
        )
    }
}
