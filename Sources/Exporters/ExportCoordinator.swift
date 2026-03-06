import Foundation
import SharedModels
import Core
import Reporting

public struct ExportOptions: Sendable {
    public var allowlist: DotfileAllowlist

    public init(allowlist: DotfileAllowlist = DotfileAllowlist()) {
        self.allowlist = allowlist
    }
}

public struct ExportCoordinator {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let preflightService: PreflightService
    private let manifestStore: ManifestStore
    private let restorePlanBuilder: RestorePlanBuilder
    private let reportWriter: ReportFileWriter
    private let manualTaskEngine: ManualTaskEngine

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        fileSystem: FileSysteming = LocalFileSystem(),
        preflightService: PreflightService? = nil,
        manifestStore: ManifestStore? = nil,
        restorePlanBuilder: RestorePlanBuilder = RestorePlanBuilder(),
        reportWriter: ReportFileWriter? = nil,
        manualTaskEngine: ManualTaskEngine = ManualTaskEngine()
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.preflightService = preflightService ?? PreflightService(runner: runner, fileSystem: fileSystem)
        self.manifestStore = manifestStore ?? ManifestStore(fileSystem: fileSystem)
        self.restorePlanBuilder = restorePlanBuilder
        self.reportWriter = reportWriter ?? ReportFileWriter(fileSystem: fileSystem)
        self.manualTaskEngine = manualTaskEngine
    }

    public func export(to bundleURL: URL, options: ExportOptions = ExportOptions()) throws -> ExportResult {
        let layout = BundleLayout(root: bundleURL)
        try fileSystem.createDirectory(at: layout.root)
        try fileSystem.createDirectory(at: layout.filesDirectory)
        try fileSystem.createDirectory(at: layout.dotfilesDirectory)
        try fileSystem.createDirectory(at: layout.vscodeDirectory)
        try fileSystem.createDirectory(at: layout.vscodeSnippetsDirectory)
        try fileSystem.createDirectory(at: layout.reportsDirectory)
        try fileSystem.createDirectory(at: layout.logsDirectory)
        let logger = StructuredLogger(fileURL: layout.logsDirectory.appendingPathComponent("export-log.jsonl"))
        logger.log(.info, message: "export_started", context: ["bundlePath": bundleURL.path])

        let preflight = preflightService.run(mode: .export(destination: bundleURL))
        if preflight.hasBlockingFailure {
            logger.log(.error, message: "preflight_blocked", context: ["bundlePath": bundleURL.path])
            throw MoverError.blockedByPreflight("Export preflight has blocking failures")
        }

        let machine = preflight.machine

        var aggregate = ComponentExportResult()

        let brewExporter = HomebrewExporter(runner: runner, fileSystem: fileSystem, manualTaskEngine: manualTaskEngine)
        aggregate.append(brewExporter.export(to: layout))
        logger.log(.info, message: "brew_export_completed", context: ["items": "\(aggregate.items.count)"])

        let dotfilesExporter = DotfilesExporter(
            fileSystem: fileSystem,
            allowlist: options.allowlist,
            manualTaskEngine: manualTaskEngine,
            homeDirectory: machine.homeDirectory
        )
        aggregate.append(dotfilesExporter.export(to: layout))
        logger.log(.info, message: "dotfiles_export_completed", context: ["items": "\(aggregate.items.count)"])

        let gitExporter = GitGlobalExporter(runner: runner, manualTaskEngine: manualTaskEngine)
        aggregate.append(gitExporter.export())
        logger.log(.info, message: "git_export_completed", context: ["items": "\(aggregate.items.count)"])

        let vscodeExporter = VSCodeExporter(
            runner: runner,
            fileSystem: fileSystem,
            manualTaskEngine: manualTaskEngine,
            homeDirectory: machine.homeDirectory
        )
        aggregate.append(vscodeExporter.export(to: layout))
        logger.log(.info, message: "vscode_export_completed", context: ["items": "\(aggregate.items.count)"])

        if aggregate.items.isEmpty {
            aggregate.items.append(
                ManifestItem(
                    id: "manual.note.empty-export",
                    kind: .manualNote,
                    title: "No supported items exported",
                    restorePhase: .manual,
                    payload: ["message": .string("No supported resources were found during export.")],
                    secret: false,
                    risk: .low,
                    notes: ["Import will only provide manual guidance for this bundle."]
                )
            )
            aggregate.warnings.append("No supported items were collected; manifest includes a manual note item.")
        }

        let reports = ManifestReports(
            exportSummaryPath: "reports/export-summary.md",
            verifySummaryPath: "reports/verify-summary.md",
            warnings: aggregate.warnings
        )

        let manifest = Manifest(
            exportedAt: Date(),
            machine: machine,
            items: aggregate.items.sorted { $0.id < $1.id },
            restorePlan: restorePlanBuilder.build(items: aggregate.items),
            manualTasks: aggregate.manualTasks,
            reports: reports
        )

        try manifestStore.write(manifest, to: layout.manifestURL)
        logger.log(.info, message: "manifest_written", context: ["path": layout.manifestURL.path, "itemCount": "\(manifest.items.count)"])

        let report = OperationReport(
            title: "Export Summary",
            generatedAt: Date(),
            successes: aggregate.successes,
            failures: aggregate.failures,
            skipped: aggregate.skipped,
            warnings: aggregate.warnings,
            manualTasks: aggregate.manualTasks
        )

        try reportWriter.writeReport(report, to: layout.exportSummaryURL)

        let placeholderVerify = OperationReport(
            title: "Verify Summary",
            generatedAt: Date(),
            successes: [],
            failures: [],
            skipped: [StepResult(id: "verify.pending", title: "Verify", status: .skipped, detail: "Run import + verify on target machine")],
            warnings: [],
            manualTasks: aggregate.manualTasks
        )
        try reportWriter.writeReport(placeholderVerify, to: layout.verifySummaryURL)
        logger.log(.info, message: "export_completed", context: ["successes": "\(report.successes.count)", "failures": "\(report.failures.count)"])

        return ExportResult(bundleURL: bundleURL, manifest: manifest, preflight: preflight, report: report)
    }
}
