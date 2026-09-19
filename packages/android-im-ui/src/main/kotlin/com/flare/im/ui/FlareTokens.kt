// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json
package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.geometry.Offset
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing

enum class FlareBrandTheme { Violet, Ocean, Forest, Sunset, Rose, Graphite }

/** Flare IM semantic colors resolved by brand and dark mode. */
data class FlareColors(
    val bgDisabled: Color,
    val bgElevated: Color,
    val bgHover: Color,
    val bgPrimary: Color,
    val bgSecondary: Color,
    val bgSelected: Color,
    val bgTertiary: Color,
    val borderHover: Color,
    val borderPrimary: Color,
    val borderSecondary: Color,
    val borderSelected: Color,
    val messageIncomingBackground: Color,
    val messageIncomingForeground: Color,
    val messageIncomingBorder: Color,
    val messageOutgoingBackground: Color,
    val messageOutgoingForeground: Color,
    val messageOutgoingBorder: Color,
    val messageSelectedBackground: Color,
    val messageSelectedBorder: Color,
    val messageFailedBackground: Color,
    val messageFailedForeground: Color,
    val messageFailedBorder: Color,
    val messageMetaForeground: Color,
    val messageStatusPending: Color,
    val messageStatusSent: Color,
    val messageStatusDelivered: Color,
    val messageStatusRead: Color,
    val messageStatusFailed: Color,
    val messageStatusOnOutgoing: Color,
    val messageStatusReadOnOutgoing: Color,
    val messageReplyBackground: Color,
    val messageReplyBorder: Color,
    val messageReactionBackground: Color,
    val messageReactionSelected: Color,
    val error: Color,
    val errorText: Color,
    val focusRing: Color,
    val important: Color,
    val info: Color,
    val infoText: Color,
    val pinned: Color,
    val primary: Color,
    val primaryActive: Color,
    val primaryHover: Color,
    val primaryText: Color,
    val robot: Color,
    val success: Color,
    val successText: Color,
    val textDisabled: Color,
    val textLink: Color,
    val textLinkHover: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val warning: Color,
    val warningText: Color,
) {
    companion object {
        val VioletLight = FlareColors(
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFF0ECFC),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFF7C3AED),
            messageIncomingBackground = Color(0xFFFFFFFF),
            messageIncomingForeground = Color(0xFF20232D),
            messageIncomingBorder = Color(0xFFE3E5EB),
            messageOutgoingBackground = Color(0xFF6D28D9),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF5B21B6),
            messageSelectedBackground = Color(0xFFF0ECFC),
            messageSelectedBorder = Color(0xFF7C3AED),
            messageFailedBackground = Color(0xFFFEF2F2),
            messageFailedForeground = Color(0xFFB91C1C),
            messageFailedBorder = Color(0xFFFCA5A5),
            messageMetaForeground = Color(0xFF5C6371),
            messageStatusPending = Color(0xFF5F6776),
            messageStatusSent = Color(0xFF5F6776),
            messageStatusDelivered = Color(0xFF5C6371),
            messageStatusRead = Color(0xFF6D28D9),
            messageStatusFailed = Color(0xFFDC2626),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFEDE9FE),
            messageReplyBackground = Color(0xFFF7F8FA),
            messageReplyBorder = Color(0xFF8B5CF6),
            messageReactionBackground = Color(0xFFF1F2F5),
            messageReactionSelected = Color(0xFFEDE9FE),
            error = Color(0xFFC62828),
            errorText = Color(0xFFC62828),
            focusRing = Color(0x576D28D9),
            important = Color(0xFFB45309),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFF4F46E5),
            pinned = Color(0xFF6D28D9),
            primary = Color(0xFF6D28D9),
            primaryActive = Color(0xFF4C1D95),
            primaryHover = Color(0xFF5B21B6),
            primaryText = Color(0xFF6D28D9),
            robot = Color(0xFF64748B),
            success = Color(0xFF16A34A),
            successText = Color(0xFF15803D),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFF6D28D9),
            textLinkHover = Color(0xFF5B21B6),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF5C6371),
            textTertiary = Color(0xFF5F6776),
            warning = Color(0xFFB45309),
            warningText = Color(0xFFB45309),
        )

        val VioletDark = FlareColors(
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0xFF2D2340),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFFA78BFA),
            messageIncomingBackground = Color(0xFF20232B),
            messageIncomingForeground = Color(0xF0FFFFFF),
            messageIncomingBorder = Color(0x1AFFFFFF),
            messageOutgoingBackground = Color(0xFF5B21B6),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF8B5CF6),
            messageSelectedBackground = Color(0xFF2D2340),
            messageSelectedBorder = Color(0xFFA78BFA),
            messageFailedBackground = Color(0xFF3F1D24),
            messageFailedForeground = Color(0xFFFCA5A5),
            messageFailedBorder = Color(0xFF991B1B),
            messageMetaForeground = Color(0xFF9AA3B3),
            messageStatusPending = Color(0xFF9AA3B3),
            messageStatusSent = Color(0xFF9AA3B3),
            messageStatusDelivered = Color(0x9EFFFFFF),
            messageStatusRead = Color(0xFFC4B5FD),
            messageStatusFailed = Color(0xFFF87171),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFEDE9FE),
            messageReplyBackground = Color(0x12FFFFFF),
            messageReplyBorder = Color(0xFFA78BFA),
            messageReactionBackground = Color(0x14FFFFFF),
            messageReactionSelected = Color(0x4D8B5CF6),
            error = Color(0xFFDC2626),
            errorText = Color(0xFFF87171),
            focusRing = Color(0x6BC4B5FD),
            important = Color(0xFFD97706),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFFA5B4FC),
            pinned = Color(0xFFC4B5FD),
            primary = Color(0xFF6D28D9),
            primaryActive = Color(0xFF5B21B6),
            primaryHover = Color(0xFF7C3AED),
            primaryText = Color(0xFFC4B5FD),
            robot = Color(0xFF94A3B8),
            success = Color(0xFF16A34A),
            successText = Color(0xFF4ADE80),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFFC4B5FD),
            textLinkHover = Color(0xFFDDD6FE),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFA16207),
            warningText = Color(0xFFFBBF24),
        )

        val OceanLight = FlareColors(
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFEFF6FF),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFF2563EB),
            messageIncomingBackground = Color(0xFFFFFFFF),
            messageIncomingForeground = Color(0xFF20232D),
            messageIncomingBorder = Color(0xFFE3E5EB),
            messageOutgoingBackground = Color(0xFF1D4ED8),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF1E40AF),
            messageSelectedBackground = Color(0xFFEFF6FF),
            messageSelectedBorder = Color(0xFF2563EB),
            messageFailedBackground = Color(0xFFFEF2F2),
            messageFailedForeground = Color(0xFFB91C1C),
            messageFailedBorder = Color(0xFFFCA5A5),
            messageMetaForeground = Color(0xFF5C6371),
            messageStatusPending = Color(0xFF5F6776),
            messageStatusSent = Color(0xFF5F6776),
            messageStatusDelivered = Color(0xFF5C6371),
            messageStatusRead = Color(0xFF1D4ED8),
            messageStatusFailed = Color(0xFFDC2626),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFDBEAFE),
            messageReplyBackground = Color(0xFFF7F8FA),
            messageReplyBorder = Color(0xFF3B82F6),
            messageReactionBackground = Color(0xFFF1F2F5),
            messageReactionSelected = Color(0xFFDBEAFE),
            error = Color(0xFFC62828),
            errorText = Color(0xFFC62828),
            focusRing = Color(0x572563EB),
            important = Color(0xFFB45309),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFF4F46E5),
            pinned = Color(0xFF1D4ED8),
            primary = Color(0xFF1D4ED8),
            primaryActive = Color(0xFF1E3A8A),
            primaryHover = Color(0xFF1E40AF),
            primaryText = Color(0xFF1D4ED8),
            robot = Color(0xFF64748B),
            success = Color(0xFF16A34A),
            successText = Color(0xFF15803D),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFF1D4ED8),
            textLinkHover = Color(0xFF1E40AF),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF5C6371),
            textTertiary = Color(0xFF5F6776),
            warning = Color(0xFFB45309),
            warningText = Color(0xFFB45309),
        )

        val OceanDark = FlareColors(
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0xFF172A46),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFF60A5FA),
            messageIncomingBackground = Color(0xFF20232B),
            messageIncomingForeground = Color(0xF0FFFFFF),
            messageIncomingBorder = Color(0x1AFFFFFF),
            messageOutgoingBackground = Color(0xFF1E40AF),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF3B82F6),
            messageSelectedBackground = Color(0xFF172A46),
            messageSelectedBorder = Color(0xFF60A5FA),
            messageFailedBackground = Color(0xFF3F1D24),
            messageFailedForeground = Color(0xFFFCA5A5),
            messageFailedBorder = Color(0xFF991B1B),
            messageMetaForeground = Color(0xFF9AA3B3),
            messageStatusPending = Color(0xFF9AA3B3),
            messageStatusSent = Color(0xFF9AA3B3),
            messageStatusDelivered = Color(0x9EFFFFFF),
            messageStatusRead = Color(0xFF93C5FD),
            messageStatusFailed = Color(0xFFF87171),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFDBEAFE),
            messageReplyBackground = Color(0x12FFFFFF),
            messageReplyBorder = Color(0xFF60A5FA),
            messageReactionBackground = Color(0x14FFFFFF),
            messageReactionSelected = Color(0x4D3B82F6),
            error = Color(0xFFDC2626),
            errorText = Color(0xFFF87171),
            focusRing = Color(0x6B93C5FD),
            important = Color(0xFFD97706),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFFA5B4FC),
            pinned = Color(0xFF93C5FD),
            primary = Color(0xFF1E40AF),
            primaryActive = Color(0xFF1E3A8A),
            primaryHover = Color(0xFF1D4ED8),
            primaryText = Color(0xFF93C5FD),
            robot = Color(0xFF94A3B8),
            success = Color(0xFF16A34A),
            successText = Color(0xFF4ADE80),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFF93C5FD),
            textLinkHover = Color(0xFFBFDBFE),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFA16207),
            warningText = Color(0xFFFBBF24),
        )

        val ForestLight = FlareColors(
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFF0FDF4),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFF16A34A),
            messageIncomingBackground = Color(0xFFFFFFFF),
            messageIncomingForeground = Color(0xFF20232D),
            messageIncomingBorder = Color(0xFFE3E5EB),
            messageOutgoingBackground = Color(0xFF15803D),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF166534),
            messageSelectedBackground = Color(0xFFF0FDF4),
            messageSelectedBorder = Color(0xFF16A34A),
            messageFailedBackground = Color(0xFFFEF2F2),
            messageFailedForeground = Color(0xFFB91C1C),
            messageFailedBorder = Color(0xFFFCA5A5),
            messageMetaForeground = Color(0xFF5C6371),
            messageStatusPending = Color(0xFF5F6776),
            messageStatusSent = Color(0xFF5F6776),
            messageStatusDelivered = Color(0xFF5C6371),
            messageStatusRead = Color(0xFF15803D),
            messageStatusFailed = Color(0xFFDC2626),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFDCFCE7),
            messageReplyBackground = Color(0xFFF7F8FA),
            messageReplyBorder = Color(0xFF22C55E),
            messageReactionBackground = Color(0xFFF1F2F5),
            messageReactionSelected = Color(0xFFDCFCE7),
            error = Color(0xFFC62828),
            errorText = Color(0xFFC62828),
            focusRing = Color(0x5716A34A),
            important = Color(0xFFB45309),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFF4F46E5),
            pinned = Color(0xFF15803D),
            primary = Color(0xFF15803D),
            primaryActive = Color(0xFF14532D),
            primaryHover = Color(0xFF166534),
            primaryText = Color(0xFF15803D),
            robot = Color(0xFF64748B),
            success = Color(0xFF16A34A),
            successText = Color(0xFF15803D),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFF15803D),
            textLinkHover = Color(0xFF166534),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF5C6371),
            textTertiary = Color(0xFF5F6776),
            warning = Color(0xFFB45309),
            warningText = Color(0xFFB45309),
        )

        val ForestDark = FlareColors(
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0xFF183528),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFF4ADE80),
            messageIncomingBackground = Color(0xFF20232B),
            messageIncomingForeground = Color(0xF0FFFFFF),
            messageIncomingBorder = Color(0x1AFFFFFF),
            messageOutgoingBackground = Color(0xFF166534),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF22C55E),
            messageSelectedBackground = Color(0xFF183528),
            messageSelectedBorder = Color(0xFF4ADE80),
            messageFailedBackground = Color(0xFF3F1D24),
            messageFailedForeground = Color(0xFFFCA5A5),
            messageFailedBorder = Color(0xFF991B1B),
            messageMetaForeground = Color(0xFF9AA3B3),
            messageStatusPending = Color(0xFF9AA3B3),
            messageStatusSent = Color(0xFF9AA3B3),
            messageStatusDelivered = Color(0x9EFFFFFF),
            messageStatusRead = Color(0xFF86EFAC),
            messageStatusFailed = Color(0xFFF87171),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFDCFCE7),
            messageReplyBackground = Color(0x12FFFFFF),
            messageReplyBorder = Color(0xFF4ADE80),
            messageReactionBackground = Color(0x14FFFFFF),
            messageReactionSelected = Color(0x4722C55E),
            error = Color(0xFFDC2626),
            errorText = Color(0xFFF87171),
            focusRing = Color(0x6686EFAC),
            important = Color(0xFFD97706),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFFA5B4FC),
            pinned = Color(0xFF86EFAC),
            primary = Color(0xFF166534),
            primaryActive = Color(0xFF14532D),
            primaryHover = Color(0xFF15803D),
            primaryText = Color(0xFF86EFAC),
            robot = Color(0xFF94A3B8),
            success = Color(0xFF16A34A),
            successText = Color(0xFF4ADE80),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFF86EFAC),
            textLinkHover = Color(0xFFBBF7D0),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFA16207),
            warningText = Color(0xFFFBBF24),
        )

        val SunsetLight = FlareColors(
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFFFF7ED),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFFEA580C),
            messageIncomingBackground = Color(0xFFFFFFFF),
            messageIncomingForeground = Color(0xFF20232D),
            messageIncomingBorder = Color(0xFFE3E5EB),
            messageOutgoingBackground = Color(0xFFC2410C),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF9A3412),
            messageSelectedBackground = Color(0xFFFFF7ED),
            messageSelectedBorder = Color(0xFFEA580C),
            messageFailedBackground = Color(0xFFFEF2F2),
            messageFailedForeground = Color(0xFFB91C1C),
            messageFailedBorder = Color(0xFFFCA5A5),
            messageMetaForeground = Color(0xFF5C6371),
            messageStatusPending = Color(0xFF5F6776),
            messageStatusSent = Color(0xFF5F6776),
            messageStatusDelivered = Color(0xFF5C6371),
            messageStatusRead = Color(0xFFC2410C),
            messageStatusFailed = Color(0xFFDC2626),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFFFEDD5),
            messageReplyBackground = Color(0xFFF7F8FA),
            messageReplyBorder = Color(0xFFF97316),
            messageReactionBackground = Color(0xFFF1F2F5),
            messageReactionSelected = Color(0xFFFFEDD5),
            error = Color(0xFFC62828),
            errorText = Color(0xFFC62828),
            focusRing = Color(0x57EA580C),
            important = Color(0xFFB45309),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFF4F46E5),
            pinned = Color(0xFFC2410C),
            primary = Color(0xFFC2410C),
            primaryActive = Color(0xFF7C2D12),
            primaryHover = Color(0xFF9A3412),
            primaryText = Color(0xFFC2410C),
            robot = Color(0xFF64748B),
            success = Color(0xFF16A34A),
            successText = Color(0xFF15803D),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFFC2410C),
            textLinkHover = Color(0xFF9A3412),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF5C6371),
            textTertiary = Color(0xFF5F6776),
            warning = Color(0xFFB45309),
            warningText = Color(0xFFB45309),
        )

        val SunsetDark = FlareColors(
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0xFF3B2619),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFFFB923C),
            messageIncomingBackground = Color(0xFF20232B),
            messageIncomingForeground = Color(0xF0FFFFFF),
            messageIncomingBorder = Color(0x1AFFFFFF),
            messageOutgoingBackground = Color(0xFF9A3412),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFFEA580C),
            messageSelectedBackground = Color(0xFF3B2619),
            messageSelectedBorder = Color(0xFFFB923C),
            messageFailedBackground = Color(0xFF3F1D24),
            messageFailedForeground = Color(0xFFFCA5A5),
            messageFailedBorder = Color(0xFF991B1B),
            messageMetaForeground = Color(0xFF9AA3B3),
            messageStatusPending = Color(0xFF9AA3B3),
            messageStatusSent = Color(0xFF9AA3B3),
            messageStatusDelivered = Color(0x9EFFFFFF),
            messageStatusRead = Color(0xFFFDBA74),
            messageStatusFailed = Color(0xFFF87171),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFFFEDD5),
            messageReplyBackground = Color(0x12FFFFFF),
            messageReplyBorder = Color(0xFFFB923C),
            messageReactionBackground = Color(0x14FFFFFF),
            messageReactionSelected = Color(0x47F97316),
            error = Color(0xFFDC2626),
            errorText = Color(0xFFF87171),
            focusRing = Color(0x66FDBA74),
            important = Color(0xFFD97706),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFFA5B4FC),
            pinned = Color(0xFFFDBA74),
            primary = Color(0xFF9A3412),
            primaryActive = Color(0xFF7C2D12),
            primaryHover = Color(0xFFC2410C),
            primaryText = Color(0xFFFDBA74),
            robot = Color(0xFF94A3B8),
            success = Color(0xFF16A34A),
            successText = Color(0xFF4ADE80),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFFFDBA74),
            textLinkHover = Color(0xFFFED7AA),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFA16207),
            warningText = Color(0xFFFBBF24),
        )

        val RoseLight = FlareColors(
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFFFF1F2),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFFE11D48),
            messageIncomingBackground = Color(0xFFFFFFFF),
            messageIncomingForeground = Color(0xFF20232D),
            messageIncomingBorder = Color(0xFFE3E5EB),
            messageOutgoingBackground = Color(0xFFBE123C),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF9F1239),
            messageSelectedBackground = Color(0xFFFFF1F2),
            messageSelectedBorder = Color(0xFFE11D48),
            messageFailedBackground = Color(0xFFFEF2F2),
            messageFailedForeground = Color(0xFFB91C1C),
            messageFailedBorder = Color(0xFFFCA5A5),
            messageMetaForeground = Color(0xFF5C6371),
            messageStatusPending = Color(0xFF5F6776),
            messageStatusSent = Color(0xFF5F6776),
            messageStatusDelivered = Color(0xFF5C6371),
            messageStatusRead = Color(0xFFBE123C),
            messageStatusFailed = Color(0xFFDC2626),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFFFE4E6),
            messageReplyBackground = Color(0xFFF7F8FA),
            messageReplyBorder = Color(0xFFF43F5E),
            messageReactionBackground = Color(0xFFF1F2F5),
            messageReactionSelected = Color(0xFFFFE4E6),
            error = Color(0xFFC62828),
            errorText = Color(0xFFC62828),
            focusRing = Color(0x52E11D48),
            important = Color(0xFFB45309),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFF4F46E5),
            pinned = Color(0xFFBE123C),
            primary = Color(0xFFBE123C),
            primaryActive = Color(0xFF881337),
            primaryHover = Color(0xFF9F1239),
            primaryText = Color(0xFFBE123C),
            robot = Color(0xFF64748B),
            success = Color(0xFF16A34A),
            successText = Color(0xFF15803D),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFFBE123C),
            textLinkHover = Color(0xFF9F1239),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF5C6371),
            textTertiary = Color(0xFF5F6776),
            warning = Color(0xFFB45309),
            warningText = Color(0xFFB45309),
        )

        val RoseDark = FlareColors(
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0xFF3B2028),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFFFB7185),
            messageIncomingBackground = Color(0xFF20232B),
            messageIncomingForeground = Color(0xF0FFFFFF),
            messageIncomingBorder = Color(0x1AFFFFFF),
            messageOutgoingBackground = Color(0xFF9F1239),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFFE11D48),
            messageSelectedBackground = Color(0xFF3B2028),
            messageSelectedBorder = Color(0xFFFB7185),
            messageFailedBackground = Color(0xFF3F1D24),
            messageFailedForeground = Color(0xFFFCA5A5),
            messageFailedBorder = Color(0xFF991B1B),
            messageMetaForeground = Color(0xFF9AA3B3),
            messageStatusPending = Color(0xFF9AA3B3),
            messageStatusSent = Color(0xFF9AA3B3),
            messageStatusDelivered = Color(0x9EFFFFFF),
            messageStatusRead = Color(0xFFFDA4AF),
            messageStatusFailed = Color(0xFFF87171),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFFFE4E6),
            messageReplyBackground = Color(0x12FFFFFF),
            messageReplyBorder = Color(0xFFFB7185),
            messageReactionBackground = Color(0x14FFFFFF),
            messageReactionSelected = Color(0x47F43F5E),
            error = Color(0xFFDC2626),
            errorText = Color(0xFFF87171),
            focusRing = Color(0x66FDA4AF),
            important = Color(0xFFD97706),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFFA5B4FC),
            pinned = Color(0xFFFDA4AF),
            primary = Color(0xFF9F1239),
            primaryActive = Color(0xFF881337),
            primaryHover = Color(0xFFBE123C),
            primaryText = Color(0xFFFDA4AF),
            robot = Color(0xFF94A3B8),
            success = Color(0xFF16A34A),
            successText = Color(0xFF4ADE80),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFFFDA4AF),
            textLinkHover = Color(0xFFFECDD3),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFA16207),
            warningText = Color(0xFFFBBF24),
        )

        val GraphiteLight = FlareColors(
            bgDisabled = Color(0xFFF1F2F5),
            bgElevated = Color(0xFFFFFFFF),
            bgHover = Color(0xFFF1F2F5),
            bgPrimary = Color(0xFFFFFFFF),
            bgSecondary = Color(0xFFF7F8FA),
            bgSelected = Color(0xFFF1F5F9),
            bgTertiary = Color(0xFFF1F2F5),
            borderHover = Color(0xFFC9CDD7),
            borderPrimary = Color(0xFFE3E5EB),
            borderSecondary = Color(0xFFECEEF2),
            borderSelected = Color(0xFF64748B),
            messageIncomingBackground = Color(0xFFFFFFFF),
            messageIncomingForeground = Color(0xFF20232D),
            messageIncomingBorder = Color(0xFFE3E5EB),
            messageOutgoingBackground = Color(0xFF475569),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF334155),
            messageSelectedBackground = Color(0xFFF1F5F9),
            messageSelectedBorder = Color(0xFF64748B),
            messageFailedBackground = Color(0xFFFEF2F2),
            messageFailedForeground = Color(0xFFB91C1C),
            messageFailedBorder = Color(0xFFFCA5A5),
            messageMetaForeground = Color(0xFF5C6371),
            messageStatusPending = Color(0xFF5F6776),
            messageStatusSent = Color(0xFF5F6776),
            messageStatusDelivered = Color(0xFF5C6371),
            messageStatusRead = Color(0xFF475569),
            messageStatusFailed = Color(0xFFDC2626),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFE2E8F0),
            messageReplyBackground = Color(0xFFF7F8FA),
            messageReplyBorder = Color(0xFF64748B),
            messageReactionBackground = Color(0xFFF1F2F5),
            messageReactionSelected = Color(0xFFE2E8F0),
            error = Color(0xFFC62828),
            errorText = Color(0xFFC62828),
            focusRing = Color(0x57475569),
            important = Color(0xFFB45309),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFF4F46E5),
            pinned = Color(0xFF475569),
            primary = Color(0xFF475569),
            primaryActive = Color(0xFF1E293B),
            primaryHover = Color(0xFF334155),
            primaryText = Color(0xFF475569),
            robot = Color(0xFF64748B),
            success = Color(0xFF16A34A),
            successText = Color(0xFF15803D),
            textDisabled = Color(0xFFB7BDC8),
            textLink = Color(0xFF475569),
            textLinkHover = Color(0xFF334155),
            textPrimary = Color(0xFF20232D),
            textSecondary = Color(0xFF5C6371),
            textTertiary = Color(0xFF5F6776),
            warning = Color(0xFFB45309),
            warningText = Color(0xFFB45309),
        )

        val GraphiteDark = FlareColors(
            bgDisabled = Color(0xFF292D37),
            bgElevated = Color(0xFF292D37),
            bgHover = Color(0x0FFFFFFF),
            bgPrimary = Color(0xFF20232B),
            bgSecondary = Color(0xFF17191F),
            bgSelected = Color(0xFF2B3440),
            bgTertiary = Color(0xFF292D37),
            borderHover = Color(0x29FFFFFF),
            borderPrimary = Color(0x1AFFFFFF),
            borderSecondary = Color(0x14FFFFFF),
            borderSelected = Color(0xFF94A3B8),
            messageIncomingBackground = Color(0xFF20232B),
            messageIncomingForeground = Color(0xF0FFFFFF),
            messageIncomingBorder = Color(0x1AFFFFFF),
            messageOutgoingBackground = Color(0xFF475569),
            messageOutgoingForeground = Color(0xFFFFFFFF),
            messageOutgoingBorder = Color(0xFF64748B),
            messageSelectedBackground = Color(0xFF2B3440),
            messageSelectedBorder = Color(0xFF94A3B8),
            messageFailedBackground = Color(0xFF3F1D24),
            messageFailedForeground = Color(0xFFFCA5A5),
            messageFailedBorder = Color(0xFF991B1B),
            messageMetaForeground = Color(0xFF9AA3B3),
            messageStatusPending = Color(0xFF9AA3B3),
            messageStatusSent = Color(0xFF9AA3B3),
            messageStatusDelivered = Color(0x9EFFFFFF),
            messageStatusRead = Color(0xFFCBD5E1),
            messageStatusFailed = Color(0xFFF87171),
            messageStatusOnOutgoing = Color(0xCCFFFFFF),
            messageStatusReadOnOutgoing = Color(0xFFE2E8F0),
            messageReplyBackground = Color(0x12FFFFFF),
            messageReplyBorder = Color(0xFF94A3B8),
            messageReactionBackground = Color(0x14FFFFFF),
            messageReactionSelected = Color(0x4794A3B8),
            error = Color(0xFFDC2626),
            errorText = Color(0xFFF87171),
            focusRing = Color(0x61CBD5E1),
            important = Color(0xFFD97706),
            info = Color(0xFF6D5DF6),
            infoText = Color(0xFFA5B4FC),
            pinned = Color(0xFFCBD5E1),
            primary = Color(0xFF475569),
            primaryActive = Color(0xFF334155),
            primaryHover = Color(0xFF64748B),
            primaryText = Color(0xFFCBD5E1),
            robot = Color(0xFF94A3B8),
            success = Color(0xFF16A34A),
            successText = Color(0xFF4ADE80),
            textDisabled = Color(0x47FFFFFF),
            textLink = Color(0xFFCBD5E1),
            textLinkHover = Color(0xFFE2E8F0),
            textPrimary = Color(0xF0FFFFFF),
            textSecondary = Color(0x9EFFFFFF),
            textTertiary = Color(0xFF9AA3B3),
            warning = Color(0xFFA16207),
            warningText = Color(0xFFFBBF24),
        )

        val Light = VioletLight
        val Dark = VioletDark

        fun resolve(brand: FlareBrandTheme, dark: Boolean): FlareColors = when (brand) {
        FlareBrandTheme.Violet -> if (dark) VioletDark else VioletLight
        FlareBrandTheme.Ocean -> if (dark) OceanDark else OceanLight
        FlareBrandTheme.Forest -> if (dark) ForestDark else ForestLight
        FlareBrandTheme.Sunset -> if (dark) SunsetDark else SunsetLight
        FlareBrandTheme.Rose -> if (dark) RoseDark else RoseLight
        FlareBrandTheme.Graphite -> if (dark) GraphiteDark else GraphiteLight
        }
    }
}

