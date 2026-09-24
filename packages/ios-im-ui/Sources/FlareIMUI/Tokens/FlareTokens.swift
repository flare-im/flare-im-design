// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json
import SwiftUI

public struct FlareBrandTheme: Hashable, Sendable, CaseIterable {
    public let name: String
    public let light: FlareColors
    public let dark: FlareColors

    public init(name: String, light: FlareColors, dark: FlareColors) {
        self.name = name
        self.light = light
        self.dark = dark
    }

    public static let violet = FlareBrandTheme(name: "violet", light: .violetLight, dark: .violetDark)
    public static let ocean = FlareBrandTheme(name: "ocean", light: .oceanLight, dark: .oceanDark)
    public static let forest = FlareBrandTheme(name: "forest", light: .forestLight, dark: .forestDark)
    public static let sunset = FlareBrandTheme(name: "sunset", light: .sunsetLight, dark: .sunsetDark)
    public static let rose = FlareBrandTheme(name: "rose", light: .roseLight, dark: .roseDark)
    public static let graphite = FlareBrandTheme(name: "graphite", light: .graphiteLight, dark: .graphiteDark)

    public static let allCases: [FlareBrandTheme] = [.violet, .ocean, .forest, .sunset, .rose, .graphite]
    public static func == (lhs: FlareBrandTheme, rhs: FlareBrandTheme) -> Bool { lhs.name == rhs.name }
    public func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

private struct FlareBrandThemeKey: EnvironmentKey { static let defaultValue: FlareBrandTheme = .violet }
public extension EnvironmentValues {
    var flareBrandTheme: FlareBrandTheme {
        get { self[FlareBrandThemeKey.self] }
        set { self[FlareBrandThemeKey.self] = newValue }
    }
}
/// The theme a host asks for: `light` and `dark` are the person overriding the system, `system` follows it.
public enum FlareThemeMode: String, Sendable, CaseIterable {
    case light, dark, system
}

/// Whether to draw dark (`spec/theme-mode-vectors.json`, the same rule on four kits).
public func flareThemeIsDark(_ mode: FlareThemeMode, systemDark: Bool) -> Bool {
    mode == .system ? systemDark : mode == .dark
}

public extension FlareThemeMode {
    /// The scheme to ask the window for (`preferredColorScheme`), so a host's status bar and system
    /// presentations follow the same choice the kit draws with. `system` asks for nothing.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public extension View {
    /// The kit's theme for this subtree: the brand, and the colour scheme the person chose. `system` leaves the
    /// environment's own scheme alone, so the platform setting keeps deciding.
    func flareTheme(mode: FlareThemeMode = .system, brand: FlareBrandTheme = .violet) -> some View {
        environment(\.flareBrandTheme, brand).modifier(FlareThemeScheme(mode: mode))
    }
}

private struct FlareThemeScheme: ViewModifier {
    let mode: FlareThemeMode

    func body(content: Content) -> some View {
        switch mode {
        case .system: content
        case .light: content.environment(\.colorScheme, .light)
        case .dark: content.environment(\.colorScheme, .dark)
        }
    }
}

/// Flare IM semantic colors resolved by brand and color scheme.
public struct FlareColors: Sendable {
    public let bgDisabled: Color
    public let bgElevated: Color
    public let bgHover: Color
    public let bgPrimary: Color
    public let bgSecondary: Color
    public let bgSelected: Color
    public let bgTertiary: Color
    public let borderHover: Color
    public let borderPrimary: Color
    public let borderSecondary: Color
    public let borderSelected: Color
    public let messageIncomingBackground: Color
    public let messageIncomingForeground: Color
    public let messageIncomingBorder: Color
    public let messageOutgoingBackground: Color
    public let messageOutgoingForeground: Color
    public let messageOutgoingBorder: Color
    public let messageSelectedBackground: Color
    public let messageSelectedBorder: Color
    public let messageFailedBackground: Color
    public let messageFailedForeground: Color
    public let messageFailedBorder: Color
    public let messageMetaForeground: Color
    public let messageStatusPending: Color
    public let messageStatusSent: Color
    public let messageStatusDelivered: Color
    public let messageStatusRead: Color
    public let messageStatusFailed: Color
    public let messageStatusOnOutgoing: Color
    public let messageStatusReadOnOutgoing: Color
    public let messageReplyBackground: Color
    public let messageReplyBorder: Color
    public let messageReactionBackground: Color
    public let messageReactionSelected: Color
    public let error: Color
    public let errorText: Color
    public let focusRing: Color
    public let important: Color
    public let info: Color
    public let infoText: Color
    public let pinned: Color
    public let primary: Color
    public let primaryActive: Color
    public let primaryHover: Color
    public let primaryText: Color
    public let robot: Color
    public let success: Color
    public let successText: Color
    public let textDisabled: Color
    public let textLink: Color
    public let textLinkHover: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color
    public let warning: Color
    public let warningText: Color
    public let avatarTintBlueBg: Color
    public let avatarTintBlueFg: Color
    public let avatarTintPurpleBg: Color
    public let avatarTintPurpleFg: Color
    public let avatarTintPinkBg: Color
    public let avatarTintPinkFg: Color
    public let avatarTintGreenBg: Color
    public let avatarTintGreenFg: Color
    public let avatarTintAmberBg: Color
    public let avatarTintAmberFg: Color
    public let avatarTintSlateBg: Color
    public let avatarTintSlateFg: Color

