import Foundation
import Localization
import SharedModels
import Core

struct HomebrewExporter {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let manualTaskEngine: ManualTaskEngine
    private let locale: Locale?

    init(
        runner: CommandRunning,
        fileSystem: FileSysteming,
        manualTaskEngine: ManualTaskEngine,
        locale: Locale? = nil
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.manualTaskEngine = manualTaskEngine
        self.locale = locale
    }

    func export(to layout: BundleLayout) -> ComponentExportResult {
        var result = ComponentExportResult()

        guard runner.commandExists("brew") else {
            result.manualTasks.append(manualTaskEngine.taskForMissingBrew())
            result.skipped.append(
                StepResult(
                    id: "export.brew",
                    title: L10n.string(.exportHomebrewTitle, locale: locale),
                    status: .skipped,
                    detail: L10n.string(.exportBrewCommandNotFound, locale: locale)
                )
            )
            return result
        }

        do {
            _ = try runner.run(
                executable: "/usr/bin/env",
                arguments: ["brew", "bundle", "dump", "--force", "--file", layout.brewfileURL.path]
            )
            result.successes.append(
                StepResult(id: "export.brew.brewfile", title: "Brewfile", status: .success, detail: layout.brewfileURL.path)
            )
        } catch {
            result.failures.append(
                StepResult(id: "export.brew.brewfile", title: "Brewfile", status: .failed, detail: error.localizedDescription)
            )
            if !fileSystem.fileExists(at: layout.brewfileURL) {
                result.warnings.append(L10n.string(.exportBrewfileCreationFailedWarning, locale: locale))
            }
        }

        let formulas = readLines(command: ["brew", "list", "--formula"])
        for formula in formulas where !formula.isEmpty {
            result.items.append(
                ManifestItem(
                    id: "brew.formula.\(IdentifierSanitizer.sanitize(formula))",
                    kind: .brewFormula,
                    title: formula,
                    restorePhase: .packages,
                    source: ItemSource(command: "brew list --formula"),
                    payload: ["name": .string(formula)],
                    secret: false,
                    risk: .low,
                    verify: VerifySpec(command: "brew list --formula", expectedValue: .string(formula)),
                    notes: []
                )
            )
            result.successes.append(
                StepResult(
                    id: "export.brew.formula.\(IdentifierSanitizer.sanitize(formula))",
                    title: L10n.format(.exportBrewFormulaTitle, locale: locale, formula),
                    status: .success,
                    detail: formula
                )
            )
        }

        let casks = readLines(command: ["brew", "list", "--cask"])
        for cask in casks where !cask.isEmpty {
            result.items.append(
                ManifestItem(
                    id: "brew.cask.\(IdentifierSanitizer.sanitize(cask))",
                    kind: .brewCask,
                    title: cask,
                    restorePhase: .packages,
                    source: ItemSource(command: "brew list --cask"),
                    payload: ["name": .string(cask)],
                    secret: false,
                    risk: .low,
                    verify: VerifySpec(command: "brew list --cask", expectedValue: .string(cask)),
                    notes: []
                )
            )
            result.successes.append(
                StepResult(
                    id: "export.brew.cask.\(IdentifierSanitizer.sanitize(cask))",
                    title: L10n.format(.exportBrewCaskTitle, locale: locale, cask),
                    status: .success,
                    detail: cask
                )
            )
        }

        let taps = readLines(command: ["brew", "tap"])
        for tap in taps where !tap.isEmpty {
            result.items.append(
                ManifestItem(
                    id: "brew.tap.\(IdentifierSanitizer.sanitize(tap))",
                    kind: .brewTap,
                    title: tap,
                    restorePhase: .packages,
                    source: ItemSource(command: "brew tap"),
                    payload: ["name": .string(tap)],
                    secret: false,
                    risk: .low,
                    verify: VerifySpec(command: "brew tap", expectedValue: .string(tap)),
                    notes: []
                )
            )
            result.successes.append(
                StepResult(
                    id: "export.brew.tap.\(IdentifierSanitizer.sanitize(tap))",
                    title: L10n.format(.exportBrewTapTitle, locale: locale, tap),
                    status: .success,
                    detail: tap
                )
            )
        }

        let serviceLines = Array(readLines(command: ["brew", "services", "list"]).dropFirst())
        for line in serviceLines {
            let columns = line.split(whereSeparator: { $0.isWhitespace })
            guard let first = columns.first, !first.isEmpty else { continue }
            let service = String(first)
            result.items.append(
                ManifestItem(
                    id: "brew.service.\(IdentifierSanitizer.sanitize(service))",
                    kind: .brewService,
                    title: service,
                    restorePhase: .packages,
                    source: ItemSource(command: "brew services list"),
                    payload: ["name": .string(service)],
                    secret: false,
                    risk: .medium,
                    verify: VerifySpec(command: "brew services list", expectedValue: .string(service)),
                    notes: []
                )
            )
            result.successes.append(
                StepResult(
                    id: "export.brew.service.\(IdentifierSanitizer.sanitize(service))",
                    title: L10n.format(.exportBrewServiceTitle, locale: locale, service),
                    status: .success,
                    detail: service
                )
            )
        }

        return result
    }

    private func readLines(command: [String]) -> [String] {
        guard !command.isEmpty,
              let output = try? runner.run(executable: "/usr/bin/env", arguments: command).stdout
        else {
            return []
        }

        return output
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
    }
}
