package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Screen-level large-title header — the quiet top bar for a tab surface (inbox / directory / me).
 * Sits on [FlareColors.bgPrimary], 24sp bold title, an optional trailing [actions] slot (icons).
 * Distinct from [ChatHeader], which is the conversation chrome (back + avatar + presence).
 */
@Composable
fun ScreenHeader(
    title: String,
    modifier: Modifier = Modifier,
    actions: @Composable RowScope.() -> Unit = {},
) {
    val colors = flareColors()
    Row(
        modifier
            .fillMaxWidth()
            .background(colors.bgPrimary)
            .padding(horizontal = FlareSizes.spacingLg, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Text(
            title,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            modifier = Modifier.weight(1f),
        )
        actions()
    }
}

/**
 * The primary filled action — brand-violet container, white [FontWeight.SemiBold] label,
 * [FlareSizes.radiusLg] corners, full-width. When [loading] the button is non-interactive and
 * shows an inline spinner + [loadingText] (falls back to [text]). An optional [leadingIcon] renders
 * before the label. Disabled dims the whole button to 55% opacity. Use for the one dominant action
 * on a surface (sign-in, confirm, send-off).
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
    loadingText: String? = null,
    leadingIcon: ImageVector? = null,
) {
    val colors = flareColors()
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        colors = ButtonDefaults.buttonColors(
            containerColor = colors.primary,
            disabledContainerColor = colors.primary,
        ),
        shape = RoundedCornerShape(FlareSizes.radiusLg),
        modifier = modifier
            .fillMaxWidth()
            .height(48.dp)
            .alpha(if (enabled) 1f else 0.55f),
    ) {
        if (loading) {
            CircularProgressIndicator(Modifier.size(16.dp), color = Color.White, strokeWidth = 2.dp)
            Spacer(Modifier.width(FlareSizes.spacingSm))
        } else if (leadingIcon != null) {
            Icon(leadingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(FlareSizes.spacingSm))
        }
        Text(
            if (loading) (loadingText ?: text) else text,
            color = Color.White,
            fontWeight = FontWeight.SemiBold,
            fontSize = FlareSizes.fontSizeXl.value.sp,
        )
    }
}

/**
 * Single-choice segmented control (分段选择器) — a row of equal-width, mutually-exclusive [options]
 * on a raised-chip track: a [FlareColors.bgSecondary] rail ([FlareSizes.radiusLg] + border), each
 * selected segment surfaced on a [FlareColors.bgPrimary] chip ([FlareSizes.radiusMd] + soft shadow,
 * [FlareColors.primary] label); unselected segments read [FlareColors.textSecondary]. Emits the
 * chosen index via [onSelect]. Use for a small, flat in-page filter (联系人 / 群组 / 新的联系人 …).
 */
@Composable
fun SegmentedControl(
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    val trackShape = RoundedCornerShape(FlareSizes.radiusLg)
    Row(
        modifier
            .clip(trackShape)
            .background(colors.bgSecondary)
            .border(1.dp, colors.borderPrimary, trackShape)
            .padding(3.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        val chipShape = RoundedCornerShape(FlareSizes.radiusMd)
        options.forEachIndexed { i, label ->
            val active = selectedIndex == i
            Box(
                Modifier
                    .weight(1f)
                    .then(
                        if (active)
                            Modifier
                                .shadow(4.dp, chipShape)
                                .clip(chipShape)
                                .background(colors.bgPrimary)
                        else Modifier.clip(chipShape),
                    )
                    .clickable { onSelect(i) }
                    .padding(vertical = FlareSizes.spacingSm),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    label,
                    color = if (active) colors.primary else colors.textSecondary,
                    fontSize = FlareSizes.fontSizeLg.value.sp,
                    fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                )
            }
        }
    }
}
