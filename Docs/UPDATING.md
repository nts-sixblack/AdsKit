# Updating

## Package maintenance

- Bump the package version using semantic versioning.
- Update the Google Mobile Ads dependency only after verifying host app compatibility.
- Re-run `xcodebuild -scheme AdsKit -destination 'generic/platform=iOS Simulator' build`.
- Re-run package tests before tagging a release.

## Host app checklist

- Re-resolve Swift packages.
- Review `CHANGELOG.md`.
- Check whether new `AdsEvent.Kind` cases need analytics mapping.
- Check whether new policy fields or slot requirements need remote config changes.
