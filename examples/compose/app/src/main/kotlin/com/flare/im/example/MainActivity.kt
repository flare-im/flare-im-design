package com.flare.im.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.flare.im.ui.CommandPalette
import com.flare.im.ui.ConversationRow
import com.flare.im.ui.ConversationRowData
import com.flare.im.ui.FlareBrandTheme
import com.flare.im.ui.FlareCommandPaletteCommand
import com.flare.im.ui.FlareCommandPaletteGroup
import com.flare.im.ui.FlareConversationKind
import com.flare.im.ui.FlareMessageData
import com.flare.im.ui.FlareMessageDeliveryStatus
import com.flare.im.ui.FlareTextContent
import com.flare.im.ui.FlareThemeMode
import com.flare.im.ui.FlareThemeProvider
import com.flare.im.ui.MessageBubble
import com.flare.im.ui.Button
import com.flare.im.ui.FlareControlSize

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { ExampleApp() }
    }
}

@Composable
private fun ExampleApp() {
    var brand by remember { mutableStateOf(FlareBrandTheme.Violet) }
    var dark by remember { mutableStateOf(false) }
    var commandPaletteOpen by remember { mutableStateOf(false) }
    var commandQuery by remember { mutableStateOf("") }
    var selectedCommand by remember { mutableStateOf("new-message") }
    val commandGroups = remember {
        listOf(
            FlareCommandPaletteGroup(
                id = "workspace",
                label = "Workspace",
                commands = listOf(
                    FlareCommandPaletteCommand("new-message", "New conversation", "Choose a contact or group", shortcut = "Ctrl+N"),
                    FlareCommandPaletteCommand("search", "Search messages", "Find content in this workspace", shortcut = "Ctrl+F"),
                    FlareCommandPaletteCommand("settings", "Open settings", shortcut = "Ctrl+,"),
                ),
            ),
        )
    }

    MaterialTheme {
        FlareThemeProvider(brand = brand, mode = if (dark) FlareThemeMode.Dark else FlareThemeMode.Light) {
            Surface(Modifier.fillMaxSize()) {
                Column(
                    Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text("Flare IM Compose", style = MaterialTheme.typography.titleLarge)
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(FlareBrandTheme.entries) { item ->
                            FilterChip(
                                selected = item == brand,
                                onClick = { brand = item },
                                label = { Text(item.name) },
                            )
                        }
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Dark mode", modifier = Modifier.weight(1f))
                        Switch(checked = dark, onCheckedChange = { dark = it })
                    }
                    ConversationRow(
                        item = ConversationRowData(
                            id = "design",
                            title = "Design review",
                            preview = "The component contract is ready.",
                            timestampLabel = "14:32",
                            unreadCount = 3,
                        ),
                        active = true,
                    )
                    MessageBubble(
                        message = FlareMessageData(
                            id = "incoming",
                            senderId = "ivy",
                            senderName = "Ivy",
                            content = FlareTextContent("Incoming messages stay neutral."),
                            timeLabel = "14:33",
                            status = FlareMessageDeliveryStatus.Delivered,
                        ),
                        currentUserId = "me",
                        conversationKind = FlareConversationKind.Group,
                    )
                    MessageBubble(
                        message = FlareMessageData(
                            id = "outgoing",
                            senderId = "me",
                            senderName = "Me",
                            content = FlareTextContent("Outgoing semantics follow the selected brand."),
                            timeLabel = "14:34",
                            status = FlareMessageDeliveryStatus.Read,
                        ),
                        currentUserId = "me",
                        conversationKind = FlareConversationKind.Group,
                    )
                    Button(label = "Open commands", size = FlareControlSize.Lg, block = true, onClick = { commandPaletteOpen = true })
                    CommandPalette(
                        open = commandPaletteOpen,
                        query = commandQuery,
                        groups = commandGroups,
                        label = "Workspace commands",
                        placeholder = "Search commands",
                        emptyText = "No matching commands",
                        selectedId = selectedCommand,
                        onQueryChange = { commandQuery = it },
                        onSelectedIdChange = { selectedCommand = it },
                        onInvoke = { commandPaletteOpen = false },
                        onClose = { commandPaletteOpen = false },
                    )
                }
            }
        }
    }
}
