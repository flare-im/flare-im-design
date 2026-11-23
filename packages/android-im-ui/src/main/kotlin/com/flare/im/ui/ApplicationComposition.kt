package com.flare.im.ui

import androidx.compose.ui.platform.LocalFocusManager

import androidx.compose.foundation.layout.imePadding

import androidx.compose.foundation.layout.ime

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.foundation.layout.height
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Text
import androidx.compose.material3.Surface
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.draw.drawBehind
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.Arrangement

enum class FlareApplicationResponsiveMode { Mobile, Tablet, Desktop, WideDesktop }

enum class FlareApplicationNavigationPresentation { Bottom, Rail, Sidebar, ExpandedSidebar }

enum class FlareApplicationWorkspacePane { Primary, Content, Detail }

enum class FlareApplicationViewStatus { Loading, Ready, Empty, Error, Offline }

/**
 * A navigation item's badge. A [Kind.Count] badge reads [count], or 99+ above 99 or when [more] says there are more than
 * the count (the server had more than it counted) — [flareCountBadgeText], `spec/count-badge-vectors.json`.
 */
data class FlareApplicationNavigationBadge(
    val kind: Kind = Kind.Count,
    val count: Int = 0,
    val label: String? = null,
    val more: Boolean = false,
) {
    enum class Kind { Dot, Count, Mention }
}

data class FlareApplicationNavigationItem(
    val id: String,
    val label: String,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    val icon: String,
    val accessibilityLabel: String = label,
    val badge: FlareApplicationNavigationBadge? = null,
    val enabled: Boolean = true,
    val visible: Boolean = true,
    val order: Int? = null,
    val capability: String? = null,
    val intent: FlareNavigationIntent? = null,
)

data class FlareApplicationNavigationGroup(
    val id: String,
    val items: List<FlareApplicationNavigationItem>,
    val label: String? = null,
)

data class FlareApplicationViewState<T>(
    val status: FlareApplicationViewStatus = FlareApplicationViewStatus.Ready,
    val value: T? = null,
    /** What went wrong, for [FlareApplicationViewStatus.Error] and `Offline`; never the empty words (FR-057). */
    val error: String? = null,
    /** What an empty list should say. Without it the container falls back to its own words. */
    val emptyTitle: String? = null,
    /**
     * A failed refresh over content that is still worth showing: the rows stay and the failure is a
     * banner above them, instead of replacing everything a person was reading (FR-057).
     */
    val stale: Boolean = false,
    val hasMore: Boolean = false,
)

/** What a container draws for a state: the rows, the rows under a banner, or a state of its own. */
enum class FlareViewPresentation { Content, ContentWithNotice, State }

/** How a list container presents a state (`spec/view-state-vectors.json`, the same table on four kits). */
fun flareViewPresentation(status: FlareApplicationViewStatus, stale: Boolean): FlareViewPresentation {
    if (status == FlareApplicationViewStatus.Ready) return FlareViewPresentation.Content
    val failed = status == FlareApplicationViewStatus.Error || status == FlareApplicationViewStatus.Offline
    return if (stale && failed) FlareViewPresentation.ContentWithNotice else FlareViewPresentation.State
}

data class FlareCapabilitySet(val values: Set<String> = emptySet()) {
    fun contains(capability: String): Boolean = capability in values
}

/**
 * The default IM tabs — 消息 / 通讯录 / 我 — labelled from [strings] and drawn from the icon registry
 * (Vue `FLARE_DEFAULT_IM_NAVIGATION` ids and names). A host that overrides [LocalFlareStrings] gets its
 * own wording without rebuilding the list; a host that wants other tabs passes its own items.
 */
fun flareDefaultIMNavigation(strings: FlareStrings = FlareStrings()): List<FlareApplicationNavigationItem> = listOf(
    FlareApplicationNavigationItem("chats", strings.navigationChats, "chats", order = 0),
    FlareApplicationNavigationItem("contacts", strings.navigationContacts, "people", order = 1),
    FlareApplicationNavigationItem("profile", strings.navigationProfile, "person", order = 2),
)

/** The default contact-directory sections — 好友 / 群聊 / 新的朋友 / 收藏 — from [strings] and the registry. */
fun flareDefaultContactNavigation(strings: FlareStrings = FlareStrings()): List<FlareApplicationNavigationItem> = listOf(
    FlareApplicationNavigationItem("friends", strings.navigationFriends, "person", order = 0),
    FlareApplicationNavigationItem("groups", strings.navigationGroups, "people", order = 1),
    FlareApplicationNavigationItem("newFriends", strings.navigationNewFriends, "person-add", order = 2),
    FlareApplicationNavigationItem("favorites", strings.favorites, "star", order = 3),
)

