import Foundation
import Testing
@testable import SharedModels

struct WorkspaceModelsTests {
    @Test
    func driftItemCapturesRepoAndLocalValues() throws {
        let item = DriftItem(
            category: .dotfiles,
            identifier: ".zshrc",
            repoValue: .string("repo"),
            localValue: .string("local"),
            status: .modified,
            suggestedResolutions: [.apply, .promote]
        )

        #expect(item.status == .modified)
        #expect(item.suggestedResolutions.contains(.apply))
        #expect(item.suggestedResolutions.contains(.promote))
    }

    @Test
    func workspaceScanResultCarriesSnapshotsAndReportDrift() throws {
        let workspace = ConnectedWorkspace(
            rootPath: "/Users/test/dev-env",
            detectedTools: [.chezmoi, .homebrew],
            lastScannedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let repoSnapshot = RepoSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
            items: [
                WorkspaceItem(category: .homebrew, identifier: "git", value: .string("present"))
            ]
        )
        let environmentSnapshot = EnvironmentSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_700_000_100),
            items: [
                WorkspaceItem(category: .homebrew, identifier: "git", value: .string("present"))
            ]
        )
        let report = OperationReport(
            title: "Scan",
            driftItems: [
                DriftItem(
                    category: .homebrew,
                    identifier: "wget",
                    repoValue: .string("present"),
                    localValue: nil,
                    status: .missing,
                    suggestedResolutions: [.apply]
                )
            ]
        )
        let result = WorkspaceScanResult(
            workspace: workspace,
            repoSnapshot: repoSnapshot,
            environmentSnapshot: environmentSnapshot,
            report: report
        )

        #expect(result.workspace.detectedTools == [.chezmoi, .homebrew])
        #expect(result.report.driftItems.count == 1)
        #expect(result.report.driftItems.first?.status == .missing)
    }
}
