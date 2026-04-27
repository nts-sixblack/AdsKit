# Updating AdsKit

## From 1.0.8 to 1.0.9

- No migration is required for existing splash interstitial call sites.
- `AdsSplashInterstitialPolicy` now includes `autoReloadAfterDismiss`, defaulting to `false`.
- Set `autoReloadAfterDismiss` to `true` only when the host app wants splash interstitials to request their next ad after the current splash ad has fully dismissed.
- If splash interstitial policy is driven by remote config, add the new boolean there only when you need to override the default behavior.

## From 1.0.7 to 1.0.8

- No API migration is required for existing load/show calls.
- Fullscreen cache readiness is now available through `hasLoadedInterstitial`, `hasLoadedRewarded`, and `hasLoadedAppOpen`.
- Native readiness is available through `hasLoadedNative`. Non-forced native refreshes now reuse the slot's existing ad instead of requesting another one; call `refreshNative(slotKey:force: true)` when replacing the native ad is intentional.
- If multiple logical slots previously pointed at the same native ad unit and relied on cross-slot native cache reuse, re-check that flow. Native cache entries are now scoped by `slotKey` to avoid attribution and display collisions.

## From 1.0.6 to 1.0.7

- No API migration is required.
- `BannerAdsView` now caps its default adaptive banner size to the standard banner envelope when `adSize` is omitted, preventing oversized banners in wide or unconstrained containers.
- Continue passing an explicit `adSize` for larger fixed banners or custom Google Mobile Ads sizes.

## From 1.0.5 to 1.0.6

- No API migration is required.
- `BannerAdsView` now derives the default adaptive banner size from the measured SwiftUI container width instead of `UIScreen.main.bounds.width`.
- If a screen depends on a fixed banner size, continue passing an explicit `adSize`.
- Re-check any layout that expected an empty reserved banner height when ads are unavailable or a banner load fails; the view now collapses to height `0` in those states.

## From 1.0.4 to 1.0.5

- No API migration is required.
- `load_failed` and failed fullscreen presentation events now include richer metadata from Google Mobile Ads errors and response info. Review any analytics allowlists if you forward `AdsEvent.metadata`.
- `BannerAdsView` now emits banner load lifecycle events and avoids reloading the same banner signature on every SwiftUI update. Re-check dashboards that counted banner load requests from view refresh frequency.
- Native preload calls now only record `preload_created` when a new request starts, and native request throttling considers the most recent request across all enabled placements for that slot.
- Repeated `apply(configuration:)` and runtime flag updates with unchanged values no longer emit duplicate events.

## From 1.0.3 to 1.0.4

- No API migration is required.
- Collapse native ads now prioritize the native ad icon in the compact collapsed row instead of showing or reserving a media thumbnail slot before the headline.
- Re-check any screenshot baselines or custom visual QA around `.collapse` native ads.

## From 0.1.x to 1.0.0

- Review the changelog before bumping the version.
- Re-run package resolution in the host app.
- Re-check `AdsConfiguration` defaults if your host app depends on implicit values.
- Re-check any custom `AdsEventSink` implementation for new event kinds.
- If you use SwiftInjected, add `Dependency.adsKitManager(...)` to your dependency graph, rebuild it at startup, and `import SwiftInjected` in files that use `Dependencies`, `@Injected`, or `@InjectedObservable`.
- If you use the example app as a reference, note that `collapse native` now ships with explicit theme configuration for better contrast and clearer controls.
