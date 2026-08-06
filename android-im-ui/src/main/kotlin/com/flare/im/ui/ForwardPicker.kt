package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Forward-target picker — search + multi-select + send. Spec: Conversation/ForwardPicker. */
@Composable
fun ForwardPicker(
    targets: List<ForwardTarget>,
    multiple: Boolean = true,
    dismissible: Boolean = true,
    onConfirm: ((List<String>) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var query by remember { mutableStateOf("") }
    val selected = remember { mutableStateListOf<String>() }
    val filtered = targets.filter {
        val q = query.trim().lowercase()
        q.isEmpty() || it.name.lowercase().contains(q) || (it.subtitle?.lowercase()?.contains(q) == true)
    }
    fun toggle(id: String) {
        if (!multiple) {
            selected.clear(); selected.add(id); return
        }
        if (selected.contains(id)) selected.remove(id) else selected.add(id)
    }

    Column(
        Modifier.width(340.dp).clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(start = 16.dp, end = 12.dp, top = 14.dp, bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(flareStrings().forwardTo, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeLg.value.sp)
            Spacer(Modifier.weight(1f))
            if (dismissible) {
                Icon(Icons.Outlined.Close, contentDescription = flareStrings().close, tint = colors.textTertiary,
                    modifier = Modifier.size(18.dp).clickable { onClose?.invoke() })
            }
        }
        // search
        Row(
            Modifier.padding(horizontal = 12.dp).fillMaxWidth()
                .clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary)
                .padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Search, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(8.dp))
            BasicTextField(
                value = query, onValueChange = { query = it }, singleLine = true,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 14.sp),
                cursorBrush = SolidColor(colors.primary),
                modifier = Modifier.weight(1f),
                decorationBox = { inner ->
                    if (query.isEmpty()) Text(flareStrings().searchConversations, color = colors.textTertiary, fontSize = 14.sp)
                    inner()
                },
            )
        }
        Column(Modifier.heightIn(max = 300.dp).verticalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 4.dp)) {
            filtered.forEach { tgt ->
                val on = selected.contains(tgt.id)
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(if (on) colors.bgSelected else Color.Transparent)
                        .clickable { toggle(tgt.id) }.padding(horizontal = 8.dp, vertical = 7.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier.size(20.dp).clip(CircleShape)
                            .background(if (on) colors.primary else Color.Transparent)
                            .border(1.5.dp, if (on) colors.primary else colors.borderHover, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        if (on) Icon(Icons.Outlined.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
                    }
                    Spacer(Modifier.width(10.dp))
                    Avatar(userId = tgt.id, displayName = tgt.name, size = 38.dp)
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text(tgt.name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                        tgt.subtitle?.let {
                            Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                                maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            }
            if (filtered.isEmpty()) {
                Text(flareStrings().noMatchingConversations, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.fillMaxWidth().padding(24.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        Row(
            Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(flareStrings().selectedCount(selected.size), color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
            Spacer(Modifier.weight(1f))
            val enabled = selected.isNotEmpty()
            Box(
                Modifier.height(36.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                    .background(if (enabled) colors.primary else colors.bgSecondary)
                    .then(if (enabled) Modifier.clickable { onConfirm?.invoke(selected.toList()) } else Modifier)
                    .padding(horizontal = 20.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(flareStrings().send, color = if (enabled) Color.White else colors.textTertiary,
                    fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeMd.value.sp)
            }
        }
    }
}
