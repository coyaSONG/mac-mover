import Foundation
import SharedModels

public struct DriftEngine: Sendable {
    public init() {}

    public func compare(repo: RepoSnapshot, local: EnvironmentSnapshot) -> [DriftItem] {
        let repoLookup = Dictionary(uniqueKeysWithValues: repo.items.map { (makeKey(for: $0), $0) })
        let localLookup = Dictionary(uniqueKeysWithValues: local.items.map { (makeKey(for: $0), $0) })

        var drift: [DriftItem] = []

        for item in repo.items {
            let key = makeKey(for: item)
            guard let localItem = localLookup[key] else {
                drift.append(
                    DriftItem(
                        category: item.category,
                        identifier: item.identifier,
                        repoValue: item.value,
                        localValue: nil,
                        status: .missing,
                        suggestedResolutions: [.apply]
                    )
                )
                continue
            }

            if item != localItem {
                drift.append(
                    DriftItem(
                        category: item.category,
                        identifier: item.identifier,
                        repoValue: item.value,
                        localValue: localItem.value,
                        status: .modified,
                        suggestedResolutions: [.apply, .promote]
                    )
                )
            }
        }

        for item in local.items {
            let key = makeKey(for: item)
            guard repoLookup[key] == nil else {
                continue
            }

            drift.append(
                DriftItem(
                    category: item.category,
                    identifier: item.identifier,
                    repoValue: nil,
                    localValue: item.value,
                    status: .extra,
                    suggestedResolutions: [.promote, .ignore]
                )
            )
        }

        return drift
    }

    private func makeKey(for item: WorkspaceItem) -> String {
        "\(item.category.rawValue)::\(item.identifier)"
    }
}
