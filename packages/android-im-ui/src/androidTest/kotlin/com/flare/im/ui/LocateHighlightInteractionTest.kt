package com.flare.im.ui

import android.graphics.Bitmap
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * The mark a located row wears, on a screen. The numbers are the shared table
 * (`test/LocateHighlightVectorsTest`); what needs a device is that the ring is actually drawn and actually
 * goes away — a mark nobody can see is the defect this batch exists to remove, and no JVM test can see one.
 */
class LocateHighlightInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun message(id: String) = FlareMessageData(
        id = id, senderId = "ann", senderName = "Ann", content = FlareTextContent("第 $id 条"),
    )

    private fun pixels(): IntArray {
        val image = compose.onRoot().captureToImage().asAndroidBitmap()
            .copy(Bitmap.Config.ARGB_8888, false)
        return IntArray(image.width * image.height).also {
            image.getPixels(it, 0, image.width, 0, 0, image.width, image.height)
        }
    }

    /**
     * Both shots are taken after the scroll has finished, so the only thing that can differ between them is
     * the mark: present inside the window, gone after it. A third shot later still proves the thread had come
     * to rest — otherwise a scroll still settling would pass for a mark going away.
     *
     * The host asks from the list's own scope, the way a host does: a scroll is animated on frames, and a
     * scope that has no frames (a bare `runBlocking`) cannot run one.
     */
    @Test fun theLocatedRowIsMarkedWhileTheWindowRunsAndPlainAfterIt() {
        val state = FlareMessageListState()
        lateinit var scope: CoroutineScope
        compose.mainClock.autoAdvance = false
        compose.setContent { MaterialTheme {
            scope = rememberCoroutineScope()
            MessageList(messages = (0..39).map { message("$it") }, currentUserId = "me", state = state)
        } }
        compose.mainClock.advanceTimeBy(1_000)

        compose.runOnUiThread { scope.launch { state.scrollToMessage("20") } }
        // Past the scroll (260 ms), inside the mark's window (1600 ms).
        compose.mainClock.advanceTimeBy(600)
        val marked = pixels()

        compose.mainClock.advanceTimeBy(LOCATE_HIGHLIGHT_DURATION_MS.toLong())
        val afterwards = pixels()
        assertFalse("the mark never goes away, or was never drawn", marked.contentEquals(afterwards))

        compose.mainClock.advanceTimeBy(1_000)
        assertTrue("the thread was still moving after the mark ended", pixels().contentEquals(afterwards))
    }
}
