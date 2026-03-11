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
        let view = AdsNativeTemplateView(style: style, theme: theme)
        view.onCollapse = onCollapse
        return view
    }

    public func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        if let templateView = nativeAdView as? AdsNativeTemplateView {
            templateView.onCollapse = onCollapse
        }

        guard let nativeAd = nativeViewModel.nativeAd else { return }

        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil

        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil

        if let starRatingLabel = nativeAdView.starRatingView as? UILabel {
            starRatingLabel.text = starsString(from: nativeAd.starRating)
            starRatingLabel.isHidden = starRatingLabel.text?.isEmpty ?? true
        }

        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil

        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil

        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil

        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil

        nativeAdView.nativeAd = nativeAd
    }

    private func starsString(from starRating: NSDecimalNumber?) -> String {
        guard let rating = starRating?.doubleValue else {
            return ""
        }

        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        let emptyStars = max(0, 5 - fullStars - (hasHalfStar ? 1 : 0))

        let full = String(repeating: "★", count: fullStars)
        let half = hasHalfStar ? "☆" : ""
        let empty = String(repeating: "·", count: emptyStars)
        return full + half + empty
    }
}
