import Foundation

public struct AdsPreloadConfiguration: Codable, Sendable, Hashable {
    public var interstitialKeys: [String]
    public var rewardedKeys: [String]
    public var appOpenKeys: [String]
    public var nativeKeys: [String]
    public var manual: AdsPreloadSlotGroup

    public init(
        interstitialKeys: [String] = [],
        rewardedKeys: [String] = [],
        appOpenKeys: [String] = [],
        nativeKeys: [String] = [],
        manual: AdsPreloadSlotGroup = .init()
    ) {
        self.interstitialKeys = interstitialKeys
        self.rewardedKeys = rewardedKeys
        self.appOpenKeys = appOpenKeys
        self.nativeKeys = nativeKeys
        self.manual = manual
    }

    enum CodingKeys: String, CodingKey {
        case interstitialKeys
        case rewardedKeys
        case appOpenKeys
        case nativeKeys
        case manual
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        interstitialKeys = try container.decodeIfPresent([String].self, forKey: .interstitialKeys) ?? []
        rewardedKeys = try container.decodeIfPresent([String].self, forKey: .rewardedKeys) ?? []
        appOpenKeys = try container.decodeIfPresent([String].self, forKey: .appOpenKeys) ?? []
        nativeKeys = try container.decodeIfPresent([String].self, forKey: .nativeKeys) ?? []
        manual = try container.decodeIfPresent(AdsPreloadSlotGroup.self, forKey: .manual) ?? .init()
    }

    var startup: AdsPreloadSlotGroup {
        AdsPreloadSlotGroup(
            interstitialKeys: interstitialKeys,
            rewardedKeys: rewardedKeys,
            appOpenKeys: appOpenKeys,
            nativeKeys: nativeKeys
        )
    }
}