    public init(
        bgDisabled: Color,
        bgElevated: Color,
        bgHover: Color,
        bgPrimary: Color,
        bgSecondary: Color,
        bgSelected: Color,
        bgTertiary: Color,
        borderHover: Color,
        borderPrimary: Color,
        borderSecondary: Color,
        borderSelected: Color,
        messageIncomingBackground: Color,
        messageIncomingForeground: Color,
        messageIncomingBorder: Color,
        messageOutgoingBackground: Color,
        messageOutgoingForeground: Color,
        messageOutgoingBorder: Color,
        messageSelectedBackground: Color,
        messageSelectedBorder: Color,
        messageFailedBackground: Color,
        messageFailedForeground: Color,
        messageFailedBorder: Color,
        messageMetaForeground: Color,
        messageStatusPending: Color,
        messageStatusSent: Color,
        messageStatusDelivered: Color,
        messageStatusRead: Color,
        messageStatusFailed: Color,
        messageStatusOnOutgoing: Color,
        messageStatusReadOnOutgoing: Color,
        messageReplyBackground: Color,
        messageReplyBorder: Color,
        messageReactionBackground: Color,
        messageReactionSelected: Color,
        error: Color,
        errorText: Color,
        focusRing: Color,
        important: Color,
        info: Color,
        infoText: Color,
        pinned: Color,
        primary: Color,
        primaryActive: Color,
        primaryHover: Color,
        primaryText: Color,
        robot: Color,
        success: Color,
        successText: Color,
        textDisabled: Color,
        textLink: Color,
        textLinkHover: Color,
        textPrimary: Color,
        textSecondary: Color,
        textTertiary: Color,
        warning: Color,
        warningText: Color,
        avatarTintBlueBg: Color,
        avatarTintBlueFg: Color,
        avatarTintPurpleBg: Color,
        avatarTintPurpleFg: Color,
        avatarTintPinkBg: Color,
        avatarTintPinkFg: Color,
        avatarTintGreenBg: Color,
        avatarTintGreenFg: Color,
        avatarTintAmberBg: Color,
        avatarTintAmberFg: Color,
        avatarTintSlateBg: Color,
        avatarTintSlateFg: Color
    ) {
        self.bgDisabled = bgDisabled
        self.bgElevated = bgElevated
        self.bgHover = bgHover
        self.bgPrimary = bgPrimary
        self.bgSecondary = bgSecondary
        self.bgSelected = bgSelected
        self.bgTertiary = bgTertiary
        self.borderHover = borderHover
        self.borderPrimary = borderPrimary
        self.borderSecondary = borderSecondary
        self.borderSelected = borderSelected
        self.messageIncomingBackground = messageIncomingBackground
        self.messageIncomingForeground = messageIncomingForeground
        self.messageIncomingBorder = messageIncomingBorder
        self.messageOutgoingBackground = messageOutgoingBackground
        self.messageOutgoingForeground = messageOutgoingForeground
        self.messageOutgoingBorder = messageOutgoingBorder
        self.messageSelectedBackground = messageSelectedBackground
        self.messageSelectedBorder = messageSelectedBorder
        self.messageFailedBackground = messageFailedBackground
        self.messageFailedForeground = messageFailedForeground
        self.messageFailedBorder = messageFailedBorder
        self.messageMetaForeground = messageMetaForeground
        self.messageStatusPending = messageStatusPending
        self.messageStatusSent = messageStatusSent
        self.messageStatusDelivered = messageStatusDelivered
        self.messageStatusRead = messageStatusRead
        self.messageStatusFailed = messageStatusFailed
        self.messageStatusOnOutgoing = messageStatusOnOutgoing
        self.messageStatusReadOnOutgoing = messageStatusReadOnOutgoing
        self.messageReplyBackground = messageReplyBackground
        self.messageReplyBorder = messageReplyBorder
        self.messageReactionBackground = messageReactionBackground
        self.messageReactionSelected = messageReactionSelected
        self.error = error
        self.errorText = errorText
        self.focusRing = focusRing
        self.important = important
        self.info = info
        self.infoText = infoText
        self.pinned = pinned
        self.primary = primary
        self.primaryActive = primaryActive
        self.primaryHover = primaryHover
        self.primaryText = primaryText
        self.robot = robot
        self.success = success
        self.successText = successText
        self.textDisabled = textDisabled
        self.textLink = textLink
        self.textLinkHover = textLinkHover
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.warning = warning
        self.warningText = warningText
        self.avatarTintBlueBg = avatarTintBlueBg
        self.avatarTintBlueFg = avatarTintBlueFg
        self.avatarTintPurpleBg = avatarTintPurpleBg
        self.avatarTintPurpleFg = avatarTintPurpleFg
        self.avatarTintPinkBg = avatarTintPinkBg
        self.avatarTintPinkFg = avatarTintPinkFg
        self.avatarTintGreenBg = avatarTintGreenBg
        self.avatarTintGreenFg = avatarTintGreenFg
        self.avatarTintAmberBg = avatarTintAmberBg
        self.avatarTintAmberFg = avatarTintAmberFg
        self.avatarTintSlateBg = avatarTintSlateBg
        self.avatarTintSlateFg = avatarTintSlateFg
    }

