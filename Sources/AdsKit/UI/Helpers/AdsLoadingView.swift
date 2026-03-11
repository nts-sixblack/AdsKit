import SwiftUI

struct AdsLoadingView: View {
    let theme: AdsTheme

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Color(hex: theme.accentHex))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
