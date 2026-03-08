import Foundation
import Testing
@testable import Localization
@testable import SharedModels
@testable import Reporting
@testable import Core

struct WorkspaceReportTests {
    @Test
    func rendersWorkspaceScanSummaryWithDetectedToolsAndCounts() {
        let writer = MarkdownReportWriter(locale: Locale(identifier: "en"))
        let workspace = ConnectedWorkspace(
            rootPath: "/tmp/dev-env-repo",
            detectedTools: [.chezmoi, .homebrew, .plainDotfiles],
            lastScannedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let repoSnapshot = RepoSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_700_000_010),
            items: [
                WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("repo")),
                WorkspaceItem(category: .gitGlobal, identifier: "user.email", value: .string("repo")),
                WorkspaceItem(category: .toolVersions, identifier: "node", value: .string("22.0.0"))
            ]
        )
        let environmentSnapshot = EnvironmentSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_700_000_020),
            items: [
                WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("local")),
                WorkspaceItem(category: .gitGlobal, identifier: "user.email", value: .string("local")),
                WorkspaceItem(category: .toolVersions, identifier: "node", value: .string("22.0.0")),
                WorkspaceItem(category: .vscode, identifier: "settings.json", value: .string("hash"))
            ]
        )

        let markdown = writer.renderWorkspaceScanSummary(
            workspace: workspace,
            repoSnapshot: repoSnapshot,
            environmentSnapshot: environmentSnapshot
        )

        #expect(markdown.contains("# Workspace Scan Summary"))
        #expect(markdown.contains("/tmp/dev-env-repo"))
        #expect(markdown.contains("chezmoi"))
        #expect(markdown.contains("Homebrew"))
        #expect(!markdown.contains("homebrew"))
        #expect(markdown.contains("Plain Dotfiles"))
        #expect(!markdown.contains("plain_dotfiles"))
        #expect(markdown.contains("Git Global"))
        #expect(!markdown.contains("git_global"))
        #expect(markdown.contains("Tool Versions"))
        #expect(!markdown.contains("tool_versions"))
        #expect(markdown.contains("Repo items: 3"))
        #expect(markdown.contains("Local items: 4"))
    }

    @Test
    func rendersWorkspaceDriftSummaryWithStatusSectionsAndManualTasks() {
        let writer = MarkdownReportWriter(locale: Locale(identifier: "en"))
        let driftItems = [
            DriftItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                repoValue: .string("repo-hash"),
                localValue: .string("local-hash"),
                status: .modified,
                suggestedResolutions: [.apply, .promote]
            ),
            DriftItem(
                category: .homebrew,
                identifier: "wget",
                repoValue: .string("brew"),
                localValue: nil,
                status: .missing,
                suggestedResolutions: [.apply]
            ),
            DriftItem(
                category: .vscode,
                identifier: "settings.json",
                repoValue: nil,
                localValue: .string("hash"),
                status: .extra,
                suggestedResolutions: [.promote, .ignore]
            )
        ]
        let manualTasks = [
            ManualTask(
                id: "manual.secret.npmrc",
                title: "Secret item requires manual transfer",
                reason: "Security policy excluded ~/.npmrc from automatic transfer.",
                action: "Transfer it manually via a secure channel if needed.",
                blocking: false
            )
        ]

        let markdown = writer.renderWorkspaceDriftSummary(
            driftItems: driftItems,
            manualTasks: manualTasks,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_030)
        )

        #expect(markdown.contains("# Workspace Drift Summary"))
        #expect(markdown.contains("## Modified"))
        #expect(markdown.contains("## Missing"))
        #expect(markdown.contains("## Extra"))
        #expect(markdown.contains("[Apply, Promote]"))
        #expect(markdown.contains("[Promote, Ignore]"))
        #expect(!markdown.contains("[apply, promote]"))
        #expect(!markdown.contains("[promote, ignore]"))
        #expect(markdown.contains("~/.zshrc"))
        #expect(markdown.contains("wget"))
        #expect(markdown.contains("settings.json"))
        #expect(markdown.contains("## Manual Follow-up"))
        #expect(markdown.contains("~/.npmrc"))
    }

    @Test
    func rendersWorkspaceDriftSummaryInKorean() {
        let writer = MarkdownReportWriter(locale: Locale(identifier: "ko"))

        let markdown = writer.renderWorkspaceDriftSummary(
            driftItems: [],
            manualTasks: [],
            generatedAt: Date(timeIntervalSince1970: 1_700_000_030)
        )

        #expect(markdown.contains("## 수정됨"))
        #expect(markdown.contains("## 수동 후속 작업"))
    }

    @Test
    func writesWorkspaceScanAndDriftReportsToDisk() throws {
        let fileSystem = InMemoryFileSystem(directories: ["/tmp/reports"])
        let writer = ReportFileWriter(
            fileSystem: fileSystem,
            markdownWriter: MarkdownReportWriter(locale: Locale(identifier: "en"))
        )
        let workspace = ConnectedWorkspace(rootPath: "/tmp/dev-env-repo", detectedTools: [.plainDotfiles])
        let repoSnapshot = RepoSnapshot(items: [WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("repo"))])
        let environmentSnapshot = EnvironmentSnapshot(items: [WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("local"))])
        let driftItems = [
            DriftItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                repoValue: .string("repo"),
                localValue: .string("local"),
                status: .modified,
                suggestedResolutions: [.apply, .promote]
            )
        ]

        let scanURL = URL(fileURLWithPath: "/tmp/reports/scan-summary.md")
        let driftURL = URL(fileURLWithPath: "/tmp/reports/drift-summary.md")

        try writer.writeWorkspaceScanSummary(
            workspace: workspace,
            repoSnapshot: repoSnapshot,
            environmentSnapshot: environmentSnapshot,
            to: scanURL
        )
        try writer.writeWorkspaceDriftSummary(
            driftItems: driftItems,
            manualTasks: [],
            to: driftURL
        )

        let scanMarkdown = try String(decoding: fileSystem.readData(at: scanURL), as: UTF8.self)
        let driftMarkdown = try String(decoding: fileSystem.readData(at: driftURL), as: UTF8.self)

        #expect(scanMarkdown.contains("# Workspace Scan Summary"))
        #expect(driftMarkdown.contains("# Workspace Drift Summary"))
        #expect(driftMarkdown.contains("~/.zshrc"))
    }
}
