import Foundation
@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
public final class AdsKitManager: NSObject, ObservableObject {
    @Published public private(set) var configuration: AdsConfiguration
    @Published public private(set) var runtimeContext: AdsRuntimeContext
    @Published public private(set) var isShowingFullscreenAd: Bool = false

    let eventReporter: AdsEventReporter
    let bannerAdService: BannerAdService
    private let interstitialAdService: InterstitialAdService
    private let rewardedAdService: RewardedAdService
    private let appOpenAdService: AppOpenAdService

    private var decisionState = AdsDecisionState()
    private var nativeViewModels: [String: NativeAdViewModel] = [:]

    public init(
        configuration: AdsConfiguration = .init(),
        runtimeContext: AdsRuntimeContext = .init(),
        eventSink: AdsEventSink? = nil
    ) {
        self.configuration = configuration
        self.runtimeContext = runtimeContext
        eventReporter = AdsEventReporter(
            sink: eventSink,
            debugOptions: configuration.debug
        )
        bannerAdService = BannerAdService()
        interstitialAdService = InterstitialAdService(reporter: eventReporter)
        rewardedAdService = RewardedAdService(reporter: eventReporter)
        appOpenAdService = AppOpenAdService(reporter: eventReporter)
        super.init()
    }

    public func startGoogleMobileAds(
        completion: ((InitializationStatus) -> Void)? = nil
    ) {
        MobileAds.shared.start { status in
            completion?(status)
        }
    }

    public func apply(configuration: AdsConfiguration) {
        let oldConfiguration = self.configuration
        self.configuration = configuration
        eventReporter.debugOptions = configuration.debug

        let oldNativePolicy = oldConfiguration.policies.native
        let newNativePolicy = configuration.policies.native

        let keys = Array(nativeViewModels.keys)
        for key in keys {
            let oldSlot = oldConfiguration.slot(forKey: key)
            let newSlot = configuration.slot(forKey: key)
            if oldSlot != newSlot || oldNativePolicy != newNativePolicy {
                nativeViewModels.removeValue(forKey: key)
            }
        }

        eventReporter.record(
            AdsEvent(
                kind: .configurationApplied,
                timestampMs: currentTimestampMs()
            )
        )
    }

    public func updateEventSink(_ sink: AdsEventSink?) {
        eventReporter.sink = sink
    }

    public func updateRuntimeContext(_ runtimeContext: AdsRuntimeContext) {
        self.runtimeContext = runtimeContext
        eventReporter.record(
            AdsEvent(
                kind: .runtimeUpdated,
                timestampMs: currentTimestampMs(),
                metadata: [
                    "ads_enabled": "\(runtimeContext.isAdsEnabled)",
                    "premium_user": "\(runtimeContext.isPremiumUser)",
                    "first_app_open": "\(runtimeContext.isFirstAppOpen)"
                ]
            )
        )
    }

    public func updateAdsEnabled(_ isEnabled: Bool) {
        runtimeContext.isAdsEnabled = isEnabled
        updateRuntimeContext(runtimeContext)
    }

    public func updatePremiumStatus(_ isPremiumUser: Bool) {
        runtimeContext.isPremiumUser = isPremiumUser
        updateRuntimeContext(runtimeContext)
    }

    public func updateFirstAppOpen(_ isFirstAppOpen: Bool) {
        runtimeContext.isFirstAppOpen = isFirstAppOpen
        updateRuntimeContext(runtimeContext)
    }

    public func suppressAppOpenAdOnce() {
        decisionState.suppressNextAppOpenAd = true
    }

    public func suppressSplashInterstitialOnce() {
        decisionState.suppressNextSplashInterstitial = true
    }

    public func slot(forKey key: String) -> AdsSlot? {
        configuration.slot(forKey: key)
    }

    public func canDisplay(slotKey: String) -> Bool {
        guard let slot = configuration.slot(forKey: slotKey) else { return false }
        return canDisplay(slot: slot)
    }

    public func loadInterstitial(
        slotKey: String,
        onLoaded: (() -> Void)? = nil
    ) {
        guard let slot = resolveSlot(
            forKey: slotKey,
            expectedFormats: [.interstitial, .splashInterstitial]
        ) else {
            return
        }
        guard canDisplay(slot: slot) else {
            onLoaded?()
            return
        }
        interstitialAdService.load(
            slot: slot,
            retryPolicy: configuration.policies.retry,
            runtimeContext: runtimeContext,
            onLoaded: onLoaded
        )
    }

