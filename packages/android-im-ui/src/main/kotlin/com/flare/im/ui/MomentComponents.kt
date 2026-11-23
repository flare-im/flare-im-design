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
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.input.ImeAction
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
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.draw.drawBehind
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
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
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
 *
 * With [foldLines] above 0 a longer comment folds to that many lines behind 展开 / 收起. [highlightId] marks the
 * comment a reader was sent to (the moment's detail from the activity inbox) and brings it into view once.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun CommentThread(
    comments: List<MomentComment>,
    onSelect: ((MomentComment) -> Unit)? = null,
    onSelectAuthor: ((String) -> Unit)? = null,
    foldLines: Int = 0,
    highlightId: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val nameStyle = SpanStyle(color = colors.primaryText, fontWeight = FontWeight.Medium)
    Column {
        comments.forEach { c -> androidx.compose.runtime.key(c.id) {
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
            var expanded by remember { mutableStateOf(false) }
            var overflows by remember { mutableStateOf(false) }
            val folded = foldLines > 0 && !expanded
            val highlighted = c.id == highlightId
            val requester = remember { BringIntoViewRequester() }
            if (highlighted) LaunchedEffect(highlightId) { requester.bringIntoView() }
            Text(
                line, fontSize = FlareSizes.fontSizeMd,
                maxLines = if (folded) foldLines else Int.MAX_VALUE,
                overflow = TextOverflow.Ellipsis,
                onTextLayout = { if (folded) overflows = it.hasVisualOverflow },
                modifier = Modifier.fillMaxWidth()
                    .then(if (highlighted) Modifier.bringIntoViewRequester(requester).clip(RoundedCornerShape(FlareSizes.radiusSm))
                        .background(colors.bgSelected).semantics { stateDescription = strings.momentLocatedComment } else Modifier)
                    .then(row).padding(vertical = 3.dp),
            )
            if (foldLines > 0 && (overflows || expanded)) {
                Text(
                    if (expanded) strings.collapse else strings.expand, color = colors.primaryText, fontSize = FlareSizes.fontSizeSm,
                    modifier = Modifier.clickable(role = Role.Button) { expanded = !expanded }.padding(vertical = 2.dp),
                )
            }
        } }
    }
}

// MARK: - MomentActionPopover

