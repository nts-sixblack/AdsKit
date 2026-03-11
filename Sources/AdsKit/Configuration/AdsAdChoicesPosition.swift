import Foundation
@preconcurrency import GoogleMobileAds

public enum AdsAdChoicesPosition: String, Codable, CaseIterable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var googleValue: AdChoicesPosition {
        switch self {
        case .topLeft:
            return .topLeftCorner
        case .topRight:
            return .topRightCorner
        case .bottomLeft:
            return .bottomLeftCorner
        case .bottomRight:
            return .bottomRightCorner
        }
    }
}
