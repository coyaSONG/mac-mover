import SwiftUI
#if canImport(Localization)
import Localization
#endif

struct ImportTab: View {
    var body: some View {
        CardView(title: L10n.string(.importLegacyTitle), icon: "shippingbox") {
            Text(L10n.string(.importLegacyDescription))
        }
    }
}
