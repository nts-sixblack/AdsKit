import Foundation

public enum AdsFormat: String, Codable, CaseIterable, Sendable {
    case banner
    case interstitial
    case splashInterstitial = "splash_interstitial"
    case rewarded
    case appOpen = "app_open"
    case native
}
