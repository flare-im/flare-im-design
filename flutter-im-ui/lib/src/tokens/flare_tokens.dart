// GENERATED. Do not edit by hand. Source: flare-im-design-tokens/tokens.json

import 'dart:ui';

/// Flare IM design colours, theme-aware. Use [FlareColors.of] with the ambient
/// [Brightness] (e.g. `Theme.of(context).brightness`).
class FlareColors {
  const FlareColors({
    required this.bgDisabled,
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
    bgDisabled: Color(0xFFF2F3F5),
    bgHover: Color(0xFFEEF1F6),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF5F6F8),
    bgSelected: Color(0xFFF1EAFF),
    bgTertiary: Color(0xFFF2F3F5),
    borderHover: Color(0xFFD7DBE3),
    borderPrimary: Color(0xFFE7E9EE),
    borderSecondary: Color(0xFFEEF0F4),
    borderSelected: Color(0xFF7C3AED),
    bubbleOther: Color(0xFFECE5FF),
    bubbleRobot: Color(0xFFF4F0FF),
    bubbleSelf: Color(0xFF7C3AED),
    bubbleSystem: Color(0xFFF2F3F5),
    error: Color(0xFFEF4444),
    important: Color(0xFFF59E0B),
    info: Color(0xFF6D5DF6),
    pinned: Color(0xFF7C3AED),
    primary: Color(0xFF7C3AED),
    primaryActive: Color(0xFF5B21B6),
    primaryHover: Color(0xFF6D28D9),
    robot: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    textDisabled: Color(0xFFC9CDD4),
    textLink: Color(0xFF7C3AED),
    textLinkHover: Color(0xFF6D28D9),
    textPrimary: Color(0xFF111318),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFFA3A7AE),
    warning: Color(0xFFF59E0B),
  );

  static const FlareColors dark = FlareColors(
    bgDisabled: Color(0xFFF2F3F5),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF1A1D23),
    bgSecondary: Color(0xFF111318),
    bgSelected: Color(0x337C3AED),
    bgTertiary: Color(0xFF22262E),
    borderHover: Color(0xFFD7DBE3),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFFA78BFA),
    bubbleOther: Color(0xFF241D33),
    bubbleRobot: Color(0xFF2B2340),
    bubbleSelf: Color(0xFF8B5CF6),
    bubbleSystem: Color(0xFFF2F3F5),
    error: Color(0xFFEF4444),
    important: Color(0xFFF59E0B),
    info: Color(0xFF6D5DF6),
    pinned: Color(0xFF7C3AED),
    primary: Color(0xFF7C3AED),
    primaryActive: Color(0xFF5B21B6),
    primaryHover: Color(0xFF6D28D9),
    robot: Color(0xFF64748B),
    success: Color(0xFF22C55E),
    textDisabled: Color(0xFFC9CDD4),
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
  static const double radiusLg = 8.0;
  static const double radiusMd = 6.0;
  static const double radiusSm = 4.0;
  static const double radiusXl = 12.0;
  static const double radiusXs = 2.0;
  static const double spacing2xl = 24.0;
  static const double spacingLg = 16.0;
  static const double spacingMd = 12.0;
  static const double spacingSm = 8.0;
  static const double spacingXl = 20.0;
  static const double spacingXs = 4.0;
}
