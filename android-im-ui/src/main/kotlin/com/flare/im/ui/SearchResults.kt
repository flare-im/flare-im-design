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
import androidx.compose.ui.text.style.TextAlign
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
