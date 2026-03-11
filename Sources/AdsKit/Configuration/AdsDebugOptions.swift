import Foundation

public struct AdsDebugOptions: Codable, Sendable, Hashable {
    public var isVerboseLoggingEnabled: Bool
    public var logSkippedShows: Bool

    public init(
        isVerboseLoggingEnabled: Bool = false,
        logSkippedShows: Bool = true
    ) {
        self.isVerboseLoggingEnabled = isVerboseLoggingEnabled
        self.logSkippedShows = logSkippedShows
    }
}
