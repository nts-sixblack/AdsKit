import Foundation
import UIKit

public struct AdsRuntimeContext: @unchecked Sendable {
    public var isAdsEnabled: Bool
    public var isPremiumUser: Bool
    public var isFirstAppOpen: Bool
    public var topViewControllerProvider: () -> UIViewController?
    public var nowProvider: () -> Date

    public init(
        isAdsEnabled: Bool = true,
        isPremiumUser: Bool = false,
        isFirstAppOpen: Bool = true,
        topViewControllerProvider: @escaping () -> UIViewController? = AdsWindowProvider.topMostViewController,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.isAdsEnabled = isAdsEnabled
        self.isPremiumUser = isPremiumUser
        self.isFirstAppOpen = isFirstAppOpen
        self.topViewControllerProvider = topViewControllerProvider
        self.nowProvider = nowProvider
    }
}
