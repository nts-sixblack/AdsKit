import Foundation

public struct AdsPreloadConfiguration: Codable, Sendable, Hashable {
    public var interstitialKeys: [String]
    public var rewardedKeys: [String]
    public var appOpenKeys: [String]
    public var nativeKeys: [String]

    public init(
        interstitialKeys: [String] = [],
        rewardedKeys: [String] = [],
        appOpenKeys: [String] = [],
        nativeKeys: [String] = []
    ) {
        self.interstitialKeys = interstitialKeys
        self.rewardedKeys = rewardedKeys
        self.appOpenKeys = appOpenKeys
        self.nativeKeys = nativeKeys
    }
}
