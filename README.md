# AdsKit

Reusable iOS 16+ Swift Package for AdMob-based ads, designed for reuse across multiple apps.

## What is included

- Banner ads
- Interstitial ads
- Splash interstitial ads
- Rewarded ads
- App open ads
- Native ads with multiple built-in styles
- Collapse native ads with an expanded media state and compact ad-icon row
- Native preload/cache support
- Slot-scoped fullscreen and native cache readiness checks
- Fallback placements
- Runtime-updatable config
- Idempotent config/runtime updates
- Pluggable event sink API
- Banner and fullscreen load lifecycle reporting
- Google Mobile Ads error metadata on failed loads and presentations
- SwiftInjected integration

## Installation

1. Add `AdsKit` to your app with Swift Package Manager.
2. `AdsKit` resolves Google Mobile Ads SDK and SwiftInjected automatically.
3. In the host app, add `GADApplicationIdentifier` and the required `SKAdNetworkItems` to `Info.plist`.
4. Call `startGoogleMobileAds()` once during startup.
5. Build your `AdsConfiguration`, then inject runtime state through `AdsRuntimeContext`.

Google quick start: <https://developers.google.com/ad-manager/mobile-ads-sdk/ios/quick-start>

`AdsKit` does not bundle mediation adapters. If your host app uses mediation, install and maintain those adapters in the host app.

## Host checklist

- Set `GADApplicationIdentifier` in `Info.plist`.
- Add Google `SKAdNetworkItems` entries required by your ad stack.
- Call `startGoogleMobileAds()` once during app startup.
- Pass a valid `topViewControllerProvider` into `AdsRuntimeContext` so fullscreen formats can present correctly.
- Wire `AdsEventSink` into your analytics layer if you need Firebase, Meta, Adjust, or custom event forwarding.
- Keep mediation adapters in the host app. AdsKit only wraps the core Google Mobile Ads SDK.

## Quick start

```swift
import AdsKit

let configuration = AdsConfiguration(
    slots: [
        AdsSlot(
            key: "splash_inter",
            format: .splashInterstitial,
            primaryPlacement: .init(id: "your_splash_interstitial_ad_unit_id", isEnabled: true)
        ),
        AdsSlot(
            key: "language_native",
            format: .native,
            primaryPlacement: .init(id: "your_native_ad_unit_id", isEnabled: true),
            fallbackPlacement: .init(id: "your_native_fallback_ad_unit_id", isEnabled: true)
        ),
        AdsSlot(
            key: "home_banner",
            format: .banner,
            primaryPlacement: .init(id: "your_banner_ad_unit_id", isEnabled: true)
        )
    ],
    preload: .init(
        interstitialKeys: ["splash_inter"],
        manual: .init(nativeKeys: ["language_native"])
    ),
    debug: .init(usesTestAdUnitIDs: true)
)

let adsManager = AdsKitManager(
    configuration: configuration,
    runtimeContext: AdsRuntimeContext(
        isAdsEnabled: true,
        isPremiumUser: false,
        isFirstAppOpen: true
    ),
    eventSink: ClosureAdsEventSink { event in
        print("[AdsKit event]", event.kind.rawValue, event.slotKey ?? "-")
    }
)

adsManager.startGoogleMobileAds()
adsManager.preloadConfiguredSlots()
```

Call manual preloads right before the screen that needs them:

```swift
adsManager.preloadManualSlots()
// or target one native slot directly
adsManager.preloadNative(slotKey: "language_native")
```

Preloaded fullscreen and native ads are cached per slot key and validated against the current slot placements before reuse. You can check readiness without starting a new load:

```swift
adsManager.hasLoadedInterstitial(slotKey: "splash_inter")
adsManager.hasLoadedRewarded(slotKey: "coins_rewarded")
adsManager.hasLoadedAppOpen(slotKey: "launch_app_open")
adsManager.hasLoadedNative(slotKey: "language_native")
```

## SwiftUI usage

```swift
struct HomeView: View {
    @StateObject private var adsManager = makeAdsManager()

    var body: some View {
        VStack(spacing: 16) {
            BannerAdsView(
                slotKey: "home_banner",
                manager: adsManager
            )

            NativeAdsView(
                slotKey: "language_native",
                manager: adsManager,
                style: .large()
            )
        }
    }
}
```

