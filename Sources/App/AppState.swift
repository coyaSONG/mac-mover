import Foundation
import SwiftUI
import AppKit
import SharedModels
import Core
import Reporting
import Exporters
import Importers

@MainActor
final class AppState: ObservableObject {
    @Published var machineSummary: String = ""
    @Published var exportPath: String = ""
    @Published var importPath: String = ""
    @Published var exportSummary: String = "No export executed"
    @Published var importSummary: String = "No import executed"
    @Published var verifySummary: String = "No verify executed"
    @Published var manualTasks: [ManualTask] = []
    @Published var preflightChecks: [PreflightCheck] = []
    @Published var logsPreview: String = "No logs"
    @Published var statusMessage: String = "Idle"
    @Published var isRunning: Bool = false

    @Published var lastExportBundleURL: URL?
    @Published var lastImportBundleURL: URL?

    private let preflightService: PreflightService
    private let bundlePreviewLoader: any BundlePreviewLoading
    private let bundleValidator: BundleValidator
    private let verifyEngine: VerifyEngine
    private let reportWriter: ReportFileWriter
    private let exportCoordinator: ExportCoordinator
    private let importCoordinator: ImportCoordinator
    private let artifactReader: BundleArtifactReading
    private let machineSummaryProvider: @MainActor () -> String

    init(
        preflightService: PreflightService = PreflightService(),
        bundlePreviewLoader: any BundlePreviewLoading = BundlePreviewService(),
        bundleValidator: BundleValidator = BundleValidator(),
        verifyEngine: VerifyEngine = VerifyEngine(),
        reportWriter: ReportFileWriter = ReportFileWriter(),
        exportCoordinator: ExportCoordinator = ExportCoordinator(),
        importCoordinator: ImportCoordinator = ImportCoordinator(),
        artifactReader: BundleArtifactReading = BundleArtifactReader(),
        machineSummaryProvider: @escaping @MainActor () -> String = AppState.buildMachineSummary
    ) {
        self.preflightService = preflightService
        self.bundlePreviewLoader = bundlePreviewLoader
        self.bundleValidator = bundleValidator
        self.verifyEngine = verifyEngine
        self.reportWriter = reportWriter
        self.exportCoordinator = exportCoordinator
        self.importCoordinator = importCoordinator
        self.artifactReader = artifactReader
        self.machineSummaryProvider = machineSummaryProvider

        machineSummary = machineSummaryProvider()
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        exportPath = desktop.appendingPathComponent("MacDevEnvExport").path
    }

    func chooseExportFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            exportPath = url.appendingPathComponent("MacDevEnvExport").path
        }
    }

    func chooseImportFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            importPath = url.path
            runImportPreflight(bundleURL: url)
        }
    }

    func runExport() {
        let destination = URL(fileURLWithPath: exportPath)
        statusMessage = "Export running..."

        Task {
            isRunning = true
            defer { isRunning = false }
            do {
                let result = try exportCoordinator.export(to: destination)
                lastExportBundleURL = result.bundleURL
                manualTasks = result.manifest.manualTasks
                preflightChecks = result.preflight.checks
                exportSummary = artifactReader.readText(at: destination.appendingPathComponent("reports/export-summary.md"))
                verifySummary = artifactReader.readText(at: destination.appendingPathComponent("reports/verify-summary.md"))
                logsPreview = artifactReader.readLogPreview(at: destination.appendingPathComponent("logs"))
                machineSummary = machineSummaryProvider()
                statusMessage = "Export completed"
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    func runImportPreflight(bundleURL: URL) {
        do {
            let preview = try bundlePreviewLoader.load(from: bundleURL)
            lastImportBundleURL = preview.bundleURL
            manualTasks = preview.manifest.manualTasks
            preflightChecks = preview.preflight.checks
            exportSummary = preview.exportSummary
            importSummary = preview.importSummary
            verifySummary = preview.verifySummary
            logsPreview = preview.logsPreview
            machineSummary = machineSummaryProvider()
            statusMessage = preview.preflight.hasBlockingFailure ? "Import bundle has blocking preflight issues" : "Import bundle ready"
        } catch {
            lastImportBundleURL = nil
            manualTasks = []
            preflightChecks = []
            exportSummary = "No export executed"
            importSummary = "No import executed"
            verifySummary = "No verify executed"
            logsPreview = "No logs"
            machineSummary = machineSummaryProvider()
            statusMessage = "Import preflight failed: \(error.localizedDescription)"
        }
    }

    func runImport() {
        guard !importPath.isEmpty else {
            statusMessage = "Select an import bundle first"
            return
        }

        let source = URL(fileURLWithPath: importPath)
        statusMessage = "Import running..."

        Task {
            isRunning = true
            defer { isRunning = false }
            do {
                let result = try importCoordinator.import(from: source)
                lastImportBundleURL = result.bundleURL
                manualTasks = result.importReport.manualTasks
                preflightChecks = result.preflight.checks
                importSummary = artifactReader.readText(at: source.appendingPathComponent("reports/import-summary.md"))
                verifySummary = artifactReader.readText(at: source.appendingPathComponent("reports/verify-summary.md"))
                logsPreview = artifactReader.readLogPreview(at: source.appendingPathComponent("logs"))
                statusMessage = "Import completed"
            } catch {
                statusMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    func runVerify() {
        guard !importPath.isEmpty else {
            statusMessage = "Select an import bundle first"
            return
        }

        let source = URL(fileURLWithPath: importPath)
        statusMessage = "Verify running..."

        Task {
            isRunning = true
            defer { isRunning = false }
            do {
                let manifest = try bundleValidator.validateBundle(at: source)
                let preflight = preflightService.run(mode: .import(bundle: source))
                preflightChecks = preflight.checks

                if preflight.hasBlockingFailure {
                    statusMessage = "Verify blocked by preflight"
                    return
                }

                let report = verifyEngine.verify(items: manifest.items, homeDirectory: preflight.machine.homeDirectory)
                try reportWriter.writeReport(report, to: BundleLayout(root: source).verifySummaryURL)

                manualTasks = manifest.manualTasks
                verifySummary = artifactReader.readText(at: source.appendingPathComponent("reports/verify-summary.md"))
                logsPreview = artifactReader.readLogPreview(at: source.appendingPathComponent("logs"))
                statusMessage = report.failures.isEmpty ? "Verify completed" : "Verify completed with failures"
            } catch {
                statusMessage = "Verify failed: \(error.localizedDescription)"
            }
        }
    }

    private static func buildMachineSummary() -> String {
        let machine = MachineInfoCollector().collect()
        return "Host: \(machine.hostname)\nArchitecture: \(machine.architecture.rawValue)\nmacOS: \(machine.macosVersion)\nHome: \(machine.homeDirectory)\nBrew Prefix: \(machine.homebrewPrefix)"
    }
}
