import XCTest
@testable import AdsKit

final class AdsPlacementResolverTests: XCTestCase {
    func testPreferredPlacementUsesPrimaryWhenEnabled() {
        let slot = AdsSlot(
            key: "home_banner",
            format: .banner,
            primaryPlacement: .init(id: "primary", isEnabled: true),
            fallbackPlacement: .init(id: "fallback", isEnabled: true)
        )

        XCTAssertEqual(AdsPlacementResolver.preferredPlacement(for: slot)?.id, "primary")
    }

    func testPreferredPlacementFallsBackWhenPrimaryDisabled() {
        let slot = AdsSlot(
            key: "home_banner",
            format: .banner,
            primaryPlacement: .init(id: "primary", isEnabled: false),
            fallbackPlacement: .init(id: "fallback", isEnabled: true)
        )

        XCTAssertEqual(AdsPlacementResolver.preferredPlacement(for: slot)?.id, "fallback")
    }

    func testLoadOrderSkipsDisabledAndDuplicatePlacements() {
        let slot = AdsSlot(
            key: "native",
            format: .native,
            primaryPlacement: .init(id: "primary", isEnabled: false),
            fallbackPlacement: .init(id: "primary", isEnabled: true)
        )

        XCTAssertEqual(AdsPlacementResolver.loadOrder(for: slot), [])
    }
}
