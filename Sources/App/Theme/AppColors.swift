import SwiftUI

extension Color {
    static let appAccent = Color.accentColor
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appDanger = Color.red
    static let appMuted = Color.secondary
}

extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
    static var appSuccess: Color { .appSuccess }
    static var appWarning: Color { .appWarning }
    static var appDanger: Color { .appDanger }
    static var appMuted: Color { .appMuted }
}
