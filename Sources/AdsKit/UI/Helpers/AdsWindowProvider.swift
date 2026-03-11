import UIKit

public enum AdsWindowProvider {
    public static func currentWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let window = connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) {
            return window
        }

        return connectedScenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
    }

    public static func topMostViewController() -> UIViewController? {
        guard let rootViewController = currentWindow()?.rootViewController else {
            return nil
        }

        var current = rootViewController
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
