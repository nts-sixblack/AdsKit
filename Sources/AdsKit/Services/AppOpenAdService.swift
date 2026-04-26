import Foundation
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class AppOpenAdService: NSObject, FullScreenContentDelegate {
    private let reporter: AdsEventReporter

    private(set) var appOpenAd: AppOpenAd?
    private(set) var isShowingAppOpenAd = false
    private var isLoading = false

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
        guard appOpenAd == nil else {
            onLoaded?()
            return
        }
        guard !isLoading else { return }
        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onLoaded?()
            return
        }
        isLoading = true
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

        if let appOpenAd {
            self.onShown = onShown
            self.onDismissed = onDismissed
            activeSlotKey = slot.key
            appOpenAd.present(from: rootViewController)
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

        guard !isLoading else {
            onDismissed?()
            return
        }

        self.onShown = onShown
        self.onDismissed = onDismissed
        activeSlotKey = slot.key
        isLoading = true
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
            isLoading = false
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
            self.isLoading = false
            guard let ad else { return }
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.appOpenAd?.paidEventHandler = { [weak self] adValue in
                self?.reporter.record(
                    AdsEvent(
                        kind: .paidImpression,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .appOpen,
                        mediationAdapterClassName: self?.appOpenAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
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
            onLoaded?()
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
            isLoading = false
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

            self.isLoading = false
            guard let ad else {
                self.finishWithoutPresentation()
                return
            }

            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.appOpenAd?.paidEventHandler = { [weak self] adValue in
                self?.reporter.record(
                    AdsEvent(
                        kind: .paidImpression,
                        slotKey: slot.key,
                        adUnitId: placement.id,
                        format: .appOpen,
                        mediationAdapterClassName: self?.appOpenAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName,
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
            ad.present(from: rootViewController)
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
        appOpenAd = nil
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
        appOpenAd = nil
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
}
