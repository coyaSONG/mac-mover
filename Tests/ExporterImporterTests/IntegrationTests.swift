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
        XCTAssertTrue(markdown.contains("git"))
        XCTAssertTrue(markdown.contains("iterm2"))
        XCTAssertTrue(markdown.contains("postgresql"))

        let gitResult = GitGlobalExporter(runner: runner, manualTaskEngine: ManualTaskEngine()).export()
        XCTAssertEqual(gitResult.items.count, 2)
        XCTAssertTrue(gitResult.items.contains(where: { $0.id == "git.global.user.email" }))
    }

    func testGitImportCreatesBackupAndManualTaskBeforeOverwrite() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let gitConfigPath = homeDirectory + "/.gitconfig"
        let bundleURL = URL(fileURLWithPath: "/tmp/git-import-bundle")
        let fileSystem = InMemoryFileSystem(
            files: [
                gitConfigPath: Data("[user]\n\tname = Old Name\n".utf8)
            ],
            directories: [
                bundleURL.path,
                homeDirectory
            ]
        )
        let manifest = Manifest(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            machine: MachineInfo(
                hostname: "source-host",
                architecture: .arm64,
                macosVersion: "15.3",
                homeDirectory: homeDirectory,
                homebrewPrefix: "/opt/homebrew",
                userName: "tester"
            ),
            items: [
                ManifestItem(
                    id: "git.global.user.email",
                    kind: .gitGlobal,
                    title: "git user.email",
                    restorePhase: .config,
                    source: ItemSource(path: "~/.gitconfig"),
                    payload: ["key": .string("user.email"), "value": .string("new@example.com")],
                    secret: false
                )
            ],
            restorePlan: [
                RestoreStep(phase: .config, itemIds: ["git.global.user.email"]),
                RestoreStep(phase: .verify, itemIds: ["git.global.user.email"])
            ],
            reports: ManifestReports(exportSummaryPath: "reports/export-summary.md", verifySummaryPath: "reports/verify-summary.md")
        )
        let store = ManifestStore(fileSystem: fileSystem)
        try store.write(manifest, to: BundleLayout(root: bundleURL).manifestURL)

        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "git"], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "git"], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "user.email", "new@example.com"], result: .success(.init(executable: "/usr/bin/env", arguments: ["git", "config", "--global", "user.email", "new@example.com"], exitCode: 0, stdout: "", stderr: "")))
        ])

        let coordinator = ImportCoordinator(
            runner: runner,
            fileSystem: fileSystem,
            manifestStore: store
        )

        let result = try coordinator.import(from: bundleURL)
        let backupPaths = fileSystem.snapshotFiles().keys.filter { $0.hasPrefix(gitConfigPath + ".bak.") }

        XCTAssertEqual(backupPaths.count, 1)
        XCTAssertTrue(result.importReport.manualTasks.contains(where: { $0.id.contains("manual.overwrite") && $0.reason.contains(".gitconfig") }))
        XCTAssertTrue(result.importReport.successes.contains(where: { $0.id == "git.global.user.email" && $0.detail.contains("backup") }))
    }

    func testVSCodeExporterCopiesFilesAndExtensions() throws {
        let homeDirectory = "/Users/test"
        let userDirectory = homeDirectory + "/Library/Application Support/Code/User"
        let fileSystem = InMemoryFileSystem(
            files: [
                userDirectory + "/settings.json": Data("{\"editor.fontSize\":14}".utf8),
                userDirectory + "/keybindings.json": Data("[]".utf8),
                userDirectory + "/snippets/javascript.json": Data("{\"log\":{\"prefix\":\"log\"}}".utf8)
            ],
            directories: [
                homeDirectory,
                userDirectory,
                userDirectory + "/snippets"
            ]
        )
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "code"], exitCode: 0, stdout: "/usr/local/bin/code\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["code", "--list-extensions", "--show-versions"], result: .success(.init(executable: "/usr/bin/env", arguments: ["code", "--list-extensions", "--show-versions"], exitCode: 0, stdout: "ms-python.python@2026.1.0\nritwickdey.liveserver\n", stderr: "")))
        ])
        let exporter = VSCodeExporter(
            runner: runner,
            fileSystem: fileSystem,
            manualTaskEngine: ManualTaskEngine(),
            homeDirectory: homeDirectory
        )
        let bundleURL = URL(fileURLWithPath: "/tmp/vscode-export-bundle")
        let layout = BundleLayout(root: bundleURL)

        let result = exporter.export(to: layout)
        let files = fileSystem.snapshotFiles()

        XCTAssertTrue(files.keys.contains(layout.vscodeSettingsURL.path))
        XCTAssertTrue(files.keys.contains(layout.vscodeKeybindingsURL.path))
        XCTAssertTrue(files.keys.contains(layout.vscodeSnippetsDirectory.appendingPathComponent("javascript.json").path))
        XCTAssertEqual(result.items.filter { $0.kind == .vscodeSettings }.count, 3)
        XCTAssertEqual(result.items.filter { $0.kind == .vscodeExtension }.count, 2)
        XCTAssertTrue(result.successes.contains(where: { $0.id == "vscode.extensions" }))
        XCTAssertEqual(
            result.items.first(where: { $0.id == "vscode.extension.ritwickdey.liveserver" })?.payload["version"]?.stringValue,
            "unknown"
        )
    }

    func testVSCodeImportRestoresFilesAndExtensions() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let bundleURL = URL(fileURLWithPath: "/tmp/vscode-import-bundle")
        let layout = BundleLayout(root: bundleURL)
        let fileSystem = InMemoryFileSystem(
            files: [
                layout.vscodeSettingsURL.path: Data("{\"files.trimTrailingWhitespace\":true}".utf8),
                layout.vscodeSnippetsDirectory.appendingPathComponent("javascript.json").path: Data("{\"log\":{\"prefix\":\"log\"}}".utf8)
            ],
            directories: [
                bundleURL.path,
                layout.filesDirectory.path,
                layout.vscodeDirectory.path,
                layout.vscodeSnippetsDirectory.path,
                homeDirectory,
                "/Applications/Visual Studio Code.app"
            ]
        )
        let manifest = Manifest(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            machine: MachineInfo(
                hostname: "source-host",
                architecture: .arm64,
                macosVersion: "15.3",
                homeDirectory: homeDirectory,
                homebrewPrefix: "/opt/homebrew",
                userName: "tester"
            ),
            items: [
                ManifestItem(
                    id: "vscode.settings",
                    kind: .vscodeSettings,
                    title: "VS Code settings",
                    restorePhase: .ide,
                    source: ItemSource(path: "~/Library/Application Support/Code/User/settings.json"),
                    payload: ["relativePath": .string("files/vscode/settings.json")],
                    secret: false
                ),
                ManifestItem(
                    id: "vscode.snippets",
                    kind: .vscodeSettings,
                    title: "VS Code snippets",
                    restorePhase: .ide,
                    source: ItemSource(path: "~/Library/Application Support/Code/User/snippets"),
                    payload: ["relativePath": .string("files/vscode/snippets")],
                    secret: false
                ),
                ManifestItem(
                    id: "vscode.extension.ms-python.python",
                    kind: .vscodeExtension,
                    title: "ms-python.python",
                    restorePhase: .ide,
                    payload: ["identifier": .string("ms-python.python"), "version": .string("2026.1.0")],
                    secret: false
                )
            ],
            restorePlan: [
                RestoreStep(phase: .ide, itemIds: ["vscode.settings", "vscode.snippets", "vscode.extension.ms-python.python"]),
                RestoreStep(phase: .verify, itemIds: ["vscode.settings", "vscode.snippets", "vscode.extension.ms-python.python"])
            ],
            reports: ManifestReports(exportSummaryPath: "reports/export-summary.md", verifySummaryPath: "reports/verify-summary.md")
        )
        let store = ManifestStore(fileSystem: fileSystem)
        try store.write(manifest, to: layout.manifestURL)

        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "code"], exitCode: 0, stdout: "/usr/local/bin/code\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "code"], exitCode: 0, stdout: "/usr/local/bin/code\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["code", "--install-extension", "ms-python.python@2026.1.0", "--force"], result: .success(.init(executable: "/usr/bin/env", arguments: ["code", "--install-extension", "ms-python.python@2026.1.0", "--force"], exitCode: 0, stdout: "", stderr: "")))
        ])

        let coordinator = ImportCoordinator(
            runner: runner,
            fileSystem: fileSystem,
            manifestStore: store
        )
        let result = try coordinator.import(from: bundleURL)
        let restoredSettings = homeDirectory + "/Library/Application Support/Code/User/settings.json"
        let restoredSnippet = homeDirectory + "/Library/Application Support/Code/User/snippets/javascript.json"

        XCTAssertTrue(fileSystem.fileExists(at: URL(fileURLWithPath: restoredSettings)))
        XCTAssertTrue(fileSystem.fileExists(at: URL(fileURLWithPath: restoredSnippet)))
        XCTAssertTrue(result.importReport.successes.contains(where: { $0.id == "vscode.settings" }))
        XCTAssertTrue(result.importReport.successes.contains(where: { $0.id == "vscode.snippets" }))
        XCTAssertTrue(result.importReport.successes.contains(where: { $0.id == "vscode.extension.ms-python.python" }))
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

    func testVerifyEngineSucceedsForBrewAndVSCodeItems() {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/usr/bin/env", arguments: ["brew", "list", "--formula"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "list", "--formula"], exitCode: 0, stdout: "git\npython\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["code", "--list-extensions", "--show-versions"], result: .success(.init(executable: "/usr/bin/env", arguments: ["code", "--list-extensions", "--show-versions"], exitCode: 0, stdout: "ms-python.python@2026.1.0\n", stderr: "")))
        ])
        let engine = VerifyEngine(fileSystem: InMemoryFileSystem(), runner: runner)
        let items = [
            ManifestItem(
                id: "brew.formula.git",
                kind: .brewFormula,
                title: "git",
                restorePhase: .verify,
                payload: [:],
                secret: false,
                verify: VerifySpec(command: "brew list --formula", expectedValue: .string("git"))
            ),
            ManifestItem(
                id: "vscode.extension.ms-python.python",
                kind: .vscodeExtension,
                title: "ms-python.python",
                restorePhase: .verify,
                payload: [:],
                secret: false,
                verify: VerifySpec(command: "code --list-extensions --show-versions", expectedValue: .string("ms-python.python"))
            )
        ]

        let report = engine.verify(items: items, homeDirectory: "/Users/test")

        XCTAssertEqual(report.successes.count, 2)
        XCTAssertTrue(report.failures.isEmpty)
    }
}
#endif