    public func showInterstitial(
        slotKey: String,
        onDismissed: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        onShown: (() -> Void)? = nil
    ) {
        guard let slot = resolveSlot(
            forKey: slotKey,
            expectedFormats: [.interstitial, .splashInterstitial]
        ) else {
            onFailed?(AdsKitError.slotNotFound(slotKey))
            return
        }
        guard canDisplay(slot: slot) else {
            onDismissed?()
            return
        }

        let nowMs = currentTimestampMs()
        let shouldShow = AdsDecisionEngine.shouldShowInterstitial(
            state: &decisionState,
            slotKey: slot.key,
            policy: configuration.policies.interstitial,
            nowMs: nowMs
        )
        guard shouldShow else {
            eventReporter.record(
                AdsEvent(
                    kind: .skipped,
                    slotKey: slot.key,
                    adUnitId: nil,
                    format: .interstitial,
                    message: "Interstitial gating prevented display",
                    timestampMs: nowMs
                )
            )
            onDismissed?()
            return
        }

        isShowingFullscreenAd = true
        interstitialAdService.showLoaded(
            slot: slot,
            retryPolicy: configuration.policies.retry,
            runtimeContext: runtimeContext,
            onShown: { [weak self] in
                guard let self else { return }
                AdsDecisionEngine.recordInterstitialShown(
                    state: &self.decisionState,
                    slotKey: slot.key,
                    nowMs: self.currentTimestampMs()
                )
                onShown?()
            },
            onDismissed: { [weak self] in
                guard let self else { return }
                self.isShowingFullscreenAd = false
                onDismissed?()
            },
            onFailed: { [weak self] error in
                self?.isShowingFullscreenAd = false
                onFailed?(error)
            },
            autoReload: configuration.policies.interstitial.autoReloadAfterDismiss ? { [weak self] in
                self?.loadInterstitial(slotKey: slot.key)
            } : nil
        )
    }

    public func showSplashInterstitial(
        slotKey: String,
        onDismissed: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        onShown: (() -> Void)? = nil
    ) {
        guard configuration.policies.splashInterstitial.isEnabled else {
            onDismissed?()
            return
        }
        guard !AdsDecisionEngine.consumeSplashSuppression(state: &decisionState) else {
            onDismissed?()
            return
        }
        guard let slot = resolveSlot(
            forKey: slotKey,
            expectedFormats: [.interstitial, .splashInterstitial]
        ) else {
            onFailed?(AdsKitError.slotNotFound(slotKey))
            return
        }
        guard canDisplay(slot: slot) else {
            onDismissed?()
            return
        }

        isShowingFullscreenAd = true
        interstitialAdService.showSplash(
            slot: slot,
            splashPolicy: configuration.policies.splashInterstitial,
            retryPolicy: configuration.policies.retry,
            runtimeContext: runtimeContext,
            onShown: { [weak self] in
                guard let self else { return }
                AdsDecisionEngine.recordInterstitialShown(
                    state: &self.decisionState,
                    slotKey: slot.key,
                    nowMs: self.currentTimestampMs()
                )
                onShown?()
            },
            onDismissed: { [weak self] in
                self?.isShowingFullscreenAd = false
                onDismissed?()
            },
            onFailed: { [weak self] error in
                self?.isShowingFullscreenAd = false
                onFailed?(error)
            }
        )
    }

    public func loadRewarded(
        slotKey: String,
        onLoaded: (() -> Void)? = nil
    ) {
        guard let slot = resolveSlot(forKey: slotKey, expectedFormats: [.rewarded]) else {
            return
        }
        guard canDisplay(slot: slot) else { return }
        rewardedAdService.load(
            slot: slot,
            runtimeContext: runtimeContext,
            onLoaded: onLoaded
        )
    }

    public func showRewarded(
        slotKey: String,
        onDismissed: (() -> Void)? = nil,
        onReward: @escaping (AdReward?) -> Void
    ) {
        guard let slot = resolveSlot(forKey: slotKey, expectedFormats: [.rewarded]) else {
            onReward(nil)
            return
        }
        guard canDisplay(slot: slot) else {
            onReward(nil)
            return
        }

        isShowingFullscreenAd = true
        rewardedAdService.show(
            slot: slot,
            runtimeContext: runtimeContext,
            onDismissed: { [weak self] in
                guard let self else { return }
                self.isShowingFullscreenAd = false
                onDismissed?()
            },
            onReward: { [weak self] reward in
                guard let self else {
                    onReward(reward)
                    return
                }
                AdsDecisionEngine.recordOtherFullscreenShown(
                    state: &self.decisionState,
                    nowMs: self.currentTimestampMs()
                )
                onReward(reward)
            }
        )
    }

    public func loadAppOpen(
        slotKey: String,
        onLoaded: (() -> Void)? = nil
    ) {
        guard let slot = resolveSlot(forKey: slotKey, expectedFormats: [.appOpen]) else {
            return
        }
        guard canDisplay(slot: slot) else { return }
        appOpenAdService.load(
            slot: slot,
            runtimeContext: runtimeContext,
            onLoaded: onLoaded
        )
    }

