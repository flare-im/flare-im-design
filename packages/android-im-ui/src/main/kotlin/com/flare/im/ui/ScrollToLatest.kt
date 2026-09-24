package com.flare.im.ui

import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.indication
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** The spoken name of the scroll-to-latest pill: how many new messages are below, else "back to latest" (Vue `FlareScrollToLatest`). */
internal fun scrollToLatestLabel(count: Int, strings: FlareStrings): String =
    if (count > 0) strings.newMessages(count) else strings.scrollToLatest

/**
 * Scroll-to-latest pill. Spec: Message/ScrollToLatest. With [onTap] it is one button named by
 * [scrollToLatestLabel] with a 48 dp touch target around the pill.
 */
@Composable
fun ScrollToLatest(count: Int = 0, onTap: (() -> Unit)? = null) {
    val colors = flareColors()
    val hasCount = count > 0
    val label = scrollToLatestLabel(count, flareStrings())
    val interaction = remember { MutableInteractionSource() }
    Box(
        Modifier
            .sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
            .then(
                if (onTap != null) Modifier
                    .clickable(interactionSource = interaction, indication = null, role = Role.Button) { onTap() }
                    .semantics { contentDescription = label }
                else Modifier,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Row(
            Modifier
                .shadow(8.dp, RoundedCornerShape(999.dp), clip = false)
                .clip(RoundedCornerShape(999.dp))
                .background(colors.bgPrimary)
                .border(1.dp, colors.borderPrimary, RoundedCornerShape(999.dp))
                .indication(interaction, LocalIndication.current)
                .padding(start = if (hasCount) FlareSizes.spacingMd else FlareSizes.spacingSm, end = FlareSizes.spacing2xs, top = FlareSizes.spacing2xs, bottom = FlareSizes.spacing2xs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (hasCount) {
                Text(if (count > 99) "99+" else "$count", color = colors.primaryText,
                    fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = if (onTap != null) Modifier.clearAndSetSemantics {} else Modifier)
                Spacer(Modifier.width(6.dp))
            }
            Box(Modifier.size(30.dp).clip(CircleShape).background(colors.primary), contentAlignment = Alignment.Center) {
                Icon(Icons.Outlined.ArrowDownward, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }
        }
    }
}
