import Foundation
import SwiftUI
import AppKit
import SharedModels
import Core
import Reporting
import Exporters
import Importers

protocol WorkspaceDetecting {
    func detect(at root: URL) throws -> ConnectedWorkspace
}

extension RepoWorkspaceDetector: WorkspaceDetecting {}

protocol RepoSnapshotLoading {
    func load(from workspace: ConnectedWorkspace) throws -> RepoSnapshot
}

extension RepoSnapshotLoader: RepoSnapshotLoading {}

protocol EnvironmentScanning {
    func scan() -> EnvironmentSnapshot
}

extension EnvironmentScanner: EnvironmentScanning {}

protocol DriftComparing {
    func compare(repo: RepoSnapshot, local: EnvironmentSnapshot) -> [DriftItem]
}

extension DriftEngine: DriftComparing {}

@MainActor
final class AppState: ObservableObject {
    @Published var machineSummary: String = ""
    @Published var workspacePath: String = ""
    @Published var workspaceScanSummary: String = "No workspace scan executed"
    @Published var workspaceDriftSummary: String = "No workspace drift computed"
    @Published var workspaceApplySummary: String = "No workspace apply preview"
    @Published var workspacePromoteSummary: String = "No workspace promote preview"
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

    @Published var connectedWorkspace: ConnectedWorkspace?
    @Published var repoSnapshot: RepoSnapshot?
    @Published var environmentSnapshot: EnvironmentSnapshot?
    @Published var driftItems: [DriftItem] = []
    @Published var lastExportBundleURL: URL?
    @Published var lastImportBundleURL: URL?
    @Published private(set) var machineInfo: MachineInfo?

    var machineHost: String { machineInfo?.hostname ?? "Unknown" }
    var machineArch: String { machineInfo?.architecture.rawValue ?? "Unknown" }
    var machineOS: String { machineInfo?.macosVersion ?? "Unknown" }
    var machineHome: String { machineInfo?.homeDirectory ?? "Unknown" }
    var machineBrewPrefix: String { machineInfo?.homebrewPrefix ?? "Unknown" }

    private let preflightService: PreflightService
    private let bundlePreviewLoader: any BundlePreviewLoading
    private let bundleValidator: BundleValidator
    private let verifyEngine: VerifyEngine
    private let reportWriter: ReportFileWriter
    private let markdownWriter: MarkdownReportWriter
    private let exportCoordinator: ExportCoordinator
    private let importCoordinator: ImportCoordinator
    private let artifactReader: BundleArtifactReading
    private let workspaceDetector: any WorkspaceDetecting
    private let repoSnapshotLoader: any RepoSnapshotLoading
    private let environmentScanner: any EnvironmentScanning
    private let driftEngine: any DriftComparing
    private let machineSummaryProvider: @MainActor () -> String

    init(
        preflightService: PreflightService = PreflightService(),
        bundlePreviewLoader: any BundlePreviewLoading = BundlePreviewService(),
        bundleValidator: BundleValidator = BundleValidator(),
        verifyEngine: VerifyEngine = VerifyEngine(),
        reportWriter: ReportFileWriter = ReportFileWriter(),
        markdownWriter: MarkdownReportWriter = MarkdownReportWriter(),
        exportCoordinator: ExportCoordinator = ExportCoordinator(),
        importCoordinator: ImportCoordinator = ImportCoordinator(),
        artifactReader: BundleArtifactReading = BundleArtifactReader(),
        workspaceDetector: any WorkspaceDetecting = RepoWorkspaceDetector(),
        repoSnapshotLoader: any RepoSnapshotLoading = RepoSnapshotLoader(),
        environmentScanner: any EnvironmentScanning = EnvironmentScanner(),
        driftEngine: any DriftComparing = DriftEngine(),
        machineSummaryProvider: @escaping @MainActor () -> String = AppState.buildMachineSummary,
        initialMachineInfo: MachineInfo? = nil
    ) {
        self.preflightService = preflightService
        self.bundlePreviewLoader = bundlePreviewLoader
        self.bundleValidator = bundleValidator
        self.verifyEngine = verifyEngine
        self.reportWriter = reportWriter
        self.markdownWriter = markdownWriter
        self.exportCoordinator = exportCoordinator
        self.importCoordinator = importCoordinator
        self.artifactReader = artifactReader
        self.workspaceDetector = workspaceDetector
        self.repoSnapshotLoader = repoSnapshotLoader
        self.environmentScanner = environmentScanner
        self.driftEngine = driftEngine
        self.machineSummaryProvider = machineSummaryProvider

        machineSummary = machineSummaryProvider()
        if let initialMachineInfo {
            machineInfo = initialMachineInfo
        } else {
            machineInfo = MachineInfoCollector().collect()
        }
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        exportPath = desktop.appendingPathComponent("MacDevEnvExport").path
    }

