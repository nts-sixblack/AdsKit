# Updating AdsKit

## From 0.1.x to newer 0.1 releases

- Review the changelog before bumping the version.
- Re-run package resolution in the host app.
- Re-check `AdsConfiguration` defaults if your host app depends on implicit values.
- Re-check any custom `AdsEventSink` implementation for new event kinds.
