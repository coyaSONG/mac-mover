import Foundation
import SwiftUI
import AppKit
#if canImport(Localization)
import Localization
#endif
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
    @Published var workspaceScanSummary: String = L10n.string(.placeholderNoWorkspaceScanExecuted)
    @Published var workspaceDriftSummary: String = L10n.string(.placeholderNoWorkspaceDriftComputed)
    @Published var workspaceApplySummary: String = L10n.string(.placeholderNoWorkspaceApplyPreview)
    @Published var workspacePromoteSummary: String = L10n.string(.placeholderNoWorkspacePromotePreview)
    @Published var exportPath: String = ""
    @Published var importPath: String = ""
    @Published var exportSummary: String = L10n.string(.placeholderNoExportExecuted)
    @Published var importSummary: String = L10n.string(.placeholderNoImportExecuted)
    @Published var verifySummary: String = L10n.string(.placeholderNoVerifyExecuted)
    @Published var manualTasks: [ManualTask] = []
    @Published var preflightChecks: [PreflightCheck] = []
    @Published var logsPreview: String = L10n.string(.placeholderNoLogs)
    @Published var statusMessage: String = L10n.string(.statusIdle)
    @Published var isRunning: Bool = false
    @Published private(set) var isWorkspaceScanRunning: Bool = false

    @Published var connectedWorkspace: ConnectedWorkspace?
    @Published var repoSnapshot: RepoSnapshot?
    @Published var environmentSnapshot: EnvironmentSnapshot?
    @Published var driftItems: [DriftItem] = []
    @Published var lastExportBundleURL: URL?
    @Published var lastImportBundleURL: URL?
    @Published private(set) var machineInfo: MachineInfo?

    var machineHost: String { machineInfo?.hostname ?? L10n.string(.labelUnknown) }
    var machineArch: String { machineInfo?.architecture.rawValue ?? L10n.string(.labelUnknown) }
    var machineOS: String { machineInfo?.macosVersion ?? L10n.string(.labelUnknown) }
    var machineHome: String { machineInfo?.homeDirectory ?? L10n.string(.labelUnknown) }
    var machineBrewPrefix: String { machineInfo?.homebrewPrefix ?? L10n.string(.labelUnknown) }
    var connectedWorkspaceToolSummary: String? {
        guard let connectedWorkspace else {
            return nil
        }

        let summary = connectedWorkspace.detectedTools.map(localizedToolName).sorted().joined(separator: ", ")
        return summary.isEmpty ? nil : summary
    }

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
        panel.prompt = L10n.string(.actionSelect)
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
        panel.prompt = L10n.string(.actionSelect)
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
        panel.prompt = L10n.string(.actionSelect)
        if panel.runModal() == .OK, let url = panel.url {
            importPath = url.path
            runImportPreflight(bundleURL: url)
        }
    }

    func connectWorkspace(at url: URL) async {
        workspacePath = url.path
        statusMessage = L10n.string(.statusWorkspaceScanRunning)
        isRunning = true
        isWorkspaceScanRunning = true
        defer {
            isRunning = false
            isWorkspaceScanRunning = false
        }

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
                title: L10n.string(.workspaceApplyPreviewTitle),
                resolution: .apply,
                driftItems: driftItems
            )
            workspacePromoteSummary = makeWorkspacePreviewSummary(
                title: L10n.string(.workspacePromotePreviewTitle),
                resolution: .promote,
                driftItems: driftItems
            )
            statusMessage = driftItems.isEmpty ? L10n.string(.statusWorkspaceScanCompleted) : L10n.string(.statusWorkspaceScanCompletedWithDrift)
        } catch {
            connectedWorkspace = nil
            repoSnapshot = nil
            environmentSnapshot = nil
            driftItems = []
            workspaceScanSummary = L10n.string(.placeholderNoWorkspaceScanExecuted)
            workspaceDriftSummary = L10n.string(.placeholderNoWorkspaceDriftComputed)
            workspaceApplySummary = L10n.string(.placeholderNoWorkspaceApplyPreview)
            workspacePromoteSummary = L10n.string(.placeholderNoWorkspacePromotePreview)
            statusMessage = L10n.format(.statusWorkspaceScanFailed, error.localizedDescription)
        }
    }

    func runExport() {
        let destination = URL(fileURLWithPath: exportPath)
        statusMessage = L10n.string(.statusExportRunning)

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
                statusMessage = L10n.string(.statusExportCompleted)
            } catch {
                statusMessage = L10n.format(.statusExportFailed, error.localizedDescription)
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
            statusMessage = preview.preflight.hasBlockingFailure ? L10n.string(.statusImportBundleBlockingPreflight) : L10n.string(.statusImportBundleReady)
        } catch {
            lastImportBundleURL = nil
            manualTasks = []
            preflightChecks = []
            exportSummary = L10n.string(.placeholderNoExportExecuted)
            importSummary = L10n.string(.placeholderNoImportExecuted)
            verifySummary = L10n.string(.placeholderNoVerifyExecuted)
            logsPreview = L10n.string(.placeholderNoLogs)
            machineSummary = machineSummaryProvider()
            statusMessage = L10n.format(.statusImportPreflightFailed, error.localizedDescription)
        }
    }

    func runImport() {
        guard !importPath.isEmpty else {
            statusMessage = L10n.string(.statusSelectImportBundleFirst)
            return
        }

        let source = URL(fileURLWithPath: importPath)
        statusMessage = L10n.string(.statusImportRunning)

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
                statusMessage = L10n.string(.statusImportCompleted)
            } catch {
                statusMessage = L10n.format(.statusImportFailed, error.localizedDescription)
            }
        }
    }

    func runVerify() {
        guard !importPath.isEmpty else {
            statusMessage = L10n.string(.statusSelectImportBundleFirst)
            return
        }

        let source = URL(fileURLWithPath: importPath)
        statusMessage = L10n.string(.statusVerifyRunning)

        Task {
            isRunning = true
            defer { isRunning = false }
            do {
                let manifest = try bundleValidator.validateBundle(at: source)
                let preflight = preflightService.run(mode: .import(bundle: source))
                preflightChecks = preflight.checks

                if preflight.hasBlockingFailure {
                    statusMessage = L10n.string(.statusVerifyBlockedByPreflight)
                    return
                }

                let report = verifyEngine.verify(items: manifest.items, homeDirectory: preflight.machine.homeDirectory)
                try reportWriter.writeReport(report, to: BundleLayout(root: source).verifySummaryURL)

                manualTasks = manifest.manualTasks
                verifySummary = artifactReader.readText(at: source.appendingPathComponent("reports/verify-summary.md"))
                logsPreview = artifactReader.readLogPreview(at: source.appendingPathComponent("logs"))
                statusMessage = report.failures.isEmpty ? L10n.string(.statusVerifyCompleted) : L10n.string(.statusVerifyCompletedWithFailures)
            } catch {
                statusMessage = L10n.format(.statusVerifyFailed, error.localizedDescription)
            }
        }
    }

    private static func buildMachineSummary() -> String {
        let machine = MachineInfoCollector().collect()
        return L10n.format(
            .machineSummaryFormat,
            machine.hostname,
            machine.architecture.rawValue,
            machine.macosVersion,
            machine.homeDirectory,
            machine.homebrewPrefix
        )
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
        lines.append(L10n.format(.workspacePreviewReadyItemsCount, selectedItems.count))
        lines.append("")
        if selectedItems.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone))")
        } else {
            for item in selectedItems.sorted(by: { $0.identifier < $1.identifier }) {
                lines.append("- \(item.identifier) [\(localizedDriftStatusLabel(for: item.status))]")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func localizedDriftStatusLabel(for status: DriftStatus) -> String {
        switch status {
        case .modified:
            return L10n.string(.driftModified)
        case .missing:
            return L10n.string(.driftMissing)
        case .extra:
            return L10n.string(.driftExtra)
        case .manual:
            return L10n.string(.driftManual)
        case .unsupported:
            return L10n.string(.driftUnsupported)
        }
    }

    private func localizedToolName(_ tool: WorkspaceTool) -> String {
        switch tool {
        case .homebrew:
            return L10n.string(.workspaceToolHomebrew)
        case .chezmoi:
            return L10n.string(.workspaceToolChezmoi)
        case .plainDotfiles:
            return L10n.string(.workspaceToolPlainDotfiles)
        case .git:
            return L10n.string(.workspaceToolGit)
        case .vscode:
            return L10n.string(.workspaceToolVSCode)
        case .mise:
            return L10n.string(.workspaceToolMise)
        case .asdf:
            return L10n.string(.workspaceToolAsdf)
        }
    }
}
