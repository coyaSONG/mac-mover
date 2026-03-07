import Foundation
import SharedModels

public struct MarkdownReportWriter {
    public init() {}

    public func renderPreflight(_ result: PreflightResult) -> String {
        var lines: [String] = []
        lines.append("# Preflight")
        lines.append("")
        lines.append("- Host: \(result.machine.hostname)")
        lines.append("- Architecture: \(result.machine.architecture.rawValue)")
        lines.append("- macOS: \(result.machine.macosVersion)")
        lines.append("- Home: \(result.machine.homeDirectory)")
        lines.append("")
        lines.append("## Checks")

        for check in result.checks {
            let icon = check.passed ? "[OK]" : (check.blocking ? "[BLOCK]" : "[WARN]")
            lines.append("- \(icon) \(check.title): \(check.detail)")
        }

        return lines.joined(separator: "\n")
    }

    public func renderOperationReport(_ report: OperationReport) -> String {
        var lines: [String] = []
        lines.append("# \(report.title)")
        lines.append("")
        lines.append("Generated at: \(ISO8601DateFormatter().string(from: report.generatedAt))")
        lines.append("")

        lines.append("## Success")
        if report.successes.isEmpty {
            lines.append("- (none)")
        } else {
            report.successes.forEach { lines.append("- \($0.title): \($0.detail)") }
        }

        lines.append("")
        lines.append("## Failed")
        if report.failures.isEmpty {
            lines.append("- (none)")
        } else {
            report.failures.forEach { lines.append("- \($0.title): \($0.detail)") }
        }

        lines.append("")
        lines.append("## Skipped")
        if report.skipped.isEmpty {
            lines.append("- (none)")
        } else {
            report.skipped.forEach { lines.append("- \($0.title): \($0.detail)") }
        }

        lines.append("")
        lines.append("## Warnings")
        if report.warnings.isEmpty {
            lines.append("- (none)")
        } else {
            report.warnings.forEach { lines.append("- \($0)") }
        }

        lines.append("")
        lines.append("## Manual Follow-up")
        if report.manualTasks.isEmpty {
            lines.append("- (none)")
        } else {
            report.manualTasks.forEach {
                lines.append("- \($0.title) [blocking: \($0.blocking ? "yes" : "no")]")
                lines.append("  - reason: \($0.reason)")
                lines.append("  - action: \($0.action)")
            }
        }

        return lines.joined(separator: "\n")
    }

    public func renderWorkspaceScanSummary(
        workspace: ConnectedWorkspace,
        repoSnapshot: RepoSnapshot,
        environmentSnapshot: EnvironmentSnapshot
    ) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append("# Workspace Scan Summary")
        lines.append("")
        lines.append("Generated at: \(formatter.string(from: workspace.lastScannedAt ?? environmentSnapshot.capturedAt ?? repoSnapshot.capturedAt ?? Date()))")
        lines.append("")
        lines.append("- Workspace root: \(workspace.rootPath)")
        lines.append("- Detected tools: \(workspace.detectedTools.map { $0.rawValue }.sorted().joined(separator: ", "))")
        lines.append("- Repo items: \(repoSnapshot.items.count)")
        lines.append("- Local items: \(environmentSnapshot.items.count)")
        lines.append("")
        lines.append("## Repo Categories")
        appendWorkspaceCategoryCounts(from: repoSnapshot.items, into: &lines)
        lines.append("")
        lines.append("## Local Categories")
        appendWorkspaceCategoryCounts(from: environmentSnapshot.items, into: &lines)
        return lines.joined(separator: "\n")
    }

    public func renderWorkspaceDriftSummary(
        driftItems: [DriftItem],
        manualTasks: [ManualTask],
        generatedAt: Date = Date()
    ) -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append("# Workspace Drift Summary")
        lines.append("")
        lines.append("Generated at: \(formatter.string(from: generatedAt))")
        lines.append("")

        for status in [DriftStatus.modified, .missing, .extra, .manual, .unsupported] {
            let matchingItems = driftItems.filter { $0.status == status }
            lines.append("## \(sectionTitle(for: status))")
            if matchingItems.isEmpty {
                lines.append("- (none)")
            } else {
                for item in matchingItems.sorted(by: driftSort) {
                    let resolutions = item.suggestedResolutions.map { $0.rawValue }.joined(separator: ", ")
                    if resolutions.isEmpty {
                        lines.append("- \(item.identifier)")
                    } else {
                        lines.append("- \(item.identifier) [\(resolutions)]")
                    }
                }
            }
            lines.append("")
        }

        appendManualTasksSection(manualTasks, into: &lines)
        return lines.joined(separator: "\n")
    }

    private func appendWorkspaceCategoryCounts(from items: [WorkspaceItem], into lines: inout [String]) {
        if items.isEmpty {
            lines.append("- (none)")
            return
        }

        let grouped = Dictionary(grouping: items, by: \.category)
        for category in WorkspaceItemCategory.allCases {
            guard let count = grouped[category]?.count else {
                continue
            }
            lines.append("- \(category.rawValue): \(count)")
        }
    }

    private func appendManualTasksSection(_ manualTasks: [ManualTask], into lines: inout [String]) {
        lines.append("## Manual Follow-up")
        if manualTasks.isEmpty {
            lines.append("- (none)")
        } else {
            manualTasks.forEach {
                lines.append("- \($0.title) [blocking: \($0.blocking ? "yes" : "no")]")
                lines.append("  - reason: \($0.reason)")
                lines.append("  - action: \($0.action)")
            }
        }
    }

    private func sectionTitle(for status: DriftStatus) -> String {
        switch status {
        case .modified:
            return "Modified"
        case .missing:
            return "Missing"
        case .extra:
            return "Extra"
        case .manual:
            return "Manual"
        case .unsupported:
            return "Unsupported"
        }
    }

    private func driftSort(lhs: DriftItem, rhs: DriftItem) -> Bool {
        if lhs.category == rhs.category {
            return lhs.identifier < rhs.identifier
        }
        return lhs.category.rawValue < rhs.category.rawValue
    }
}
