import Foundation

public struct AdsFormatEnablement: Codable, Sendable, Hashable {
    public var banner: Bool
    public var interstitial: Bool
    public var splashInterstitial: Bool
    public var rewarded: Bool
    public var native: Bool
    public var appOpen: Bool

    public init(
        banner: Bool = true,
        interstitial: Bool = true,
        splashInterstitial: Bool = true,
        rewarded: Bool = true,
        native: Bool = true,
        appOpen: Bool = true
    ) {
        self.banner = banner
        self.interstitial = interstitial
        self.splashInterstitial = splashInterstitial
        self.rewarded = rewarded
        self.native = native
        self.appOpen = appOpen
    }

    public func isEnabled(for format: AdsFormat) -> Bool {
        switch format {
        case .banner:
            banner
        case .interstitial:
            interstitial
        case .splashInterstitial:
            splashInterstitial
        case .rewarded:
            rewarded
        case .appOpen:
            appOpen
        case .native:
            native
        }
    }

    private enum CodingKeys: String, CodingKey {
        case banner
        case interstitial
        case splashInterstitial
        case rewarded
        case native
        case appOpen
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        banner = try container.decodeIfPresent(Bool.self, forKey: .banner) ?? true
        interstitial = try container.decodeIfPresent(Bool.self, forKey: .interstitial) ?? true
        splashInterstitial = try container.decodeIfPresent(Bool.self, forKey: .splashInterstitial) ?? true
        rewarded = try container.decodeIfPresent(Bool.self, forKey: .rewarded) ?? true
        native = try container.decodeIfPresent(Bool.self, forKey: .native) ?? true
        appOpen = try container.decodeIfPresent(Bool.self, forKey: .appOpen) ?? true
    }
}
