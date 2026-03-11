import Foundation
@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
public final class NativeAdViewModel: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published public private(set) var nativeAd: NativeAd?
    @Published public private(set) var isLoading: Bool = false

    public var slotKey: String { slot.key }

    private let slot: AdsSlot
    private let policy: AdsNativePolicy
    private let runtimeProvider: () -> AdsRuntimeContext
    private let eventReporter: AdsEventReporter

    private var adLoader: AdLoader?
    private var activePlacements: [AdsPlacement] = []
    private var activePlacementIndex: Int = 0
    private var loadedPlacementId: String?

    private static var cachedAds: [String: NativeAd] = [:]
    private static var lastRequestTimes: [String: Date] = [:]

    init(
        slot: AdsSlot,
        policy: AdsNativePolicy,
        runtimeProvider: @escaping () -> AdsRuntimeContext,
        eventReporter: AdsEventReporter
    ) {
        self.slot = slot
        self.policy = policy
        self.runtimeProvider = runtimeProvider
        self.eventReporter = eventReporter
        super.init()

        if policy.usesSharedCache {
            if let cachedAd = Self.cachedAds[slot.primaryPlacement.id] {
                nativeAd = cachedAd
                loadedPlacementId = slot.primaryPlacement.id
            } else if let fallbackPlacement = slot.fallbackPlacement,
                      let cachedAd = Self.cachedAds[fallbackPlacement.id] {
                nativeAd = cachedAd
                loadedPlacementId = fallbackPlacement.id
            }
        }
    }

    public func refreshAd(force: Bool = false) {
        let runtimeContext = runtimeProvider()
        guard runtimeContext.isAdsEnabled else { return }
        guard !runtimeContext.isPremiumUser else { return }
        guard !isLoading else { return }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else { return }

        if !force,
           let currentPlacementId = loadedPlacementId,
           let lastRequestTime = Self.lastRequestTimes[currentPlacementId] {
            let elapsed = runtimeContext.nowProvider().timeIntervalSince(lastRequestTime)
            let requestInterval = TimeInterval(slot.requestIntervalSeconds ?? policy.defaultRequestIntervalSeconds)
            if elapsed < requestInterval, nativeAd != nil {
                return
            }
        }

        activePlacements = placements
        activePlacementIndex = 0
        loadPlacement(at: activePlacementIndex)
    }

    public func clear() {
        nativeAd = nil
        loadedPlacementId = nil
    }

    private func loadPlacement(at index: Int) {
        guard activePlacements.indices.contains(index) else {
            isLoading = false
            return
        }

        isLoading = true
        activePlacementIndex = index

        let placement = activePlacements[index]
        let runtimeContext = runtimeProvider()
        let timestamp = Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
        eventReporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .native,
                timestampMs: timestamp
            )
        )

        let viewOptions = NativeAdViewAdOptions()
        viewOptions.preferredAdChoicesPosition = (slot.adChoicesPosition ?? policy.defaultAdChoicesPosition).googleValue

        Self.lastRequestTimes[placement.id] = runtimeContext.nowProvider()
        adLoader = AdLoader(
            adUnitID: placement.id,
            rootViewController: runtimeContext.topViewControllerProvider(),
            adTypes: [.native],
            options: [viewOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        nativeAd.mediaContent.videoController.delegate = self
        nativeAd.paidEventHandler = { [weak self] adValue in
            guard let self else { return }
            self.eventReporter.record(
                AdsEvent(
                    kind: .paidImpression,
                    slotKey: self.slot.key,
                    adUnitId: adLoader.adUnitID,
                    format: .native,
                    mediationAdapterClassName: nativeAd.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
                    valueMicros: adValue.value.doubleValue,
                    precision: adValue.precision.rawValue,
                    currencyCode: adValue.currencyCode,
                    timestampMs: Int64(self.runtimeProvider().nowProvider().timeIntervalSince1970 * 1000)
                )
            )
        }

        self.nativeAd = nativeAd
        self.loadedPlacementId = adLoader.adUnitID
        if policy.usesSharedCache {
            Self.cachedAds[adLoader.adUnitID] = nativeAd
        }
        isLoading = false

        eventReporter.record(
            AdsEvent(
                kind: .loadSucceeded,
                slotKey: slot.key,
                adUnitId: adLoader.adUnitID,
                format: .native,
                timestampMs: Int64(runtimeProvider().nowProvider().timeIntervalSince1970 * 1000)
            )
        )
    }

    public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        eventReporter.record(
            AdsEvent(
                kind: .loadFailed,
                slotKey: slot.key,
                adUnitId: adLoader.adUnitID,
                format: .native,
                message: error.localizedDescription,
                timestampMs: Int64(runtimeProvider().nowProvider().timeIntervalSince1970 * 1000)
            )
        )

        let nextIndex = activePlacementIndex + 1
        guard activePlacements.indices.contains(nextIndex) else {
            isLoading = false
            return
        }

        loadPlacement(at: nextIndex)
    }
}

extension NativeAdViewModel: VideoControllerDelegate {
    public func videoControllerDidPlayVideo(_ videoController: VideoController) {}
    public func videoControllerDidPauseVideo(_ videoController: VideoController) {}
    public func videoControllerDidEndVideoPlayback(_ videoController: VideoController) {}
    public func videoControllerDidMuteVideo(_ videoController: VideoController) {}
    public func videoControllerDidUnmuteVideo(_ videoController: VideoController) {}
}

extension NativeAdViewModel: NativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        eventReporter.record(
            AdsEvent(
                kind: .click,
                slotKey: slot.key,
                adUnitId: loadedPlacementId,
                format: .native,
                timestampMs: Int64(runtimeProvider().nowProvider().timeIntervalSince1970 * 1000)
            )
        )
    }

    public func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {}
    public func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {}
    public func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {}
    public func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {}
}
