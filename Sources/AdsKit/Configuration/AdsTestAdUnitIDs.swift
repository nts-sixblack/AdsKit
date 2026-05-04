import Foundation

public enum AdsTestAdUnitIDs {
    public static let appOpen = "ca-app-pub-3940256099942544/5575463023"
    public static let adaptiveBanner = "ca-app-pub-3940256099942544/2435281174"
    public static let banner = "ca-app-pub-3940256099942544/2934735716"
    public static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    public static let splashInterstitial = interstitial
    public static let rewarded = "ca-app-pub-3940256099942544/1712485313"
    public static let native = "ca-app-pub-3940256099942544/3986624511"
    public static let nativeVideo = "ca-app-pub-3940256099942544/2521693316"

    static func adUnitID(for format: AdsFormat) -> String {
        switch format {
        case .banner:
            adaptiveBanner
        case .interstitial:
            interstitial
        case .splashInterstitial:
            splashInterstitial
        case .rewarded:
            rewarded
        case .appOpen:
            appOpen
        case .native:
            native
        }
    }
}
