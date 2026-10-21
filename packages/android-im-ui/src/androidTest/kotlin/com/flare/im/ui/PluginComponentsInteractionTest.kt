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

    @Test fun packetBusyDisabledFinishedAndMissingHandlerAreInert() {
        val mode = mutableStateOf(0)
        var calls = 0
        compose.setContent {
            FlareThemeProvider {
                CompositionLocalProvider(LocalFlareStrings provides flareStringsEnglish()) {
                    RedPacketCard(blessing = "Hello", disabled = mode.value == 1, busy = mode.value == 2,
                        finished = mode.value == 3, onOpen = if (mode.value == 4) null else ({ calls++ }))
                }
            }
        }
        compose.onNodeWithText("Hello").assertIsEnabled().performClick()
        assertEquals(1, calls)
        for (next in 1..4) {
            compose.runOnIdle { mode.value = next }
            compose.onNodeWithText("Hello").assertIsNotEnabled()
            if (next == 1) compose.onNodeWithText("Unavailable", substring = true).assertExists()
            if (next == 2) compose.onNodeWithText("Processing", substring = true).assertExists()
        }
        assertEquals(1, calls)
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
