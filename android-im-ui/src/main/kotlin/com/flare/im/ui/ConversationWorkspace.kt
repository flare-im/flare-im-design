package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Forum
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp

// MARK: contract ------------------------------------------------------------

/** Which pane a state / retry belongs to. */
enum class FlareWorkspacePaneKey { List, Chat, Detail }

/**
 * Host-reported load status of a single pane. Panes are independent: a failing
 * timeline never degrades an inbox that already loaded.
 */
enum class FlareWorkspacePaneStatus { Ready, Loading, Empty, Failure }

/** What a pane actually renders. */
enum class FlareWorkspacePaneRender { Content, Skeleton, Empty, Failure }

/** Tone of the workspace-wide banner (offline / reconnecting / session expired). */
enum class FlareWorkspaceBannerTone { Info, Warning, Error, Success }

/** One pane's host-reported state. */
data class FlareWorkspacePaneState(
    /** Defaults to [FlareWorkspacePaneStatus.Ready]. */
    val status: FlareWorkspacePaneStatus = FlareWorkspacePaneStatus.Ready,
    /** User-facing text: the empty explanation, or the failure cause. */
    val message: String? = null,
    /** Recovery action label. Without it no button is offered, only the reason. */
    val actionLabel: String? = null,
)

/** Cross-pane notice rendered above all three panes. */
data class FlareWorkspaceBanner(
    val message: String,
    val tone: FlareWorkspaceBannerTone = FlareWorkspaceBannerTone.Info,
    val actionLabel: String? = null,
)

/**
 * Map a host pane state onto what to render. A missing state and
 * [FlareWorkspacePaneStatus.Ready] both fall back to the host content: an
 * unresolved status must never blank a pane or fake an empty list.
 */
fun paneRender(state: FlareWorkspacePaneState?): FlareWorkspacePaneRender = when (state?.status) {
    FlareWorkspacePaneStatus.Loading -> FlareWorkspacePaneRender.Skeleton
    FlareWorkspacePaneStatus.Empty -> FlareWorkspacePaneRender.Empty
    FlareWorkspacePaneStatus.Failure -> FlareWorkspacePaneRender.Failure
    else -> FlareWorkspacePaneRender.Content
}

/**
 * Whether the pane failure offers a recovery button. Needs all three: an actual
 * failure, a non-blank label, and a host handler — a button the host cannot
 * service is worse than no button.
 */
fun paneRetryVisible(state: FlareWorkspacePaneState?, hasRetry: Boolean): Boolean {
    if (!hasRetry) return false
    if (paneRender(state) != FlareWorkspacePaneRender.Failure) return false
    return !state?.actionLabel.isNullOrBlank()
}

/**
 * Whether the cross-pane banner shows at all. Blank or whitespace-only messages
 * are not a banner. Independent of pane state: an offline banner can sit above a
 * list that still reads fine from cache.
 */
fun workspaceBannerVisible(banner: FlareWorkspaceBanner?): Boolean = !banner?.message.isNullOrBlank()

/** Whether the banner's inline action renders (non-blank label + host handler). */
fun workspaceBannerActionVisible(banner: FlareWorkspaceBanner?, hasAction: Boolean): Boolean {
    if (!hasAction || !workspaceBannerVisible(banner)) return false
    return !banner?.actionLabel.isNullOrBlank()
}

/** StatusBanner tone for a workspace tone; `Error` is StatusBanner's `Danger`. */
fun workspaceBannerTone(tone: FlareWorkspaceBannerTone?): FlareStatusTone = when (tone) {
    FlareWorkspaceBannerTone.Warning -> FlareStatusTone.Warning
    FlareWorkspaceBannerTone.Error -> FlareStatusTone.Danger
    FlareWorkspaceBannerTone.Success -> FlareStatusTone.Success
    else -> FlareStatusTone.Info
}

/** Skeleton shape per pane: rows for the inbox, bubbles for the timeline, a card for details. */
fun paneSkeletonVariant(pane: FlareWorkspacePaneKey): SkeletonVariant = when (pane) {
    FlareWorkspacePaneKey.Chat -> SkeletonVariant.Message
    FlareWorkspacePaneKey.Detail -> SkeletonVariant.Profile
    FlareWorkspacePaneKey.List -> SkeletonVariant.Conversation
}

private fun paneEmptyIcon(pane: FlareWorkspacePaneKey): ImageVector = when (pane) {
    FlareWorkspacePaneKey.Chat -> Icons.Outlined.ChatBubbleOutline
    FlareWorkspacePaneKey.Detail -> Icons.Outlined.Info
    FlareWorkspacePaneKey.List -> Icons.Outlined.Forum
}

private fun workspaceText(value: String?, fallback: String): String =
    if (value.isNullOrBlank()) fallback else value

