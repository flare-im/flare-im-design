package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.test.platform.app.InstrumentationRegistry
import coil.Coil
import coil.ImageLoader
import coil.intercept.Interceptor
import coil.request.ErrorResult
import coil.request.ImageResult
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * The message surface and meta on a device (docs/design/message-surface-and-meta.md): a plugin card is one container
 * (no bubble around PluginView's shell), the meta of a card sits below it, the retry and read-summary keys reach the
 * touch target, the card's ⋯ menu runs its actions, grouping breaks at a card, a read-only copy acts on nothing, and
 * the bubble's avatar loads its URL.
 */
class MessageSurfaceInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val zh = FlareStrings()

    private fun content(body: @Composable () -> Unit) = compose.setContent {
        FlareThemeProvider { Box(Modifier.width(400.dp)) { body() } }
    }

    private fun SemanticsNodeInteraction.size(): Pair<Dp, Dp> = getUnclippedBoundsInRoot().let { (it.right - it.left) to (it.bottom - it.top) }

    private val poll = PluginViewModel(
        available = true,
        title = "周五团建去哪儿？",
        blocks = listOf(PluginChoicesBlock(listOf(PluginChoice(0, "爬山"), PluginChoice(1, "桌游")),
            action = PluginViewAction("vote", "投票"))),
        menuActions = listOf(PluginViewAction("close", "结束投票", PluginActionStyle.Danger)),
    )

    private fun pluginMessage(id: String = "p1", sender: String = "u1", at: Long = 0, status: FlareMessageDeliveryStatus = FlareMessageDeliveryStatus.Sent) =
        FlareMessageData(
            id = id, senderId = sender, senderName = "Ann", sentAtMs = at, timeLabel = "09:30", status = status,
            content = FlareGenericContent("custom", "Poll", subtype = "flare.plugin.message.v1"),
        )

    private val pluginCard: FlareContentBuilder = { _, _ -> Box(Modifier.testTag("card")) { PluginView(view = poll, onAction = { _, _ -> }) } }

    /** P0-1: the card is drawn straight in the row — at the row's own inset, not inside a bubble's padding. */
    @Test fun aPluginCardIsOneContainer() {
        content {
            FlareContentScope(builders = mapOf("custom" to pluginCard)) {
                Column(Modifier.fillMaxWidth()) {
                    MessageBubble(message = pluginMessage(), currentUserId = "me")
                }
            }
        }
        val card = compose.onNodeWithTag("card", useUnmergedTree = true).getUnclippedBoundsInRoot()
        assertEquals("no bubble padding before the card's shell", FlareSizes.spacingMd.value, card.left.value, 0.5f)
        assertTrue("the shell is at most the rich card width", (card.right - card.left).value <= FlareSizes.componentRichCardWidth.value + 0.5f)
    }

    /** C2: a card's time sits under it, at its trailing edge. */
    @Test fun aCardsMetaSitsBelowIt() {
        content {
            FlareContentScope(builders = mapOf("custom" to pluginCard)) {
                MessageBubble(message = pluginMessage(), currentUserId = "me")
            }
        }
        val card = compose.onNodeWithTag("card", useUnmergedTree = true).getUnclippedBoundsInRoot()
        val time = compose.onNodeWithText("09:30", useUnmergedTree = true).getUnclippedBoundsInRoot()
        assertTrue("the time is under the card (${time.top} vs ${card.bottom})", time.top >= card.bottom)
        assertEquals("at the card's trailing edge", card.right.value, time.right.value, 1f)
    }

    /** C2 / C3: the failed card's "Failed to send. Retry" and the failed bubble's glyph both reach the touch target. */
    @Test fun retryKeysReachTheTouchTarget() {
        var resent = 0
        content {
            FlareContentScope(builders = mapOf("custom" to pluginCard)) {
                Column {
                    MessageBubble(message = pluginMessage(sender = "me", status = FlareMessageDeliveryStatus.Failed), currentUserId = "me",
                        onResend = { resent++ })
                    MessageBubble(
                        message = FlareMessageData(id = "t1", senderId = "me", senderName = "我", content = FlareTextContent("hello"),
                            timeLabel = "09:31", status = FlareMessageDeliveryStatus.Failed),
                        currentUserId = "me", onResend = { resent++ },
                    )
                }
            }
        }
        val text = compose.onNodeWithContentDescription(zh.messageSendFailedRetry, useUnmergedTree = true)
        val (w, h) = text.size()
        assertTrue("text key $w × $h", w >= FlareSizes.touchTarget && h >= FlareSizes.touchTarget)
        text.performClick()
        val glyph = compose.onNodeWithContentDescription("${zh.messageFailed}, ${zh.retry}", useUnmergedTree = true)
        val (gw, gh) = glyph.size()
        assertTrue("glyph key $gw × $gh", gw >= FlareSizes.touchTarget && gh >= FlareSizes.touchTarget)
        glyph.performClick()
        compose.runOnIdle { assertEquals(2, resent) }
    }

    /** How many pixels of [tag]'s capture are [color], within [tolerance] per channel. */
    private fun count(tag: String, color: androidx.compose.ui.graphics.Color, tolerance: Int = 2): Int {
        val bitmap = compose.onNodeWithTag(tag).captureToImage().asAndroidBitmap()
            .copy(android.graphics.Bitmap.Config.ARGB_8888, false)
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        val target = color.toArgb()
        fun channel(argb: Int, shift: Int) = (argb shr shift) and 0xFF
        return pixels.count { p -> listOf(16, 8, 0).all { kotlin.math.abs(channel(p, it) - channel(target, it)) <= tolerance } }
    }

    /**
     * A failed outgoing bubble is the failure surface (spec/message-surface-vectors.json `palette`): the failure fill
     * with its text in the failure foreground, never the outgoing fill with white text; a sent one keeps the outgoing
     * palette.
     */
    @Test fun aFailedBubbleIsTheFailureSurface() {
        val colors = FlareColors.Light
        fun text(id: String, status: FlareMessageDeliveryStatus) = FlareMessageData(
            id = id, senderId = "me", senderName = "我", content = FlareTextContent("MMMMMMMMMMMM WWWWWWWWWW"),
            timeLabel = "09:31", status = status,
        )
        compose.setContent {
            FlareThemeProvider(colors = colors) {
                Column(Modifier.width(400.dp)) {
                    Box(Modifier.testTag("failed")) { MessageBubble(message = text("f", FlareMessageDeliveryStatus.Failed), currentUserId = "me") }
                    Box(Modifier.testTag("sent")) { MessageBubble(message = text("s", FlareMessageDeliveryStatus.Sent), currentUserId = "me") }
                }
            }
        }
        compose.waitForIdle()
        assertTrue("the failure fill", count("failed", colors.messageFailedBackground) > 2_000)
        assertEquals("no outgoing fill on a failed bubble", 0, count("failed", colors.messageOutgoingBackground))
        assertTrue("its text in the failure foreground", count("failed", colors.messageFailedForeground, tolerance = 24) > 50)
        assertTrue("its red edge", count("failed", colors.messageFailedBorder, tolerance = 6) > 100)
        assertTrue("a sent bubble keeps the outgoing fill", count("sent", colors.messageOutgoingBackground) > 2_000)
        assertEquals("and no failure fill", 0, count("sent", colors.messageFailedBackground))
    }

    /** C3: a group's own message shows "N unread" as a key that opens the read list with the message's core id. */
    @Test fun theReadSummaryOpensTheReadList() {
        val opened = mutableListOf<String>()
        content {
            MessageBubble(
                message = FlareMessageData(id = "c1", serverId = "s1", senderId = "me", senderName = "我", content = FlareTextContent("开会了"),
                    timeLabel = "10:00", readSummary = FlareMessageReadSummary(2, 3, 5)),
                currentUserId = "me", conversationKind = FlareConversationKind.Group, onReadReceiptOpen = { opened += it },
            )
        }
        val key = compose.onNodeWithContentDescription("3 人未读", useUnmergedTree = true)
        val (w, h) = key.size()
        assertTrue("summary key $w × $h", w >= FlareSizes.touchTarget && h >= FlareSizes.touchTarget)
        key.performClick()
        compose.runOnIdle { assertEquals(listOf("s1"), opened) }
        // No check glyph next to the summary.
        compose.onAllNodesWithContentDescription(zh.messageSent, useUnmergedTree = true).assertCountEquals(0)
    }

    /** menuActions: the ⋯ key opens the kit menu, whose item runs the action; embedded, they are keys. */
    @Test fun theCardsMenuRunsItsActions() {
        val actions = mutableListOf<String>()
        val embedded = mutableStateOf(false)
        content { PluginView(view = poll, embedded = embedded.value, onAction = { id, _ -> actions += id }) }
        compose.onNodeWithContentDescription(zh.pluginViewMore).performClick()
        compose.onNodeWithText("结束投票").performClick()
        compose.runOnIdle { assertEquals(listOf("close"), actions) }
        compose.runOnIdle { embedded.value = true }
        compose.onAllNodesWithContentDescription(zh.pluginViewMore).assertCountEquals(0)
        compose.onNodeWithText("结束投票").performClick()
        compose.runOnIdle { assertEquals(listOf("close", "close"), actions) }
    }

    /** C4: a switch between a bubble and a card ends the run, so each run opens with its own avatar. */
    @Test fun groupingBreaksAtACard() {
        val base = System.currentTimeMillis() - 600_000
        fun text(id: String, at: Long) = FlareMessageData(id = id, senderId = "u1", senderName = "Ann", content = FlareTextContent(id), sentAtMs = at)
        content {
            FlareContentScope(builders = mapOf("custom" to pluginCard)) {
                MessageList(
                    messages = listOf(text("a1", base), pluginMessage("h2", at = base + 60_000), pluginMessage("h3", at = base + 120_000), text("h4", base + 180_000)),
                    currentUserId = "me", conversationKind = FlareConversationKind.Group, onAvatarTap = {},
                )
            }
        }
        compose.onAllNodesWithContentDescription("Ann", useUnmergedTree = true).assertCountEquals(3)
    }

    /** unbound_copy: the copy keeps its content, acts on nothing and says why. */
    @Test fun aReadOnlyCopyActsOnNothing() {
        val actions = mutableListOf<String>()
        content { PluginView(view = poll.copy(unavailableReason = PluginUnavailableReason.UnboundCopy), onAction = { id, _ -> actions += id }) }
        compose.onNodeWithText(zh.pluginViewUnavailableUnboundCopy).assertExists()
        compose.onNodeWithText("爬山").assertIsNotEnabled()
        compose.onAllNodesWithContentDescription(zh.pluginViewMore).assertCountEquals(0)
        compose.runOnIdle { assertTrue(actions.isEmpty()) }
    }

    private val requested = mutableListOf<Any>()

    @After fun resetImageLoader() {
        Coil.reset()
    }

    /** The bubble's avatar loads the sender's URL (it drew initials only before). */
    @Test fun theBubbleAvatarLoadsItsUrl() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        Coil.setImageLoader(
            ImageLoader.Builder(context).components {
                add(object : Interceptor {
                    override suspend fun intercept(chain: Interceptor.Chain): ImageResult {
                        synchronized(requested) { requested += chain.request.data }
                        return ErrorResult(null, chain.request, IllegalStateException("offline"))
                    }
                })
            }.build(),
        )
        val taps = mutableListOf<String>()
        content {
            MessageBubble(
                message = FlareMessageData(id = "m1", senderId = "u1", senderName = "Ann", content = FlareTextContent("hi"),
                    senderAvatarUrl = "https://example.com/ann.png"),
                currentUserId = "me", rowPresentation = MessageRowPresentation(showAvatar = true, reserveAvatarSpace = true),
                onAvatarTap = { taps += it.senderId },
            )
        }
        compose.waitForIdle()
        compose.runOnIdle { assertTrue("requested $requested", synchronized(requested) { "https://example.com/ann.png" in requested }) }
        compose.onNodeWithContentDescription("Ann", useUnmergedTree = true).performClick()
        compose.runOnIdle { assertEquals(listOf("u1"), taps) }
    }

    /** Multi-select: a tap on the card's content selects the row; the card itself does not act. */
    @Test fun multiSelectMakesTheContentInert() {
        val toggled = mutableListOf<String>()
        val actions = mutableListOf<String>()
        val card: FlareContentBuilder = { _, ctx ->
            Box(Modifier.testTag("card")) { PluginView(view = poll, onAction = if (ctx.selectionMode) null else ({ id, _ -> actions += id })) }
        }
        content {
            FlareContentScope(builders = mapOf("custom" to card)) {
                MessageBubble(message = pluginMessage(), currentUserId = "me", multiSelectMode = true, onToggleSelect = { toggled += it })
            }
        }
        // The row's name stands for its content in multi-select; a touch on the card lands on the row.
        compose.onNode(hasContentDescription("Ann", substring = true)).performTouchInput { click(center) }
        compose.runOnIdle {
            assertEquals(listOf("p1"), toggled)
            assertTrue(actions.isEmpty())
        }
    }
}
