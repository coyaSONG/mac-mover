import Foundation

public struct SecretPolicy {
    public static let blockedPathFragments: [String] = [
        ".ssh/id_",
        "token",
        "session",
        "password",
        "credentials",
        "keychain",
        ".aws/credentials",
        ".gnupg",
        ".npmrc"
    ]

    public static func shouldExclude(path: String) -> Bool {
        let normalized = path.lowercased()
        return blockedPathFragments.contains { normalized.contains($0) }
    }
}
