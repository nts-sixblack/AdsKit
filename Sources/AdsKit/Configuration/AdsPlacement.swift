import Foundation

public struct AdsPlacement: Codable, Sendable, Hashable {
    public var id: String
    public var isEnabled: Bool

    public init(id: String, isEnabled: Bool) {
        self.id = id
        self.isEnabled = isEnabled
    }
}
