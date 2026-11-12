package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class ScanViewfinderRetryInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun pausedImageOffersTheExistingExplicitRetryAction() {
        var retries = 0
        compose.setContent { MaterialTheme {
            ScanViewfinder(state = "paused", capabilities = FlareScanCapabilities(live = false, album = false, paste = false, myCode = false),
                onClose = {}, onRetry = { retries++ }, preview = {})
        } }
        compose.onNodeWithText(FlareStrings().retry).performClick()
        compose.runOnIdle { assertEquals(1, retries) }
    }

    @Test fun anExplicitMultiCodeChoiceDoesNotAcquireARetryThatDiscardsIt() {
        compose.setContent { MaterialTheme {
            ScanViewfinder(state = "choosing", capabilities = FlareScanCapabilities(live = false, album = false, paste = false, myCode = false),
                onClose = {}, onRetry = {}, preview = {})
        } }
        compose.onNodeWithText(FlareStrings().retry).assertDoesNotExist()
    }
    @Test fun imageFailureKeepsItsOwnLabelRetryAndAlbum() {
        var retries = 0
        var picks = 0
        val strings = FlareStrings()
        compose.setContent { MaterialTheme {
            ScanViewfinder(state = "imageError", capabilities = FlareScanCapabilities(live = false, album = true, paste = false, myCode = false),
                onClose = {}, onRetry = { retries++ }, onPickImage = { picks++ }, preview = {})
        } }
        compose.onNodeWithText(strings.scanImageError).assertExists()
        compose.onNodeWithText(strings.scanNoCodeInImage).assertDoesNotExist()
        compose.onNodeWithText(strings.scanCameraError).assertDoesNotExist()
        compose.onNodeWithText(strings.retry).performClick()
        compose.onNodeWithText(strings.scanAlbum).performClick()
        compose.runOnIdle { assertEquals(1, retries); assertEquals(1, picks) }
    }
}
