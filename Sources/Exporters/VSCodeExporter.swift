import Foundation
import SharedModels
import Core

struct VSCodeExporter {
    private let runner: CommandRunning
    private let fileSystem: FileSysteming
    private let manualTaskEngine: ManualTaskEngine
    private let homeDirectory: String

    init(
        runner: CommandRunning,
        fileSystem: FileSysteming,
        manualTaskEngine: ManualTaskEngine,
        homeDirectory: String
    ) {
        self.runner = runner
        self.fileSystem = fileSystem
        self.manualTaskEngine = manualTaskEngine
        self.homeDirectory = homeDirectory
    }

    func export(to layout: BundleLayout) -> ComponentExportResult {
        var result = ComponentExportResult()
        let vscodeUserDir = URL(fileURLWithPath: homeDirectory)
            .appendingPathComponent("Library/Application Support/Code/User")

        let settingsURL = vscodeUserDir.appendingPathComponent("settings.json")
        if fileSystem.fileExists(at: settingsURL) {
            do {
                try fileSystem.copyItem(at: settingsURL, to: layout.vscodeSettingsURL)
                result.items.append(
                    ManifestItem(
                        id: "vscode.settings",
                        kind: .vscodeSettings,
                        title: "VS Code settings",
                        restorePhase: .ide,
                        source: ItemSource(path: "~/Library/Application Support/Code/User/settings.json"),
                        payload: ["relativePath": .string("files/vscode/settings.json")],
                        secret: false,
                        risk: .medium,
                        verify: VerifySpec(expectedFile: "~/Library/Application Support/Code/User/settings.json"),
                        notes: []
                    )
                )
                result.successes.append(StepResult(id: "vscode.settings", title: "VS Code settings", status: .success, detail: "settings.json exported"))
            } catch {
                result.failures.append(StepResult(id: "vscode.settings", title: "VS Code settings", status: .failed, detail: error.localizedDescription))
            }
        } else {
            result.skipped.append(StepResult(id: "vscode.settings", title: "VS Code settings", status: .skipped, detail: "settings.json not found"))
        }

        let keybindingsURL = vscodeUserDir.appendingPathComponent("keybindings.json")
        if fileSystem.fileExists(at: keybindingsURL) {
            do {
                try fileSystem.copyItem(at: keybindingsURL, to: layout.vscodeKeybindingsURL)
                result.items.append(
                    ManifestItem(
                        id: "vscode.keybindings",
                        kind: .vscodeSettings,
                        title: "VS Code keybindings",
                        restorePhase: .ide,
                        source: ItemSource(path: "~/Library/Application Support/Code/User/keybindings.json"),
                        payload: ["relativePath": .string("files/vscode/keybindings.json")],
                        secret: false,
                        risk: .medium,
                        verify: VerifySpec(expectedFile: "~/Library/Application Support/Code/User/keybindings.json"),
                        notes: []
                    )
                )
                result.successes.append(StepResult(id: "vscode.keybindings", title: "VS Code keybindings", status: .success, detail: "keybindings.json exported"))
            } catch {
                result.failures.append(StepResult(id: "vscode.keybindings", title: "VS Code keybindings", status: .failed, detail: error.localizedDescription))
            }
        }

        let snippetsSource = vscodeUserDir.appendingPathComponent("snippets")
        if fileSystem.fileExists(at: snippetsSource) {
            do {
                try fileSystem.createDirectory(at: layout.vscodeSnippetsDirectory)
                let snippetFiles = try fileSystem.listDirectory(at: snippetsSource)
                for snippetFile in snippetFiles {
                    let destination = layout.vscodeSnippetsDirectory.appendingPathComponent(snippetFile.lastPathComponent)
                    try fileSystem.copyItem(at: snippetFile, to: destination)
                }
                result.items.append(
                    ManifestItem(
                        id: "vscode.snippets",
                        kind: .vscodeSettings,
                        title: "VS Code snippets",
                        restorePhase: .ide,
                        source: ItemSource(path: "~/Library/Application Support/Code/User/snippets"),
                        payload: ["relativePath": .string("files/vscode/snippets")],
                        secret: false,
                        risk: .medium,
                        verify: VerifySpec(expectedFile: "~/Library/Application Support/Code/User/snippets"),
                        notes: []
                    )
                )
                result.successes.append(StepResult(id: "vscode.snippets", title: "VS Code snippets", status: .success, detail: "\(snippetFiles.count) files exported"))
            } catch {
                result.failures.append(StepResult(id: "vscode.snippets", title: "VS Code snippets", status: .failed, detail: error.localizedDescription))
            }
        }

        guard runner.commandExists("code") else {
            result.manualTasks.append(manualTaskEngine.taskForMissingCodeCLI())
            result.skipped.append(StepResult(id: "vscode.extensions", title: "VS Code extensions", status: .skipped, detail: "code CLI not found"))
            return result
        }

        do {
            let rawExtensions = try runner.run(executable: "/usr/bin/env", arguments: ["code", "--list-extensions", "--show-versions"]).stdout
            let lines = rawExtensions.split(whereSeparator: \.isNewline).map(String.init)
            for line in lines where !line.isEmpty {
                let split = line.split(separator: "@", maxSplits: 1).map(String.init)
                let identifier = split[0]
                let version = split.count > 1 ? split[1] : "unknown"
                result.items.append(
                    ManifestItem(
                        id: "vscode.extension.\(IdentifierSanitizer.sanitize(identifier))",
                        kind: .vscodeExtension,
                        title: identifier,
                        restorePhase: .ide,
                        source: ItemSource(command: "code --list-extensions --show-versions"),
                        payload: ["identifier": .string(identifier), "version": .string(version)],
                        secret: false,
                        risk: .low,
                        verify: VerifySpec(command: "code --list-extensions --show-versions", expectedValue: .string(identifier)),
                        notes: []
                    )
                )
            }
            result.successes.append(StepResult(id: "vscode.extensions", title: "VS Code extensions", status: .success, detail: "\(lines.count) extensions exported"))
        } catch {
            result.failures.append(StepResult(id: "vscode.extensions", title: "VS Code extensions", status: .failed, detail: error.localizedDescription))
        }

        return result
    }
}
