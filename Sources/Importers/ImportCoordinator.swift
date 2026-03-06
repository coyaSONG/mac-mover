import Foundation
import SharedModels
import Core
import Reporting

public struct ImportCoordinator {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let bundleValidator: BundleValidator
    private let manifestStore: ManifestStore
    private let preflightService: PreflightService
    private let fileRestorer: FileRestorer
    private let manualTaskEngine: ManualTaskEngine
    private let reportWriter: ReportFileWriter
    private let verifyEngine: VerifyEngine

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        fileSystem: FileSysteming = LocalFileSystem(),
        bundleValidator: BundleValidator? = nil,
        manifestStore: ManifestStore? = nil,
        preflightService: PreflightService? = nil,
        fileRestorer: FileRestorer? = nil,
        manualTaskEngine: ManualTaskEngine = ManualTaskEngine(),
        reportWriter: ReportFileWriter? = nil,
        verifyEngine: VerifyEngine? = nil
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.bundleValidator = bundleValidator ?? BundleValidator(fileSystem: fileSystem, manifestStore: manifestStore ?? ManifestStore(fileSystem: fileSystem))
        self.manifestStore = manifestStore ?? ManifestStore(fileSystem: fileSystem)
        self.preflightService = preflightService ?? PreflightService(runner: runner, fileSystem: fileSystem)
        self.fileRestorer = fileRestorer ?? FileRestorer(fileSystem: fileSystem)
        self.manualTaskEngine = manualTaskEngine
        self.reportWriter = reportWriter ?? ReportFileWriter(fileSystem: fileSystem)
        self.verifyEngine = verifyEngine ?? VerifyEngine(fileSystem: fileSystem, runner: runner)
    }

    public func `import`(from bundleURL: URL) throws -> ImportResult {
        let layout = BundleLayout(root: bundleURL)
        try? fileSystem.createDirectory(at: layout.logsDirectory)
        let logger = StructuredLogger(fileURL: layout.logsDirectory.appendingPathComponent("import-log.jsonl"))
        logger.log(.info, message: "import_started", context: ["bundlePath": bundleURL.path])
        let manifest = try bundleValidator.validateBundle(at: bundleURL)
        logger.log(.info, message: "bundle_validated", context: ["itemCount": "\(manifest.items.count)"])

        let preflight = preflightService.run(mode: .import(bundle: bundleURL))
        if preflight.hasBlockingFailure {
            logger.log(.error, message: "preflight_blocked", context: ["bundlePath": bundleURL.path])
            throw MoverError.blockedByPreflight("Import preflight has blocking failures")
        }

        var aggregate = ComponentImportResult()
        aggregate.manualTasks += manifest.manualTasks

        if manifest.machine.architecture != preflight.machine.architecture {
            aggregate.manualTasks.append(
                manualTaskEngine.taskForArchitectureMismatch(source: manifest.machine.architecture, target: preflight.machine.architecture)
            )
        }

        let brewAvailable = runner.commandExists("brew")
        if !brewAvailable {
            aggregate.manualTasks.append(manualTaskEngine.taskForMissingBrew())
            aggregate.skipped.append(
                StepResult(id: "import.packages", title: "Homebrew packages", status: .skipped, detail: "brew missing; bootstrap manual task added")
            )
        } else if fileSystem.fileExists(at: layout.brewfileURL) {
            do {
                _ = try runner.run(executable: "/usr/bin/env", arguments: ["brew", "bundle", "--file", layout.brewfileURL.path])
                aggregate.successes.append(StepResult(id: "import.packages", title: "Brewfile restore", status: .success, detail: "brew bundle applied"))
                logger.log(.info, message: "brew_bundle_applied", context: ["path": layout.brewfileURL.path])
            } catch {
                aggregate.failures.append(StepResult(id: "import.packages", title: "Brewfile restore", status: .failed, detail: error.localizedDescription))
                logger.log(.error, message: "brew_bundle_failed", context: ["error": error.localizedDescription])
            }
        }

        aggregate.append(try applyDotfiles(manifest: manifest, layout: layout, homeDirectory: preflight.machine.homeDirectory))
        aggregate.append(applyGitGlobal(manifest: manifest))
        aggregate.append(try applyVSCode(manifest: manifest, layout: layout, homeDirectory: preflight.machine.homeDirectory))

        var importReport = OperationReport(
            title: "Import Summary",
            generatedAt: Date(),
            successes: aggregate.successes,
            failures: aggregate.failures,
            skipped: aggregate.skipped,
            warnings: aggregate.warnings,
            manualTasks: aggregate.manualTasks
        )

        let verifyReport = verifyEngine.verify(items: manifest.items, homeDirectory: preflight.machine.homeDirectory)
        if !verifyReport.failures.isEmpty {
            importReport.warnings.append("Verify phase contains failed checks.")
        }

        try reportWriter.writeReport(importReport, to: layout.importSummaryURL)
        try reportWriter.writeReport(verifyReport, to: layout.verifySummaryURL)
        logger.log(.info, message: "import_completed", context: ["successes": "\(importReport.successes.count)", "failures": "\(importReport.failures.count)", "verifyFailures": "\(verifyReport.failures.count)"])

        return ImportResult(
            bundleURL: bundleURL,
            manifest: manifest,
            preflight: preflight,
            importReport: importReport,
            verifyReport: verifyReport
        )
    }

    private func applyDotfiles(manifest: Manifest, layout: BundleLayout, homeDirectory: String) throws -> ComponentImportResult {
        var result = ComponentImportResult()
        let dotfileItems = manifest.items.filter { $0.kind == .dotfile }

        for item in dotfileItems {
            guard
                let relativePath = item.payload["relativePath"]?.stringValue,
                let sourcePath = item.source?.path
            else {
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: "missing source metadata"))
                continue
            }

            let sourceURL = layout.root.appendingPathComponent(relativePath)
            let destinationPath = PathNormalizer.expandTilde(sourcePath, homeDirectory: homeDirectory)
            let destinationURL = URL(fileURLWithPath: destinationPath)

            do {
                if fileSystem.fileExists(at: destinationURL) {
                    result.manualTasks.append(manualTaskEngine.taskForOverwriteConfirmation(sourcePath))
                }
                let backup = try fileRestorer.restoreFile(from: sourceURL, to: destinationURL)
                let detail = backup == nil ? "restored" : "restored with backup: \(backup!.lastPathComponent)"
                result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: detail))
            } catch {
                result.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
            }
        }

        return result
    }

    private func applyGitGlobal(manifest: Manifest) -> ComponentImportResult {
        var result = ComponentImportResult()
        let gitItems = manifest.items.filter { $0.kind == .gitGlobal }

        guard runner.commandExists("git") else {
            if !gitItems.isEmpty {
                result.skipped.append(StepResult(id: "import.git", title: "Git global config", status: .skipped, detail: "git command not found"))
            }
            return result
        }

        for item in gitItems {
            guard let key = item.payload["key"]?.stringValue,
                  let value = item.payload["value"]?.stringValue else {
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: "missing key/value payload"))
                continue
            }

            do {
                _ = try runner.run(executable: "/usr/bin/env", arguments: ["git", "config", "--global", key, value])
                result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: "git config applied"))
            } catch {
                result.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
            }
        }

        return result
    }

    private func applyVSCode(manifest: Manifest, layout: BundleLayout, homeDirectory: String) throws -> ComponentImportResult {
        var result = ComponentImportResult()
        let vscodeSettingsItems = manifest.items.filter { $0.kind == .vscodeSettings }
        let vscodeExtensionItems = manifest.items.filter { $0.kind == .vscodeExtension }

        for item in vscodeSettingsItems {
            guard let relativePath = item.payload["relativePath"]?.stringValue,
                  let targetPath = item.source?.path else {
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: "missing vscode payload metadata"))
                continue
            }

            let sourceURL = layout.root.appendingPathComponent(relativePath)
            let destinationURL = URL(fileURLWithPath: PathNormalizer.expandTilde(targetPath, homeDirectory: homeDirectory))

            do {
                if isDirectory(at: sourceURL) {
                    if !fileSystem.fileExists(at: destinationURL) {
                        try fileSystem.createDirectory(at: destinationURL)
                    }
                    let children = try fileSystem.listDirectory(at: sourceURL)
                    for child in children {
                        let targetChild = destinationURL.appendingPathComponent(child.lastPathComponent)
                        if fileSystem.fileExists(at: targetChild) {
                            result.manualTasks.append(manualTaskEngine.taskForOverwriteConfirmation(targetChild.path))
                        }
                        _ = try fileRestorer.restoreFile(from: child, to: targetChild)
                    }
                    result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: "directory restored"))
                } else {
                    if fileSystem.fileExists(at: destinationURL) {
                        result.manualTasks.append(manualTaskEngine.taskForOverwriteConfirmation(destinationURL.path))
                    }
                    let backup = try fileRestorer.restoreFile(from: sourceURL, to: destinationURL)
                    let detail = backup == nil ? "restored" : "restored with backup: \(backup!.lastPathComponent)"
                    result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: detail))
                }
            } catch {
                result.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
            }
        }

        if !vscodeExtensionItems.isEmpty && !runner.commandExists("code") {
            result.manualTasks.append(manualTaskEngine.taskForMissingCodeCLI())
            result.skipped.append(StepResult(id: "import.vscode.extensions", title: "VS Code extensions", status: .skipped, detail: "code CLI not found"))
            return result
        }

        for item in vscodeExtensionItems {
            guard let identifier = item.payload["identifier"]?.stringValue else {
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: "missing extension identifier"))
                continue
            }

            let version = item.payload["version"]?.stringValue
            let installArg: String
            if let version, version != "unknown", !version.isEmpty {
                installArg = "\(identifier)@\(version)"
            } else {
                installArg = identifier
            }

            do {
                _ = try runner.run(executable: "/usr/bin/env", arguments: ["code", "--install-extension", installArg, "--force"])
                result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: "extension installed"))
            } catch {
                result.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
            }
        }

        return result
    }

    private func isDirectory(at url: URL) -> Bool {
        (try? fileSystem.listDirectory(at: url)) != nil
    }
}
