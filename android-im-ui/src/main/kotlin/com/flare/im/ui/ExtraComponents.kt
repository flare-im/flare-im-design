package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.VideocamOff
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Typing indicator — bouncing dots. Spec: Message/TypingIndicator. */
enum class TypingVariant { Bubble, Inline }

@Composable
fun TypingIndicator(
    names: List<String> = emptyList(),
    userId: String? = null,
    variant: TypingVariant = TypingVariant.Bubble,
) {
    val colors = flareColors()
    val clean = names.filter { it.isNotEmpty() }
    val label = when {
        clean.isEmpty() -> "typing…"
        clean.size == 1 -> "${clean[0]} is typing…"
        else -> "${clean.size} people typing…"
    }
    val isBubble = variant == TypingVariant.Bubble
    val dotColor = if (isBubble) colors.primary.copy(alpha = 0.65f) else colors.textTertiary

    val transition = rememberInfiniteTransition(label = "typing")
    val body: @Composable () -> Unit = {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (variant == TypingVariant.Inline || names.isNotEmpty()) {
                Text(label, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
                Spacer(Modifier.width(8.dp))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                repeat(3) { i ->
                    val y by transition.animateFloat(
                        initialValue = 0f, targetValue = -4f,
                        animationSpec = infiniteRepeatable(
                            tween(durationMillis = 600, delayMillis = i * 150), RepeatMode.Reverse),
                        label = "dot$i",
                    )
                    Box(Modifier.offset(y = y.dp).size(6.dp).clip(CircleShape).background(dotColor))
                }
            }
        }
    }

    if (!isBubble) {
        body()
    } else {
        Row(verticalAlignment = Alignment.Bottom) {
            Avatar(userId = names.firstOrNull() ?: (userId ?: "typing"),
                displayName = names.firstOrNull() ?: (userId ?: "typing"), size = 32.dp)
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Box(
                Modifier.clip(RoundedCornerShape(4.dp, 16.dp, 16.dp, 16.dp))
                    .background(colors.bgPrimary)
                    .border(1.dp, colors.borderPrimary, RoundedCornerShape(4.dp, 16.dp, 16.dp, 16.dp))
                    .padding(horizontal = 14.dp, vertical = 10.dp),
            ) { body() }
        }
    }
}

