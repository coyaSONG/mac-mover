import Foundation
import SwiftUI
import AppKit
import SharedModels
import Core
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

    @Published var lastExportBundleURL: URL?
    @Published var lastImportBundleURL: URL?

    private let preflightService = PreflightService()
    private let exportCoordinator = ExportCoordinator()
    private let importCoordinator = ImportCoordinator()

    init() {
        machineSummary = currentMachineSummary()
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
            do {
                let result = try exportCoordinator.export(to: destination)
                lastExportBundleURL = result.bundleURL
                manualTasks = result.manifest.manualTasks
                preflightChecks = result.preflight.checks
                exportSummary = readFile(at: destination.appendingPathComponent("reports/export-summary.md"))
                verifySummary = readFile(at: destination.appendingPathComponent("reports/verify-summary.md"))
                logsPreview = readLogPreview(at: destination.appendingPathComponent("logs"))
                machineSummary = currentMachineSummary()
                statusMessage = "Export completed"
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    func runImportPreflight(bundleURL: URL) {
        let preflight = preflightService.run(mode: .import(bundle: bundleURL))
        preflightChecks = preflight.checks
        machineSummary = currentMachineSummary()
    }

    func runImport() {
        guard !importPath.isEmpty else {
            statusMessage = "Select an import bundle first"
            return
        }

        let source = URL(fileURLWithPath: importPath)
        statusMessage = "Import running..."

        Task {
            do {
                let result = try importCoordinator.import(from: source)
                lastImportBundleURL = result.bundleURL
                manualTasks = result.importReport.manualTasks
                preflightChecks = result.preflight.checks
                importSummary = readFile(at: source.appendingPathComponent("reports/import-summary.md"))
                verifySummary = readFile(at: source.appendingPathComponent("reports/verify-summary.md"))
                logsPreview = readLogPreview(at: source.appendingPathComponent("logs"))
                statusMessage = "Import completed"
            } catch {
                statusMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func currentMachineSummary() -> String {
        let machine = MachineInfoCollector().collect()
        return "Host: \(machine.hostname)\nArchitecture: \(machine.architecture.rawValue)\nmacOS: \(machine.macosVersion)\nHome: \(machine.homeDirectory)\nBrew Prefix: \(machine.homebrewPrefix)"
    }

    private func readFile(at url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? "Not found: \(url.path)"
    }

    private func readLogPreview(at logsDirectory: URL) -> String {
        guard let files = try? FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil),
              let first = files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first,
              let content = try? String(contentsOf: first, encoding: .utf8)
        else {
            return "No logs"
        }
        return content
    }
}
