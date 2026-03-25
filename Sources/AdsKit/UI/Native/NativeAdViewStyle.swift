import SwiftUI

public enum NativeAdViewStyle: Equatable {
    case basic
    case banner
    case fullScreen
    case large(isFilled: Bool = true)
    case largeGray
    case medium
    case mediumMedia
    case smallMedia
    case overlay
    case collapse
    case iconMedia
    case video

    var suggestedHeight: CGFloat {
        switch self {
        case .basic:
            return 110
        case .banner:
            return 90
        case .fullScreen:
            return UIScreen.main.bounds.height
        case .large:
            return 280
        case .largeGray:
            return 280
        case .medium:
            return 150
        case .mediumMedia:
            return 180
        case .smallMedia:
            return 220
        case .overlay:
            return 220
        case .collapse:
            return 80
        case .iconMedia:
            return 300
        case .video:
            return 300
        }
    }

    var usesFilledCTA: Bool {
        switch self {
        case .large(let isFilled):
            return isFilled
        default:
            return true
        }
    }
}
