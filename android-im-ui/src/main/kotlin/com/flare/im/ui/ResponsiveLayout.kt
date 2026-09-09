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
 * Adaptive conversation layout — phone single column (list ↔ chat), tablet two
 * columns (list + chat), desktop three columns (list + chat + detail). Spec:
 * Layout/ResponsiveLayout (`ResponsiveLayout`). Breakpoints via [BoxWithConstraints].
 */
@Composable
fun ResponsiveLayout(
    list: @Composable () -> Unit,
    chat: @Composable () -> Unit,
    detail: (@Composable () -> Unit)? = null,
    activePane: FlarePane = FlarePane.List,
    listWidth: androidx.compose.ui.unit.Dp = FlareSizes.leftPanel,
    detailWidth: androidx.compose.ui.unit.Dp = FlareSizes.rightPanel,
    onPaneChange: ((FlarePane) -> Unit)? = null,
    hideMobileBar: Boolean = false,
    backLabel: String = flareStrings().back,
) {
    require(listWidth.value >= 0 && detailWidth.value >= 0) { "Pane widths must be non-negative" }
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val panes = FlareLayoutPolicy.paneCount(maxWidth.value, detail != null, LocalDensity.current.fontScale, listWidth.value, detailWidth.value)
        when {
            panes == 3 && detail != null -> Row(Modifier.fillMaxSize()) {
                Box(Modifier.width(listWidth).fillMaxHeight()) { list() }
                VerticalDivider()
                Box(Modifier.weight(1f).fillMaxHeight()) { chat() }
                VerticalDivider()
                Box(Modifier.width(detailWidth).fillMaxHeight()) { detail() }
            }
            panes == 2 -> Row(Modifier.fillMaxSize()) {
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
