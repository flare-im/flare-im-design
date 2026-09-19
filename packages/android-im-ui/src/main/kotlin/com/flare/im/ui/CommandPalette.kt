package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

data class FlareCommandPaletteCommand(
    val id: String,
    val label: String,
    val description: String? = null,
    val keywords: List<String> = emptyList(),
    val shortcut: String? = null,
    val disabled: Boolean = false,
)

data class FlareCommandPaletteGroup(
    val id: String,
    val label: String,
    val commands: List<FlareCommandPaletteCommand>,
)

/** Searchable command surface. The host owns command execution and open state. */
@Composable
fun CommandPalette(
    open: Boolean,
    query: String,
    groups: List<FlareCommandPaletteGroup>,
    label: String,
    placeholder: String,
    emptyText: String,
    onQueryChange: (String) -> Unit,
    onInvoke: (FlareCommandPaletteCommand) -> Unit,
    onClose: () -> Unit,
    busy: Boolean = false,
    selectedId: String? = null,
    onSelectedIdChange: ((String) -> Unit)? = null,
) {
    if (!open) return
    val normalized = query.trim().lowercase()
    val visibleGroups = groups.map { group ->
        group.copy(commands = group.commands.filter { command ->
            normalized.isEmpty() || listOfNotNull(command.label, command.description)
                .plus(command.keywords).any { it.lowercase().contains(normalized) }
        })
    }.filter { it.commands.isNotEmpty() }
    val enabled = visibleGroups.flatMap { it.commands }.filterNot { it.disabled }
    var internalSelectedId by remember { mutableStateOf<String?>(null) }
    val activeId = (selectedId ?: internalSelectedId).takeIf { id -> enabled.any { it.id == id } }
        ?: enabled.firstOrNull()?.id
    val requester = remember { FocusRequester() }

    fun select(id: String) {
        internalSelectedId = id
        onSelectedIdChange?.invoke(id)
    }

    fun move(delta: Int) {
        if (enabled.isEmpty()) return
        val current = enabled.indexOfFirst { it.id == activeId }.coerceAtLeast(0)
        select(enabled[Math.floorMod(current + delta, enabled.size)].id)
    }

    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        val colors = flareColors()
        Surface(
            modifier = Modifier.width(640.dp).heightIn(max = 560.dp)
                .semantics {
                    paneTitle = label
                    contentDescription = label
                }
                .onPreviewKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                    when (event.key) {
                        Key.Escape -> { onClose(); true }
                        Key.DirectionDown -> { move(1); true }
                        Key.DirectionUp -> { move(-1); true }
                        Key.MoveHome -> { enabled.firstOrNull()?.let { select(it.id) }; true }
                        Key.MoveEnd -> { enabled.lastOrNull()?.let { select(it.id) }; true }
                        Key.Enter -> { enabled.firstOrNull { it.id == activeId }?.let { if (!busy) onInvoke(it) }; true }
                        else -> false
                    }
            },
            color = colors.bgElevated,
            shape = RoundedCornerShape(FlareSizes.radiusLg),
            tonalElevation = FlareSizes.spacingSm,
        ) {
            Column {
                TextField(
                    value = query,
                    onValueChange = onQueryChange,
                    enabled = !busy,
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Outlined.Search, contentDescription = null) },
                    placeholder = { Text(placeholder) },
                    modifier = Modifier.fillMaxWidth().focusRequester(requester),
                )
                HorizontalDivider(color = colors.borderPrimary)
                if (busy) CircularProgressIndicator(Modifier.padding(FlareSizes.spacingMd))
                if (visibleGroups.isEmpty()) {
                    Text(emptyText, color = colors.textSecondary, modifier = Modifier.padding(FlareSizes.spacingXl))
                } else LazyColumn {
                    visibleGroups.forEach { group ->
                        item(group.id) {
                            Text(group.label, color = colors.textTertiary,
                                style = MaterialTheme.typography.labelSmall,
                                modifier = Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm).semantics { heading() })
                        }
                        items(group.commands, key = { it.id }) { command ->
                            ListItem(
                                headlineContent = { Text(command.label) },
                                supportingContent = command.description?.let { description -> { Text(description) } },
                                trailingContent = command.shortcut?.let { shortcut -> { Text(shortcut, color = colors.textTertiary) } },
                                colors = ListItemDefaults.colors(containerColor = if (command.id == activeId) colors.bgSelected else colors.bgElevated),
                                modifier = Modifier.fillMaxWidth().semantics { selected = command.id == activeId; role = Role.Button }
                                    .then(if (!busy && !command.disabled) Modifier.clickable { onInvoke(command) } else Modifier),
                            )
                        }
                    }
                }
            }
        }
        LaunchedEffect(open) { requester.requestFocus() }
    }
}
