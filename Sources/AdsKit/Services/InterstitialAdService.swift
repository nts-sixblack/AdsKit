import Foundation
@preconcurrency import Dispatch
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdService: NSObject, FullScreenContentDelegate {
    private final class SplashLoadState {
        var didFinish = false
    }

    private let reporter: AdsEventReporter

    private(set) var interstitialAd: InterstitialAd?
    private(set) var splashInterstitialAd: InterstitialAd?

    private var isLoading = false
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

    func load(
        slot: AdsSlot,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)? = nil
    ) {
        guard !isLoading else { return }
        guard interstitialAd == nil else {
            onLoaded?()
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onLoaded?()
            return
        }

        loadInterstitial(
            slot: slot,
            placements: placements,
            index: 0,
            retryPolicy: retryPolicy,
            runtimeContext: runtimeContext,
            onLoaded: onLoaded
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

        guard let interstitialAd else {
            reporter.record(
                AdsEvent(
                    kind: .skipped,
                    slotKey: slot.key,
                    adUnitId: nil,
                    format: .interstitial,
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
        activeFormat = .interstitial
        self.onShown = onShown
        self.onDismissed = onDismissed
        self.onFailed = onFailed
        self.autoReload = autoReload

        interstitialAd.present(from: rootViewController)
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

        activeSlotKey = slot.key
        activeFormat = .splashInterstitial
        self.onShown = onShown
        self.onDismissed = onDismissed
        self.onFailed = onFailed
        autoReload = nil

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
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)?
    ) {
        guard placements.indices.contains(index) else {
            scheduleRetry(
                slot: slot,
                retryPolicy: retryPolicy,
                runtimeContext: runtimeContext,
                onLoaded: onLoaded
            )
            return
        }

        isLoading = true
        let placement = placements[index]
        reporter.record(
            AdsEvent(
                kind: .loadRequested,
                slotKey: slot.key,
                adUnitId: placement.id,
                format: .interstitial,
                timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
            )
        )

        InterstitialAd.load(
            with: placement.id,
            request: Request()
        ) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false

            if let error {
                self.reporter.record(
                    AdsEvent(
                        kind: .loadFailed,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .interstitial,
                        message: error.localizedDescription,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                    )
                )
                self.loadInterstitial(
                    slot: slot,
                    placements: placements,
                    index: index + 1,
                    retryPolicy: retryPolicy,
                    runtimeContext: runtimeContext,
                    onLoaded: onLoaded
                )
                return
            }

            self.retryAttemptsBySlot[slot.key] = 0
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.interstitialAd?.paidEventHandler = { [weak self] adValue in
                self?.recordPaidEvent(
                    slotKey: slot.key,
                    format: .interstitial,
                    adUnitId: placement.id,
                    adapterName: self?.interstitialAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
                    adValue: adValue,
                    runtimeContext: runtimeContext
                )
            }
            self.reporter.record(
                AdsEvent(
                    kind: .loadSucceeded,
                    slotKey: slot.key,
                    adUnitId: placement.id,
                    format: .interstitial,
                    timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
                )
            )
            onLoaded?()
        }
    }

    private func scheduleRetry(
        slot: AdsSlot,
        retryPolicy: AdsRetryPolicy,
        runtimeContext: AdsRuntimeContext,
        onLoaded: (() -> Void)?
    ) {
        let attempts = retryAttemptsBySlot[slot.key] ?? 0
        guard attempts + 1 < retryPolicy.maxAttempts else { return }
        retryAttemptsBySlot[slot.key] = attempts + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + retryPolicy.loadRetryDelaySeconds) { [weak self] in
            guard let self else { return }
            self.load(
                slot: slot,
                retryPolicy: retryPolicy,
                runtimeContext: runtimeContext,
                onLoaded: onLoaded
            )
        }
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
            guard let self, !state.didFinish else { return }

            if let error {
                self.reporter.record(
                    AdsEvent(
                        kind: .loadFailed,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .splashInterstitial,
                        message: error.localizedDescription,
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
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

            state.didFinish = true
            timeout.cancel()
            self.retryAttemptsBySlot[slot.key] = 0
            self.splashInterstitialAd = ad
            self.splashInterstitialAd?.fullScreenContentDelegate = self
            self.splashInterstitialAd?.paidEventHandler = { [weak self] adValue in
                self?.recordPaidEvent(
                    slotKey: slot.key,
                    format: .splashInterstitial,
                    adUnitId: placement.id,
                    adapterName: self?.splashInterstitialAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
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
            ad?.present(from: rootViewController)
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
            splashInterstitialAd = nil
        } else {
            interstitialAd = nil
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
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        if activeFormat == .splashInterstitial {
            splashInterstitialAd = nil
        } else {
            interstitialAd = nil
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
}
