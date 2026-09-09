package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Adaptive application shell — bottom navigation on phones, a side rail on
 * tablet/desktop, wrapping the content area. Spec: Layout/AppShell (`AppShell`).
 * Responsive via [BoxWithConstraints] (rail at ≥ 600dp width).
 */
@Composable
fun AppShell(
    items: List<NavItem>,
    activeKey: String,
    onNavigate: ((String) -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val wide = maxWidth >= 600.dp
        if (wide) {
            Row(Modifier.fillMaxSize()) {
                // Rail sits on bgSecondary with a hairline against the content (parity with iOS/Flutter).
                NavigationRail(Modifier.fillMaxHeight(), containerColor = colors.bgSecondary) {
                    items.forEach { item ->
                        NavigationRailItem(
                            selected = item.key == activeKey,
                            onClick = { onNavigate?.invoke(item.key) },
                            icon = { navIcon(item) },
                            label = { Text(item.label) },
                        )
                    }
                }
                Box(Modifier.fillMaxHeight().width(1.dp).background(colors.borderPrimary))
                Box(Modifier.weight(1f).fillMaxSize()) { content() }
            }
        } else {
            Column(Modifier.fillMaxSize()) {
                Box(Modifier.weight(1f)) { content() }
                Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
                NavigationBar(containerColor = colors.bgPrimary) {
                    items.forEach { item ->
                        NavigationBarItem(
                            selected = item.key == activeKey,
                            onClick = { onNavigate?.invoke(item.key) },
                            icon = { navIcon(item) },
                            label = { Text(item.label) },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun navIcon(item: NavItem) {
    if (item.badge > 0) {
        BadgedBox(badge = { Badge { Text(if (item.badge > 99) "99+" else "${item.badge}") } }) {
            Icon(item.icon, item.label)
        }
    } else {
        Icon(item.icon, item.label)
    }
}
