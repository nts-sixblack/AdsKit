import Foundation

public protocol AdsEventSink: AnyObject {
    func record(_ event: AdsEvent)
}

public final class ClosureAdsEventSink: AdsEventSink {
    private let handler: (AdsEvent) -> Void

    public init(_ handler: @escaping (AdsEvent) -> Void) {
        self.handler = handler
    }

    public func record(_ event: AdsEvent) {
        handler(event)
    }
}
