import Foundation
@preconcurrency import Dispatch
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdService: NSObject, FullScreenContentDelegate {
    @MainActor
    private final class SplashLoadState {
        var didFinish = false
    }

    private struct CachedInterstitialAd {
        let ad: InterstitialAd
        let adUnitID: String
    }

    private let reporter: AdsEventReporter

    var interstitialAd: InterstitialAd? {
        interstitialAdsBySlot.values.first?.ad
    }

    var splashInterstitialAd: InterstitialAd? {
        splashInterstitialAdsBySlot.values.first?.ad
    }

    private var interstitialAdsBySlot: [String: CachedInterstitialAd] = [:]
    private var splashInterstitialAdsBySlot: [String: CachedInterstitialAd] = [:]
    private var loadingKeys: Set<String> = []
    private var pendingLoadCallbacksByKey: [String: [() -> Void]] = [:]
    private var retryAttemptsBySlot: [String: Int] = [:]
    private var activeSlotKey: String?
    private var activeFormat: AdsFormat?
    private var onShown: (() -> Void)?
    private var onDismissed: (() -> Void)?
    private var onFailed: ((Error) -> Void)?
    private var autoReload: (() -> Void)?

    init(reporter: AdsEventReporter) {
        self.reporter = reporter
    }

    func hasCachedAd(for slot: AdsSlot) -> Bool {
        cachedAd(for: slot, format: cacheFormat(for: slot)) != nil
    }

    func load(
        slot: AdsSlot,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)? = nil
    ) {
        let format = cacheFormat(for: slot)
        guard cachedAd(for: slot, format: format) == nil else {
            onLoaded?()
            return
        }
        guard !isLoading(slot: slot, format: format) else {
            appendPendingLoadCallback(onLoaded, slot: slot, format: format)
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onLoaded?()
            return
        }

        startLoading(slot: slot, format: format)
        appendPendingLoadCallback(onLoaded, slot: slot, format: format)
        loadInterstitial(
            slot: slot,
            placements: placements,
            index: 0,
            format: format,
            retryPolicy: retryPolicy,
            runtimeContext: runtimeContext
        )
    }

    func showLoaded(
        slot: AdsSlot,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext,
        onShown: (() -> Void)?,
        onDismissed: (() -> Void)?,
        onFailed: ((Error) -> Void)?,
        autoReload: (() -> Void)?
    ) {
        guard let rootViewController = runtimeContext.topViewControllerProvider() else {
            onFailed?(AdsKitError.missingRootViewController)
            return
        }

        let format = cacheFormat(for: slot)
        guard let cachedAd = cachedAd(for: slot, format: format) else {
            reporter.record(
                AdsEvent(
                    kind: .skipped,
                    slotKey: slot.key,
                    adUnitId: nil,
                    format: format,
                    message: "Interstitial not ready",
                    timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                )
            )
            load(
                slot: slot,
                retryPolicy: retryPolicy,
                runtimeContext: runtimeContext
            )
            onDismissed?()
            return
        }

        activeSlotKey = slot.key
        activeFormat = format
        self.onShown = onShown
        self.onDismissed = onDismissed
        self.onFailed = onFailed
        self.autoReload = autoReload

        cachedAd.ad.present(from: rootViewController)
    }

    func showSplash(
        slot: AdsSlot,
        splashPolicy: AdsSplashInterstitialPolicy,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext,
        onShown: (() -> Void)?,
        onDismissed: (() -> Void)?,
        onFailed: ((Error) -> Void)?
    ) {
        guard let rootViewController = runtimeContext.topViewControllerProvider() else {
            onFailed?(AdsKitError.missingRootViewController)
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onDismissed?()
            return
        }

        if let cachedAd = cachedAd(for: slot, format: .splashInterstitial) {
            activeSlotKey = slot.key
            activeFormat = .splashInterstitial
            self.onShown = onShown
            self.onDismissed = onDismissed
            self.onFailed = onFailed
            autoReload = nil
            cachedAd.ad.present(from: rootViewController)
            return
        }

        let state = SplashLoadState()
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, !state.didFinish else { return }
            state.didFinish = true
            self.onFailed?(AdsKitError.loadFailed("Splash interstitial load timeout"))
            self.onDismissed?()
            self.resetPresentationCallbacks()
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Double(splashPolicy.loadTimeoutSeconds),
            execute: timeout
        )

        if isLoading(slot: slot, format: .splashInterstitial) {
            guard activeSlotKey == nil else {
                timeout.cancel()
                onDismissed?()
                return
            }

            activeSlotKey = slot.key
            activeFormat = .splashInterstitial
            self.onShown = onShown
            self.onDismissed = onDismissed
            self.onFailed = onFailed
            autoReload = nil

            appendPendingLoadCallback({ [weak self] in
                guard let self, !state.didFinish else { return }
                state.didFinish = true
                timeout.cancel()
                guard let cachedAd = self.cachedAd(for: slot, format: .splashInterstitial) else {
                    self.onFailed?(AdsKitError.loadFailed("Failed to load splash interstitial for slot '\(slot.key)'"))
                    self.onDismissed?()
                    self.resetPresentationCallbacks()
                    return
                }
                cachedAd.ad.present(from: rootViewController)
            }, slot: slot, format: .splashInterstitial)
            return
        }

        activeSlotKey = slot.key
        activeFormat = .splashInterstitial
        self.onShown = onShown
        self.onDismissed = onDismissed
        self.onFailed = onFailed
        autoReload = nil

        startLoading(slot: slot, format: .splashInterstitial)
        loadSplash(
            slot: slot,
            placements: placements,
            index: 0,
            rootViewController: rootViewController,
            timeout: timeout,
            state: state,
            retryPolicy: retryPolicy,
            runtimeContext: runtimeContext
        )
    }

    private func loadInterstitial(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        format: AdsFormat,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext
    ) {
        guard placements.indices.contains(index) else {
            stopLoading(slot: slot, format: format)
            if !scheduleRetry(
                slot: slot,
                format: format,
                retryPolicy: retryPolicy,
                runtimeContext: runtimeContext
            ) {
                finishPendingLoadCallbacks(slot: slot, format: format, didLoad: false)
            }
            return
        }

        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: format,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )

        InterstitialAd.load(
            with: placement.id,
            request: Request()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.reporter.record(
                        AdsEvent(
                            kind: .loadFailed,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: format,
                            message: error.localizedDescription,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: AdsErrorMetadata.make(from: error)
                        )
                    )
                    self.loadInterstitial(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        format: format,
                        retryPolicy: retryPolicy,
                        runtimeContext: runtimeContext
                    )
                    return
                }

                guard let ad else {
                    self.loadInterstitial(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        format: format,
                        retryPolicy: retryPolicy,
                        runtimeContext: runtimeContext
                    )
                    return
                }

                self.retryAttemptsBySlot[self.loadingKey(slot: slot, format: format)] = 0
                self.setCachedAd(ad, adUnitID: placement.id, slot: slot, format: format)
                ad.fullScreenContentDelegate = self
                ad.paidEventHandler = { @MainActor [weak self, weak ad] adValue in
                    self?.recordPaidEvent(
                        slotKey: slot.key,
                        format: format,
                        adUnitId: placement.id,
                        adapterName: ad?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
                        adValue: adValue,
                        runtimeContext: runtimeContext
                    )
                }
                self.reporter.record(
                    AdsEvent(
                        kind: .loadSucceeded,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: format,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.stopLoading(slot: slot, format: format)
                self.finishPendingLoadCallbacks(slot: slot, format: format, didLoad: true)
            }
        }
    }

    @discardableResult
    private func scheduleRetry(
        slot: AdsSlot,
        format: AdsFormat,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext
    ) -> Bool {
        let key = loadingKey(slot: slot, format: format)
        let attempts = retryAttemptsBySlot[key] ?? 0
        guard attempts + 1 < retryPolicy.maxAttempts else { return false }
        retryAttemptsBySlot[key] = attempts + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + retryPolicy.loadRetryDelaySeconds) { [weak self] in
            guard let self else { return }
            self.load(
                slot: slot,
                retryPolicy: retryPolicy,
                runtimeContext: runtimeContext
            )
        }
        return true
    }

    private func loadSplash(
        slot: AdsSlot,
        placements: [AdsPlacement],
        index: Int,
        rootViewController: UIViewController,
        timeout: DispatchWorkItem,
        state: SplashLoadState,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext
    ) {
        guard placements.indices.contains(index) else {
            state.didFinish = true
            timeout.cancel()
            stopLoading(slot: slot, format: .splashInterstitial)
            finishPendingLoadCallbacks(slot: slot, format: .splashInterstitial, didLoad: false)
            onFailed?(AdsKitError.loadFailed("Failed to load splash interstitial for slot '\(slot.key)'"))
            onDismissed?()
            resetPresentationCallbacks()
            return
        }

        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .splashInterstitial,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )

        InterstitialAd.load(
            with: placement.id,
            request: Request()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self, !state.didFinish else { return }

                if let error {
                    self.reporter.record(
                        AdsEvent(
                            kind: .loadFailed,
                            slotKey: slot.key,
                            adUnitId: placement.id,
                            format: .splashInterstitial,
                            message: error.localizedDescription,
                            timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000),
                            metadata: AdsErrorMetadata.make(from: error)
                        )
                    )
                    self.loadSplash(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        rootViewController: rootViewController,
                        timeout: timeout,
                        state: state,
                        retryPolicy: retryPolicy,
                        runtimeContext: runtimeContext
                    )
                    return
                }

                guard let ad else {
                    self.loadSplash(
                        slot: slot,
                        placements: placements,
                        index: index + 1,
                        rootViewController: rootViewController,
                        timeout: timeout,
                        state: state,
                        retryPolicy: retryPolicy,
                        runtimeContext: runtimeContext
                    )
                    return
                }

                state.didFinish = true
                timeout.cancel()
                self.retryAttemptsBySlot[self.loadingKey(slot: slot, format: .splashInterstitial)] = 0
                self.setCachedAd(ad, adUnitID: placement.id, slot: slot, format: .splashInterstitial)
                ad.fullScreenContentDelegate = self
                ad.paidEventHandler = { @MainActor [weak self, weak ad] adValue in
                    self?.recordPaidEvent(
                        slotKey: slot.key,
                        format: .splashInterstitial,
                        adUnitId: placement.id,
                        adapterName: ad?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
                        adValue: adValue,
                        runtimeContext: runtimeContext
                    )
                }
                self.reporter.record(
                    AdsEvent(
                        kind: .loadSucceeded,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .splashInterstitial,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.stopLoading(slot: slot, format: .splashInterstitial)
                self.finishPendingLoadCallbacks(slot: slot, format: .splashInterstitial, didLoad: true)
                ad.present(from: rootViewController)
            }
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        reporter.record(
            AdsEvent(
                kind: .willPresent,
                slotKey: activeSlotKey,
                adUnitId: currentAdUnitId(for: ad),
                format: activeFormat,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        onShown?()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        reporter.record(
            AdsEvent(
                kind: .didDismiss,
                slotKey: activeSlotKey,
                adUnitId: currentAdUnitId(for: ad),
                format: activeFormat,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        if activeFormat == .splashInterstitial {
            removeCachedAd(slotKey: activeSlotKey, format: .splashInterstitial)
        } else {
            removeCachedAd(slotKey: activeSlotKey, format: .interstitial)
            autoReload?()
        }

        onDismissed?()
        resetPresentationCallbacks()
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        onFailed?(error)
        reporter.record(
            AdsEvent(
                kind: .loadFailed,
                slotKey: activeSlotKey,
                adUnitId: currentAdUnitId(for: ad),
                format: activeFormat,
                message: error.localizedDescription,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000),
                metadata: AdsErrorMetadata.make(from: error)
            )
        )
        if activeFormat == .splashInterstitial {
            removeCachedAd(slotKey: activeSlotKey, format: .splashInterstitial)
        } else {
            removeCachedAd(slotKey: activeSlotKey, format: .interstitial)
        }
        resetPresentationCallbacks()
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        reporter.record(
            AdsEvent(
                kind: .click,
                slotKey: activeSlotKey,
                adUnitId: currentAdUnitId(for: ad),
                format: activeFormat,
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
    }

    private func currentAdUnitId(for ad: FullScreenPresentingAd) -> String? {
        if let interstitialAd = ad as? InterstitialAd {
            return interstitialAd.adUnitID
        }
        return nil
    }

    private func recordPaidEvent(
        slotKey: String,
        format: AdsFormat,
        adUnitId: String,
        adapterName: String?,
        adValue: AdValue,
        runtimeContext: AdsRuntimeContext
    ) {
        reporter.record(
            AdsEvent(
                kind: .paidImpression,
                slotKey: slotKey,
                adUnitId: adUnitId,
                format: format,
                mediationAdapterClassName: adapterName,
                valueMicros: adValue.value.doubleValue,
                precision: adValue.precision.rawValue,
                currencyCode: adValue.currencyCode,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )
    }

    private func resetPresentationCallbacks() {
        activeSlotKey = nil
        activeFormat = nil
        onShown = nil
        onDismissed = nil
        onFailed = nil
        autoReload = nil
    }

    private func cacheFormat(for slot: AdsSlot) -> AdsFormat {
        slot.format == .splashInterstitial ? .splashInterstitial : .interstitial
    }

    private func cachedAd(for slot: AdsSlot, format: AdsFormat) -> CachedInterstitialAd? {
        let cachedAd: CachedInterstitialAd?
        switch format {
        case .splashInterstitial:
            cachedAd = splashInterstitialAdsBySlot[slot.key]
        default:
            cachedAd = interstitialAdsBySlot[slot.key]
        }

        guard let cachedAd else { return nil }
        let validAdUnitIDs = Set(AdsPlacementResolver.loadOrder(for: slot).map(\.id))
        guard validAdUnitIDs.contains(cachedAd.adUnitID) else {
            removeCachedAd(slotKey: slot.key, format: format)
            return nil
        }
        return cachedAd
    }

    private func setCachedAd(
        _ ad: InterstitialAd,
        adUnitID: String,
        slot: AdsSlot,
        format: AdsFormat
    ) {
        let cachedAd = CachedInterstitialAd(ad: ad, adUnitID: adUnitID)
        switch format {
        case .splashInterstitial:
            splashInterstitialAdsBySlot[slot.key] = cachedAd
        default:
            interstitialAdsBySlot[slot.key] = cachedAd
        }
    }

    private func removeCachedAd(slotKey: String?, format: AdsFormat?) {
        guard let slotKey, let format else { return }
        switch format {
        case .splashInterstitial:
            splashInterstitialAdsBySlot[slotKey] = nil
        default:
            interstitialAdsBySlot[slotKey] = nil
        }
    }

    private func loadingKey(slot: AdsSlot, format: AdsFormat) -> String {
        "\(format.rawValue)|\(slot.key)"
    }

    private func isLoading(slot: AdsSlot, format: AdsFormat) -> Bool {
        loadingKeys.contains(loadingKey(slot: slot, format: format))
    }

    private func startLoading(slot: AdsSlot, format: AdsFormat) {
        loadingKeys.insert(loadingKey(slot: slot, format: format))
    }

    private func stopLoading(slot: AdsSlot, format: AdsFormat) {
        loadingKeys.remove(loadingKey(slot: slot, format: format))
    }

    private func appendPendingLoadCallback(
        _ callback: (() -> Void)?,
        slot: AdsSlot,
        format: AdsFormat
    ) {
        guard let callback else { return }
        pendingLoadCallbacksByKey[loadingKey(slot: slot, format: format), default: []].append(callback)
    }

    private func finishPendingLoadCallbacks(
        slot: AdsSlot,
        format: AdsFormat,
        didLoad: Bool
    ) {
        let key = loadingKey(slot: slot, format: format)
        let callbacks = pendingLoadCallbacksByKey[key] ?? []
        pendingLoadCallbacksByKey[key] = nil
        guard didLoad else { return }
        callbacks.forEach { $0() }
    }
}
