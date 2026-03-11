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

    func testNativeViewModelRegistryReusesInstanceUntilConfigurationChanges() {
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
            XCTFail("Expected recreated native view model")
            return
        }

        XCTAssertFalse(first === third)
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

    private func makeNativeConfiguration() -> AdsConfiguration {
        AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "feed_native",
                    format: .native,
                    primaryPlacement: .init(id: "native_primary", isEnabled: true),
                    fallbackPlacement: .init(id: "native_fallback", isEnabled: true)
                )
            ]
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
