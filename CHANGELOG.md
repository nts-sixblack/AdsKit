# Changelog

## 1.0.6

- Updated `BannerAdsView` to resolve adaptive banner size from the SwiftUI container width instead of the full screen width when no explicit `adSize` is provided.
- Collapsed banner layout height to `0` while width is still being measured, ads are suppressed, or the banner load has failed, preventing blank reserved space.
- Preserved explicit `adSize` behavior for hosts that need a fixed Google Mobile Ads banner size.

## 1.0.5

- Added richer `load_failed` metadata for Google Mobile Ads errors, including NSError domain/code, underlying errors, response identifiers, and adapter response details when available.
- Added banner `load_requested`, `load_succeeded`, and `load_failed` event reporting from `BannerAdsView`.
- Prevented repeated SwiftUI banner updates from reloading the same ad unit, size, and collapse configuration.
- Reduced duplicate app-open, rewarded, and native loads by tracking in-flight requests and making native request throttling consider all candidate placements.
- Updated app-open and rewarded presentation callbacks so fullscreen cooldown state is recorded when the ad actually presents and dismissal callbacks are cleared consistently.
- Made identical configuration and runtime flag updates no-op so analytics sinks do not receive duplicate `configuration_applied` or `runtime_updated` events.

## 1.0.4

- Fixed collapse native ads so the compact collapsed row shows the ad icon before the headline instead of reserving a media thumbnail slot.
- Hidden the compact `MediaView` from layout while keeping it registered for media-backed native ads.
- Updated docs to clarify collapse native compact-row behavior.

## 1.0.3

- Fixed collapse native button rendering so the chevron icon is drawn through a dedicated image view instead of relying on `UIButton` image layout, which restores reliable tinting and visibility.
- Added package-aware asset loading for collapse button icons so image resources resolve correctly when `AdsKit` is consumed through Swift Package Manager.
- Applied collapse native theme updates during `UIViewRepresentable` refreshes and slightly increased the default collapse icon display size for better legibility.

## 1.0.2

- Fixed collapse native ads so media-backed creatives are detected from `mainImage` or video instead of `aspectRatio`, preventing false banner fallback when the aspect ratio is unknown.
- Kept a `MediaView` bound in the compact collapsed state for media-backed native ads to satisfy AdMob native validator requirements.
- Updated collapse native container height logic to render no-media ads directly at compact height without a transient expanded frame.
- Added focused coverage for native media detection behavior.

## 1.0.1

- Split preload configuration into startup and manual buckets, added `AdsPreloadSlotGroup`, and added `AdsKitManager.preloadManualSlots()`.
- Preserved backward-compatible decoding for preload payloads that do not include the new `manual` bucket.
- Reused cached native view models when native configuration is unchanged, while still invalidating them when the native slot or native policy changes.
- Refined native template and collapse views so only visible assets are bound, and increased `.iconMedia` native style height for clearer layouts.
- Updated the sample app and docs to demonstrate startup preload versus manual preload before entering native ad screens.

## 1.0.0

- First stable release of `AdsKit`.
- Added `SwiftInjected` integration through `Dependency.adsKitManager(...)`.
- Added the sample app with banner, interstitial, rewarded, app open, native, and collapse native demos.
- Added configurable collapse native button styling and refined the default example theme for clearer UI.
- Finalized package docs, configuration guides, and test coverage for reusable adoption.

## 0.1.1

- Added `Dependency.adsKitManager(...)` to wire `AdsKitManager` into a `SwiftInjected` dependency graph.
- Updated the example app to resolve `AdsKitManager` through `@InjectedObservable`.

## 0.1.0

- First reusable SPM extraction of the original in-app ads module.
- Added configurable banner, interstitial, splash interstitial, rewarded, app open, native, and preload support.
- Added pluggable event sink API, host-managed runtime context, docs, and tests.
