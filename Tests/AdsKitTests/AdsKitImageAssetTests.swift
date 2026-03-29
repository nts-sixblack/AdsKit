import UIKit
import XCTest
@testable import AdsKit

final class AdsKitImageAssetTests: XCTestCase {
    func testDownArrowAssetLoadsFromAdsKitBundle() {
        XCTAssertNotNil(AdsKitImageAsset.image(named: "down-arrow"))
    }
}
