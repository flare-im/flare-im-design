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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * New friends — friend requests with a note: incoming ones with accept / reject,
 * outgoing ones with their pending status and withdraw.
 * Spec: Contacts/NewFriendRequests (`NewFriendRequests`).
 *
 * [onView] receives the request id when the row itself is tapped (open the
 * applicant's detail). Without it the row is inert — no dead affordance. Each
 * action button likewise exists only with its callback ([onAccept], [onReject],
 * [onWithdraw]).
 */
@Suppress("NAME_SHADOWING")
@Composable
fun NewFriendRequests(
    items: List<FriendRequest>,
    emptyText: String? = null,
    acceptLabel: String? = null,
    declineLabel: String? = null,
    onAccept: ((FriendRequest) -> Unit)? = null,
    onReject: ((FriendRequest) -> Unit)? = null,
    onView: ((String) -> Unit)? = null,
    withdrawLabel: String? = null,
    onWithdraw: ((FriendRequest) -> Unit)? = null,
) {
    val strings = flareStrings()
    val emptyText = emptyText ?: strings.newFriendRequestsEmpty
    val acceptLabel = acceptLabel ?: strings.newFriendRequestsAccept
    val declineLabel = declineLabel ?: strings.newFriendRequestsDecline
    val withdrawLabel = withdrawLabel ?: strings.newFriendRequestsWithdraw
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
                Avatar(userId = req.id, displayName = req.name, size = FlareSizes.avatarSize)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    Text(req.name, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp)
                    if (!req.message.isNullOrEmpty()) {
                        Text(req.message, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
                when (req.direction) {
                    FriendRequestDirection.Incoming -> {
                        // 两颗都走 kit 自己的 Button。从前这里是 Material 的 OutlinedButton +
                        // Button:一是 kit 没有「中性的低强度」这一档(现在有了 Quiet),二是
                        // `import androidx.compose.material3.Button` 和本包自己声明的 Button
                        // 重名,重载按参数名静默选中 —— 写 `colors =` 就悄悄走了 Material 那个。
                        if (onReject != null) {
                            Button(label = declineLabel, variant = FlareButtonVariant.Quiet,
                                size = FlareControlSize.Sm, onClick = { onReject(req) })
                        }
                        if (onReject != null && onAccept != null) Spacer(Modifier.width(FlareSizes.spacingSm))
                        if (onAccept != null) {
                            Button(label = acceptLabel, variant = FlareButtonVariant.Primary,
                                size = FlareControlSize.Sm, onClick = { onAccept(req) })
                        }
                    }
                    FriendRequestDirection.Outgoing -> {
                        // Waiting on the other side: the status in words, withdraw only when the host can.
                        Text(strings.newFriendRequestsPending, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm.value.sp)
                        if (onWithdraw != null) {
                            Spacer(Modifier.width(FlareSizes.spacingSm))
                            Button(label = withdrawLabel, variant = FlareButtonVariant.Quiet,
                                size = FlareControlSize.Sm, onClick = { onWithdraw(req) })
                        }
                    }
                }
            }
        }
    }
}

/** Row-level tap is only wired when the host supplied [NewFriendRequests]' `onView`. */
internal fun newFriendRequestRowTappable(hasOnView: Boolean): Boolean = hasOnView
