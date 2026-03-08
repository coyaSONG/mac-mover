import Foundation
import Localization
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
    private let locale: Locale?

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        manualTaskEngine: ManualTaskEngine = ManualTaskEngine(),
        locale: Locale? = nil
    ) {
        self.fileSystem = fileSystem
        self.manualTaskEngine = manualTaskEngine.locale == locale ? manualTaskEngine : ManualTaskEngine(locale: locale)
        self.locale = locale
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
        let isChezmoiWorkspace = workspace.detectedTools.contains(.chezmoi)

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
                        detail: L10n.string(.workspacePromoteUnsupportedCategory, locale: locale)
                    )
                )
                manualTasks.append(manualTaskEngine.taskForUnsupportedFile(selection.identifier))
                continue
            }

            let isSecretLikePath = SecretPolicy.shouldExclude(path: selection.identifier)

            if isSecretLikePath {
                skipped.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .skipped,
                        detail: L10n.string(.workspacePromoteSecretManualTransfer, locale: locale)
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
                        detail: L10n.string(.workspacePromoteMissingLocalMetadata, locale: locale)
                    )
                )
                continue
            }

            let sourceURL = URL(fileURLWithPath: PathNormalizer.expandTilde(selection.identifier, homeDirectory: homeDirectory))
            let relativePath = stagedRelativePath(
                for: selection.identifier,
                homeDirectory: homeDirectory,
                useChezmoiNaming: isChezmoiWorkspace
            )
            let destinationURL = stagingRoot.appendingPathComponent(relativePath)

            do {
                try fileSystem.copyItem(at: sourceURL, to: destinationURL)
                stagedFiles.append(destinationURL)
                successes.append(
                    StepResult(
                        id: "workspace.promote.\(selection.identifier)",
                        title: selection.identifier,
                        status: .success,
                        detail: L10n.format(.workspacePromoteStagedCandidate, locale: locale, destinationURL.path)
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
                title: L10n.string(.reportWorkspacePromoteSummaryTitle, locale: locale),
                generatedAt: Date(),
                successes: successes,
                failures: failures,
                skipped: skipped,
                warnings: [],
                manualTasks: manualTasks
            )
        )
    }

    private func stagedRelativePath(
        for path: String,
        homeDirectory: String,
        useChezmoiNaming: Bool
    ) -> String {
        let relativePath = PathNormalizer.normalizedDotfileRelativePath(path, homeDirectory: homeDirectory)
        guard useChezmoiNaming else {
            return relativePath
        }

        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard let first = components.first else {
            return relativePath
        }

        let transformedFirst: String
        if first.hasPrefix(".") {
            transformedFirst = "dot_" + String(first.dropFirst())
        } else {
            transformedFirst = first
        }

        return ([transformedFirst] + components.dropFirst()).joined(separator: "/")
    }
}
