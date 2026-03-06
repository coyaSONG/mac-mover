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
}