fun resolveNavigationItems(
    defaults: List<FlareApplicationNavigationItem>,
    items: List<FlareApplicationNavigationItem>? = null,
    capabilities: FlareCapabilitySet = FlareCapabilitySet(),
): List<FlareApplicationNavigationItem> {
    val seen = mutableSetOf<String>()
    return (items ?: defaults)
        .withIndex()
        .filter { (_, item) -> item.id.isNotEmpty() && item.visible && seen.add(item.id) }
        .filter { (_, item) -> item.capability == null || capabilities.contains(item.capability) }
        .sortedWith(compareBy<IndexedValue<FlareApplicationNavigationItem>> { it.value.order ?: it.index }.thenBy { it.index })
        .map { it.value }
}

data class FlareApplicationFeatures(
    val search: Boolean = true,
    val contacts: Boolean = true,
    val groups: Boolean = true,
    val calls: Boolean = false,
    val media: Boolean = true,
    val savedMessages: Boolean = true,
    val settings: Boolean = true,
)

data class FlareIMAppConfiguration(
    val features: FlareApplicationFeatures = FlareApplicationFeatures(),
    val capabilities: FlareCapabilitySet = FlareCapabilitySet(),
    val locale: String? = null,
)

fun interface FlareDataSource<Request, Result> {
    suspend fun load(request: Request): FlareApplicationViewState<Result>
}

interface FlareIMHostAdapter {
    suspend fun execute(intent: FlareNavigationIntent): Result<Unit>
}

sealed interface FlareNavigationIntent {
    data class OpenConversation(val conversationId: String) : FlareNavigationIntent
    data class OpenContact(val contactId: String) : FlareNavigationIntent
    data class OpenGroup(val groupId: String) : FlareNavigationIntent
    data class OpenSearch(val query: String = "") : FlareNavigationIntent
    data object OpenSettings : FlareNavigationIntent
    data class Custom(val id: String, val payload: Map<String, String> = emptyMap()) : FlareNavigationIntent
}

data class FlareMessageActionExtension(
    val id: String,
    val label: String,
    val capability: String? = null,
    val group: String? = null,
    val order: Int? = null,
    val visible: Boolean = true,
    val enabled: (messageId: String) -> Boolean = { true },
    val available: (messageId: String) -> Boolean = { true },
    val intent: String? = null,
    val accessibilityLabel: String = label,
    val disabledReason: String? = null,
    val invoke: (messageId: String) -> Unit,
)

/** Shared breakpoints with Vue/Flutter/SwiftUI: 600 / 900 / 1500 on width divided by the text scale. */
fun resolveApplicationResponsiveMode(width: Dp, textScale: Float = 1f): FlareApplicationResponsiveMode {
    val effective = width.value / textScale.coerceAtLeast(1f)
    return when {
        effective < FlareSizes.navigationRailMinWidth.value -> FlareApplicationResponsiveMode.Mobile
        effective < FlareSizes.appShellCompactMinWidth.value -> FlareApplicationResponsiveMode.Tablet
        effective < FlareSizes.appShellExpandedMinWidth.value -> FlareApplicationResponsiveMode.Desktop
        else -> FlareApplicationResponsiveMode.WideDesktop
    }
}

enum class FlareWorkspacePaneMode { SinglePane, DualPane, TriplePane }

enum class FlareWorkspaceDetailPresentation { Hidden, Inline, Overlay, Route }

data class FlareWorkspacePresentation(val paneMode: FlareWorkspacePaneMode, val detail: FlareWorkspaceDetailPresentation)

/** Width the navigation presentation for [mode] occupies beside the panes. */
fun resolveNavigationWidth(mode: FlareApplicationResponsiveMode): Dp = when (mode) {
    FlareApplicationResponsiveMode.Mobile -> 0.dp
    FlareApplicationResponsiveMode.Tablet -> FlareSizes.navigationRailWidth
    FlareApplicationResponsiveMode.WideDesktop -> FlareSizes.primaryPaneDefaultWidth
    FlareApplicationResponsiveMode.Desktop -> FlareSizes.primaryPaneMinWidth
}

/**
 * Width that [paneMode] needs side by side — the one pane rule of every layout in the kit (FR-110,
 * `spec/application-layout-vectors.json` `panes`). Two panes: navigation + list + a usable chat
 * ([FlareSizes.chatMinWidth] times the text scale, never less than the minimum); three: that plus the detail.
 * Navigation, list and detail are drawn at fixed widths, so only the chat grows with the text.
 * A 72dp rail + 320dp list + 360dp chat = 752dp. One pane needs nothing.
 */
fun paneModeMinWidth(
    paneMode: FlareWorkspacePaneMode,
    navigationWidth: Dp = 0.dp,
    primaryWidth: Dp = FlareSizes.primaryPaneDefaultWidth,
    detailWidth: Dp = FlareSizes.detailPaneDefaultWidth,
    textScale: Float = 1f,
): Dp {
    if (paneMode == FlareWorkspacePaneMode.SinglePane) return 0.dp
    val scale = if (textScale.isFinite()) textScale.coerceAtLeast(1f) else 1f
    val two = navigationWidth.value.coerceAtLeast(0f) + primaryWidth.value.coerceAtLeast(0f) +
        FlareSizes.chatMinWidth.value * scale
    return (if (paneMode == FlareWorkspacePaneMode.DualPane) two else two + detailWidth.value.coerceAtLeast(0f)).dp
}

