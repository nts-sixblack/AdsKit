@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

public struct NativeAdsSwiftUIView: UIViewRepresentable {
    public typealias UIViewType = NativeAdView

    @ObservedObject private var nativeViewModel: NativeAdViewModel
    private let style: NativeAdViewStyle
    private let theme: AdsTheme
    private let onCollapse: (() -> Void)?

    public init(
        nativeViewModel: NativeAdViewModel,
        style: NativeAdViewStyle = .basic,
        theme: AdsTheme = .init(),
        onCollapse: (() -> Void)? = nil
    ) {
        self.nativeViewModel = nativeViewModel
        self.style = style
        self.theme = theme
        self.onCollapse = onCollapse
    }

    public func makeUIView(context: Context) -> NativeAdView {
        if case .collapse = style {
            let view = AdsNativeCollapseView(theme: theme)
            view.onCollapse = onCollapse
            return view
        } else {
            let view = AdsNativeTemplateView(style: style, theme: theme)
            view.onCollapse = onCollapse
            return view
        }
    }

    public func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        if let collapseView = nativeAdView as? AdsNativeCollapseView {
            collapseView.onCollapse = onCollapse

            guard let nativeAd = nativeViewModel.nativeAd else { return }
            collapseView.apply(nativeAd: nativeAd)
            return
        }

        if let templateView = nativeAdView as? AdsNativeTemplateView {
            templateView.onCollapse = onCollapse

            guard let nativeAd = nativeViewModel.nativeAd else { return }
            templateView.apply(nativeAd: nativeAd)
            return
        }
    }
}
