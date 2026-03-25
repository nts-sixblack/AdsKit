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
            policies: .init(
                interstitial: .init(
                    minimumIntervalForSameSlotSeconds: 30,
                    minimumIntervalForAnyFullscreenSeconds: 15,
                    displayThreshold: 5,
                    autoReloadAfterDismiss: false
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

    func testPreloadConfigurationDecodesLegacyPayloadWithoutManualBucket() throws {
        let data = Data(
            #"{"interstitialKeys":["share_inter"],"nativeKeys":["language_native"]}"#.utf8
        )

        let decoded = try JSONDecoder().decode(AdsPreloadConfiguration.self, from: data)

        XCTAssertEqual(decoded.interstitialKeys, ["share_inter"])
        XCTAssertEqual(decoded.nativeKeys, ["language_native"])
        XCTAssertEqual(decoded.manual, .init())
    }
}