/** The most panes that fit side by side in [width] (a third only when there is a detail to show). */
fun resolvePaneMode(
    width: Dp,
    hasDetail: Boolean = false,
    textScale: Float = 1f,
    navigationWidth: Dp = 0.dp,
    primaryWidth: Dp = FlareSizes.primaryPaneDefaultWidth,
    detailWidth: Dp = FlareSizes.detailPaneDefaultWidth,
): FlareWorkspacePaneMode {
    fun needs(mode: FlareWorkspacePaneMode) =
        paneModeMinWidth(mode, navigationWidth, primaryWidth, detailWidth, textScale).value
    return when {
        !(width.value >= needs(FlareWorkspacePaneMode.DualPane)) -> FlareWorkspacePaneMode.SinglePane
        hasDetail && width.value >= needs(FlareWorkspacePaneMode.TriplePane) -> FlareWorkspacePaneMode.TriplePane
        else -> FlareWorkspacePaneMode.DualPane
    }
}

/**
 * Shared rule (spec/application-layout-vectors.json): the pane rule above with the navigation [mode] draws, and
 * the detail inline only when three panes fit.
 */
fun resolveWorkspacePresentation(
    mode: FlareApplicationResponsiveMode,
    hasDetail: Boolean = false,
    width: Dp? = null,
    textScale: Float = 1f,
    navigationWidth: Dp? = null,
    primaryWidth: Dp = FlareSizes.primaryPaneDefaultWidth,
    detailWidth: Dp = FlareSizes.detailPaneDefaultWidth,
): FlareWorkspacePresentation {
    val routed = if (hasDetail) FlareWorkspaceDetailPresentation.Route else FlareWorkspaceDetailPresentation.Hidden
    if (mode == FlareApplicationResponsiveMode.Mobile) return FlareWorkspacePresentation(FlareWorkspacePaneMode.SinglePane, routed)
    val measured = width != null && width.value.isFinite()
    fun fit(detail: Boolean) = resolvePaneMode(
        width ?: 0.dp, detail, textScale, navigationWidth ?: resolveNavigationWidth(mode), primaryWidth, detailWidth,
    )
    if (mode == FlareApplicationResponsiveMode.Tablet) {
        // A tablet's layout has no detail column: two panes at most, and a detail over them. One pane makes the
        // detail a page the host routes to. A width the caller does not know keeps two panes.
        return if (measured && fit(false) == FlareWorkspacePaneMode.SinglePane) {
            FlareWorkspacePresentation(FlareWorkspacePaneMode.SinglePane, routed)
        } else {
            FlareWorkspacePresentation(
                FlareWorkspacePaneMode.DualPane,
                if (hasDetail) FlareWorkspaceDetailPresentation.Overlay else FlareWorkspaceDetailPresentation.Hidden,
            )
        }
    }
    val paneMode = when {
        measured -> fit(hasDetail)
        hasDetail -> FlareWorkspacePaneMode.TriplePane
        else -> FlareWorkspacePaneMode.DualPane
    }
    return when (paneMode) {
        FlareWorkspacePaneMode.TriplePane -> FlareWorkspacePresentation(paneMode, FlareWorkspaceDetailPresentation.Inline)
        // Two panes: a detail opens over the chat rather than crushing the navigation.
        FlareWorkspacePaneMode.DualPane -> FlareWorkspacePresentation(
            paneMode,
            if (hasDetail) FlareWorkspaceDetailPresentation.Overlay else FlareWorkspaceDetailPresentation.Hidden,
        )
        FlareWorkspacePaneMode.SinglePane -> FlareWorkspacePresentation(paneMode, routed)
    }
}

fun resolveApplicationNavigationPresentation(
    mode: FlareApplicationResponsiveMode,
): FlareApplicationNavigationPresentation = when (mode) {
    FlareApplicationResponsiveMode.Mobile -> FlareApplicationNavigationPresentation.Bottom
    FlareApplicationResponsiveMode.Tablet -> FlareApplicationNavigationPresentation.Rail
    FlareApplicationResponsiveMode.Desktop -> FlareApplicationNavigationPresentation.Sidebar
    FlareApplicationResponsiveMode.WideDesktop -> FlareApplicationNavigationPresentation.ExpandedSidebar
}

fun resolveMessageActionExtensions(
    extensions: List<FlareMessageActionExtension>,
    capabilities: FlareCapabilitySet,
    messageId: String,
): List<FlareMessageActionExtension> = extensions
    .withIndex()
    .filter { (_, extension) -> extension.visible }
    .filter { (_, extension) -> extension.capability == null || capabilities.contains(extension.capability) }
    .filter { (_, extension) -> extension.available(messageId) }
    .sortedWith(compareBy<IndexedValue<FlareMessageActionExtension>> { it.value.order ?: it.index }.thenBy { it.index })
    .map { it.value }

