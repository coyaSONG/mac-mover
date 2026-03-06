import Foundation
import SharedModels

public struct VerifyEngine {
    private let fileSystem: FileSysteming
    private let runner: CommandRunning

    public init(fileSystem: FileSysteming = LocalFileSystem(), runner: CommandRunning = ProcessCommandRunner()) {
        self.fileSystem = fileSystem
        self.runner = runner
    }

    public func verify(items: [ManifestItem], homeDirectory: String) -> OperationReport {
        var report = OperationReport(title: "Verify Report")

        for item in items {
            guard let verify = item.verify else {
                report.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: "verify spec not provided"))
                continue
            }

            if let expectedFile = verify.expectedFile {
                let path = PathNormalizer.expandTilde(expectedFile, homeDirectory: homeDirectory)
                let exists = fileSystem.fileExists(at: URL(fileURLWithPath: path))
                if exists {
                    report.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: "File exists: \(expectedFile)"))
                } else {
                    report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: "File missing: \(expectedFile)"))
                }
                continue
            }

            if let command = verify.command {
                let parts = command.split(separator: " ").map(String.init)
                guard let executableName = parts.first else {
                    report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: "Invalid verify command"))
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
                            report.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: "Expected value matched"))
                        } else {
                            report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: "Expected \(expectedValue), got \(output)"))
                        }
                    } else {
                        report.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: "Command succeeded"))
                    }
                } catch {
                    report.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
                }
                continue
            }

            report.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: "No supported verify spec"))
        }

        return report
    }
}
