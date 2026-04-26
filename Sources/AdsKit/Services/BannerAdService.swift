@preconcurrency import GoogleMobileAds
import UIKit

@MainActor
final class BannerAdService {
    func createBannerView(
        adUnitID: String,
        adSize: AdSize,
        rootViewController: UIViewController?
    ) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        return bannerView
    }

    @discardableResult
    func load(
        bannerView: BannerView,
        collapse: AdsBannerCollapse?,
        rootViewController: UIViewController?
    ) -> Bool {
        if bannerView.rootViewController == nil {
            bannerView.rootViewController = rootViewController
        }

        guard bannerView.rootViewController != nil else {
            return false
        }

        let request = Request()
        if let collapse {
            let extras = Extras()
            extras.additionalParameters = [
                "collapsible": collapse.rawValue
            ]
            request.register(extras)
        }

        bannerView.load(request)
        return true
    }
}