When `adSize` is omitted, `BannerAdsView` measures the SwiftUI container width and creates an adaptive banner capped to the standard banner envelope, so wider containers do not inflate the ad and break nearby layout. Pass an explicit Google Mobile Ads `AdSize` when the host screen needs a fixed, larger, or fully custom banner size.

The banner view does not reserve vertical space while its width is unknown, when the slot cannot display, or after a load failure.

## UIKit usage

```swift
final class HomeViewController: UIViewController {
    private lazy var adsManager = AdsKitManager(
        configuration: makeAdsConfiguration(),
        runtimeContext: AdsRuntimeContext(
            isAdsEnabled: true,
            isPremiumUser: false,
            isFirstAppOpen: false,
            topViewControllerProvider: { [weak self] in self }
        )
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        adsManager.startGoogleMobileAds()
        adsManager.loadInterstitial(slotKey: "share_inter")
    }

    @IBAction private func didTapShare() {
        adsManager.showInterstitial(slotKey: "share_inter")
    }
}
```

For banner/native content on UIKit screens, embed `BannerAdsView` or `NativeAdsView` with `UIHostingController`, or bind `NativeAdViewModel` into your own `UIView` container if you need a custom layout.

`NativeAdViewStyle.collapse` starts expanded when the ad has primary media. After collapse, the compact row shows the ad icon before the headline and hides the media thumbnail from layout, while still keeping media registered for Google Mobile Ads validation.

## Events

Use `AdsEventSink` to forward ad events into Firebase, Meta, Adjust, your own analytics, or logging.

```swift
final class AnalyticsSink: AdsEventSink {
    func record(_ event: AdsEvent) {
        // Map to your analytics pipeline here.
    }
}
```

`BannerAdsView` reports `load_requested`, `load_succeeded`, `load_failed`, and `click` events. SwiftUI refreshes only trigger a new banner load when the ad unit, ad size, or collapse setting changes, so view updates no longer inflate banner request counts.

Failed load and presentation events include structured metadata when Google Mobile Ads exposes it. Common keys include `error_domain`, `error_code`, `underlying_error_domain`, `response_identifier`, `adapter_response_count`, `loaded_adapter_name`, and first-adapter error details.

Calling `apply(configuration:)` with the same configuration, or updating runtime flags to their current values, is a no-op and does not emit duplicate analytics events.

Fullscreen services keep separate cached ads and in-flight loads per `slotKey`, so an ad loaded for one logical slot is not presented or attributed as another slot. Splash interstitial presentation also consumes a matching preloaded splash cache before starting an on-demand request.

Set `configuration.policies.splashInterstitial.autoReloadAfterDismiss` to `true` when a splash slot should automatically request its next ad only after the current splash has fully dismissed.

## SwiftInjected

`AdsKit` includes a `Dependency.adsKitManager(...)` helper for `SwiftInjected`. Files that use `Dependencies`, `@Injected`, or `@InjectedObservable` should import both `AdsKit` and `SwiftInjected`.

```swift
import AdsKit
import SwiftInjected

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
                print("[AdsKit]", event.kind.rawValue, event.slotKey ?? "-")
            },
            bootstrap: { manager in
                manager.startGoogleMobileAds()
                manager.preloadConfiguredSlots()
            }
        )
    }
    dependencies.build()
}

struct HomeView: View {
    @InjectedObservable var adsManager: AdsKitManager

    var body: some View {
        BannerAdsView(slotKey: "home_banner", manager: adsManager)
    }
}
```

## More docs

- [`Docs/CONFIGURATION.md`](Docs/CONFIGURATION.md)
- [`Docs/REMOTE_CONFIG_SAMPLE.md`](Docs/REMOTE_CONFIG_SAMPLE.md)
- [`Docs/MIGRATION.md`](Docs/MIGRATION.md)
- [`Docs/UPDATING.md`](Docs/UPDATING.md)

## Example app

An iOS sample app is included at `Example/AdsExample`. It enables `debug.usesTestAdUnitIDs` and demonstrates banner, native, interstitial, rewarded, and app open flows with the package directly.
