package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Public
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

// MARK: - TopicChip

/** Inline #topic hashtag. Spec: Moments/TopicChip. */
@Composable
fun TopicChip(topic: String, onTap: (() -> Unit)? = null) {
    val colors = flareColors()
    Text(
        "#$topic",
        color = colors.primary,
        fontWeight = FontWeight.Medium,
        modifier = if (onTap != null) Modifier.clickable { onTap() } else Modifier,
    )
}

// MARK: - CommentThread

/** Comment list under a moment. Spec: Moments/CommentThread. */
@Composable
fun CommentThread(
    comments: List<MomentComment>,
    onSelect: ((MomentComment) -> Unit)? = null,
    onSelectAuthor: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    Column {
        comments.forEach { c ->
            val line = buildAnnotatedString {
                withStyle(SpanStyle(color = colors.primary, fontWeight = FontWeight.Medium)) { append(c.author.name) }
                if (c.replyToName != null) {
                    withStyle(SpanStyle(color = colors.textTertiary)) { append(" replying to ") }
                    withStyle(SpanStyle(color = colors.primary, fontWeight = FontWeight.Medium)) { append(c.replyToName) }
                }
                withStyle(SpanStyle(color = colors.textTertiary)) { append("：") }
                withStyle(SpanStyle(color = colors.textPrimary)) { append(c.text) }
            }
            Text(
                line, fontSize = 13.sp,
                modifier = Modifier.fillMaxWidth()
                    .then(if (onSelect != null) Modifier.clickable { onSelect(c) } else Modifier)
                    .padding(vertical = 3.dp),
            )
        }
    }
}

// MARK: - MomentActionPopover

/**
 * Dark like/comment capsule from the ··· button. Spec: Moments/MomentActionPopover.
 *
 * [canDelete] adds a trailing destructive **Delete** action — shown only for the current user's own
 * moments (parity with `FlareMomentActionPopover.vue`'s `canDelete` gate).
 */
@Composable
fun MomentActionPopover(
    liked: Boolean,
    canDelete: Boolean = false,
    onLike: (() -> Unit)? = null,
    onComment: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
) {
    Row(
        Modifier.height(34.dp).clip(RoundedCornerShape(8.dp)).background(Color(0xFF2C2B33)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.fillMaxSize().weight(1f, fill = false).clickable { onLike?.invoke() }.padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(if (liked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder, contentDescription = null,
                tint = Color(0xFFF2F0F7), modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(5.dp))
            Text(if (liked) "Unlike" else "Like", color = Color(0xFFF2F0F7), fontSize = 13.sp)
        }
        Box(Modifier.width(1.dp).height(18.dp).background(Color.White.copy(alpha = 0.16f)))
        Row(
            Modifier.fillMaxSize().weight(1f, fill = false).clickable { onComment?.invoke() }.padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.ChatBubbleOutline, contentDescription = null,
                tint = Color(0xFFF2F0F7), modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(5.dp))
            Text("Comment", color = Color(0xFFF2F0F7), fontSize = 13.sp)
        }
        if (canDelete) {
            Box(Modifier.width(1.dp).height(18.dp).background(Color.White.copy(alpha = 0.16f)))
            Row(
                Modifier.fillMaxSize().weight(1f, fill = false).clickable { onDelete?.invoke() }.padding(horizontal = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.DeleteOutline, contentDescription = null,
                    tint = Color(0xFFFF8A80), modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(5.dp))
                Text("Delete", color = Color(0xFFFF8A80), fontSize = 13.sp)
            }
        }
    }
}

// MARK: - MomentsCoverHeader

