package com.flare.im.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertHasNoClickAction
import androidx.compose.ui.test.assertHeightIsAtLeast
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertWidthIsAtLeast
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import kotlin.math.abs

/**
 * Where a picture, a video and a file stand on this device, in a real semantics tree: the file card's trailing key and
 * the viewers' key follow the host's download state — a download, its progress, then the folder that hands the host the
 * message to show in its folder — the open viewer catching up without closing; a received message's time sits at its
 * trailing edge; a video of unknown length has no "00:00" badge.
 */
class MediaDownloadStateInteractionTest {
    @get:Rule val compose = createComposeRule()
    private val strings = FlareStrings()

    private fun message(id: String, content: FlareMessageContent, timeLabel: String = "", replyTo: FlareReplyTarget? = null) =
        FlareMessageData(id = id, senderId = "ann", senderName = "Ann", content = content, timeLabel = timeLabel, replyTo = replyTo)

    private fun SemanticsNodeInteraction.assertButton(): SemanticsNodeInteraction =
        assertHasClickAction().assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))

    private fun SemanticsNodeInteraction.assertTouchTarget(min: Dp = FlareSizes.touchTarget): SemanticsNodeInteraction =
        assertWidthIsAtLeast(min).assertHeightIsAtLeast(min)

    private fun clickLabel(label: String) =
        SemanticsMatcher("click label $label") { it.config.getOrNull(SemanticsActions.OnClick)?.label == label }

    private fun bounds(node: SemanticsNodeInteraction): DpRect = node.assertIsDisplayed().getBoundsInRoot()

    private fun assertSameEdge(expected: Dp, actual: Dp, what: String) =
        assertTrue("$what: $expected vs $actual", abs(expected.value - actual.value) <= 1f)

    private val downloading = FlareMediaDownloadState(FlareMediaDownloadStatus.Downloading, 40)
    private val saved = FlareMediaDownloadState(FlareMediaDownloadStatus.Done)

    // MARK: file card

    @Test fun theFileCardKeyDownloadsShowsItsProgressThenTheFolder() {
        var state by mutableStateOf<FlareMediaDownloadState?>(null)
        val intents = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                FileMessage(
                    name = "连调测试.txt", size = "8.5 KB", ext = "TXT",
                    onOpen = { intents += "open" },
                    onDownload = { intents += "download" },
                    downloadState = state,
                    onReveal = { intents += "reveal" },
                )
            }
        }
        compose.onNodeWithContentDescription(strings.showInFolder).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.download).assertButton().assertTouchTarget().performClick()

        compose.runOnIdle { state = downloading }
        // The ring stands where the key was and is not a second key; the line says the download runs.
        compose.onNodeWithContentDescription(strings.downloading).assertHasNoClickAction().assertTouchTarget()
        compose.onNodeWithContentDescription(strings.download).assertDoesNotExist()
        compose.onNodeWithText("8.5 KB · TXT · ${strings.downloading} 40%", substring = true).assertExists()

        compose.runOnIdle { state = saved }
        compose.onNodeWithText("8.5 KB · TXT · ${strings.downloaded}", substring = true).assertExists()
        compose.onNodeWithContentDescription(strings.download).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.showInFolder).assertButton().assertTouchTarget().performClick()

        // The file deleted since: the host passes idle again and the key downloads once more.
        compose.runOnIdle { state = FlareMediaDownloadState() }
        compose.onNodeWithContentDescription(strings.showInFolder).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.download).assertButton()
        // The card itself still opens the file.
        compose.onNodeWithText("连调测试.txt").performClick()
        compose.runOnIdle { assertEquals(listOf("download", "reveal", "open"), intents) }
    }

    @Test fun aFileCardWithoutADownloadHandlerDrawsNoKey() {
        compose.setContent {
            FlareThemeProvider { FileMessage(name = "spec.pdf", size = "2 MB", downloadState = saved, onReveal = {}) }
        }
        compose.onNodeWithContentDescription(strings.download).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.showInFolder).assertDoesNotExist()
    }

    @Test fun aTimelineFileCardHandsTheHostTheMessageAndTheFile() {
        val file = FlareFileContent("spec.pdf", "https://example.invalid/spec.pdf", 2048)
        var states by mutableStateOf(emptyMap<String, FlareMediaDownloadState>())
        val intents = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(message("f1", file)),
                    currentUserId = "me",
                    mediaDownloadStates = states,
                    onOpenFile = { msg, _ -> intents += "open ${msg.id}" },
                    onMediaDownload = { msg, content -> intents += "download ${msg.id} ${(content as FlareFileContent).name}"; states = states + (msg.id to downloading) },
                    onMediaReveal = { msg, content -> intents += "reveal ${msg.id} ${(content as FlareFileContent).name}" },
                )
            }
        }
        compose.onNodeWithContentDescription(strings.download).performClick()
        compose.onNodeWithContentDescription(strings.downloading).assertExists()
        compose.runOnIdle { states = mapOf("f1" to saved) }
        compose.onNodeWithContentDescription(strings.showInFolder).performClick()
        compose.onNodeWithText("spec.pdf").performClick()
        compose.runOnIdle { assertEquals(listOf("download f1 spec.pdf", "reveal f1 spec.pdf", "open f1"), intents) }
    }

    // MARK: viewers follow the state while open

    @Test fun theVideoPlayersKeyFollowsTheStateWithoutClosing() {
        val video = FlareVideoContent("https://example.invalid/v.mp4", durationSec = 12)
        var states by mutableStateOf(emptyMap<String, FlareMediaDownloadState>())
        val intents = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(message("v1", video)),
                    currentUserId = "me",
                    mediaDownloadStates = states,
                    onMediaDownload = { msg, _ -> intents += "download ${msg.id}"; states = states + (msg.id to downloading) },
                    onMediaReveal = { msg, content -> intents += "reveal ${msg.id} ${(content as FlareVideoContent).url}" },
                )
            }
        }
        compose.onNodeWithText("00:12").performClick()
        compose.onNodeWithContentDescription(strings.download).assertButton().assertTouchTarget().performClick()
        // Still the player: its key is now the ring, then the folder.
        compose.onNodeWithContentDescription(strings.downloading).assertIsDisplayed().assertHasNoClickAction()
        compose.onNodeWithContentDescription(strings.close).assertIsDisplayed()
        compose.runOnIdle { states = mapOf("v1" to saved) }
        compose.onNodeWithContentDescription(strings.downloading).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.showInFolder).assertButton().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.close).assertIsDisplayed()
        compose.runOnIdle { assertEquals(listOf("download v1", "reveal v1 https://example.invalid/v.mp4"), intents) }
    }

    @Test fun theImagePreviewsKeyFollowsThePageOnScreen() {
        var states by mutableStateOf(emptyMap<String, FlareMediaDownloadState>())
        val intents = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(
                        message("i1", FlareImageContent("https://example.invalid/1.jpg", alt = "海边")),
                        message("i2", FlareImageContent("https://example.invalid/2.jpg", alt = "山顶")),
                    ),
                    currentUserId = "me",
                    mediaDownloadStates = states,
                    onMediaDownload = { msg, _ -> intents += "download ${msg.id}"; states = states + (msg.id to downloading) },
                    onMediaReveal = { msg, content -> intents += "reveal ${msg.id} ${(content as FlareImageContent).url}" },
                )
            }
        }
        compose.onNodeWithContentDescription("海边").performClick()
        compose.onNodeWithContentDescription(strings.download).performClick()
        compose.onNodeWithContentDescription(strings.downloading).assertIsDisplayed()
        compose.runOnIdle { states = mapOf("i1" to saved) }
        compose.onNodeWithContentDescription(strings.showInFolder).assertButton().performClick()
        // The next page is another message, not saved: its key is a download.
        compose.onNodeWithContentDescription(strings.imagePreviewNext).performClick()
        compose.onNodeWithContentDescription(strings.showInFolder).assertDoesNotExist()
        compose.onNodeWithContentDescription(strings.download).assertButton()
        compose.runOnIdle { assertEquals(listOf("download i1", "reveal i1 https://example.invalid/1.jpg"), intents) }
    }

    // MARK: time at the trailing edge

    @Test fun aReceivedTextsTimeSitsAtTheBubblesTrailingEdge() {
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(
                        message("t1", FlareTextContent("这是一条比时间宽得多的收到的消息，正文仍然从左边开始"), timeLabel = "09:41"),
                        message("t2", FlareTextContent("嗯"), timeLabel = "09:42"),
                        message("t3", FlareTextContent("好"), timeLabel = "09:43", replyTo = FlareReplyTarget(messageId = null, senderName = "Bo", summary = "一条比回复和时间都宽得多的被引用消息")),
                    ),
                    currentUserId = "me",
                )
            }
        }
        // Body wider than the time: the time ends where the body ends, and does not start where the body starts.
        val wide = bounds(compose.onNodeWithText("这是一条", substring = true))
        val wideTime = bounds(compose.onNodeWithText("09:41"))
        assertSameEdge(wide.right, wideTime.right, "wide body: time at the trailing edge")
        assertTrue("wide body: the text keeps its own start", wideTime.left > wide.left + 8.dp)
        // Body narrower than the time: the bubble is as wide as the time, which reaches its trailing edge.
        val narrow = bounds(compose.onNodeWithText("嗯"))
        val narrowTime = bounds(compose.onNodeWithText("09:42"))
        assertTrue("narrow body: time reaches past the body", narrowTime.right >= narrow.right)
        assertSameEdge(narrow.left, narrowTime.left, "narrow body: bubble hugs the time")
        // A quote wider than body and time: the time sits under the quote's trailing edge, not under the short body.
        val quote = bounds(compose.onNodeWithText("一条比回复", substring = true))
        val quotedTime = bounds(compose.onNodeWithText("09:43"))
        assertSameEdge(quote.right, quotedTime.right, "quoted: time at the bubble's trailing edge")
    }

    @Test fun aReceivedFileAndPicturesTimeSitAtTheirTrailingEdge() {
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(
                        message("f1", FlareFileContent("连调测试.txt", "https://example.invalid/a.txt", 8704), timeLabel = "00:11"),
                        message("i1", FlareImageContent("https://example.invalid/p.jpg", alt = "照片"), timeLabel = "00:12"),
                    ),
                    currentUserId = "me",
                    onMediaDownload = { _, _ -> },
                )
            }
        }
        // The file card: its key is its trailing edge, and the time sits under it at the bubble's bottom right.
        val key = bounds(compose.onNodeWithContentDescription(strings.download))
        val name = bounds(compose.onNodeWithText("连调测试.txt"))
        val fileTime = bounds(compose.onNodeWithText("00:11"))
        assertSameEdge(key.right, fileTime.right, "file card: time at the card's trailing edge")
        assertTrue("file card: time is not at the card's start", fileTime.left > name.left + 8.dp)
        // A bare picture: the time under it at its trailing edge.
        val picture = bounds(compose.onNodeWithContentDescription("照片"))
        val pictureTime = bounds(compose.onNodeWithText("00:12"))
        assertSameEdge(picture.right, pictureTime.right, "picture: time at the picture's trailing edge")
        assertTrue("picture: time is not at the picture's start", pictureTime.left > picture.left + 8.dp)
    }

    // MARK: video thumbnail

    @Test fun aVideoOfUnknownLengthHasNoZeroBadgeAndStillPlays() {
        compose.setContent {
            FlareThemeProvider {
                MessageList(messages = listOf(message("v1", FlareVideoContent("https://example.invalid/v.mp4"))), currentUserId = "me")
            }
        }
        compose.onNodeWithText("00:00").assertDoesNotExist()
        compose.onNode(clickLabel(strings.play)).assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.close).assertIsDisplayed()
    }
}
