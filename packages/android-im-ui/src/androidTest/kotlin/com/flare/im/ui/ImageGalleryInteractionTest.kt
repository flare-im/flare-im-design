package com.flare.im.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * A picture tapped in a timeline opens the timeline's gallery at that picture, which pages with its controls and a swipe
 * and downloads the picture on screen.
 */
class ImageGalleryInteractionTest {
    @get:Rule val compose = createComposeRule()
    private val strings = FlareStrings()

    private fun message(id: String, content: FlareMessageContent) =
        FlareMessageData(id = id, senderId = "ann", senderName = "Ann", content = content)

    @Test fun anAlbumTileOpensTheTimelineGalleryAtItsPicture() {
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(
                        message("m1", FlareImageContent("https://example.invalid/1.jpg")),
                        message("m2", FlareImageGroupContent(listOf(FlareImageContent("https://example.invalid/2.jpg"), FlareImageContent("https://example.invalid/3.jpg")))),
                    ),
                    currentUserId = "me",
                )
            }
        }
        compose.onNodeWithContentDescription(strings.messageImageGroupItem(2, 2)).performClick()
        // The position is read as a sentence ("3 of 3"); the digits on screen carry no semantics of their own.
        compose.onNodeWithContentDescription(strings.imagePreviewPosition(3, 3)).assertExists()
        compose.onNodeWithContentDescription(strings.imagePreviewNext).assertIsNotEnabled()
        compose.onNodeWithContentDescription(strings.imagePreviewPrevious).performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewPosition(2, 3)).assertExists()
    }

    /** The key downloads the picture on screen, with the message it belongs to — whichever picture was tapped. */
    @Test fun theGalleryDownloadsThePictureOnScreenWithTheMessageItBelongsTo() {
        val saved = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(
                        message("m1", FlareImageContent("https://example.invalid/1.jpg")),
                        message("m2", FlareImageGroupContent(listOf(FlareImageContent("https://example.invalid/2.jpg"), FlareImageContent("https://example.invalid/3.jpg")))),
                    ),
                    currentUserId = "me",
                    onMediaDownload = { message, content -> saved += "${message.id}:${(content as FlareImageContent).url}" },
                )
            }
        }
        compose.onNodeWithContentDescription(strings.messageImageGroupItem(2, 2)).performClick()
        compose.onNodeWithContentDescription(strings.download).performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewPrevious).performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewPrevious).performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewPosition(1, 3)).assertExists()
        compose.onNodeWithContentDescription(strings.download).performClick()
        compose.runOnIdle { assertEquals(listOf("m2:https://example.invalid/3.jpg", "m1:https://example.invalid/1.jpg"), saved) }
    }

    /** Outside a timeline a picture opens alone, with the key its body was given — and without one, no key. */
    @Test fun aPictureAloneOffersTheDownloadItsBodyWasGivenAndNoneWithoutOne() {
        val saved = mutableListOf<String>()
        var offered by mutableStateOf(true)
        val picture = FlareImageContent("https://example.invalid/solo.jpg", alt = "海边")
        compose.setContent {
            FlareThemeProvider {
                MessageContentView(
                    content = picture,
                    onMediaDownload = if (offered) ({ saved += (it as FlareImageContent).url }) else null,
                )
            }
        }
        compose.onNodeWithContentDescription("海边").performClick()
        compose.onNodeWithContentDescription(strings.download).performClick()
        compose.runOnIdle { assertEquals(listOf("https://example.invalid/solo.jpg"), saved) }

        compose.onNodeWithContentDescription(strings.imagePreviewClose).performClick()
        compose.runOnIdle { offered = false }
        compose.onNodeWithContentDescription("海边").performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewClose).assertExists()
        compose.onNodeWithContentDescription(strings.download).assertDoesNotExist()
    }

    @Test fun aSidewaysSwipePages() {
        compose.setContent {
            FlareThemeProvider {
                ImageGalleryPreview(listOf("https://example.invalid/a.jpg", "https://example.invalid/b.jpg"), 0, onClose = {})
            }
        }
        compose.onNodeWithContentDescription(strings.imagePreviewPosition(1, 2)).assertExists()
        // Across the whole preview, not across the few digits of the position.
        compose.onRoot().performTouchInput { swipeLeft() }
        compose.onNodeWithContentDescription(strings.imagePreviewPosition(2, 2)).assertExists()
    }
}
