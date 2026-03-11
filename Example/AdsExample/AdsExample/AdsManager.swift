//
//  AdsManager.swift
//  AdsExample
//

import AdsKit

/// Factory that builds a fully-configured `AdsKitManager` using Google test ad-unit IDs.
@MainActor
func makeAdsManager() -> AdsKitManager {
  let configuration = AdsConfiguration(
    slots: [
      // Banner
      AdsSlot(
        key: "home_banner",
        format: .banner,
        primaryPlacement: .init(id: "ca-app-pub-3940256099942544/2934735716", isEnabled: true)
      ),
      // Splash Interstitial
      AdsSlot(
        key: "splash_inter",
        format: .splashInterstitial,
        primaryPlacement: .init(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
      ),
      // Interstitial
      AdsSlot(
        key: "demo_inter",
        format: .interstitial,
        primaryPlacement: .init(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
      ),
      // Rewarded
      AdsSlot(
        key: "demo_rewarded",
        format: .rewarded,
        primaryPlacement: .init(id: "ca-app-pub-3940256099942544/1712485313", isEnabled: true)
      ),
      // App Open
      AdsSlot(
        key: "demo_app_open",
        format: .appOpen,
        primaryPlacement: .init(id: "ca-app-pub-3940256099942544/5575463023", isEnabled: true)
      ),
      // Native
      AdsSlot(
        key: "demo_native",
        format: .native,
        primaryPlacement: .init(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true)
      ),
    ],
    policies: .init(
      appOpen: .init(waitForSecondOpportunity: false)
    ),
    preload: .init(
      interstitialKeys: ["demo_inter"],
      nativeKeys: ["demo_native"]
    ),
    debug: .init(isVerboseLoggingEnabled: true, logSkippedShows: true)
  )

  return AdsKitManager(
    configuration: configuration,
    runtimeContext: AdsRuntimeContext(
      isAdsEnabled: true,
      isPremiumUser: false,
      isFirstAppOpen: false
    ),
    eventSink: ClosureAdsEventSink { event in
      print("[AdsKit]", event.kind.rawValue, event.slotKey ?? "-", event.message ?? "")
    }
  )
}
