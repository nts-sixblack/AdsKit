@preconcurrency import GoogleMobileAds
import UIKit

enum AdsNativeMediaSupport {
    static func hasPrimaryMedia(in mediaContent: MediaContent?) -> Bool {
        guard let mediaContent else { return false }
        return hasPrimaryMedia(
            hasVideoContent: mediaContent.hasVideoContent,
            mainImage: mediaContent.mainImage
        )
    }

    static func hasPrimaryMedia(hasVideoContent: Bool, mainImage: UIImage?) -> Bool {
        hasVideoContent || mainImage != nil
    }
}
