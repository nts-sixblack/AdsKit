import UIKit
import XCTest
@testable import AdsKit

final class AdsNativeMediaSupportTests: XCTestCase {
    func testHasPrimaryMediaReturnsTrueForVideoWhenAspectRatioIsUnknown() {
        XCTAssertTrue(
            AdsNativeMediaSupport.hasPrimaryMedia(
                hasVideoContent: true,
                mainImage: nil
            )
        )
    }

    func testHasPrimaryMediaReturnsTrueForMainImageWhenAspectRatioIsUnknown() {
        XCTAssertTrue(
            AdsNativeMediaSupport.hasPrimaryMedia(
                hasVideoContent: false,
                mainImage: UIImage()
            )
        )
    }

    func testHasPrimaryMediaReturnsFalseWithoutVideoOrMainImage() {
        XCTAssertFalse(
            AdsNativeMediaSupport.hasPrimaryMedia(
                hasVideoContent: false,
                mainImage: nil
            )
        )
    }
}
