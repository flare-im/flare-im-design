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
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Search
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** @-mention candidate picker with search. Spec: Composer/MentionPicker. */
@Composable
fun MentionPicker(
    candidates: List<MentionCandidate>,
    allowEveryone: Boolean = false,
    onSelect: ((MentionCandidate) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var query by remember { mutableStateOf("") }
    val q = query.trim().lowercase()
    val filtered = candidates.filter {
        q.isEmpty() || it.name.lowercase().contains(q) || (it.detail?.lowercase()?.contains(q) == true)
    }
    val showEveryone = allowEveryone && (q.isEmpty() || "everyone".contains(q))
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    Column(
        Modifier.width(280.dp)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Search, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(8.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) {
                    Text(flareStrings().searchMembers, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
                }
                BasicTextField(
                    value = query,
                    onValueChange = { query = it },
                    singleLine = true,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp),
                    cursorBrush = SolidColor(colors.primary),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        val everyoneName = flareStrings().everyone
        Column(Modifier.fillMaxWidth().heightIn(max = 264.dp).verticalScroll(rememberScrollState())) {
            if (showEveryone) {
                Row(
                    Modifier.fillMaxWidth()
                        .then(
                            if (onSelect != null) {
                                Modifier.clickable {
                                    onSelect(MentionCandidate(id = "__all__", name = everyoneName, isEveryone = true))
                                }
                            } else {
                                Modifier
                            },
                        )
                        .padding(horizontal = FlareSizes.spacingMd, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier.size(32.dp).clip(CircleShape).background(colors.primary),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Outlined.People, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                    }
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column {
                        Text(flareStrings().everyone, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium)
                        Text(flareStrings().notifyEveryone, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
            }
            filtered.forEach { c ->
                Row(
                    Modifier.fillMaxWidth()
                        .then(if (onSelect != null) Modifier.clickable { onSelect(c) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingMd, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(userId = c.id, displayName = c.name, size = 32.dp)
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column {
                        Text(c.name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                        if (!c.detail.isNullOrEmpty()) {
                            Text(c.detail, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                                maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            }
            if (!showEveryone && filtered.isEmpty()) {
                Text(
                    flareStrings().noMatchingMembers,
                    color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp),
                )
            }
        }
    }
}
