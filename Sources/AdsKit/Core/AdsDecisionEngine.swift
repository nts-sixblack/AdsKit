import Foundation

struct AdsDecisionState {
    var lastShownAtBySlot: [String: Int64] = [:]
    var lastFullscreenShownAt: Int64 = 0
    var lastAppOpenShownAt: Int64 = 0
    var interstitialOpportunityCountBySlot: [String: Int] = [:]
    var hasConsumedFirstAppOpenOpportunity: Bool = false
    var suppressNextAppOpenAd: Bool = false
    var suppressNextSplashInterstitial: Bool = false
}

enum AdsDecisionEngine {
    static func shouldShowInterstitial(
        state: inout AdsDecisionState,
        slotKey: String,
        policy: AdsInterstitialPolicy,
        nowMs: Int64
    ) -> Bool {
        let count = state.interstitialOpportunityCountBySlot[slotKey] ?? 1
        let lastSameSlotShownAt = state.lastShownAtBySlot[slotKey] ?? 0
        let enoughTimeForSameSlot = lastSameSlotShownAt == 0
            || nowMs - lastSameSlotShownAt >= Int64(policy.minimumIntervalForSameSlotSeconds * 1000)
        let enoughTimeForAnyFullscreen = state.lastFullscreenShownAt == 0
            || nowMs - state.lastFullscreenShownAt >= Int64(policy.minimumIntervalForAnyFullscreenSeconds * 1000)
        let thresholdSatisfied = count >= policy.displayThreshold

        guard enoughTimeForAnyFullscreen, enoughTimeForSameSlot || thresholdSatisfied else {
            state.interstitialOpportunityCountBySlot[slotKey] = count + 1
            return false
        }

        return true
    }

    static func recordInterstitialShown(
        state: inout AdsDecisionState,
        slotKey: String,
        nowMs: Int64
    ) {
        state.lastShownAtBySlot[slotKey] = nowMs
        state.lastFullscreenShownAt = nowMs
        state.interstitialOpportunityCountBySlot[slotKey] = 1
    }

    static func recordOtherFullscreenShown(
        state: inout AdsDecisionState,
        nowMs: Int64
    ) {
        state.lastFullscreenShownAt = nowMs
    }

    static func shouldShowAppOpen(
        state: inout AdsDecisionState,
        runtimeContext: AdsRuntimeContext,
        policy: AdsAppOpenPolicy,
        isShowingFullscreenAd: Bool,
        nowMs: Int64
    ) -> Bool {
        guard runtimeContext.isAdsEnabled else { return false }
        guard !runtimeContext.isPremiumUser else { return false }
        guard !runtimeContext.isFirstAppOpen else { return false }
        guard !isShowingFullscreenAd || !policy.respectFullscreenSuppression else { return false }

        if state.suppressNextAppOpenAd {
            state.suppressNextAppOpenAd = false
            return false
        }

        if policy.waitForSecondOpportunity && !state.hasConsumedFirstAppOpenOpportunity {
            state.hasConsumedFirstAppOpenOpportunity = true
            return false
        }

        let minIntervalMs = Int64(policy.minimumIntervalBetweenShowsSeconds * 1000)
        guard state.lastAppOpenShownAt == 0 || nowMs - state.lastAppOpenShownAt >= minIntervalMs else {
            return false
        }

        return true
    }

    static func recordAppOpenShown(
        state: inout AdsDecisionState,
        nowMs: Int64
    ) {
        state.lastAppOpenShownAt = nowMs
        state.lastFullscreenShownAt = nowMs
    }

    static func consumeSplashSuppression(state: inout AdsDecisionState) -> Bool {
        guard state.suppressNextSplashInterstitial else { return false }
        state.suppressNextSplashInterstitial = false
        return true
    }
}
