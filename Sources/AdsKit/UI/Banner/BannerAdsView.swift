@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

public struct BannerAdsView: View {
    @ObservedObject private var manager: AdsKitManager
    private let slotKey: String
    private let adSize: AdSize
    private let collapse: AdsBannerCollapse?

    @State private var isAdLoaded = true

    public init(
        slotKey: String,
        manager: AdsKitManager,
        adSize: AdSize? = nil,
        collapse: AdsBannerCollapse? = nil
    ) {
        self.slotKey = slotKey
        self.manager = manager
        self.collapse = collapse
        self.adSize = adSize ?? currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
    }

    public var body: some View {
        VStack {
            if !manager.canDisplay(slotKey: slotKey) || !isAdLoaded {
                EmptyView()
            } else if let slot = manager.slot(forKey: slotKey),
                      let placement = AdsPlacementResolver.preferredPlacement(for: slot) {
                BannerAdsRepresentable(
                    slotKey: slot.key,
                    adUnitID: placement.id,
                    adSize: adSize,
                    manager: manager,
                    collapse: collapse,
                    isAdLoaded: $isAdLoaded
                )
                .frame(height: max(60, adSize.size.height))
            } else {
                EmptyView()
            }
        }
    }
}

private struct BannerAdsRepresentable: UIViewRepresentable {
    let slotKey: String
    let adUnitID: String
    let adSize: AdSize
    let manager: AdsKitManager
    let collapse: AdsBannerCollapse?
    @Binding var isAdLoaded: Bool

    func makeUIView(context: Context) -> BannerView {
        let bannerView = manager.bannerAdService.createBannerView(
            adUnitID: adUnitID,
            adSize: adSize,
            rootViewController: manager.runtimeContext.topViewControllerProvider()
        )
        bannerView.delegate = context.coordinator
        bannerView.paidEventHandler = { adValue in
            manager.recordBannerPaidEvent(
                slotKey: slotKey,
                adUnitId: adUnitID,
                adValue: adValue,
                bannerView: bannerView
            )
        }
        manager.bannerAdService.load(
            bannerView: bannerView,
            collapse: collapse,
            rootViewController: manager.runtimeContext.topViewControllerProvider()
        )
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        manager.bannerAdService.load(
            bannerView: bannerView,
            collapse: collapse,
            rootViewController: manager.runtimeContext.topViewControllerProvider()
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        private let parent: BannerAdsRepresentable

        init(_ parent: BannerAdsRepresentable) {
            self.parent = parent
        }

        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            guard let adUnitId = bannerView.adUnitID else { return }
            parent.manager.recordBannerClick(
                slotKey: parent.slotKey,
                adUnitId: adUnitId
            )
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            parent.isAdLoaded = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.isAdLoaded = false
        }
    }
}
