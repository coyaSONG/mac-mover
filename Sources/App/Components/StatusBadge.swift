import SwiftUI
import SharedModels

struct StatusBadge: View {
    let check: PreflightCheck

    private var icon: String {
        if check.passed { return "checkmark.circle.fill" }
        return check.blocking ? "xmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var color: Color {
        if check.passed { return .appSuccess }
        return check.blocking ? .appDanger : .appWarning
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(check.title)
                    .font(.body)
                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.appMuted)
            }
        }
    }
}
