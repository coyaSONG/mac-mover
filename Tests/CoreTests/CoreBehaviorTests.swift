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

        let secretTask = engine.taskForExcludedSecret("~/.ssh/id_ed25519")
        XCTAssertEqual(secretTask.title, "Secret item requires manual transfer")
        XCTAssertTrue(secretTask.reason.contains(".ssh"))

        let unsupportedTask = engine.taskForUnsupportedFile("~/Library/Application Support/Docker")
        XCTAssertEqual(unsupportedTask.title, "Unsupported file")
        XCTAssertTrue(unsupportedTask.reason.contains("Docker"))

        let overwriteTask = engine.taskForOverwriteConfirmation("~/.gitconfig")
        XCTAssertEqual(overwriteTask.title, "Overwrite backup created")
        XCTAssertTrue(overwriteTask.reason.contains(".gitconfig"))
    }

    func testPreflightChecksIncludeBrewPrefixAndWriteability() {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], exitCode: 0, stdout: "/opt/homebrew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "git"], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "code"], exitCode: 0, stdout: "/usr/local/bin/code\n", stderr: "")))
        ])
        let fileSystem = InMemoryFileSystem(
            directories: [
                "/Users/test",
                "/Applications/Visual Studio Code.app"
            ]
        )
        let machineCollector = MachineInfoCollector(runner: runner)
        let service = PreflightService(runner: runner, fileSystem: fileSystem, machineCollector: machineCollector)

        let result = service.run(mode: .export(destination: URL(fileURLWithPath: "/tmp/export")))

        XCTAssertEqual(result.machine.homebrewPrefix, "/opt/homebrew")
        XCTAssertTrue(result.checks.contains(where: { $0.id == "preflight.brew-prefix" && $0.passed && $0.detail == "/opt/homebrew" }))
        XCTAssertTrue(result.checks.contains(where: { $0.id == "preflight.write" && $0.passed && $0.detail == "/tmp/export" }))
    }

    func testPreflightBrewPrefixFailsWhenPrefixLookupFails() {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], code: 1, stderr: "prefix unavailable"))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], code: 1, stderr: "prefix unavailable")))
        ])
        let fileSystem = InMemoryFileSystem(directories: ["/Users/test"])
        let machineCollector = MachineInfoCollector(runner: runner)
        let service = PreflightService(runner: runner, fileSystem: fileSystem, machineCollector: machineCollector)

        let result = service.run(mode: .export(destination: URL(fileURLWithPath: "/tmp/export")))

        XCTAssertTrue(result.checks.contains(where: { $0.id == "preflight.brew" && $0.passed }))
        XCTAssertTrue(result.checks.contains(where: { $0.id == "preflight.brew-prefix" && !$0.passed }))
    }

    func testRestoreFileCreatesBackupBeforeOverwrite() throws {
        let sourceURL = URL(fileURLWithPath: "/tmp/source/.zshrc")
        let destinationURL = URL(fileURLWithPath: "/Users/test/.zshrc")
        let fileSystem = InMemoryFileSystem(
            files: [
                sourceURL.path: Data("new-value".utf8),
                destinationURL.path: Data("old-value".utf8)
            ]
        )
        let restorer = FileRestorer(fileSystem: fileSystem)

        let backupURL = try restorer.restoreFile(
            from: sourceURL,
            to: destinationURL,
            timestamp: Date(timeIntervalSince1970: 1_735_872_123)
        )

        XCTAssertEqual(backupURL?.lastPathComponent, ".zshrc.bak.20250103-024203")
        XCTAssertEqual(String(data: try fileSystem.readData(at: destinationURL), encoding: .utf8), "new-value")
        XCTAssertEqual(String(data: try fileSystem.readData(at: backupURL!), encoding: .utf8), "old-value")
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
