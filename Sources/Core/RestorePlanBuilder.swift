import Foundation
import SharedModels

public struct RestorePlanBuilder {
    public init() {}

    public func build(items: [ManifestItem], includeVerifyPhase: Bool = true) -> [RestoreStep] {
        var grouped: [RestorePhase: [String]] = [:]
        for item in items {
            grouped[item.restorePhase, default: []].append(item.id)
        }

        var plan: [RestoreStep] = RestorePhase.allCases.map { phase in
            RestoreStep(phase: phase, itemIds: grouped[phase, default: []].sorted())
        }

        if includeVerifyPhase {
            let verifyIds = items.map(\.id).sorted()
            if let index = plan.firstIndex(where: { $0.phase == .verify }) {
                plan[index].itemIds = verifyIds
            } else {
                plan.append(RestoreStep(phase: .verify, itemIds: verifyIds))
            }
        }

        return plan.sorted { $0.phase < $1.phase }
    }
}