    public func copy(
        bgDisabled: Color? = nil,
        bgElevated: Color? = nil,
        bgHover: Color? = nil,
        bgPrimary: Color? = nil,
        bgSecondary: Color? = nil,
        bgSelected: Color? = nil,
        bgTertiary: Color? = nil,
        borderHover: Color? = nil,
        borderPrimary: Color? = nil,
        borderSecondary: Color? = nil,
        borderSelected: Color? = nil,
        messageIncomingBackground: Color? = nil,
        messageIncomingForeground: Color? = nil,
        messageIncomingBorder: Color? = nil,
        messageOutgoingBackground: Color? = nil,
        messageOutgoingForeground: Color? = nil,
        messageOutgoingBorder: Color? = nil,
        messageSelectedBackground: Color? = nil,
        messageSelectedBorder: Color? = nil,
        messageFailedBackground: Color? = nil,
        messageFailedForeground: Color? = nil,
        messageFailedBorder: Color? = nil,
        messageMetaForeground: Color? = nil,
        messageStatusPending: Color? = nil,
        messageStatusSent: Color? = nil,
        messageStatusDelivered: Color? = nil,
        messageStatusRead: Color? = nil,
        messageStatusFailed: Color? = nil,
        messageStatusOnOutgoing: Color? = nil,
        messageStatusReadOnOutgoing: Color? = nil,
        messageReplyBackground: Color? = nil,
        messageReplyBorder: Color? = nil,
        messageReactionBackground: Color? = nil,
        messageReactionSelected: Color? = nil,
        error: Color? = nil,
        errorText: Color? = nil,
        focusRing: Color? = nil,
        important: Color? = nil,
        info: Color? = nil,
        infoText: Color? = nil,
        pinned: Color? = nil,
        primary: Color? = nil,
        primaryActive: Color? = nil,
        primaryHover: Color? = nil,
        primaryText: Color? = nil,
        robot: Color? = nil,
        success: Color? = nil,
        successText: Color? = nil,
        textDisabled: Color? = nil,
        textLink: Color? = nil,
        textLinkHover: Color? = nil,
        textPrimary: Color? = nil,
        textSecondary: Color? = nil,
        textTertiary: Color? = nil,
        warning: Color? = nil,
        warningText: Color? = nil,
        avatarTintBlueBg: Color? = nil,
        avatarTintBlueFg: Color? = nil,
        avatarTintPurpleBg: Color? = nil,
        avatarTintPurpleFg: Color? = nil,
        avatarTintPinkBg: Color? = nil,
        avatarTintPinkFg: Color? = nil,
        avatarTintGreenBg: Color? = nil,
        avatarTintGreenFg: Color? = nil,
        avatarTintAmberBg: Color? = nil,
        avatarTintAmberFg: Color? = nil,
        avatarTintSlateBg: Color? = nil,
        avatarTintSlateFg: Color? = nil
    ) -> FlareColors {
        FlareColors(
            bgDisabled: bgDisabled ?? self.bgDisabled,
            bgElevated: bgElevated ?? self.bgElevated,
            bgHover: bgHover ?? self.bgHover,
            bgPrimary: bgPrimary ?? self.bgPrimary,
            bgSecondary: bgSecondary ?? self.bgSecondary,
            bgSelected: bgSelected ?? self.bgSelected,
            bgTertiary: bgTertiary ?? self.bgTertiary,
            borderHover: borderHover ?? self.borderHover,
            borderPrimary: borderPrimary ?? self.borderPrimary,
            borderSecondary: borderSecondary ?? self.borderSecondary,
            borderSelected: borderSelected ?? self.borderSelected,
            messageIncomingBackground: messageIncomingBackground ?? self.messageIncomingBackground,
            messageIncomingForeground: messageIncomingForeground ?? self.messageIncomingForeground,
            messageIncomingBorder: messageIncomingBorder ?? self.messageIncomingBorder,
            messageOutgoingBackground: messageOutgoingBackground ?? self.messageOutgoingBackground,
            messageOutgoingForeground: messageOutgoingForeground ?? self.messageOutgoingForeground,
            messageOutgoingBorder: messageOutgoingBorder ?? self.messageOutgoingBorder,
            messageSelectedBackground: messageSelectedBackground ?? self.messageSelectedBackground,
            messageSelectedBorder: messageSelectedBorder ?? self.messageSelectedBorder,
            messageFailedBackground: messageFailedBackground ?? self.messageFailedBackground,
            messageFailedForeground: messageFailedForeground ?? self.messageFailedForeground,
            messageFailedBorder: messageFailedBorder ?? self.messageFailedBorder,
            messageMetaForeground: messageMetaForeground ?? self.messageMetaForeground,
            messageStatusPending: messageStatusPending ?? self.messageStatusPending,
            messageStatusSent: messageStatusSent ?? self.messageStatusSent,
            messageStatusDelivered: messageStatusDelivered ?? self.messageStatusDelivered,
            messageStatusRead: messageStatusRead ?? self.messageStatusRead,
            messageStatusFailed: messageStatusFailed ?? self.messageStatusFailed,
            messageStatusOnOutgoing: messageStatusOnOutgoing ?? self.messageStatusOnOutgoing,
            messageStatusReadOnOutgoing: messageStatusReadOnOutgoing ?? self.messageStatusReadOnOutgoing,
            messageReplyBackground: messageReplyBackground ?? self.messageReplyBackground,
            messageReplyBorder: messageReplyBorder ?? self.messageReplyBorder,
            messageReactionBackground: messageReactionBackground ?? self.messageReactionBackground,
            messageReactionSelected: messageReactionSelected ?? self.messageReactionSelected,
            error: error ?? self.error,
            errorText: errorText ?? self.errorText,
            focusRing: focusRing ?? self.focusRing,
            important: important ?? self.important,
            info: info ?? self.info,
            infoText: infoText ?? self.infoText,
            pinned: pinned ?? self.pinned,
            primary: primary ?? self.primary,
            primaryActive: primaryActive ?? self.primaryActive,
            primaryHover: primaryHover ?? self.primaryHover,
            primaryText: primaryText ?? self.primaryText,
            robot: robot ?? self.robot,
            success: success ?? self.success,
            successText: successText ?? self.successText,
            textDisabled: textDisabled ?? self.textDisabled,
            textLink: textLink ?? self.textLink,
            textLinkHover: textLinkHover ?? self.textLinkHover,
            textPrimary: textPrimary ?? self.textPrimary,
            textSecondary: textSecondary ?? self.textSecondary,
            textTertiary: textTertiary ?? self.textTertiary,
            warning: warning ?? self.warning,
            warningText: warningText ?? self.warningText,
            avatarTintBlueBg: avatarTintBlueBg ?? self.avatarTintBlueBg,
            avatarTintBlueFg: avatarTintBlueFg ?? self.avatarTintBlueFg,
            avatarTintPurpleBg: avatarTintPurpleBg ?? self.avatarTintPurpleBg,
            avatarTintPurpleFg: avatarTintPurpleFg ?? self.avatarTintPurpleFg,
            avatarTintPinkBg: avatarTintPinkBg ?? self.avatarTintPinkBg,
            avatarTintPinkFg: avatarTintPinkFg ?? self.avatarTintPinkFg,
            avatarTintGreenBg: avatarTintGreenBg ?? self.avatarTintGreenBg,
            avatarTintGreenFg: avatarTintGreenFg ?? self.avatarTintGreenFg,
            avatarTintAmberBg: avatarTintAmberBg ?? self.avatarTintAmberBg,
            avatarTintAmberFg: avatarTintAmberFg ?? self.avatarTintAmberFg,
            avatarTintSlateBg: avatarTintSlateBg ?? self.avatarTintSlateBg,
            avatarTintSlateFg: avatarTintSlateFg ?? self.avatarTintSlateFg
        )
    }

