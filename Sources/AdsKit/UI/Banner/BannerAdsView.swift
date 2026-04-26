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

fileprivate struct BannerLoadSignature: Equatable {
    let adUnitID: String
    let width: CGFloat
    let height: CGFloat
    let collapse: String?
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
        loadIfNeeded(bannerView, context: context, force: true)
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        bannerView.adUnitID = adUnitID
        bannerView.adSize = adSize
        if bannerView.rootViewController == nil {
            bannerView.rootViewController = manager.runtimeContext.topViewControllerProvider()
        }
        loadIfNeeded(bannerView, context: context)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func loadIfNeeded(
        _ bannerView: BannerView,
        context: Context,
        force: Bool = false
    ) {
        let signature = BannerLoadSignature(
            adUnitID: adUnitID,
            width: adSize.size.width,
            height: adSize.size.height,
            collapse: collapse?.rawValue
        )
        guard force || context.coordinator.shouldLoad(signature: signature) else { return }

        let didStartLoad = manager.bannerAdService.load(
            bannerView: bannerView,
            collapse: collapse,
            rootViewController: manager.runtimeContext.topViewControllerProvider()
        )
        guard didStartLoad else { return }

        context.coordinator.markLoadStarted(signature: signature)
        manager.recordBannerLoadRequested(
            slotKey: slotKey,
            adUnitId: adUnitID
        )
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        private let parent: BannerAdsRepresentable
        private var lastLoadedSignature: BannerLoadSignature?

        init(_ parent: BannerAdsRepresentable) {
            self.parent = parent
        }

        func shouldLoad(signature: BannerLoadSignature) -> Bool {
            lastLoadedSignature != signature
        }

        func markLoadStarted(signature: BannerLoadSignature) {
            lastLoadedSignature = signature
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
            guard let adUnitId = bannerView.adUnitID else { return }
            parent.manager.recordBannerLoadSucceeded(
                slotKey: parent.slotKey,
                adUnitId: adUnitId
            )
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.isAdLoaded = false
            parent.manager.recordBannerLoadFailed(
                slotKey: parent.slotKey,
                adUnitId: bannerView.adUnitID ?? parent.adUnitID,
                error: error,
                responseInfo: bannerView.responseInfo
            )
        }
    }
}
