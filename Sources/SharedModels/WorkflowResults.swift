import Foundation

public struct ExportResult: Sendable {
    public var bundleURL: URL
    public var manifest: Manifest
    public var preflight: PreflightResult
    public var report: OperationReport

    public init(bundleURL: URL, manifest: Manifest, preflight: PreflightResult, report: OperationReport) {
        self.bundleURL = bundleURL
        self.manifest = manifest
        self.preflight = preflight
        self.report = report
    }
}

public struct ImportResult: Sendable {
    public var bundleURL: URL
    public var manifest: Manifest
    public var preflight: PreflightResult
    public var importReport: OperationReport
    public var verifyReport: OperationReport

    public init(bundleURL: URL, manifest: Manifest, preflight: PreflightResult, importReport: OperationReport, verifyReport: OperationReport) {
        self.bundleURL = bundleURL
        self.manifest = manifest
        self.preflight = preflight
        self.importReport = importReport
        self.verifyReport = verifyReport
    }
}

public struct WorkspaceScanResult: Sendable {
    public var workspace: ConnectedWorkspace
    public var repoSnapshot: RepoSnapshot
    public var environmentSnapshot: EnvironmentSnapshot
    public var report: OperationReport

    public init(
        workspace: ConnectedWorkspace,
        repoSnapshot: RepoSnapshot,
        environmentSnapshot: EnvironmentSnapshot,
        report: OperationReport
    ) {
        self.workspace = workspace
        self.repoSnapshot = repoSnapshot
        self.environmentSnapshot = environmentSnapshot
        self.report = report
    }
}
