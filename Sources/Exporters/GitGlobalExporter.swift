import Foundation
import Localization
import SharedModels
import Core

struct GitGlobalExporter {
    private let runner: CommandRunning
    private let manualTaskEngine: ManualTaskEngine
    private let locale: Locale?

    init(runner: CommandRunning, manualTaskEngine: ManualTaskEngine, locale: Locale? = nil) {
        self.runner = runner
        self.manualTaskEngine = manualTaskEngine
        self.locale = locale
    }

    func export() -> ComponentExportResult {
        var result = ComponentExportResult()

        guard runner.commandExists("git") else {
            result.skipped.append(StepResult(id: "git.global", title: L10n.string(.exportGitGlobalTitle, locale: locale), status: .skipped, detail: L10n.string(.exportGitCommandNotFound, locale: locale)))
            return result
        }

        guard let output = try? runner.run(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--list"]).stdout else {
            result.failures.append(StepResult(id: "git.global", title: L10n.string(.exportGitGlobalTitle, locale: locale), status: .failed, detail: L10n.string(.exportGitReadFailed, locale: locale)))
            return result
        }

        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        for line in lines {
            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<separator])
            let value = String(line[line.index(after: separator)...])

            if SecretPolicy.shouldExclude(path: key) {
                result.manualTasks.append(manualTaskEngine.taskForExcludedSecret("git config --global \(key)"))
                result.skipped.append(StepResult(id: "git.global.skip.\(IdentifierSanitizer.sanitize(key))", title: key, status: .skipped, detail: L10n.string(.exportExcludedBySecretPolicy, locale: locale)))
                continue
            }

            let itemID = "git.global.\(IdentifierSanitizer.sanitize(key))"
            result.items.append(
                ManifestItem(
                    id: itemID,
                    kind: .gitGlobal,
                    title: "git \(key)",
                    restorePhase: .config,
                    source: ItemSource(path: "~/.gitconfig"),
                    payload: ["key": .string(key), "value": .string(value)],
                    secret: false,
                    risk: .low,
                    verify: VerifySpec(command: "git config --global --get \(key)", expectedValue: .string(value)),
                    notes: []
                )
            )
        }

        result.successes.append(StepResult(id: "git.global", title: L10n.string(.exportGitGlobalTitle, locale: locale), status: .success, detail: L10n.format(.exportGitEntries, locale: locale, result.items.count)))
        return result
    }
}
