// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json

import 'dart:ui';

/// Flare IM design colours, theme-aware. Use [FlareColors.of] with the ambient
/// [Brightness] (e.g. `Theme.of(context).brightness`).
class FlareColors {
  const FlareColors({
    required this.auroraDeep,
    required this.auroraBase,
    required this.auroraSoft,
    required this.auroraMist,
    required this.bgDisabled,
    required this.bgElevated,
    required this.bgHover,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgSelected,
    required this.bgTertiary,
    required this.borderHover,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.borderSelected,
    required this.bubbleOther,
    required this.bubbleRobot,
    required this.bubbleSelf,
    required this.bubbleSystem,
    required this.error,
    required this.focusRing,
    required this.important,
    required this.info,
    required this.pinned,
    required this.primary,
    required this.primaryActive,
    required this.primaryHover,
    required this.robot,
    required this.success,
    required this.textDisabled,
    required this.textLink,
    required this.textLinkHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.warning,
  });

  final Color auroraDeep;
  final Color auroraBase;
  final Color auroraSoft;
  final Color auroraMist;
  final Color bgDisabled;
  final Color bgElevated;
  final Color bgHover;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgSelected;
  final Color bgTertiary;
  final Color borderHover;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color borderSelected;
  final Color bubbleOther;
  final Color bubbleRobot;
  final Color bubbleSelf;
  final Color bubbleSystem;
  final Color error;
  final Color focusRing;
  final Color important;
  final Color info;
  final Color pinned;
  final Color primary;
  final Color primaryActive;
  final Color primaryHover;
  final Color robot;
  final Color success;
  final Color textDisabled;
  final Color textLink;
  final Color textLinkHover;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color warning;

  static const FlareColors light = FlareColors(
    auroraDeep: Color(0xFF391F7A),
    auroraBase: Color(0xFF7047D6),
    auroraSoft: Color(0xFF9C7EE7),
    auroraMist: Color(0xFFCCBBF7),
    bgDisabled: Color(0xFFF1F2F5),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1F2F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7F8FA),
    bgSelected: Color(0xFFF0ECFC),
    bgTertiary: Color(0xFFF1F2F5),
    borderHover: Color(0xFFC9CDD7),
    borderPrimary: Color(0xFFE3E5EB),
    borderSecondary: Color(0xFFECEEF2),
    borderSelected: Color(0xFF7C3AED),
    bubbleOther: Color(0xFFFFFFFF),
    bubbleRobot: Color(0xFFF1F2F5),
    bubbleSelf: Color(0xFF7047D6),
    bubbleSystem: Color(0xFFF1F2F5),
    error: Color(0xFFEF4444),
    focusRing: Color(0x597047D6),
    important: Color(0xFFF59E0B),
    info: Color(0xFF6D5DF6),
    pinned: Color(0xFF7047D6),
    primary: Color(0xFF7047D6),
    primaryActive: Color(0xFF512CAC),
    primaryHover: Color(0xFF6138C4),
    robot: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFF7047D6),
    textLinkHover: Color(0xFF6138C4),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF626978),
    textTertiary: Color(0xFF687182),
    warning: Color(0xFFF59E0B),
  );

  static const FlareColors dark = FlareColors(
    auroraDeep: Color(0xFF391F7A),
    auroraBase: Color(0xFF7047D6),
    auroraSoft: Color(0xFF9C7EE7),
    auroraMist: Color(0xFFCCBBF7),
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0x337C3AED),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFFA78BFA),
    bubbleOther: Color(0xFF20232B),
    bubbleRobot: Color(0xFF292D37),
    bubbleSelf: Color(0xFF7047D6),
    bubbleSystem: Color(0xFF292D37),
    error: Color(0xFFEF4444),
    focusRing: Color(0x66A78BFA),
    important: Color(0xFFF59E0B),
    info: Color(0xFF6D5DF6),
    pinned: Color(0xFF7047D6),
    primary: Color(0xFF7047D6),
    primaryActive: Color(0xFF512CAC),
    primaryHover: Color(0xFF6138C4),
    robot: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFFC4B5FD),
    textLinkHover: Color(0xFF6138C4),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFF59E0B),
  );

  static FlareColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).
abstract final class FlareSizes {
  static const double fontSize2xl = 16.0;
  static const double fontSize3xl = 18.0;
  static const double fontSize4xl = 20.0;
  static const double fontSizeLg = 14.0;
  static const double fontSizeMd = 13.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeXl = 15.0;
  static const double fontSizeXs = 11.0;
  static const double avatarSize = 44.0;
  static const double headerHeight = 60.0;
  static const double leftPanel = 320.0;
  static const double rightPanel = 300.0;
  static const double sessionItemHeight = 72.0;
  static const double dualPaneMinWidth = 720.0;
  static const double triplePaneMinWidth = 1100.0;
  static const double chatMinWidth = 360.0;
  static const double touchTarget = 48.0;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightTight = 1.2;
  static const double radius2xl = 18.0;
  static const double radiusFull = 999.0;
  static const double radiusLg = 10.0;
  static const double radiusMd = 8.0;
  static const double radiusSm = 6.0;
  static const double radiusXl = 14.0;
  static const double radiusXs = 3.0;
  static const double spacing2xl = 24.0;
  static const double spacingLg = 16.0;
  static const double spacingMd = 12.0;
  static const double spacingSm = 8.0;
  static const double spacingXl = 20.0;
  static const double spacingXs = 4.0;
}

