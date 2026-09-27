// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json

import 'dart:ui' show Brightness, Color, Offset;
import 'package:flutter/animation.dart' show Curve, Cubic;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/painting.dart' show BoxShadow;
import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget;

enum FlareBrandTheme { violet, ocean, forest, sunset, rose, graphite }

/// Flare IM semantic colors resolved by brand and brightness.
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
    required this.messageIncomingBackground,
    required this.messageIncomingForeground,
    required this.messageIncomingBorder,
    required this.messageOutgoingBackground,
    required this.messageOutgoingForeground,
    required this.messageOutgoingBorder,
    required this.messageSelectedBackground,
    required this.messageSelectedBorder,
    required this.messageFailedBackground,
    required this.messageFailedForeground,
    required this.messageFailedBorder,
    required this.messageMetaForeground,
    required this.messageStatusPending,
    required this.messageStatusSent,
    required this.messageStatusDelivered,
    required this.messageStatusRead,
    required this.messageStatusFailed,
    required this.messageStatusOnOutgoing,
    required this.messageStatusReadOnOutgoing,
    required this.messageReplyBackground,
    required this.messageReplyBorder,
    required this.messageReactionBackground,
    required this.messageReactionSelected,
    required this.error,
    required this.errorText,
    required this.focusRing,
    required this.important,
    required this.info,
    required this.infoText,
    required this.pinned,
    required this.primary,
    required this.primaryActive,
    required this.primaryHover,
    required this.primaryText,
    required this.robot,
    required this.success,
    required this.successText,
    required this.textDisabled,
    required this.textLink,
    required this.textLinkHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.warning,
    required this.warningText,
    required this.avatarTintBlueBg,
    required this.avatarTintBlueFg,
    required this.avatarTintPurpleBg,
    required this.avatarTintPurpleFg,
    required this.avatarTintPinkBg,
    required this.avatarTintPinkFg,
    required this.avatarTintGreenBg,
    required this.avatarTintGreenFg,
    required this.avatarTintAmberBg,
    required this.avatarTintAmberFg,
    required this.avatarTintSlateBg,
    required this.avatarTintSlateFg,
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
  final Color messageIncomingBackground;
  final Color messageIncomingForeground;
  final Color messageIncomingBorder;
  final Color messageOutgoingBackground;
  final Color messageOutgoingForeground;
  final Color messageOutgoingBorder;
  final Color messageSelectedBackground;
  final Color messageSelectedBorder;
  final Color messageFailedBackground;
  final Color messageFailedForeground;
  final Color messageFailedBorder;
  final Color messageMetaForeground;
  final Color messageStatusPending;
  final Color messageStatusSent;
  final Color messageStatusDelivered;
  final Color messageStatusRead;
  final Color messageStatusFailed;
  final Color messageStatusOnOutgoing;
  final Color messageStatusReadOnOutgoing;
  final Color messageReplyBackground;
  final Color messageReplyBorder;
  final Color messageReactionBackground;
  final Color messageReactionSelected;
  final Color error;
  final Color errorText;
  final Color focusRing;
  final Color important;
  final Color info;
  final Color infoText;
  final Color pinned;
  final Color primary;
  final Color primaryActive;
  final Color primaryHover;
  final Color primaryText;
  final Color robot;
  final Color success;
  final Color successText;
  final Color textDisabled;
  final Color textLink;
  final Color textLinkHover;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color warning;
  final Color warningText;
  final Color avatarTintBlueBg;
  final Color avatarTintBlueFg;
  final Color avatarTintPurpleBg;
  final Color avatarTintPurpleFg;
  final Color avatarTintPinkBg;
  final Color avatarTintPinkFg;
  final Color avatarTintGreenBg;
  final Color avatarTintGreenFg;
  final Color avatarTintAmberBg;
  final Color avatarTintAmberFg;
  final Color avatarTintSlateBg;
  final Color avatarTintSlateFg;

  FlareColors copyWith({
    Color? bgDisabled,
    Color? bgElevated,
    Color? bgHover,
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgSelected,
    Color? bgTertiary,
    Color? borderHover,
    Color? borderPrimary,
    Color? borderSecondary,
    Color? borderSelected,
    Color? messageIncomingBackground,
    Color? messageIncomingForeground,
    Color? messageIncomingBorder,
    Color? messageOutgoingBackground,
    Color? messageOutgoingForeground,
    Color? messageOutgoingBorder,
    Color? messageSelectedBackground,
    Color? messageSelectedBorder,
    Color? messageFailedBackground,
    Color? messageFailedForeground,
    Color? messageFailedBorder,
    Color? messageMetaForeground,
    Color? messageStatusPending,
    Color? messageStatusSent,
    Color? messageStatusDelivered,
    Color? messageStatusRead,
    Color? messageStatusFailed,
    Color? messageStatusOnOutgoing,
    Color? messageStatusReadOnOutgoing,
    Color? messageReplyBackground,
    Color? messageReplyBorder,
    Color? messageReactionBackground,
    Color? messageReactionSelected,
    Color? error,
    Color? errorText,
    Color? focusRing,
    Color? important,
    Color? info,
    Color? infoText,
    Color? pinned,
    Color? primary,
    Color? primaryActive,
    Color? primaryHover,
    Color? primaryText,
    Color? robot,
    Color? success,
    Color? successText,
    Color? textDisabled,
    Color? textLink,
    Color? textLinkHover,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? warning,
    Color? warningText,
    Color? avatarTintBlueBg,
    Color? avatarTintBlueFg,
    Color? avatarTintPurpleBg,
    Color? avatarTintPurpleFg,
    Color? avatarTintPinkBg,
    Color? avatarTintPinkFg,
    Color? avatarTintGreenBg,
    Color? avatarTintGreenFg,
    Color? avatarTintAmberBg,
    Color? avatarTintAmberFg,
    Color? avatarTintSlateBg,
    Color? avatarTintSlateFg,
  }) => FlareColors(
    bgDisabled: bgDisabled ?? this.bgDisabled,
    bgElevated: bgElevated ?? this.bgElevated,
    bgHover: bgHover ?? this.bgHover,
    bgPrimary: bgPrimary ?? this.bgPrimary,
    bgSecondary: bgSecondary ?? this.bgSecondary,
    bgSelected: bgSelected ?? this.bgSelected,
    bgTertiary: bgTertiary ?? this.bgTertiary,
    borderHover: borderHover ?? this.borderHover,
    borderPrimary: borderPrimary ?? this.borderPrimary,
    borderSecondary: borderSecondary ?? this.borderSecondary,
    borderSelected: borderSelected ?? this.borderSelected,
    messageIncomingBackground: messageIncomingBackground ?? this.messageIncomingBackground,
    messageIncomingForeground: messageIncomingForeground ?? this.messageIncomingForeground,
    messageIncomingBorder: messageIncomingBorder ?? this.messageIncomingBorder,
    messageOutgoingBackground: messageOutgoingBackground ?? this.messageOutgoingBackground,
    messageOutgoingForeground: messageOutgoingForeground ?? this.messageOutgoingForeground,
    messageOutgoingBorder: messageOutgoingBorder ?? this.messageOutgoingBorder,
    messageSelectedBackground: messageSelectedBackground ?? this.messageSelectedBackground,
    messageSelectedBorder: messageSelectedBorder ?? this.messageSelectedBorder,
    messageFailedBackground: messageFailedBackground ?? this.messageFailedBackground,
    messageFailedForeground: messageFailedForeground ?? this.messageFailedForeground,
    messageFailedBorder: messageFailedBorder ?? this.messageFailedBorder,
    messageMetaForeground: messageMetaForeground ?? this.messageMetaForeground,
    messageStatusPending: messageStatusPending ?? this.messageStatusPending,
    messageStatusSent: messageStatusSent ?? this.messageStatusSent,
    messageStatusDelivered: messageStatusDelivered ?? this.messageStatusDelivered,
    messageStatusRead: messageStatusRead ?? this.messageStatusRead,
    messageStatusFailed: messageStatusFailed ?? this.messageStatusFailed,
    messageStatusOnOutgoing: messageStatusOnOutgoing ?? this.messageStatusOnOutgoing,
    messageStatusReadOnOutgoing: messageStatusReadOnOutgoing ?? this.messageStatusReadOnOutgoing,
    messageReplyBackground: messageReplyBackground ?? this.messageReplyBackground,
    messageReplyBorder: messageReplyBorder ?? this.messageReplyBorder,
    messageReactionBackground: messageReactionBackground ?? this.messageReactionBackground,
    messageReactionSelected: messageReactionSelected ?? this.messageReactionSelected,
    error: error ?? this.error,
    errorText: errorText ?? this.errorText,
    focusRing: focusRing ?? this.focusRing,
    important: important ?? this.important,
    info: info ?? this.info,
    infoText: infoText ?? this.infoText,
    pinned: pinned ?? this.pinned,
    primary: primary ?? this.primary,
    primaryActive: primaryActive ?? this.primaryActive,
    primaryHover: primaryHover ?? this.primaryHover,
    primaryText: primaryText ?? this.primaryText,
    robot: robot ?? this.robot,
    success: success ?? this.success,
    successText: successText ?? this.successText,
    textDisabled: textDisabled ?? this.textDisabled,
    textLink: textLink ?? this.textLink,
    textLinkHover: textLinkHover ?? this.textLinkHover,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    warning: warning ?? this.warning,
    warningText: warningText ?? this.warningText,
    avatarTintBlueBg: avatarTintBlueBg ?? this.avatarTintBlueBg,
    avatarTintBlueFg: avatarTintBlueFg ?? this.avatarTintBlueFg,
    avatarTintPurpleBg: avatarTintPurpleBg ?? this.avatarTintPurpleBg,
    avatarTintPurpleFg: avatarTintPurpleFg ?? this.avatarTintPurpleFg,
    avatarTintPinkBg: avatarTintPinkBg ?? this.avatarTintPinkBg,
    avatarTintPinkFg: avatarTintPinkFg ?? this.avatarTintPinkFg,
    avatarTintGreenBg: avatarTintGreenBg ?? this.avatarTintGreenBg,
    avatarTintGreenFg: avatarTintGreenFg ?? this.avatarTintGreenFg,
    avatarTintAmberBg: avatarTintAmberBg ?? this.avatarTintAmberBg,
    avatarTintAmberFg: avatarTintAmberFg ?? this.avatarTintAmberFg,
    avatarTintSlateBg: avatarTintSlateBg ?? this.avatarTintSlateBg,
    avatarTintSlateFg: avatarTintSlateFg ?? this.avatarTintSlateFg,
  );

  static const FlareColors violetLight = FlareColors(
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
    messageIncomingBackground: Color(0xFFF1F2F5),
    messageIncomingForeground: Color(0xFF20232D),
    messageIncomingBorder: Color(0xFFE3E5EB),
    messageOutgoingBackground: Color(0xFF6D28D9),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF5B21B6),
    messageSelectedBackground: Color(0xFFF0ECFC),
    messageSelectedBorder: Color(0xFF7C3AED),
    messageFailedBackground: Color(0xFFFEF2F2),
    messageFailedForeground: Color(0xFFB91C1C),
    messageFailedBorder: Color(0xFFFCA5A5),
    messageMetaForeground: Color(0xFF5C6371),
    messageStatusPending: Color(0xFF5F6776),
    messageStatusSent: Color(0xFF5F6776),
    messageStatusDelivered: Color(0xFF5C6371),
    messageStatusRead: Color(0xFF6D28D9),
    messageStatusFailed: Color(0xFFDC2626),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFEDE9FE),
    messageReplyBackground: Color(0xFFF7F8FA),
    messageReplyBorder: Color(0xFF8B5CF6),
    messageReactionBackground: Color(0xFFF1F2F5),
    messageReactionSelected: Color(0xFFEDE9FE),
    error: Color(0xFFC62828),
    errorText: Color(0xFFC62828),
    focusRing: Color(0x576D28D9),
    important: Color(0xFFB45309),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFF4F46E5),
    pinned: Color(0xFF6D28D9),
    primary: Color(0xFF6D28D9),
    primaryActive: Color(0xFF4C1D95),
    primaryHover: Color(0xFF5B21B6),
    primaryText: Color(0xFF6D28D9),
    robot: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    successText: Color(0xFF15803D),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFF6D28D9),
    textLinkHover: Color(0xFF5B21B6),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF5C6371),
    textTertiary: Color(0xFF5F6776),
    warning: Color(0xFFB45309),
    warningText: Color(0xFFB45309),
    avatarTintBlueBg: Color(0xFFDBEAFE),
    avatarTintBlueFg: Color(0xFF1D4ED8),
    avatarTintPurpleBg: Color(0xFFE9D5FF),
    avatarTintPurpleFg: Color(0xFF6D28D9),
    avatarTintPinkBg: Color(0xFFFBCFE8),
    avatarTintPinkFg: Color(0xFF9D174D),
    avatarTintGreenBg: Color(0xFFD1FAE5),
    avatarTintGreenFg: Color(0xFF047857),
    avatarTintAmberBg: Color(0xFFFEF3C7),
    avatarTintAmberFg: Color(0xFFB45309),
    avatarTintSlateBg: Color(0xFFE5E7EB),
    avatarTintSlateFg: Color(0xFF374151),
  );

  static const FlareColors violetDark = FlareColors(
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0xFF2D2340),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFFA78BFA),
    messageIncomingBackground: Color(0xFF292D37),
    messageIncomingForeground: Color(0xF0FFFFFF),
    messageIncomingBorder: Color(0x1AFFFFFF),
    messageOutgoingBackground: Color(0xFF5B21B6),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF8B5CF6),
    messageSelectedBackground: Color(0xFF2D2340),
    messageSelectedBorder: Color(0xFFA78BFA),
    messageFailedBackground: Color(0xFF3F1D24),
    messageFailedForeground: Color(0xFFFCA5A5),
    messageFailedBorder: Color(0xFF991B1B),
    messageMetaForeground: Color(0xFF9AA3B3),
    messageStatusPending: Color(0xFF9AA3B3),
    messageStatusSent: Color(0xFF9AA3B3),
    messageStatusDelivered: Color(0x9EFFFFFF),
    messageStatusRead: Color(0xFFC4B5FD),
    messageStatusFailed: Color(0xFFF87171),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFEDE9FE),
    messageReplyBackground: Color(0x12FFFFFF),
    messageReplyBorder: Color(0xFFA78BFA),
    messageReactionBackground: Color(0x14FFFFFF),
    messageReactionSelected: Color(0x4D8B5CF6),
    error: Color(0xFFDC2626),
    errorText: Color(0xFFF87171),
    focusRing: Color(0x6BC4B5FD),
    important: Color(0xFFD97706),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFFA5B4FC),
    pinned: Color(0xFFC4B5FD),
    primary: Color(0xFF6D28D9),
    primaryActive: Color(0xFF5B21B6),
    primaryHover: Color(0xFF7C3AED),
    primaryText: Color(0xFFC4B5FD),
    robot: Color(0xFF94A3B8),
    success: Color(0xFF16A34A),
    successText: Color(0xFF4ADE80),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFFC4B5FD),
    textLinkHover: Color(0xFFDDD6FE),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFA16207),
    warningText: Color(0xFFFBBF24),
    avatarTintBlueBg: Color(0xFF1F3266),
    avatarTintBlueFg: Color(0xFFBFDBFE),
    avatarTintPurpleBg: Color(0xFF3A2566),
    avatarTintPurpleFg: Color(0xFFDDD6FE),
    avatarTintPinkBg: Color(0xFF5C1F3E),
    avatarTintPinkFg: Color(0xFFFBCFE8),
    avatarTintGreenBg: Color(0xFF15433C),
    avatarTintGreenFg: Color(0xFFA7F3D0),
    avatarTintAmberBg: Color(0xFF58351E),
    avatarTintAmberFg: Color(0xFFFDE68A),
    avatarTintSlateBg: Color(0xFF282D38),
    avatarTintSlateFg: Color(0xFFE5E7EB),
  );

  static const FlareColors oceanLight = FlareColors(
    bgDisabled: Color(0xFFF1F2F5),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1F2F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7F8FA),
    bgSelected: Color(0xFFEFF6FF),
    bgTertiary: Color(0xFFF1F2F5),
    borderHover: Color(0xFFC9CDD7),
    borderPrimary: Color(0xFFE3E5EB),
    borderSecondary: Color(0xFFECEEF2),
    borderSelected: Color(0xFF2563EB),
    messageIncomingBackground: Color(0xFFF1F2F5),
    messageIncomingForeground: Color(0xFF20232D),
    messageIncomingBorder: Color(0xFFE3E5EB),
    messageOutgoingBackground: Color(0xFF1D4ED8),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF1E40AF),
    messageSelectedBackground: Color(0xFFEFF6FF),
    messageSelectedBorder: Color(0xFF2563EB),
    messageFailedBackground: Color(0xFFFEF2F2),
    messageFailedForeground: Color(0xFFB91C1C),
    messageFailedBorder: Color(0xFFFCA5A5),
    messageMetaForeground: Color(0xFF5C6371),
    messageStatusPending: Color(0xFF5F6776),
    messageStatusSent: Color(0xFF5F6776),
    messageStatusDelivered: Color(0xFF5C6371),
    messageStatusRead: Color(0xFF1D4ED8),
    messageStatusFailed: Color(0xFFDC2626),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFDBEAFE),
    messageReplyBackground: Color(0xFFF7F8FA),
    messageReplyBorder: Color(0xFF3B82F6),
    messageReactionBackground: Color(0xFFF1F2F5),
    messageReactionSelected: Color(0xFFDBEAFE),
    error: Color(0xFFC62828),
    errorText: Color(0xFFC62828),
    focusRing: Color(0x572563EB),
    important: Color(0xFFB45309),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFF4F46E5),
    pinned: Color(0xFF1D4ED8),
    primary: Color(0xFF1D4ED8),
    primaryActive: Color(0xFF1E3A8A),
    primaryHover: Color(0xFF1E40AF),
    primaryText: Color(0xFF1D4ED8),
    robot: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    successText: Color(0xFF15803D),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFF1D4ED8),
    textLinkHover: Color(0xFF1E40AF),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF5C6371),
    textTertiary: Color(0xFF5F6776),
    warning: Color(0xFFB45309),
    warningText: Color(0xFFB45309),
    avatarTintBlueBg: Color(0xFFDBEAFE),
    avatarTintBlueFg: Color(0xFF1D4ED8),
    avatarTintPurpleBg: Color(0xFFE9D5FF),
    avatarTintPurpleFg: Color(0xFF6D28D9),
    avatarTintPinkBg: Color(0xFFFBCFE8),
    avatarTintPinkFg: Color(0xFF9D174D),
    avatarTintGreenBg: Color(0xFFD1FAE5),
    avatarTintGreenFg: Color(0xFF047857),
    avatarTintAmberBg: Color(0xFFFEF3C7),
    avatarTintAmberFg: Color(0xFFB45309),
    avatarTintSlateBg: Color(0xFFE5E7EB),
    avatarTintSlateFg: Color(0xFF374151),
  );

  static const FlareColors oceanDark = FlareColors(
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0xFF172A46),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFF60A5FA),
    messageIncomingBackground: Color(0xFF292D37),
    messageIncomingForeground: Color(0xF0FFFFFF),
    messageIncomingBorder: Color(0x1AFFFFFF),
    messageOutgoingBackground: Color(0xFF1E40AF),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF3B82F6),
    messageSelectedBackground: Color(0xFF172A46),
    messageSelectedBorder: Color(0xFF60A5FA),
    messageFailedBackground: Color(0xFF3F1D24),
    messageFailedForeground: Color(0xFFFCA5A5),
    messageFailedBorder: Color(0xFF991B1B),
    messageMetaForeground: Color(0xFF9AA3B3),
    messageStatusPending: Color(0xFF9AA3B3),
    messageStatusSent: Color(0xFF9AA3B3),
    messageStatusDelivered: Color(0x9EFFFFFF),
    messageStatusRead: Color(0xFF93C5FD),
    messageStatusFailed: Color(0xFFF87171),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFDBEAFE),
    messageReplyBackground: Color(0x12FFFFFF),
    messageReplyBorder: Color(0xFF60A5FA),
    messageReactionBackground: Color(0x14FFFFFF),
    messageReactionSelected: Color(0x4D3B82F6),
    error: Color(0xFFDC2626),
    errorText: Color(0xFFF87171),
    focusRing: Color(0x6B93C5FD),
    important: Color(0xFFD97706),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFFA5B4FC),
    pinned: Color(0xFF93C5FD),
    primary: Color(0xFF1E40AF),
    primaryActive: Color(0xFF1E3A8A),
    primaryHover: Color(0xFF1D4ED8),
    primaryText: Color(0xFF93C5FD),
    robot: Color(0xFF94A3B8),
    success: Color(0xFF16A34A),
    successText: Color(0xFF4ADE80),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFF93C5FD),
    textLinkHover: Color(0xFFBFDBFE),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFA16207),
    warningText: Color(0xFFFBBF24),
    avatarTintBlueBg: Color(0xFF1F3266),
    avatarTintBlueFg: Color(0xFFBFDBFE),
    avatarTintPurpleBg: Color(0xFF3A2566),
    avatarTintPurpleFg: Color(0xFFDDD6FE),
    avatarTintPinkBg: Color(0xFF5C1F3E),
    avatarTintPinkFg: Color(0xFFFBCFE8),
    avatarTintGreenBg: Color(0xFF15433C),
    avatarTintGreenFg: Color(0xFFA7F3D0),
    avatarTintAmberBg: Color(0xFF58351E),
    avatarTintAmberFg: Color(0xFFFDE68A),
    avatarTintSlateBg: Color(0xFF282D38),
    avatarTintSlateFg: Color(0xFFE5E7EB),
  );

  static const FlareColors forestLight = FlareColors(
    bgDisabled: Color(0xFFF1F2F5),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1F2F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7F8FA),
    bgSelected: Color(0xFFF0FDF4),
    bgTertiary: Color(0xFFF1F2F5),
    borderHover: Color(0xFFC9CDD7),
    borderPrimary: Color(0xFFE3E5EB),
    borderSecondary: Color(0xFFECEEF2),
    borderSelected: Color(0xFF16A34A),
    messageIncomingBackground: Color(0xFFF1F2F5),
    messageIncomingForeground: Color(0xFF20232D),
    messageIncomingBorder: Color(0xFFE3E5EB),
    messageOutgoingBackground: Color(0xFF15803D),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF166534),
    messageSelectedBackground: Color(0xFFF0FDF4),
    messageSelectedBorder: Color(0xFF16A34A),
    messageFailedBackground: Color(0xFFFEF2F2),
    messageFailedForeground: Color(0xFFB91C1C),
    messageFailedBorder: Color(0xFFFCA5A5),
    messageMetaForeground: Color(0xFF5C6371),
    messageStatusPending: Color(0xFF5F6776),
    messageStatusSent: Color(0xFF5F6776),
    messageStatusDelivered: Color(0xFF5C6371),
    messageStatusRead: Color(0xFF15803D),
    messageStatusFailed: Color(0xFFDC2626),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFDCFCE7),
    messageReplyBackground: Color(0xFFF7F8FA),
    messageReplyBorder: Color(0xFF22C55E),
    messageReactionBackground: Color(0xFFF1F2F5),
    messageReactionSelected: Color(0xFFDCFCE7),
    error: Color(0xFFC62828),
    errorText: Color(0xFFC62828),
    focusRing: Color(0x5716A34A),
    important: Color(0xFFB45309),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFF4F46E5),
    pinned: Color(0xFF15803D),
    primary: Color(0xFF15803D),
    primaryActive: Color(0xFF14532D),
    primaryHover: Color(0xFF166534),
    primaryText: Color(0xFF15803D),
    robot: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    successText: Color(0xFF15803D),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFF15803D),
    textLinkHover: Color(0xFF166534),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF5C6371),
    textTertiary: Color(0xFF5F6776),
    warning: Color(0xFFB45309),
    warningText: Color(0xFFB45309),
    avatarTintBlueBg: Color(0xFFDBEAFE),
    avatarTintBlueFg: Color(0xFF1D4ED8),
    avatarTintPurpleBg: Color(0xFFE9D5FF),
    avatarTintPurpleFg: Color(0xFF6D28D9),
    avatarTintPinkBg: Color(0xFFFBCFE8),
    avatarTintPinkFg: Color(0xFF9D174D),
    avatarTintGreenBg: Color(0xFFD1FAE5),
    avatarTintGreenFg: Color(0xFF047857),
    avatarTintAmberBg: Color(0xFFFEF3C7),
    avatarTintAmberFg: Color(0xFFB45309),
    avatarTintSlateBg: Color(0xFFE5E7EB),
    avatarTintSlateFg: Color(0xFF374151),
  );

  static const FlareColors forestDark = FlareColors(
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0xFF183528),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFF4ADE80),
    messageIncomingBackground: Color(0xFF292D37),
    messageIncomingForeground: Color(0xF0FFFFFF),
    messageIncomingBorder: Color(0x1AFFFFFF),
    messageOutgoingBackground: Color(0xFF166534),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF22C55E),
    messageSelectedBackground: Color(0xFF183528),
    messageSelectedBorder: Color(0xFF4ADE80),
    messageFailedBackground: Color(0xFF3F1D24),
    messageFailedForeground: Color(0xFFFCA5A5),
    messageFailedBorder: Color(0xFF991B1B),
    messageMetaForeground: Color(0xFF9AA3B3),
    messageStatusPending: Color(0xFF9AA3B3),
    messageStatusSent: Color(0xFF9AA3B3),
    messageStatusDelivered: Color(0x9EFFFFFF),
    messageStatusRead: Color(0xFF86EFAC),
    messageStatusFailed: Color(0xFFF87171),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFDCFCE7),
    messageReplyBackground: Color(0x12FFFFFF),
    messageReplyBorder: Color(0xFF4ADE80),
    messageReactionBackground: Color(0x14FFFFFF),
    messageReactionSelected: Color(0x4722C55E),
    error: Color(0xFFDC2626),
    errorText: Color(0xFFF87171),
    focusRing: Color(0x6686EFAC),
    important: Color(0xFFD97706),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFFA5B4FC),
    pinned: Color(0xFF86EFAC),
    primary: Color(0xFF166534),
    primaryActive: Color(0xFF14532D),
    primaryHover: Color(0xFF15803D),
    primaryText: Color(0xFF86EFAC),
    robot: Color(0xFF94A3B8),
    success: Color(0xFF16A34A),
    successText: Color(0xFF4ADE80),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFF86EFAC),
    textLinkHover: Color(0xFFBBF7D0),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFA16207),
    warningText: Color(0xFFFBBF24),
    avatarTintBlueBg: Color(0xFF1F3266),
    avatarTintBlueFg: Color(0xFFBFDBFE),
    avatarTintPurpleBg: Color(0xFF3A2566),
    avatarTintPurpleFg: Color(0xFFDDD6FE),
    avatarTintPinkBg: Color(0xFF5C1F3E),
    avatarTintPinkFg: Color(0xFFFBCFE8),
    avatarTintGreenBg: Color(0xFF15433C),
    avatarTintGreenFg: Color(0xFFA7F3D0),
    avatarTintAmberBg: Color(0xFF58351E),
    avatarTintAmberFg: Color(0xFFFDE68A),
    avatarTintSlateBg: Color(0xFF282D38),
    avatarTintSlateFg: Color(0xFFE5E7EB),
  );

  static const FlareColors sunsetLight = FlareColors(
    bgDisabled: Color(0xFFF1F2F5),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1F2F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7F8FA),
    bgSelected: Color(0xFFFFF7ED),
    bgTertiary: Color(0xFFF1F2F5),
    borderHover: Color(0xFFC9CDD7),
    borderPrimary: Color(0xFFE3E5EB),
    borderSecondary: Color(0xFFECEEF2),
    borderSelected: Color(0xFFEA580C),
    messageIncomingBackground: Color(0xFFF1F2F5),
    messageIncomingForeground: Color(0xFF20232D),
    messageIncomingBorder: Color(0xFFE3E5EB),
    messageOutgoingBackground: Color(0xFFC2410C),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF9A3412),
    messageSelectedBackground: Color(0xFFFFF7ED),
    messageSelectedBorder: Color(0xFFEA580C),
    messageFailedBackground: Color(0xFFFEF2F2),
    messageFailedForeground: Color(0xFFB91C1C),
    messageFailedBorder: Color(0xFFFCA5A5),
    messageMetaForeground: Color(0xFF5C6371),
    messageStatusPending: Color(0xFF5F6776),
    messageStatusSent: Color(0xFF5F6776),
    messageStatusDelivered: Color(0xFF5C6371),
    messageStatusRead: Color(0xFFC2410C),
    messageStatusFailed: Color(0xFFDC2626),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFFFEDD5),
    messageReplyBackground: Color(0xFFF7F8FA),
    messageReplyBorder: Color(0xFFF97316),
    messageReactionBackground: Color(0xFFF1F2F5),
    messageReactionSelected: Color(0xFFFFEDD5),
    error: Color(0xFFC62828),
    errorText: Color(0xFFC62828),
    focusRing: Color(0x57EA580C),
    important: Color(0xFFB45309),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFF4F46E5),
    pinned: Color(0xFFC2410C),
    primary: Color(0xFFC2410C),
    primaryActive: Color(0xFF7C2D12),
    primaryHover: Color(0xFF9A3412),
    primaryText: Color(0xFFC2410C),
    robot: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    successText: Color(0xFF15803D),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFFC2410C),
    textLinkHover: Color(0xFF9A3412),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF5C6371),
    textTertiary: Color(0xFF5F6776),
    warning: Color(0xFFB45309),
    warningText: Color(0xFFB45309),
    avatarTintBlueBg: Color(0xFFDBEAFE),
    avatarTintBlueFg: Color(0xFF1D4ED8),
    avatarTintPurpleBg: Color(0xFFE9D5FF),
    avatarTintPurpleFg: Color(0xFF6D28D9),
    avatarTintPinkBg: Color(0xFFFBCFE8),
    avatarTintPinkFg: Color(0xFF9D174D),
    avatarTintGreenBg: Color(0xFFD1FAE5),
    avatarTintGreenFg: Color(0xFF047857),
    avatarTintAmberBg: Color(0xFFFEF3C7),
    avatarTintAmberFg: Color(0xFFB45309),
    avatarTintSlateBg: Color(0xFFE5E7EB),
    avatarTintSlateFg: Color(0xFF374151),
  );

  static const FlareColors sunsetDark = FlareColors(
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0xFF3B2619),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFFFB923C),
    messageIncomingBackground: Color(0xFF292D37),
    messageIncomingForeground: Color(0xF0FFFFFF),
    messageIncomingBorder: Color(0x1AFFFFFF),
    messageOutgoingBackground: Color(0xFF9A3412),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFFEA580C),
    messageSelectedBackground: Color(0xFF3B2619),
    messageSelectedBorder: Color(0xFFFB923C),
    messageFailedBackground: Color(0xFF3F1D24),
    messageFailedForeground: Color(0xFFFCA5A5),
    messageFailedBorder: Color(0xFF991B1B),
    messageMetaForeground: Color(0xFF9AA3B3),
    messageStatusPending: Color(0xFF9AA3B3),
    messageStatusSent: Color(0xFF9AA3B3),
    messageStatusDelivered: Color(0x9EFFFFFF),
    messageStatusRead: Color(0xFFFDBA74),
    messageStatusFailed: Color(0xFFF87171),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFFFEDD5),
    messageReplyBackground: Color(0x12FFFFFF),
    messageReplyBorder: Color(0xFFFB923C),
    messageReactionBackground: Color(0x14FFFFFF),
    messageReactionSelected: Color(0x47F97316),
    error: Color(0xFFDC2626),
    errorText: Color(0xFFF87171),
    focusRing: Color(0x66FDBA74),
    important: Color(0xFFD97706),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFFA5B4FC),
    pinned: Color(0xFFFDBA74),
    primary: Color(0xFF9A3412),
    primaryActive: Color(0xFF7C2D12),
    primaryHover: Color(0xFFC2410C),
    primaryText: Color(0xFFFDBA74),
    robot: Color(0xFF94A3B8),
    success: Color(0xFF16A34A),
    successText: Color(0xFF4ADE80),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFFFDBA74),
    textLinkHover: Color(0xFFFED7AA),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFA16207),
    warningText: Color(0xFFFBBF24),
    avatarTintBlueBg: Color(0xFF1F3266),
    avatarTintBlueFg: Color(0xFFBFDBFE),
    avatarTintPurpleBg: Color(0xFF3A2566),
    avatarTintPurpleFg: Color(0xFFDDD6FE),
    avatarTintPinkBg: Color(0xFF5C1F3E),
    avatarTintPinkFg: Color(0xFFFBCFE8),
    avatarTintGreenBg: Color(0xFF15433C),
    avatarTintGreenFg: Color(0xFFA7F3D0),
    avatarTintAmberBg: Color(0xFF58351E),
    avatarTintAmberFg: Color(0xFFFDE68A),
    avatarTintSlateBg: Color(0xFF282D38),
    avatarTintSlateFg: Color(0xFFE5E7EB),
  );

  static const FlareColors roseLight = FlareColors(
    bgDisabled: Color(0xFFF1F2F5),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1F2F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7F8FA),
    bgSelected: Color(0xFFFFF1F2),
    bgTertiary: Color(0xFFF1F2F5),
    borderHover: Color(0xFFC9CDD7),
    borderPrimary: Color(0xFFE3E5EB),
    borderSecondary: Color(0xFFECEEF2),
    borderSelected: Color(0xFFE11D48),
    messageIncomingBackground: Color(0xFFF1F2F5),
    messageIncomingForeground: Color(0xFF20232D),
    messageIncomingBorder: Color(0xFFE3E5EB),
    messageOutgoingBackground: Color(0xFFBE123C),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF9F1239),
    messageSelectedBackground: Color(0xFFFFF1F2),
    messageSelectedBorder: Color(0xFFE11D48),
    messageFailedBackground: Color(0xFFFEF2F2),
    messageFailedForeground: Color(0xFFB91C1C),
    messageFailedBorder: Color(0xFFFCA5A5),
    messageMetaForeground: Color(0xFF5C6371),
    messageStatusPending: Color(0xFF5F6776),
    messageStatusSent: Color(0xFF5F6776),
    messageStatusDelivered: Color(0xFF5C6371),
    messageStatusRead: Color(0xFFBE123C),
    messageStatusFailed: Color(0xFFDC2626),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFFFE4E6),
    messageReplyBackground: Color(0xFFF7F8FA),
    messageReplyBorder: Color(0xFFF43F5E),
    messageReactionBackground: Color(0xFFF1F2F5),
    messageReactionSelected: Color(0xFFFFE4E6),
    error: Color(0xFFC62828),
    errorText: Color(0xFFC62828),
    focusRing: Color(0x52E11D48),
    important: Color(0xFFB45309),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFF4F46E5),
    pinned: Color(0xFFBE123C),
    primary: Color(0xFFBE123C),
    primaryActive: Color(0xFF881337),
    primaryHover: Color(0xFF9F1239),
    primaryText: Color(0xFFBE123C),
    robot: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    successText: Color(0xFF15803D),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFFBE123C),
    textLinkHover: Color(0xFF9F1239),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF5C6371),
    textTertiary: Color(0xFF5F6776),
    warning: Color(0xFFB45309),
    warningText: Color(0xFFB45309),
    avatarTintBlueBg: Color(0xFFDBEAFE),
    avatarTintBlueFg: Color(0xFF1D4ED8),
    avatarTintPurpleBg: Color(0xFFE9D5FF),
    avatarTintPurpleFg: Color(0xFF6D28D9),
    avatarTintPinkBg: Color(0xFFFBCFE8),
    avatarTintPinkFg: Color(0xFF9D174D),
    avatarTintGreenBg: Color(0xFFD1FAE5),
    avatarTintGreenFg: Color(0xFF047857),
    avatarTintAmberBg: Color(0xFFFEF3C7),
    avatarTintAmberFg: Color(0xFFB45309),
    avatarTintSlateBg: Color(0xFFE5E7EB),
    avatarTintSlateFg: Color(0xFF374151),
  );

  static const FlareColors roseDark = FlareColors(
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0xFF3B2028),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFFFB7185),
    messageIncomingBackground: Color(0xFF292D37),
    messageIncomingForeground: Color(0xF0FFFFFF),
    messageIncomingBorder: Color(0x1AFFFFFF),
    messageOutgoingBackground: Color(0xFF9F1239),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFFE11D48),
    messageSelectedBackground: Color(0xFF3B2028),
    messageSelectedBorder: Color(0xFFFB7185),
    messageFailedBackground: Color(0xFF3F1D24),
    messageFailedForeground: Color(0xFFFCA5A5),
    messageFailedBorder: Color(0xFF991B1B),
    messageMetaForeground: Color(0xFF9AA3B3),
    messageStatusPending: Color(0xFF9AA3B3),
    messageStatusSent: Color(0xFF9AA3B3),
    messageStatusDelivered: Color(0x9EFFFFFF),
    messageStatusRead: Color(0xFFFDA4AF),
    messageStatusFailed: Color(0xFFF87171),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFFFE4E6),
    messageReplyBackground: Color(0x12FFFFFF),
    messageReplyBorder: Color(0xFFFB7185),
    messageReactionBackground: Color(0x14FFFFFF),
    messageReactionSelected: Color(0x47F43F5E),
    error: Color(0xFFDC2626),
    errorText: Color(0xFFF87171),
    focusRing: Color(0x66FDA4AF),
    important: Color(0xFFD97706),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFFA5B4FC),
    pinned: Color(0xFFFDA4AF),
    primary: Color(0xFF9F1239),
    primaryActive: Color(0xFF881337),
    primaryHover: Color(0xFFBE123C),
    primaryText: Color(0xFFFDA4AF),
    robot: Color(0xFF94A3B8),
    success: Color(0xFF16A34A),
    successText: Color(0xFF4ADE80),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFFFDA4AF),
    textLinkHover: Color(0xFFFECDD3),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFA16207),
    warningText: Color(0xFFFBBF24),
    avatarTintBlueBg: Color(0xFF1F3266),
    avatarTintBlueFg: Color(0xFFBFDBFE),
    avatarTintPurpleBg: Color(0xFF3A2566),
    avatarTintPurpleFg: Color(0xFFDDD6FE),
    avatarTintPinkBg: Color(0xFF5C1F3E),
    avatarTintPinkFg: Color(0xFFFBCFE8),
    avatarTintGreenBg: Color(0xFF15433C),
    avatarTintGreenFg: Color(0xFFA7F3D0),
    avatarTintAmberBg: Color(0xFF58351E),
    avatarTintAmberFg: Color(0xFFFDE68A),
    avatarTintSlateBg: Color(0xFF282D38),
    avatarTintSlateFg: Color(0xFFE5E7EB),
  );

  static const FlareColors graphiteLight = FlareColors(
    bgDisabled: Color(0xFFF1F2F5),
    bgElevated: Color(0xFFFFFFFF),
    bgHover: Color(0xFFF1F2F5),
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF7F8FA),
    bgSelected: Color(0xFFF1F5F9),
    bgTertiary: Color(0xFFF1F2F5),
    borderHover: Color(0xFFC9CDD7),
    borderPrimary: Color(0xFFE3E5EB),
    borderSecondary: Color(0xFFECEEF2),
    borderSelected: Color(0xFF64748B),
    messageIncomingBackground: Color(0xFFF1F2F5),
    messageIncomingForeground: Color(0xFF20232D),
    messageIncomingBorder: Color(0xFFE3E5EB),
    messageOutgoingBackground: Color(0xFF475569),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF334155),
    messageSelectedBackground: Color(0xFFF1F5F9),
    messageSelectedBorder: Color(0xFF64748B),
    messageFailedBackground: Color(0xFFFEF2F2),
    messageFailedForeground: Color(0xFFB91C1C),
    messageFailedBorder: Color(0xFFFCA5A5),
    messageMetaForeground: Color(0xFF5C6371),
    messageStatusPending: Color(0xFF5F6776),
    messageStatusSent: Color(0xFF5F6776),
    messageStatusDelivered: Color(0xFF5C6371),
    messageStatusRead: Color(0xFF475569),
    messageStatusFailed: Color(0xFFDC2626),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFE2E8F0),
    messageReplyBackground: Color(0xFFF7F8FA),
    messageReplyBorder: Color(0xFF64748B),
    messageReactionBackground: Color(0xFFF1F2F5),
    messageReactionSelected: Color(0xFFE2E8F0),
    error: Color(0xFFC62828),
    errorText: Color(0xFFC62828),
    focusRing: Color(0x57475569),
    important: Color(0xFFB45309),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFF4F46E5),
    pinned: Color(0xFF475569),
    primary: Color(0xFF475569),
    primaryActive: Color(0xFF1E293B),
    primaryHover: Color(0xFF334155),
    primaryText: Color(0xFF475569),
    robot: Color(0xFF64748B),
    success: Color(0xFF16A34A),
    successText: Color(0xFF15803D),
    textDisabled: Color(0xFFB7BDC8),
    textLink: Color(0xFF475569),
    textLinkHover: Color(0xFF334155),
    textPrimary: Color(0xFF20232D),
    textSecondary: Color(0xFF5C6371),
    textTertiary: Color(0xFF5F6776),
    warning: Color(0xFFB45309),
    warningText: Color(0xFFB45309),
    avatarTintBlueBg: Color(0xFFDBEAFE),
    avatarTintBlueFg: Color(0xFF1D4ED8),
    avatarTintPurpleBg: Color(0xFFE9D5FF),
    avatarTintPurpleFg: Color(0xFF6D28D9),
    avatarTintPinkBg: Color(0xFFFBCFE8),
    avatarTintPinkFg: Color(0xFF9D174D),
    avatarTintGreenBg: Color(0xFFD1FAE5),
    avatarTintGreenFg: Color(0xFF047857),
    avatarTintAmberBg: Color(0xFFFEF3C7),
    avatarTintAmberFg: Color(0xFFB45309),
    avatarTintSlateBg: Color(0xFFE5E7EB),
    avatarTintSlateFg: Color(0xFF374151),
  );

  static const FlareColors graphiteDark = FlareColors(
    bgDisabled: Color(0xFF292D37),
    bgElevated: Color(0xFF292D37),
    bgHover: Color(0x0FFFFFFF),
    bgPrimary: Color(0xFF20232B),
    bgSecondary: Color(0xFF17191F),
    bgSelected: Color(0xFF2B3440),
    bgTertiary: Color(0xFF292D37),
    borderHover: Color(0x29FFFFFF),
    borderPrimary: Color(0x1AFFFFFF),
    borderSecondary: Color(0x14FFFFFF),
    borderSelected: Color(0xFF94A3B8),
    messageIncomingBackground: Color(0xFF292D37),
    messageIncomingForeground: Color(0xF0FFFFFF),
    messageIncomingBorder: Color(0x1AFFFFFF),
    messageOutgoingBackground: Color(0xFF475569),
    messageOutgoingForeground: Color(0xFFFFFFFF),
    messageOutgoingBorder: Color(0xFF64748B),
    messageSelectedBackground: Color(0xFF2B3440),
    messageSelectedBorder: Color(0xFF94A3B8),
    messageFailedBackground: Color(0xFF3F1D24),
    messageFailedForeground: Color(0xFFFCA5A5),
    messageFailedBorder: Color(0xFF991B1B),
    messageMetaForeground: Color(0xFF9AA3B3),
    messageStatusPending: Color(0xFF9AA3B3),
    messageStatusSent: Color(0xFF9AA3B3),
    messageStatusDelivered: Color(0x9EFFFFFF),
    messageStatusRead: Color(0xFFCBD5E1),
    messageStatusFailed: Color(0xFFF87171),
    messageStatusOnOutgoing: Color(0xCCFFFFFF),
    messageStatusReadOnOutgoing: Color(0xFFE2E8F0),
    messageReplyBackground: Color(0x12FFFFFF),
    messageReplyBorder: Color(0xFF94A3B8),
    messageReactionBackground: Color(0x14FFFFFF),
    messageReactionSelected: Color(0x4794A3B8),
    error: Color(0xFFDC2626),
    errorText: Color(0xFFF87171),
    focusRing: Color(0x61CBD5E1),
    important: Color(0xFFD97706),
    info: Color(0xFF6D5DF6),
    infoText: Color(0xFFA5B4FC),
    pinned: Color(0xFFCBD5E1),
    primary: Color(0xFF475569),
    primaryActive: Color(0xFF334155),
    primaryHover: Color(0xFF64748B),
    primaryText: Color(0xFFCBD5E1),
    robot: Color(0xFF94A3B8),
    success: Color(0xFF16A34A),
    successText: Color(0xFF4ADE80),
    textDisabled: Color(0x47FFFFFF),
    textLink: Color(0xFFCBD5E1),
    textLinkHover: Color(0xFFE2E8F0),
    textPrimary: Color(0xF0FFFFFF),
    textSecondary: Color(0x9EFFFFFF),
    textTertiary: Color(0xFF9AA3B3),
    warning: Color(0xFFA16207),
    warningText: Color(0xFFFBBF24),
    avatarTintBlueBg: Color(0xFF1F3266),
    avatarTintBlueFg: Color(0xFFBFDBFE),
    avatarTintPurpleBg: Color(0xFF3A2566),
    avatarTintPurpleFg: Color(0xFFDDD6FE),
    avatarTintPinkBg: Color(0xFF5C1F3E),
    avatarTintPinkFg: Color(0xFFFBCFE8),
    avatarTintGreenBg: Color(0xFF15433C),
    avatarTintGreenFg: Color(0xFFA7F3D0),
    avatarTintAmberBg: Color(0xFF58351E),
    avatarTintAmberFg: Color(0xFFFDE68A),
    avatarTintSlateBg: Color(0xFF282D38),
    avatarTintSlateFg: Color(0xFFE5E7EB),
  );

  static const FlareColors light = violetLight;
  static const FlareColors dark = violetDark;

  static FlareColors resolve(Brightness brightness, {FlareBrandTheme brand = FlareBrandTheme.violet}) => switch (brand) {
      FlareBrandTheme.violet => brightness == Brightness.dark ? violetDark : violetLight,
      FlareBrandTheme.ocean => brightness == Brightness.dark ? oceanDark : oceanLight,
      FlareBrandTheme.forest => brightness == Brightness.dark ? forestDark : forestLight,
      FlareBrandTheme.sunset => brightness == Brightness.dark ? sunsetDark : sunsetLight,
      FlareBrandTheme.rose => brightness == Brightness.dark ? roseDark : roseLight,
      FlareBrandTheme.graphite => brightness == Brightness.dark ? graphiteDark : graphiteLight,
    };

  static FlareColors of(Object source, {FlareBrandTheme brand = FlareBrandTheme.violet}) {
    if (source is BuildContext) {
      final inherited = FlareTheme.maybeOf(source);
      final dark = flareThemeIsDark(
        inherited?.mode ?? FlareThemeMode.system,
        systemDark: flareSystemDark(source),
      );
      return inherited?.colors ?? resolve(dark ? Brightness.dark : Brightness.light, brand: inherited?.brand ?? brand);
    }
    return resolve(source as Brightness, brand: brand);
  }
}

