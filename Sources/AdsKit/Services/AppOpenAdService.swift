import Foundation
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class AppOpenAdService: NSObject, FullScreenContentDelegate {
    private struct CachedAppOpenAd {
        let ad: AppOpenAd
        let adUnitID: String
    }

    private let reporter: AdsEventReporter

    var appOpenAd: AppOpenAd? {
        appOpenAdsBySlot.values.first?.ad
    }

    private(set) var isShowingAppOpenAd = false
    private var appOpenAdsBySlot: [String: CachedAppOpenAd] = [:]
    private var loadingSlotKeys: Set<String> = []
    private var pendingLoadCallbacksBySlot: [String: [() -> Void]] = [:]

    private var activeSlotKey: String?
    private var onShown: (() -> Void)?
    private var onDismissed: (() -> Void)?

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
        loadAppOpen(
            slot: slot,
            placements: placements,
            index: 0,
            runtimeContext: runtimeContext,
            onLoaded: onLoaded
        )
    }

    func show(
        slot: AdsSlot,
        runtimeContext: AdsRuntimeContext,
        policy: AdsAppOpenPolicy,
        onShown: (() -> Void)?,
        onDismissed: (() -> Void)?
    ) {
        guard let rootViewController = runtimeContext.topViewControllerProvider() else {
            onDismissed?()
            return
        }

        if let cachedAd = cachedAd(for: slot) {
            self.onShown = onShown
            self.onDismissed = onDismissed
            activeSlotKey = slot.key
            cachedAd.ad.present(from: rootViewController)
            return
        }

        guard policy.loadOnDemandIfNeeded else {
            onDismissed?()
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onDismissed?()
            return
        }

        guard !isLoading(slot: slot) else {
            onDismissed?()
            return
        }

        self.onShown = onShown
        self.onDismissed = onDismissed
        activeSlotKey = slot.key
        startLoading(slot: slot)
        loadAndPresent(
            slot: slot,
            placements: placements,
            index: 0,
            rootViewController: rootViewController,
            runtimeContext: runtimeContext
        )
    }

    private func loadAppOpen(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)?
    ) {
        guard placements.indices.contains(index) else {
            finishLoadingAppOpen(slot: slot, didLoad: false)
            return
        }
        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .appOpen,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )
        AppOpenAd.load(with: placement.id, request: Request()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.reporter.record(
                        AdsEvent(
                            kind: .loadFailed,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .appOpen,
                            message: error.localizedDescription,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: AdsErrorMetadata.make(from: error)
                        )
                    )
                    self.loadAppOpen(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        runtimeContext: runtimeContext,
                        onLoaded: onLoaded
                    )
                    return
                }
                guard let ad else {
                    self.finishLoadingAppOpen(slot: slot, didLoad: false)
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
                            format: .appOpen,
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
                        format: .appOpen,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.finishLoadingAppOpen(slot: slot, didLoad: true)
            }
        }
    }

    private func loadAndPresent(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        rootViewController: UIViewController,
        runtimeContext: AdsRuntimeContext
    ) {
        guard placements.indices.contains(index) else {
            finishLoadingAppOpen(slot: slot, didLoad: false)
            finishWithoutPresentation()
            return
        }

        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .appOpen,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )

        AppOpenAd.load(with: placement.id, request: Request()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.reporter.record(
                        AdsEvent(
                            kind: .loadFailed,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .appOpen,
                            message: error.localizedDescription,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: AdsErrorMetadata.make(from: error)
                        )
                    )
                    self.loadAndPresent(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        rootViewController: rootViewController,
                        runtimeContext: runtimeContext
                    )
                    return
                }

                guard let ad else {
                    self.finishLoadingAppOpen(slot: slot, didLoad: false)
                    self.finishWithoutPresentation()
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
                            format: .appOpen,
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
                        format: .appOpen,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.finishLoadingAppOpen(slot: slot, didLoad: true)
                ad.present(from: rootViewController)
            }
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingAppOpenAd = true
        onShown?()
        onShown = nil
        reporter.record(
            AdsEvent(
                kind: .willPresent,
                slotKey: activeSlotKey,
                adUnitId: (ad as? AppOpenAd)?.adUnitID,
                format: .appOpen,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingAppOpenAd = false
        reporter.record(
            AdsEvent(
                kind: .didDismiss,
                slotKey: activeSlotKey,
                adUnitId: (ad as? AppOpenAd)?.adUnitID,
                format: .appOpen,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        removeCachedAd(slotKey: activeSlotKey)
        onDismissed?()
        onDismissed = nil
        onShown = nil
        activeSlotKey = nil
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        isShowingAppOpenAd = false
        reporter.record(
            AdsEvent(
                kind: .loadFailed,
                slotKey: activeSlotKey,
                adUnitId: (ad as? AppOpenAd)?.adUnitID,
                format: .appOpen,
                message: error.localizedDescription,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000),
                metadata: AdsErrorMetadata.make(from: error)
            )
        )
        removeCachedAd(slotKey: activeSlotKey)
        onDismissed?()
        onDismissed = nil
        onShown = nil
        activeSlotKey = nil
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        reporter.record(
            AdsEvent(
                kind: .click,
                slotKey: activeSlotKey,
                adUnitId: (ad as? AppOpenAd)?.adUnitID,
                format: .appOpen,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
    }

    private func finishWithoutPresentation() {
        onDismissed?()
        onDismissed = nil
        onShown = nil
        activeSlotKey = nil
    }

    private func cachedAd(for slot: AdsSlot) -> CachedAppOpenAd? {
        guard let cachedAd = appOpenAdsBySlot[slot.key] else { return nil }
        let validAdUnitIDs = Set(AdsPlacementResolver.loadOrder(for: slot).map(\.id))
        guard validAdUnitIDs.contains(cachedAd.adUnitID) else {
            removeCachedAd(slotKey: slot.key)
            return nil
        }
        return cachedAd
    }

    private func setCachedAd(_ ad: AppOpenAd, adUnitID: String, slot: AdsSlot) {
        appOpenAdsBySlot[slot.key] = CachedAppOpenAd(ad: ad, adUnitID: adUnitID)
    }

    private func removeCachedAd(slotKey: String?) {
        guard let slotKey else { return }
        appOpenAdsBySlot[slotKey] = nil
    }

    private func isLoading(slot: AdsSlot) -> Bool {
        loadingSlotKeys.contains(slot.key)
    }

    private func startLoading(slot: AdsSlot) {
        loadingSlotKeys.insert(slot.key)
    }

    private func finishLoadingAppOpen(slot: AdsSlot, didLoad: Bool) {
        loadingSlotKeys.remove(slot.key)
        let callbacks = pendingLoadCallbacksBySlot[slot.key] ?? []
        pendingLoadCallbacksBySlot[slot.key] = nil
        guard didLoad else { return }
        callbacks.forEach { $0() }
    }

    private func appendPendingLoadCallback(_ callback: (() -> Void)?, slot: AdsSlot) {
        guard let callback else { return }
        pendingLoadCallbacksBySlot[slot.key, default: []].append(callback)
    }
}
