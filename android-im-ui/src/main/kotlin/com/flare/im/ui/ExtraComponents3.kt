package com.flare.im.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MicOff
import androidx.compose.material.icons.outlined.OpenInFull
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material.icons.outlined.Videocam
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: - ForwardPicker

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

// MARK: - Toast

enum class ToastVariant { Info, Success, Error, Warning, Loading }

/** Lightweight feedback toast. Spec: General/Toast. */
@Composable
fun Toast(
    message: String,
    variant: ToastVariant = ToastVariant.Info,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val (icon, tint) = when (variant) {
        ToastVariant.Info -> Icons.Outlined.Info to colors.primary
        ToastVariant.Success -> Icons.Filled.CheckCircle to colors.success
        ToastVariant.Error -> Icons.Filled.Cancel to colors.error
        ToastVariant.Warning -> Icons.Filled.Warning to colors.warning
        ToastVariant.Loading -> Icons.Outlined.Sync to colors.textSecondary
    }
    val spin = rememberInfiniteTransition(label = "toast")
    val angle by spin.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(900, easing = LinearEasing), RepeatMode.Restart),
        label = "spin",
    )
    Row(
        Modifier.widthIn(max = 420.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg))
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = tint,
            modifier = Modifier.size(18.dp)
                .then(if (variant == ToastVariant.Loading) Modifier.rotate(angle) else Modifier))
        Spacer(Modifier.width(10.dp))
        Text(message, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp, modifier = Modifier.weight(1f, fill = false))
        if (actionLabel != null) {
            Spacer(Modifier.width(10.dp))
            Text(actionLabel, color = colors.primary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.clickable { onAction?.invoke() })
        }
    }
}

// MARK: - CallDock

/** Minimized floating call bar. Spec: Call/CallDock. */
@Composable
fun CallDock(
    title: String,
    avatarUrl: String? = null,
    durationLabel: String? = null,
    mode: FlareCallMode = FlareCallMode.Audio,
    muted: Boolean = false,
    onExpand: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(Brush.linearGradient(listOf(Color(0xFF2A2438), Color(0xFF191320))))
            .padding(start = 8.dp, top = 8.dp, bottom = 8.dp, end = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.clickable { onExpand?.invoke() },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(contentAlignment = Alignment.Center) {
                Avatar(userId = title, displayName = title, size = 34.dp)
                Box(Modifier.size(40.dp).clip(CircleShape).border(2.dp, colors.success, CircleShape))
            }
            Spacer(Modifier.width(10.dp))
            Column {
                Text(title, color = Color.White, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeMd.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.widthIn(max = 120.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (mode == FlareCallMode.Video) Icons.Outlined.Videocam else Icons.Outlined.Call,
                        contentDescription = null, tint = Color.White.copy(alpha = 0.66f), modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(durationLabel ?: flareStrings().callConnected, color = Color.White.copy(alpha = 0.66f), fontSize = 12.sp)
                }
            }
            Spacer(Modifier.width(2.dp))
            Icon(Icons.Outlined.OpenInFull, contentDescription = null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(10.dp))
        Box(
            Modifier.size(36.dp).clip(CircleShape)
                .background(if (muted) Color.White else Color.White.copy(alpha = 0.14f))
                .clickable { onToggleMute?.invoke() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(if (muted) Icons.Outlined.MicOff else Icons.Outlined.Mic, contentDescription = flareStrings().microphone,
                tint = if (muted) Color(0xFF17131F) else Color.White, modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(6.dp))
        Box(
            Modifier.size(36.dp).clip(CircleShape).background(colors.error).clickable { onHangup?.invoke() },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Call, contentDescription = flareStrings().hangUp, tint = Color.White,
                modifier = Modifier.size(18.dp).rotate(135f))
        }
    }
}

// MARK: - AnnouncementBanner

/** Pinned group announcement banner. Spec: Message/AnnouncementBanner. */
@Composable
fun AnnouncementBanner(
    text: String,
    author: String? = null,
    collapsible: Boolean = true,
    dismissible: Boolean = false,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var expanded by remember { mutableStateOf(false) }
    val showToggle = collapsible && text.length > 40
    Row(
        Modifier.clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSelected)
            .border(1.dp, colors.primary.copy(alpha = 0.22f), RoundedCornerShape(FlareSizes.radiusLg))
            .padding(horizontal = 12.dp, vertical = 11.dp),
    ) {
        Box(
            Modifier.size(26.dp).clip(RoundedCornerShape(8.dp)).background(colors.primary),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Campaign, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Row {
                Text(flareStrings().groupAnnouncement, color = colors.primary, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                author?.let {
                    Text(" · $it", color = colors.textTertiary, fontSize = 12.sp)
                }
            }
            Text(text, color = colors.textPrimary, fontSize = 13.sp,
                maxLines = if (showToggle && !expanded) 1 else Int.MAX_VALUE,
                overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 3.dp))
            if (showToggle) {
                Row(
                    Modifier.padding(top = 4.dp).clickable { expanded = !expanded },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(if (expanded) flareStrings().collapse else flareStrings().expand, color = colors.primary, fontSize = 12.sp)
                    Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = colors.primary,
                        modifier = Modifier.size(14.dp).rotate(if (expanded) 180f else 0f))
                }
            }
        }
        if (dismissible) {
            Spacer(Modifier.width(6.dp))
            Icon(Icons.Outlined.Close, contentDescription = flareStrings().close, tint = colors.textTertiary,
                modifier = Modifier.size(16.dp).align(Alignment.Top).clickable { onClose?.invoke() })
        }
    }
}

// MARK: - DatePill

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
