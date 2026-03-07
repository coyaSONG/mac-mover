import Foundation
import SharedModels

public struct DriftEngine: Sendable {
    public init() {}

    public func compare(repo: RepoSnapshot, local: EnvironmentSnapshot) -> [DriftItem] {
        let repoLookup = makeLookup(for: repo.items)
        let localLookup = makeLookup(for: local.items)

        var drift: [DriftItem] = []

        for (key, repoItems) in repoLookup {
            var unmatchedLocalItems = localLookup[key] ?? []

            for item in repoItems {
                if let matchIndex = unmatchedLocalItems.firstIndex(where: { areSemanticallyEqual(item, $0) }) {
                    unmatchedLocalItems.remove(at: matchIndex)
                    continue
                }

                if let localItem = unmatchedLocalItems.first {
                    unmatchedLocalItems.removeFirst()
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
                    continue
                }

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
            }

            for item in unmatchedLocalItems {
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
        }

        for (key, localItems) in localLookup where repoLookup[key] == nil {
            for item in localItems {
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
        }

        return drift
    }

    private func makeLookup(for items: [WorkspaceItem]) -> [String: [WorkspaceItem]] {
        var grouped: [String: [WorkspaceItem]] = [:]

        for item in items {
            let key = makeKey(for: item)
            let group = grouped[key, default: []]
            if group.contains(where: { areSemanticallyEqual($0, item) }) {
                continue
            }
            grouped[key, default: []].append(item)
        }

        return grouped
    }

    private func areSemanticallyEqual(_ lhs: WorkspaceItem, _ rhs: WorkspaceItem) -> Bool {
        lhs.category == rhs.category
            && lhs.identifier == rhs.identifier
            && lhs.value == rhs.value
    }

    private func makeKey(for item: WorkspaceItem) -> String {
        "\(item.category.rawValue)::\(item.identifier)"
    }
}