    public static let violetLight = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.9412, green: 0.9255, blue: 0.9882, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.7882, green: 0.8039, blue: 0.8431, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 0.9490, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        messageIncomingBorder: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        messageOutgoingBackground: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.9412, green: 0.9255, blue: 0.9882, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.9961, green: 0.9490, blue: 0.9490, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.7255, green: 0.1098, blue: 0.1098, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusRead: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.9294, green: 0.9137, blue: 0.9961, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        messageReplyBorder: Color(.sRGB, red: 0.5451, green: 0.3608, blue: 0.9647, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageReactionSelected: Color(.sRGB, red: 0.9294, green: 0.9137, blue: 0.9961, opacity: 1.0),
        error: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 0.3400),
        important: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.3098, green: 0.2745, blue: 0.8980, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        primary: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.2980, green: 0.1137, blue: 0.5843, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.7176, green: 0.7412, blue: 0.7843, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        warning: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.9137, green: 0.8353, blue: 1.0000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.6157, green: 0.0902, blue: 0.3020, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.8196, green: 0.9804, blue: 0.8980, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.0157, green: 0.4706, blue: 0.3412, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.9961, green: 0.9529, blue: 0.7804, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.2157, green: 0.2549, blue: 0.3176, opacity: 1.0)
    )

    public static let violetDark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1686, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0902, green: 0.0980, blue: 0.1216, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.1765, green: 0.1373, blue: 0.2510, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.6549, green: 0.5451, blue: 0.9804, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        messageIncomingBorder: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        messageOutgoingBackground: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.5451, green: 0.3608, blue: 0.9647, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.1765, green: 0.1373, blue: 0.2510, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.6549, green: 0.5451, blue: 0.9804, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.2471, green: 0.1137, blue: 0.1412, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.6000, green: 0.1059, blue: 0.1059, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        messageStatusRead: Color(.sRGB, red: 0.7686, green: 0.7098, blue: 0.9922, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.9294, green: 0.9137, blue: 0.9961, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0700),
        messageReplyBorder: Color(.sRGB, red: 0.6549, green: 0.5451, blue: 0.9804, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        messageReactionSelected: Color(.sRGB, red: 0.5451, green: 0.3608, blue: 0.9647, opacity: 0.3000),
        error: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.7686, green: 0.7098, blue: 0.9922, opacity: 0.4200),
        important: Color(.sRGB, red: 0.8510, green: 0.4667, blue: 0.0235, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.6471, green: 0.7059, blue: 0.9882, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.7686, green: 0.7098, blue: 0.9922, opacity: 1.0),
        primary: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.3569, green: 0.1294, blue: 0.7137, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.4863, green: 0.2275, blue: 0.9294, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.7686, green: 0.7098, blue: 0.9922, opacity: 1.0),
        robot: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.7686, green: 0.7098, blue: 0.9922, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        warning: Color(.sRGB, red: 0.6314, green: 0.3843, blue: 0.0275, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.1216, green: 0.1961, blue: 0.4000, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.2275, green: 0.1451, blue: 0.4000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.3608, green: 0.1216, blue: 0.2431, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.0824, green: 0.2627, blue: 0.2353, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.6549, green: 0.9529, blue: 0.8157, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.3451, green: 0.2078, blue: 0.1176, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.9922, green: 0.9020, blue: 0.5412, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.1569, green: 0.1765, blue: 0.2196, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0)
    )

    public static let oceanLight = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.9373, green: 0.9647, blue: 1.0000, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.7882, green: 0.8039, blue: 0.8431, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 0.9490, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.1451, green: 0.3882, blue: 0.9216, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        messageIncomingBorder: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        messageOutgoingBackground: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.1176, green: 0.2510, blue: 0.6863, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.9373, green: 0.9647, blue: 1.0000, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.1451, green: 0.3882, blue: 0.9216, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.9961, green: 0.9490, blue: 0.9490, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.7255, green: 0.1098, blue: 0.1098, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusRead: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        messageReplyBorder: Color(.sRGB, red: 0.2314, green: 0.5098, blue: 0.9647, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageReactionSelected: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        error: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.1451, green: 0.3882, blue: 0.9216, opacity: 0.3400),
        important: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.3098, green: 0.2745, blue: 0.8980, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        primary: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.1176, green: 0.2275, blue: 0.5412, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.1176, green: 0.2510, blue: 0.6863, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.7176, green: 0.7412, blue: 0.7843, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.1176, green: 0.2510, blue: 0.6863, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        warning: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.9137, green: 0.8353, blue: 1.0000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.6157, green: 0.0902, blue: 0.3020, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.8196, green: 0.9804, blue: 0.8980, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.0157, green: 0.4706, blue: 0.3412, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.9961, green: 0.9529, blue: 0.7804, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.2157, green: 0.2549, blue: 0.3176, opacity: 1.0)
    )

    public static let oceanDark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1686, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0902, green: 0.0980, blue: 0.1216, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.0902, green: 0.1647, blue: 0.2745, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.3765, green: 0.6471, blue: 0.9804, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        messageIncomingBorder: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        messageOutgoingBackground: Color(.sRGB, red: 0.1176, green: 0.2510, blue: 0.6863, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.2314, green: 0.5098, blue: 0.9647, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.0902, green: 0.1647, blue: 0.2745, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.3765, green: 0.6471, blue: 0.9804, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.2471, green: 0.1137, blue: 0.1412, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.6000, green: 0.1059, blue: 0.1059, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        messageStatusRead: Color(.sRGB, red: 0.5765, green: 0.7725, blue: 0.9922, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0700),
        messageReplyBorder: Color(.sRGB, red: 0.3765, green: 0.6471, blue: 0.9804, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        messageReactionSelected: Color(.sRGB, red: 0.2314, green: 0.5098, blue: 0.9647, opacity: 0.3000),
        error: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.5765, green: 0.7725, blue: 0.9922, opacity: 0.4200),
        important: Color(.sRGB, red: 0.8510, green: 0.4667, blue: 0.0235, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.6471, green: 0.7059, blue: 0.9882, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.5765, green: 0.7725, blue: 0.9922, opacity: 1.0),
        primary: Color(.sRGB, red: 0.1176, green: 0.2510, blue: 0.6863, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.1176, green: 0.2275, blue: 0.5412, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.5765, green: 0.7725, blue: 0.9922, opacity: 1.0),
        robot: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.5765, green: 0.7725, blue: 0.9922, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        warning: Color(.sRGB, red: 0.6314, green: 0.3843, blue: 0.0275, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.1216, green: 0.1961, blue: 0.4000, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.2275, green: 0.1451, blue: 0.4000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.3608, green: 0.1216, blue: 0.2431, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.0824, green: 0.2627, blue: 0.2353, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.6549, green: 0.9529, blue: 0.8157, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.3451, green: 0.2078, blue: 0.1176, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.9922, green: 0.9020, blue: 0.5412, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.1569, green: 0.1765, blue: 0.2196, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0)
    )

    public static let forestLight = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.9412, green: 0.9922, blue: 0.9569, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.7882, green: 0.8039, blue: 0.8431, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 0.9490, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        messageIncomingBorder: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        messageOutgoingBackground: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.0863, green: 0.3961, blue: 0.2039, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.9412, green: 0.9922, blue: 0.9569, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.9961, green: 0.9490, blue: 0.9490, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.7255, green: 0.1098, blue: 0.1098, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusRead: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.8627, green: 0.9882, blue: 0.9059, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        messageReplyBorder: Color(.sRGB, red: 0.1333, green: 0.7725, blue: 0.3686, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageReactionSelected: Color(.sRGB, red: 0.8627, green: 0.9882, blue: 0.9059, opacity: 1.0),
        error: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 0.3400),
        important: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.3098, green: 0.2745, blue: 0.8980, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        primary: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.0784, green: 0.3255, blue: 0.1765, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.0863, green: 0.3961, blue: 0.2039, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.7176, green: 0.7412, blue: 0.7843, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.0863, green: 0.3961, blue: 0.2039, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        warning: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.9137, green: 0.8353, blue: 1.0000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.6157, green: 0.0902, blue: 0.3020, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.8196, green: 0.9804, blue: 0.8980, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.0157, green: 0.4706, blue: 0.3412, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.9961, green: 0.9529, blue: 0.7804, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.2157, green: 0.2549, blue: 0.3176, opacity: 1.0)
    )

    public static let forestDark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1686, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0902, green: 0.0980, blue: 0.1216, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.0941, green: 0.2078, blue: 0.1569, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        messageIncomingBorder: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        messageOutgoingBackground: Color(.sRGB, red: 0.0863, green: 0.3961, blue: 0.2039, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.1333, green: 0.7725, blue: 0.3686, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.0941, green: 0.2078, blue: 0.1569, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.2471, green: 0.1137, blue: 0.1412, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.6000, green: 0.1059, blue: 0.1059, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        messageStatusRead: Color(.sRGB, red: 0.5255, green: 0.9373, blue: 0.6745, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.8627, green: 0.9882, blue: 0.9059, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0700),
        messageReplyBorder: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        messageReactionSelected: Color(.sRGB, red: 0.1333, green: 0.7725, blue: 0.3686, opacity: 0.2800),
        error: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.5255, green: 0.9373, blue: 0.6745, opacity: 0.4000),
        important: Color(.sRGB, red: 0.8510, green: 0.4667, blue: 0.0235, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.6471, green: 0.7059, blue: 0.9882, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.5255, green: 0.9373, blue: 0.6745, opacity: 1.0),
        primary: Color(.sRGB, red: 0.0863, green: 0.3961, blue: 0.2039, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.0784, green: 0.3255, blue: 0.1765, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.5255, green: 0.9373, blue: 0.6745, opacity: 1.0),
        robot: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.5255, green: 0.9373, blue: 0.6745, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.7333, green: 0.9686, blue: 0.8157, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        warning: Color(.sRGB, red: 0.6314, green: 0.3843, blue: 0.0275, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.1216, green: 0.1961, blue: 0.4000, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.2275, green: 0.1451, blue: 0.4000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.3608, green: 0.1216, blue: 0.2431, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.0824, green: 0.2627, blue: 0.2353, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.6549, green: 0.9529, blue: 0.8157, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.3451, green: 0.2078, blue: 0.1176, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.9922, green: 0.9020, blue: 0.5412, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.1569, green: 0.1765, blue: 0.2196, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0)
    )

    public static let sunsetLight = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 1.0000, green: 0.9686, blue: 0.9294, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.7882, green: 0.8039, blue: 0.8431, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 0.9490, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.9176, green: 0.3451, blue: 0.0471, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        messageIncomingBorder: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        messageOutgoingBackground: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.6039, green: 0.2039, blue: 0.0706, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 1.0000, green: 0.9686, blue: 0.9294, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.9176, green: 0.3451, blue: 0.0471, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.9961, green: 0.9490, blue: 0.9490, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.7255, green: 0.1098, blue: 0.1098, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusRead: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 1.0000, green: 0.9294, blue: 0.8353, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        messageReplyBorder: Color(.sRGB, red: 0.9765, green: 0.4510, blue: 0.0863, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageReactionSelected: Color(.sRGB, red: 1.0000, green: 0.9294, blue: 0.8353, opacity: 1.0),
        error: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.9176, green: 0.3451, blue: 0.0471, opacity: 0.3400),
        important: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.3098, green: 0.2745, blue: 0.8980, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        primary: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.4863, green: 0.1765, blue: 0.0706, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.6039, green: 0.2039, blue: 0.0706, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.7176, green: 0.7412, blue: 0.7843, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.6039, green: 0.2039, blue: 0.0706, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        warning: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.9137, green: 0.8353, blue: 1.0000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.6157, green: 0.0902, blue: 0.3020, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.8196, green: 0.9804, blue: 0.8980, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.0157, green: 0.4706, blue: 0.3412, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.9961, green: 0.9529, blue: 0.7804, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.2157, green: 0.2549, blue: 0.3176, opacity: 1.0)
    )

    public static let sunsetDark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1686, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0902, green: 0.0980, blue: 0.1216, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.2314, green: 0.1490, blue: 0.0980, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.9843, green: 0.5725, blue: 0.2353, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        messageIncomingBorder: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        messageOutgoingBackground: Color(.sRGB, red: 0.6039, green: 0.2039, blue: 0.0706, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.9176, green: 0.3451, blue: 0.0471, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.2314, green: 0.1490, blue: 0.0980, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.9843, green: 0.5725, blue: 0.2353, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.2471, green: 0.1137, blue: 0.1412, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.6000, green: 0.1059, blue: 0.1059, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        messageStatusRead: Color(.sRGB, red: 0.9922, green: 0.7294, blue: 0.4549, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 1.0000, green: 0.9294, blue: 0.8353, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0700),
        messageReplyBorder: Color(.sRGB, red: 0.9843, green: 0.5725, blue: 0.2353, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        messageReactionSelected: Color(.sRGB, red: 0.9765, green: 0.4510, blue: 0.0863, opacity: 0.2800),
        error: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.9922, green: 0.7294, blue: 0.4549, opacity: 0.4000),
        important: Color(.sRGB, red: 0.8510, green: 0.4667, blue: 0.0235, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.6471, green: 0.7059, blue: 0.9882, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.9922, green: 0.7294, blue: 0.4549, opacity: 1.0),
        primary: Color(.sRGB, red: 0.6039, green: 0.2039, blue: 0.0706, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.4863, green: 0.1765, blue: 0.0706, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.7608, green: 0.2549, blue: 0.0471, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.9922, green: 0.7294, blue: 0.4549, opacity: 1.0),
        robot: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.9922, green: 0.7294, blue: 0.4549, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.9961, green: 0.8431, blue: 0.6667, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        warning: Color(.sRGB, red: 0.6314, green: 0.3843, blue: 0.0275, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.1216, green: 0.1961, blue: 0.4000, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.2275, green: 0.1451, blue: 0.4000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.3608, green: 0.1216, blue: 0.2431, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.0824, green: 0.2627, blue: 0.2353, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.6549, green: 0.9529, blue: 0.8157, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.3451, green: 0.2078, blue: 0.1176, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.9922, green: 0.9020, blue: 0.5412, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.1569, green: 0.1765, blue: 0.2196, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0)
    )

    public static let roseLight = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 1.0000, green: 0.9451, blue: 0.9490, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.7882, green: 0.8039, blue: 0.8431, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 0.9490, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.8824, green: 0.1137, blue: 0.2824, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        messageIncomingBorder: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        messageOutgoingBackground: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.6235, green: 0.0706, blue: 0.2235, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 1.0000, green: 0.9451, blue: 0.9490, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.8824, green: 0.1137, blue: 0.2824, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.9961, green: 0.9490, blue: 0.9490, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.7255, green: 0.1098, blue: 0.1098, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusRead: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 1.0000, green: 0.8941, blue: 0.9020, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        messageReplyBorder: Color(.sRGB, red: 0.9569, green: 0.2471, blue: 0.3686, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageReactionSelected: Color(.sRGB, red: 1.0000, green: 0.8941, blue: 0.9020, opacity: 1.0),
        error: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.8824, green: 0.1137, blue: 0.2824, opacity: 0.3200),
        important: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.3098, green: 0.2745, blue: 0.8980, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        primary: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.5333, green: 0.0745, blue: 0.2157, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.6235, green: 0.0706, blue: 0.2235, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.7176, green: 0.7412, blue: 0.7843, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.6235, green: 0.0706, blue: 0.2235, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        warning: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.9137, green: 0.8353, blue: 1.0000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.6157, green: 0.0902, blue: 0.3020, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.8196, green: 0.9804, blue: 0.8980, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.0157, green: 0.4706, blue: 0.3412, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.9961, green: 0.9529, blue: 0.7804, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.2157, green: 0.2549, blue: 0.3176, opacity: 1.0)
    )

    public static let roseDark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1686, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0902, green: 0.0980, blue: 0.1216, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.2314, green: 0.1255, blue: 0.1569, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.9843, green: 0.4431, blue: 0.5216, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        messageIncomingBorder: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        messageOutgoingBackground: Color(.sRGB, red: 0.6235, green: 0.0706, blue: 0.2235, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.8824, green: 0.1137, blue: 0.2824, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.2314, green: 0.1255, blue: 0.1569, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.9843, green: 0.4431, blue: 0.5216, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.2471, green: 0.1137, blue: 0.1412, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.6000, green: 0.1059, blue: 0.1059, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        messageStatusRead: Color(.sRGB, red: 0.9922, green: 0.6431, blue: 0.6863, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 1.0000, green: 0.8941, blue: 0.9020, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0700),
        messageReplyBorder: Color(.sRGB, red: 0.9843, green: 0.4431, blue: 0.5216, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        messageReactionSelected: Color(.sRGB, red: 0.9569, green: 0.2471, blue: 0.3686, opacity: 0.2800),
        error: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.9922, green: 0.6431, blue: 0.6863, opacity: 0.4000),
        important: Color(.sRGB, red: 0.8510, green: 0.4667, blue: 0.0235, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.6471, green: 0.7059, blue: 0.9882, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.9922, green: 0.6431, blue: 0.6863, opacity: 1.0),
        primary: Color(.sRGB, red: 0.6235, green: 0.0706, blue: 0.2235, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.5333, green: 0.0745, blue: 0.2157, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.7451, green: 0.0706, blue: 0.2353, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.9922, green: 0.6431, blue: 0.6863, opacity: 1.0),
        robot: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.9922, green: 0.6431, blue: 0.6863, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.9961, green: 0.8039, blue: 0.8275, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        warning: Color(.sRGB, red: 0.6314, green: 0.3843, blue: 0.0275, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.1216, green: 0.1961, blue: 0.4000, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.2275, green: 0.1451, blue: 0.4000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.3608, green: 0.1216, blue: 0.2431, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.0824, green: 0.2627, blue: 0.2353, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.6549, green: 0.9529, blue: 0.8157, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.3451, green: 0.2078, blue: 0.1176, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.9922, green: 0.9020, blue: 0.5412, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.1569, green: 0.1765, blue: 0.2196, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0)
    )

    public static let graphiteLight = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgHover: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        bgPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.9451, green: 0.9608, blue: 0.9765, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        borderHover: Color(.sRGB, red: 0.7882, green: 0.8039, blue: 0.8431, opacity: 1.0),
        borderPrimary: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        borderSecondary: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 0.9490, opacity: 1.0),
        borderSelected: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        messageIncomingBorder: Color(.sRGB, red: 0.8902, green: 0.8980, blue: 0.9216, opacity: 1.0),
        messageOutgoingBackground: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.2000, green: 0.2549, blue: 0.3333, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.9451, green: 0.9608, blue: 0.9765, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.9961, green: 0.9490, blue: 0.9490, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.7255, green: 0.1098, blue: 0.1098, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        messageStatusRead: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.8863, green: 0.9098, blue: 0.9412, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 0.9686, green: 0.9725, blue: 0.9804, opacity: 1.0),
        messageReplyBorder: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 0.9451, green: 0.9490, blue: 0.9608, opacity: 1.0),
        messageReactionSelected: Color(.sRGB, red: 0.8863, green: 0.9098, blue: 0.9412, opacity: 1.0),
        error: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.7765, green: 0.1569, blue: 0.1569, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 0.3400),
        important: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.3098, green: 0.2745, blue: 0.8980, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        primary: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.1176, green: 0.1608, blue: 0.2314, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.2000, green: 0.2549, blue: 0.3333, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        robot: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.0824, green: 0.5020, blue: 0.2392, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 0.7176, green: 0.7412, blue: 0.7843, opacity: 1.0),
        textLink: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.2000, green: 0.2549, blue: 0.3333, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1765, opacity: 1.0),
        textSecondary: Color(.sRGB, red: 0.3608, green: 0.3882, blue: 0.4431, opacity: 1.0),
        textTertiary: Color(.sRGB, red: 0.3725, green: 0.4039, blue: 0.4627, opacity: 1.0),
        warning: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.8588, green: 0.9176, blue: 0.9961, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.1137, green: 0.3059, blue: 0.8471, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.9137, green: 0.8353, blue: 1.0000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.4275, green: 0.1569, blue: 0.8510, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.6157, green: 0.0902, blue: 0.3020, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.8196, green: 0.9804, blue: 0.8980, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.0157, green: 0.4706, blue: 0.3412, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.9961, green: 0.9529, blue: 0.7804, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.7059, green: 0.3255, blue: 0.0353, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.2157, green: 0.2549, blue: 0.3176, opacity: 1.0)
    )

    public static let graphiteDark = FlareColors(
        bgDisabled: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgElevated: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        bgHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0600),
        bgPrimary: Color(.sRGB, red: 0.1255, green: 0.1373, blue: 0.1686, opacity: 1.0),
        bgSecondary: Color(.sRGB, red: 0.0902, green: 0.0980, blue: 0.1216, opacity: 1.0),
        bgSelected: Color(.sRGB, red: 0.1686, green: 0.2039, blue: 0.2510, opacity: 1.0),
        bgTertiary: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        borderHover: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1600),
        borderPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        borderSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        borderSelected: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        messageIncomingBackground: Color(.sRGB, red: 0.1608, green: 0.1765, blue: 0.2157, opacity: 1.0),
        messageIncomingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        messageIncomingBorder: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1000),
        messageOutgoingBackground: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        messageOutgoingForeground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0),
        messageOutgoingBorder: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        messageSelectedBackground: Color(.sRGB, red: 0.1686, green: 0.2039, blue: 0.2510, opacity: 1.0),
        messageSelectedBorder: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        messageFailedBackground: Color(.sRGB, red: 0.2471, green: 0.1137, blue: 0.1412, opacity: 1.0),
        messageFailedForeground: Color(.sRGB, red: 0.9882, green: 0.6471, blue: 0.6471, opacity: 1.0),
        messageFailedBorder: Color(.sRGB, red: 0.6000, green: 0.1059, blue: 0.1059, opacity: 1.0),
        messageMetaForeground: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusPending: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusSent: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        messageStatusDelivered: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        messageStatusRead: Color(.sRGB, red: 0.7961, green: 0.8353, blue: 0.8824, opacity: 1.0),
        messageStatusFailed: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        messageStatusOnOutgoing: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.8000),
        messageStatusReadOnOutgoing: Color(.sRGB, red: 0.8863, green: 0.9098, blue: 0.9412, opacity: 1.0),
        messageReplyBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0700),
        messageReplyBorder: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        messageReactionBackground: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.0800),
        messageReactionSelected: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 0.2800),
        error: Color(.sRGB, red: 0.8627, green: 0.1490, blue: 0.1490, opacity: 1.0),
        errorText: Color(.sRGB, red: 0.9725, green: 0.4431, blue: 0.4431, opacity: 1.0),
        focusRing: Color(.sRGB, red: 0.7961, green: 0.8353, blue: 0.8824, opacity: 0.3800),
        important: Color(.sRGB, red: 0.8510, green: 0.4667, blue: 0.0235, opacity: 1.0),
        info: Color(.sRGB, red: 0.4275, green: 0.3647, blue: 0.9647, opacity: 1.0),
        infoText: Color(.sRGB, red: 0.6471, green: 0.7059, blue: 0.9882, opacity: 1.0),
        pinned: Color(.sRGB, red: 0.7961, green: 0.8353, blue: 0.8824, opacity: 1.0),
        primary: Color(.sRGB, red: 0.2784, green: 0.3333, blue: 0.4118, opacity: 1.0),
        primaryActive: Color(.sRGB, red: 0.2000, green: 0.2549, blue: 0.3333, opacity: 1.0),
        primaryHover: Color(.sRGB, red: 0.3922, green: 0.4549, blue: 0.5451, opacity: 1.0),
        primaryText: Color(.sRGB, red: 0.7961, green: 0.8353, blue: 0.8824, opacity: 1.0),
        robot: Color(.sRGB, red: 0.5804, green: 0.6392, blue: 0.7216, opacity: 1.0),
        success: Color(.sRGB, red: 0.0863, green: 0.6392, blue: 0.2902, opacity: 1.0),
        successText: Color(.sRGB, red: 0.2902, green: 0.8706, blue: 0.5020, opacity: 1.0),
        textDisabled: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2800),
        textLink: Color(.sRGB, red: 0.7961, green: 0.8353, blue: 0.8824, opacity: 1.0),
        textLinkHover: Color(.sRGB, red: 0.8863, green: 0.9098, blue: 0.9412, opacity: 1.0),
        textPrimary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.9400),
        textSecondary: Color(.sRGB, red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.6200),
        textTertiary: Color(.sRGB, red: 0.6039, green: 0.6392, blue: 0.7020, opacity: 1.0),
        warning: Color(.sRGB, red: 0.6314, green: 0.3843, blue: 0.0275, opacity: 1.0),
        warningText: Color(.sRGB, red: 0.9843, green: 0.7490, blue: 0.1412, opacity: 1.0),
        avatarTintBlueBg: Color(.sRGB, red: 0.1216, green: 0.1961, blue: 0.4000, opacity: 1.0),
        avatarTintBlueFg: Color(.sRGB, red: 0.7490, green: 0.8588, blue: 0.9961, opacity: 1.0),
        avatarTintPurpleBg: Color(.sRGB, red: 0.2275, green: 0.1451, blue: 0.4000, opacity: 1.0),
        avatarTintPurpleFg: Color(.sRGB, red: 0.8667, green: 0.8392, blue: 0.9961, opacity: 1.0),
        avatarTintPinkBg: Color(.sRGB, red: 0.3608, green: 0.1216, blue: 0.2431, opacity: 1.0),
        avatarTintPinkFg: Color(.sRGB, red: 0.9843, green: 0.8118, blue: 0.9098, opacity: 1.0),
        avatarTintGreenBg: Color(.sRGB, red: 0.0824, green: 0.2627, blue: 0.2353, opacity: 1.0),
        avatarTintGreenFg: Color(.sRGB, red: 0.6549, green: 0.9529, blue: 0.8157, opacity: 1.0),
        avatarTintAmberBg: Color(.sRGB, red: 0.3451, green: 0.2078, blue: 0.1176, opacity: 1.0),
        avatarTintAmberFg: Color(.sRGB, red: 0.9922, green: 0.9020, blue: 0.5412, opacity: 1.0),
        avatarTintSlateBg: Color(.sRGB, red: 0.1569, green: 0.1765, blue: 0.2196, opacity: 1.0),
        avatarTintSlateFg: Color(.sRGB, red: 0.8980, green: 0.9059, blue: 0.9216, opacity: 1.0)
    )

    public static let light = violetLight
    public static let dark = violetDark

    public static func of(_ scheme: ColorScheme, brand: FlareBrandTheme = .violet) -> FlareColors {
        scheme == .dark ? brand.dark : brand.light
    }
}

