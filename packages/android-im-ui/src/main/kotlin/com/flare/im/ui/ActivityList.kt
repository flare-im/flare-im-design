package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

/**
 * One row of an [ActivityList]: who did what ([title]), an excerpt ([description]), when ([time]) and whether it is
 * still [unread]. [avatarSeed] colours the initials avatar when there is no [avatarUrl].
 */
data class FlareActivityItem(
    val id: String,
    val title: String,
    val description: String? = null,
    val time: String? = null,
    val avatarUrl: String? = null,
    val avatarSeed: String = id,
    val unread: Boolean = false,
)

/**
 * A list of activity — likes, comments and replies on what the reader posted or took part in. Spec:
 * General/ActivityList (`FlareActivityList.vue`, compact density).
 *
 * Each row: a 32 avatar, the title (semi-bold while unread), up to two lines of description, the time, and a dot at the
 * end while unread, read aloud with `activityUnreadSuffix`. A row is a control only with [onOpen]; [disabled] dims the
 * list and takes no taps (while the host loads, marks or opens one). With no [items] the list is the empty state
 * [emptyTitle] / [emptyHint] and its [emptyActionText] → [onEmptyAction]. [footer] ends the list — the host's load
 * more, or why the next page did not load.
 */
@Composable
fun ActivityList(
    items: List<FlareActivityItem>,
    emptyTitle: String,
    modifier: Modifier = Modifier,
    onOpen: ((FlareActivityItem) -> Unit)? = null,
    disabled: Boolean = false,
    emptyHint: String? = null,
    emptyActionText: String? = null,
    onEmptyAction: (() -> Unit)? = null,
    state: LazyListState = rememberLazyListState(),
    footer: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    if (items.isEmpty()) {
        Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            EmptyState(title = emptyTitle, description = emptyHint, actionText = emptyActionText, icon = "notification", onAction = onEmptyAction)
        }
        return
    }
    LazyColumn(modifier.fillMaxSize().flareDimmed(if (disabled) FlareOpacity.disabled else 1f), state = state) {
        items(items, key = { it.id }) { item ->
            val spoken = listOfNotNull(item.title, item.description, item.time).joinToString("，") +
                if (item.unread) strings.activityUnreadSuffix else ""
            Row(
                Modifier.fillMaxWidth()
                    .then(
                        if (onOpen != null) Modifier.clearAndSetSemantics {
                            contentDescription = spoken
                            role = Role.Button
                            if (!disabled) onClick { onOpen(item); true }
                        }.clickable(enabled = !disabled) { onOpen(item) }
                        else Modifier.clearAndSetSemantics { contentDescription = spoken },
                    )
                    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.Top,
            ) {
                Avatar(userId = item.avatarSeed, displayName = item.title, avatarUrl = item.avatarUrl, size = 32.dp)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    Text(
                        item.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd,
                        fontWeight = if (item.unread) FontWeight.SemiBold else FontWeight.Normal,
                        maxLines = 2, overflow = TextOverflow.Ellipsis,
                    )
                    item.description?.takeIf { it.isNotBlank() }?.let {
                        Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, maxLines = 2, overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.padding(top = 2.dp))
                    }
                    item.time?.takeIf { it.isNotBlank() }?.let {
                        Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs, modifier = Modifier.padding(top = 2.dp))
                    }
                }
                if (item.unread) {
                    Spacer(Modifier.width(FlareSizes.spacingSm))
                    Box(Modifier.padding(top = FlareSizes.spacing2xs).size(8.dp).clip(CircleShape).background(colors.error))
                }
            }
        }
        if (footer != null) item(key = "footer") { footer() }
    }
}
