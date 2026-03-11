# Updating AdsKit

## From 0.1.x to 1.0.0

- Review the changelog before bumping the version.
- Re-run package resolution in the host app.
- Re-check `AdsConfiguration` defaults if your host app depends on implicit values.
- Re-check any custom `AdsEventSink` implementation for new event kinds.
- If you use SwiftInjected, add `Dependency.adsKitManager(...)` to your dependency graph, rebuild it at startup, and `import SwiftInjected` in files that use `Dependencies`, `@Injected`, or `@InjectedObservable`.
- If you use the example app as a reference, note that `collapse native` now ships with explicit theme configuration for better contrast and clearer controls.
