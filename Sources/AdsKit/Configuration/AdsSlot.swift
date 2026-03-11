import Foundation

public struct AdsSlot: Codable, Sendable, Hashable, Identifiable {
    public var key: String
    public var format: AdsFormat
    public var primaryPlacement: AdsPlacement
    public var fallbackPlacement: AdsPlacement?
    public var adChoicesPosition: AdsAdChoicesPosition?
    public var requestIntervalSeconds: Int?

    public var id: String { key }

    public init(
        key: String,
        format: AdsFormat,
        primaryPlacement: AdsPlacement,
        fallbackPlacement: AdsPlacement? = nil,
        adChoicesPosition: AdsAdChoicesPosition? = nil,
        requestIntervalSeconds: Int? = nil
    ) {
        self.key = key
        self.format = format
        self.primaryPlacement = primaryPlacement
        self.fallbackPlacement = fallbackPlacement
        self.adChoicesPosition = adChoicesPosition
        self.requestIntervalSeconds = requestIntervalSeconds
    }
}
