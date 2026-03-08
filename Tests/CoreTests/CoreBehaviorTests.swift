import Foundation
import Testing
@testable import Localization
@testable import SharedModels
@testable import Core
@testable import Reporting

@Suite("Core Behavior Tests")
struct CoreBehaviorTests {
    @Test("Restore plan ordering")
    func restorePlanOrdering() {
        let items = [
            ManifestItem(id: "vscode.ext", kind: .vscodeExtension, title: "ext", restorePhase: .ide, payload: [:], secret: false),
            ManifestItem(id: "dotfile.zshrc", kind: .dotfile, title: "zshrc", restorePhase: .config, payload: [:], secret: false),
            ManifestItem(id: "brew.formula.git", kind: .brewFormula, title: "git", restorePhase: .packages, payload: [:], secret: false)
        ]

        let plan = RestorePlanBuilder().build(items: items)
        #expect(plan.map(\.phase) == [.preflight, .bootstrap, .packages, .config, .ide, .manual, .verify])
        #expect(plan.first(where: { $0.phase == .verify })?.itemIds.sorted() == items.map(\.id).sorted())
    }

    @Test("Dotfile backup naming")
    func dotfileBackupNaming() {
        let date = Date(timeIntervalSince1970: 1_735_872_123)
        let backup = BackupNamer.backupURL(for: URL(fileURLWithPath: "/Users/test/.zshrc"), timestamp: date)

        #expect(backup.path.hasPrefix("/Users/test/.zshrc.bak."))
        #expect(backup.lastPathComponent.contains(".bak."))
    }

    @Test("Path normalization")
    func pathNormalization() {
        let expanded = PathNormalizer.expandTilde("~/.config/starship.toml", homeDirectory: "/Users/test")
        #expect(expanded == "/Users/test/.config/starship.toml")

        let collapsed = PathNormalizer.collapseHome("/Users/test/.zshrc", homeDirectory: "/Users/test")
        #expect(collapsed == "~/.zshrc")

        let relative = PathNormalizer.normalizedDotfileRelativePath("~/.config/starship.toml", homeDirectory: "/Users/test")
        #expect(relative == ".config/starship.toml")
    }

    @Test("Manual task generation")
    func manualTaskGeneration() {
        let engine = ManualTaskEngine()
        let brewTask = engine.taskForMissingBrew()
        #expect(brewTask.blocking)
        #expect(brewTask.id == "manual.install.homebrew")

        let archTask = engine.taskForArchitectureMismatch(source: .arm64, target: .x86_64)
        #expect(!archTask.blocking)
        #expect(archTask.reason.contains("arm64"))
        #expect(archTask.reason.contains("x86_64"))

        let secretTask = engine.taskForExcludedSecret("~/.ssh/id_ed25519")
        #expect(secretTask.title == "Secret item requires manual transfer")
        #expect(secretTask.reason.contains(".ssh"))

        let unsupportedTask = engine.taskForUnsupportedFile("~/Library/Application Support/Docker")
        #expect(unsupportedTask.title == "Unsupported file")
        #expect(unsupportedTask.reason.contains("Docker"))

        let overwriteTask = engine.taskForOverwriteConfirmation("~/.gitconfig")
        #expect(overwriteTask.title == "Overwrite backup created")
        #expect(overwriteTask.reason.contains(".gitconfig"))
    }

    @Test("Manual tasks and verify output can use Korean locale")
    func manualTasksAndVerifyOutputCanUseKoreanLocale() {
        let locale = Locale(identifier: "ko")
        let engine = ManualTaskEngine(locale: locale)
        let brewTask = engine.taskForMissingBrew()
        let verifyEngine = VerifyEngine(
            fileSystem: InMemoryFileSystem(files: ["/Users/test/.zshrc": Data()]),
            locale: locale
        )

        let report = verifyEngine.verify(
            items: [
                ManifestItem(
                    id: "dotfile.zshrc",
                    kind: .dotfile,
                    title: "~/.zshrc",
                    restorePhase: .verify,
                    payload: [:],
                    secret: false,
                    verify: VerifySpec(expectedFile: "~/.zshrc")
                )
            ],
            homeDirectory: "/Users/test"
        )

        #expect(brewTask.title == "Homebrew 설치 필요")
        #expect(brewTask.reason == "이 머신에는 Homebrew가 설치되어 있지 않습니다.")
        #expect(report.title == "검증 리포트")
        #expect(report.successes.first?.detail == "파일 존재: ~/.zshrc")
    }

