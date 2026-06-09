import Foundation
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdService: NSObject, FullScreenContentDelegate {
    private struct CachedRewardedAd {
        let ad: RewardedAd
        let adUnitID: String
    }

    private let reporter: AdsEventReporter

    var rewardedAd: RewardedAd? {
        rewardedAdsBySlot.values.first?.ad
    }

    private var rewardedAdsBySlot: [String: CachedRewardedAd] = [:]
    private var loadingSlotKeys: Set<String> = []
    private var pendingLoadCallbacksBySlot: [String: [() -> Void]] = [:]
    private var activeSlotKey: String?
    private var onShown: (() -> Void)?
    private var onDismissed: (() -> Void)?
    private var onReward: ((AdReward?) -> Void)?
    private var pendingReward: AdReward?

    init(reporter: AdsEventReporter) {
        self.reporter = reporter
    }

    func hasCachedAd(for slot: AdsSlot) -> Bool {
        cachedAd(for: slot) != nil
    }

    func load(
        slot: AdsSlot,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)? = nil
    ) {
        guard cachedAd(for: slot) == nil else {
            onLoaded?()
            return
        }
        guard !isLoading(slot: slot) else {
            appendPendingLoadCallback(onLoaded, slot: slot)
            return
        }
        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onLoaded?()
            return
        }
        startLoading(slot: slot)
        appendPendingLoadCallback(onLoaded, slot: slot)
        loadRewarded(
            slot: slot,
            placements: placements,
            index: 0,
            runtimeContext: runtimeContext
        )
    }

    func show(
        slot: AdsSlot,
        runtimeContext: AdsRuntimeContext,
        onShown: (() -> Void)?,
        onDismissed: (() -> Void)?,
        onReward: @escaping (AdReward?) -> Void
    ) {
        guard let rootViewController = runtimeContext.topViewControllerProvider() else {
            onReward(nil)
            onDismissed?()
            return
        }

        if let cachedAd = cachedAd(for: slot) {
            self.onShown = onShown
            self.onDismissed = onDismissed
            self.onReward = onReward
            activeSlotKey = slot.key
            cachedAd.ad.present(from: rootViewController) { [weak self] in
                guard let self else { return }
                self.reporter.record(
                    AdsEvent(
                        kind: .rewardEarned,
                        slotKey: slot.key,
                        adUnitId: cachedAd.ad.adUnitID,
                        format: .rewarded,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                        metadata: [
                            "reward_amount": cachedAd.ad.adReward.amount.stringValue,
                            "reward_type": cachedAd.ad.adReward.type
                        ]
                    )
                )
                self.pendingReward = cachedAd.ad.adReward
            }
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onReward(nil)
            onDismissed?()
            return
        }
        guard !isLoading(slot: slot) else {
            onReward(nil)
            onDismissed?()
            return
        }

        self.onShown = onShown
        self.onDismissed = onDismissed
        self.onReward = onReward
        activeSlotKey = slot.key
        startLoading(slot: slot)
        loadAndPresentRewarded(
            slot: slot,
            placements: placements,
            index: 0,
            rootViewController: rootViewController,
            runtimeContext: runtimeContext
        )
    }

    private func loadRewarded(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        runtimeContext: AdsRuntimeContext
    ) {
        guard placements.indices.contains(index) else {
            finishLoadingRewarded(slot: slot, didLoad: false)
            return
        }
        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .rewarded,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )
        RewardedAd.load(with: placement.id, request: Request()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.reporter.record(
                        AdsEvent(
                            kind: .loadFailed,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .rewarded,
                            message: error.localizedDescription,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: AdsErrorMetadata.make(from: error)
                        )
                    )
                    self.loadRewarded(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        runtimeContext: runtimeContext
                    )
                    return
                }
                guard let ad else {
                    self.finishLoadingRewarded(slot: slot, didLoad: false)
                    return
                }
                self.setCachedAd(ad, adUnitID: placement.id, slot: slot)
                ad.fullScreenContentDelegate = self
                ad.paidEventHandler = { @MainActor [weak self, weak ad] adValue in
                    self?.reporter.record(
                        AdsEvent(
                            kind: .paidImpression,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .rewarded,
                            mediationAdapterClassName: ad?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
                            valueMicros: adValue.value.doubleValue,
                            precision: adValue.precision.rawValue,
                            currencyCode: adValue.currencyCode,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                        )
                    )
                }
                self.reporter.record(
                    AdsEvent(
                        kind: .loadSucceeded,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .rewarded,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.finishLoadingRewarded(slot: slot, didLoad: true)
            }
        }
    }

    private func loadAndPresentRewarded(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        rootViewController: UIViewController,
        runtimeContext: AdsRuntimeContext
    ) {
        guard placements.indices.contains(index) else {
            finishLoadingRewarded(slot: slot, didLoad: false)
            onReward?(nil)
            onDismissed?()
            clearPresentationCallbacks()
            return
        }

        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .rewarded,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )

        RewardedAd.load(with: placement.id, request: Request()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.reporter.record(
                        AdsEvent(
                            kind: .loadFailed,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .rewarded,
                            message: error.localizedDescription,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: AdsErrorMetadata.make(from: error)
                        )
                    )
                    self.loadAndPresentRewarded(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        rootViewController: rootViewController,
                        runtimeContext: runtimeContext
                    )
                    return
                }

                guard let ad else {
                    self.finishLoadingRewarded(slot: slot, didLoad: false)
                    self.onReward?(nil)
                    self.onDismissed?()
                    self.clearPresentationCallbacks()
                    return
                }

                self.setCachedAd(ad, adUnitID: placement.id, slot: slot)
                ad.fullScreenContentDelegate = self
                ad.paidEventHandler = { @MainActor [weak self, weak ad] adValue in
                    self?.reporter.record(
                        AdsEvent(
                            kind: .paidImpression,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .rewarded,
                            mediationAdapterClassName: ad?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
                            valueMicros: adValue.value.doubleValue,
                            precision: adValue.precision.rawValue,
                            currencyCode: adValue.currencyCode,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                        )
                    )
                }
                self.reporter.record(
                    AdsEvent(
                        kind: .loadSucceeded,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .rewarded,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.finishLoadingRewarded(slot: slot, didLoad: true)
                ad.present(from: rootViewController) { [weak self] in
                    guard let self else { return }
                    self.reporter.record(
                        AdsEvent(
                            kind: .rewardEarned,
                            slotKey: slot.key,
                            adUnitId: ad.adUnitID,
                            format: .rewarded,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: [
                                "reward_amount": ad.adReward.amount.stringValue,
                                "reward_type": ad.adReward.type
                            ]
                        )
                    )
                    self.pendingReward = ad.adReward
                }
            }
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        onShown?()
        onShown = nil
        reporter.record(
            AdsEvent(
                kind: .willPresent,
                slotKey: activeSlotKey,
                adUnitId: (ad as? RewardedAd)?.adUnitID,
                format: .rewarded,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        reporter.record(
            AdsEvent(
                kind: .didDismiss,
                slotKey: activeSlotKey,
                adUnitId: (ad as? RewardedAd)?.adUnitID,
                format: .rewarded,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        removeCachedAd(slotKey: activeSlotKey)

        let rewardCallback = onReward
        let dismissedCallback = onDismissed
        let earnedReward = pendingReward
        clearPresentationCallbacks()

        dismissedCallback?()
        if let earnedReward {
            rewardCallback?(earnedReward)
        }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        reporter.record(
            AdsEvent(
                kind: .loadFailed,
                slotKey: activeSlotKey,
                adUnitId: (ad as? RewardedAd)?.adUnitID,
                format: .rewarded,
                message: error.localizedDescription,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000),
                metadata: AdsErrorMetadata.make(from: error)
            )
        )
        removeCachedAd(slotKey: activeSlotKey)
        activeSlotKey = nil
        onDismissed?()
        clearPresentationCallbacks()
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        reporter.record(
            AdsEvent(
                kind: .click,
                slotKey: activeSlotKey,
                adUnitId: (ad as? RewardedAd)?.adUnitID,
                format: .rewarded,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
    }

    private func finishLoadingRewarded(slot: AdsSlot, didLoad: Bool) {
        stopLoading(slot: slot)
        let callbacks = pendingLoadCallbacksBySlot[slot.key] ?? []
        pendingLoadCallbacksBySlot[slot.key] = nil

        guard didLoad else { return }
        callbacks.forEach { $0() }
    }

    private func clearPresentationCallbacks() {
        activeSlotKey = nil
        onDismissed = nil
        onShown = nil
        onReward = nil
        pendingReward = nil
    }

    private func cachedAd(for slot: AdsSlot) -> CachedRewardedAd? {
        guard let cachedAd = rewardedAdsBySlot[slot.key] else { return nil }
        let validAdUnitIDs = Set(AdsPlacementResolver.loadOrder(for: slot).map(\.id))
        guard validAdUnitIDs.contains(cachedAd.adUnitID) else {
            removeCachedAd(slotKey: slot.key)
            return nil
        }
        return cachedAd
    }

    private func setCachedAd(_ ad: RewardedAd, adUnitID: String, slot: AdsSlot) {
        rewardedAdsBySlot[slot.key] = CachedRewardedAd(ad: ad, adUnitID: adUnitID)
    }

    private func removeCachedAd(slotKey: String?) {
        guard let slotKey else { return }
        rewardedAdsBySlot[slotKey] = nil
    }

    private func isLoading(slot: AdsSlot) -> Bool {
        loadingSlotKeys.contains(slot.key)
    }

    private func startLoading(slot: AdsSlot) {
        loadingSlotKeys.insert(slot.key)
    }

    private func stopLoading(slot: AdsSlot) {
        loadingSlotKeys.remove(slot.key)
    }

    private func appendPendingLoadCallback(_ callback: (() -> Void)?, slot: AdsSlot) {
        guard let callback else { return }
        pendingLoadCallbacksBySlot[slot.key, default: []].append(callback)
    }
}
