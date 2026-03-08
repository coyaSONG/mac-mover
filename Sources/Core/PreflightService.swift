import Foundation
import Localization
import SharedModels

public enum PreflightMode: Sendable {
    case export(destination: URL)
    case `import`(bundle: URL)
}

public struct PreflightService {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let machineCollector: MachineInfoCollector
    private let locale: Locale?

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        fileSystem: FileSysteming = LocalFileSystem(),
        machineCollector: MachineInfoCollector? = nil,
        locale: Locale? = nil
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.machineCollector = machineCollector ?? MachineInfoCollector(runner: runner)
        self.locale = locale
    }

    public func run(mode: PreflightMode) -> PreflightResult {
        let machine = machineCollector.collect()
        var checks: [PreflightCheck] = []
        let brewAvailable = runner.commandExists("brew")
        let resolvedBrewPrefix = brewAvailable ? readBrewPrefix() : nil
        let gitAvailable = runner.commandExists("git")
        let vscodeApp = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
        let vscodeInstalled = fileSystem.fileExists(at: vscodeApp)
        let codeCLIAvailable = runner.commandExists("code")

        checks.append(
            PreflightCheck(
                id: "preflight.macos",
                title: L10n.string(.preflightMacOSTitle, locale: locale),
                passed: !machine.macosVersion.isEmpty,
                detail: machine.macosVersion,
                blocking: true
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.architecture",
                title: L10n.string(.preflightArchitectureTitle, locale: locale),
                passed: true,
                detail: machine.architecture.rawValue,
                blocking: false
            )
        )

        let homeExists = fileSystem.fileExists(at: URL(fileURLWithPath: machine.homeDirectory))
        checks.append(
            PreflightCheck(
                id: "preflight.home",
                title: L10n.string(.preflightHomeTitle, locale: locale),
                passed: homeExists,
                detail: machine.homeDirectory,
                blocking: true
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.brew",
                title: L10n.string(.preflightBrewTitle, locale: locale),
                passed: brewAvailable,
                detail: brewAvailable ? (resolvedBrewPrefix ?? machine.homebrewPrefix) : L10n.string(.preflightBrewCommandNotFound, locale: locale),
                blocking: false
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.brew-prefix",
                title: L10n.string(.preflightBrewPrefixTitle, locale: locale),
                passed: resolvedBrewPrefix?.isEmpty == false,
                detail: brewAvailable
                    ? (resolvedBrewPrefix ?? L10n.string(.preflightBrewPrefixFailed, locale: locale))
                    : L10n.string(.preflightBrewPrefixUnavailable, locale: locale),
                blocking: false
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.git",
                title: L10n.string(.preflightGitTitle, locale: locale),
                passed: gitAvailable,
                detail: gitAvailable ? L10n.string(.preflightGitAvailable, locale: locale) : L10n.string(.preflightGitCommandNotFound, locale: locale),
                blocking: false
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.vscode",
                title: L10n.string(.preflightVSCodeTitle, locale: locale),
                passed: vscodeInstalled,
                detail: vscodeInstalled ? vscodeApp.path : L10n.string(.preflightVSCodeAppNotFound, locale: locale),
                blocking: false
            )
        )

        checks.append(
            PreflightCheck(
                id: "preflight.code-cli",
                title: L10n.string(.preflightCodeCLITitle, locale: locale),
                passed: codeCLIAvailable,
                detail: codeCLIAvailable ? L10n.string(.preflightCodeCLIAvailable, locale: locale) : L10n.string(.preflightCodeCLICommandNotFound, locale: locale),
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
                    title: L10n.string(.preflightImportBundleExistsTitle, locale: locale),
                    passed: fileSystem.fileExists(at: bundle),
                    detail: bundle.path,
                    blocking: true
                )
            )
            checks.append(checkWritePermission(for: URL(fileURLWithPath: machine.homeDirectory)))
        }

        return PreflightResult(machine: machine, checks: checks)
    }

    private func readBrewPrefix() -> String? {
        guard let output = try? runner.run(executable: "/usr/bin/env", arguments: ["brew", "--prefix"]).stdout else {
            return nil
        }

        let prefix = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix.isEmpty ? nil : prefix
    }

    private func checkWritePermission(for url: URL) -> PreflightCheck {
        let testDir = url.appendingPathComponent(".mac-dev-env-mover-preflight")
        do {
            try fileSystem.createDirectory(at: testDir)
            try fileSystem.removeItem(at: testDir)
            return PreflightCheck(
                id: "preflight.write",
                title: L10n.string(.preflightWriteTitle, locale: locale),
                passed: true,
                detail: url.path,
                blocking: true
            )
        } catch {
            return PreflightCheck(
                id: "preflight.write",
                title: L10n.string(.preflightWriteTitle, locale: locale),
                passed: false,
                detail: "\(url.path): \(error.localizedDescription)",
                blocking: true
            )
        }
    }
}
