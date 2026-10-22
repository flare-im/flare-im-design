package com.flare.im.ui

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class PluginComponentsInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun packetBusyDisabledAndMissingHandlerAreInertButFinishedOpens() {
        val mode = mutableStateOf(0)
        var calls = 0
        compose.setContent {
            FlareThemeProvider {
                CompositionLocalProvider(LocalFlareStrings provides flareStringsEnglish()) {
                    RedPacketCard(blessing = "Hello", disabled = mode.value == 1, busy = mode.value == 2,
                        state = if (mode.value == 3) FlareRedPacketCardState.Finished else FlareRedPacketCardState.Unopened,
                        onOpen = if (mode.value == 4) null else ({ calls++ }))
                }
            }
        }
        compose.onNodeWithText("Hello").assertIsEnabled().performClick()
        assertEquals(1, calls)
        // A finished packet still opens: the viewer goes on to its details.
        compose.runOnIdle { mode.value = 3 }
        compose.onNodeWithText("Hello").assertIsEnabled().performClick()
        assertEquals(2, calls)
        for (next in listOf(1, 2, 4)) {
            compose.runOnIdle { mode.value = next }
            compose.onNodeWithText("Hello").assertIsNotEnabled()
            if (next == 1) compose.onNodeWithText("Unavailable", substring = true).assertExists()
            if (next == 2) compose.onNodeWithText("Processing", substring = true).assertExists()
        }
        assertEquals(2, calls)
    }

    @Test fun unavailableGenericPluginDoesNotExposeFieldsOrActions() {
        compose.setContent {
            FlareThemeProvider {
                PluginView(PluginViewModel(false, "History", listOf(PluginViewField("Private", "secret")),
                    listOf(PluginViewAction("claim", "Claim"))))
            }
        }
        compose.onNodeWithText("History").assertExists()
        compose.onNodeWithText("secret").assertDoesNotExist()
        compose.onNodeWithText("Claim").assertDoesNotExist()
    }
}
