import Foundation
import Localization
import SharedModels

public struct VerifyEngine {
    private let fileSystem: FileSysteming
    private let runner: CommandRunning
    private let locale: Locale?

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        runner: CommandRunning = ProcessCommandRunner(),
        locale: Locale? = nil
    ) {
        self.fileSystem = fileSystem
        self.runner = runner
        self.locale = locale
    }

    public func verify(items: [ManifestItem], homeDirectory: String) -> OperationReport {
        var report = OperationReport(title: L10n.string(.reportVerifyReportTitle, locale: locale))

        for item in items {
            guard let verify = item.verify else {
                report.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: L10n.string(.verifySpecNotProvided, locale: locale)))
                continue
            }

            if let expectedFile = verify.expectedFile {
                let path = PathNormalizer.expandTilde(expectedFile, homeDirectory: homeDirectory)
                let exists = fileSystem.fileExists(at: URL(fileURLWithPath: path))
                if exists {
                    report.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: L10n.format(.verifyFileExists, locale: locale, expectedFile)))
                } else {
                    report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: L10n.format(.verifyFileMissing, locale: locale, expectedFile)))
                }
                continue
            }

            if let command = verify.command {
                let parts = command.split(separator: " ").map(String.init)
                guard let executableName = parts.first else {
                    report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: L10n.string(.verifyInvalidCommand, locale: locale)))
                    continue
                }

                let executable: String
                let args = Array(parts.dropFirst())
                if executableName.contains("/") {
                    executable = executableName
                } else {
                    executable = "/usr/bin/env"
                }

                do {
                    let result = try runner.run(executable: executable, arguments: executable == "/usr/bin/env" ? [executableName] + args : args)
                    if let expectedValue = verify.expectedValue?.stringValue {
                        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                        if output == expectedValue || output.contains(expectedValue) {
                            report.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: L10n.string(.verifyExpectedValueMatched, locale: locale)))
                        } else {
                            report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: L10n.format(.verifyExpectedValueMismatch, locale: locale, expectedValue, output)))
                        }
                    } else {
                        report.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: L10n.string(.verifyCommandSucceeded, locale: locale)))
                    }
                } catch {
                    report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
                }
                continue
            }

            report.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: L10n.string(.verifyUnsupportedSpec, locale: locale)))
        }

        return report
    }
}
