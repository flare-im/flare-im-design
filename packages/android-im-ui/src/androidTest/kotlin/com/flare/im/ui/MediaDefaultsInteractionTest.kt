package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertHeightIsAtLeast
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertWidthIsAtLeast
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.Dp
import java.time.LocalDate
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * Received media in a real semantics tree: without a host media handler a tap presents the image
 * preview or the video player, a voice plays in its bubble one at a time, a host handler takes the tap
 * instead, and files go to the host's file handler. The timeline dates its days.
 */
class MediaDefaultsInteractionTest {
    @get:Rule val compose = createComposeRule()
    private val strings = FlareStrings()

    private fun message(id: String, content: FlareMessageContent, sentAtMs: Long = 0) =
        FlareMessageData(id = id, senderId = "ann", senderName = "Ann", content = content, sentAtMs = sentAtMs)

    private fun SemanticsNodeInteraction.assertButton(): SemanticsNodeInteraction =
        assertHasClickAction().assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button))

    private fun SemanticsNodeInteraction.assertTouchTarget(min: Dp = FlareSizes.touchTarget): SemanticsNodeInteraction =
        assertWidthIsAtLeast(min).assertHeightIsAtLeast(min)

    private fun clickLabel(label: String) =
        SemanticsMatcher("click label $label") { it.config.getOrNull(SemanticsActions.OnClick)?.label == label }

    @Test fun tappingAnImagePresentsThePreviewAndCloseDismissesIt() {
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(message("i1", FlareImageContent("https://example.invalid/full.jpg", thumbnailUrl = "https://example.invalid/thumb.jpg", alt = "照片"))),
                    currentUserId = "me",
                )
            }
        }
        compose.onNodeWithContentDescription(strings.imagePreviewClose).assertDoesNotExist()
        // TalkBack announces what the tap does.
        compose.onNodeWithContentDescription("照片").assert(clickLabel(strings.imagePreviewOpen)).performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewClose).assertIsDisplayed().assertButton().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.imagePreviewClose).assertDoesNotExist()
    }

    @Test fun tappingAVideoPresentsThePlayer() {
        compose.setContent {
            FlareThemeProvider {
                MessageList(messages = listOf(message("v1", FlareVideoContent("https://example.invalid/v.mp4", durationSec = 12))), currentUserId = "me")
            }
        }
        compose.onNodeWithText("00:12").assert(clickLabel(strings.play)).performClick()
        compose.onNodeWithContentDescription(strings.close).assertIsDisplayed().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.close).assertDoesNotExist()
    }

    @Test fun anUnplayableVideoShowsTheFailureAndCloseInsteadOfABlankScreen() {
        var closes = 0
        compose.setContent { FlareThemeProvider { VideoPlayer(show = true, videoSrc = "javascript:alert(1)", onClose = { closes++ }) } }
        compose.onNodeWithText(strings.videoLoadFailed).assertIsDisplayed()
        // Nothing to retry for an address the player may not load; close stays.
        compose.onNodeWithText(strings.retry).assertDoesNotExist()
        compose.onNodeWithText(strings.close).assertHasClickAction().assertHeightIsAtLeast(FlareSizes.touchTarget).performClick()
        compose.runOnIdle { assertEquals(1, closes) }
    }

    private class FakeVoiceEngine : FlareVoiceEngine {
        var prepared: ((Int) -> Unit)? = null
        var released = false
        override val positionMs: Int = 0
        override fun open(url: String, onPrepared: (durationMs: Int) -> Unit, onCompleted: () -> Unit, onError: () -> Unit) { prepared = onPrepared }
        override fun start() {}
        override fun pause() {}
        override fun release() { released = true }
    }

    @Test fun aVoicePlaysInItsBubbleAndASecondVoiceStopsTheFirst() {
        val engines = mutableListOf<FakeVoiceEngine>()
        val host = FlareMediaHost(FlareVoicePlayback { FakeVoiceEngine().also { engines += it } })
        compose.setContent {
            FlareThemeProvider {
                CompositionLocalProvider(LocalFlareMediaHost provides host) {
                    Column {
                        CompositionLocalProvider(LocalFlareMessageKey provides "a1") { MessageContentView(FlareAudioContent("https://example.invalid/a.m4a", 5)) }
                        CompositionLocalProvider(LocalFlareMessageKey provides "a2") { MessageContentView(FlareAudioContent("https://example.invalid/b.m4a", 7)) }
                    }
                }
            }
        }
        compose.onAllNodesWithContentDescription(strings.play).assertCountEquals(2)
        compose.onAllNodesWithContentDescription(strings.play)[0].assertButton().assertTouchTarget().performClick()
        compose.runOnIdle { engines.single().prepared!!(5_000) }
        compose.onAllNodesWithContentDescription(strings.pause).assertCountEquals(1)
        // The other voice is still the one to play.
        compose.onAllNodesWithContentDescription(strings.play).assertCountEquals(1)[0].performClick()
        compose.runOnIdle {
            assertTrue(engines[0].released)
            assertEquals("a2", host.voice.activeKey)
        }
        compose.onAllNodesWithContentDescription(strings.pause).assertCountEquals(1)
        compose.onAllNodesWithContentDescription(strings.play).assertCountEquals(1)
    }

    @Test fun aHostMediaHandlerTakesTheTapInsteadOfThePreview() {
        val taps = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(message("i1", FlareImageContent("https://example.invalid/i.jpg", alt = "照片"))),
                    currentUserId = "me",
                    onMediaAction = { msg, _ -> taps += msg.id },
                )
            }
        }
        compose.onNodeWithContentDescription("照片").performClick()
        compose.runOnIdle { assertEquals(listOf("i1"), taps) }
        compose.onNodeWithContentDescription(strings.imagePreviewClose).assertDoesNotExist()
    }

    @Test fun aFileTapGoesToTheHostFileHandler() {
        val opened = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(message("f1", FlareFileContent("spec.pdf", "https://example.invalid/spec.pdf", 2048))),
                    currentUserId = "me",
                    onOpenFile = { _, file -> opened += file.url },
                )
            }
        }
        compose.onNodeWithText("spec.pdf").performClick()
        compose.runOnIdle { assertEquals(listOf("https://example.invalid/spec.pdf"), opened) }
    }

    @Test fun theTimelineDatesItsDaysAndTheUnreadDividerFollowsThePill() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now(zone)
        fun on(day: LocalDate, hour: Int) = day.atTime(hour, 0).atZone(zone).toInstant().toEpochMilli()
        compose.setContent {
            FlareThemeProvider {
                MessageList(
                    messages = listOf(
                        message("y", FlareTextContent("昨天的消息"), on(today.minusDays(1), 9)),
                        message("t1", FlareTextContent("今天第一条"), on(today, 1)),
                        message("t2", FlareTextContent("今天第二条"), on(today, 2)),
                    ),
                    currentUserId = "me",
                    unreadFromId = "t1",
                )
            }
        }
        val pill = compose.onNodeWithText(strings.today).assertIsDisplayed().getBoundsInRoot()
        val divider = compose.onNodeWithText(strings.newMessages(2)).assertIsDisplayed().getBoundsInRoot()
        compose.onNodeWithText(strings.yesterday).assertIsDisplayed()
        assertTrue("the unread divider sits below today's pill", divider.top >= pill.bottom)
    }
}
