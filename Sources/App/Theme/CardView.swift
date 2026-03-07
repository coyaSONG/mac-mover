import SwiftUI

struct CardView<Content: View>: View {
    let title: String?
    let icon: String?
    @ViewBuilder let content: () -> Content

    init(title: String? = nil, icon: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 6) {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(Color.appAccent)
                    }
                    Text(title).font(.headline)
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GlassCardBackground())
    }
}

private struct GlassCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
        } else {
            content
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        }
    }
}