    @Test("Preflight checks include Brew prefix and writeability")
    func preflightChecksIncludeBrewPrefixAndWriteability() {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], exitCode: 0, stdout: "/opt/homebrew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], exitCode: 0, stdout: "/opt/homebrew\n", stderr: ""))),
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

        #expect(result.machine.homebrewPrefix == "/opt/homebrew")
        #expect(result.checks.contains(where: { $0.id == "preflight.brew-prefix" && $0.passed && $0.detail == "/opt/homebrew" }))
        #expect(result.checks.contains(where: { $0.id == "preflight.write" && $0.passed && $0.detail == "/tmp/export" }))
    }

    @Test("Preflight Brew prefix fails when lookup fails")
    func preflightBrewPrefixFailsWhenPrefixLookupFails() {
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

        #expect(result.checks.contains(where: { $0.id == "preflight.brew" && $0.passed }))
        #expect(result.checks.contains(where: { $0.id == "preflight.brew-prefix" && !$0.passed }))
    }

    @Test("Preflight checks can use Korean locale")
    func preflightChecksCanUseKoreanLocale() {
        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["which", "brew"], code: 1, stderr: "not found"))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "git"], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .failure(MoverError.commandFailed(executable: "/usr/bin/env", arguments: ["which", "code"], code: 1, stderr: "not found")))
        ])
        let fileSystem = InMemoryFileSystem(directories: ["/Users/test"])
        let service = PreflightService(
            runner: runner,
            fileSystem: fileSystem,
            machineCollector: MachineInfoCollector(runner: runner),
            locale: Locale(identifier: "ko")
        )

        let result = service.run(mode: .export(destination: URL(fileURLWithPath: "/tmp/export")))

        #expect(result.checks.contains(where: { $0.id == "preflight.macos" && $0.title == "macOS 버전" }))
        #expect(result.checks.contains(where: { $0.id == "preflight.brew" && $0.detail == "brew 명령을 찾을 수 없습니다" }))
        #expect(result.checks.contains(where: { $0.id == "preflight.git" && $0.detail == "git 사용 가능" }))
    }

    @Test("Restore file creates backup before overwrite")
    func restoreFileCreatesBackupBeforeOverwrite() throws {
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
        let unwrappedBackupURL = try #require(backupURL)

        #expect(unwrappedBackupURL.lastPathComponent == ".zshrc.bak.20250103-024203")
        #expect(String(data: try fileSystem.readData(at: destinationURL), encoding: .utf8) == "new-value")
        #expect(String(data: try fileSystem.readData(at: unwrappedBackupURL), encoding: .utf8) == "old-value")
    }

    @Test("Bundle preview loads manual tasks reports and logs")
    func bundlePreviewLoadsManualTasksReportsAndLogs() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let bundleURL = URL(fileURLWithPath: "/tmp/preview-bundle")
        let layout = BundleLayout(root: bundleURL)
        let fileSystem = InMemoryFileSystem(
            files: [
                layout.reportsDirectory.appendingPathComponent("export-summary.md").path: Data("# Export\n".utf8),
                layout.reportsDirectory.appendingPathComponent("verify-summary.md").path: Data("# Verify\n".utf8),
                layout.logsDirectory.appendingPathComponent("import-log.jsonl").path: Data("{\"message\":\"ok\"}\n".utf8)
            ],
            directories: [
                bundleURL.path,
                layout.reportsDirectory.path,
                layout.logsDirectory.path,
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
                    id: "dotfile.zshrc",
                    kind: .dotfile,
                    title: "~/.zshrc",
                    restorePhase: .config,
                    source: ItemSource(path: "~/.zshrc"),
                    payload: ["relativePath": .string("files/dotfiles/.zshrc")],
                    secret: false
                )
            ],
            restorePlan: [
                RestoreStep(phase: .config, itemIds: ["dotfile.zshrc"]),
                RestoreStep(phase: .verify, itemIds: ["dotfile.zshrc"])
            ],
            manualTasks: [
                ManualTask(
                    id: "manual.overwrite.zshrc",
                    title: "Overwrite backup created",
                    reason: "~/.zshrc already exists",
                    action: "Review the backup before replacing the file.",
                    blocking: false
                )
            ],
            reports: ManifestReports(
                exportSummaryPath: "reports/export-summary.md",
                verifySummaryPath: "reports/verify-summary.md"
            )
        )
        let store = ManifestStore(fileSystem: fileSystem)
        try store.write(manifest, to: layout.manifestURL)

        let runner = MockCommandRunner(stubs: [
            .init(executable: "/bin/hostname", arguments: [], result: .success(.init(executable: "/bin/hostname", arguments: [], exitCode: 0, stdout: "test-host\n", stderr: ""))),
            .init(executable: "/usr/bin/uname", arguments: ["-m"], result: .success(.init(executable: "/usr/bin/uname", arguments: ["-m"], exitCode: 0, stdout: "arm64\n", stderr: ""))),
            .init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], result: .success(.init(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"], exitCode: 0, stdout: "15.3\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "brew"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "brew"], exitCode: 0, stdout: "/opt/homebrew/bin/brew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], result: .success(.init(executable: "/usr/bin/env", arguments: ["brew", "--prefix"], exitCode: 0, stdout: "/opt/homebrew\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "git"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "git"], exitCode: 0, stdout: "/usr/bin/git\n", stderr: ""))),
            .init(executable: "/usr/bin/env", arguments: ["which", "code"], result: .success(.init(executable: "/usr/bin/env", arguments: ["which", "code"], exitCode: 0, stdout: "/usr/local/bin/code\n", stderr: "")))
        ])
        let previewService = BundlePreviewService(
            fileSystem: fileSystem,
            bundleValidator: BundleValidator(fileSystem: fileSystem, manifestStore: store),
            preflightService: PreflightService(
                runner: runner,
                fileSystem: fileSystem,
                machineCollector: MachineInfoCollector(runner: runner)
            )
        )

        let preview = try previewService.load(from: bundleURL)

        #expect(preview.manifest.manualTasks.count == 1)
        #expect(preview.exportSummary == "# Export\n")
        #expect(preview.importSummary.hasPrefix("Not found:"))
        #expect(preview.verifySummary == "# Verify\n")
        #expect(preview.logsPreview == "{\"message\":\"ok\"}\n")
        #expect(preview.preflight.checks.contains(where: { $0.id == "preflight.bundle.exists" && $0.passed }))
    }

    @Test("Report generation includes sections")
    func reportGenerationIncludesSections() {
        let report = OperationReport(
            title: "Verify Summary",
            successes: [StepResult(id: "1", title: "A", status: .success, detail: "ok")],
            failures: [StepResult(id: "2", title: "B", status: .failed, detail: "fail")],
            skipped: [StepResult(id: "3", title: "C", status: .skipped, detail: "skip")],
            warnings: ["warn"],
            manualTasks: [ManualTask(id: "m1", title: "Manual", reason: "r", action: "a", blocking: false)]
        )

        let markdown = MarkdownReportWriter(locale: Locale(identifier: "en")).renderOperationReport(report)
        #expect(markdown.contains("## Success"))
        #expect(markdown.contains("## Failed"))
        #expect(markdown.contains("## Manual Follow-up"))
        #expect(markdown.contains("Manual"))
    }
}
