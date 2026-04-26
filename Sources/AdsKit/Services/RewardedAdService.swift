import Foundation
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdService: NSObject, FullScreenContentDelegate {
    private let reporter: AdsEventReporter

    private(set) var rewardedAd: RewardedAd?
    private var isLoading = false
    private var pendingLoadCallbacks: [() -> Void] = []
    private var activeSlotKey: String?
    private var onShown: (() -> Void)?
    private var onDismissed: (() -> Void)?

    init(reporter: AdsEventReporter) {
        self.reporter = reporter
    }

    func load(
        slot: AdsSlot,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)? = nil
    ) {
        guard rewardedAd == nil else {
            onLoaded?()
            return
        }
        guard !isLoading else {
            if let onLoaded {
                pendingLoadCallbacks.append(onLoaded)
            }
            return
        }
        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onLoaded?()
            return
        }
        isLoading = true
        if let onLoaded {
            pendingLoadCallbacks.append(onLoaded)
        }
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

        if let rewardedAd {
            self.onShown = onShown
            self.onDismissed = onDismissed
            activeSlotKey = slot.key
            rewardedAd.present(from: rootViewController) { [weak self] in
                guard let self else { return }
                self.reporter.record(
                    AdsEvent(
                        kind: .rewardEarned,
                        slotKey: slot.key,
                        adUnitId: rewardedAd.adUnitID,
                        format: .rewarded,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                        metadata: [
                            "reward_amount": rewardedAd.adReward.amount.stringValue,
                            "reward_type": rewardedAd.adReward.type
                        ]
                    )
                )
                onReward(rewardedAd.adReward)
            }
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onReward(nil)
            onDismissed?()
            return
        }
        guard !isLoading else {
            onReward(nil)
            onDismissed?()
            return
        }

        self.onShown = onShown
        self.onDismissed = onDismissed
        activeSlotKey = slot.key
        isLoading = true
        loadAndPresentRewarded(
            slot: slot,
            placements: placements,
            index: 0,
            rootViewController: rootViewController,
            runtimeContext: runtimeContext,
            onReward: onReward
        )
    }

    private func loadRewarded(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        runtimeContext: AdsRuntimeContext
    ) {
        guard placements.indices.contains(index) else {
            finishLoadingRewarded(didLoad: false)
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
                self.finishLoadingRewarded(didLoad: false)
                return
            }
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.rewardedAd?.paidEventHandler = { [weak self] adValue in
                self?.reporter.record(
                    AdsEvent(
                        kind: .paidImpression,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .rewarded,
                        mediationAdapterClassName: self?.rewardedAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
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
            self.finishLoadingRewarded(didLoad: true)
        }
    }

    private func loadAndPresentRewarded(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        rootViewController: UIViewController,
        runtimeContext: AdsRuntimeContext,
        onReward: @escaping (AdReward?) -> Void
    ) {
        guard placements.indices.contains(index) else {
            isLoading = false
            onReward(nil)
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
                    runtimeContext: runtimeContext,
                    onReward: onReward
                )
                return
            }

            guard let ad else {
                self.isLoading = false
                onReward(nil)
                self.onDismissed?()
                self.clearPresentationCallbacks()
                return
            }

            self.isLoading = false
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.rewardedAd?.paidEventHandler = { [weak self] adValue in
                self?.reporter.record(
                    AdsEvent(
                        kind: .paidImpression,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .rewarded,
                        mediationAdapterClassName: self?.rewardedAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
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
                onReward(ad.adReward)
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
        rewardedAd = nil
        activeSlotKey = nil
        onDismissed?()
        clearPresentationCallbacks()
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
        rewardedAd = nil
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

    private func finishLoadingRewarded(didLoad: Bool) {
        isLoading = false
        let callbacks = pendingLoadCallbacks
        pendingLoadCallbacks.removeAll()

        guard didLoad else { return }
        callbacks.forEach { $0() }
    }

    private func clearPresentationCallbacks() {
        activeSlotKey = nil
        onDismissed = nil
        onShown = nil
    }
}
