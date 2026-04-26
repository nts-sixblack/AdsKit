@preconcurrency import GoogleMobileAds
import XCTest
@testable import AdsKit

final class BannerAdLayoutTests: XCTestCase {
    @MainActor
    func testDefaultLayoutCapsWidthToStandardBannerWidth() {
        let layout = BannerAdLayout.defaultLayout(for: 600)

        XCTAssertLessThanOrEqual(layout.adSize.size.width, AdSizeBanner.size.width)
        XCTAssertLessThanOrEqual(layout.frameSize.width, AdSizeBanner.size.width)
        XCTAssertLessThanOrEqual(layout.frameSize.height, AdSizeBanner.size.height)
    }

    @MainActor
    func testDefaultLayoutUsesAvailableWidthWhenNarrowerThanStandardBanner() {
        let availableWidth: CGFloat = 240

        let layout = BannerAdLayout.defaultLayout(for: availableWidth)

        XCTAssertLessThanOrEqual(layout.adSize.size.width, availableWidth)
        XCTAssertLessThanOrEqual(layout.frameSize.width, availableWidth)
        XCTAssertLessThanOrEqual(layout.frameSize.height, AdSizeBanner.size.height)
    }

    @MainActor
    func testExplicitAdSizeKeepsRequestedSizeButFramesWithinAvailableWidth() {
        let availableWidth: CGFloat = 280

        let layout = BannerAdLayout(
            adSize: AdSizeLargeBanner,
            availableWidth: availableWidth
        )

        XCTAssertEqual(layout.adSize.size.width, AdSizeLargeBanner.size.width)
        XCTAssertEqual(layout.adSize.size.height, AdSizeLargeBanner.size.height)
        XCTAssertEqual(layout.frameSize.width, availableWidth)
        XCTAssertEqual(layout.frameSize.height, AdSizeLargeBanner.size.height)
    }
}
