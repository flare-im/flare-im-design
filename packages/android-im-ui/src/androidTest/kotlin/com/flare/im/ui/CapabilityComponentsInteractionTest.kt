package com.flare.im.ui

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ExifInterface
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.runtime.CompositionLocalProvider
import java.io.ByteArrayOutputStream
import java.io.File
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/** The capability components drawn and the document processing run on a device (BitmapFactory, ExifInterface). */
class CapabilityComponentsInteractionTest {
    @get:Rule val compose = createComposeRule()
    private val en = flareStringsEnglish()

    private fun content(body: @androidx.compose.runtime.Composable () -> Unit) =
        compose.setContent { CompositionLocalProvider(LocalFlareStrings provides en) { body() } }

    @Test fun aPhotoWithExifComesOutUprightWithoutIt() {
        val bitmap = Bitmap.createBitmap(3000, 2000, Bitmap.Config.ARGB_8888).apply { eraseColor(0xFFCCB4A0.toInt()) }
        val raw = ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.JPEG, 95, it) }.toByteArray()
        val file = File.createTempFile("doc", ".jpg").apply { writeBytes(raw) }
        ExifInterface(file.absolutePath).apply {
            setAttribute(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_ROTATE_90.toString())
            setAttribute(ExifInterface.TAG_GPS_LATITUDE, "31/1,12/1,0/1")
            setAttribute(ExifInterface.TAG_MAKE, "Camera")
            saveAttributes()
        }
        val withExif = file.readBytes()
        assertFalse(FlareDocumentRules.jpegIsStripped(withExif))
        val out = runBlocking { FlareDocumentRules.process(withExif, FlareDocumentSide.Front, 400 * 1024) }
        assertEquals("document-front.jpg", out.fileName)
        assertTrue(out.bytes.size <= 400 * 1024)
        assertTrue(FlareDocumentRules.jpegIsStripped(out.bytes))
        val decoded = BitmapFactory.decodeByteArray(out.bytes, 0, out.bytes.size)
        assertTrue("rotation is baked into the pixels", decoded.height > decoded.width)
        assertTrue(maxOf(decoded.width, decoded.height) <= 2048)
    }

    @Test fun consentOffersAlwaysOnlyWhereItMay() {
        val decisions = mutableListOf<FlareCapabilityConsentDecision>()
        content { FlareCapabilityConsentBody("documentCapture", { decisions += it }, purpose = "Verify") }
        compose.onNodeWithText(en.capabilityDocumentCapture).assertExists()
        compose.onNodeWithText(en.capabilityConsentAllowAlways).performClick()
        compose.onNodeWithText(en.capabilityConsentDeny).performClick()
        compose.runOnIdle { assertEquals(listOf(FlareCapabilityConsentDecision.Always, FlareCapabilityConsentDecision.Deny), decisions) }
    }

    @Test fun aOneTimeLocationOffersNoAlways() {
        content { FlareCapabilityConsentBody("locationOnce", {}, params = mapOf("precision" to "fine")) }
        compose.onNodeWithText(en.capabilityConsentAllowAlways).assertDoesNotExist()
        compose.onNodeWithText(en.capabilityLocationFine).assertExists()
    }

    @Test fun anExpiredOrderCannotBeConfirmed() {
        var confirms = 0
        val order = FlarePaymentOrder("o", "1234.50", "CNY", "Wallet", "Red packet", expiresAtMs = 1_000)
        content { FlarePaymentConfirmationBody(order, { confirms++ }, {}, nowMs = { 2_000 }) }
        compose.onNodeWithText("¥1,234.50").assertExists()
        compose.onNodeWithTag("flare-payment-expired").assertExists()
        compose.onNodeWithText(en.paymentConfirmationConfirm).assertIsNotEnabled()
        compose.runOnIdle { assertEquals(0, confirms) }
    }

    @Test fun anOpenOrderConfirmsOnce() {
        var confirms = 0
        val order = FlarePaymentOrder("o", "5.00", "CNY", "Wallet", "", expiresAtMs = 120_000)
        content { FlarePaymentConfirmationBody(order, { confirms++ }, {}, nowMs = { 0 }) }
        compose.onNodeWithTag("flare-payment-countdown").assertExists()
        compose.onNodeWithText(en.paymentConfirmationConfirm).performClick()
        compose.runOnIdle { assertEquals(1, confirms) }
    }

    @Test fun theCaptureFramesTheSideAndOffersTheAlbumWhenTheCameraIsOut() {
        content {
            FlareDocumentCaptureBody(FlareDocumentSide.Holding, 1_000_000, {}, capture = { null }, pickPhoto = { null },
                cameraUnavailable = true)
        }
        compose.onNodeWithTag("flare-doc-frame").assertExists()
        compose.onNodeWithText(en.documentCaptureShoot).assertDoesNotExist()
        compose.onNodeWithText(en.documentCaptureFromAlbum).assertExists()
        compose.onNodeWithText(en.documentCaptureCameraUnavailable).assertExists()
    }

    @Test fun theOwnerReadsWithOneTapAndALocationArrivesFromTheHost() {
        val reads = mutableListOf<PluginProtectedMediaRead>()
        val block = PluginProtectedMediaBlock(label = "Mine", items = listOf(PluginProtectedItem("m1", "Front", "image/jpeg")),
            action = PluginViewAction("viewDocument", "View"), inputName = "materialId", urlPath = "/url")
        content { PluginProtectedMediaBlockView(block, emptyMap(), busy = false) { reads += it } }
        compose.onNodeWithText(en.pluginProtectedMediaView).performClick()
        compose.runOnIdle { assertEquals(mapOf("materialId" to "m1"), reads.single().formValues) }
        compose.onNodeWithText(en.pluginProtectedMediaOwnNotice).assertExists()
    }

    @Test fun aLocationInputShowsTheHostsFix() {
        val actions = mutableListOf<PluginLocationAction>()
        val input = PluginInput("place", PluginInputKind.Location, "Where", required = true, precision = PluginLocationPrecision.Coarse)
        val fix = PluginLocationValue(31.23, 121.47, 1000, PluginLocationPrecision.Coarse)
        content {
            PluginForm(listOf(input), locationStates = mapOf("place" to PluginLocationState(value = fix)),
                onLocationAction = { actions += it })
        }
        compose.onNodeWithTag("plugin-location-place-place").assertExists()
        compose.onNodeWithText("31.23°N, 121.47°E").assertExists()
        compose.onNodeWithText(en.pluginLocationClear).performClick()
        compose.runOnIdle { assertEquals(PluginLocationActionKind.Clear, actions.single().action) }
    }
}
