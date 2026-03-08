import Foundation
import SharedModels
#if canImport(Localization)
import Localization
#endif

public struct MarkdownReportWriter {
    private let locale: Locale?

    public init(locale: Locale? = nil) {
        self.locale = locale
    }

    public func renderPreflight(_ result: PreflightResult) -> String {
        var lines: [String] = []
        lines.append("# \(L10n.string(.reportPreflightTitle, locale: locale))")
        lines.append("")
        lines.append("- \(L10n.string(.labelHost, locale: locale)): \(result.machine.hostname)")
        lines.append("- \(L10n.string(.labelArchitecture, locale: locale)): \(result.machine.architecture.rawValue)")
        lines.append("- \(L10n.string(.labelMacOS, locale: locale)): \(result.machine.macosVersion)")
        lines.append("- \(L10n.string(.labelHome, locale: locale)): \(result.machine.homeDirectory)")
        lines.append("")
        lines.append("## \(L10n.string(.reportChecksTitle, locale: locale))")

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
        lines.append(L10n.format(.reportGeneratedAt, locale: locale, ISO8601DateFormatter().string(from: report.generatedAt)))
        lines.append("")

        lines.append("## \(L10n.string(.reportSuccessTitle, locale: locale))")
        if report.successes.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
        } else {
            report.successes.forEach { lines.append("- \($0.title): \($0.detail)") }
        }

