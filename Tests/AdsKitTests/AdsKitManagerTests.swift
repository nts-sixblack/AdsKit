import Foundation
import XCTest
@testable import AdsKit

@MainActor
final class AdsKitManagerTests: XCTestCase {
    func testManagerEmitsConfigurationAndRuntimeEventsInOrder() {
        let sink = RecordingSink()
        let manager = AdsKitManager(
            configuration: .init(),
            runtimeContext: makeRuntimeContext(now: 10),
            eventSink: sink
        )

        manager.apply(configuration: makeNativeConfiguration())
        manager.updateRuntimeContext(
            AdsRuntimeContext(
                isAdsEnabled: false,
                isPremiumUser: true,
                isFirstAppOpen: false,
                topViewControllerProvider: { nil },
                nowProvider: { Date(timeIntervalSince1970: 12) }
            )
        )

        XCTAssertEqual(
            sink.events.map(\.kind),
            [.configurationApplied, .runtimeUpdated]
        )
        XCTAssertEqual(sink.events[0].timestampMs, 10_000)
        XCTAssertEqual(sink.events[1].timestampMs, 12_000)
        XCTAssertEqual(
            sink.events[1].metadata,
            [
                "ads_enabled": "false",
                "premium_user": "true",
                "first_app_open": "false"
            ]
        )
    }

