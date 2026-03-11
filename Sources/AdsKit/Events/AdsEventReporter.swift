import Foundation

final class AdsEventReporter {
    weak var sink: AdsEventSink?
    var debugOptions: AdsDebugOptions

    init(
        sink: AdsEventSink?,
        debugOptions: AdsDebugOptions
    ) {
        self.sink = sink
        self.debugOptions = debugOptions
    }

    func record(_ event: AdsEvent) {
        if debugOptions.isVerboseLoggingEnabled {
            print("[AdsKit]", event.kind.rawValue, event.slotKey ?? "-", event.adUnitId ?? "-", event.message ?? "")
        } else if debugOptions.logSkippedShows, event.kind == .skipped {
            print("[AdsKit]", event.kind.rawValue, event.slotKey ?? "-", event.message ?? "")
        }
        sink?.record(event)
    }
}
