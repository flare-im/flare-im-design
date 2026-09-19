package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/** Which pane is shown when collapsed to a single column (phone). */
enum class FlarePane { List, Chat, Detail }

/**
 * Adaptive conversation layout — one column (list ↔ chat), the list beside the chat, or list + chat + detail.
 * How many columns fit is the kit's one pane rule ([resolvePaneMode]) on the width [BoxWithConstraints] gives it.
 * Spec: Layout/ResponsiveLayout (`ResponsiveLayout`).
 *
 * [onLayoutChange] reports the panes in use, in the words the application frames use, after the first
 * composition and on every change: `SinglePane` means the chat or detail replaced the list and the host owns
 * the way back.
 */
@Composable
fun ResponsiveLayout(
    list: @Composable () -> Unit,
    chat: @Composable () -> Unit,
    detail: (@Composable () -> Unit)? = null,
    activePane: FlarePane = FlarePane.List,
    listWidth: androidx.compose.ui.unit.Dp = FlareSizes.primaryPaneDefaultWidth,
    detailWidth: androidx.compose.ui.unit.Dp = FlareSizes.detailPaneDefaultWidth,
    onPaneChange: ((FlarePane) -> Unit)? = null,
    hideMobileBar: Boolean = false,
    backLabel: String = flareStrings().back,
    onLayoutChange: ((FlareWorkspacePresentation) -> Unit)? = null,
) {
    require(listWidth.value >= 0 && detailWidth.value >= 0) { "Pane widths must be non-negative" }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val paneMode = resolvePaneMode(
            maxWidth, detail != null, LocalDensity.current.fontScale, primaryWidth = listWidth, detailWidth = detailWidth,
        )
        // A detail that is not beside the chat takes a pane's place when the host opens it.
        ReportWorkspacePresentation(
            FlareWorkspacePresentation(
                paneMode,
                when {
                    paneMode == FlareWorkspacePaneMode.TriplePane -> FlareWorkspaceDetailPresentation.Inline
                    detail != null -> FlareWorkspaceDetailPresentation.Route
                    else -> FlareWorkspaceDetailPresentation.Hidden
                },
            ),
            onLayoutChange,
        )
        // The chat or the detail in the list's place is a page beyond the destination's root.
        FlareDestinationDepth(paneMode == FlareWorkspacePaneMode.SinglePane && activePane != FlarePane.List)
        when {
            paneMode == FlareWorkspacePaneMode.TriplePane && detail != null -> Row(Modifier.fillMaxSize()) {
                Box(Modifier.width(listWidth).fillMaxHeight()) { list() }
                VerticalDivider()
                Box(Modifier.weight(1f).fillMaxHeight()) { chat() }
                VerticalDivider()
                Box(Modifier.width(detailWidth).fillMaxHeight()) { detail() }
            }
            paneMode == FlareWorkspacePaneMode.DualPane -> Row(Modifier.fillMaxSize()) {
                Box(Modifier.width(listWidth).fillMaxHeight()) { list() }
                VerticalDivider()
                Box(Modifier.weight(1f).fillMaxHeight()) {
                    if (activePane == FlarePane.Detail && detail != null) detail() else chat()
                }
            }
            else -> Column(Modifier.fillMaxSize()) {
                if (!hideMobileBar && activePane != FlarePane.List && onPaneChange != null) {
                    TextButton(onClick = { onPaneChange(if (activePane == FlarePane.Detail) FlarePane.Chat else FlarePane.List) },
                        modifier = Modifier.defaultMinSize(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)) { Text(backLabel) }
                }
                Box(Modifier.weight(1f)) { when (activePane) {
                    FlarePane.List -> list()
                    FlarePane.Chat -> chat()
                    FlarePane.Detail -> detail?.invoke() ?: chat()
                } }
            }
        }
    }
}
