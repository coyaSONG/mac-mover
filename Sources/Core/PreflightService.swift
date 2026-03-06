import Foundation
import SharedModels

public enum PreflightMode: Sendable {
    case export(destination: URL)
    case `import`(bundle: URL)
}

public struct PreflightService {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let machineCollector: MachineInfoCollector

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        fileSystem: FileSysteming = LocalFileSystem(),
        machineCollector: MachineInfoCollector? = nil
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.machineCollector = machineCollector ?? MachineInfoCollector(runner: runner)
    }

    public func run(mode: PreflightMode) -> PreflightResult {
        let machine = machineCollector.collect()
        var checks: [PreflightCheck] = []

        checks.append(
            PreflightCheck(
                id: "preflight.macos",
                title: "macOS version",
                passed: !machine.macosVersion.isEmpty,
                detail: machine.macosVersion,
                blocking: true
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.architecture",
                title: "CPU architecture",
                passed: true,
                detail: machine.architecture.rawValue,
                blocking: false
            )
        )

        let homeExists = fileSystem.fileExists(at: URL(fileURLWithPath: machine.homeDirectory))
        checks.append(
            PreflightCheck(
                id: "preflight.home",
                title: "Home directory",
                passed: homeExists,
                detail: machine.homeDirectory,
                blocking: true
            )
        )

        let brewAvailable = runner.commandExists("brew")
        checks.append(
            PreflightCheck(
                id: "preflight.brew",
                title: "Homebrew installed",
                passed: brewAvailable,
                detail: brewAvailable ? machine.homebrewPrefix : "brew command not found",
                blocking: false
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.git",
                title: "git installed",
                passed: runner.commandExists("git"),
                detail: runner.commandExists("git") ? "git available" : "git command not found",
                blocking: false
            )
        )

        let vscodeApp = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
        checks.append(
            PreflightCheck(
                id: "preflight.vscode",
                title: "VS Code installed",
                passed: fileSystem.fileExists(at: vscodeApp),
                detail: fileSystem.fileExists(at: vscodeApp) ? vscodeApp.path : "VS Code.app not found",
                blocking: false
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.code-cli",
                title: "code CLI available",
                passed: runner.commandExists("code"),
                detail: runner.commandExists("code") ? "code CLI available" : "code command not found",
                blocking: false
            )
        )

        switch mode {
        case .export(let destination):
            checks.append(checkWritePermission(for: destination))
        case .import(let bundle):
            checks.append(
                PreflightCheck(
                    id: "preflight.bundle.exists",
                    title: "Import bundle exists",
                    passed: fileSystem.fileExists(at: bundle),
                    detail: bundle.path,
                    blocking: true
                )
            )
            checks.append(checkWritePermission(for: URL(fileURLWithPath: machine.homeDirectory)))
        }

        return PreflightResult(machine: machine, checks: checks)
    }

    private func checkWritePermission(for url: URL) -> PreflightCheck {
        let testDir = url.appendingPathComponent(".mac-dev-env-mover-preflight")
        do {
            try fileSystem.createDirectory(at: testDir)
            try fileSystem.removeItem(at: testDir)
            return PreflightCheck(
                id: "preflight.write",
                title: "Target path writable",
                passed: true,
                detail: url.path,
                blocking: true
            )
        } catch {
            return PreflightCheck(
                id: "preflight.write",
                title: "Target path writable",
                passed: false,
                detail: "\(url.path): \(error.localizedDescription)",
                blocking: true
            )
        }
    }
}
