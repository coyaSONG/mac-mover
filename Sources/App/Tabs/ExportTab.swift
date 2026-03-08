import SwiftUI
#if canImport(Localization)
import Localization
#endif

struct ExportTab: View {
    var body: some View {
        CardView(title: L10n.string(.exportLegacyTitle), icon: "shippingbox") {
            Text(L10n.string(.exportLegacyDescription))
        }
    }
}
