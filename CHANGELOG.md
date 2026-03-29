# Changelog

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