/**
 * Dark like/comment capsule from the ··· button. Spec: Moments/MomentActionPopover.
 *
 * [canDelete] adds a trailing destructive **Delete** action — shown only for the current user's own
 * moments; [canReport] adds **Report** in the same slot for everyone else's (parity with
 * `FlareMomentActionPopover.vue`'s `canDelete` / `canReport` gates). Like and Comment appear only when [onLike] /
 * [onComment] are handled: the host leaves a switch that is off unhandled (an existing like stays undoable).
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
        var separator = false
        if (onLike != null) {
            Row(
                Modifier.fillMaxSize().weight(1f, fill = false).clickable { onLike() }.padding(horizontal = FlareSizes.spacing2md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(if (liked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder, contentDescription = null,
                    tint = colors.textPrimary, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(5.dp))
                Text(if (liked) flareStrings().unlike else flareStrings().like, color = colors.textPrimary, fontSize = 13.sp)
            }
            separator = true
        }
        if (onComment != null) {
            if (separator) Box(Modifier.width(1.dp).height(18.dp).background(colors.borderSecondary))
            Row(
                Modifier.fillMaxSize().weight(1f, fill = false).clickable { onComment() }.padding(horizontal = FlareSizes.spacing2md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.ChatBubbleOutline, contentDescription = null,
                    tint = colors.textPrimary, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(5.dp))
                Text(flareStrings().comment, color = colors.textPrimary, fontSize = 13.sp)
            }
            separator = true
        }
        if (canDelete) {
            if (separator) Box(Modifier.width(1.dp).height(18.dp).background(colors.borderSecondary))
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
            if (separator) Box(Modifier.width(1.dp).height(18.dp).background(colors.borderSecondary))
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
    Column(Modifier.fillMaxWidth().then(if (look.photo) Modifier.padding(bottom = FlareSizes.spacingXl) else Modifier)) {
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
                // right alignment. Vue's `--empty`: the page surface, a hairline under it, lg padding.
                Modifier.fillMaxWidth().background(colors.bgPrimary)
                    .drawBehind { drawLine(colors.borderSecondary, Offset(0f, size.height - 0.5.dp.toPx()), Offset(size.width, size.height - 0.5.dp.toPx()), 1.dp.toPx()) }
                    .padding(FlareSizes.spacingLg)
            },
            horizontalArrangement = if (look.photo) Arrangement.End else Arrangement.Start,
            verticalAlignment = if (look.photo) Alignment.Bottom else Alignment.CenterVertically,
        ) {
            if (!look.photo) {
                // A plain 48 circle beside the name, no lift (Vue `--empty`).
                Box(Modifier.clip(CircleShape).then(if (onAvatar != null) Modifier.clickable(onClick = onAvatar) else Modifier)) {
                    Avatar(userId = userId, displayName = name, avatarUrl = avatarUrl, size = 48.dp)
                }
                Spacer(Modifier.width(FlareSizes.spacingMd))
            }
            Column(
                horizontalAlignment = if (look.photo) Alignment.End else Alignment.Start,
                modifier = Modifier.weight(1f).then(if (look.photo) Modifier.padding(bottom = FlareSizes.spacing2xs) else Modifier),
            ) {
                Text(name, color = if (look.photo) Color.White else colors.textPrimary, fontWeight = FontWeight.Bold, fontSize = if (look.photo) FlareSizes.fontSize3xl else FlareSizes.fontSizeLg,
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
                // Vue's quiet text key: no pill and no glyph, the touch target around the words.
                Spacer(Modifier.width(FlareSizes.spacingSm))
                Text(
                    flareStrings().changeCover, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm,
                    modifier = Modifier.heightIn(min = FlareSizes.touchTarget).clip(RoundedCornerShape(FlareSizes.radiusMd))
                        .clickable(role = Role.Button, onClick = onEditCover).wrapContentHeight()
                        .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
                )
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

/**
 * Compose a moment. Spec: Moments/MomentComposer.
 *
 * [page] is the full-width layout a drawer or a page hosts (`layout=page`): no card chrome, the cancel / post header
 * stays on top while the rest scrolls, the text opens focused and grows from 3 to 8 lines, and images sit three to a
 * row. Without it the composer is the 360dp card.
 *
 * Images: [images] are what each tile shows (a local or remote address) and [imageStates] what became of each upload
 * (none given: all uploaded; [FlareImageUploadState.Empty] is a picked image waiting its turn). An uploading tile keeps
 * its remove control away, a failed one offers [onRetryImage], and [onOpenImage] previews one. While an image uploads
 * the add tile hides and posting waits; with [maxImages] 0 and no image the area is not drawn. [imageHint] heads the
 * area with 添加图片, the count n / [maxImages] and the hint.
 *
 * [error] is a post that failed: a danger banner under the header whose retry posts the current text again through
 * [onRetry]. With [onLocationChange] the location row edits in place (✓ or Done confirms, ✕ or Escape cancels, an empty
 * value clears it, [locationPlaceholder] when there is none); otherwise a tap runs [onPickLocation].
 */
