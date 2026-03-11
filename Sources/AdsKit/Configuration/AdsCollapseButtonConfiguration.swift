import Foundation

public struct AdsCollapseButtonConfiguration: Codable, Sendable, Hashable {
    public var symbolName: String
    public var iconHex: String
    public var backgroundHex: String
    public var borderHex: String
    public var borderOpacity: Double
    public var touchTargetSize: Double
    public var visualSize: Double
    public var iconPointSize: Double
    public var topInset: Double
    public var trailingInset: Double

    public init(
        symbolName: String = "chevron.down",
        iconHex: String = "#111111",
        backgroundHex: String = "#FFFFFF",
        borderHex: String = "#BFC6D7",
        borderOpacity: Double = 0.35,
        touchTargetSize: Double = 44,
        visualSize: Double = 30,
        iconPointSize: Double = 14,
        topInset: Double = 8,
        trailingInset: Double = 16
    ) {
        self.symbolName = symbolName
        self.iconHex = iconHex
        self.backgroundHex = backgroundHex
        self.borderHex = borderHex
        self.borderOpacity = borderOpacity
        self.touchTargetSize = touchTargetSize
        self.visualSize = visualSize
        self.iconPointSize = iconPointSize
        self.topInset = topInset
        self.trailingInset = trailingInset
    }
}
