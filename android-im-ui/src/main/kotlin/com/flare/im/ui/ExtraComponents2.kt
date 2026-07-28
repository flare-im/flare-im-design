package com.flare.im.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.outlined.AddReaction
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.FlashOn
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Message reaction pills + add button. Spec: Message/ReactionSummary. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ReactionSummary(
    reactions: List<ReactionGroup>,
    hideAdd: Boolean = false,
    onToggle: ((String) -> Unit)? = null,
    onAdd: (() -> Unit)? = null,
) {
    val colors = flareColors()
    if (reactions.isEmpty() && hideAdd) return
    val pillShape = RoundedCornerShape(999.dp)
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        reactions.forEach { r ->
            val active = r.reactedBySelf
            Row(
                Modifier.height(26.dp)
                    .clip(pillShape)
                    .background(if (active) colors.bgSelected else colors.bgSecondary)
                    .border(1.dp, if (active) colors.primary else colors.borderPrimary, pillShape)
                    .then(if (onToggle != null) Modifier.clickable { onToggle(r.emoji) } else Modifier)
                    .padding(horizontal = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(r.emoji, fontSize = FlareSizes.fontSizeMd.value.sp)
                Text(
                    "${r.count}",
                    color = if (active) colors.primary else colors.textSecondary,
                    fontWeight = FontWeight.Medium,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                )
            }
        }
        if (!hideAdd) {
            Row(
                Modifier.height(26.dp)
                    .clip(pillShape)
                    .background(colors.bgSecondary)
                    .border(1.dp, colors.borderPrimary, pillShape)
                    .then(if (onAdd != null) Modifier.clickable { onAdd() } else Modifier)
                    .padding(horizontal = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Outlined.AddReaction,
                    contentDescription = flareStrings().addReaction,
                    tint = colors.textTertiary,
                    modifier = Modifier.size(15.dp),
                )
            }
        }
    }
}

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

/** Multi-select toolbar for batch message actions. Spec: Message/MessageBatchToolbar. */
@Composable
fun MessageBatchToolbar(
    count: Int,
    total: Int,
    busy: Boolean = false,
    onSelectAll: (() -> Unit)? = null,
    onForwardEach: (() -> Unit)? = null,
    onForwardMerged: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null,
    onExit: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    Row(
        Modifier.fillMaxWidth()
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("$count", color = colors.primary, fontWeight = FontWeight.Bold, fontSize = FlareSizes.fontSizeLg.value.sp)
            Text(" / $total · ${flareStrings().selectedSuffix}", color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
        Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically) {
            batchBtn(colors, Icons.Outlined.DoneAll, flareStrings().selectAll, total > 0 && !busy, onSelectAll)
            batchBtn(colors, Icons.Outlined.Share, flareStrings().forwardEach, count > 0 && !busy, onForwardEach)
            batchBtn(colors, Icons.AutoMirrored.Outlined.LibraryBooks, flareStrings().forwardMerged, count >= 2 && !busy, onForwardMerged)
            batchBtn(colors, Icons.Outlined.DeleteOutline, flareStrings().delete, count > 0 && !busy, onDelete, tint = colors.error)
            batchBtn(colors, Icons.Outlined.Close, null, !busy, onExit)
        }
    }
}

