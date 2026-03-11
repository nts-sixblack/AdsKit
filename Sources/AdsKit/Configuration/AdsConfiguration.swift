import Foundation

public struct AdsConfiguration: Codable, Sendable, Hashable {
    public var slots: [AdsSlot]
    public var policies: AdsPolicies
    public var preload: AdsPreloadConfiguration
    public var theme: AdsTheme
    public var debug: AdsDebugOptions

    public init(
        slots: [AdsSlot] = [],
        policies: AdsPolicies = .init(),
        preload: AdsPreloadConfiguration = .init(),
        theme: AdsTheme = .init(),
        debug: AdsDebugOptions = .init()
    ) {
        self.slots = slots
        self.policies = policies
        self.preload = preload
        self.theme = theme
        self.debug = debug
    }

    public func slot(forKey key: String) -> AdsSlot? {
        slots.first(where: { $0.key == key })
    }
}