/** Unread divider — the "N new messages" line. Spec: Message/UnreadDivider. */
@Composable
fun UnreadDivider(count: Int = 0) {
    val colors = flareColors()
    val text = if (count > 0) "$count new messages" else "New messages"
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

/** Mini profile card. Spec: Profile/ProfileCard. */
@Composable
fun ProfileCard(
    user: Contact,
    onMessage: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
    onVideo: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val meta = buildList {
        add("Flare ID · ${user.id}")
        if (!user.region.isNullOrEmpty()) add(user.region)
    }.joinToString(" · ")
    Column(
        Modifier.width(260.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl))
            .padding(FlareSizes.spacingLg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Avatar(userId = user.id, displayName = user.name, size = 56.dp, presence = user.presence)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Text(user.name, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSize2xl.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (!user.signature.isNullOrEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Text(user.signature, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
        Spacer(Modifier.height(FlareSizes.spacingSm))
        Text(meta, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
            maxLines = 1, overflow = TextOverflow.Ellipsis)
        if (user.tags.isNotEmpty()) {
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                user.tags.forEach { t ->
                    Text(t, color = colors.primary, fontSize = FlareSizes.fontSizeXs.value.sp,
                        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSelected)
                            .padding(horizontal = 9.dp, vertical = 2.dp))
                }
            }
        }
        Spacer(Modifier.height(FlareSizes.spacingLg))
        Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            cardAction(colors, Icons.Outlined.ChatBubbleOutline, "Message", onMessage, primary = true, modifier = Modifier.weight(1f))
            cardAction(colors, Icons.Outlined.Call, null, onCall)
            cardAction(colors, Icons.Outlined.Videocam, null, onVideo)
        }
    }
}

@Composable
private fun cardAction(
    colors: FlareColors,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String?,
    onTap: (() -> Unit)?,
    primary: Boolean = false,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier
            .then(if (label == null) Modifier.width(44.dp) else Modifier)
            .height(38.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(if (primary) colors.primary else colors.bgSecondary)
            .then(if (onTap != null) Modifier.clickable { onTap() } else Modifier)
            .padding(horizontal = 10.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = label, tint = if (primary) Color.White else colors.textPrimary,
            modifier = Modifier.size(17.dp))
        if (label != null) {
            Spacer(Modifier.width(6.dp))
            Text(label, color = if (primary) Color.White else colors.textPrimary,
                fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
    }
}

/** Group member grid. Spec: Contacts/GroupMemberGrid. */
@Composable
fun GroupMemberGrid(
    members: List<Contact>,
    ownerId: String? = null,
    adminIds: List<String> = emptyList(),
    showAdd: Boolean = true,
    columns: Int = 5,
    onSelect: ((String) -> Unit)? = null,
    onAddMember: (() -> Unit)? = null,
    title: String = "群成员",
    ownerLabel: String = "群主",
    adminLabel: String = "管理员",
    addLabel: String = "加成员",
    memberCountText: (Int) -> String = { "$it 名成员" },
) {
    val colors = flareColors()
    fun role(m: Contact): String? = when {
        m.id == ownerId -> ownerLabel
        adminIds.contains(m.id) -> adminLabel
        else -> null
    }
    Column(Modifier.padding(FlareSizes.spacingLg)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeLg.value.sp)
            Text(memberCountText(members.size), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
        Spacer(Modifier.height(14.dp))
        LazyVerticalGrid(
            columns = GridCells.Fixed(columns),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.height(((members.size + (if (showAdd) 1 else 0) + columns - 1) / columns * 84).dp),
        ) {
            items(members, key = { it.id }) { m ->
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = if (onSelect != null) Modifier.clickable { onSelect(m.id) } else Modifier) {
                    Box(contentAlignment = Alignment.BottomCenter) {
                        Avatar(userId = m.id, displayName = m.name, size = 48.dp)
                        role(m)?.let { r ->
                            Text(r, color = Color.White, fontSize = 10.sp,
                                modifier = Modifier.offset(y = 6.dp).clip(RoundedCornerShape(999.dp))
                                    .background(if (m.id == ownerId) colors.warning else colors.textTertiary)
                                    .padding(horizontal = 6.dp, vertical = 1.dp))
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Text(m.name, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            if (showAdd) {
                item {
                    Column(horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = if (onAddMember != null) Modifier.clickable { onAddMember() } else Modifier) {
                        Box(Modifier.size(48.dp).clip(CircleShape)
                            .border(BorderStroke(1.dp, colors.borderHover), CircleShape),
                            contentAlignment = Alignment.Center) {
                            Icon(Icons.Outlined.Add, contentDescription = addLabel, tint = colors.textTertiary,
                                modifier = Modifier.size(22.dp))
                        }
                        Spacer(Modifier.height(8.dp))
                        Text(addLabel, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
            }
        }
    }
}

/** Group (multi-party) call — participant grid + controls. Spec: Call/GroupCallView. */
@Composable
fun GroupCallView(
    participants: List<CallParticipant>,
    mode: FlareCallMode,
    state: String,
    title: String? = null,
    durationLabel: String? = null,
    muted: Boolean = false,
    cameraOn: Boolean = true,
    speakerOn: Boolean = false,
    onHangup: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onToggleCamera: (() -> Unit)? = null,
    onToggleSpeaker: (() -> Unit)? = null,
    onSwitchCamera: (() -> Unit)? = null,
    onMinimize: (() -> Unit)? = null,
) {
    val cols = when {
        participants.size <= 1 -> 1
        participants.size <= 4 -> 2
        participants.size <= 9 -> 3
        else -> 4
    }
    val status = when (state) {
        "connected" -> durationLabel ?: "Connected"
        "ringing" -> "Ringing…"
        else -> "Calling…"
    }
    Column(
        Modifier.fillMaxWidth().background(
            Brush.verticalGradient(listOf(Color(0xFF211D30), Color(0xFF17131F), Color(0xFF100C17)))),
    ) {
        Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(36.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.12f))
                .then(if (onMinimize != null) Modifier.clickable { onMinimize() } else Modifier),
                contentAlignment = Alignment.Center) {
                Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column {
                Text(title ?: "群通话", color = Color.White, fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text("${participants.size} 人已加入 · $status", color = Color.White.copy(alpha = 0.62f), fontSize = 12.sp)
            }
        }
        LazyVerticalGrid(
            columns = GridCells.Fixed(cols),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
            modifier = Modifier.weight(1f),
        ) {
            items(participants, key = { it.id }) { p -> callTile(p, mode) }
        }
        Box(Modifier.fillMaxWidth().padding(vertical = 20.dp), contentAlignment = Alignment.Center) {
            CallControls(muted = muted, cameraOn = cameraOn, speakerOn = speakerOn, mode = mode,
                onToggleMute = onToggleMute, onToggleCamera = onToggleCamera, onToggleSpeaker = onToggleSpeaker,
                onSwitchCamera = onSwitchCamera, onHangup = onHangup)
        }
    }
}

@Composable
private fun callTile(p: CallParticipant, mode: FlareCallMode) {
    Box(
        Modifier.aspectRatio(0.86f).clip(RoundedCornerShape(16.dp))
            .background(if (p.isSelf) Color(0x297C3AED) else Color.White.copy(alpha = 0.06f))
            .border(2.dp, if (p.speaking) Color(0xFF34D17F) else Color.Transparent, RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Avatar(userId = p.id, displayName = p.name, size = 56.dp)
        Row(Modifier.align(Alignment.BottomStart).padding(8.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            if (p.muted) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.MicOff, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            } else if (p.cameraOff && mode == FlareCallMode.Video) {
                Box(Modifier.size(20.dp).clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f)),
                    contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.VideocamOff, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
                }
            }
            Text(if (p.isSelf) "${p.name} (me)" else p.name, color = Color.White, fontSize = 12.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(Color.Black.copy(alpha = 0.42f))
                    .padding(horizontal = 8.dp, vertical = 2.dp))
        }
    }
}
