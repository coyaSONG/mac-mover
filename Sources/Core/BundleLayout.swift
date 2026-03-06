import Foundation

public struct BundleLayout {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public var manifestURL: URL { root.appendingPathComponent("manifest.json") }
    public var brewfileURL: URL { root.appendingPathComponent("Brewfile") }
    public var reportsDirectory: URL { root.appendingPathComponent("reports") }
    public var logsDirectory: URL { root.appendingPathComponent("logs") }
    public var filesDirectory: URL { root.appendingPathComponent("files") }
    public var dotfilesDirectory: URL { filesDirectory.appendingPathComponent("dotfiles") }
    public var vscodeDirectory: URL { filesDirectory.appendingPathComponent("vscode") }
    public var vscodeSettingsURL: URL { vscodeDirectory.appendingPathComponent("settings.json") }
    public var vscodeKeybindingsURL: URL { vscodeDirectory.appendingPathComponent("keybindings.json") }
    public var vscodeSnippetsDirectory: URL { vscodeDirectory.appendingPathComponent("snippets") }
    public var exportSummaryURL: URL { reportsDirectory.appendingPathComponent("export-summary.md") }
    public var importSummaryURL: URL { reportsDirectory.appendingPathComponent("import-summary.md") }
    public var verifySummaryURL: URL { reportsDirectory.appendingPathComponent("verify-summary.md") }
}