/// A named text role: what a title, a section header, body text or a caption is, in one place
/// (FR-051). Sizes are points; `weight` is the CSS weight, mapped to `Font.Weight` by `font`.
public struct FlareTextRole: Sendable {
    public let fontSize: CGFloat
    public let lineHeight: CGFloat
    public let weight: Int
    public var font: Font { .system(size: fontSize, weight: weight >= 700 ? .bold : weight >= 600 ? .semibold : weight >= 500 ? .medium : .regular) }
}

/// Flare IM text roles.
public enum FlareTextRoles {
    public static let title = FlareTextRole(fontSize: 20, lineHeight: 1.2, weight: 700)
    public static let section = FlareTextRole(fontSize: 13, lineHeight: 1.2, weight: 600)
    public static let body = FlareTextRole(fontSize: 14, lineHeight: 1.5, weight: 400)
    public static let caption = FlareTextRole(fontSize: 12, lineHeight: 1.5, weight: 400)
    public static let message = FlareTextRole(fontSize: 15, lineHeight: 1.45, weight: 400)
}

/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).
public enum FlareSizes {
    public static let fontSize2xs: CGFloat = 10.0
    public static let fontSizeXs: CGFloat = 11.0
    public static let fontSizeSm: CGFloat = 12.0
    public static let fontSizeMd: CGFloat = 13.0
    public static let fontSizeLg: CGFloat = 14.0
    public static let fontSizeXl: CGFloat = 15.0
    public static let fontSize2xl: CGFloat = 16.0
    public static let fontSize3xl: CGFloat = 18.0
    public static let fontSize4xl: CGFloat = 20.0
    public static let fontSize5xl: CGFloat = 24.0
    public static let iconSizeLg: CGFloat = 24.0
    public static let iconSizeMd: CGFloat = 20.0
    public static let iconSizeSm: CGFloat = 16.0
    public static let iconSizeXl: CGFloat = 32.0
    public static let avatarSize: CGFloat = 44.0
    public static let bubbleMaxWidth: CGFloat = 640.0
    public static let messageTimelineContentMaxWidth: CGFloat = 920.0
    public static let chatMinWidth: CGFloat = 360.0
    public static let navigationRailWidth: CGFloat = 72.0
    public static let navigationRailMinWidth: CGFloat = 600.0
    public static let workbenchResizeHandleWidth: CGFloat = 8.0
    public static let primaryPaneMinWidth: CGFloat = 280.0
    public static let primaryPaneDefaultWidth: CGFloat = 320.0
    public static let primaryPaneMaxWidth: CGFloat = 420.0
    public static let detailPaneDefaultWidth: CGFloat = 300.0
    public static let detailPaneMaxWidth: CGFloat = 420.0
    public static let appShellCompactMinWidth: CGFloat = 900.0
    public static let appShellExpandedMinWidth: CGFloat = 1500.0
    public static let controlHeightLg: CGFloat = 48.0
    public static let controlHeightMd: CGFloat = 40.0
    public static let controlHeightSm: CGFloat = 32.0
    public static let controlPadXLg: CGFloat = 24.0
    public static let controlPadXMd: CGFloat = 18.0
    public static let controlPadXSm: CGFloat = 12.0
    public static let headerHeight: CGFloat = 60.0
    public static let sessionItemHeight: CGFloat = 72.0
    public static let touchTarget: CGFloat = 48.0
    public static let touchTargetMin: CGFloat = 44.0
    public static let lineHeightNone: CGFloat = 1.0
    public static let lineHeightTight: CGFloat = 1.2
    public static let lineHeightSnug: CGFloat = 1.4
    public static let lineHeightNormal: CGFloat = 1.5
    public static let lineHeightRelaxed: CGFloat = 1.6
    public static let radiusXs: CGFloat = 3.0
    public static let radiusBubbleTail: CGFloat = 4.0
    public static let radiusSm: CGFloat = 6.0
    public static let radiusMd: CGFloat = 8.0
    public static let radiusLg: CGFloat = 10.0
    public static let radiusCard: CGFloat = 12.0
    public static let radiusXl: CGFloat = 14.0
    public static let radiusBubble: CGFloat = 16.0
    public static let radius2xl: CGFloat = 18.0
    public static let radiusFull: CGFloat = 999.0
    public static let spacing3xs: CGFloat = 2.0
    public static let spacingXs: CGFloat = 4.0
    public static let spacing2xs: CGFloat = 6.0
    public static let spacingSm: CGFloat = 8.0
    public static let spacing2sm: CGFloat = 10.0
    public static let spacingMd: CGFloat = 12.0
    public static let spacing2md: CGFloat = 14.0
    public static let spacingLg: CGFloat = 16.0
    public static let spacingXl: CGFloat = 20.0
    public static let spacing2xl: CGFloat = 24.0
    public static let componentBubblePaddingX: CGFloat = 14.0
    public static let componentBubblePaddingY: CGFloat = 9.0
    public static let componentMessageAvatarSize: CGFloat = 40.0
    public static let componentComposerActionHeight: CGFloat = 40.0
    public static let componentComposerActionWidth: CGFloat = 44.0
    public static let componentComposerToolbarIcon: CGFloat = 34.0
    public static let componentComposerToolbarWidth: CGFloat = 44.0
    public static let componentComposerDesktopHeight: CGFloat = 46.0
    public static let componentBubbleRichMinWidth: CGFloat = 220.0
    public static let componentBubbleSystemMaxWidth: CGFloat = 560.0
    public static let componentMessageGutterInline: CGFloat = 16.0
    public static let componentMessageTailSpace: CGFloat = 10.0
    public static let componentMediaCardMinWidth: CGFloat = 220.0
    public static let componentMediaImageMaxWidth: CGFloat = 320.0
    public static let componentMediaVideoWidth: CGFloat = 320.0
    public static let componentRichCardWidth: CGFloat = 320.0
    public static let componentRichCardCompactWidth: CGFloat = 240.0
    public static let componentRichCardMediaHeight: CGFloat = 148.0
    public static let componentSheetWidth: CGFloat = 420.0
    public static let componentSheetDialogWidth: CGFloat = 480.0
    public static let componentConversationRowMetaWidth: CGFloat = 60.0
    public static let componentBubbleMaxWidthRatioCompact: CGFloat = 0.88
    public static let componentBubbleMaxWidthRatioRegular: CGFloat = 0.62
}

