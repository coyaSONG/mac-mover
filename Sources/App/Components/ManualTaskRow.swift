import SwiftUI
import SharedModels

struct ManualTaskRow: View {
    let task: ManualTask

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: task.blocking ? "exclamationmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(task.blocking ? Color.appDanger : Color.appMuted)
                .imageScale(.medium)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                Text(task.reason)
                    .font(.caption)
                    .foregroundStyle(.appMuted)
                Text(task.action)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
            }
        }
    }
}
