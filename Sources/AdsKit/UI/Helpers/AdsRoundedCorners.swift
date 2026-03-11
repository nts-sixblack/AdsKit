import SwiftUI

extension View {
    func adsCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(
            AdsRoundedCornerShape(
                radius: radius,
                corners: corners
            )
        )
    }
}

private struct AdsRoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
        )
    }
}
