import Foundation

public enum AdsKitError: LocalizedError {
    case slotNotFound(String)
    case invalidSlotFormat(expected: [AdsFormat], actual: AdsFormat)
    case noEnabledPlacement(String)
    case missingRootViewController
    case adNotReady(String)
    case loadFailed(String)
    case presentationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .slotNotFound(let key):
            return "AdsKit could not find slot '\(key)'."
        case .invalidSlotFormat(let expected, let actual):
            let formats = expected.map(\.rawValue).joined(separator: ", ")
            return "AdsKit expected slot formats [\(formats)] but received '\(actual.rawValue)'."
        case .noEnabledPlacement(let key):
            return "AdsKit found no enabled placement for slot '\(key)'."
        case .missingRootViewController:
            return "AdsKit could not resolve a root view controller."
        case .adNotReady(let key):
            return "AdsKit ad is not ready for slot '\(key)'."
        case .loadFailed(let message):
            return message
        case .presentationFailed(let message):
            return message
        }
    }
}
