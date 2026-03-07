import Foundation

public enum StepStatus: String, Codable, Sendable {
    case success
    case failed
    case skipped
    case warning
}

public struct StepResult: Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var status: StepStatus
    public var detail: String

    public init(id: String, title: String, status: StepStatus, detail: String) {
        self.id = id
        self.title = title
        self.status = status
        self.detail = detail
    }
}

public struct OperationReport: Codable, Hashable, Sendable {
    public var title: String
    public var generatedAt: Date
    public var successes: [StepResult]
    public var failures: [StepResult]
    public var skipped: [StepResult]
    public var warnings: [String]
    public var driftItems: [DriftItem]
    public var manualTasks: [ManualTask]

    public init(
        title: String,
        generatedAt: Date = Date(),
        successes: [StepResult] = [],
        failures: [StepResult] = [],
        skipped: [StepResult] = [],
        warnings: [String] = [],
        driftItems: [DriftItem] = [],
        manualTasks: [ManualTask] = []
    ) {
        self.title = title
        self.generatedAt = generatedAt
        self.successes = successes
        self.failures = failures
        self.skipped = skipped
        self.warnings = warnings
        self.driftItems = driftItems
        self.manualTasks = manualTasks
    }
}

public struct PreflightCheck: Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var passed: Bool
    public var detail: String
    public var blocking: Bool

    public init(id: String, title: String, passed: Bool, detail: String, blocking: Bool = false) {
        self.id = id
        self.title = title
        self.passed = passed
        self.detail = detail
        self.blocking = blocking
    }
}

public struct PreflightResult: Codable, Hashable, Sendable {
    public var machine: MachineInfo
    public var checks: [PreflightCheck]

    public init(machine: MachineInfo, checks: [PreflightCheck]) {
        self.machine = machine
        self.checks = checks
    }

    public var hasBlockingFailure: Bool {
        checks.contains { !$0.passed && $0.blocking }
    }
}
