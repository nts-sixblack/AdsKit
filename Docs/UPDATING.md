# Updating

## Package maintenance

- Bump the package version using semantic versioning.
- SPM package versions are released through git tags. Patch-only fixes should use the next patch tag, for example `1.0.5` after `1.0.4`.
- Update the Google Mobile Ads dependency only after verifying host app compatibility.
- Re-run `xcodebuild -scheme AdsKit -destination 'generic/platform=iOS Simulator' build`.
- Re-run package tests before tagging a release.

## Host app checklist

- Re-resolve Swift packages.
- Review `CHANGELOG.md`.
- Check whether new `AdsEvent.Kind` cases need analytics mapping.
- Check whether new `AdsEvent.metadata` keys should be forwarded to analytics or diagnostics.
- Check whether new policy fields or slot requirements need remote config changes.
- Re-check banner containers after updates that affect `BannerAdsView` sizing, especially screens that constrain banner width or expect a fixed reserved height.
