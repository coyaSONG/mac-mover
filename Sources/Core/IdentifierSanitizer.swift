import Foundation

public struct IdentifierSanitizer {
    public static func sanitize(_ value: String) -> String {
        let lower = value.lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")
        let scalarView = lower.unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) {
                return Character(String(scalar))
            }
            return "-"
        }
        let string = String(scalarView)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return string.isEmpty ? "item" : string
    }
}
