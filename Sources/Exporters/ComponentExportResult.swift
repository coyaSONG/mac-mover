import Foundation
import SharedModels

struct ComponentExportResult {
    var items: [ManifestItem] = []
    var successes: [StepResult] = []
    var failures: [StepResult] = []
    var skipped: [StepResult] = []
    var warnings: [String] = []
    var manualTasks: [ManualTask] = []

    mutating func append(_ other: ComponentExportResult) {
        items += other.items
        successes += other.successes
        failures += other.failures
        skipped += other.skipped
        warnings += other.warnings
        manualTasks += other.manualTasks
    }
}
