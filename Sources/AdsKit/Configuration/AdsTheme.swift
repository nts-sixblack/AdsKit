import Foundation

public struct AdsTheme: Codable, Sendable, Hashable {
    public var cardBackgroundHex: String
    public var primaryTextHex: String
    public var secondaryTextHex: String
    public var accentHex: String
    public var accentTextHex: String
    public var mutedBackgroundHex: String
    public var mutedTextHex: String
    public var borderHex: String
    public var borderOpacity: Double
    public var smallCornerRadius: Double
    public var mediumCornerRadius: Double
    public var largeCornerRadius: Double
    public var adBadgeText: String
    public var fontFamilyName: String?
    public var collapseButton: AdsCollapseButtonConfiguration?

    public init(
        cardBackgroundHex: String = "#111111",
        primaryTextHex: String = "#FFFFFF",
        secondaryTextHex: String = "#D0D5DD",
        accentHex: String = "#F6C453",
        accentTextHex: String = "#111111",
        mutedBackgroundHex: String = "#3A3A3A",
        mutedTextHex: String = "#B8B8B8",
        borderHex: String = "#BFC6D7",
        borderOpacity: Double = 0.25,
        smallCornerRadius: Double = 8,
        mediumCornerRadius: Double = 12,
        largeCornerRadius: Double = 16,
        adBadgeText: String = "Ad",
        fontFamilyName: String? = nil,
        collapseButton: AdsCollapseButtonConfiguration? = nil
    ) {
        self.cardBackgroundHex = cardBackgroundHex
        self.primaryTextHex = primaryTextHex
        self.secondaryTextHex = secondaryTextHex
        self.accentHex = accentHex
        self.accentTextHex = accentTextHex
        self.mutedBackgroundHex = mutedBackgroundHex
        self.mutedTextHex = mutedTextHex
        self.borderHex = borderHex
        self.borderOpacity = borderOpacity
        self.smallCornerRadius = smallCornerRadius
        self.mediumCornerRadius = mediumCornerRadius
        self.largeCornerRadius = largeCornerRadius
        self.adBadgeText = adBadgeText
        self.fontFamilyName = fontFamilyName
        self.collapseButton = collapseButton
    }
}
