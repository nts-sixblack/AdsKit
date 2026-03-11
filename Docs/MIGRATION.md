# Migration From TCGScanner Ads Module

## Type mapping

- `AdPlacement` -> `AdsPlacement`
- `AdsManager` -> `AdsKitManager`
- `AdsPreloadService` -> `AdsKitManager.preloadNative(...)` and `nativeViewModel(for:)`
- `AdsEventManager` / `AdsEventLogger` -> `AdsEventSink`
- `BannerAdsView(adPlacement:)` -> `BannerAdsView(slotKey:manager:)`
- `NativeAdsView(adPlacement:adPlacementHight:style:height:)` -> configure a logical native slot and use `NativeAdsView(slotKey:manager:style:)`

## Behavior mapping

- High-priority ad unit fallback becomes `primaryPlacement` + `fallbackPlacement`.
- Subscription / premium suppression becomes `runtimeContext.isPremiumUser`.
- Global ads toggle becomes `runtimeContext.isAdsEnabled`.
- First-open logic becomes `runtimeContext.isFirstAppOpen`.
- Remote config storage is no longer inside the package; the host app maps remote values into `AdsConfiguration`.

## Suggested migration flow

1. Create logical slot keys that replace hard-coded placement access from `LocalStorageService`.
2. Build one `AdsConfiguration` from your existing local/remote values.
3. Replace direct calls to the old manager with `AdsKitManager`.
4. Replace old banner/native SwiftUI views with the AdsKit views.
5. Move analytics forwarding into one `AdsEventSink`.