        lines.append("")
        lines.append("## \(L10n.string(.reportFailedTitle, locale: locale))")
        if report.failures.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
        } else {
            report.failures.forEach { lines.append("- \($0.title): \($0.detail)") }
        }

        lines.append("")
        lines.append("## \(L10n.string(.reportSkippedTitle, locale: locale))")
        if report.skipped.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
        } else {
            report.skipped.forEach { lines.append("- \($0.title): \($0.detail)") }
        }

        lines.append("")
        lines.append("## \(L10n.string(.reportWarningsTitle, locale: locale))")
        if report.warnings.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
        } else {
            report.warnings.forEach { lines.append("- \($0)") }
        }

        lines.append("")
        lines.append("## \(L10n.string(.reportManualFollowUpTitle, locale: locale))")
        if report.manualTasks.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
        } else {
            report.manualTasks.forEach {
                let blockingValue = $0.blocking ? L10n.string(.reportBlockingYes, locale: locale) : L10n.string(.reportBlockingNo, locale: locale)
                lines.append("- \($0.title) [blocking: \(blockingValue)]")
                lines.append("  - \(L10n.string(.reportReasonLabel, locale: locale)): \($0.reason)")
                lines.append("  - \(L10n.string(.reportActionLabel, locale: locale)): \($0.action)")
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
        lines.append("# \(L10n.string(.repoWorkspaceScanSummaryTitle, locale: locale))")
        lines.append("")
        lines.append(L10n.format(.reportGeneratedAt, locale: locale, formatter.string(from: workspace.lastScannedAt ?? environmentSnapshot.capturedAt ?? repoSnapshot.capturedAt ?? Date())))
        lines.append("")
        lines.append("- \(L10n.format(.reportWorkspaceRoot, locale: locale, workspace.rootPath))")
        lines.append("- \(L10n.format(.reportDetectedTools, locale: locale, workspace.detectedTools.map(localizedToolName).sorted().joined(separator: ", ")))")
        lines.append("- \(L10n.format(.reportRepoItems, locale: locale, repoSnapshot.items.count))")
        lines.append("- \(L10n.format(.reportLocalItems, locale: locale, environmentSnapshot.items.count))")
        lines.append("")
        lines.append("## \(L10n.string(.reportRepoCategoriesTitle, locale: locale))")
        appendWorkspaceCategoryCounts(from: repoSnapshot.items, into: &lines)
        lines.append("")
        lines.append("## \(L10n.string(.reportLocalCategoriesTitle, locale: locale))")
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
        lines.append("# \(L10n.string(.driftWorkspaceSummaryTitle, locale: locale))")
        lines.append("")
        lines.append(L10n.format(.reportGeneratedAt, locale: locale, formatter.string(from: generatedAt)))
        lines.append("")

        for status in [DriftStatus.modified, .missing, .extra, .manual, .unsupported] {
            let matchingItems = driftItems.filter { $0.status == status }
            lines.append("## \(sectionTitle(for: status))")
            if matchingItems.isEmpty {
                lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
            } else {
                for item in matchingItems.sorted(by: driftSort) {
                    let resolutions = item.suggestedResolutions.map(localizedResolutionName).joined(separator: ", ")
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
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
            return
        }

        let grouped = Dictionary(grouping: items, by: \.category)
        for category in WorkspaceItemCategory.allCases {
            guard let count = grouped[category]?.count else {
                continue
            }
            lines.append("- \(localizedCategoryName(category)): \(count)")
        }
    }

    private func appendManualTasksSection(_ manualTasks: [ManualTask], into lines: inout [String]) {
        lines.append("## \(L10n.string(.reportManualFollowUpTitle, locale: locale))")
        if manualTasks.isEmpty {
            lines.append("- \(L10n.string(.placeholderNone, locale: locale))")
        } else {
            manualTasks.forEach {
                let blockingValue = $0.blocking ? L10n.string(.reportBlockingYes, locale: locale) : L10n.string(.reportBlockingNo, locale: locale)
                lines.append("- \($0.title) [blocking: \(blockingValue)]")
                lines.append("  - \(L10n.string(.reportReasonLabel, locale: locale)): \($0.reason)")
                lines.append("  - \(L10n.string(.reportActionLabel, locale: locale)): \($0.action)")
            }
        }
    }

    private func sectionTitle(for status: DriftStatus) -> String {
        switch status {
        case .modified:
            return L10n.string(.driftModified, locale: locale)
        case .missing:
            return L10n.string(.driftMissing, locale: locale)
        case .extra:
            return L10n.string(.driftExtra, locale: locale)
        case .manual:
            return L10n.string(.driftManual, locale: locale)
        case .unsupported:
            return L10n.string(.driftUnsupported, locale: locale)
        }
    }

    private func localizedToolName(_ tool: WorkspaceTool) -> String {
        switch tool {
        case .homebrew:
            return L10n.string(.workspaceToolHomebrew, locale: locale)
        case .chezmoi:
            return L10n.string(.workspaceToolChezmoi, locale: locale)
        case .plainDotfiles:
            return L10n.string(.workspaceToolPlainDotfiles, locale: locale)
        case .git:
            return L10n.string(.workspaceToolGit, locale: locale)
        case .vscode:
            return L10n.string(.workspaceToolVSCode, locale: locale)
        case .mise:
            return L10n.string(.workspaceToolMise, locale: locale)
        case .asdf:
            return L10n.string(.workspaceToolAsdf, locale: locale)
        }
    }

    private func localizedCategoryName(_ category: WorkspaceItemCategory) -> String {
        switch category {
        case .homebrew:
            return L10n.string(.workspaceCategoryHomebrew, locale: locale)
        case .dotfiles:
            return L10n.string(.workspaceCategoryDotfiles, locale: locale)
        case .gitGlobal:
            return L10n.string(.workspaceCategoryGitGlobal, locale: locale)
        case .vscode:
            return L10n.string(.workspaceCategoryVSCode, locale: locale)
        case .toolVersions:
            return L10n.string(.workspaceCategoryToolVersions, locale: locale)
        case .manual:
            return L10n.string(.workspaceCategoryManual, locale: locale)
        }
    }

    private func localizedResolutionName(_ resolution: DriftResolution) -> String {
        switch resolution {
        case .apply:
            return L10n.string(.workspaceResolutionApply, locale: locale)
        case .promote:
            return L10n.string(.workspaceResolutionPromote, locale: locale)
        case .ignore:
            return L10n.string(.workspaceResolutionIgnore, locale: locale)
        }
    }

    private func driftSort(lhs: DriftItem, rhs: DriftItem) -> Bool {
        if lhs.category == rhs.category {
            return lhs.identifier < rhs.identifier
        }
        return lhs.category.rawValue < rhs.category.rawValue
    }
}