@Composable
fun AdaptiveNavigation(
    groups: List<FlareApplicationNavigationGroup>,
    activeId: String,
    responsiveMode: FlareApplicationResponsiveMode,
    onNavigate: (String) -> Unit,
    modifier: Modifier = Modifier,
    presentation: FlareApplicationNavigationPresentation = resolveApplicationNavigationPresentation(responsiveMode),
) {
    val colors = flareColors()
    val items = groups.flatMap { it.items }.filter { it.visible }
    if (presentation == FlareApplicationNavigationPresentation.Bottom) {
        // Vue's bottom bar (`data-presentation="bottom"`): a top hairline, 4 around the items, each a 24 icon over a 12 label
        // 2 apart with 4 above and below — about 62 in all, the system navigation bar's inset under it and not counted in it.
        // The active item is told by colour alone: no Material indicator capsule (iOS has only ever used colour).
        Row(
            modifier.fillMaxWidth()
                .background(colors.bgPrimary)
                .drawBehind { drawLine(colors.borderPrimary, Offset(0f, 0.5.dp.toPx()), Offset(size.width, 0.5.dp.toPx()), 1.dp.toPx()) }
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(FlareSizes.spacingXs)
                .selectableGroup(),
        ) {
            items.forEach { item ->
                val tint = if (item.id == activeId) colors.primaryText else colors.textSecondary
                Column(
                    Modifier.weight(1f).heightIn(min = FlareSizes.touchTarget)
                        .selectable(selected = item.id == activeId, enabled = item.enabled, role = Role.Tab) { onNavigate(item.id) }
                        .flareDimmed(if (item.enabled) 1f else FlareOpacity.disabled)
                        .padding(vertical = FlareSizes.spacingXs, horizontal = 2.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterVertically),
                ) {
                    CompositionLocalProvider(LocalContentColor provides tint) { ApplicationNavigationIcon(item) }
                    Text(item.label, color = tint, fontSize = FlareSizes.fontSizeSm, lineHeight = 18.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
    } else {
        val expanded = presentation == FlareApplicationNavigationPresentation.Sidebar ||
            presentation == FlareApplicationNavigationPresentation.ExpandedSidebar
        NavigationRail(
            modifier = modifier
                .fillMaxHeight()
                // The widths the pane rule assumes for each presentation (resolveNavigationWidth).
                .width(
                    when (presentation) {
                        FlareApplicationNavigationPresentation.ExpandedSidebar -> FlareSizes.primaryPaneDefaultWidth
                        FlareApplicationNavigationPresentation.Sidebar -> FlareSizes.primaryPaneMinWidth
                        else -> FlareSizes.navigationRailWidth
                    },
                )
                .selectableGroup(),
            containerColor = colors.bgSecondary,
        ) {
            items.forEach { item ->
                NavigationRailItem(
                    selected = item.id == activeId,
                    enabled = item.enabled,
                    onClick = { onNavigate(item.id) },
                    icon = { ApplicationNavigationIcon(item) },
                    label = { Text(item.label) },
                    alwaysShowLabel = expanded,
                )
            }
        }
    }
}

@Composable
private fun ApplicationNavigationIcon(item: FlareApplicationNavigationItem) {
    val badge = item.badge
    val icon: @Composable () -> Unit = {
        // The navigation bar tints its selected item itself, so the glyph inherits the item's content
        // colour instead of the registry view's default.
        FlareIcon(name = item.icon, size = FlareSizes.iconSizeLg, tint = LocalContentColor.current, contentDescription = item.accessibilityLabel)
    }
    if (badge == null) {
        icon()
    } else {
        BadgedBox(badge = {
            Badge(modifier = Modifier.semantics {
                contentDescription = badge.label ?: item.accessibilityLabel
            }) {
                when (badge.kind) {
                    FlareApplicationNavigationBadge.Kind.Dot -> Unit
                    FlareApplicationNavigationBadge.Kind.Mention -> Text(badge.label ?: "@")
                    FlareApplicationNavigationBadge.Kind.Count -> Text(flareCountBadgeText(badge.count, badge.more))
                }
            }
        }) { icon() }
    }
}

/**
 * The application frame: navigation beside (or under) the panes the host supplies.
 *
 * Inside a shell it takes the shell's responsive mode ([LocalFlareShellResponsiveMode]); on its own it resolves the
 * mode from its own box. It measures **its own box**, not the window, and decides from that width how many panes fit
 * ([resolveWorkspacePresentation]): below navigation + list + a usable chat ([paneModeMinWidth],
 * 752 dp with the tablet rail and the default list) it shows **one pane at a time** — the host's
 * [activePane] — and keeps the navigation rail; a detail is then a page the host routes to, not an overlay
 * over a screen-wide pane. A phone always shows one pane, and a pane other than the list is a page beyond the
 * destination's root ([FlareDestinationDepth]).
 *
 * [onLayoutChange] hands the host the presentation actually in use (pane mode + detail mode) on the first
 * resolution and whenever it changes, so a host never has to guess it back from a width.
 */
@Composable
fun AppLayout(
    primary: (@Composable () -> Unit)? = null,
    content: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    navigation: (@Composable () -> Unit)? = null,
    detail: (@Composable () -> Unit)? = null,
    activePane: FlareApplicationWorkspacePane = FlareApplicationWorkspacePane.Content,
    overlay: (@Composable () -> Unit)? = null,
    floating: (@Composable () -> Unit)? = null,
    onLayoutChange: ((FlareWorkspacePresentation) -> Unit)? = null,
    /** The list column's width beside the content (Vue `primary-width`); the pane decision counts it too. */
    primaryWidth: Dp = FlareSizes.primaryPaneDefaultWidth,
) {
    val colors = flareColors()
    val shellMode = LocalFlareShellResponsiveMode.current
    Box(modifier.fillMaxSize().background(colors.bgPrimary)) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val textScale = LocalDensity.current.fontScale
            // Inside a shell the mode is the shell's: it measured the box the whole app lives in. On its own the
            // layout resolves the mode from its own box.
            val mode = shellMode ?: resolveApplicationResponsiveMode(maxWidth, textScale)
            val mobile = mode == FlareApplicationResponsiveMode.Mobile
            val presentation = if (mobile) {
                resolveWorkspacePresentation(mode, hasDetail = detail != null)
            } else {
                resolveWorkspacePresentation(
                    mode,
                    hasDetail = detail != null,
                    width = maxWidth,
                    textScale = textScale,
                    navigationWidth = if (navigation == null) 0.dp else null,
                    primaryWidth = primaryWidth,
                )
            }
            ReportWorkspacePresentation(presentation, onLayoutChange)
            val singlePane = presentation.paneMode == FlareWorkspacePaneMode.SinglePane
            // One pane showing something other than the list is a page beyond the destination's root.
            FlareDestinationDepth(singlePane && primary != null && activePane != FlareApplicationWorkspacePane.Primary)
            val activeBody: @Composable () -> Unit = {
                when (activePane) {
                    FlareApplicationWorkspacePane.Primary -> primary?.invoke() ?: content()
                    FlareApplicationWorkspacePane.Detail -> detail?.invoke() ?: content()
                    FlareApplicationWorkspacePane.Content -> content()
                }
            }
            if (mobile) {
                // A phone shows the host's active pane; its navigation is the shell's.
                activeBody()
            } else {
                Row(Modifier.fillMaxSize()) {
                    navigation?.invoke()
                    if (singlePane) {
                        // One pane: the host's active pane fills what is left of the rail.
                        Box(Modifier.weight(1f).fillMaxHeight()) { activeBody() }
                    } else {
                        if (primary != null) {
                            Box(Modifier.width(primaryWidth).fillMaxHeight()) { primary() }
                            VerticalDivider(Modifier.fillMaxHeight())
                        }
                        Box(Modifier.weight(1f).fillMaxHeight()) { content() }
                        if (detail != null && presentation.detail == FlareWorkspaceDetailPresentation.Inline) {
                            VerticalDivider(Modifier.fillMaxHeight())
                            Box(Modifier.width(FlareSizes.detailPaneDefaultWidth).fillMaxHeight()) { detail() }
                        }
                    }
                }
                if (detail != null && presentation.detail == FlareWorkspaceDetailPresentation.Overlay &&
                    activePane == FlareApplicationWorkspacePane.Detail
                ) {
                    Surface(
                        Modifier.align(Alignment.CenterEnd).width(FlareSizes.detailPaneDefaultWidth).fillMaxHeight(),
                        color = colors.bgPrimary,
                        shadowElevation = 8.dp,
                    ) { detail() }
                }
            }
        }
        overlay?.invoke()
        floating?.invoke()
    }
}

/**
 * Reports [presentation] to the host after composition: once on the first resolution, then on every change.
 * Shared by the application frames and [ResponsiveLayout], so both layout families report panes the same way.
 */
@Composable
internal fun ReportWorkspacePresentation(
    presentation: FlareWorkspacePresentation,
    onLayoutChange: ((FlareWorkspacePresentation) -> Unit)?,
) {
    val report by rememberUpdatedState(onLayoutChange)
    LaunchedEffect(presentation) { report?.invoke(presentation) }
}

@Composable
fun MobileAppShell(
    groups: List<FlareApplicationNavigationGroup>,
    activeNavigationId: String,
    onNavigate: (String) -> Unit,
    hideNavigation: Boolean = false,
    content: @Composable () -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        // The bottom bar pads itself above the system navigation; the page above it must not pad for it again.
        Box(Modifier.weight(1f).fillMaxWidth().then(if (hideNavigation) Modifier else Modifier.consumeWindowInsets(WindowInsets.navigationBars))) { content() }
        if (!hideNavigation) {
            AdaptiveNavigation(groups, activeNavigationId, FlareApplicationResponsiveMode.Mobile, onNavigate)
        }
    }
}

/**
 * The desktop shell: navigation beside the host's content. It arranges no panes of its own — the
 * navigation column and one content slot — so there is no presentation for it to report; a host that
 * needs that composes [WorkspaceFrame] or [IMAppKit], which do arrange panes.
 */
@Composable
fun DesktopAppShell(
    groups: List<FlareApplicationNavigationGroup>,
    activeNavigationId: String,
    responsiveMode: FlareApplicationResponsiveMode = FlareApplicationResponsiveMode.Desktop,
    onNavigate: (String) -> Unit,
    content: @Composable () -> Unit,
) {
    Row(Modifier.fillMaxSize()) {
        AdaptiveNavigation(groups, activeNavigationId, responsiveMode, onNavigate)
        // A desktop shell is told its presentation rather than measuring for it; frames inside read it.
        Box(Modifier.weight(1f).fillMaxHeight()) {
            CompositionLocalProvider(LocalFlareShellResponsiveMode provides responsiveMode) { content() }
        }
    }
}

/**
 * One host state per pane, plus the cross-pane banner. Contacts, settings,
 * search and media all come through here, so the fallback text stays generic
 * and the panes resolve through the same [WorkspacePane] the inbox uses.
 */
data class FlareWorkspaceState(
    val primary: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    val content: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    val detail: FlareWorkspacePaneState = FlareWorkspacePaneState(),
    val banner: FlareWorkspaceBanner? = null,
)

private fun FlareWorkspaceState.pane(pane: FlareApplicationWorkspacePane): FlareWorkspacePaneState = when (pane) {
    FlareApplicationWorkspacePane.Primary -> primary
    FlareApplicationWorkspacePane.Content -> content
    FlareApplicationWorkspacePane.Detail -> detail
}

private fun paneSkeleton(pane: FlareApplicationWorkspacePane): SkeletonVariant = when (pane) {
    FlareApplicationWorkspacePane.Primary -> SkeletonVariant.Conversation
    FlareApplicationWorkspacePane.Content -> SkeletonVariant.Message
    FlareApplicationWorkspacePane.Detail -> SkeletonVariant.Profile
}

private fun paneSkeletonRows(pane: FlareApplicationWorkspacePane): Int = when (pane) {
    FlareApplicationWorkspacePane.Primary -> 6
    FlareApplicationWorkspacePane.Content -> 5
    FlareApplicationWorkspacePane.Detail -> 1
}

/** The registry icon name each workspace pane shows when it is empty. */
private fun paneIcon(pane: FlareApplicationWorkspacePane): String = when (pane) {
    FlareApplicationWorkspacePane.Primary -> "folder"
    FlareApplicationWorkspacePane.Content -> "chats"
    FlareApplicationWorkspacePane.Detail -> "info"
}

@Composable
fun WorkspaceFrame(
    primary: @Composable () -> Unit,
    content: @Composable () -> Unit,
    detail: (@Composable () -> Unit)? = null,
    activePane: FlareApplicationWorkspacePane = FlareApplicationWorkspacePane.Content,
    state: FlareWorkspaceState = FlareWorkspaceState(),
    onRetry: ((FlareApplicationWorkspacePane) -> Unit)? = null,
    onEmptyAction: ((FlareApplicationWorkspacePane) -> Unit)? = null,
    onBannerAction: (() -> Unit)? = null,
    /** The presentation the frame settled on (pane mode + detail mode); see [AppLayout]. */
    onLayoutChange: ((FlareWorkspacePresentation) -> Unit)? = null,
) {
    val strings = flareStrings()
    val banner = state.banner
    val bannerAction = workspaceBannerActionVisible(banner, onBannerAction != null)

    @Composable
    fun pane(key: FlareApplicationWorkspacePane, body: @Composable () -> Unit) = WorkspacePane(
        state = state.pane(key),
        skeleton = paneSkeleton(key),
        skeletonRows = paneSkeletonRows(key),
        emptyIcon = paneIcon(key),
        emptyText = strings.workspaceFrameEmpty,
        failureText = strings.workspaceFrameFailure,
        loadingText = strings.workspaceFrameLoading,
        onRetry = onRetry?.let { handler -> { handler(key) } },
        onEmptyAction = onEmptyAction?.let { handler -> { handler(key) } },
        content = body,
    )

    Column(Modifier.fillMaxSize()) {
        if (banner != null && workspaceBannerVisible(banner)) {
            Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingSm)) {
                StatusBanner(
                    text = banner.message,
                    tone = workspaceBannerTone(banner.tone),
                    actionText = if (bannerAction) banner.actionLabel else null,
                    onAction = if (bannerAction) onBannerAction else null,
                )
            }
        }
        Box(Modifier.weight(1f).fillMaxWidth()) {
            AppLayout(
                primary = { pane(FlareApplicationWorkspacePane.Primary, primary) },
                content = { pane(FlareApplicationWorkspacePane.Content, content) },
                detail = detail?.let { body -> { pane(FlareApplicationWorkspacePane.Detail, body) } },
                activePane = activePane,
                onLayoutChange = onLayoutChange,
            )
        }
    }
}


