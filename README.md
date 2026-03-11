# AdsKit

Reusable iOS 16+ Swift Package for AdMob-based ads, designed for reuse across multiple apps.

## What is included

- Banner ads
- Interstitial ads
- Splash interstitial ads
- Rewarded ads
- App open ads
- Native ads with multiple built-in styles
- Native preload/cache support
- Fallback placements
- Runtime-updatable config
- Pluggable event sink API
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
            primaryPlacement: .init(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
        ),
        AdsSlot(
            key: "language_native",
            format: .native,
            primaryPlacement: .init(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true),
            fallbackPlacement: .init(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true)
        ),
        AdsSlot(
            key: "home_banner",
            format: .banner,
            primaryPlacement: .init(id: "ca-app-pub-3940256099942544/2934735716", isEnabled: true)
        )
    ],
    preload: .init(nativeKeys: ["language_native"])
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

## Events

Use `AdsEventSink` to forward ad events into Firebase, Meta, Adjust, your own analytics, or logging.

```swift
final class AnalyticsSink: AdsEventSink {
    func record(_ event: AdsEvent) {
        // Map to your analytics pipeline here.
    }
}
```

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

An iOS sample app is included at `Example/AdsExample`. It uses Google test ad-unit IDs and demonstrates banner, native, interstitial, rewarded, and app open flows with the package directly.