/// The theme a host asks for: [light] and [dark] are the person overriding the system, [system] follows it.
enum FlareThemeMode { light, dark, system }

/// Whether to draw dark (`spec/theme-mode-vectors.json`, the same rule on four kits).
bool flareThemeIsDark(FlareThemeMode mode, {required bool systemDark}) =>
    mode == FlareThemeMode.system ? systemDark : mode == FlareThemeMode.dark;

/// What the app itself is set to: the enclosing Material theme's brightness, which `MaterialApp` resolves from the
/// platform for `ThemeMode.system` and which a host (or a test) can set directly by wrapping in a `Theme`.
bool flareSystemDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// The kit's theme for this subtree. [mode] is the person's choice, which the host holds and stores.
class FlareTheme extends InheritedWidget {
  const FlareTheme({
    super.key,
    this.brand = FlareBrandTheme.violet,
    this.mode = FlareThemeMode.system,
    this.colors,
    required super.child,
  });
  final FlareBrandTheme brand;
  final FlareThemeMode mode;
  final FlareColors? colors;
  static FlareTheme? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FlareTheme>();
  @override
  bool updateShouldNotify(FlareTheme oldWidget) => brand != oldWidget.brand || mode != oldWidget.mode || colors != oldWidget.colors;
}

/// A named text role: what a title, a section header, body text or a caption is, in one place
/// (FR-051). Sizes are logical px; [weight] is the CSS weight the platform maps to its own.
class FlareTextRole {
  const FlareTextRole({required this.fontSize, required this.lineHeight, required this.weight});
  final double fontSize;
  final double lineHeight;
  final int weight;
}

