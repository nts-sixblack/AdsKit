# Changelog

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
