package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CardGiftcard
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Lucky-money red packet card. Spec: Message/RedPacketCard. */
@Composable
fun RedPacketCard(
    blessing: String,
    amount: String? = null,
    opened: Boolean = false,
    finished: Boolean = false,
    onOpen: (() -> Unit)? = null,
) {
    val gold = Color(0xFFFFE9B8)
    Box(
        Modifier.width(248.dp).clip(RoundedCornerShape(14.dp))
            .background(Brush.linearGradient(listOf(Color(0xFFF0503C), Color(0xFFE23B2E), Color(0xFFC8291F))))
            .then(if (!finished && onOpen != null) Modifier.clickable { onOpen() } else Modifier)
            .padding(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(42.dp).clip(CircleShape)
                    .background(Brush.radialGradient(listOf(gold, Color(0xFFF6C453)))),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Outlined.CardGiftcard, contentDescription = null, tint = Color(0xFFC8291F), modifier = Modifier.size(22.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(blessing, color = Color.White, fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                val status = when {
                    opened && amount != null -> flareStrings().packetClaimed(amount)
                    finished -> flareStrings().packetFinished
                    else -> flareStrings().packetTapToClaim
                }
                Text(status, color = if (opened && amount != null) gold else Color(0xFFFFECD2).copy(alpha = 0.85f),
                    fontSize = 12.sp, modifier = Modifier.padding(top = 3.dp))
            }
        }
        Text(flareStrings().packetBrand, color = Color(0xFFFFECD2).copy(alpha = 0.5f), fontSize = 10.sp,
            modifier = Modifier.align(Alignment.BottomEnd))
    }
}
