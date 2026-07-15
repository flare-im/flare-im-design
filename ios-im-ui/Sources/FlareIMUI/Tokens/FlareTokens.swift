// GENERATED. Do not edit by hand. Source: flare-im-design-tokens/tokens.json
import SwiftUI

/// Flare IM design colours, theme-aware. Use `FlareColors.of(colorScheme)`.
public struct FlareColors: Sendable {
    public let bgDisabled: Color
    public let bgHover: Color
    public let bgPrimary: Color
    public let bgSecondary: Color
    public let bgSelected: Color
    public let bgTertiary: Color
    public let borderHover: Color
    public let borderPrimary: Color
    public let borderSecondary: Color
    public let borderSelected: Color
    public let bubbleOther: Color
    public let bubbleRobot: Color
    public let bubbleSelf: Color
    public let bubbleSystem: Color
    public let error: Color
    public let focusRing: Color
    public let important: Color
    public let info: Color
    public let pinned: Color
    public let primary: Color
    public let primaryActive: Color
    public let primaryHover: Color
    public let robot: Color
    public let success: Color
    public let textDisabled: Color
    public let textLink: Color
    public let textLinkHover: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color
    public let warning: Color

    public static let light = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9529, green: 0.9451, blue: 0.9765, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9333, blue: 0.9725, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9647, green: 0.9608, blue: 0.9843, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.9451, green: 0.9176, blue: 1.0000, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9529, green: 0.9451, blue: 0.9765, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.8549, green: 0.8353, blue: 0.9059, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.9137, green: 0.9020, blue: 0.9451, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9412, green: 0.9294, blue: 0.9686, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        bubbleOther: Color(.sRGB, red: 0.9255, green: 0.8980, blue: 1.0000, opacity: 1.0),
        bubbleRobot: Color(.sRGB, red: 0.9569, green: 0.9412, blue: 1.0000, opacity: 1.0),
        bubbleSelf: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        bubbleSystem: Color(.sRGB, red: 0.9529, green: 0.9451, blue: 0.9765, opacity: 1.0),
        error: Color(.sRGB, red: 0.9373, green: 0.2667, blue: 0.2667, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 0.3500),
        important: Color(.sRGB, red: 0.9608, green: 0.6196, blue: 0.0431, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        primary: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.1333, green: 0.7725, blue: 0.3686, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.8000, green: 0.7843, blue: 0.8471, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.0824, green: 0.0745, blue: 0.1098, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.4196, green: 0.4039, blue: 0.5020, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.6549, green: 0.6353, blue: 0.7059, opacity: 1.0),
        warning: Color(.sRGB, red: 0.9608, green: 0.6196, blue: 0.0431, opacity: 1.0)
    )

    public static let dark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1529, green: 0.1373, blue: 0.2039, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1059, green: 0.0980, blue: 0.1333, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0745, green: 0.0627, blue: 0.0980, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 0.2000),
        bgTertiary: Color(.sRGB, red: 0.1373, green: 0.1255, blue: 0.1882, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.6549, green: 0.5451, blue: 0.9804, opacity: 1.0),
        bubbleOther: Color(.sRGB, red: 0.1412, green: 0.1137, blue: 0.2000, opacity: 1.0),
        bubbleRobot: Color(.sRGB, red: 0.1686, green: 0.1373, blue: 0.2510, opacity: 1.0),
        bubbleSelf: Color(.sRGB, red: 0.5451, green: 0.3608, blue: 0.9647, opacity: 1.0),
        bubbleSystem: Color(.sRGB, red: 0.1373, green: 0.1255, blue: 0.1882, opacity: 1.0),
        error: Color(.sRGB, red: 0.9373, green: 0.2667, blue: 0.2667, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.6549, green: 0.5451, blue: 0.9804, opacity: 0.4000),
        important: Color(.sRGB, red: 0.9608, green: 0.6196, blue: 0.0431, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        primary: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.1333, green: 0.7725, blue: 0.3686, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.7686, green: 0.7098, blue: 0.9922, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.4000),
        warning: Color(.sRGB, red: 0.9608, green: 0.6196, blue: 0.0431, opacity: 1.0)
    )

    public static func of(_ scheme: ColorScheme) -> FlareColors {
        scheme == .dark ? dark : light
    }
}

/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).
public enum FlareSizes {
    public static let fontSize2xl: CGFloat = 16.0
    public static let fontSize3xl: CGFloat = 18.0
    public static let fontSize4xl: CGFloat = 20.0
    public static let fontSizeLg: CGFloat = 14.0
    public static let fontSizeMd: CGFloat = 13.0
    public static let fontSizeSm: CGFloat = 12.0
    public static let fontSizeXl: CGFloat = 15.0
    public static let fontSizeXs: CGFloat = 11.0
    public static let avatarSize: CGFloat = 42.0
    public static let headerHeight: CGFloat = 60.0
    public static let leftPanel: CGFloat = 260.0
    public static let rightPanel: CGFloat = 300.0
    public static let sessionItemHeight: CGFloat = 68.0
    public static let lineHeightNormal: CGFloat = 1.5
    public static let lineHeightRelaxed: CGFloat = 1.6
    public static let lineHeightTight: CGFloat = 1.2
    public static let radius2xl: CGFloat = 18.0
    public static let radiusFull: CGFloat = 999.0
    public static let radiusLg: CGFloat = 10.0
    public static let radiusMd: CGFloat = 8.0
    public static let radiusSm: CGFloat = 6.0
    public static let radiusXl: CGFloat = 14.0
    public static let radiusXs: CGFloat = 3.0
    public static let spacing2xl: CGFloat = 24.0
    public static let spacingLg: CGFloat = 16.0
    public static let spacingMd: CGFloat = 12.0
    public static let spacingSm: CGFloat = 8.0
    public static let spacingXl: CGFloat = 20.0
    public static let spacingXs: CGFloat = 4.0
}