    func testNativeViewModelRegistryReusesInstanceWhenConfigurationDoesNotChange() {
        let configuration = makeNativeConfiguration()
        let manager = AdsKitManager(
            configuration: configuration,
            runtimeContext: makeRuntimeContext(now: 20)
        )

        guard let first = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected first native view model")
            return
        }
        guard let second = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected cached native view model")
            return
        }

        XCTAssertTrue(first === second)

        manager.apply(configuration: configuration)

        guard let third = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected cached native view model after identical configuration")
            return
        }

        XCTAssertTrue(first === third)
    }

    func testNativeViewModelRegistryRecreatesInstanceWhenNativeSlotChanges() {
        let manager = AdsKitManager(
            configuration: makeNativeConfiguration(),
            runtimeContext: makeRuntimeContext(now: 21)
        )

        guard let first = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected first native view model")
            return
        }

        manager.apply(
            configuration: makeNativeConfiguration(primaryPlacementID: "native_primary_updated")
        )

        guard let second = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected recreated native view model after slot change")
            return
        }

        XCTAssertFalse(first === second)
    }

    func testNativeViewModelRegistryRecreatesInstanceWhenNativePolicyChanges() {
        let manager = AdsKitManager(
            configuration: makeNativeConfiguration(),
            runtimeContext: makeRuntimeContext(now: 22)
        )

        guard let first = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected first native view model")
            return
        }

        manager.apply(
            configuration: makeNativeConfiguration(
                nativePolicy: .init(
                    defaultRequestIntervalSeconds: 120,
                    usesSharedCache: false,
                    defaultAdChoicesPosition: .bottomLeft
                )
            )
        )

        guard let second = manager.nativeViewModel(for: "feed_native") else {
            XCTFail("Expected recreated native view model after policy change")
            return
        }

        XCTAssertFalse(first === second)
    }

    func testCanDisplayRespectsRuntimeFlags() {
        let configuration = AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "home_banner",
                    format: .banner,
                    primaryPlacement: .init(id: "banner_primary", isEnabled: true)
                ),
                AdsSlot(
                    key: "launch_app_open",
                    format: .appOpen,
                    primaryPlacement: .init(id: "app_open_primary", isEnabled: true)
                )
            ]
        )
        let manager = AdsKitManager(
            configuration: configuration,
            runtimeContext: makeRuntimeContext(now: 30)
        )

        XCTAssertTrue(manager.canDisplay(slotKey: "home_banner"))

        manager.updateAdsEnabled(false)
        XCTAssertFalse(manager.canDisplay(slotKey: "home_banner"))

        manager.updateAdsEnabled(true)
        manager.updatePremiumStatus(true)
        XCTAssertFalse(manager.canDisplay(slotKey: "home_banner"))

        manager.updatePremiumStatus(false)
        manager.updateFirstAppOpen(true)
        XCTAssertFalse(manager.canDisplay(slotKey: "launch_app_open"))
    }

    func testPreloadConfiguredSlotsOnlyLoadsStartupBucket() {
        let sink = RecordingSink()
        let manager = AdsKitManager(
            configuration: makeSplitPreloadConfiguration(),
            runtimeContext: makeRuntimeContext(now: 40),
            eventSink: sink
        )

        manager.preloadConfiguredSlots()

        let recordedSlotKeys = Set(sink.events.compactMap(\.slotKey))

        XCTAssertTrue(recordedSlotKeys.contains("startup_inter"))
        XCTAssertTrue(recordedSlotKeys.contains("startup_rewarded"))
        XCTAssertTrue(recordedSlotKeys.contains("startup_app_open"))
        XCTAssertTrue(recordedSlotKeys.contains("startup_native"))

        XCTAssertFalse(recordedSlotKeys.contains("manual_inter"))
        XCTAssertFalse(recordedSlotKeys.contains("manual_rewarded"))
        XCTAssertFalse(recordedSlotKeys.contains("manual_app_open"))
        XCTAssertFalse(recordedSlotKeys.contains("manual_native"))
    }

    func testPreloadManualSlotsOnlyLoadsManualBucketAndRecordsNativePreloadCreation() {
        let sink = RecordingSink()
        let manager = AdsKitManager(
            configuration: makeSplitPreloadConfiguration(),
            runtimeContext: makeRuntimeContext(now: 50),
            eventSink: sink
        )

        manager.preloadManualSlots()

        let recordedSlotKeys = Set(sink.events.compactMap(\.slotKey))

        XCTAssertTrue(recordedSlotKeys.contains("manual_inter"))
        XCTAssertTrue(recordedSlotKeys.contains("manual_rewarded"))
        XCTAssertTrue(recordedSlotKeys.contains("manual_app_open"))
        XCTAssertTrue(recordedSlotKeys.contains("manual_native"))

        XCTAssertFalse(recordedSlotKeys.contains("startup_inter"))
        XCTAssertFalse(recordedSlotKeys.contains("startup_rewarded"))
        XCTAssertFalse(recordedSlotKeys.contains("startup_app_open"))
        XCTAssertFalse(recordedSlotKeys.contains("startup_native"))

        let manualNativePreloadEvents = sink.events.filter {
            $0.kind == .preloadCreated && $0.slotKey == "manual_native"
        }
        XCTAssertEqual(manualNativePreloadEvents.count, 1)
    }

    private func makeNativeConfiguration(
        primaryPlacementID: String = "native_primary",
        fallbackPlacementID: String = "native_fallback",
        nativePolicy: AdsNativePolicy = .init()
    ) -> AdsConfiguration {
        AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "feed_native",
                    format: .native,
                    primaryPlacement: .init(id: primaryPlacementID, isEnabled: true),
                    fallbackPlacement: .init(id: fallbackPlacementID, isEnabled: true)
                )
            ],
            policies: .init(native: nativePolicy)
        )
    }

    private func makeSplitPreloadConfiguration() -> AdsConfiguration {
        AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "startup_inter",
                    format: .interstitial,
                    primaryPlacement: .init(id: "startup_interstitial", isEnabled: true)
                ),
                AdsSlot(
                    key: "manual_inter",
                    format: .interstitial,
                    primaryPlacement: .init(id: "manual_interstitial", isEnabled: true)
                ),
                AdsSlot(
                    key: "startup_rewarded",
                    format: .rewarded,
                    primaryPlacement: .init(id: "startup_rewarded", isEnabled: true)
                ),
                AdsSlot(
                    key: "manual_rewarded",
                    format: .rewarded,
                    primaryPlacement: .init(id: "manual_rewarded", isEnabled: true)
                ),
                AdsSlot(
                    key: "startup_app_open",
                    format: .appOpen,
                    primaryPlacement: .init(id: "startup_app_open", isEnabled: true)
                ),
                AdsSlot(
                    key: "manual_app_open",
                    format: .appOpen,
                    primaryPlacement: .init(id: "manual_app_open", isEnabled: true)
                ),
                AdsSlot(
                    key: "startup_native",
                    format: .native,
                    primaryPlacement: .init(id: "startup_native", isEnabled: true)
                ),
                AdsSlot(
                    key: "manual_native",
                    format: .native,
                    primaryPlacement: .init(id: "manual_native", isEnabled: true)
                )
            ],
            preload: .init(
                interstitialKeys: ["startup_inter"],
                rewardedKeys: ["startup_rewarded"],
                appOpenKeys: ["startup_app_open"],
                nativeKeys: ["startup_native"],
                manual: .init(
                    interstitialKeys: ["manual_inter"],
                    rewardedKeys: ["manual_rewarded"],
                    appOpenKeys: ["manual_app_open"],
                    nativeKeys: ["manual_native"]
                )
            )
        )
    }

    private func makeRuntimeContext(now: TimeInterval) -> AdsRuntimeContext {
        AdsRuntimeContext(
            isAdsEnabled: true,
            isPremiumUser: false,
            isFirstAppOpen: false,
            topViewControllerProvider: { nil },
            nowProvider: { Date(timeIntervalSince1970: now) }
        )
    }
}

private final class RecordingSink: AdsEventSink {
    private(set) var events: [AdsEvent] = []

    func record(_ event: AdsEvent) {
        events.append(event)
    }
}
