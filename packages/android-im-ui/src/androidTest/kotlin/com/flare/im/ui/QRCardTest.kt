package com.flare.im.ui

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import kotlin.math.floor
import kotlin.math.sqrt

/** FR-031: [QRCard] encodes its payload; without one it says so and draws no matrix. */
class QRCardTest {
    @get:Rule val compose = createComposeRule()

    private val english = FlareStrings {
        qrCode = "QR code"
        qrCardUnavailable = "QR code unavailable"
        scanToAddMe = "Scan to add me"
    }

    @Test fun withoutAPayloadTheFrameSaysUnavailableAndDrawsNoCode() {
        var payload by mutableStateOf<String?>(null)
        compose.setContent {
            CompositionLocalProvider(LocalFlareStrings provides english) {
                FlareThemeProvider { QRCard(name = "Alice", qrPayload = payload) }
            }
        }
        for (value in listOf(null, "", "x".repeat(2332))) {
            payload = value
            compose.waitForIdle()
            compose.onNodeWithText("QR code unavailable").assertIsDisplayed()
            compose.onNodeWithContentDescription("QR code, Alice").assertDoesNotExist()
            compose.onNodeWithText("Scan to add me").assertDoesNotExist()
        }
    }

    @Test fun aPayloadDrawsDarkModulesOnALightPanelInTheDarkTheme() {
        val payload = "https://flare.im/add-friend?token=compose-qr-card"
        compose.setContent {
            CompositionLocalProvider(LocalFlareStrings provides english) {
                FlareThemeProvider(mode = FlareThemeMode.Dark) { QRCard(name = "Alice", qrPayload = payload) }
            }
        }
        compose.onNodeWithText("QR code unavailable").assertDoesNotExist()
        compose.onNodeWithText("Scan to add me").assertIsDisplayed()
        val code = compose.onNodeWithContentDescription("QR code, Alice")
            .assertIsDisplayed()
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Image))

        // Every module centre, quiet zone included, against the encoder output.
        val pixels = code.captureToImage().toPixelMap()
        val symbol = QrEncoder.encodeText(payload)!!
        val quiet = QrEncoder.QUIET_ZONE
        val count = symbol.size + 2 * quiet
        val inset = with(compose.density) { FlareSizes.radiusLg.toPx() } * (1 - sqrt(0.5f))
        val module = floor((minOf(pixels.width, pixels.height) - 2 * inset) / count)
        val left = floor((pixels.width - module * count) / 2)
        val top = floor((pixels.height - module * count) / 2)
        var mismatches = 0
        val details = mutableListOf<String>()
        for (my in 0 until count) {
            for (mx in 0 until count) {
                val inside = mx in quiet until quiet + symbol.size && my in quiet until quiet + symbol.size
                val dark = inside && symbol.isDark(mx - quiet, my - quiet)
                val expected = if (dark) FlareColors.Light.textPrimary else FlareColors.Light.bgPrimary
                val px = (left + (mx + 0.5f) * module).toInt()
                val py = (top + (my + 0.5f) * module).toInt()
                if (pixels[px, py] != expected) {
                    mismatches++
                    details += "($mx,$my px $px,$py got ${pixels[px, py]} want $expected)"
                }
            }
        }
        assertEquals("module centres that differ from the symbol: w=${pixels.width} h=${pixels.height} module=$module left=$left top=$top $details", 0, mismatches)
    }
}
