#if canImport(XCTest)
import XCTest
@testable import SharedModels
@testable import Core
@testable import Reporting

final class CoreBehaviorTests: XCTestCase {
    func testRestorePlanOrdering() {
        let items = [
            ManifestItem(id: "vscode.ext", kind: .vscodeExtension, title: "ext", restorePhase: .ide, payload: [:], secret: false),
            ManifestItem(id: "dotfile.zshrc", kind: .dotfile, title: "zshrc", restorePhase: .config, payload: [:], secret: false),
            ManifestItem(id: "brew.formula.git", kind: .brewFormula, title: "git", restorePhase: .packages, payload: [:], secret: false)
        ]

        let plan = RestorePlanBuilder().build(items: items)
        XCTAssertEqual(plan.map(\.phase), [.preflight, .bootstrap, .packages, .config, .ide, .manual, .verify])
        XCTAssertEqual(plan.first(where: { $0.phase == .verify })?.itemIds.sorted(), items.map(\.id).sorted())
    }

    func testDotfileBackupNaming() {
        let date = Date(timeIntervalSince1970: 1_735_872_123)
        let backup = BackupNamer.backupURL(for: URL(fileURLWithPath: "/Users/test/.zshrc"), timestamp: date)
        XCTAssertTrue(backup.path.hasPrefix("/Users/test/.zshrc.bak."))
        XCTAssertTrue(backup.lastPathComponent.contains(".bak."))
    }

    func testPathNormalization() {
        let expanded = PathNormalizer.expandTilde("~/.config/starship.toml", homeDirectory: "/Users/test")
        XCTAssertEqual(expanded, "/Users/test/.config/starship.toml")

        let collapsed = PathNormalizer.collapseHome("/Users/test/.zshrc", homeDirectory: "/Users/test")
        XCTAssertEqual(collapsed, "~/.zshrc")

        let relative = PathNormalizer.normalizedDotfileRelativePath("~/.config/starship.toml", homeDirectory: "/Users/test")
        XCTAssertEqual(relative, ".config/starship.toml")
    }

    func testManualTaskGeneration() {
        let engine = ManualTaskEngine()
        let brewTask = engine.taskForMissingBrew()
        XCTAssertTrue(brewTask.blocking)
        XCTAssertEqual(brewTask.id, "manual.install.homebrew")

        let archTask = engine.taskForArchitectureMismatch(source: .arm64, target: .x86_64)
        XCTAssertFalse(archTask.blocking)
        XCTAssertTrue(archTask.reason.contains("arm64"))
        XCTAssertTrue(archTask.reason.contains("x86_64"))
    }

    func testReportGenerationIncludesSections() {
        let report = OperationReport(
            title: "Verify Summary",
            successes: [StepResult(id: "1", title: "A", status: .success, detail: "ok")],
            failures: [StepResult(id: "2", title: "B", status: .failed, detail: "fail")],
            skipped: [StepResult(id: "3", title: "C", status: .skipped, detail: "skip")],
            warnings: ["warn"],
            manualTasks: [ManualTask(id: "m1", title: "Manual", reason: "r", action: "a", blocking: false)]
        )

        let markdown = MarkdownReportWriter().renderOperationReport(report)
        XCTAssertTrue(markdown.contains("## Success"))
        XCTAssertTrue(markdown.contains("## Failed"))
        XCTAssertTrue(markdown.contains("## Manual Follow-up"))
        XCTAssertTrue(markdown.contains("Manual"))
    }
}
#endif
