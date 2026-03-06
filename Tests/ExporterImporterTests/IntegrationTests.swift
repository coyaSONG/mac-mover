#if canImport(XCTest)
import XCTest
@testable import SharedModels
@testable import Core
@testable import Exporters
@testable import Importers
@testable import Reporting

final class IntegrationTests: XCTestCase {
    func testBrewAndGitParsersWithMockRunner() throws {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "bundle", "dump", "--force", "--file", "/tmp/bundle/Brewfile"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "list", "--formula"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "git\npython\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "list", "--cask"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "iterm2\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "tap"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "homebrew/cask\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "services", "list"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "Name Status User File\npostgresql started test ~/Library\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--list"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "user.name=Tester\nuser.email=test@example.com\n", stderr: "")))
        ])

        let fs = LocalFileSystem()
        let layoutRoot = URL(fileURLWithPath: "/tmp/bundle")
        try? fs.removeItem(at: layoutRoot)
        try fs.createDirectory(at: layoutRoot)
        let layout = BundleLayout(root: layoutRoot)

        let brewResult = HomebrewExporter(runner: runner, fileSystem: fs, manualTaskEngine: ManualTaskEngine()).export(to: layout)
        XCTAssertEqual(brewResult.items.filter { $0.kind == .brewFormula }.count, 2)
        XCTAssertEqual(brewResult.items.filter { $0.kind == .brewCask }.count, 1)
        XCTAssertEqual(brewResult.items.filter { $0.kind == .brewTap }.count, 1)
        XCTAssertEqual(brewResult.items.filter { $0.kind == .brewService }.count, 1)
        XCTAssertTrue(brewResult.successes.contains(where: { $0.id == "export.brew.brewfile" }))

        let exportReport = OperationReport(
            title: "Export Summary",
            successes: brewResult.successes,
            failures: brewResult.failures,
            skipped: brewResult.skipped,
            warnings: brewResult.warnings,
            manualTasks: brewResult.manualTasks
        )
        let markdown = MarkdownReportWriter().renderOperationReport(exportReport)
        XCTAssertTrue(markdown.contains("Brewfile"))

        let gitResult = GitGlobalExporter(runner: runner, manualTaskEngine: ManualTaskEngine()).export()
        XCTAssertEqual(gitResult.items.count, 2)
        XCTAssertTrue(gitResult.items.contains(where: { $0.id == "git.global.user.email" }))
    }

    func testVerifyEngineAndReportOnPartialFailure() {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "--get", "user.email"], result: .success(.init(executable: "/usr/bin/env", arguments: [], exitCode: 0, stdout: "wrong@example.com\n", stderr: "")))
        ])

        let fileSystem = InMemoryFileSystem(files: ["/Users/test/.zshrc": Data("ok".utf8)])
        let engine = VerifyEngine(fileSystem: fileSystem, runner: runner)

        let items = [
            ManifestItem(
                id: "dotfile.zshrc",
                kind: .dotfile,
                title: "~/.zshrc",
                restorePhase: .verify,
                payload: [:],
                secret: false,
                verify: VerifySpec(expectedFile: "~/.zshrc")
            ),
            ManifestItem(
                id: "git.global.user.email",
                kind: .gitGlobal,
                title: "git user.email",
                restorePhase: .verify,
                payload: ["key": .string("user.email")],
                secret: false,
                verify: VerifySpec(command: "git config --global --get user.email", expectedValue: .string("expected@example.com"))
            )
        ]

        let report = engine.verify(items: items, homeDirectory: "/Users/test")
        XCTAssertEqual(report.successes.count, 1)
        XCTAssertEqual(report.failures.count, 1)

        let markdown = MarkdownReportWriter().renderOperationReport(report)
        XCTAssertTrue(markdown.contains("## Failed"))
        XCTAssertTrue(markdown.contains("expected@example.com"))
    }
}
#endif
