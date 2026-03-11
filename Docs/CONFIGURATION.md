# Configuration

`AdsConfiguration` is the single source of truth for placements, policies, preload behavior, theme, and debug options.

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

`AdsPreloadConfiguration` tells `AdsKitManager.preloadConfiguredSlots()` which slot keys should be preloaded at startup.

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
