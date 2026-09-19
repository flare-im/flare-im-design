package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test

/**
 * The shell contract (FR-095) on the device: the shell resolves its mode from its own box, keeps a destination's
 * saveable state while another is active, and steps its phone navigation aside while the active destination shows a
 * page with a way back. The box is sized with `requiredWidth`: a plain `width` is clamped to the screen, and on a phone
 * emulator every box would be a phone.
 */
class ShellContractTest {
    @get:Rule val compose = createComposeRule()

    private val groups = listOf(
        FlareApplicationNavigationGroup(
            "main",
            listOf(
                FlareApplicationNavigationItem("chats", "Chats", "chats", order = 0),
                FlareApplicationNavigationItem("contacts", "Contacts", "people", order = 1),
            ),
        ),
    )

    private var active by mutableStateOf("chats")
    private var page by mutableStateOf(false)

    private fun shell(width: Dp) {
        compose.setContent {
            MaterialTheme {
                Box(Modifier.requiredWidth(width).fillMaxHeight()) {
                    IMAppKit(FlareIMAppConfiguration(), groups, active, onNavigate = { active = it }) { id ->
                        if (id == "chats") {
                            var count by rememberSaveable { mutableIntStateOf(0) }
                            Button(onClick = { count += 1 }) { Text("chats $count") }
                        } else {
                            FlareScreen(title = "Contacts", onBack = if (page) ({ page = false }) else null) { Text("contact list") }
                        }
                    }
                }
            }
        }
    }

    @Test fun aDestinationKeepsItsSaveableStateWhileAnotherIsActive() {
        shell(390.dp)
        compose.onNodeWithText("chats 0").performClick()
        compose.onNodeWithText("chats 1").assertExists()
        compose.runOnIdle { active = "contacts" }
        compose.onNodeWithText("contact list").assertExists()
        compose.runOnIdle { active = "chats" }
        compose.onNodeWithText("chats 1").assertExists()
    }

    @Test fun thePhoneNavigationStepsAsideForAPageWithAWayBack() {
        shell(390.dp)
        compose.runOnIdle { active = "contacts" }
        compose.onNodeWithText("Chats").assertExists()
        compose.runOnIdle { page = true }
        compose.onNodeWithText("Chats").assertDoesNotExist()
        compose.runOnIdle { page = false }
        compose.onNodeWithText("Chats").assertExists()
    }

    @Test fun aWiderBoxKeepsItsRailBesideAPage() {
        shell(1200.dp)
        compose.runOnIdle {
            active = "contacts"
            page = true
        }
        compose.onNodeWithText("Chats").assertExists()
    }
}
