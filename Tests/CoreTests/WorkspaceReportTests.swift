import Foundation
import Testing
@testable import SharedModels
@testable import Reporting
@testable import Core

struct WorkspaceReportTests {
    @Test
    func rendersWorkspaceScanSummaryWithDetectedToolsAndCounts() {
        let writer = MarkdownReportWriter()
        let workspace = ConnectedWorkspace(
            rootPath: "/tmp/dev-env-repo",
            detectedTools: [.chezmoi, .homebrew, .vscode],
            lastScannedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let repoSnapshot = RepoSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_700_000_010),
            items: [
                WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("repo")),
                WorkspaceItem(category: .homebrew, identifier: "git", value: .string("brew"))
            ]
        )
        let environmentSnapshot = EnvironmentSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_700_000_020),
            items: [
                WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("local")),
                WorkspaceItem(category: .homebrew, identifier: "git", value: .string("brew")),
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
        #expect(markdown.contains("homebrew"))
        #expect(markdown.contains("vscode"))
        #expect(markdown.contains("Repo items: 2"))
        #expect(markdown.contains("Local items: 3"))
    }

    @Test
    func rendersWorkspaceDriftSummaryWithStatusSectionsAndManualTasks() {
        let writer = MarkdownReportWriter()
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
        #expect(markdown.contains("~/.zshrc"))
        #expect(markdown.contains("wget"))
        #expect(markdown.contains("settings.json"))
        #expect(markdown.contains("## Manual Follow-up"))
        #expect(markdown.contains("~/.npmrc"))
    }

    @Test
    func writesWorkspaceScanAndDriftReportsToDisk() throws {
        let fileSystem = InMemoryFileSystem(directories: ["/tmp/reports"])
        let writer = ReportFileWriter(fileSystem: fileSystem)
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