/**
 * The application shell (FR-095). It measures its own box — not the window — for the responsive mode and hands that
 * mode down ([LocalFlareShellResponsiveMode]), draws the navigation the mode calls for, and shows one destination per
 * navigation item from [destination]. A destination arranges its own panes ([AppLayout], [WorkspaceFrame],
 * [ConversationWorkspace]).
 *
 * A destination's saveable state is kept while another is active, the way navigation back stacks keep it: coming back
 * finds what the destination kept with `rememberSaveable` — the list's scroll position, the chat that was open. The
 * phone navigation steps aside while the active destination shows a page beyond its root ([FlareDestinationDepth]).
 */
@Composable
fun IMAppKit(
    configuration: FlareIMAppConfiguration,
    groups: List<FlareApplicationNavigationGroup>,
    activeNavigationId: String,
    onNavigate: (String) -> Unit,
    destination: @Composable (id: String) -> Unit,
) {
    @Suppress("UNUSED_VARIABLE") val resolvedConfiguration = configuration
    val holder = rememberSaveableStateHolder()
    val known = groups.flatMap { it.items }.map { it.id }.toSet()
    var visited by remember { mutableStateOf(listOf(activeNavigationId)) }
    val depths = remember { mutableStateMapOf<String, FlareDestinationDepthRegistry>() }
    val shown = flareShellDestinations(visited, activeNavigationId, known)
    LaunchedEffect(shown) {
        (visited - shown.toSet()).forEach { id ->
            holder.removeState(id)
            depths.remove(id)
        }
        visited = shown
    }
    val registry = depths.getOrPut(activeNavigationId) { FlareDestinationDepthRegistry() }
    val searchTaps = remember { SearchTapScope() }
    val focus = LocalFocusManager.current
    BoxWithConstraints(Modifier.fillMaxSize().background(flareColors().bgPrimary)
        .dismissSearchOnOutsideTap(searchTaps) { focus.clearFocus() }) {
        val mode = resolveApplicationResponsiveMode(maxWidth, LocalDensity.current.fontScale)
        val mobile = mode == FlareApplicationResponsiveMode.Mobile
        // One structure for every mode, so the destination keeps its place when the window crosses a breakpoint: the
        // navigation column is an optional sibling before it, the bottom bar one after.
        Row(Modifier.fillMaxSize()) {
            if (!mobile) AdaptiveNavigation(groups, activeNavigationId, mode, onNavigate)
            Column(Modifier.weight(1f).fillMaxHeight()) {
                val keyboardVisible = WindowInsets.ime.getBottom(LocalDensity.current) > 0
                val atRoot = flareShellNavigationVisible(mode, registry.depth)
                val bottomBar = mobile && atRoot && !keyboardVisible
                // The bottom bar pads itself above the system navigation; the page above it must not pad for it again.
                Box(Modifier.weight(1f).fillMaxWidth().then(
                    when {
                        bottomBar -> Modifier.consumeWindowInsets(WindowInsets.navigationBars)
                        mobile && atRoot && keyboardVisible -> Modifier.imePadding()
                        else -> Modifier
                    },
                )) {
                    CompositionLocalProvider(
                        LocalFlareShellResponsiveMode provides mode,
                        LocalFlareDestinationDepth provides registry,
                        LocalSearchTapScope provides searchTaps,
                    ) {
                        holder.SaveableStateProvider(activeNavigationId) { destination(activeNavigationId) }
                    }
                }
                if (bottomBar) {
                    AdaptiveNavigation(groups, activeNavigationId, FlareApplicationResponsiveMode.Mobile, onNavigate)
                }
            }
        }
    }
}