/// Flare IM text roles.
abstract final class FlareTextRoles {
  static const FlareTextRole title = FlareTextRole(fontSize: 20.0, lineHeight: 1.2, weight: 700);
  static const FlareTextRole section = FlareTextRole(fontSize: 13.0, lineHeight: 1.2, weight: 600);
  static const FlareTextRole body = FlareTextRole(fontSize: 14.0, lineHeight: 1.5, weight: 400);
  static const FlareTextRole caption = FlareTextRole(fontSize: 12.0, lineHeight: 1.5, weight: 400);
  static const FlareTextRole message = FlareTextRole(fontSize: 15.0, lineHeight: 1.45, weight: 400);
}

/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).
abstract final class FlareSizes {
  static const double fontSize2xs = 10.0;
  static const double fontSizeXs = 11.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 13.0;
  static const double fontSizeLg = 14.0;
  static const double fontSizeXl = 15.0;
  static const double fontSize2xl = 16.0;
  static const double fontSize3xl = 18.0;
  static const double fontSize4xl = 20.0;
  static const double fontSize5xl = 24.0;
  static const double iconSizeLg = 24.0;
  static const double iconSizeMd = 20.0;
  static const double iconSizeSm = 16.0;
  static const double iconSizeXl = 32.0;
  static const double avatarSize = 44.0;
  static const double bubbleMaxWidth = 640.0;
  static const double messageTimelineContentMaxWidth = 920.0;
  static const double chatMinWidth = 360.0;
  static const double navigationRailWidth = 72.0;
  static const double navigationRailMinWidth = 600.0;
  static const double workbenchResizeHandleWidth = 8.0;
  static const double primaryPaneMinWidth = 280.0;
  static const double primaryPaneDefaultWidth = 320.0;
  static const double primaryPaneMaxWidth = 420.0;
  static const double detailPaneDefaultWidth = 300.0;
  static const double detailPaneMaxWidth = 420.0;
  static const double appShellCompactMinWidth = 900.0;
  static const double appShellExpandedMinWidth = 1500.0;
  static const double controlHeightLg = 48.0;
  static const double controlHeightMd = 40.0;
  static const double controlHeightSm = 32.0;
  static const double controlPadXLg = 24.0;
  static const double controlPadXMd = 18.0;
  static const double controlPadXSm = 12.0;
  static const double headerHeight = 60.0;
  static const double sessionItemHeight = 72.0;
  static const double touchTarget = 48.0;
  static const double touchTargetMin = 44.0;
  static const double lineHeightNone = 1.0;
  static const double lineHeightTight = 1.2;
  static const double lineHeightSnug = 1.4;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.6;
  static const double radiusXs = 3.0;
  static const double radiusBubbleTail = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 10.0;
  static const double radiusCard = 12.0;
  static const double radiusXl = 14.0;
  static const double radiusBubble = 16.0;
  static const double radius2xl = 18.0;
  static const double radiusFull = 999.0;
  static const double spacing3xs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacing2xs = 6.0;
  static const double spacingSm = 8.0;
  static const double spacing2sm = 10.0;
  static const double spacingMd = 12.0;
  static const double spacing2md = 14.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacing2xl = 24.0;
  static const double componentBubblePaddingX = 14.0;
  static const double componentBubblePaddingY = 9.0;
  static const double componentMessageAvatarSize = 40.0;
  static const double componentComposerActionHeight = 40.0;
  static const double componentComposerActionWidth = 44.0;
  static const double componentComposerToolbarIcon = 34.0;
  static const double componentComposerToolbarWidth = 44.0;
  static const double componentComposerDesktopHeight = 46.0;
  static const double componentBubbleRichMinWidth = 220.0;
  static const double componentBubbleSystemMaxWidth = 560.0;
  static const double componentMessageGutterInline = 16.0;
  static const double componentMessageTailSpace = 10.0;
  static const double componentMediaCardMinWidth = 220.0;
  static const double componentMediaImageMaxWidth = 320.0;
  static const double componentMediaVideoWidth = 320.0;
  static const double componentRichCardWidth = 320.0;
  static const double componentRichCardCompactWidth = 240.0;
  static const double componentRichCardMediaHeight = 148.0;
  static const double componentSheetWidth = 420.0;
  static const double componentSheetDialogWidth = 480.0;
  static const double componentConversationRowMetaWidth = 60.0;
  static const double componentBubbleMaxWidthRatioCompact = 0.88;
  static const double componentBubbleMaxWidthRatioRegular = 0.62;
}

