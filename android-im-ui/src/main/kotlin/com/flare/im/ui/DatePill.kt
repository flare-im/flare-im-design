package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Floating day-divider chip. Spec: Message/DatePill. */
@Composable
fun DatePill(label: String, floating: Boolean = false) {
    val colors = flareColors()
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), horizontalArrangement = Arrangement.Center) {
        Text(
            label, color = colors.textSecondary, fontWeight = FontWeight.Medium, fontSize = 12.sp,
            modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgPrimary.copy(alpha = 0.78f))
                .border(1.dp, colors.borderPrimary, RoundedCornerShape(999.dp))
                .padding(horizontal = 12.dp, vertical = 3.dp),
        )
    }
}
