package com.flare.im.ui

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
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
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
        modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
        verticalAlignment = Alignment.CenterVertically,
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
 * The primary filled action — brand-violet container, white label, [FlareSizes.radiusLg] corners.
 * When [loading] the button is non-interactive and shows an inline spinner + [loadingText] (falls
 * back to [text]). Use for the one dominant action on a surface (sign-in, confirm, send-off).
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
    loadingText: String? = null,
) {
    val colors = flareColors()
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        colors = ButtonDefaults.buttonColors(
            containerColor = colors.primary,
            disabledContainerColor = colors.primary.copy(alpha = 0.6f),
        ),
        shape = RoundedCornerShape(FlareSizes.radiusLg),
        modifier = modifier.height(48.dp),
    ) {
        if (loading) {
            CircularProgressIndicator(Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
            Spacer(Modifier.width(FlareSizes.spacingSm))
        }
        Text(
            if (loading) (loadingText ?: text) else text,
            color = Color.White,
            fontSize = FlareSizes.fontSizeXl.value.sp,
        )
    }
}

/**
 * Single-choice segmented control (分段选择器) — a row of mutually-exclusive [options]; the selected
 * segment is brand-tinted (12% violet fill + violet content/border), the rest transparent. Emits the
 * chosen index via [onSelect]. Use for a small, flat in-page filter (联系人 / 群组 / 新的联系人 …).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SegmentedControl(
    options: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = flareColors()
    SingleChoiceSegmentedButtonRow(modifier) {
        options.forEachIndexed { i, label ->
            SegmentedButton(
                selected = selectedIndex == i,
                onClick = { onSelect(i) },
                shape = SegmentedButtonDefaults.itemShape(i, options.size),
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = colors.primary.copy(alpha = 0.12f),
                    activeContentColor = colors.primary,
                    activeBorderColor = colors.primary,
                    inactiveContainerColor = Color.Transparent,
                ),
            ) { Text(label) }
        }
    }
}