@OptIn(ExperimentalLayoutApi::class)
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
    page: Boolean = false,
    imageStates: List<FlareImageUploadState> = emptyList(),
    onRetryImage: ((Int) -> Unit)? = null,
    onOpenImage: ((Int) -> Unit)? = null,
    imageHint: String? = null,
    error: String? = null,
    onRetry: ((String) -> Unit)? = null,
    onLocationChange: ((String?) -> Unit)? = null,
    locationPlaceholder: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var text by remember { mutableStateOf("") }
    val uploading = imageStates.any { it == FlareImageUploadState.Uploading || it == FlareImageUploadState.Empty }
    val canPost = (text.trim().isNotEmpty() || images.isNotEmpty()) && !busy && !uploading
    val focus = remember { FocusRequester() }
    if (page) LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }

    Column(
        if (page) Modifier.fillMaxSize().background(colors.bgPrimary)
        else Modifier.width(360.dp)
            .shadow(16.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacing2md, vertical = FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Vue: a small ghost 取消 and a small primary 发表, the kit's own buttons.
            Button(label = strings.cancel, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm, disabled = busy,
                onClick = { onCancel?.invoke() })
            Spacer(Modifier.weight(1f))
            Button(label = strings.post, size = FlareControlSize.Sm, disabled = !canPost, onClick = { onSubmit?.invoke(text.trim()) })
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        Column(if (page) Modifier.fillMaxWidth().weight(1f).verticalScroll(rememberScrollState()) else Modifier.fillMaxWidth()) {
            if (error != null && !busy) {
                Box(Modifier.padding(horizontal = FlareSizes.spacing2md).padding(top = FlareSizes.spacingSm)) {
                    StatusBanner(error, tone = FlareStatusTone.Danger, actionText = strings.retry,
                        onAction = onRetry?.let { retry -> { retry(text.trim()) } })
                }
            }
            BasicTextField(
                value = text, onValueChange = { text = it },
                enabled = !busy,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 15.sp),
                cursorBrush = SolidColor(colors.primary),
                minLines = 3, maxLines = if (page) 8 else Int.MAX_VALUE,
                modifier = Modifier.fillMaxWidth().focusRequester(focus)
                    .then(if (page) Modifier else Modifier.heightIn(min = 96.dp)).padding(FlareSizes.spacing2md),
                decorationBox = { inner ->
                    if (text.isEmpty()) Text(strings.momentTextHint, color = colors.textTertiary, fontSize = 15.sp)
                    inner()
                },
            )
            if (maxImages > 0 || images.isNotEmpty()) {
                val columns = if (page) 3 else 4
                val showAdd = images.size < maxImages && !uploading && !busy && onAddImage != null
                Column(Modifier.padding(horizontal = FlareSizes.spacing2md).padding(bottom = FlareSizes.spacingMd), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                    // Vue `layout="images"`: only the count shows; the title names the add tile and the hint is its click label.
                    if (imageHint != null) {
                        Text("${images.size} / $maxImages", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, modifier = Modifier.align(Alignment.End))
                    }
                    val rows = (images.indices.toList() + if (showAdd) listOf(-1) else emptyList()).chunked(columns)
                    rows.forEach { row ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                            row.forEach { idx ->
                                if (idx >= 0) ComposerImageTile(images[idx], imageStates.getOrNull(idx) ?: FlareImageUploadState.Uploaded, busy,
                                    onRemove = onRemoveImage?.let { remove -> { remove(idx) } },
                                    onRetry = onRetryImage?.let { retry -> { retry(idx) } },
                                    onOpen = onOpenImage?.let { open -> { open(idx) } },
                                    modifier = Modifier.weight(1f))
                                else Box(
                                    Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusMd))
                                        .background(colors.bgSecondary)
                                        .border(1.dp, colors.borderHover, RoundedCornerShape(FlareSizes.radiusMd))
                                        .clickable(role = Role.Button, onClickLabel = imageHint) { onAddImage?.invoke() },
                                    contentAlignment = Alignment.Center,
                                ) { Icon(Icons.Outlined.Add, contentDescription = strings.addImage, tint = colors.textTertiary, modifier = Modifier.size(26.dp)) }
                            }
                            repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                        }
                    }
                }
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
            if (onLocationChange != null) {
                ComposerLocationRow(location, locationPlaceholder ?: strings.pickLocation, enabled = !busy, onChange = onLocationChange)
            } else {
                composerRow(colors, Icons.Outlined.LocationOn, location ?: strings.pickLocation) { onPickLocation?.invoke() }
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
            composerRow(colors, Icons.Outlined.Public, visibility ?: strings.pickVisibility) { if (!busy) onPickVisibility?.invoke() }
        }
    }
}