@Composable
fun flareColors(): FlareColors =
    LocalFlareColors.current ?: if (isSystemInDarkTheme()) FlareColors.Dark else FlareColors.Light

private val LocalFlareColors = staticCompositionLocalOf<FlareColors?> { null }

/** The theme a host asks for: [Light] and [Dark] are the person overriding the system, [System] follows it. */
enum class FlareThemeMode { Light, Dark, System }

/** Whether to draw dark (`spec/theme-mode-vectors.json`, the same rule on four kits). */
fun flareThemeIsDark(mode: FlareThemeMode, systemDark: Boolean): Boolean =
    if (mode == FlareThemeMode.System) systemDark else mode == FlareThemeMode.Dark

/**
 * Provides semantic Flare colors and their Material presentation from one theme. [mode] is the person's choice,
 * which the host holds and stores; the system setting answers for [FlareThemeMode.System].
 */
@Composable
fun FlareThemeProvider(
    mode: FlareThemeMode = FlareThemeMode.System,
    brand: FlareBrandTheme = FlareBrandTheme.Violet,
    colors: FlareColors? = null,
    content: @Composable () -> Unit,
) {
    val dark = flareThemeIsDark(mode, isSystemInDarkTheme())
    val resolved = colors ?: FlareColors.resolve(brand, dark)
    CompositionLocalProvider(LocalFlareColors provides resolved) {
        androidx.compose.material3.MaterialTheme(
            colorScheme = flareMaterialColorScheme(resolved, dark),
            typography = flareMaterialTypography(),
            content = content,
        )
    }
}

