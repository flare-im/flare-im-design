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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.height
import androidx.compose.material3.HorizontalDivider
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.LiveRegionMode

/** Lucky-money red packet card. Spec: Message/RedPacketCard. */
@Composable
fun RedPacketCard(
    blessing: String,
    amount: String? = null,
    opened: Boolean = false,
    finished: Boolean = false,
    disabled: Boolean = false,
    busy: Boolean = false,
    statusLabel: String? = null,
    onOpen: (() -> Unit)? = null,
) {
    val gold = Color(0xFFFFE9B8)
    val deepRed = Color(0xFFC8291F)
    val strings = flareStrings()
    val status = when {
        busy -> strings.packetBusy
        statusLabel != null -> statusLabel
        opened && amount != null -> strings.packetClaimed(amount)
        finished -> strings.packetFinished
        disabled -> strings.packetUnavailable
        else -> strings.packetTapToClaim
    }
    val canOpen = !finished && !disabled && !busy && onOpen != null
    Box(
        Modifier.widthIn(max = 248.dp).fillMaxWidth().heightIn(min = 48.dp)
            .alpha(if (finished) 0.65f else 1f)
            .shadow(10.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false, ambientColor = deepRed, spotColor = deepRed)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(Brush.linearGradient(listOf(Color(0xFFF0503C), Color(0xFFE23B2E), Color(0xFFC8291F))))
            .semantics(mergeDescendants = true) {
                stateDescription = status
                if (busy) liveRegion = LiveRegionMode.Polite
            }
            .clickable(enabled = canOpen, role = Role.Button) { if (canOpen) onOpen?.invoke() }
            .padding(FlareSizes.spacing2md),
    ) {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.size(42.dp).clip(CircleShape)
                        .background(Brush.radialGradient(listOf(gold, Color(0xFFF6C453)))),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Outlined.CardGiftcard, contentDescription = null, tint = deepRed, modifier = Modifier.size(22.dp))
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(blessing, color = Color.White, fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(status, color = if (!busy && statusLabel == null && opened && amount != null) gold else Color(0xFFFFECD2).copy(alpha = 0.85f),
                        fontSize = 12.sp, modifier = Modifier.padding(top = 3.dp))
                }
            }
            Spacer(Modifier.height(FlareSizes.spacingSm))
            HorizontalDivider(color = Color.White.copy(alpha = 0.28f))
            Text(strings.packetBrand, color = Color(0xFFFFECD2).copy(alpha = 0.7f), fontSize = FlareSizes.fontSize2xs,
                textAlign = TextAlign.End, modifier = Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm))
        }
    }
}
