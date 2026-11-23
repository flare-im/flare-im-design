package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
        EmptyState(title = flareStrings().searchEmpty, description = flareStrings().searchEmptyHint, icon = "search")
        return
    }
    Column(Modifier.fillMaxWidth()) {
        nonEmpty.forEach { g ->
            Text(
                g.label,
                color = colors.textTertiary,
                fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeSm.value.sp,
                modifier = Modifier.padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacing2xs),
            )
            g.items.forEach { item ->
                Row(
                    Modifier.fillMaxWidth()
                        .then(if (onOpen != null) Modifier.clickable { onOpen(item) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Avatar(userId = item.id, displayName = item.title, size = 38.dp, avatarUrl = item.avatarUrl)
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
                                highlightQuery(if (item.kind == SearchResultKind.Message) flareSearchExcerpt(item.subtitle, query) else item.subtitle, query, colors),
                                color = colors.textTertiary,
                                fontSize = FlareSizes.fontSizeSm.value.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                    if (!item.meta.isNullOrEmpty()) {
                        Spacer(Modifier.width(8.dp))
                        Text(item.meta, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                    }
                }
            }
            val counted = g.total != null && g.total > g.items.size
            if (counted || g.hasMore) {
                Text(
                    flareSearchMoreText(g, flareStrings()),
                    color = colors.primaryText,
                    fontWeight = FontWeight.Medium,
                    fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.fillMaxWidth()
                        .then(if (onViewAll != null) Modifier.clickable { onViewAll(g.kind) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacing2sm),
                )
            }
        }
    }
}

/** The truncated group's last row: the counted "查看全部 N" when the total is known, "查看更多" otherwise. */
internal fun flareSearchMoreText(group: SearchResultGroup, strings: FlareStrings): String {
    val total = group.total
    return if (total != null && total > group.items.size) strings.viewAll(total) else strings.searchViewMore
}

/** Keeps a message hit's first match in view in a long sentence (the Vue kit's excerpt): 24 before it, 128 in all. */
internal fun flareSearchExcerpt(text: String, query: String): String {
    val q = query.trim()
    val at = if (q.isEmpty()) -1 else text.indexOf(q, ignoreCase = true)
    val points = text.codePoints().toArray()
    if (at < 0 || points.size <= 128) return text
    val from = text.codePointCount(0, at)
    val start = maxOf(0, from - 24)
    val end = minOf(points.size, maxOf(start + 128, from + q.codePointCount(0, q.length) + 24))
    return (if (start > 0) "…" else "") + String(points, start, end - start) + (if (end < points.size) "…" else "")
}

internal fun highlightQuery(text: String, query: String, colors: FlareColors): AnnotatedString {
    val q = query.trim()
    if (q.isEmpty()) return AnnotatedString(text)
    return buildAnnotatedString {
        var start = 0
        Regex(Regex.escape(q), RegexOption.IGNORE_CASE).findAll(text).forEach { match ->
            append(text.substring(start, match.range.first))
            withStyle(SpanStyle(color = colors.primaryText, fontWeight = FontWeight.SemiBold)) {
                append(match.value)
            }
            start = match.range.last + 1
        }
        append(text.substring(start))
    }
}
