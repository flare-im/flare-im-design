package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Read receipt sheet with read/unread tabs. Spec: Message/ReadReceiptSheet. */
@Composable
fun ReadReceiptSheet(
    readers: List<Contact>,
    unread: List<Contact>,
    dismissible: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var tab by remember { mutableStateOf(0) }
    val list = if (tab == 0) readers else unread
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    Column(
        Modifier.width(320.dp)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.DoneAll, contentDescription = null, tint = colors.primary, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                flareStrings().readReceipt,
                color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeXl.value.sp,
                modifier = Modifier.weight(1f),
            )
            if (dismissible) {
                Icon(
                    Icons.Outlined.Close,
                    contentDescription = flareStrings().close,
                    tint = colors.textTertiary,
                    modifier = Modifier.size(18.dp)
                        .then(if (onClose != null) Modifier.clickable { onClose() } else Modifier),
                )
            }
        }
        Row(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg)) {
            receiptTab(colors, flareStrings().readTab(readers.size), tab == 0) { tab = 0 }
            receiptTab(colors, flareStrings().unreadTab(unread.size), tab == 1) { tab = 1 }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        if (list.isEmpty()) {
            Text(
                if (tab == 0) flareStrings().noReadersYet else flareStrings().everyoneHasRead,
                color = colors.textTertiary,
                fontSize = FlareSizes.fontSizeSm.value.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp),
            )
        } else {
            Column(Modifier.fillMaxWidth().heightIn(max = 320.dp).verticalScroll(rememberScrollState())) {
                list.forEach { c ->
                    Row(
                        Modifier.fillMaxWidth()
                            .then(if (onSelect != null) Modifier.clickable { onSelect(c.id) } else Modifier)
                            .padding(horizontal = FlareSizes.spacingLg, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Avatar(userId = c.id, displayName = c.name, size = 36.dp, presence = c.presence)
                        Spacer(Modifier.width(FlareSizes.spacingMd))
                        Text(
                            c.name,
                            color = colors.textPrimary,
                            fontSize = FlareSizes.fontSizeLg.value.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RowScope.receiptTab(colors: FlareColors, label: String, active: Boolean, onClick: () -> Unit) {
    Column(
        Modifier.weight(1f).clickable { onClick() }.padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            label,
            color = if (active) colors.primary else colors.textSecondary,
            fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
            fontSize = FlareSizes.fontSizeMd.value.sp,
        )
        Spacer(Modifier.height(6.dp))
        Box(Modifier.width(24.dp).height(2.dp).background(if (active) colors.primary else Color.Transparent))
    }
}
