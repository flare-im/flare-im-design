// GENERATED. Do not edit by hand. Source: flare-im-design-tokens/tokens.json

import 'dart:ui';

/// Flare IM design colours, theme-aware. Use [FlareColors.of] with the ambient
/// [Brightness] (e.g. `Theme.of(context).brightness`).
class FlareColors {
  const FlareColors({
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
    bgDisabled: Color(0xFFF3F1F9),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1EEF8),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF6F5FB),
    bgSelected: Color(0xFFF1EAFF),
    bgTertiary: Color(0xFFF3F1F9),
    borderHover: Color(0xFFDAD5E7),
    borderPrimary: Color(0xFFE9E6F1),
    borderSecondary: Color(0xFFF0EDF7),
    borderSelected: Color(0xFF7C3AED),
    bubbleOther: Color(0xFFECE5FF),
    bubbleRobot: Color(0xFFF4F0FF),
    bubbleSelf: Color(0xFF7C3AED),
    bubbleSystem: Color(0xFFF3F1F9),
    error: Color(0xFFEF4444),
    focusRing: Color(0x597C3AED),
    important: Color(0xFFF59E0B),
    info: Color(0xFF6D5DF6),
    pinned: Color(0xFF7C3AED),
    primary: Color(0xFF7C3AED),
    primaryActive: Color(0xFF5B21B6),
    primaryHover: Color(0xFF6D28D9),
    robot: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    textDisabled: Color(0xFFCCC8D8),
    textLink: Color(0xFF7C3AED),
    textLinkHover: Color(0xFF6D28D9),
    textPrimary: Color(0xFF15131C),
    textSecondary: Color(0xFF6B6780),
    textTertiary: Color(0xFFA7A2B4),
    warning: Color(0xFFF59E0B),
  );

  static const FlareColors dark = FlareColors(
    bgDisabled: Color(0xFF272334),
    bgElevated: Color(0xFF221E30),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF1B1922),
    bgSecondary: Color(0xFF131019),
    bgSelected: Color(0x337C3AED),
    bgTertiary: Color(0xFF232030),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFFA78BFA),
    bubbleOther: Color(0xFF241D33),
    bubbleRobot: Color(0xFF2B2340),
    bubbleSelf: Color(0xFF8B5CF6),
    bubbleSystem: Color(0xFF232030),
    error: Color(0xFFEF4444),
    focusRing: Color(0x66A78BFA),
    important: Color(0xFFF59E0B),
    info: Color(0xFF6D5DF6),
    pinned: Color(0xFF7C3AED),
    primary: Color(0xFF7C3AED),
    primaryActive: Color(0xFF5B21B6),
    primaryHover: Color(0xFF6D28D9),
    robot: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFFC4B5FD),
    textLinkHover: Color(0xFF6D28D9),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0x66FFFFFF),
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
  static const double avatarSize = 42.0;
  static const double headerHeight = 60.0;
  static const double leftPanel = 260.0;
  static const double rightPanel = 300.0;
  static const double sessionItemHeight = 68.0;
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
