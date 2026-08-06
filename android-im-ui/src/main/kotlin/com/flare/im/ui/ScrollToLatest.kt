package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Scroll-to-latest pill. Spec: Message/ScrollToLatest. */
@Composable
fun ScrollToLatest(count: Int = 0, onTap: (() -> Unit)? = null) {
    val colors = flareColors()
    val hasCount = count > 0
    Row(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(999.dp))
            .then(if (onTap != null) Modifier.clickable { onTap() } else Modifier)
            .padding(start = if (hasCount) 12.dp else 8.dp, end = 6.dp, top = 6.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (hasCount) {
            Text(if (count > 99) "99+" else "$count", color = colors.primary,
                fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp)
            Spacer(Modifier.width(6.dp))
        }
        Box(Modifier.size(30.dp).clip(CircleShape).background(colors.primary), contentAlignment = Alignment.Center) {
            Icon(Icons.Outlined.ArrowDownward, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
        }
    }
}