/** One picked image in the composer: its upload state over the thumbnail, remove, retry and preview. */
@Composable
private fun ComposerImageTile(
    url: String,
    state: FlareImageUploadState,
    busy: Boolean,
    onRemove: (() -> Unit)?,
    onRetry: (() -> Unit)?,
    onOpen: (() -> Unit)?,
    modifier: Modifier,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val status = when (state) {
        FlareImageUploadState.Empty -> strings.pluginFileSelected
        FlareImageUploadState.Uploading -> strings.pluginFileUploading
        FlareImageUploadState.Uploaded -> strings.pluginFileUploaded
        FlareImageUploadState.Failed -> strings.retry
    }
    Box(
        modifier.aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary)
            .semantics { stateDescription = status }
            .then(if (onOpen != null) Modifier.clickable(onClickLabel = strings.pluginFilePreview, onClick = onOpen) else Modifier),
    ) {
        AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        if (state != FlareImageUploadState.Uploaded) Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.35f)))
        when (state) {
            FlareImageUploadState.Uploading -> CircularProgressIndicator(Modifier.align(Alignment.Center).size(22.dp), color = Color.White, strokeWidth = 2.dp)
            FlareImageUploadState.Failed -> FlareIconControl(label = strings.retry, onClick = onRetry, modifier = Modifier.align(Alignment.Center)) {
                Icon(flareIconVector("refresh"), contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
            }
            else -> Unit
        }
        if (state != FlareImageUploadState.Uploading && !busy) {
            // The 18 dp disc stays in the corner; its 48 dp target is a square anchored to the same corner.
            FlareIconControl(
                label = strings.removeImage,
                onClick = onRemove,
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
    }
}

/** The location row edited in place: ✓ or Done confirms (empty clears), ✕ or Escape puts the old value back. */
@Composable
private fun ComposerLocationRow(location: String?, placeholder: String, enabled: Boolean, onChange: (String?) -> Unit) {
    val colors = flareColors()
    val strings = flareStrings()
    var editing by remember { mutableStateOf(false) }
    var draft by remember { mutableStateOf("") }
    val focus = remember { FocusRequester() }
    if (!editing) {
        composerRow(colors, Icons.Outlined.LocationOn, location ?: placeholder) { if (enabled) { draft = location.orEmpty(); editing = true } }
        return
    }
    LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }
    val confirm = { onChange(draft.trim().ifEmpty { null }); editing = false }
    Row(
        Modifier.fillMaxWidth().padding(start = FlareSizes.spacing2md, end = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Outlined.LocationOn, contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(FlareSizes.spacing2sm))
        Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
            if (draft.isEmpty()) Text(placeholder, color = colors.textTertiary, fontSize = 14.sp)
            BasicTextField(
                value = draft, onValueChange = { draft = it }, singleLine = true,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 14.sp),
                cursorBrush = SolidColor(colors.primary),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { confirm() }),
                modifier = Modifier.fillMaxWidth().focusRequester(focus).onPreviewKeyEvent { event ->
                    if (event.key == Key.Escape && event.type == KeyEventType.KeyUp) { editing = false; true } else false
                },
            )
        }
        FlareIconControl(label = strings.confirmAction, onClick = confirm) {
            Icon(flareIconVector("check"), contentDescription = null, tint = colors.primaryText, modifier = Modifier.size(18.dp))
        }
        FlareIconControl(label = strings.cancel, onClick = { editing = false }) {
            Icon(flareIconVector("close"), contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(18.dp))
        }
    }
}

// MARK: - CommentComposer

/**
 * The comment box under a moment's detail. Spec: Moments/CommentComposer (`FlareCommentComposer.vue`).
 *
 * The host holds the draft ([value]) — per moment, so it survives closing and reopening the detail. [replyToName] shows
 * the 回复 name：[replyToExcerpt] strip with a cancel ([onCancelReply]); [error] is the last failure, shown above the field,
 * after which the send key reads 重试. The field grows from 1 to 3 lines, takes at most [maxLength] characters and counts
 * them from 80 %. Enter is a new line, Ctrl/Cmd+Enter or the send key sends; an empty draft cannot. While [busy]
 * nothing is editable.
 */