/**
 * [status] sits between the filters and the rows (a permission soft-ask, a notice). With [onRefresh] the rows take a
 * pull from the top (touch is how this kit is used, so there is no refresh key); [refreshing] keeps the indicator up
 * and stops a second pull. A list with no rows that failed shows the failure as the screen's own error state.
 */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun ConversationListContainer(
    state: FlareApplicationViewState<List<Any>> = FlareApplicationViewState(),
    onRetry: (() -> Unit)? = null,
    onLoadMore: (() -> Unit)? = null,
    retryLabel: String = "",
    loadMoreLabel: String = "",
    /** The container's own words for an empty list; `state.emptyTitle` overrides it per state. */
    emptyTitle: String = "",
    header: (@Composable () -> Unit)? = null,
    search: (@Composable () -> Unit)? = null,
    filters: (@Composable () -> Unit)? = null,
    pinned: (@Composable () -> Unit)? = null,
    archived: (@Composable () -> Unit)? = null,
    status: (@Composable () -> Unit)? = null,
    refreshing: Boolean = false,
    onRefresh: (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    Column(Modifier.fillMaxSize().background(flareColors().bgPrimary)) {
        header?.invoke(); search?.invoke(); filters?.invoke(); status?.invoke()
        if (state.status == FlareApplicationViewStatus.Ready) pinned?.invoke()
        val presentation = flareViewPresentation(state.status, state.stale)
        val rows: @Composable () -> Unit = {
            if (onRefresh != null && presentation != FlareViewPresentation.State) {
                val pull = androidx.compose.material3.pulltorefresh.rememberPullToRefreshState()
                val strings = flareStrings()
                // The Vue kit's band: it grows with the finger (64 at the threshold) and says what letting go will do.
                val band = if (refreshing) 64.dp / 1.5f else 64.dp * pull.distanceFraction.coerceIn(0f, 1.5f)
                androidx.compose.material3.pulltorefresh.PullToRefreshBox(
                    isRefreshing = refreshing,
                    onRefresh = { if (!refreshing) onRefresh() },
                    modifier = Modifier.fillMaxSize(),
                    state = pull,
                    indicator = {
                        if (band > 0.dp) Text(
                            when {
                                refreshing -> strings.listRefreshRefreshing
                                pull.distanceFraction >= 1f -> strings.listRefreshRelease
                                else -> strings.listRefreshPull
                            },
                            modifier = Modifier.align(Alignment.TopCenter).height(band).padding(top = FlareSizes.spacingSm)
                                .semantics { liveRegion = androidx.compose.ui.semantics.LiveRegionMode.Polite },
                            color = flareColors().textTertiary,
                            fontSize = FlareSizes.fontSizeSm,
                        )
                    },
                ) { Box(Modifier.fillMaxSize().padding(top = band)) { content() } }
            } else content()
        }
        Box(Modifier.weight(1f).fillMaxWidth()) {
            when (presentation) {
                FlareViewPresentation.Content -> rows()
                // A failed refresh over rows worth keeping: the failure is a banner, the rows stay readable.
                FlareViewPresentation.ContentWithNotice -> Column(Modifier.fillMaxSize()) {
                    StatusBanner(
                        text = state.error.orEmpty(),
                        tone = if (state.status == FlareApplicationViewStatus.Error) FlareStatusTone.Danger else FlareStatusTone.Info,
                        actionText = retryLabel.takeIf { onRetry != null && it.isNotBlank() },
                        onAction = onRetry,
                    )
                    Box(Modifier.weight(1f).fillMaxWidth()) { rows() }
                }
                FlareViewPresentation.State -> when (state.status) {
                    FlareApplicationViewStatus.Empty -> EmptyState(state.emptyTitle ?: emptyTitle, icon = "chats")
                    // Nothing else is on this screen, so the failure is its content, not a thin band over a blank list.
                    FlareApplicationViewStatus.Error -> EmptyState(
                        title = state.error.orEmpty(),
                        actionText = retryLabel.takeIf { onRetry != null && it.isNotBlank() },
                        icon = "warning",
                        onAction = onRetry,
                        tone = FlareEmptyStateTone.Error,
                    )
                    FlareApplicationViewStatus.Offline -> StatusBanner(
                        text = state.error.orEmpty(),
                        tone = if (state.status == FlareApplicationViewStatus.Error) FlareStatusTone.Danger else FlareStatusTone.Info,
                        actionText = retryLabel.takeIf { onRetry != null && it.isNotBlank() },
                        onAction = onRetry,
                    )
                    else -> Skeleton(SkeletonVariant.Conversation)
                }
            }
        }
        if (state.status == FlareApplicationViewStatus.Ready) archived?.invoke()
        if (state.hasMore && onLoadMore != null && loadMoreLabel.isNotBlank()) {
            Box(Modifier.fillMaxWidth().padding(FlareSizes.spacingSm)) {
                Button(label = loadMoreLabel, size = FlareControlSize.Lg, block = true, onClick = onLoadMore)
            }
        }
    }
}

@Composable
fun FriendListContainer(
    state: FlareApplicationViewState<List<Any>> = FlareApplicationViewState(),
    onRetry: (() -> Unit)? = null,
    retryLabel: String = "",
    emptyTitle: String = "",
    header: (@Composable () -> Unit)? = null,
    search: (@Composable () -> Unit)? = null,
    /** Under the search field, above the list (the phone directory's 群聊 / 新的好友 / 黑名单 entries). */
    filters: (@Composable () -> Unit)? = null,
    content: @Composable () -> Unit,
) = ConversationListContainer(
    state = state,
    onRetry = onRetry,
    retryLabel = retryLabel,
    emptyTitle = emptyTitle,
    header = header,
    search = search,
    filters = filters,
    content = content,
)
