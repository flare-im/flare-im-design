package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Flag
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
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
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
        color = colors.primaryText,
        fontWeight = FontWeight.Medium,
        modifier = if (onTap != null) Modifier.clickable { onTap() } else Modifier,
    )
}

// MARK: - CommentThread

/**
 * Comment list under a moment. Spec: Moments/CommentThread.
 *
 * A comment row is a control only when the host replies to it ([onSelect]), named "回复 {name}：{text}"
 * ([FlareStrings.momentReplyToComment]); otherwise it is plain text. Inside such a row, a tap on the author's name
 * opens the author when [onSelectAuthor] is handled — a pointer shortcut, since a control cannot hold another one.
 * Names read in the accessible primary text colour.
 */
@Composable
fun CommentThread(
    comments: List<MomentComment>,
    onSelect: ((MomentComment) -> Unit)? = null,
    onSelectAuthor: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val nameStyle = SpanStyle(color = colors.primaryText, fontWeight = FontWeight.Medium)
    Column {
        comments.forEach { c ->
            val authorShortcut = if (onSelect != null) onSelectAuthor else null
            val line = buildAnnotatedString {
                if (authorShortcut != null) {
                    withLink(LinkAnnotation.Clickable("author:${c.author.id}", TextLinkStyles(nameStyle)) { authorShortcut(c.author.id) }) { append(c.author.name) }
                } else {
                    withStyle(nameStyle) { append(c.author.name) }
                }
                if (c.replyToName != null) {
                    withStyle(SpanStyle(color = colors.textTertiary)) { append(" ${strings.momentReplyTo} ") }
                    withStyle(nameStyle) { append(c.replyToName) }
                }
                withStyle(SpanStyle(color = colors.textTertiary)) { append("：") }
                withStyle(SpanStyle(color = colors.textPrimary)) { append(c.text) }
            }
            val row = if (onSelect != null) {
                Modifier.clearAndSetSemantics {
                    contentDescription = strings.momentReplyToComment(c.author.name, c.text)
                    role = Role.Button
                    onClick { onSelect(c); true }
                }.clickable { onSelect(c) }
            } else Modifier
            Text(
                line, fontSize = FlareSizes.fontSizeMd,
                modifier = Modifier.fillMaxWidth().then(row).padding(vertical = 3.dp),
            )
        }
    }
}

// MARK: - MomentActionPopover

/**
 * Dark like/comment capsule from the ··· button. Spec: Moments/MomentActionPopover.
 *
 * [canDelete] adds a trailing destructive **Delete** action — shown only for the current user's own
 * moments; [canReport] adds **Report** in the same slot for everyone else's (parity with
 * `FlareMomentActionPopover.vue`'s `canDelete` / `canReport` gates).
 *
 * 二者同形是故意的：删除和举报都是「对这一条动作」、都低频、且互斥（自己的东西删，别人的
 * 东西报）。宿主原先没地方放举报，就在卡片**下面**另挂一条文字按钮 —— 属于这条动态的动作
 * 画在了这条动态外面，而且只有别人的动态才有，信息流的行距一条一个样。
 */
@Composable
fun MomentActionPopover(
    liked: Boolean,
    canDelete: Boolean = false,
    canReport: Boolean = false,
    onLike: (() -> Unit)? = null,
    onComment: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
    onReport: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.height(34.dp)
            .shadow(4.dp, RoundedCornerShape(FlareSizes.radiusMd), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgPrimary)
            .border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusMd)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.fillMaxSize().weight(1f, fill = false).clickable { onLike?.invoke() }.padding(horizontal = FlareSizes.spacing2md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(if (liked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder, contentDescription = null,
                tint = colors.textPrimary, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(5.dp))
            Text(if (liked) flareStrings().unlike else flareStrings().like, color = colors.textPrimary, fontSize = 13.sp)
        }
        Box(Modifier.width(1.dp).height(18.dp).background(colors.borderSecondary))
        Row(
            Modifier.fillMaxSize().weight(1f, fill = false).clickable { onComment?.invoke() }.padding(horizontal = FlareSizes.spacing2md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.ChatBubbleOutline, contentDescription = null,
                tint = colors.textPrimary, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(5.dp))
            Text(flareStrings().comment, color = colors.textPrimary, fontSize = 13.sp)
        }
        if (canDelete) {
            Box(Modifier.width(1.dp).height(18.dp).background(colors.borderSecondary))
            Row(
                Modifier.fillMaxSize().weight(1f, fill = false).clickable { onDelete?.invoke() }.padding(horizontal = FlareSizes.spacing2md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.DeleteOutline, contentDescription = null,
                    tint = colors.errorText, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(5.dp))
                Text(flareStrings().delete, color = colors.errorText, fontSize = 13.sp)
            }
        } else if (canReport) {
            // 举报不销毁我自己的东西，所以用常规色：危险色留给「这会删掉你的东西」。
            Box(Modifier.width(1.dp).height(18.dp).background(colors.borderSecondary))
            Row(
                Modifier.fillMaxSize().weight(1f, fill = false).clickable { onReport?.invoke() }.padding(horizontal = FlareSizes.spacing2md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(flareIconVector("report"), contentDescription = null,
                    tint = colors.textPrimary, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(5.dp))
                Text(flareStrings().report, color = colors.textPrimary, fontSize = 13.sp)
            }
        }
    }
}

