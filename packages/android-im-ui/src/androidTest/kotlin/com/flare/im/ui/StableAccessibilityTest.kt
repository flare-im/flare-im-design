package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import org.junit.Rule
import org.junit.Test

class StableAccessibilityTest {
    @get:Rule val compose = createComposeRule()

    @Test fun deliveryFailureHasNamedRetryAction() {
        compose.setContent {
            CompositionLocalProvider(LocalFlareStrings provides FlareStrings {
                messageFailed = "Failed"
                retry = "Retry"
            }) {
                FlareThemeProvider {
                    MessageStatus(FlareMessageDeliveryStatus.Failed, onResend = {})
                }
            }
        }
        compose.onNodeWithContentDescription("Failed, Retry").assertExists().assertHasClickAction()
    }

    @Test fun criticalControlsRemainReachableAtTwoHundredPercent() {
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, 2f)) {
                FlareThemeProvider {
                    Column(
                        Modifier.fillMaxWidth().verticalScroll(rememberScrollState()),
                    ) {
                        Button(label = "Retry sending the message safely", block = true, onClick = {})
                        Input(value = "", onValueChange = {}, placeholder = "Long localized input label")
                        ConversationRow(
                            item = ConversationRowData(
                                id = "a11y",
                                title = "Long translated conversation title",
                                preview = "Latest message remains available",
                                timestampLabel = "23:59",
                                unreadCount = 120,
                            ),
                        )
                        MessageMeta(
                            timestamp = "23:59",
                            edited = true,
                            status = FlareMessageDeliveryStatus.Failed,
                        )
                        Composer(placeholder = "Write a message", onSend = {})
                    }
                }
            }
        }
        compose.onNodeWithText("Retry sending the message safely").assertIsDisplayed().assertHasClickAction()
        compose.onNodeWithText("Write a message").assertIsDisplayed()
    }
}