// MARK: composable ----------------------------------------------------------

/**
 * The conversation workspace: [ResponsiveLayout] plus ONE place where every pane
 * resolves loading / empty / failure, so hosts stop re-writing a skeleton, an
 * empty card and an error card per app and per pane.
 *
 * It owns no data and performs no side effect: pane content stays in [list] /
 * [chat] / [detail], splitting and breakpoints stay in [ResponsiveLayout],
 * recovery stays with the host via [onRetry].
 * Spec: Layout/ConversationWorkspace (`ConversationWorkspace`).
 */
@Composable
fun ConversationWorkspace(
    list: @Composable () -> Unit,
    chat: @Composable () -> Unit,
    detail: (@Composable () -> Unit)? = null,
    activePane: FlarePane = FlarePane.List,
    listWidth: Dp = FlareSizes.leftPanel,
    detailWidth: Dp = FlareSizes.rightPanel,
    onPaneChange: ((FlarePane) -> Unit)? = null,
    hideMobileBar: Boolean = false,
    backLabel: String = flareStrings().back,
    listState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    chatState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    detailState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    banner: FlareWorkspaceBanner? = null,
    onRetry: ((FlareWorkspacePaneKey) -> Unit)? = null,
    onBannerAction: (() -> Unit)? = null,
    listEmptyText: String = "暂无会话",
    chatEmptyText: String = "选择一个会话开始聊天",
    detailEmptyText: String = "暂无详情",
    listFailureText: String = "会话列表加载失败",
    chatFailureText: String = "消息加载失败",
    detailFailureText: String = "详情加载失败",
    listLoadingText: String = "正在加载会话列表",
    chatLoadingText: String = "正在加载消息",
    detailLoadingText: String = "正在加载详情",
) {
    val showBanner = workspaceBannerVisible(banner)
    val bannerAction = workspaceBannerActionVisible(banner, onBannerAction != null)

    @Composable
    fun pane(
        key: FlareWorkspacePaneKey,
        content: @Composable () -> Unit,
        state: FlareWorkspacePaneState,
        emptyText: String,
        failureText: String,
        loadingText: String,
        rows: Int,
    ) {
        when (paneRender(state)) {
            FlareWorkspacePaneRender.Content -> content()
            // A labelled skeleton — never an empty list pretending there is nothing to show.
            FlareWorkspacePaneRender.Skeleton -> Column(
                Modifier
                    .fillMaxWidth()
                    .padding(FlareSizes.spacingLg)
                    .semantics {
                        contentDescription = loadingText
                        liveRegion = LiveRegionMode.Polite
                    },
            ) { Skeleton(variant = paneSkeletonVariant(key), rows = rows) }
            FlareWorkspacePaneRender.Empty -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                EmptyState(title = workspaceText(state.message, emptyText), icon = paneEmptyIcon(key))
            }
            FlareWorkspacePaneRender.Failure -> {
                val retry = paneRetryVisible(state, onRetry != null)
                Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg)) {
                    StatusBanner(
                        text = workspaceText(state.message, failureText),
                        tone = FlareStatusTone.Danger,
                        actionText = if (retry) state.actionLabel else null,
                        onAction = if (retry) ({ onRetry?.invoke(key) }) else null,
                    )
                }
            }
        }
    }

    Column(Modifier.fillMaxSize()) {
        if (showBanner && banner != null) {
            Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingSm)) {
                StatusBanner(
                    text = banner.message,
                    tone = workspaceBannerTone(banner.tone),
                    actionText = if (bannerAction) banner.actionLabel else null,
                    onAction = if (bannerAction) onBannerAction else null,
                )
            }
            HorizontalDivider()
        }
        Box(Modifier.weight(1f)) {
            ResponsiveLayout(
                list = {
                    pane(
                        FlareWorkspacePaneKey.List, list, listState,
                        listEmptyText, listFailureText, listLoadingText, rows = 6,
                    )
                },
                chat = {
                    pane(
                        FlareWorkspacePaneKey.Chat, chat, chatState,
                        chatEmptyText, chatFailureText, chatLoadingText, rows = 5,
                    )
                },
                // The detail pane must exist whenever it has something to say: with a
                // null slot but a non-ready state the host has no content yet — which is
                // exactly when the loading / empty / failure panel is the point.
                detail = if (detail == null && detailState.status == FlareWorkspacePaneStatus.Ready) null else ({
                    pane(
                        FlareWorkspacePaneKey.Detail, detail ?: {}, detailState,
                        detailEmptyText, detailFailureText, detailLoadingText, rows = 1,
                    )
                }),
                activePane = activePane,
                listWidth = listWidth,
                detailWidth = detailWidth,
                onPaneChange = onPaneChange,
                hideMobileBar = hideMobileBar,
                backLabel = backLabel,
            )
        }
    }
}