/// Opacity tokens (disabled / muted / tint overlays).
public enum FlareOpacity {
    public static let disabled: Double = 0.5
    public static let muted: Double = 0.7
    public static let tintWeak: Double = 0.1
    public static let tintStrong: Double = 0.24
}

public struct FlareShadowLayer: Sendable {
    public let color: Color
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
}

/// Elevation tokens; apply every layer with `.shadow(color:radius:x:y:)`.
public struct FlareShadows: Sendable {
    public let card: [FlareShadowLayer]
    public let lg: [FlareShadowLayer]
    public let md: [FlareShadowLayer]
    public let none: [FlareShadowLayer]
    public let sm: [FlareShadowLayer]
    public let xl: [FlareShadowLayer]
    public static let light = FlareShadows(
        card: [FlareShadowLayer(color: Color(.sRGB, red: 0.0784, green: 0.0980, blue: 0.1490, opacity: 0.0600), x: 0, y: 2, blur: 8)],
        lg: [FlareShadowLayer(color: Color(.sRGB, red: 0.0784, green: 0.0980, blue: 0.1490, opacity: 0.1200), x: 0, y: 12, blur: 32)],
        md: [FlareShadowLayer(color: Color(.sRGB, red: 0.0784, green: 0.0980, blue: 0.1490, opacity: 0.1000), x: 0, y: 4, blur: 16)],
        none: [],
        sm: [FlareShadowLayer(color: Color(.sRGB, red: 0.0824, green: 0.0706, blue: 0.1255, opacity: 0.0500), x: 0, y: 1, blur: 2), FlareShadowLayer(color: Color(.sRGB, red: 0.0824, green: 0.0706, blue: 0.1255, opacity: 0.0400), x: 0, y: 1, blur: 1)],
        xl: [FlareShadowLayer(color: Color(.sRGB, red: 0.0784, green: 0.0980, blue: 0.1490, opacity: 0.1600), x: 0, y: 20, blur: 56)]
    )
    public static let dark = FlareShadows(
        card: [FlareShadowLayer(color: Color(.sRGB, red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.3200), x: 0, y: 8, blur: 28)],
        lg: [FlareShadowLayer(color: Color(.sRGB, red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.3200), x: 0, y: 8, blur: 28)],
        md: [FlareShadowLayer(color: Color(.sRGB, red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.3200), x: 0, y: 8, blur: 28)],
        none: [],
        sm: [FlareShadowLayer(color: Color(.sRGB, red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.4200), x: 0, y: 1, blur: 2), FlareShadowLayer(color: Color(.sRGB, red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.3000), x: 0, y: 1, blur: 1)],
        xl: [FlareShadowLayer(color: Color(.sRGB, red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.3200), x: 0, y: 8, blur: 28)]
    )
    public static func of(_ scheme: ColorScheme) -> FlareShadows { scheme == .dark ? dark : light }
}

/// Motion tokens: durations (seconds) and animations shared with the web transitions.
public enum FlareMotion {
    public static let fast: Double = 0.150
    public static var fastAnimation: Animation { .timingCurve(0.22, 1, 0.36, 1, duration: 0.150) }
    public static let normal: Double = 0.200
    public static var normalAnimation: Animation { .timingCurve(0.22, 1, 0.36, 1, duration: 0.200) }
    public static let slow: Double = 0.260
    public static var slowAnimation: Animation { .timingCurve(0.22, 1, 0.36, 1, duration: 0.260) }
    public static let spring: Double = 0.360
    public static var springAnimation: Animation { .timingCurve(0.34, 1.4, 0.5, 1, duration: 0.360) }
}