    func chooseWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            workspacePath = url.path
            Task {
                await connectWorkspace(at: url)
            }
        }
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

    func connectWorkspace(at url: URL) async {
        workspacePath = url.path
        statusMessage = "Workspace scan running..."
        isRunning = true
        defer { isRunning = false }

        do {
            var workspace = try workspaceDetector.detect(at: url)
            let repoSnapshot = try repoSnapshotLoader.load(from: workspace)
            let environmentSnapshot = environmentScanner.scan()
            let driftItems = driftEngine.compare(repo: repoSnapshot, local: environmentSnapshot)
            workspace.lastScannedAt = Date()

            connectedWorkspace = workspace
            self.repoSnapshot = repoSnapshot
            self.environmentSnapshot = environmentSnapshot
            self.driftItems = driftItems
            manualTasks = []
            preflightChecks = []
            machineSummary = machineSummaryProvider()

            workspaceScanSummary = markdownWriter.renderWorkspaceScanSummary(
                workspace: workspace,
                repoSnapshot: repoSnapshot,
                environmentSnapshot: environmentSnapshot
            )
            workspaceDriftSummary = markdownWriter.renderWorkspaceDriftSummary(
                driftItems: driftItems,
                manualTasks: manualTasks,
                generatedAt: workspace.lastScannedAt ?? Date()
            )
            workspaceApplySummary = makeWorkspacePreviewSummary(
                title: "Workspace Apply Preview",
                resolution: .apply,
                driftItems: driftItems
            )
            workspacePromoteSummary = makeWorkspacePreviewSummary(
                title: "Workspace Promote Preview",
                resolution: .promote,
                driftItems: driftItems
            )
            statusMessage = driftItems.isEmpty ? "Workspace scan completed" : "Workspace scan completed with drift"
        } catch {
            connectedWorkspace = nil
            repoSnapshot = nil
            environmentSnapshot = nil
            driftItems = []
            workspaceScanSummary = "No workspace scan executed"
            workspaceDriftSummary = "No workspace drift computed"
            workspaceApplySummary = "No workspace apply preview"
            workspacePromoteSummary = "No workspace promote preview"
            statusMessage = "Workspace scan failed: \(error.localizedDescription)"
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

    private func makeWorkspacePreviewSummary(
        title: String,
        resolution: DriftResolution,
        driftItems: [DriftItem]
    ) -> String {
        let selectedItems = driftItems.filter { $0.suggestedResolutions.contains(resolution) }
        var lines: [String] = []
        lines.append("# \(title)")
        lines.append("")
        lines.append("Ready items: \(selectedItems.count)")
        lines.append("")
        if selectedItems.isEmpty {
            lines.append("- (none)")
        } else {
            for item in selectedItems.sorted(by: { $0.identifier < $1.identifier }) {
                lines.append("- \(item.identifier) [\(item.status.rawValue)]")
            }
        }
        return lines.joined(separator: "\n")
    }
}