@Composable
private fun batchBtn(
    colors: FlareColors,
    icon: ImageVector,
    label: String?,
    enabled: Boolean,
    onTap: (() -> Unit)?,
    tint: Color? = null,
) {
    Row(
        Modifier.height(32.dp)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(colors.bgSecondary)
            .then(if (enabled && onTap != null) Modifier.clickable { onTap() } else Modifier)
            .alpha(if (enabled) 1f else 0.45f)
            .padding(horizontal = if (label == null) 8.dp else 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(icon, contentDescription = label, tint = tint ?: colors.textPrimary, modifier = Modifier.size(16.dp))
        if (label != null) {
            Text(label, color = tint ?: colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeSm.value.sp)
        }
    }
}

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

/** Quick phrases / canned replies picker. Spec: Composer/QuickPhrases. */
@Composable
fun QuickPhrases(
    groups: List<QuickPhraseGroup>,
    manageable: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    onManage: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var activeKey by remember { mutableStateOf(groups.firstOrNull()?.key ?: "") }
    val active = groups.firstOrNull { it.key == activeKey } ?: groups.firstOrNull()
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
            Icon(Icons.Outlined.FlashOn, contentDescription = null, tint = colors.primary, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                flareStrings().quickPhrases,
                color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeXl.value.sp,
                modifier = Modifier.weight(1f),
            )
            if (manageable) {
                Row(
                    Modifier.then(if (onManage != null) Modifier.clickable { onManage() } else Modifier),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(flareStrings().manage, color = colors.primary, fontSize = FlareSizes.fontSizeMd.value.sp, fontWeight = FontWeight.Medium)
                    Icon(Icons.Outlined.Edit, contentDescription = null, tint = colors.primary, modifier = Modifier.size(14.dp))
                }
            }
        }
        if (groups.size > 1) {
            Row(
                Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = FlareSizes.spacingLg),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                groups.forEach { g ->
                    val sel = g.key == active?.key
                    Text(
                        g.title,
                        color = if (sel) colors.primary else colors.textSecondary,
                        fontWeight = if (sel) FontWeight.Medium else FontWeight.Normal,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        modifier = Modifier.clip(RoundedCornerShape(999.dp))
                            .background(if (sel) colors.bgSelected else colors.bgSecondary)
                            .clickable { activeKey = g.key }
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                    )
                }
            }
            Spacer(Modifier.height(8.dp))
        }
        Column(
            Modifier.fillMaxWidth().heightIn(max = 280.dp).verticalScroll(rememberScrollState())
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, bottom = FlareSizes.spacingMd),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            active?.phrases?.forEach { p ->
                Text(
                    p.text,
                    color = colors.textPrimary,
                    fontSize = 14.sp,
                    modifier = Modifier.fillMaxWidth()
                        .clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(colors.bgSecondary)
                        .then(if (onSelect != null) Modifier.clickable { onSelect(p.text) } else Modifier)
                        .padding(horizontal = 12.dp, vertical = 10.dp),
                )
            }
        }
    }
}

