import Foundation

public struct AdsDebugOptions: Codable, Sendable, Hashable {
    public var isVerboseLoggingEnabled: Bool
    public var logSkippedShows: Bool
    public var usesTestAdUnitIDs: Bool

    public init(
        isVerboseLoggingEnabled: Bool = false,
        logSkippedShows: Bool = true,
        usesTestAdUnitIDs: Bool = false
    ) {
        self.isVerboseLoggingEnabled = isVerboseLoggingEnabled
        self.logSkippedShows = logSkippedShows
        self.usesTestAdUnitIDs = usesTestAdUnitIDs
    }

    private enum CodingKeys: String, CodingKey {
        case isVerboseLoggingEnabled
        case logSkippedShows
        case usesTestAdUnitIDs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isVerboseLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isVerboseLoggingEnabled) ?? false
        logSkippedShows = try container.decodeIfPresent(Bool.self, forKey: .logSkippedShows) ?? true
        usesTestAdUnitIDs = try container.decodeIfPresent(Bool.self, forKey: .usesTestAdUnitIDs) ?? false
    }
}
