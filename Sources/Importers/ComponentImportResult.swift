import Foundation
import SharedModels

struct ComponentImportResult {
    var successes: [StepResult] = []
    var failures: [StepResult] = []
    var skipped: [StepResult] = []
    var warnings: [String] = []
    var manualTasks: [ManualTask] = []

    mutating func append(_ other: ComponentImportResult) {
        successes += other.successes
        failures += other.failures
        skipped += other.skipped
        warnings += other.warnings
        manualTasks += other.manualTasks
    }
}
