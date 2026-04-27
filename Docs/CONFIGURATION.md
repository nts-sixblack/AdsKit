# Configuration

`AdsConfiguration` is the single source of truth for placements, policies, preload behavior, theme, and debug options.

Applying the same configuration more than once is a no-op. Runtime updates also only emit `runtime_updated` when `isAdsEnabled`, `isPremiumUser`, or `isFirstAppOpen` actually changes.

## Slots

Each `AdsSlot` represents one logical placement key used by the host app.

```swift
AdsSlot(
    key: "share_inter",
    format: .interstitial,
    primaryPlacement: .init(id: "...", isEnabled: true),
    fallbackPlacement: .init(id: "...", isEnabled: true)
)
```

Fields:

- `key`: logical identifier used by `AdsKitManager`.
- `format`: `.banner`, `.interstitial`, `.splashInterstitial`, `.rewarded`, `.appOpen`, `.native`.
- `primaryPlacement`: preferred ad unit.
- `fallbackPlacement`: optional fallback ad unit.
- `adChoicesPosition`: optional native-only override.
- `requestIntervalSeconds`: optional native-only throttle override.

## Banner Layout

`BannerAdsView(slotKey:manager:)` defaults to an adaptive banner based on the measured SwiftUI container width, capped to the standard banner envelope. This keeps banners correctly sized inside constrained layouts, split views, and device rotations without letting wide containers inflate the ad and crowd the banner content.

Pass `adSize:` when the host app needs a fixed, larger, or custom Google Mobile Ads banner size. The view collapses to height `0` until it has a valid width and after a failed banner load, so parent layouts do not keep an empty banner gap.

## Policies

`AdsPolicies` groups runtime behavior:

- `interstitial`
  - `minimumIntervalForSameSlotSeconds`
  - `minimumIntervalForAnyFullscreenSeconds`
  - `displayThreshold`
  - `autoReloadAfterDismiss`
- `splashInterstitial`
  - `isEnabled`
  - `loadTimeoutSeconds`
  - `autoReloadAfterDismiss`
- `appOpen`
  - `waitForSecondOpportunity`
  - `minimumIntervalBetweenShowsSeconds`
  - `respectFullscreenSuppression`
  - `loadOnDemandIfNeeded`
- `native`
  - `defaultRequestIntervalSeconds`
  - `usesSharedCache`
  - `defaultAdChoicesPosition`
- `retry`
  - `loadRetryDelaySeconds`
  - `maxAttempts`

## Preload

`AdsPreloadConfiguration` has two buckets:

- top-level `interstitialKeys`, `rewardedKeys`, `appOpenKeys`, `nativeKeys`: startup preload keys used by `AdsKitManager.preloadConfiguredSlots()`
- `manual`: explicit preload keys used by `AdsKitManager.preloadManualSlots()`

You can still preload one native slot directly with `AdsKitManager.preloadNative(slotKey:)`.

Fullscreen preloads are cached per slot key and validated against the slot's current enabled placements before being reused. A cached interstitial, rewarded, app-open, or splash interstitial ad for one slot key is not presented for another slot key.

When `policies.splashInterstitial.autoReloadAfterDismiss` is `true`, AdsKit requests the next splash interstitial only after the current splash ad has finished dismissing.

Native preloads are also scoped by slot key. `refreshNative(slotKey:)` does not request a new native ad while that slot's view model already has an ad; use `refreshNative(slotKey:force: true)` when you intentionally want to replace it. `preloadNative(slotKey:)` only records `preload_created` when a new native request actually starts.

You can inspect cache readiness without triggering a load:

```swift
adsManager.hasLoadedInterstitial(slotKey: "share_inter")
adsManager.hasLoadedRewarded(slotKey: "coins_rewarded")
adsManager.hasLoadedAppOpen(slotKey: "launch_app_open")
adsManager.hasLoadedNative(slotKey: "language_native")
```

Example:

```swift
preload: .init(
    interstitialKeys: ["splash_inter"],
    manual: .init(nativeKeys: ["language_native"])
)
```

## Theme

`AdsTheme` is package-owned and overridable. You can change:

- background colors
- text colors
- accent colors
- border color and opacity
- small/medium/large corner radius
- badge text
- collapse button styling for `.collapse` native ads
- optional font family name

If `fontFamilyName` is `nil`, AdsKit uses system fonts.

For `.collapse` native ads, media-backed creatives open in an expanded media layout. The collapsed compact row shows the native ad icon before the headline when one is available; if the icon is missing, AdsKit removes that leading asset from layout instead of leaving an empty placeholder.

`AdsTheme.collapseButton` supports:

- `symbolName`
- `iconHex`
- `backgroundHex`
- `borderHex`
- `borderOpacity`
- `touchTargetSize`
- `visualSize`
- `iconPointSize`
- `topInset`
- `trailingInset`

Example:

```swift
theme: .init(
    collapseButton: .init(
        symbolName: "chevron.down",
        iconHex: "#111111",
        backgroundHex: "#FFFFFF",
        borderHex: "#BFC6D7",
        borderOpacity: 0.35,
        touchTargetSize: 44,
        visualSize: 30,
        iconPointSize: 14,
        topInset: 8,
        trailingInset: 16
    )
)
```

## Debug

`AdsDebugOptions` currently supports:

- `isVerboseLoggingEnabled`
- `logSkippedShows`

## Events

`AdsEventSink` receives lifecycle events for banner, interstitial, splash interstitial, rewarded, app-open, and native ads. Banner SwiftUI updates only request a new ad when the banner load signature changes: ad unit ID, ad size, or collapse behavior.

`load_failed` and failed fullscreen presentation events include structured metadata when available:

- `error_domain`
- `error_code`
- `underlying_error_domain`
- `underlying_error_code`
- `underlying_error_message`
- `response_identifier`
- `adapter_response_count`
- `loaded_adapter_name`
- `loaded_ad_source_name`
- `first_adapter_name`
- `first_adapter_error_domain`
- `first_adapter_error_code`
- `first_adapter_error_message`
