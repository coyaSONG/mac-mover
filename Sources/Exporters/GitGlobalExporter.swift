import Foundation
import SharedModels
import Core

struct GitGlobalExporter {
    private let runner: CommandRunning
    private let manualTaskEngine: ManualTaskEngine

    init(runner: CommandRunning, manualTaskEngine: ManualTaskEngine) {
        self.runner = runner
        self.manualTaskEngine = manualTaskEngine
    }

    func export() -> ComponentExportResult {
        var result = ComponentExportResult()

        guard runner.commandExists("git") else {
            result.skipped.append(StepResult(id: "git.global", title: "Git global config", status: .skipped, detail: "git command not found"))
            return result
        }

        guard let output = try? runner.run(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--list"]).stdout else {
            result.failures.append(StepResult(id: "git.global", title: "Git global config", status: .failed, detail: "failed to read git global config"))
            return result
        }

        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        for line in lines {
            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<separator])
            let value = String(line[line.index(after: separator)...])

            if SecretPolicy.shouldExclude(path: key) {
                result.manualTasks.append(manualTaskEngine.taskForExcludedSecret("git config --global \(key)"))
                result.skipped.append(StepResult(id: "git.global.skip.\(IdentifierSanitizer.sanitize(key))", title: key, status: .skipped, detail: "excluded by secret policy"))
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

        result.successes.append(StepResult(id: "git.global", title: "Git global config", status: .success, detail: "\(result.items.count) entries"))
        return result
    }
}
