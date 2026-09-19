package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
    /** Second line under an empty explanation — what the user can do about it. */
    val description: String? = null,
    /**
     * Label of the one action this state offers: retry on a failure, the next
     * step on an empty pane. Without it no button is offered, only the reason.
     */
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
 * Whether an empty pane offers a next step. Same three conditions as a retry —
 * the state, a non-blank label and a host handler — because an empty list whose
 * only affordance does nothing is worse than one with no affordance at all.
 */
fun paneEmptyActionVisible(state: FlareWorkspacePaneState?, hasAction: Boolean): Boolean {
    if (!hasAction) return false
    if (paneRender(state) != FlareWorkspacePaneRender.Empty) return false
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

/** The registry icon name each pane shows when it is empty. */
internal fun paneEmptyIcon(pane: FlareWorkspacePaneKey): String = when (pane) {
    FlareWorkspacePaneKey.Chat -> "comment"
    FlareWorkspacePaneKey.Detail -> "info"
    FlareWorkspacePaneKey.List -> "chats"
}

internal fun workspaceText(value: String?, fallback: String): String =
    if (value.isNullOrBlank()) fallback else value

/**
 * One pane's four outcomes, in one place: host content, a skeleton while it
 * loads, an explanation when it is empty, a reason plus recovery when it failed.
 *
 * Both [ConversationWorkspace] and [WorkspaceFrame] render their panes through
 * it, so the inbox and a settings surface fail the same way instead of two
 * dialects of "something went wrong".
 */
@Composable
fun WorkspacePane(
    state: FlareWorkspacePaneState,
    skeleton: SkeletonVariant = SkeletonVariant.Conversation,
    skeletonRows: Int = 6,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    emptyIcon: String = "folder",
    emptyText: String = "",
    failureText: String = "",
    loadingText: String = "",
    onRetry: (() -> Unit)? = null,
    onEmptyAction: (() -> Unit)? = null,
    content: @Composable () -> Unit,
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
        ) { Skeleton(variant = skeleton, rows = skeletonRows) }
        FlareWorkspacePaneRender.Empty -> {
            val action = paneEmptyActionVisible(state, onEmptyAction != null)
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                EmptyState(
                    title = workspaceText(state.message, emptyText),
                    description = state.description,
                    icon = emptyIcon,
                    actionText = if (action) state.actionLabel else null,
                    onAction = if (action) ({ onEmptyAction?.invoke() }) else null,
                )
            }
        }
        FlareWorkspacePaneRender.Failure -> {
            val retry = paneRetryVisible(state, onRetry != null)
            Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg)) {
                StatusBanner(
                    text = workspaceText(state.message, failureText),
                    tone = FlareStatusTone.Danger,
                    actionText = if (retry) state.actionLabel else null,
                    onAction = if (retry) ({ onRetry?.invoke() }) else null,
                )
            }
        }
    }
}

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
@Suppress("NAME_SHADOWING")
@Composable
fun ConversationWorkspace(
    list: @Composable () -> Unit,
    chat: @Composable () -> Unit,
    detail: (@Composable () -> Unit)? = null,
    activePane: FlarePane = FlarePane.List,
    listWidth: Dp = FlareSizes.primaryPaneDefaultWidth,
    detailWidth: Dp = FlareSizes.detailPaneDefaultWidth,
    onPaneChange: ((FlarePane) -> Unit)? = null,
    hideMobileBar: Boolean = false,
    backLabel: String = flareStrings().back,
    onLayoutChange: ((FlareWorkspacePresentation) -> Unit)? = null,
    listState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    chatState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    detailState: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    banner: FlareWorkspaceBanner? = null,
    onRetry: ((FlareWorkspacePaneKey) -> Unit)? = null,
    onEmptyAction: ((FlareWorkspacePaneKey) -> Unit)? = null,
    onBannerAction: (() -> Unit)? = null,
    listEmptyText: String? = null,
    chatEmptyText: String? = null,
    detailEmptyText: String? = null,
    listFailureText: String? = null,
    chatFailureText: String? = null,
    detailFailureText: String? = null,
    listLoadingText: String? = null,
    chatLoadingText: String? = null,
    detailLoadingText: String? = null,
) {
    val strings = flareStrings()
    val listEmptyText = listEmptyText ?: strings.conversationWorkspaceListEmpty
    val chatEmptyText = chatEmptyText ?: strings.conversationWorkspaceChatEmpty
    val detailEmptyText = detailEmptyText ?: strings.conversationWorkspaceDetailEmpty
    val listFailureText = listFailureText ?: strings.conversationWorkspaceListFailure
    val chatFailureText = chatFailureText ?: strings.conversationWorkspaceChatFailure
    val detailFailureText = detailFailureText ?: strings.conversationWorkspaceDetailFailure
    val listLoadingText = listLoadingText ?: strings.conversationWorkspaceListLoading
    val chatLoadingText = chatLoadingText ?: strings.conversationWorkspaceChatLoading
    val detailLoadingText = detailLoadingText ?: strings.conversationWorkspaceDetailLoading
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
    ) = WorkspacePane(
        state = state,
        skeleton = paneSkeletonVariant(key),
        skeletonRows = rows,
        emptyIcon = paneEmptyIcon(key),
        emptyText = emptyText,
        failureText = failureText,
        loadingText = loadingText,
        onRetry = onRetry?.let { handler -> { handler(key) } },
        onEmptyAction = onEmptyAction?.let { handler -> { handler(key) } },
        content = content,
    )

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
                onLayoutChange = onLayoutChange,
            )
        }
    }
}
