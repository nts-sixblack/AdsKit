import Foundation

public struct AdsPolicies: Codable, Sendable, Hashable {
    public var interstitial: AdsInterstitialPolicy
    public var splashInterstitial: AdsSplashInterstitialPolicy
    public var appOpen: AdsAppOpenPolicy
    public var native: AdsNativePolicy
    public var retry: AdsRetryPolicy

    public init(
        interstitial: AdsInterstitialPolicy = .init(),
        splashInterstitial: AdsSplashInterstitialPolicy = .init(),
        appOpen: AdsAppOpenPolicy = .init(),
        native: AdsNativePolicy = .init(),
        retry: AdsRetryPolicy = .init()
    ) {
        self.interstitial = interstitial
        self.splashInterstitial = splashInterstitial
        self.appOpen = appOpen
        self.native = native
        self.retry = retry
    }
}

public struct AdsInterstitialPolicy: Codable, Sendable, Hashable {
    public var minimumIntervalForSameSlotSeconds: Int
    public var minimumIntervalForAnyFullscreenSeconds: Int
    public var displayThreshold: Int
    public var autoReloadAfterDismiss: Bool

    public init(
        minimumIntervalForSameSlotSeconds: Int = 20,
        minimumIntervalForAnyFullscreenSeconds: Int = 20,
        displayThreshold: Int = 3,
        autoReloadAfterDismiss: Bool = true
    ) {
        self.minimumIntervalForSameSlotSeconds = minimumIntervalForSameSlotSeconds
        self.minimumIntervalForAnyFullscreenSeconds = minimumIntervalForAnyFullscreenSeconds
        self.displayThreshold = max(1, displayThreshold)
        self.autoReloadAfterDismiss = autoReloadAfterDismiss
    }
}

public struct AdsSplashInterstitialPolicy: Codable, Sendable, Hashable {
    public var isEnabled: Bool
    public var loadTimeoutSeconds: Int

    public init(
        isEnabled: Bool = true,
        loadTimeoutSeconds: Int = 20
    ) {
        self.isEnabled = isEnabled
        self.loadTimeoutSeconds = max(1, loadTimeoutSeconds)
    }
}

public struct AdsAppOpenPolicy: Codable, Sendable, Hashable {
    public var waitForSecondOpportunity: Bool
    public var minimumIntervalBetweenShowsSeconds: Int
    public var respectFullscreenSuppression: Bool
    public var loadOnDemandIfNeeded: Bool

    public init(
        waitForSecondOpportunity: Bool = true,
        minimumIntervalBetweenShowsSeconds: Int = 20,
        respectFullscreenSuppression: Bool = true,
        loadOnDemandIfNeeded: Bool = true
    ) {
        self.waitForSecondOpportunity = waitForSecondOpportunity
        self.minimumIntervalBetweenShowsSeconds = max(0, minimumIntervalBetweenShowsSeconds)
        self.respectFullscreenSuppression = respectFullscreenSuppression
        self.loadOnDemandIfNeeded = loadOnDemandIfNeeded
    }
}

public struct AdsNativePolicy: Codable, Sendable, Hashable {
    public var defaultRequestIntervalSeconds: Int
    public var usesSharedCache: Bool
    public var defaultAdChoicesPosition: AdsAdChoicesPosition

    public init(
        defaultRequestIntervalSeconds: Int = 60,
        usesSharedCache: Bool = true,
        defaultAdChoicesPosition: AdsAdChoicesPosition = .topRight
    ) {
        self.defaultRequestIntervalSeconds = max(0, defaultRequestIntervalSeconds)
        self.usesSharedCache = usesSharedCache
        self.defaultAdChoicesPosition = defaultAdChoicesPosition
    }
}

public struct AdsRetryPolicy: Codable, Sendable, Hashable {
    public var loadRetryDelaySeconds: Double
    public var maxAttempts: Int

    public init(
        loadRetryDelaySeconds: Double = 1,
        maxAttempts: Int = 3
    ) {
        self.loadRetryDelaySeconds = max(0, loadRetryDelaySeconds)
        self.maxAttempts = max(1, maxAttempts)
    }
}