/// Const palette for const widget and ThemeData declarations.
abstract final class FlarePalette {
  static const Color lightAuroraDeep = Color(0xFF391F7A);
  static const Color darkAuroraDeep = Color(0xFF391F7A);
  static const Color lightAuroraBase = Color(0xFF7047D6);
  static const Color darkAuroraBase = Color(0xFF7047D6);
  static const Color lightAuroraSoft = Color(0xFF9C7EE7);
  static const Color darkAuroraSoft = Color(0xFF9C7EE7);
  static const Color lightAuroraMist = Color(0xFFCCBBF7);
  static const Color darkAuroraMist = Color(0xFFCCBBF7);
  static const Color lightBgDisabled = Color(0xFFF1F2F5);
  static const Color darkBgDisabled = Color(0xFF292D37);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color darkBgElevated = Color(0xFF292D37);
  static const Color lightBgHover = Color(0xFFF1F2F5);
  static const Color darkBgHover = Color(0x0FFFFFFF);
  static const Color lightBgPrimary = Color(0xFFFFFFFF);
  static const Color darkBgPrimary = Color(0xFF20232B);
  static const Color lightBgSecondary = Color(0xFFF7F8FA);
  static const Color darkBgSecondary = Color(0xFF17191F);
  static const Color lightBgSelected = Color(0xFFF0ECFC);
  static const Color darkBgSelected = Color(0x337C3AED);
  static const Color lightBgTertiary = Color(0xFFF1F2F5);
  static const Color darkBgTertiary = Color(0xFF292D37);
  static const Color lightBorderHover = Color(0xFFC9CDD7);
  static const Color darkBorderHover = Color(0x29FFFFFF);
  static const Color lightBorderPrimary = Color(0xFFE3E5EB);
  static const Color darkBorderPrimary = Color(0x1AFFFFFF);
  static const Color lightBorderSecondary = Color(0xFFECEEF2);
  static const Color darkBorderSecondary = Color(0x14FFFFFF);
  static const Color lightBorderSelected = Color(0xFF7C3AED);
  static const Color darkBorderSelected = Color(0xFFA78BFA);
  static const Color lightBubbleOther = Color(0xFFFFFFFF);
  static const Color darkBubbleOther = Color(0xFF20232B);
  static const Color lightBubbleRobot = Color(0xFFF1F2F5);
  static const Color darkBubbleRobot = Color(0xFF292D37);
  static const Color lightBubbleSelf = Color(0xFF7047D6);
  static const Color darkBubbleSelf = Color(0xFF7047D6);
  static const Color lightBubbleSystem = Color(0xFFF1F2F5);
  static const Color darkBubbleSystem = Color(0xFF292D37);
  static const Color lightError = Color(0xFFEF4444);
  static const Color darkError = Color(0xFFEF4444);
  static const Color lightFocusRing = Color(0x597047D6);
  static const Color darkFocusRing = Color(0x66A78BFA);
  static const Color lightImportant = Color(0xFFF59E0B);
  static const Color darkImportant = Color(0xFFF59E0B);
  static const Color lightInfo = Color(0xFF6D5DF6);
  static const Color darkInfo = Color(0xFF6D5DF6);
  static const Color lightPinned = Color(0xFF7047D6);
  static const Color darkPinned = Color(0xFF7047D6);
  static const Color lightPrimary = Color(0xFF7047D6);
  static const Color darkPrimary = Color(0xFF7047D6);
  static const Color lightPrimaryActive = Color(0xFF512CAC);
  static const Color darkPrimaryActive = Color(0xFF512CAC);
  static const Color lightPrimaryHover = Color(0xFF6138C4);
  static const Color darkPrimaryHover = Color(0xFF6138C4);
  static const Color lightRobot = Color(0xFF64748B);
  static const Color darkRobot = Color(0xFF64748B);
  static const Color lightSuccess = Color(0xFF22C55E);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color lightTextDisabled = Color(0xFFB7BDC8);
  static const Color darkTextDisabled = Color(0x47FFFFFF);
  static const Color lightTextLink = Color(0xFF7047D6);
  static const Color darkTextLink = Color(0xFFC4B5FD);
  static const Color lightTextLinkHover = Color(0xFF6138C4);
  static const Color darkTextLinkHover = Color(0xFF6138C4);
  static const Color lightTextPrimary = Color(0xFF20232D);
  static const Color darkTextPrimary = Color(0xF0FFFFFF);
  static const Color lightTextSecondary = Color(0xFF626978);
  static const Color darkTextSecondary = Color(0x9EFFFFFF);
  static const Color lightTextTertiary = Color(0xFF687182);
  static const Color darkTextTertiary = Color(0xFF9AA3B3);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color darkWarning = Color(0xFFF59E0B);
}

/// Decisions use the available container width, never the physical device model.
abstract final class FlareLayoutPolicy {
  static int paneCount(double width, {bool hasDetail = false, double textScale = 1,
      double listWidth = FlareSizes.leftPanel, double detailWidth = FlareSizes.rightPanel}) {
    final chat = FlareSizes.chatMinWidth * textScale.clamp(1.0, 2.0);
    final list = listWidth.clamp(0.0, double.infinity);
    final detail = detailWidth.clamp(0.0, double.infinity);
    if (hasDetail && width >= FlareSizes.triplePaneMinWidth && width >= list + detail + chat + 2) return 3;
    if (width >= FlareSizes.dualPaneMinWidth && width >= list + chat + 1) return 2;
    return 1;
  }
}
