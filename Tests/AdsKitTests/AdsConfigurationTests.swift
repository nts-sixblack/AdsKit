import XCTest
@testable import AdsKit

final class AdsConfigurationTests: XCTestCase {
    func testSlotLookupReturnsMatchingSlot() {
        let configuration = AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "share_inter",
                    format: .interstitial,
                    primaryPlacement: .init(id: "share", isEnabled: true)
                ),
                AdsSlot(
                    key: "language_native",
                    format: .native,
                    primaryPlacement: .init(id: "native", isEnabled: true)
                )
            ]
        )

        XCTAssertEqual(configuration.slot(forKey: "language_native")?.primaryPlacement.id, "native")
        XCTAssertNil(configuration.slot(forKey: "missing"))
    }

    func testConfigurationCodableRoundTripPreservesValues() throws {
        let configuration = AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "splash",
                    format: .splashInterstitial,
                    primaryPlacement: .init(id: "primary", isEnabled: true),
                    fallbackPlacement: .init(id: "fallback", isEnabled: false),
                    adChoicesPosition: .bottomRight,
                    requestIntervalSeconds: 120
                )
            ],
            enabled: .init(
                banner: false,
                interstitial: true,
                splashInterstitial: false,
                rewarded: true,
                native: false,
                appOpen: true
            ),
            policies: .init(
                interstitial: .init(
                    minimumIntervalForSameSlotSeconds: 30,
                    minimumIntervalForAnyFullscreenSeconds: 15,
                    displayThreshold: 5,
                    autoReloadAfterDismiss: false
                ),
                splashInterstitial: .init(
                    isEnabled: false,
                    loadTimeoutSeconds: 9,
                    autoReloadAfterDismiss: true
                )
            ),
            preload: .init(
                nativeKeys: ["language_native"],
                manual: .init(nativeKeys: ["manual_native"])
            ),
            theme: .init(
                cardBackgroundHex: "#222222",
                collapseButton: .init(
                    symbolName: "chevron.compact.down",
                    iconHex: "#000000",
                    backgroundHex: "#FFFFFF",
                    borderHex: "#222222"
                )
            ),
            debug: .init(isVerboseLoggingEnabled: true, logSkippedShows: false)
        )

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(AdsConfiguration.self, from: data)

        XCTAssertEqual(decoded, configuration)
    }

    func testConfigurationDecodesLegacyPayloadWithoutFormatEnablement() throws {
        let data = Data(
            """
            {
              "slots": [
                {
                  "key": "home_banner",
                  "format": "banner",
                  "primaryPlacement": {
                    "id": "banner_primary",
                    "isEnabled": true
                  }
                }
              ]
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(AdsConfiguration.self, from: data)

        XCTAssertEqual(decoded.enabled, .init())
        XCTAssertTrue(decoded.enabled.isEnabled(for: .banner))
        XCTAssertTrue(decoded.enabled.isEnabled(for: .interstitial))
        XCTAssertTrue(decoded.enabled.isEnabled(for: .splashInterstitial))
        XCTAssertTrue(decoded.enabled.isEnabled(for: .rewarded))
        XCTAssertTrue(decoded.enabled.isEnabled(for: .native))
        XCTAssertTrue(decoded.enabled.isEnabled(for: .appOpen))
    }

    func testFormatEnablementDecodesPartialPayloadWithEnabledDefaults() throws {
        let data = Data(
            #"{"banner":false,"appOpen":false}"#.utf8
        )

        let decoded = try JSONDecoder().decode(AdsFormatEnablement.self, from: data)

        XCTAssertFalse(decoded.banner)
        XCTAssertTrue(decoded.interstitial)
        XCTAssertTrue(decoded.splashInterstitial)
        XCTAssertTrue(decoded.rewarded)
        XCTAssertTrue(decoded.native)
        XCTAssertFalse(decoded.appOpen)
    }

    func testPreloadConfigurationDecodesLegacyPayloadWithoutManualBucket() throws {
        let data = Data(
            #"{"interstitialKeys":["share_inter"],"nativeKeys":["language_native"]}"#.utf8
        )

        let decoded = try JSONDecoder().decode(AdsPreloadConfiguration.self, from: data)

        XCTAssertEqual(decoded.interstitialKeys, ["share_inter"])
        XCTAssertEqual(decoded.nativeKeys, ["language_native"])
        XCTAssertEqual(decoded.manual, .init())
    }

    func testSplashInterstitialPolicyDecodesLegacyPayloadWithoutAutoReloadFlag() throws {
        let data = Data(
            #"{"isEnabled":false,"loadTimeoutSeconds":7}"#.utf8
        )

        let decoded = try JSONDecoder().decode(AdsSplashInterstitialPolicy.self, from: data)

        XCTAssertEqual(
            decoded,
            .init(
                isEnabled: false,
                loadTimeoutSeconds: 7,
                autoReloadAfterDismiss: false
            )
        )
    }

    func testDebugOptionsDecodesLegacyPayloadWithoutTestAdUnitIDFlag() throws {
        let data = Data(
            #"{"isVerboseLoggingEnabled":true,"logSkippedShows":false}"#.utf8
        )

        let decoded = try JSONDecoder().decode(AdsDebugOptions.self, from: data)

        XCTAssertTrue(decoded.isVerboseLoggingEnabled)
        XCTAssertFalse(decoded.logSkippedShows)
        XCTAssertFalse(decoded.usesTestAdUnitIDs)
    }
}