    public func showAppOpen(
        slotKey: String,
        onDismissed: (() -> Void)? = nil
    ) {
        guard let slot = resolveSlot(forKey: slotKey, expectedFormats: [.appOpen]) else {
            onDismissed?()
            return
        }
        guard canDisplay(slot: slot) else {
            onDismissed?()
            return
        }

        let shouldShow = AdsDecisionEngine.shouldShowAppOpen(
            state: &decisionState,
            runtimeContext: runtimeContext,
            policy: configuration.policies.appOpen,
            isShowingFullscreenAd: isShowingFullscreenAd || appOpenAdService.isShowingAppOpenAd,
            nowMs: currentTimestampMs()
        )
        guard shouldShow else {
            onDismissed?()
            return
        }

        isShowingFullscreenAd = true
        appOpenAdService.show(
            slot: slot,
            runtimeContext: runtimeContext,
            policy: configuration.policies.appOpen,
            onDismissed: { [weak self] in
                guard let self else { return }
                self.isShowingFullscreenAd = false
                AdsDecisionEngine.recordAppOpenShown(
                    state: &self.decisionState,
                    nowMs: self.currentTimestampMs()
                )
                onDismissed?()
            }
        )
    }

    public func preloadConfiguredSlots() {
        preload(slotGroup: configuration.preload.startup)
    }

    public func preloadManualSlots() {
        preload(slotGroup: configuration.preload.manual)
    }

    public func preloadNative(slotKey: String) {
        guard let viewModel = nativeViewModel(for: slotKey) else { return }
        eventReporter.record(
            AdsEvent(
                kind: .preloadCreated,
                slotKey: slotKey,
                format: .native,
                timestampMs: currentTimestampMs()
            )
        )
        viewModel.refreshAd()
    }

    public func refreshNative(slotKey: String, force: Bool = false) {
        nativeViewModel(for: slotKey)?.refreshAd(force: force)
    }

    public func nativeViewModel(for slotKey: String) -> NativeAdViewModel? {
        if let cachedViewModel = nativeViewModels[slotKey] {
            return cachedViewModel
        }
        guard let slot = resolveSlot(forKey: slotKey, expectedFormats: [.native]) else {
            return nil
        }

        let viewModel = NativeAdViewModel(
            slot: slot,
            policy: configuration.policies.native,
            runtimeProvider: { [weak self] in
                self?.runtimeContext ?? .init()
            },
            eventReporter: eventReporter
        )
        nativeViewModels[slotKey] = viewModel
        return viewModel
    }

    public func presentAdInspector() {
        guard let rootViewController = runtimeContext.topViewControllerProvider() else {
            return
        }
        MobileAds.shared.presentAdInspector(from: rootViewController) { _ in }
    }

    func recordBannerPaidEvent(
        slotKey: String,
        adUnitId: String,
        adValue: AdValue,
        bannerView: BannerView
    ) {
        eventReporter.record(
            AdsEvent(
                kind: .paidImpression,
                slotKey: slotKey,
                adUnitId: adUnitId,
                format: .banner,
                mediationAdapterClassName: bannerView.responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName,
                valueMicros: adValue.value.doubleValue,
                precision: adValue.precision.rawValue,
                currencyCode: adValue.currencyCode,
                timestampMs: currentTimestampMs()
            )
        )
    }

    func recordBannerClick(
        slotKey: String,
        adUnitId: String
    ) {
        eventReporter.record(
            AdsEvent(
                kind: .click,
                slotKey: slotKey,
                adUnitId: adUnitId,
                format: .banner,
                timestampMs: currentTimestampMs()
            )
        )
    }

    func currentTimestampMs() -> Int64 {
        Int64(runtimeContext.nowProvider().timeIntervalSince1970 * 1000)
    }

    private func canDisplay(slot: AdsSlot) -> Bool {
        guard runtimeContext.isAdsEnabled else { return false }
        guard !runtimeContext.isPremiumUser else { return false }
        guard AdsPlacementResolver.preferredPlacement(for: slot) != nil else { return false }
        if slot.format == .appOpen {
            guard !runtimeContext.isFirstAppOpen else { return false }
        }
        return true
    }

    private func preload(slotGroup: AdsPreloadSlotGroup) {
        slotGroup.interstitialKeys.forEach { loadInterstitial(slotKey: $0) }
        slotGroup.rewardedKeys.forEach { loadRewarded(slotKey: $0) }
        slotGroup.appOpenKeys.forEach { loadAppOpen(slotKey: $0) }
        slotGroup.nativeKeys.forEach { preloadNative(slotKey: $0) }
    }

    private func resolveSlot(
        forKey key: String,
        expectedFormats: [AdsFormat]
    ) -> AdsSlot? {
        guard let slot = configuration.slot(forKey: key) else {
            return nil
        }
        guard expectedFormats.contains(slot.format) else {
            return nil
        }
        return slot
    }
}
