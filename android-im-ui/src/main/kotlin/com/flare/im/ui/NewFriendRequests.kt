package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * New friends — incoming friend requests with accept / reject and a note.
 * Spec: Contacts/NewFriendRequests (`NewFriendRequests`).
 *
 * [onView] receives the request id when the row itself is tapped (open the
 * applicant's detail). Without it the row is inert — no dead affordance.
 */
@Composable
fun NewFriendRequests(
    items: List<FriendRequest>,
    emptyText: String = "暂无新的好友申请",
    acceptLabel: String = "接受",
    declineLabel: String = "拒绝",
    onAccept: ((FriendRequest) -> Unit)? = null,
    onReject: ((FriendRequest) -> Unit)? = null,
    onView: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    if (items.isEmpty()) {
        EmptyState(title = emptyText)
        return
    }
    LazyColumn(Modifier.fillMaxWidth()) {
        items(items, key = { it.id }) { req ->
            Row(
                Modifier.fillMaxWidth()
                    .then(if (newFriendRequestRowTappable(onView != null)) Modifier.clickable { onView?.invoke(req.id) } else Modifier)
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Avatar(userId = req.id, displayName = req.name, size = 44.dp)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    Text(req.name, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeXl.value.sp)
                    if (!req.message.isNullOrEmpty()) {
                        Text(req.message, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
                OutlinedButton(onClick = { onReject?.invoke(req) }, contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp, vertical = 4.dp)) {
                    Text(declineLabel, fontSize = 13.sp)
                }
                Spacer(Modifier.width(8.dp))
                Button(onClick = { onAccept?.invoke(req) },
                    colors = ButtonDefaults.buttonColors(containerColor = colors.primary),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 14.dp, vertical = 4.dp)) {
                    Text(acceptLabel, fontSize = 13.sp)
                }
            }
        }
    }
}

/** Row-level tap is only wired when the host supplied [NewFriendRequests]' `onView`. */
internal fun newFriendRequestRowTappable(hasOnView: Boolean): Boolean = hasOnView