@Composable
fun CommentComposer(
    value: String,
    onValueChange: (String) -> Unit,
    onSend: () -> Unit,
    placeholder: String? = null,
    replyToName: String? = null,
    replyToExcerpt: String? = null,
    onCancelReply: (() -> Unit)? = null,
    error: String? = null,
    busy: Boolean = false,
    maxLength: Int = 500,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val canSend = value.trim().isNotEmpty() && !busy
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary).padding(FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        if (replyToName != null) Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                buildAnnotatedString {
                    withStyle(SpanStyle(color = colors.textTertiary)) { append(strings.momentReplyTo + " ") }
                    withStyle(SpanStyle(color = colors.primaryText)) { append(replyToName) }
                    if (!replyToExcerpt.isNullOrEmpty()) withStyle(SpanStyle(color = colors.textTertiary)) { append("：$replyToExcerpt") }
                },
                fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
            )
            if (onCancelReply != null) FlareIconControl(label = strings.cancelReply, onClick = onCancelReply, enabled = !busy) {
                Icon(flareIconVector("close"), contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(16.dp))
            }
        }
        if (error != null) Text(error, color = colors.errorText, fontSize = FlareSizes.fontSizeSm)
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            Box(Modifier.weight(1f).onPreviewKeyEvent { event ->
                val send = event.key == Key.Enter && (event.isCtrlPressed || event.isMetaPressed)
                if (send && event.type == KeyEventType.KeyUp && canSend) onSend()
                send
            }) {
                Textarea(
                    value = value, placeholder = placeholder, size = FlareControlSize.Sm, rows = 1, maxRows = 3,
                    showCount = value.length >= maxLength * 4 / 5, maxlength = maxLength, disabled = busy,
                    onChange = { onValueChange(it.take(maxLength)) },
                )
            }
            Button(label = if (error != null) strings.retry else strings.send, size = FlareControlSize.Sm,
                disabled = !canSend, loading = busy, onClick = onSend)
        }
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

