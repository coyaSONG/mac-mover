import Foundation
import SharedModels

public struct ManualTaskEngine {
    public init() {}

    public func taskForMissingBrew() -> ManualTask {
        ManualTask(
            id: "manual.install.homebrew",
            title: "Homebrew installation required",
            reason: "Homebrew is not installed on this machine.",
            action: "Install Homebrew from https://brew.sh and rerun import.",
            blocking: true
        )
    }

    public func taskForMissingCodeCLI() -> ManualTask {
        ManualTask(
            id: "manual.enable.code-cli",
            title: "VS Code CLI (code) required",
            reason: "`code` CLI is unavailable, so extension restore cannot run automatically.",
            action: "In VS Code, run: Shell Command: Install code command in PATH.",
            blocking: false
        )
    }

    public func taskForArchitectureMismatch(source: MachineArchitecture, target: MachineArchitecture) -> ManualTask {
        ManualTask(
            id: "manual.arch.mismatch",
            title: "Architecture mismatch",
            reason: "Export machine (\(source.rawValue)) differs from current machine (\(target.rawValue)).",
            action: "If compatibility issues occur, reinstall affected packages manually and check Rosetta if needed.",
            blocking: false
        )
    }

    public func taskForExcludedSecret(_ path: String) -> ManualTask {
        ManualTask(
            id: "manual.secret.\(path.replacingOccurrences(of: "/", with: "_"))",
            title: "Secret item requires manual transfer",
            reason: "Security policy excluded \(path) from automatic transfer.",
            action: "Transfer it manually via a secure channel if needed.",
            blocking: false
        )
    }

    public func taskForUnsupportedFile(_ path: String) -> ManualTask {
        ManualTask(
            id: "manual.unsupported.\(path.replacingOccurrences(of: "/", with: "_"))",
            title: "Unsupported file",
            reason: "Item is outside v1 support scope: \(path)",
            action: "Review and transfer this file manually.",
            blocking: false
        )
    }

    public func taskForOverwriteConfirmation(_ path: String) -> ManualTask {
        ManualTask(
            id: "manual.overwrite.\(path.replacingOccurrences(of: "/", with: "_"))",
            title: "Overwrite backup created",
            reason: "Existing file detected; backup will be created before overwrite: \(path)",
            action: "If needed, restore from the generated .bak file.",
            blocking: false
        )
    }
}
