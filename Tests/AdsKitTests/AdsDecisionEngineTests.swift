import XCTest
@testable import AdsKit

final class AdsDecisionEngineTests: XCTestCase {
    func testInterstitialThresholdAllowsSameSlotAfterEnoughAttempts() {
        var state = AdsDecisionState(
            lastShownAtBySlot: ["share": 5_000],
            lastFullscreenShownAt: 0
        )
        let policy = AdsInterstitialPolicy(
            minimumIntervalForSameSlotSeconds: 20,
            minimumIntervalForAnyFullscreenSeconds: 0,
            displayThreshold: 3
        )

        XCTAssertFalse(
            AdsDecisionEngine.shouldShowInterstitial(
                state: &state,
                slotKey: "share",
                policy: policy,
                nowMs: 10_000
            )
        )
        XCTAssertFalse(
            AdsDecisionEngine.shouldShowInterstitial(
                state: &state,
                slotKey: "share",
                policy: policy,
                nowMs: 10_001
            )
        )
        XCTAssertTrue(
            AdsDecisionEngine.shouldShowInterstitial(
                state: &state,
                slotKey: "share",
                policy: policy,
                nowMs: 10_002
            )
        )
    }

    func testAppOpenRequiresSecondOpportunityWhenEnabled() {
        var state = AdsDecisionState()
        let runtimeContext = AdsRuntimeContext(
            isAdsEnabled: true,
            isPremiumUser: false,
            isFirstAppOpen: false,
            topViewControllerProvider: { nil },
            nowProvider: { Date(timeIntervalSince1970: 100) }
        )

        XCTAssertFalse(
            AdsDecisionEngine.shouldShowAppOpen(
                state: &state,
                runtimeContext: runtimeContext,
                policy: .init(waitForSecondOpportunity: true, minimumIntervalBetweenShowsSeconds: 0),
                isShowingFullscreenAd: false,
                nowMs: 100_000
            )
        )
        XCTAssertTrue(
            AdsDecisionEngine.shouldShowAppOpen(
                state: &state,
                runtimeContext: runtimeContext,
                policy: .init(waitForSecondOpportunity: true, minimumIntervalBetweenShowsSeconds: 0),
                isShowingFullscreenAd: false,
                nowMs: 100_001
            )
        )
    }

    func testAppOpenSuppressionIsConsumedOnce() {
        var state = AdsDecisionState()
        state.suppressNextAppOpenAd = true

        let runtimeContext = AdsRuntimeContext(
            isAdsEnabled: true,
            isPremiumUser: false,
            isFirstAppOpen: false,
            topViewControllerProvider: { nil },
            nowProvider: { Date(timeIntervalSince1970: 200) }
        )

        XCTAssertFalse(
            AdsDecisionEngine.shouldShowAppOpen(
                state: &state,
                runtimeContext: runtimeContext,
                policy: .init(waitForSecondOpportunity: false, minimumIntervalBetweenShowsSeconds: 0),
                isShowingFullscreenAd: false,
                nowMs: 200_000
            )
        )
        XCTAssertFalse(state.suppressNextAppOpenAd)
        XCTAssertTrue(
            AdsDecisionEngine.shouldShowAppOpen(
                state: &state,
                runtimeContext: runtimeContext,
                policy: .init(waitForSecondOpportunity: false, minimumIntervalBetweenShowsSeconds: 0),
                isShowingFullscreenAd: false,
                nowMs: 200_001
            )
        )
    }

    func testSplashSuppressionIsConsumedOnce() {
        var state = AdsDecisionState()
        state.suppressNextSplashInterstitial = true

        XCTAssertTrue(AdsDecisionEngine.consumeSplashSuppression(state: &state))
        XCTAssertFalse(AdsDecisionEngine.consumeSplashSuppression(state: &state))
    }
}
