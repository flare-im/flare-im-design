package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp

/**
 * The recent-search list after [term] was used: trimmed, newest first, an exact repeat moves to the front instead of
 * appearing twice, and the oldest fall off past [max]. A blank term changes nothing. The host stores the list (per
 * signed-in user); the rule is here so every client keeps the same one (the Vue kit's `flareRememberSearch`).
 */
fun flareRememberSearch(list: List<String>, term: String, max: Int = 8): List<String> {
    val value = term.trim()
    if (value.isEmpty()) return list
    return (listOf(value) + list.filter { it != value }).take(maxOf(0, max))
}

/**
 * Recent searches — what a search page shows before anything is typed: the terms used last, one tap from searching
 * again, and one way to forget them all. The host owns the list ([flareRememberSearch]); this draws it and reports
 * [onPick] and [onClear] (the clear key is drawn only when handled). With no items it draws nothing, so the page's
 * idle line shows instead. The terms are rows, not capsules: they sit under a row of type capsules and must not be
 * mistaken for filters. Spec: Search/RecentSearches (the Vue kit's `FlareRecentSearches`).
 */
@Composable
fun RecentSearches(
    items: List<String>,
    onPick: ((String) -> Unit)? = null,
    onClear: (() -> Unit)? = null,
    title: String? = null,
    clearText: String? = null,
) {
    if (items.isEmpty()) return
    val colors = flareColors()
    val strings = flareStrings()
    Column(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).padding(horizontal = FlareSizes.spacingLg),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                title ?: strings.recentSearchesTitle,
                modifier = Modifier.weight(1f).semantics { heading() },
                color = colors.textTertiary,
                fontSize = FlareSizes.fontSizeSm.value.sp,
                fontWeight = FontWeight.SemiBold,
            )
            if (onClear != null) {
                androidx.compose.foundation.layout.Box(Modifier.semantics { contentDescription = strings.recentSearchesClearLabel }) {
                    Button(label = clearText ?: strings.recentSearchesClear, variant = FlareButtonVariant.Quiet,
                        size = FlareControlSize.Sm, onClick = onClear)
                }
            }
        }
        items.forEach { term ->
            Row(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                    .then(if (onPick != null) Modifier.clickable { onPick(term) } else Modifier)
                    .padding(horizontal = FlareSizes.spacingLg),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                FlareIcon("clock", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Text(term, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}
