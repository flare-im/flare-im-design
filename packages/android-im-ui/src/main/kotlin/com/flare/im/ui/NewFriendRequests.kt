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
 * [onWithdraw]). A request's [FriendRequest.source] is its own line under the message
 * (the same quiet style, one line with an ellipsis), never on the message's line.
 *
 * Each incoming request answers on its own (Vue `pending` / `errors`): while [pending] holds a request's id, the key
 * being carried out spins and both keys take no taps — other rows stay usable. A failure the host keeps in [errors]
 * shows as a danger line under its row, with [retryLabel] running [onRetry] once the row is no longer pending.
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
    pending: Map<String, FriendRequestAnswer> = emptyMap(),
    errors: Map<String, String> = emptyMap(),
    retryLabel: String? = null,
    onRetry: ((FriendRequest) -> Unit)? = null,
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
          val answering = pending[req.id]
          androidx.compose.foundation.layout.Column(Modifier.fillMaxWidth()) {
            Row(
                Modifier.fillMaxWidth()
                    .then(if (newFriendRequestRowTappable(onView != null)) Modifier.clickable { onView?.invoke(req.id) } else Modifier)
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Avatar(userId = req.userId ?: req.id, displayName = req.name, avatarUrl = req.avatarUrl, size = FlareSizes.avatarSize)
                Spacer(Modifier.width(FlareSizes.spacingMd))
                Column(Modifier.weight(1f)) {
                    Text(req.name, color = colors.textPrimary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp)
                    // The message, then the source: each on a line of its own.
                    for (line in newFriendRequestLines(req)) {
                        Text(line, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
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
                                size = FlareControlSize.Sm, disabled = answering != null,
                                loading = answering == FriendRequestAnswer.Reject, onClick = { onReject(req) })
                        }
                        if (onReject != null && onAccept != null) Spacer(Modifier.width(FlareSizes.spacingSm))
                        if (onAccept != null) {
                            Button(label = acceptLabel, variant = FlareButtonVariant.Primary,
                                size = FlareControlSize.Sm, disabled = answering != null,
                                loading = answering == FriendRequestAnswer.Accept, onClick = { onAccept(req) })
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
            errors[req.id]?.let { message ->
                androidx.compose.foundation.layout.Box(Modifier.padding(start = FlareSizes.spacingMd, end = FlareSizes.spacingMd, bottom = FlareSizes.spacingSm)) {
                    StatusBanner(
                        text = message, tone = FlareStatusTone.Danger,
                        actionText = retryLabel?.takeIf { answering == null && onRetry != null },
                        onAction = { onRetry?.invoke(req) },
                    )
                }
            }
          }
        }
    }
}

/** Row-level tap is only wired when the host supplied [NewFriendRequests]' `onView`. */
internal fun newFriendRequestRowTappable(hasOnView: Boolean): Boolean = hasOnView

/** The quiet lines under a request's name, in order: its message, then its source; blank ones are left out. */
internal fun newFriendRequestLines(request: FriendRequest): List<String> =
    listOfNotNull(request.message, request.source).filter { it.isNotEmpty() }