/** Unified search results grouped by kind. Spec: Search/SearchResults. */
@Composable
fun SearchResults(
    groups: List<SearchResultGroup>,
    query: String,
    onOpen: ((SearchResultItem) -> Unit)? = null,
    onViewAll: ((SearchResultKind) -> Unit)? = null,
) {
    val colors = flareColors()
    val nonEmpty = groups.filter { it.items.isNotEmpty() }
    if (nonEmpty.isEmpty()) {
        Text(
            flareStrings().noResults,
            color = colors.textTertiary,
            fontSize = FlareSizes.fontSizeSm.value.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp),
        )
        return
    }
    Column(Modifier.fillMaxWidth()) {
        nonEmpty.forEach { g ->
            Text(
                g.label,
                color = colors.textTertiary,
                fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeSm.value.sp,
                modifier = Modifier.padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = 12.dp, bottom = 6.dp),
            )
            g.items.forEach { item ->
                Row(
                    Modifier.fillMaxWidth()
                        .then(if (onOpen != null) Modifier.clickable { onOpen(item) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingLg, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(userId = item.id, displayName = item.title, size = 38.dp)
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column(Modifier.weight(1f)) {
                        Text(
                            highlightQuery(item.title, query, colors),
                            color = colors.textPrimary,
                            fontSize = FlareSizes.fontSizeLg.value.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        if (!item.subtitle.isNullOrEmpty()) {
                            Spacer(Modifier.height(2.dp))
                            Text(
                                highlightQuery(item.subtitle, query, colors),
                                color = colors.textTertiary,
                                fontSize = FlareSizes.fontSizeSm.value.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                    if (!item.meta.isNullOrEmpty()) {
                        Spacer(Modifier.width(8.dp))
                        Text(item.meta, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp)
                    }
                }
            }
            if (g.total != null && g.total > g.items.size) {
                Text(
                    flareStrings().viewAll(g.total),
                    color = colors.primary,
                    fontWeight = FontWeight.Medium,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.fillMaxWidth()
                        .then(if (onViewAll != null) Modifier.clickable { onViewAll(g.kind) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingLg, vertical = 10.dp),
                )
            }
        }
    }
}

private fun highlightQuery(text: String, query: String, colors: FlareColors): AnnotatedString {
    val q = query.trim()
    if (q.isEmpty()) return AnnotatedString(text)
    val lower = text.lowercase()
    val lq = q.lowercase()
    if (!lower.contains(lq)) return AnnotatedString(text)
    return buildAnnotatedString {
        var start = 0
        while (true) {
            val idx = lower.indexOf(lq, start)
            if (idx < 0) {
                append(text.substring(start))
                break
            }
            append(text.substring(start, idx))
            withStyle(SpanStyle(color = colors.primary, fontWeight = FontWeight.SemiBold)) {
                append(text.substring(idx, idx + q.length))
            }
            start = idx + q.length
        }
    }
}

/** Loading skeleton placeholders. Spec: Feedback/Skeleton. */
enum class SkeletonVariant { Conversation, Message, Profile, Text }

@Composable
fun Skeleton(
    variant: SkeletonVariant = SkeletonVariant.Conversation,
    rows: Int = 4,
    still: Boolean = false,
) {
    val colors = flareColors()
    val transition = rememberInfiniteTransition(label = "skeleton")
    val progress by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(durationMillis = 1200), RepeatMode.Restart),
        label = "shimmer",
    )
    val brush: Brush = if (still) {
        SolidColor(colors.bgSecondary)
    } else {
        val x = progress * 600f - 300f
        Brush.linearGradient(
            colors = listOf(colors.bgSecondary, colors.bgHover, colors.bgSecondary),
            start = Offset(x, 0f),
            end = Offset(x + 300f, 0f),
        )
    }
    when (variant) {
        SkeletonVariant.Conversation -> Column(Modifier.fillMaxWidth()) {
            repeat(rows) {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    skBlock(Modifier.size(44.dp), brush, CircleShape)
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        skBlock(Modifier.fillMaxWidth(0.42f).height(11.dp), brush)
                        skBlock(Modifier.fillMaxWidth(0.68f).height(11.dp), brush)
                    }
                    Spacer(Modifier.width(8.dp))
                    skBlock(Modifier.width(34.dp).height(11.dp), brush)
                }
            }
        }

        SkeletonVariant.Message -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            val fractions = listOf(0.6f, 0.45f, 0.7f, 0.5f, 0.65f)
            repeat(rows) { i ->
                val fraction = fractions[i % fractions.size]
                if (i % 2 == 0) {
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                        skBlock(Modifier.size(32.dp), brush, CircleShape)
                        Spacer(Modifier.width(FlareSizes.spacingSm))
                        skBlock(
                            Modifier.fillMaxWidth(fraction).height(40.dp),
                            brush,
                            RoundedCornerShape(FlareSizes.radiusLg),
                        )
                    }
                } else {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        skBlock(
                            Modifier.fillMaxWidth(fraction).height(40.dp),
                            brush,
                            RoundedCornerShape(FlareSizes.radiusLg),
                        )
                    }
                }
            }
        }

        SkeletonVariant.Profile -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingXl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            skBlock(Modifier.size(72.dp), brush, CircleShape)
            skBlock(Modifier.fillMaxWidth(0.4f).height(15.dp), brush)
            skBlock(Modifier.fillMaxWidth(0.6f).height(11.dp), brush)
        }

        SkeletonVariant.Text -> Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            val fractions = listOf(0.9f, 0.75f, 0.85f, 0.6f, 0.8f)
            repeat(rows) { i ->
                skBlock(Modifier.fillMaxWidth(fractions[i % fractions.size]).height(11.dp), brush)
            }
        }
    }
}

@Composable
private fun skBlock(modifier: Modifier, brush: Brush, shape: Shape = RoundedCornerShape(6.dp)) {
    Box(modifier.clip(shape).background(brush))
}