/** Profile cover header with overlapping avatar. Spec: Moments/MomentsCoverHeader. */
@Composable
fun MomentsCoverHeader(
    userId: String,
    name: String,
    coverUrl: String? = null,
    avatarUrl: String? = null,
    signature: String? = null,
    onEditCover: (() -> Unit)? = null,
    onAvatar: (() -> Unit)? = null,
) {
    // White text over the cover — legible on any photo. A soft shadow lifts each glyph off the image.
    val titleShadow = Shadow(color = Color(0x73000000), offset = Offset(0f, 1f), blurRadius = 6f)
    val sigShadow = Shadow(color = Color(0x66000000), offset = Offset(0f, 1f), blurRadius = 4f)
    Column(Modifier.fillMaxWidth().padding(bottom = 20.dp)) {
        Box(
            Modifier.fillMaxWidth().height(240.dp)
                .background(Brush.linearGradient(listOf(Color(0xFF3B1F7A), Color(0xFF7C3AED), Color(0xFFA78BFA))))
                .clickable { onEditCover?.invoke() },
        ) {
            if (coverUrl != null) {
                AsyncImage(model = coverUrl, contentDescription = null,
                    modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
            }
            // Bottom scrim so the name + signature stay legible over any cover image.
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(
                        0.45f to Color.Transparent,
                        1f to Color(0x6B0F0C19),
                    ),
                ),
            )
            // 换封面 — top-right, clear of the avatar. Its own tap target over the whole-cover click.
            Row(
                Modifier.align(Alignment.TopEnd).padding(14.dp)
                    .clip(RoundedCornerShape(999.dp)).background(Color(0x520F0C19))
                    .clickable { onEditCover?.invoke() }
                    .padding(horizontal = 11.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.Image, contentDescription = null,
                    tint = Color.White.copy(alpha = 0.92f), modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(4.dp))
                Text("换封面", color = Color.White.copy(alpha = 0.92f), fontSize = 12.sp)
            }
        }
        Row(
            Modifier.fillMaxWidth().offset(y = (-30).dp).padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.Bottom,
        ) {
            Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1f).padding(bottom = 6.dp)) {
                Text(name, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 17.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                    style = TextStyle(shadow = titleShadow))
                signature?.let {
                    Text(it, color = Color.White.copy(alpha = 0.88f), fontSize = 12.sp, maxLines = 1,
                        overflow = TextOverflow.Ellipsis, style = TextStyle(shadow = sigShadow),
                        modifier = Modifier.padding(top = 4.dp))
                }
            }
            Spacer(Modifier.width(12.dp))
            // Borderless avatar — a soft shadow + rounded-square lifts it off the cover (no white frame).
            Box(
                Modifier.shadow(10.dp, RoundedCornerShape(15.dp), clip = false)
                    .clip(RoundedCornerShape(15.dp))
                    .clickable { onAvatar?.invoke() },
            ) {
                Avatar(userId = userId, displayName = name, size = 64.dp)
            }
        }
    }
}

// MARK: - MomentComposer

