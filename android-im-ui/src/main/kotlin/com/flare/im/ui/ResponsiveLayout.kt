package com.flare.im.ui

import androidx.compose.foundation.layout.Box
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
    listWidth: androidx.compose.ui.unit.Dp = 300.dp,
    detailWidth: androidx.compose.ui.unit.Dp = 320.dp,
) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val w = maxWidth
        when {
            w >= 1100.dp && detail != null -> Row(Modifier.fillMaxSize()) {
                Box(Modifier.width(listWidth).fillMaxHeight()) { list() }
                VerticalDivider()
                Box(Modifier.weight(1f).fillMaxHeight()) { chat() }
                VerticalDivider()
                Box(Modifier.width(detailWidth).fillMaxHeight()) { detail() }
            }
            w >= 680.dp -> Row(Modifier.fillMaxSize()) {
                Box(Modifier.width(listWidth).fillMaxHeight()) { list() }
                VerticalDivider()
                Box(Modifier.weight(1f).fillMaxHeight()) { chat() }
            }
            else -> Box(Modifier.fillMaxSize()) {
                when (activePane) {
                    FlarePane.List -> list()
                    FlarePane.Chat -> chat()
                    FlarePane.Detail -> detail?.invoke() ?: chat()
                }
            }
        }
    }
}
