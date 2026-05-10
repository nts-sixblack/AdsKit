import Foundation

public struct AdsConfiguration: Codable, Sendable, Hashable {
    public var slots: [AdsSlot]
    public var enabled: AdsFormatEnablement
    public var policies: AdsPolicies
    public var preload: AdsPreloadConfiguration
    public var theme: AdsTheme
    public var debug: AdsDebugOptions

    public init(
        slots: [AdsSlot] = [],
        enabled: AdsFormatEnablement = .init(),
        policies: AdsPolicies = .init(),
        preload: AdsPreloadConfiguration = .init(),
        theme: AdsTheme = .init(),
        debug: AdsDebugOptions = .init()
    ) {
        self.slots = slots
        self.enabled = enabled
        self.policies = policies
        self.preload = preload
        self.theme = theme
        self.debug = debug
    }

    public func slot(forKey key: String) -> AdsSlot? {
        slots.first(where: { $0.key == key })
    }

    private enum CodingKeys: String, CodingKey {
        case slots
        case enabled
        case policies
        case preload
        case theme
        case debug
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slots = try container.decodeIfPresent([AdsSlot].self, forKey: .slots) ?? []
        enabled = try container.decodeIfPresent(AdsFormatEnablement.self, forKey: .enabled) ?? .init()
        policies = try container.decodeIfPresent(AdsPolicies.self, forKey: .policies) ?? .init()
        preload = try container.decodeIfPresent(AdsPreloadConfiguration.self, forKey: .preload) ?? .init()
        theme = try container.decodeIfPresent(AdsTheme.self, forKey: .theme) ?? .init()
        debug = try container.decodeIfPresent(AdsDebugOptions.self, forKey: .debug) ?? .init()
    }
}
