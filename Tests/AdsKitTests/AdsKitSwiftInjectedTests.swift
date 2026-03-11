import SwiftInjected
import XCTest
@testable import AdsKit

@MainActor
final class AdsKitSwiftInjectedTests: XCTestCase {
    func testAdsKitManagerDependencyHelperRegistersSharedManager() {
        let configuration = AdsConfiguration(
            slots: [
                AdsSlot(
                    key: "home_banner",
                    format: .banner,
                    primaryPlacement: .init(id: "banner_primary", isEnabled: true)
                )
            ]
        )
        var didBootstrap = false

        let dependencies = Dependencies {
            Dependency.adsKitManager(
                configuration: configuration,
                runtimeContext: AdsRuntimeContext(
                    isAdsEnabled: true,
                    isPremiumUser: false,
                    isFirstAppOpen: false,
                    topViewControllerProvider: { nil },
                    nowProvider: { Date(timeIntervalSince1970: 100) }
                ),
                bootstrap: { manager in
                    didBootstrap = true
                    manager.updateAdsEnabled(false)
                }
            )
        }
        dependencies.build()

        let consumer = InjectedConsumer()

        XCTAssertTrue(didBootstrap)
        XCTAssertEqual(consumer.manager.configuration, configuration)
        XCTAssertFalse(consumer.manager.runtimeContext.isAdsEnabled)
    }
}

private final class InjectedConsumer {
    @Injected var manager: AdsKitManager
}
