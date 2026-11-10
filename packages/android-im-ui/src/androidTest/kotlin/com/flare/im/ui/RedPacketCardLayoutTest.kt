package com.flare.im.ui

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertWidthIsEqualTo
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/** Same envelope dimensions on phone and desktop, with long status and independent quoted-reply actions. */
class RedPacketCardLayoutTest {
    @get:Rule val compose = createComposeRule()

    @Test fun widthIsCappedForWideParentsAndRespectsNarrowParents() {
        val width = mutableStateOf(720.dp)
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density / 2f, 1f)) {
                FlareThemeProvider {
                    Box(Modifier.width(width.value)) { RedPacketCard(blessing = "Hello", onOpen = {}) }
                }
            }
        }
        compose.onNodeWithText("Hello").assertWidthIsEqualTo(FlareSizes.componentRedPacketCardWidth)
        compose.runOnIdle { width.value = 180.dp }
        compose.onNodeWithText("Hello").assertWidthIsEqualTo(180.dp)
        compose.runOnIdle { width.value = 360.dp }
        compose.onNodeWithText("Hello").assertWidthIsEqualTo(FlareSizes.componentRedPacketCardWidth)
    }

    @Test fun aLongStatusWrapsInsteadOfLosingTheRecoveryExplanation() {
        val status = "This red packet is unavailable while the connection is recovering. Please try again after reconnecting."
        compose.setContent {
            FlareThemeProvider { RedPacketCard(blessing = "Hello", statusLabel = status, disabled = true) }
        }
        val results = mutableListOf<TextLayoutResult>()
        compose.onNodeWithText(status, useUnmergedTree = true).assertIsDisplayed()
            .performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(results) }
        assertTrue(results.single().lineCount > 1)
        assertTrue(!results.single().isLineEllipsized(results.single().lineCount - 1))
    }

    @Test fun theBrandStaysAtTheTrailingInsetWhenARecipientIsPresent() {
        compose.setContent {
            FlareThemeProvider {
                Column(Modifier.width(360.dp)) {
                    RedPacketCard(blessing = "Normal", onOpen = {})
                    RedPacketCard(blessing = "Exclusive", kind = FlareRedPacketKind.Exclusive,
                        recipientName = "QA Dave", onOpen = {})
                }
            }
        }
        val card = compose.onNodeWithText("Normal").getUnclippedBoundsInRoot()
        val brands = compose.onAllNodesWithText(FlareStrings().packetBrand, useUnmergedTree = true)
        for (index in 0..1) {
            val brand = brands[index].getUnclippedBoundsInRoot()
            assertEquals((card.right - FlareSizes.spacing2md).value, brand.right.value, 0.5f)
        }
    }

    @Test fun aQuotedReplyDoesNotOpenThePacket() {
        var quoteOpens = 0
        var packetOpens = 0
        compose.setContent {
            FlareThemeProvider {
                CompositionLocalProvider(LocalFlareCardQuote provides {
                    Text("Quoted greeting", Modifier.clickable { quoteOpens++ })
                }) {
                    RedPacketCard(blessing = "Hello", onOpen = { packetOpens++ })
                }
            }
        }
        compose.onNodeWithText("Quoted greeting").performClick()
        assertEquals(1, quoteOpens)
        assertEquals(0, packetOpens)
        compose.onNodeWithText("Hello").performClick()
        assertEquals(1, packetOpens)
    }

    @Test fun phoneAndDesktopCardsShareTheSameVisualContractInBothThemes() {
        val mode = mutableStateOf(FlareThemeMode.Light)
        val desktop = mutableStateOf(false)
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density / if (desktop.value) 2f else 1f, 1f)) {
                FlareThemeProvider(mode = mode.value) {
                    Column(Modifier.width(if (desktop.value) 720.dp else 360.dp)
                        .background(flareColors().bgSecondary).padding(FlareSizes.spacingMd),
                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
                        RedPacketCard(blessing = "恭喜发财，大吉大利", onOpen = {})
                        RedPacketCard(blessing = "红包已领取", state = FlareRedPacketCardState.Claimed, onOpen = {})
                        RedPacketCard(blessing = "专属红包", kind = FlareRedPacketKind.Exclusive,
                            recipientName = "QA Dave", statusLabel = "等待连接恢复后可领取此红包", onOpen = {})
                    }
                }
            }
        }
        capture("red-packet-android-phone-light.png")
        compose.runOnIdle { mode.value = FlareThemeMode.Dark }
        capture("red-packet-android-phone-dark.png")
        compose.runOnIdle { mode.value = FlareThemeMode.Light; desktop.value = true }
        capture("red-packet-android-desktop-light.png")
        compose.runOnIdle { mode.value = FlareThemeMode.Dark }
        capture("red-packet-android-desktop-dark.png")
    }

    private fun capture(name: String) {
        val file = File(InstrumentationRegistry.getInstrumentation().targetContext.getExternalFilesDir(null), name)
        file.outputStream().use { compose.onRoot().captureToImage().asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, it) }
        assertTrue(file.length() > 0)
    }
}
