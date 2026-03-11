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

    func load(
        bannerView: BannerView,
        collapse: AdsBannerCollapse?,
        rootViewController: UIViewController?
    ) {
        if bannerView.rootViewController == nil {
            bannerView.rootViewController = rootViewController
        }

        guard bannerView.rootViewController != nil else {
            return
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
    }
}