/** A feed moment's text folds past this many characters or [MOMENT_FOLD_LINES] lines. */
internal const val MOMENT_FOLD_CHARS = 280
internal const val MOMENT_FOLD_LINES = 6

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
    /**
     * The detail appearance (a moment opened from the activity inbox): the text never folds, comments fold after 5
     * lines instead of 3, and the comments carry a 评论 N heading, or 还没有评论.
     */
    detail: Boolean = false,
    /** The comment the reader was sent to, marked and brought into view ([CommentThread]). */
    highlightCommentId: String? = null,
    /** Vue's `appearance="feed"`: a full-width row of the feed — no card lift or corners, a hairline under it. */
    feed: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var menuOpen by remember { mutableStateOf(false) }
    // No action to offer, no ··· key (DM-00.1: what is not handled is not drawn).
    val hasActions = onLike != null || onComment != null || canDelete || canReport
    // The card uses a restrained theme-tinted lift in dark mode.
    val cardDark = isSystemInDarkTheme()
    Row(
        (if (feed) Modifier.fillMaxWidth().background(colors.bgElevated)
            .drawBehind { drawLine(colors.borderSecondary, Offset(0f, size.height - 0.5.dp.toPx()), Offset(size.width, size.height - 0.5.dp.toPx()), 1.dp.toPx()) }
        else Modifier.fillMaxWidth()
            .shadow(
                if (cardDark) 14.dp else 10.dp, RoundedCornerShape(FlareSizes.radius2xl), clip = false,
                ambientColor = if (cardDark) colors.primary else Color(0xFF151320),
                spotColor = if (cardDark) colors.primary else Color(0xFF151320),
            )
            .clip(RoundedCornerShape(FlareSizes.radius2xl)).background(colors.bgElevated)).padding(FlareSizes.spacingLg),
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
            moment.text?.let { text ->
                // The feed folds a long text (over 280 characters or 6 lines) behind 展开 / 收起; the detail shows it all.
                var expanded by remember(moment.id) { mutableStateOf(false) }
                var overflows by remember(moment.id) { mutableStateOf(false) }
                val folded = !detail && !expanded
                val long = !detail && text.length > MOMENT_FOLD_CHARS
                Text(
                    if (folded && long) text.take(MOMENT_FOLD_CHARS) + "…" else text,
                    color = colors.textPrimary, fontSize = 15.sp,
                    maxLines = if (folded) MOMENT_FOLD_LINES else Int.MAX_VALUE, overflow = TextOverflow.Ellipsis,
                    onTextLayout = { if (folded) overflows = it.hasVisualOverflow },
                    modifier = Modifier.padding(top = FlareSizes.spacingXs),
                )
                if (!detail && (long || overflows || expanded)) {
                    Text(
                        if (expanded) strings.collapse else strings.expand, color = colors.primaryText, fontSize = FlareSizes.fontSizeMd,
                        modifier = Modifier.padding(top = FlareSizes.spacing2xs).clickable(role = Role.Button) { expanded = !expanded },
                    )
                }
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
                if (menuOpen && hasActions) {
                    MomentActionPopover(
                        liked = moment.likedBySelf,
                        canDelete = canDelete,
                        canReport = canReport,
                        onLike = onLike?.let { like -> { menuOpen = false; like() } },
                        onComment = onComment?.let { comment -> { menuOpen = false; comment() } },
                        onDelete = { menuOpen = false; onDelete?.invoke() },
                        onReport = { menuOpen = false; onReport?.invoke() },
                    )
                    Spacer(Modifier.width(6.dp))
                }
                // 30×24 drawn, a touch target taken (Vue: 24 visible, 48 hit area).
                if (hasActions) Box(
                    Modifier.size(FlareSizes.touchTarget).clickable(role = androidx.compose.ui.semantics.Role.Button) { menuOpen = !menuOpen },
                    contentAlignment = Alignment.Center,
                ) {
                    Box(
                        Modifier.size(width = 30.dp, height = 24.dp).clip(RoundedCornerShape(FlareSizes.radiusSm))
                            .background(if (menuOpen) colors.bgSelected else colors.bgSecondary),
                        contentAlignment = Alignment.Center,
                    ) { Icon(Icons.Outlined.MoreHoriz, contentDescription = flareStrings().more, tint = if (menuOpen) colors.primaryText else colors.textSecondary, modifier = Modifier.size(16.dp)) }
                }
            }
            if (detail || moment.likes.isNotEmpty() || moment.comments.isNotEmpty()) {
                // Vue `.flare-moment__social`: likes and comments under a hairline, on the card's own surface.
                Column(
                    Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2xs)
                        .drawBehind { drawLine(colors.borderSecondary, Offset(0f, 0.5.dp.toPx()), Offset(size.width, 0.5.dp.toPx()), 1.dp.toPx()) }
                        .padding(top = FlareSizes.spacingSm),
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
                    if (moment.likes.isNotEmpty() && (detail || moment.comments.isNotEmpty())) {
                        Box(Modifier.fillMaxWidth().padding(vertical = 7.dp).height(1.dp).background(colors.textTertiary.copy(alpha = 0.22f)))
                    }
                    if (detail) {
                        Text(
                            if (moment.comments.isEmpty()) strings.momentNoComments else "${strings.momentCommentsTitle} ${moment.comments.size}",
                            color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(bottom = FlareSizes.spacing2xs),
                        )
                    }
                    if (moment.comments.isNotEmpty()) {
                        CommentThread(
                            comments = moment.comments, onSelect = onSelectComment, onSelectAuthor = onSelectAuthor,
                            foldLines = if (detail) 5 else 3, highlightId = highlightCommentId,
                        )
                    }
                }
            }
        }
    }
}
