//
//  AdsManager.swift
//  AdsExample
//

import AdsKit
import SwiftInjected

/// Builds and registers a shared `AdsKitManager` using Google test ad-unit IDs.
@MainActor
func setupDependencies() {
  let dependencies = Dependencies {
    Dependency.adsKitManager(
      configuration: makeAdsConfiguration(),
      runtimeContext: AdsRuntimeContext(
        isAdsEnabled: true,
        isPremiumUser: false,
        isFirstAppOpen: false
      ),
      eventSink: ClosureAdsEventSink { event in
        print("[AdsKit]", event.kind.rawValue, event.slotKey ?? "-", event.message ?? "")
      },
      bootstrap: { manager in
        manager.startGoogleMobileAds()
        manager.preloadConfiguredSlots()
      }
    )
  }

  dependencies.build()
}

private func makeAdsConfiguration() -> AdsConfiguration {
  AdsConfiguration(
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
      manual: .init(nativeKeys: ["demo_native"])
    ),
    theme: .init(
      cardBackgroundHex: "#F8FAFC",
      primaryTextHex: "#0F172A",
      secondaryTextHex: "#475467",
      accentHex: "#F6C453",
      accentTextHex: "#111111",
      mutedBackgroundHex: "#EEF2F6",
      mutedTextHex: "#667085",
      borderHex: "#D0D5DD",
      borderOpacity: 0.8,
      collapseButton: .init(
        symbolName: "chevron.down",
        iconHex: "#0F172A",
        backgroundHex: "#FFFFFFE6",
        borderHex: "#D0D5DD",
        borderOpacity: 0.95,
        touchTargetSize: 44,
        visualSize: 28,
        iconPointSize: 13,
        topInset: 10,
        trailingInset: 10
      )
    ),
    debug: .init(isVerboseLoggingEnabled: true, logSkippedShows: true)
  )
}