// MARK: - MomentsCoverHeader

/**
 * How the moments cover looks: with a cover image, the tall photo under a brand placeholder and a bottom scrim, with
 * the name and signature in white with soft shadows.
 *
 * Without one there is **no band to reserve** ([height] = 0): the header is a compact identity row read left to
 * right — avatar, then name and signature — on the tertiary surface, in the normal text colours and no shadows.
 * It used to keep the photo geometry (a 140dp band with the name right-aligned and pulled up onto where the scrim
 * would be), but right alignment, the overlap and the overhang only mean something with a photo under them; with
 * no photo they left ~110dp of empty band above a name glued to its bottom-right corner.
 */
internal data class MomentsCoverLook(val height: Dp, val photo: Boolean) {
    val brandPlaceholder: Boolean get() = photo
    val scrim: Boolean get() = photo
    val textShadows: Boolean get() = photo
}

internal fun momentsCoverLook(coverUrl: String?): MomentsCoverLook =
    if (coverUrl.isNullOrBlank()) MomentsCoverLook(height = 0.dp, photo = false) else MomentsCoverLook(height = 240.dp, photo = true)

/**
 * Profile cover header with overlapping avatar. Spec: Moments/MomentsCoverHeader.
 *
 * Without a cover image it stays quiet ([momentsCoverLook]). 换封面 and the cover itself open the cover editor only
 * when [onEditCover] is handled, and the avatar is a control only with [onAvatar].
 */
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
    val colors = flareColors()
    val look = momentsCoverLook(coverUrl)
    // White text over a photo — legible on any image. A soft shadow lifts each glyph off it.
    val titleShadow = Shadow(color = Color(0x73000000), offset = Offset(0f, 1f), blurRadius = 6f)
    val sigShadow = Shadow(color = Color(0x66000000), offset = Offset(0f, 1f), blurRadius = 4f)
    Column(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingXl)) {
        if (look.photo) Box(
            Modifier.fillMaxWidth().height(look.height)
                .then(
                    // Theme-aware placeholder behind a photo that is still loading; a quiet band without one.
                    if (look.brandPlaceholder) Modifier.background(Brush.linearGradient(listOf(colors.primaryActive, colors.primary, colors.primaryHover)))
                    else Modifier.background(colors.bgTertiary),
                )
                .then(if (onEditCover != null) Modifier.clickable(onClickLabel = flareStrings().changeCover, onClick = onEditCover) else Modifier),
        ) {
            if (look.photo) {
                AsyncImage(model = coverUrl, contentDescription = null,
                    modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
            }
            if (look.scrim) {
                // Bottom scrim so the name + signature stay legible over any cover image.
                Box(
                    Modifier.fillMaxSize().background(
                        Brush.verticalGradient(
                            0.45f to Color.Transparent,
                            1f to Color(0x6B0F0C19),
                        ),
                    ),
                )
            }
            // 换封面 — top-right, clear of the avatar. Its own tap target over the whole-cover click.
            if (onEditCover != null) {
                val hint = Color.White.copy(alpha = 0.92f)
                Row(
                    Modifier.align(Alignment.TopEnd).padding(FlareSizes.spacing2md)
                        .clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(Color(0x520F0C19))
                        .clickable(onClick = onEditCover)
                        .padding(horizontal = 11.dp, vertical = 5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(flareIconVector("image"), contentDescription = null, tint = hint, modifier = Modifier.size(FlareSizes.spacing2md))
                    Spacer(Modifier.width(FlareSizes.spacingXs))
                    Text(flareStrings().changeCover, color = hint, fontSize = FlareSizes.fontSizeSm)
                }
            }
        }
        Row(
            if (look.photo) {
                Modifier.fillMaxWidth().offset(y = (-30).dp).padding(horizontal = FlareSizes.spacingLg)
            } else {
                // Nothing here is positioned relative to a picture that does not exist: no overhang, no
                // right alignment, and the row carries the tertiary surface itself.
                Modifier.fillMaxWidth().background(colors.bgTertiary).padding(FlareSizes.spacingMd)
            },
            horizontalArrangement = if (look.photo) Arrangement.End else Arrangement.Start,
            verticalAlignment = if (look.photo) Alignment.Bottom else Alignment.CenterVertically,
        ) {
            if (!look.photo) {
                CoverAvatar(userId, name, avatarUrl, onAvatar)
                Spacer(Modifier.width(FlareSizes.spacingMd))
            }
            Column(
                horizontalAlignment = if (look.photo) Alignment.End else Alignment.Start,
                modifier = Modifier.weight(1f).then(if (look.photo) Modifier.padding(bottom = FlareSizes.spacing2xs) else Modifier),
            ) {
                Text(name, color = if (look.photo) Color.White else colors.textPrimary, fontWeight = FontWeight.Bold, fontSize = FlareSizes.fontSize3xl,
                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                    style = if (look.textShadows) TextStyle(shadow = titleShadow) else TextStyle.Default)
                signature?.let {
                    Text(it, color = if (look.photo) Color.White.copy(alpha = 0.88f) else colors.textSecondary, fontSize = 12.5.sp, maxLines = 1,
                        overflow = TextOverflow.Ellipsis, style = if (look.textShadows) TextStyle(shadow = sigShadow) else TextStyle.Default,
                        modifier = Modifier.padding(top = FlareSizes.spacingXs))
                }
            }
            if (look.photo) {
                Spacer(Modifier.width(FlareSizes.spacingMd))
                CoverAvatar(userId, name, avatarUrl, onAvatar)
            } else if (onEditCover != null) {
                // Without a photo the affordance has no photo to sit on top of: it ends the identity row
                // instead of floating over a blank band.
                Spacer(Modifier.width(FlareSizes.spacingSm))
                Row(
                    Modifier.clip(RoundedCornerShape(FlareSizes.radiusFull))
                        .background(colors.bgElevated)
                        .border(1.dp, colors.borderSecondary, RoundedCornerShape(FlareSizes.radiusFull))
                        .clickable(onClick = onEditCover)
                        .padding(horizontal = 11.dp, vertical = 5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(flareIconVector("image"), contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(FlareSizes.spacing2md))
                    Spacer(Modifier.width(FlareSizes.spacingXs))
                    Text(flareStrings().changeCover, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                }
            }
        }
    }
}

/** Borderless cover avatar — a soft shadow + rounded square lifts it off the cover (no white frame). */
@Composable
private fun CoverAvatar(userId: String, name: String, avatarUrl: String?, onAvatar: (() -> Unit)?) {
    Box(
        Modifier.shadow(10.dp, RoundedCornerShape(15.dp), clip = false)
            .clip(RoundedCornerShape(15.dp))
            .then(if (onAvatar != null) Modifier.clickable(onClick = onAvatar) else Modifier),
    ) {
        Avatar(userId = userId, displayName = name, avatarUrl = avatarUrl, size = 66.dp)
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
        Modifier.width(360.dp)
            .shadow(16.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacing2md, vertical = FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(flareStrings().cancel, color = colors.textSecondary, fontSize = 14.sp,
                modifier = Modifier.clickable { onCancel?.invoke() })
            Spacer(Modifier.weight(1f))
            Box(
                Modifier.clip(RoundedCornerShape(999.dp)).background(colors.primary)
                    .then(if (canPost && !busy) Modifier.clickable { onSubmit?.invoke(text.trim()) } else Modifier)
                    .padding(horizontal = 18.dp, vertical = FlareSizes.spacing2xs),
            ) {
                Text(flareStrings().post, color = Color.White.copy(alpha = if (canPost && !busy) 1f else 0.45f),
                    fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        BasicTextField(
            value = text, onValueChange = { text = it },
            textStyle = TextStyle(color = colors.textPrimary, fontSize = 15.sp),
            cursorBrush = SolidColor(colors.primary),
            modifier = Modifier.fillMaxWidth().heightIn(min = 96.dp).padding(FlareSizes.spacing2md),
            decorationBox = { inner ->
                if (text.isEmpty()) Text(flareStrings().momentTextHint, color = colors.textTertiary, fontSize = 15.sp)
                inner()
            },
        )
        // image grid (4-col rows)
        val cells = images.take(maxImages)
        val showAdd = images.size < maxImages
        Column(Modifier.padding(horizontal = FlareSizes.spacing2md).padding(bottom = FlareSizes.spacingMd), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
            val items = cells.indices.toList()
            val rows = (items + if (showAdd) listOf(-1) else emptyList()).chunked(4)
            rows.forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                    row.forEach { idx ->
                        if (idx >= 0) {
                            Box(Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)) {
                                AsyncImage(model = images[idx], contentDescription = null,
                                    modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                                // The 18 dp disc stays in the corner; its 48 dp target is a square anchored to the
                                // same corner inside the thumbnail, so nothing outside the tile takes the tap.
                                FlareIconControl(
                                    label = flareStrings().removeImage,
                                    onClick = onRemoveImage?.let { remove -> { remove(idx) } },
                                    modifier = Modifier.align(Alignment.TopEnd),
                                    shape = RoundedCornerShape(FlareSizes.radiusMd),
                                ) {
                                    Box(
                                        Modifier.align(Alignment.TopEnd).padding(2.dp).size(18.dp).clip(CircleShape)
                                            .background(Color.Black.copy(alpha = 0.55f)),
                                        contentAlignment = Alignment.Center,
                                    ) { Icon(flareIconVector("close"), contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp)) }
                                }
                            }
                        } else {
                            Box(
                                Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusMd))
                                    .background(colors.bgSecondary)
                                    .border(1.dp, colors.borderHover, RoundedCornerShape(FlareSizes.radiusMd))
                                    .clickable { onAddImage?.invoke() },
                                contentAlignment = Alignment.Center,
                            ) { Icon(Icons.Outlined.Add, contentDescription = flareStrings().addImage, tint = colors.textTertiary, modifier = Modifier.size(26.dp)) }
                        }
                    }
                    repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        composerRow(colors, Icons.Outlined.LocationOn, location ?: flareStrings().pickLocation) { onPickLocation?.invoke() }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        composerRow(colors, Icons.Outlined.Public, visibility ?: flareStrings().pickVisibility) { onPickVisibility?.invoke() }
    }
}

@Composable
private fun composerRow(colors: FlareColors, icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onClick() }.padding(horizontal = FlareSizes.spacing2md, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(FlareSizes.spacing2sm))
        Text(label, color = colors.textSecondary, fontSize = 14.sp)
    }
}

// MARK: - MomentCard

/**
 * Social-feed moment card. Spec: Moments/MomentCard.
 *
 * People and comments are controls only when the host does something with them: the author's name (and avatar) with
 * [onSelectAuthor], each liker with [onSelectLiker], each comment with [onSelectComment] ([CommentThread]); otherwise
 * they are plain text. The avatar repeats the name, so it is hidden from accessibility when the name is a control.
 * Names read in the accessible primary text colour.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun MomentCard(
    moment: Moment,
    canDelete: Boolean = false,
    canReport: Boolean = false,
    onLike: (() -> Unit)? = null,
    onComment: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
    onReport: (() -> Unit)? = null,
    onOpenImage: ((Int) -> Unit)? = null,
    onSelectAuthor: ((String) -> Unit)? = null,
    onSelectLiker: ((String) -> Unit)? = null,
    onSelectComment: ((MomentComment) -> Unit)? = null,
) {
    val colors = flareColors()
    var menuOpen by remember { mutableStateOf(false) }
    // The card uses a restrained theme-tinted lift in dark mode.
    val cardDark = isSystemInDarkTheme()
    Row(
        Modifier.fillMaxWidth()
            .shadow(
                if (cardDark) 14.dp else 10.dp, RoundedCornerShape(FlareSizes.radius2xl), clip = false,
                ambientColor = if (cardDark) colors.primary else Color(0xFF151320),
                spotColor = if (cardDark) colors.primary else Color(0xFF151320),
            )
            .clip(RoundedCornerShape(FlareSizes.radius2xl)).background(colors.bgElevated).padding(FlareSizes.spacingLg),
    ) {
        // The avatar repeats the name: with a name control it is a pointer shortcut hidden from accessibility.
        Box(if (onSelectAuthor != null) Modifier.clearAndSetSemantics {}.clickable { onSelectAuthor(moment.author.id) } else Modifier) {
            Avatar(
                userId = moment.author.id, displayName = moment.author.name, size = 42.dp,
                image = moment.author.avatarUrl?.let { url ->
                    { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                },
            )
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(moment.author.name, color = colors.primaryText, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeXl,
                modifier = if (onSelectAuthor != null) Modifier.clickable(role = Role.Button) { onSelectAuthor(moment.author.id) } else Modifier)
            moment.text?.let {
                Text(it, color = colors.textPrimary, fontSize = 15.sp, modifier = Modifier.padding(top = FlareSizes.spacingXs))
            }
            if (moment.images.isNotEmpty()) {
                Box(Modifier.padding(top = FlareSizes.spacing2sm)) { ImageGrid(images = moment.images, onOpen = onOpenImage) }
            }
            moment.location?.let {
                Row(Modifier.padding(top = FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.LocationOn, contentDescription = null, tint = colors.primaryText.copy(alpha = 0.8f), modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(3.dp))
                    Text(it, color = colors.primaryText.copy(alpha = 0.8f), fontSize = 12.sp)
                }
            }
            Row(Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2sm), verticalAlignment = Alignment.CenterVertically) {
                Text(moment.time ?: "", color = colors.textTertiary, fontSize = 12.sp)
                Spacer(Modifier.weight(1f))
                if (menuOpen) {
                    MomentActionPopover(
                        liked = moment.likedBySelf,
                        canDelete = canDelete,
                        canReport = canReport,
                        onLike = { menuOpen = false; onLike?.invoke() },
                        onComment = { menuOpen = false; onComment?.invoke() },
                        onDelete = { menuOpen = false; onDelete?.invoke() },
                        onReport = { menuOpen = false; onReport?.invoke() },
                    )
                    Spacer(Modifier.width(6.dp))
                }
                Box(
                    Modifier.size(width = 30.dp, height = 24.dp).clip(RoundedCornerShape(FlareSizes.radiusSm))
                        .background(if (menuOpen) colors.bgSelected else colors.bgSecondary)
                        .clickable { menuOpen = !menuOpen },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Outlined.MoreHoriz, contentDescription = flareStrings().more, tint = if (menuOpen) colors.primaryText else colors.textSecondary, modifier = Modifier.size(16.dp)) }
            }
            if (moment.likes.isNotEmpty() || moment.comments.isNotEmpty()) {
                Column(
                    Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2sm).clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(colors.bgSecondary).padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                ) {
                    if (moment.likes.isNotEmpty()) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.FavoriteBorder, contentDescription = null, tint = colors.errorText, modifier = Modifier.size(FlareSizes.spacing2md))
                            Spacer(Modifier.width(FlareSizes.spacing2xs))
                            // Each liker is its own control when the host opens people; otherwise the names are text.
                            FlowRow {
                                moment.likes.forEachIndexed { i, l ->
                                    val separator = if (i < moment.likes.size - 1) ", " else ""
                                    if (onSelectLiker != null) {
                                        Text(l.name, color = colors.primaryText, fontSize = FlareSizes.fontSizeMd,
                                            modifier = Modifier.clickable(role = Role.Button) { onSelectLiker(l.id) })
                                        if (separator.isNotEmpty()) Text(separator, color = colors.primaryText, fontSize = FlareSizes.fontSizeMd)
                                    } else {
                                        Text(l.name + separator, color = colors.primaryText, fontSize = FlareSizes.fontSizeMd)
                                    }
                                }
                            }
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
