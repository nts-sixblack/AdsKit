import SwiftInjected

@MainActor
public extension SwiftInjected.Dependency {
    static func adsKitManager(
        configuration: AdsConfiguration = .init(),
        runtimeContext: AdsRuntimeContext = .init(),
        eventSink: AdsEventSink? = nil,
        bootstrap: ((AdsKitManager) -> Void)? = nil
    ) -> Self {
        Self {
            let manager = AdsKitManager(
                configuration: configuration,
                runtimeContext: runtimeContext,
                eventSink: eventSink
            )
            bootstrap?(manager)
            return manager
        }
    }
}
