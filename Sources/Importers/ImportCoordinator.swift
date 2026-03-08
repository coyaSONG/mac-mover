import Foundation
import Localization
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
    private let locale: Locale?

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        fileSystem: FileSysteming = LocalFileSystem(),
        bundleValidator: BundleValidator? = nil,
        manifestStore: ManifestStore? = nil,
        preflightService: PreflightService? = nil,
        fileRestorer: FileRestorer? = nil,
        manualTaskEngine: ManualTaskEngine = ManualTaskEngine(),
        reportWriter: ReportFileWriter? = nil,
        verifyEngine: VerifyEngine? = nil,
        locale: Locale? = nil
    ) {
        self.locale = locale
        self.runner = runner
        self.fileSystem = fileSystem
        self.bundleValidator = bundleValidator ?? BundleValidator(fileSystem: fileSystem, manifestStore: manifestStore ?? ManifestStore(fileSystem: fileSystem))
        self.manifestStore = manifestStore ?? ManifestStore(fileSystem: fileSystem)
        self.preflightService = preflightService ?? PreflightService(runner: runner, fileSystem: fileSystem, locale: locale)
        self.fileRestorer = fileRestorer ?? FileRestorer(fileSystem: fileSystem)
        self.manualTaskEngine = manualTaskEngine.locale == locale ? manualTaskEngine : ManualTaskEngine(locale: locale)
        self.reportWriter = reportWriter ?? ReportFileWriter(fileSystem: fileSystem, markdownWriter: MarkdownReportWriter(locale: locale))
        self.verifyEngine = verifyEngine ?? VerifyEngine(fileSystem: fileSystem, runner: runner, locale: locale)
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
            throw MoverError.blockedByPreflight(L10n.string(.statusImportBundleBlockingPreflight, locale: locale))
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
                StepResult(id: "import.packages", title: L10n.string(.importPackagesTitle, locale: locale), status: .skipped, detail: L10n.string(.importPackagesBrewMissing, locale: locale))
            )
        } else if fileSystem.fileExists(at: layout.brewfileURL) {
            do {
                _ = try runner.run(executable: "/usr/bin/env", arguments: ["brew", "bundle", "--file", layout.brewfileURL.path])
                aggregate.successes.append(StepResult(id: "import.packages", title: L10n.string(.importBrewfileRestoreTitle, locale: locale), status: .success, detail: L10n.string(.importBrewBundleApplied, locale: locale)))
                logger.log(.info, message: "brew_bundle_applied", context: ["path": layout.brewfileURL.path])
            } catch {
                aggregate.failures.append(StepResult(id: "import.packages", title: L10n.string(.importBrewfileRestoreTitle, locale: locale), status: .failed, detail: error.localizedDescription))
                logger.log(.error, message: "brew_bundle_failed", context: ["error": error.localizedDescription])
            }
        }

        aggregate.append(try applyDotfiles(manifest: manifest, layout: layout, homeDirectory: preflight.machine.homeDirectory))
        aggregate.append(try applyGitGlobal(manifest: manifest, homeDirectory: preflight.machine.homeDirectory))
        aggregate.append(try applyVSCode(manifest: manifest, layout: layout, homeDirectory: preflight.machine.homeDirectory))

        var importReport = OperationReport(
            title: L10n.string(.reportImportSummaryTitle, locale: locale),
            generatedAt: Date(),
            successes: aggregate.successes,
            failures: aggregate.failures,
            skipped: aggregate.skipped,
            warnings: aggregate.warnings,
            manualTasks: aggregate.manualTasks
        )

        let verifyReport = verifyEngine.verify(items: manifest.items, homeDirectory: preflight.machine.homeDirectory)
        if !verifyReport.failures.isEmpty {
            importReport.warnings.append(L10n.string(.importVerifyFailedWarning, locale: locale))
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
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: L10n.string(.importMissingSourceMetadata, locale: locale)))
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
                let detail = backup == nil ? L10n.string(.importRestored, locale: locale) : L10n.format(.importRestoredWithBackup, locale: locale, backup!.lastPathComponent)
                result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: detail))
            } catch {
                result.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
            }
        }

        return result
    }

    private func applyGitGlobal(manifest: Manifest, homeDirectory: String) throws -> ComponentImportResult {
        var result = ComponentImportResult()
        let gitItems = manifest.items.filter { $0.kind == .gitGlobal }
        guard !gitItems.isEmpty else { return result }

        guard runner.commandExists("git") else {
            result.skipped.append(StepResult(id: "import.git", title: L10n.string(.importGitTitle, locale: locale), status: .skipped, detail: L10n.string(.exportGitCommandNotFound, locale: locale)))
            return result
        }

        let gitConfigURL = URL(fileURLWithPath: homeDirectory).appendingPathComponent(".gitconfig")
        var backupURL: URL?

        if fileSystem.fileExists(at: gitConfigURL) {
            result.manualTasks.append(manualTaskEngine.taskForOverwriteConfirmation("~/.gitconfig"))
            do {
                backupURL = try fileRestorer.backupIfNeeded(destination: gitConfigURL)
            } catch {
                result.failures.append(
                    StepResult(
                        id: "import.git.backup",
                        title: L10n.string(.importGitBackupTitle, locale: locale),
                        status: .failed,
                        detail: error.localizedDescription
                    )
                )
                return result
            }
        }

        for item in gitItems {
            guard let key = item.payload["key"]?.stringValue,
                  let value = item.payload["value"]?.stringValue else {
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: L10n.string(.importMissingKeyValuePayload, locale: locale)))
                continue
            }

            do {
                _ = try runner.run(executable: "/usr/bin/env", arguments: ["git", "config", "--global", key, value])
                let detail = backupURL == nil ? L10n.string(.importGitConfigApplied, locale: locale) : L10n.format(.importGitConfigAppliedWithBackup, locale: locale, backupURL!.lastPathComponent)
                result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: detail))
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
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: L10n.string(.importMissingVSCodePayloadMetadata, locale: locale)))
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
                    result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: L10n.string(.importDirectoryRestored, locale: locale)))
                } else {
                    if fileSystem.fileExists(at: destinationURL) {
                        result.manualTasks.append(manualTaskEngine.taskForOverwriteConfirmation(destinationURL.path))
                    }
                    let backup = try fileRestorer.restoreFile(from: sourceURL, to: destinationURL)
                    let detail = backup == nil ? L10n.string(.importRestored, locale: locale) : L10n.format(.importRestoredWithBackup, locale: locale, backup!.lastPathComponent)
                    result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: detail))
                }
            } catch {
                result.failures.append(StepResult(id: item.id, title: item.title, status: .failed, detail: error.localizedDescription))
            }
        }

        if !vscodeExtensionItems.isEmpty && !runner.commandExists("code") {
            result.manualTasks.append(manualTaskEngine.taskForMissingCodeCLI())
            result.skipped.append(StepResult(id: "import.vscode.extensions", title: L10n.string(.importVSCodeExtensionsTitle, locale: locale), status: .skipped, detail: L10n.string(.exportVSCodeCodeCLINotFound, locale: locale)))
            return result
        }

        for item in vscodeExtensionItems {
            guard let identifier = item.payload["identifier"]?.stringValue else {
                result.skipped.append(StepResult(id: item.id, title: item.title, status: .skipped, detail: L10n.string(.importMissingExtensionIdentifier, locale: locale)))
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
                result.successes.append(StepResult(id: item.id, title: item.title, status: .success, detail: L10n.string(.importExtensionInstalled, locale: locale)))
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