/**
 * A named text role: what a title, a section header, body text or a caption is, in one place
 * (FR-051). [fontSize] is sp, [weight] the CSS weight mapped to a [FontWeight] by [fontWeight].
 */
data class FlareTextRole(val fontSize: TextUnit, val lineHeight: Float, val weight: Int) {
    val fontWeight: FontWeight get() = FontWeight(weight)
}

/** Flare IM text roles. */
object FlareTextRoles {
    val Title = FlareTextRole(20.sp, 1.2f, 700)
    val Section = FlareTextRole(13.sp, 1.2f, 600)
    val Body = FlareTextRole(14.sp, 1.5f, 400)
    val Caption = FlareTextRole(12.sp, 1.5f, 400)
}

/** Flare IM spacing / radius / font-size / line-height / layout tokens. */
object FlareSizes {
    val fontSize2xl: TextUnit = 16.sp
    val fontSize3xl: TextUnit = 18.sp
    val fontSize4xl: TextUnit = 20.sp
    val fontSizeLg: TextUnit = 14.sp
    val fontSizeMd: TextUnit = 13.sp
    val fontSizeSm: TextUnit = 12.sp
    val fontSizeXl: TextUnit = 15.sp
    val fontSizeXs: TextUnit = 11.sp
    val iconSizeLg: Dp = 24.dp
    val iconSizeMd: Dp = 20.dp
    val iconSizeSm: Dp = 16.dp
    val iconSizeXl: Dp = 32.dp
    val avatarSize: Dp = 44.dp
    val bubbleMaxWidth: Dp = 640.dp
    val messageTimelineContentMaxWidth: Dp = 920.dp
    val chatMinWidth: Dp = 360.dp
    val navigationRailWidth: Dp = 72.dp
    val navigationRailMinWidth: Dp = 600.dp
    val workbenchResizeHandleWidth: Dp = 8.dp
    val primaryPaneMinWidth: Dp = 280.dp
    val primaryPaneDefaultWidth: Dp = 320.dp
    val primaryPaneMaxWidth: Dp = 420.dp
    val detailPaneDefaultWidth: Dp = 300.dp
    val detailPaneMaxWidth: Dp = 420.dp
    val appShellCompactMinWidth: Dp = 900.dp
    val appShellExpandedMinWidth: Dp = 1500.dp
    val controlHeightLg: Dp = 48.dp
    val controlHeightMd: Dp = 40.dp
    val controlHeightSm: Dp = 32.dp
    val controlPadXLg: Dp = 24.dp
    val controlPadXMd: Dp = 18.dp
    val controlPadXSm: Dp = 12.dp
    val headerHeight: Dp = 60.dp
    val sessionItemHeight: Dp = 72.dp
    val touchTarget: Dp = 48.dp
    val touchTargetMin: Dp = 44.dp
    const val lineHeightNormal: Float = 1.5f
    const val lineHeightRelaxed: Float = 1.6f
    const val lineHeightTight: Float = 1.2f
    val radius2xl: Dp = 18.dp
    val radiusBubble: Dp = 16.dp
    val radiusBubbleTail: Dp = 4.dp
    val radiusFull: Dp = 999.dp
    val radiusLg: Dp = 10.dp
    val radiusMd: Dp = 8.dp
    val radiusSm: Dp = 6.dp
    val radiusXl: Dp = 14.dp
    val radiusXs: Dp = 3.dp
    val spacing2xl: Dp = 24.dp
    val spacing2xs: Dp = 6.dp
    val spacingLg: Dp = 16.dp
    val spacingMd: Dp = 12.dp
    val spacingSm: Dp = 8.dp
    val spacingXl: Dp = 20.dp
    val spacingXs: Dp = 4.dp
}

