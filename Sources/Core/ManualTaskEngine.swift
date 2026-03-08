import Foundation
import Localization
import SharedModels

public struct ManualTaskEngine {
    public let locale: Locale?

    public init(locale: Locale? = nil) {
        self.locale = locale
    }

    public func taskForMissingBrew() -> ManualTask {
        ManualTask(
            id: "manual.install.homebrew",
            title: L10n.string(.manualTaskMissingBrewTitle, locale: locale),
            reason: L10n.string(.manualTaskMissingBrewReason, locale: locale),
            action: L10n.string(.manualTaskMissingBrewAction, locale: locale),
            blocking: true
        )
    }

    public func taskForMissingCodeCLI() -> ManualTask {
        ManualTask(
            id: "manual.enable.code-cli",
            title: L10n.string(.manualTaskMissingCodeCLITitle, locale: locale),
            reason: L10n.string(.manualTaskMissingCodeCLIReason, locale: locale),
            action: L10n.string(.manualTaskMissingCodeCLIAction, locale: locale),
            blocking: false
        )
    }

    public func taskForArchitectureMismatch(source: MachineArchitecture, target: MachineArchitecture) -> ManualTask {
        ManualTask(
            id: "manual.arch.mismatch",
            title: L10n.string(.manualTaskArchitectureMismatchTitle, locale: locale),
            reason: L10n.format(.manualTaskArchitectureMismatchReason, locale: locale, source.rawValue, target.rawValue),
            action: L10n.string(.manualTaskArchitectureMismatchAction, locale: locale),
            blocking: false
        )
    }

    public func taskForExcludedSecret(_ path: String) -> ManualTask {
        ManualTask(
            id: "manual.secret.\(path.replacingOccurrences(of: "/", with: "_"))",
            title: L10n.string(.manualTaskExcludedSecretTitle, locale: locale),
            reason: L10n.format(.manualTaskExcludedSecretReason, locale: locale, path),
            action: L10n.string(.manualTaskExcludedSecretAction, locale: locale),
            blocking: false
        )
    }

    public func taskForUnsupportedFile(_ path: String) -> ManualTask {
        ManualTask(
            id: "manual.unsupported.\(path.replacingOccurrences(of: "/", with: "_"))",
            title: L10n.string(.manualTaskUnsupportedFileTitle, locale: locale),
            reason: L10n.format(.manualTaskUnsupportedFileReason, locale: locale, path),
            action: L10n.string(.manualTaskUnsupportedFileAction, locale: locale),
            blocking: false
        )
    }

    public func taskForOverwriteConfirmation(_ path: String) -> ManualTask {
        ManualTask(
            id: "manual.overwrite.\(path.replacingOccurrences(of: "/", with: "_"))",
            title: L10n.string(.manualTaskOverwriteConfirmationTitle, locale: locale),
            reason: L10n.format(.manualTaskOverwriteConfirmationReason, locale: locale, path),
            action: L10n.string(.manualTaskOverwriteConfirmationAction, locale: locale),
            blocking: false
        )
    }
}