/// Const palette for const widget and ThemeData declarations.
abstract final class FlarePalette {
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
  static const Color lightMessageIncomingBackground = Color(0xFFF1F2F5);
  static const Color darkMessageIncomingBackground = Color(0xFF292D37);
  static const Color lightMessageIncomingForeground = Color(0xFF20232D);
  static const Color darkMessageIncomingForeground = Color(0xF0FFFFFF);
  static const Color lightMessageIncomingBorder = Color(0xFFE3E5EB);
  static const Color darkMessageIncomingBorder = Color(0x1AFFFFFF);
  static const Color lightMessageOutgoingBackground = Color(0xFF6D28D9);
  static const Color darkMessageOutgoingBackground = Color(0xFF6D28D9);
  static const Color lightMessageOutgoingForeground = Color(0xFFFFFFFF);
  static const Color darkMessageOutgoingForeground = Color(0xFFFFFFFF);
  static const Color lightMessageOutgoingBorder = Color(0xFF5B21B6);
  static const Color darkMessageOutgoingBorder = Color(0xFF8B5CF6);
  static const Color lightMessageSelectedBackground = Color(0xFFF0ECFC);
  static const Color darkMessageSelectedBackground = Color(0x337C3AED);
  static const Color lightMessageSelectedBorder = Color(0xFF7C3AED);
  static const Color darkMessageSelectedBorder = Color(0xFFA78BFA);
  static const Color lightMessageFailedBackground = Color(0xFFFEF2F2);
  static const Color darkMessageFailedBackground = Color(0xFF3F1D24);
  static const Color lightMessageFailedForeground = Color(0xFFB91C1C);
  static const Color darkMessageFailedForeground = Color(0xFFFCA5A5);
  static const Color lightMessageFailedBorder = Color(0xFFFCA5A5);
  static const Color darkMessageFailedBorder = Color(0xFF991B1B);
  static const Color lightMessageMetaForeground = Color(0xFF5C6371);
  static const Color darkMessageMetaForeground = Color(0xFF9AA3B3);
  static const Color lightMessageStatusPending = Color(0xFF5F6776);
  static const Color darkMessageStatusPending = Color(0xFF9AA3B3);
  static const Color lightMessageStatusSent = Color(0xFF5F6776);
  static const Color darkMessageStatusSent = Color(0xFF9AA3B3);
  static const Color lightMessageStatusDelivered = Color(0xFF5C6371);
  static const Color darkMessageStatusDelivered = Color(0x9EFFFFFF);
  static const Color lightMessageStatusRead = Color(0xFF6D28D9);
  static const Color darkMessageStatusRead = Color(0xFFC4B5FD);
  static const Color lightMessageStatusFailed = Color(0xFFDC2626);
  static const Color darkMessageStatusFailed = Color(0xFFF87171);
  static const Color lightMessageStatusOnOutgoing = Color(0xCCFFFFFF);
  static const Color darkMessageStatusOnOutgoing = Color(0xCCFFFFFF);
  static const Color lightMessageStatusReadOnOutgoing = Color(0xFFEDE9FE);
  static const Color darkMessageStatusReadOnOutgoing = Color(0xFFEDE9FE);
  static const Color lightMessageReplyBackground = Color(0xFFF7F5FF);
  static const Color darkMessageReplyBackground = Color(0x298B5CF6);
  static const Color lightMessageReplyBorder = Color(0xFF8B5CF6);
  static const Color darkMessageReplyBorder = Color(0xFFA78BFA);
  static const Color lightMessageReactionBackground = Color(0xFFF1F2F5);
  static const Color darkMessageReactionBackground = Color(0x14FFFFFF);
  static const Color lightMessageReactionSelected = Color(0xFFEDE9FE);
  static const Color darkMessageReactionSelected = Color(0x478B5CF6);
  static const Color lightError = Color(0xFFC62828);
  static const Color darkError = Color(0xFFDC2626);
  static const Color lightErrorText = Color(0xFFC62828);
  static const Color darkErrorText = Color(0xFFF87171);
  static const Color lightFocusRing = Color(0x597047D6);
  static const Color darkFocusRing = Color(0x66A78BFA);
  static const Color lightImportant = Color(0xFFB45309);
  static const Color darkImportant = Color(0xFFD97706);
  static const Color lightInfo = Color(0xFF6D5DF6);
  static const Color darkInfo = Color(0xFF6D5DF6);
  static const Color lightInfoText = Color(0xFF4F46E5);
  static const Color darkInfoText = Color(0xFFA5B4FC);
  static const Color lightPinned = Color(0xFF7047D6);
  static const Color darkPinned = Color(0xFFA78BFA);
  static const Color lightPrimary = Color(0xFF7047D6);
  static const Color darkPrimary = Color(0xFF7047D6);
  static const Color lightPrimaryActive = Color(0xFF512CAC);
  static const Color darkPrimaryActive = Color(0xFF6641C9);
  static const Color lightPrimaryHover = Color(0xFF6138C4);
  static const Color darkPrimaryHover = Color(0xFF7D58DD);
  static const Color lightPrimaryText = Color(0xFF7047D6);
  static const Color darkPrimaryText = Color(0xFFC4B5FD);
  static const Color lightRobot = Color(0xFF64748B);
  static const Color darkRobot = Color(0xFF94A3B8);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color darkSuccess = Color(0xFF16A34A);
  static const Color lightSuccessText = Color(0xFF15803D);
  static const Color darkSuccessText = Color(0xFF4ADE80);
  static const Color lightTextDisabled = Color(0xFFB7BDC8);
  static const Color darkTextDisabled = Color(0x47FFFFFF);
  static const Color lightTextLink = Color(0xFF7047D6);
  static const Color darkTextLink = Color(0xFFC4B5FD);
  static const Color lightTextLinkHover = Color(0xFF6138C4);
  static const Color darkTextLinkHover = Color(0xFFDDD0FE);
  static const Color lightTextPrimary = Color(0xFF20232D);
  static const Color darkTextPrimary = Color(0xF0FFFFFF);
  static const Color lightTextSecondary = Color(0xFF5C6371);
  static const Color darkTextSecondary = Color(0x9EFFFFFF);
  static const Color lightTextTertiary = Color(0xFF5F6776);
  static const Color darkTextTertiary = Color(0xFF9AA3B3);
  static const Color lightWarning = Color(0xFFB45309);
  static const Color darkWarning = Color(0xFFA16207);
  static const Color lightWarningText = Color(0xFFB45309);
  static const Color darkWarningText = Color(0xFFFBBF24);
  static const Color lightAvatarTintBlueBg = Color(0xFFDBEAFE);
  static const Color darkAvatarTintBlueBg = Color(0xFF1F3266);
  static const Color lightAvatarTintBlueFg = Color(0xFF1D4ED8);
  static const Color darkAvatarTintBlueFg = Color(0xFFBFDBFE);
  static const Color lightAvatarTintPurpleBg = Color(0xFFE9D5FF);
  static const Color darkAvatarTintPurpleBg = Color(0xFF3A2566);
  static const Color lightAvatarTintPurpleFg = Color(0xFF6D28D9);
  static const Color darkAvatarTintPurpleFg = Color(0xFFDDD6FE);
  static const Color lightAvatarTintPinkBg = Color(0xFFFBCFE8);
  static const Color darkAvatarTintPinkBg = Color(0xFF5C1F3E);
  static const Color lightAvatarTintPinkFg = Color(0xFF9D174D);
  static const Color darkAvatarTintPinkFg = Color(0xFFFBCFE8);
  static const Color lightAvatarTintGreenBg = Color(0xFFD1FAE5);
  static const Color darkAvatarTintGreenBg = Color(0xFF15433C);
  static const Color lightAvatarTintGreenFg = Color(0xFF047857);
  static const Color darkAvatarTintGreenFg = Color(0xFFA7F3D0);
  static const Color lightAvatarTintAmberBg = Color(0xFFFEF3C7);
  static const Color darkAvatarTintAmberBg = Color(0xFF58351E);
  static const Color lightAvatarTintAmberFg = Color(0xFFB45309);
  static const Color darkAvatarTintAmberFg = Color(0xFFFDE68A);
  static const Color lightAvatarTintSlateBg = Color(0xFFE5E7EB);
  static const Color darkAvatarTintSlateBg = Color(0xFF282D38);
  static const Color lightAvatarTintSlateFg = Color(0xFF374151);
  static const Color darkAvatarTintSlateFg = Color(0xFFE5E7EB);
}

