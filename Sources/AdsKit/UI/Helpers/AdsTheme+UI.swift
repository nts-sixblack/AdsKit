import SwiftUI
import UIKit

extension AdsTheme {
    func uiColor(_ hex: String) -> UIColor {
        UIColor(hex: hex)
    }

    var cardBackgroundColor: UIColor { uiColor(cardBackgroundHex) }
    var primaryTextColor: UIColor { uiColor(primaryTextHex) }
    var secondaryTextColor: UIColor { uiColor(secondaryTextHex) }
    var accentColor: UIColor { uiColor(accentHex) }
    var accentTextColor: UIColor { uiColor(accentTextHex) }
    var mutedBackgroundColor: UIColor { uiColor(mutedBackgroundHex) }
    var mutedTextColor: UIColor { uiColor(mutedTextHex) }
    var borderColor: UIColor { uiColor(borderHex).withAlphaComponent(borderOpacity) }

    func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard let fontFamilyName, let customFont = UIFont(name: fontFamilyName, size: size) else {
            return .systemFont(ofSize: size, weight: weight)
        }
        return customFont
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        switch cleaned.count {
        case 8:
            red = CGFloat((value & 0xFF000000) >> 24) / 255
            green = CGFloat((value & 0x00FF0000) >> 16) / 255
            blue = CGFloat((value & 0x0000FF00) >> 8) / 255
            alpha = CGFloat(value & 0x000000FF) / 255
        default:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            alpha = 1
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
