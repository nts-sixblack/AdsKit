import Foundation

public struct AdsEvent: Sendable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case configurationApplied = "configuration_applied"
        case runtimeUpdated = "runtime_updated"
        case preloadCreated = "preload_created"
        case loadRequested = "load_requested"
        case loadSucceeded = "load_succeeded"
        case loadFailed = "load_failed"
        case willPresent = "will_present"
        case didDismiss = "did_dismiss"
        case skipped = "skipped"
        case click = "click"
        case paidImpression = "paid_impression"
        case rewardEarned = "reward_earned"
    }

    public var kind: Kind
    public var slotKey: String?
    public var adUnitId: String?
    public var format: AdsFormat?
    public var mediationAdapterClassName: String?
    public var valueMicros: Double?
    public var precision: Int?
    public var currencyCode: String?
    public var message: String?
    public var timestampMs: Int64
    public var metadata: [String: String]

    public init(
        kind: Kind,
        slotKey: String? = nil,
        adUnitId: String? = nil,
        format: AdsFormat? = nil,
        mediationAdapterClassName: String? = nil,
        valueMicros: Double? = nil,
        precision: Int? = nil,
        currencyCode: String? = nil,
        message: String? = nil,
        timestampMs: Int64,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.slotKey = slotKey
        self.adUnitId = adUnitId
        self.format = format
        self.mediationAdapterClassName = mediationAdapterClassName
        self.valueMicros = valueMicros
        self.precision = precision
        self.currencyCode = currencyCode
        self.message = message
        self.timestampMs = timestampMs
        self.metadata = metadata
    }
}