/// Opacity tokens (disabled / muted / tint overlays).
abstract final class FlareOpacity {
  static const double disabled = 0.5;
  static const double muted = 0.7;
  static const double tintWeak = 0.1;
  static const double tintStrong = 0.24;
}

/// Elevation tokens as [BoxShadow] lists; pick by [Brightness] with [FlareShadows.of].
class FlareShadows {
  const FlareShadows({required this.card, required this.lg, required this.md, required this.none, required this.sm, required this.xl});
  final List<BoxShadow> card;
  final List<BoxShadow> lg;
  final List<BoxShadow> md;
  final List<BoxShadow> none;
  final List<BoxShadow> sm;
  final List<BoxShadow> xl;
  static const FlareShadows light = FlareShadows(
    card: [BoxShadow(color: Color(0x0F141926), offset: Offset(0, 2), blurRadius: 8, spreadRadius: 0)],
    lg: [BoxShadow(color: Color(0x1F141926), offset: Offset(0, 12), blurRadius: 32, spreadRadius: 0)],
    md: [BoxShadow(color: Color(0x1A141926), offset: Offset(0, 4), blurRadius: 16, spreadRadius: 0)],
    none: [],
    sm: [BoxShadow(color: Color(0x0D151220), offset: Offset(0, 1), blurRadius: 2, spreadRadius: 0), BoxShadow(color: Color(0x0A151220), offset: Offset(0, 1), blurRadius: 1, spreadRadius: 0)],
    xl: [BoxShadow(color: Color(0x29141926), offset: Offset(0, 20), blurRadius: 56, spreadRadius: 0)],
  );
  static const FlareShadows dark = FlareShadows(
    card: [BoxShadow(color: Color(0x52000000), offset: Offset(0, 8), blurRadius: 28, spreadRadius: 0)],
    lg: [BoxShadow(color: Color(0x52000000), offset: Offset(0, 8), blurRadius: 28, spreadRadius: 0)],
    md: [BoxShadow(color: Color(0x52000000), offset: Offset(0, 8), blurRadius: 28, spreadRadius: 0)],
    none: [],
    sm: [BoxShadow(color: Color(0x6B000000), offset: Offset(0, 1), blurRadius: 2, spreadRadius: 0), BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 1, spreadRadius: 0)],
    xl: [BoxShadow(color: Color(0x52000000), offset: Offset(0, 8), blurRadius: 28, spreadRadius: 0)],
  );
  static FlareShadows of(Brightness brightness) => brightness == Brightness.dark ? dark : light;
}

/// Motion tokens: durations and curves shared with the web transitions.
abstract final class FlareMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Curve fastCurve = Cubic(0.22, 1, 0.36, 1);
  static const Duration normal = Duration(milliseconds: 200);
  static const Curve normalCurve = Cubic(0.22, 1, 0.36, 1);
  static const Duration slow = Duration(milliseconds: 260);
  static const Curve slowCurve = Cubic(0.22, 1, 0.36, 1);
  static const Duration spring = Duration(milliseconds: 360);
  static const Curve springCurve = Cubic(0.34, 1.4, 0.5, 1);
}
