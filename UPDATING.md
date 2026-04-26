# Updating AdsKit

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
