import Foundation
@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class AppOpenAdService: NSObject, FullScreenContentDelegate {
    private let reporter: AdsEventReporter

    private(set) var appOpenAd: AppOpenAd?
    private(set) var isShowingAppOpenAd = false

    private var activeSlotKey: String?
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
        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            onLoaded?()
            return
        }
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
        onDismissed: (() -> Void)?
    ) {
        self.onDismissed = onDismissed
        activeSlotKey = slot.key

        guard let rootViewController = runtimeContext.topViewControllerProvider() else {
            self.onDismissed?()
            self.onDismissed = nil
            return
        }

        if let appOpenAd {
            appOpenAd.present(from: rootViewController)
            return
        }

        guard policy.loadOnDemandIfNeeded else {
            self.onDismissed?()
            self.onDismissed = nil
            return
        }

        let placements = AdsPlacementResolver.loadOrder(for: slot)
        guard !placements.isEmpty else {
            self.onDismissed?()
            self.onDismissed = nil
            return
        }

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
        guard placements.indices.contains(index) else { return }
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
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
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
            onDismissed?()
            onDismissed = nil
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
                        timestampMs: Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
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
            ad?.present(from: rootViewController)
        }
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        isShowingAppOpenAd = true
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
                timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        appOpenAd = nil
        onDismissed?()
        onDismissed = nil
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
}
