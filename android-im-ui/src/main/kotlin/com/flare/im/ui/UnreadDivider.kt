package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Unread divider — the "N new messages" line. Spec: Message/UnreadDivider. */
@Composable
fun UnreadDivider(count: Int = 0) {
    val colors = flareColors()
    val text = flareStrings().newMessages(count)
    Row(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.weight(1f).height(1.dp).background(colors.primary.copy(alpha = 0.24f)))
        Text(text, color = colors.primary, fontWeight = FontWeight.Medium,
            fontSize = FlareSizes.fontSizeSm.value.sp,
            modifier = Modifier.padding(horizontal = FlareSizes.spacingMd))
        Box(Modifier.weight(1f).height(1.dp).background(colors.primary.copy(alpha = 0.24f)))
    }
}