/** Compose a moment. Spec: Moments/MomentComposer. */
@Composable
fun MomentComposer(
    images: List<String> = emptyList(),
    maxImages: Int = 9,
    location: String? = null,
    visibility: String? = null,
    busy: Boolean = false,
    onSubmit: ((String) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
    onAddImage: (() -> Unit)? = null,
    onRemoveImage: ((Int) -> Unit)? = null,
    onPickLocation: (() -> Unit)? = null,
    onPickVisibility: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var text by remember { mutableStateOf("") }
    val canPost = text.trim().isNotEmpty() || images.isNotEmpty()

    Column(
        Modifier.width(360.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Cancel", color = colors.textSecondary, fontSize = 14.sp,
                modifier = Modifier.clickable { onCancel?.invoke() })
            Spacer(Modifier.weight(1f))
            Box(
                Modifier.clip(RoundedCornerShape(999.dp)).background(colors.primary)
                    .then(if (canPost && !busy) Modifier.clickable { onSubmit?.invoke(text.trim()) } else Modifier)
                    .padding(horizontal = 18.dp, vertical = 6.dp),
            ) {
                Text("Post", color = Color.White.copy(alpha = if (canPost && !busy) 1f else 0.45f),
                    fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        BasicTextField(
            value = text, onValueChange = { text = it },
            textStyle = TextStyle(color = colors.textPrimary, fontSize = 15.sp),
            cursorBrush = SolidColor(colors.primary),
            modifier = Modifier.fillMaxWidth().heightIn(min = 96.dp).padding(14.dp),
            decorationBox = { inner ->
                if (text.isEmpty()) Text("What's on your mind…", color = colors.textTertiary, fontSize = 15.sp)
                inner()
            },
        )
        // image grid (4-col rows)
        val cells = images.take(maxImages)
        val showAdd = images.size < maxImages
        Column(Modifier.padding(horizontal = 14.dp).padding(bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            val items = cells.indices.toList()
            val rows = (items + if (showAdd) listOf(-1) else emptyList()).chunked(4)
            rows.forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    row.forEach { idx ->
                        if (idx >= 0) {
                            Box(Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(8.dp)).background(colors.bgSecondary)) {
                                AsyncImage(model = images[idx], contentDescription = null,
                                    modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                                Box(
                                    Modifier.align(Alignment.TopEnd).padding(2.dp).size(18.dp).clip(CircleShape)
                                        .background(Color.Black.copy(alpha = 0.55f)).clickable { onRemoveImage?.invoke(idx) },
                                    contentAlignment = Alignment.Center,
                                ) { Icon(Icons.Outlined.Close, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp)) }
                            }
                        } else {
                            Box(
                                Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(8.dp))
                                    .background(colors.bgSecondary)
                                    .border(1.dp, colors.borderHover, RoundedCornerShape(8.dp))
                                    .clickable { onAddImage?.invoke() },
                                contentAlignment = Alignment.Center,
                            ) { Icon(Icons.Outlined.Add, contentDescription = "Add photo", tint = colors.textTertiary, modifier = Modifier.size(26.dp)) }
                        }
                    }
                    repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        composerRow(colors, Icons.Outlined.LocationOn, location ?: "Location") { onPickLocation?.invoke() }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        composerRow(colors, Icons.Outlined.Public, visibility ?: "Who can see") { onPickVisibility?.invoke() }
    }
}

@Composable
private fun composerRow(colors: FlareColors, icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onClick() }.padding(horizontal = 14.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(10.dp))
        Text(label, color = colors.textSecondary, fontSize = 14.sp)
    }
}

// MARK: - MomentCard

/** Social-feed moment card. Spec: Moments/MomentCard. */
@Composable
fun MomentCard(
    moment: Moment,
    canDelete: Boolean = false,
    onLike: (() -> Unit)? = null,
    onComment: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
    onOpenImage: ((Int) -> Unit)? = null,
    onSelectAuthor: ((String) -> Unit)? = null,
    onSelectLiker: ((String) -> Unit)? = null,
    onSelectComment: ((MomentComment) -> Unit)? = null,
) {
    val colors = flareColors()
    var menuOpen by remember { mutableStateOf(false) }
    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(colors.bgElevated).padding(16.dp)) {
        Box(Modifier.clickable { onSelectAuthor?.invoke(moment.author.id) }) {
            Avatar(
                userId = moment.author.id, displayName = moment.author.name, size = 42.dp,
                image = moment.author.avatarUrl?.let { url ->
                    { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                },
            )
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(moment.author.name, color = colors.primary, fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                modifier = Modifier.clickable { onSelectAuthor?.invoke(moment.author.id) })
            moment.text?.let {
                Text(it, color = colors.textPrimary, fontSize = 15.sp, modifier = Modifier.padding(top = 4.dp))
            }
            if (moment.images.isNotEmpty()) {
                Box(Modifier.padding(top = 10.dp)) { ImageGrid(images = moment.images, onOpen = onOpenImage) }
            }
            moment.location?.let {
                Row(Modifier.padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.LocationOn, contentDescription = null, tint = colors.primary.copy(alpha = 0.8f), modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(3.dp))
                    Text(it, color = colors.primary.copy(alpha = 0.8f), fontSize = 12.sp)
                }
            }
            Row(Modifier.fillMaxWidth().padding(top = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(moment.time ?: "", color = colors.textTertiary, fontSize = 12.sp)
                Spacer(Modifier.weight(1f))
                if (menuOpen) {
                    MomentActionPopover(
                        liked = moment.likedBySelf,
                        canDelete = canDelete,
                        onLike = { menuOpen = false; onLike?.invoke() },
                        onComment = { menuOpen = false; onComment?.invoke() },
                        onDelete = { menuOpen = false; onDelete?.invoke() },
                    )
                    Spacer(Modifier.width(6.dp))
                }
                Box(
                    Modifier.size(width = 30.dp, height = 24.dp).clip(RoundedCornerShape(6.dp))
                        .background(if (menuOpen) colors.bgSelected else colors.bgSecondary)
                        .clickable { menuOpen = !menuOpen },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Outlined.MoreHoriz, contentDescription = "More", tint = if (menuOpen) colors.primary else colors.textSecondary, modifier = Modifier.size(16.dp)) }
            }
            if (moment.likes.isNotEmpty() || moment.comments.isNotEmpty()) {
                Column(
                    Modifier.fillMaxWidth().padding(top = 10.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(colors.bgSecondary).padding(horizontal = 12.dp, vertical = 8.dp),
                ) {
                    if (moment.likes.isNotEmpty()) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.FavoriteBorder, contentDescription = null, tint = colors.error, modifier = Modifier.size(14.dp))
                            Spacer(Modifier.width(6.dp))
                            val likers = buildAnnotatedString {
                                moment.likes.forEachIndexed { i, l ->
                                    withStyle(SpanStyle(color = colors.primary)) { append(l.name) }
                                    if (i < moment.likes.size - 1) withStyle(SpanStyle(color = colors.primary)) { append(", ") }
                                }
                            }
                            Text(likers, fontSize = 13.sp)
                        }
                    }
                    if (moment.likes.isNotEmpty() && moment.comments.isNotEmpty()) {
                        Box(Modifier.fillMaxWidth().padding(vertical = 7.dp).height(1.dp).background(colors.textTertiary.copy(alpha = 0.22f)))
                    }
                    if (moment.comments.isNotEmpty()) {
                        CommentThread(comments = moment.comments, onSelect = onSelectComment, onSelectAuthor = onSelectAuthor)
                    }
                }
            }
        }
    }
}
