import SwiftUI

struct ImportTab: View {
    var body: some View {
        CardView(title: "Legacy Import", icon: "shippingbox") {
            Text("Legacy bundle import and verify flows still exist behind AppState for compatibility, but the shell now surfaces repo control tower workflows first.")
        }
    }
}