/** Opacity tokens (disabled / muted / tint overlays). */
object FlareOpacity {
    const val disabled: Float = 0.5f
    const val muted: Float = 0.7f
    const val tintWeak: Float = 0.1f
    const val tintStrong: Float = 0.24f
}

data class FlareShadowLayer(val color: Color, val offset: Offset, val blur: Dp)

/** Elevation tokens; theme-aware via [flareShadows]. */
data class FlareShadows(
    val card: List<FlareShadowLayer>,
    val lg: List<FlareShadowLayer>,
    val md: List<FlareShadowLayer>,
    val none: List<FlareShadowLayer>,
    val sm: List<FlareShadowLayer>,
    val xl: List<FlareShadowLayer>,
) {
    companion object {
        val Light = FlareShadows(
            card = listOf(FlareShadowLayer(color = Color(0x0F141926), offset = Offset(0f, 2f), blur = 8.dp)),
            lg = listOf(FlareShadowLayer(color = Color(0x1F141926), offset = Offset(0f, 12f), blur = 32.dp)),
            md = listOf(FlareShadowLayer(color = Color(0x1A141926), offset = Offset(0f, 4f), blur = 16.dp)),
            none = listOf(),
            sm = listOf(FlareShadowLayer(color = Color(0x0D151220), offset = Offset(0f, 1f), blur = 2.dp), FlareShadowLayer(color = Color(0x0A151220), offset = Offset(0f, 1f), blur = 1.dp)),
            xl = listOf(FlareShadowLayer(color = Color(0x29141926), offset = Offset(0f, 20f), blur = 56.dp)),
        )
        val Dark = FlareShadows(
            card = listOf(FlareShadowLayer(color = Color(0x52000000), offset = Offset(0f, 8f), blur = 28.dp)),
            lg = listOf(FlareShadowLayer(color = Color(0x52000000), offset = Offset(0f, 8f), blur = 28.dp)),
            md = listOf(FlareShadowLayer(color = Color(0x52000000), offset = Offset(0f, 8f), blur = 28.dp)),
            none = listOf(),
            sm = listOf(FlareShadowLayer(color = Color(0x6B000000), offset = Offset(0f, 1f), blur = 2.dp), FlareShadowLayer(color = Color(0x4D000000), offset = Offset(0f, 1f), blur = 1.dp)),
            xl = listOf(FlareShadowLayer(color = Color(0x52000000), offset = Offset(0f, 8f), blur = 28.dp)),
        )
    }
}

@Composable
fun flareShadows(): FlareShadows = if (flareColors() == FlareColors.Dark) FlareShadows.Dark else FlareShadows.Light

/** Motion tokens: durations (ms) and easings shared with the web transitions. */
object FlareMotion {
    const val fast: Int = 150
    val fastEasing: Easing = CubicBezierEasing(0.22f, 1f, 0.36f, 1f)
    const val normal: Int = 200
    val normalEasing: Easing = CubicBezierEasing(0.22f, 1f, 0.36f, 1f)
    const val slow: Int = 260
    val slowEasing: Easing = CubicBezierEasing(0.22f, 1f, 0.36f, 1f)
    const val spring: Int = 360
    val springEasing: Easing = CubicBezierEasing(0.34f, 1.4f, 0.5f, 1f)
}
