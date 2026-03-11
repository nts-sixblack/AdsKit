# Remote Config Sample

`AdsKit` intentionally does not depend on Firebase. The host app owns remote config mapping and then calls `apply(configuration:)`.

## Example shape

```swift
import AdsKit

struct RemoteAdsPayload {
    let adsEnabled: Bool
    let premiumUser: Bool
    let splashInterstitialId: String
    let splashInterstitialEnabled: Bool
    let languageNativeId: String
    let languageNativeEnabled: Bool
}

func makeConfiguration(from payload: RemoteAdsPayload) -> AdsConfiguration {
    AdsConfiguration(
        slots: [
            AdsSlot(
                key: "splash_inter",
                format: .splashInterstitial,
                primaryPlacement: .init(
                    id: payload.splashInterstitialId,
                    isEnabled: payload.splashInterstitialEnabled
                )
            ),
            AdsSlot(
                key: "language_native",
                format: .native,
                primaryPlacement: .init(
                    id: payload.languageNativeId,
                    isEnabled: payload.languageNativeEnabled
                )
            )
        ],
        preload: .init(nativeKeys: ["language_native"])
    )
}
```

## Applying a remote update

```swift
let payload = RemoteAdsPayload(
    adsEnabled: remoteValue("ads_enabled"),
    premiumUser: currentPremiumState,
    splashInterstitialId: remoteString("tcg_scanner_inter_splash"),
    splashInterstitialEnabled: remoteBool("tcg_scanner_inter_splash_enabled"),
    languageNativeId: remoteString("tcg_scanner_native_language"),
    languageNativeEnabled: remoteBool("tcg_scanner_native_language_enabled")
)

adsManager.updateAdsEnabled(payload.adsEnabled)
adsManager.updatePremiumStatus(payload.premiumUser)
adsManager.apply(configuration: makeConfiguration(from: payload))
adsManager.preloadConfiguredSlots()
```

The same approach works with Firebase Remote Config, LaunchDarkly, local JSON, or your own API.
