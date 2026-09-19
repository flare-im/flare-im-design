package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** The kit's own rules around the shared summary table: what a reply target is built from. */
class MessagePreviewTest {
    private val strings = FlareStrings()

    private fun message(content: FlareMessageContent, id: String = "m1", sender: String = "Ivy") =
        FlareMessageData(id = id, senderId = "u1", senderName = sender, content = content)

    @Test fun replyTargetTakesTheSenderTheSummaryAndTheCoreId() {
        val target = flareReplyTarget(message(FlareTextContent("明天见"), id = "row-9"), strings)
        assertEquals("Ivy", target.senderName)
        assertEquals("明天见", target.summary)
        // No core id of its own: the row id is the only id this message has to be named by.
        assertEquals("row-9", target.messageId)
    }

    /**
     * A quote names its original by the core id, so replying to a message this device sent quotes the id
     * the core knows it by — not the client id its row is drawn with, which no other client could resolve.
     */
    @Test fun replyTargetNamesTheMessageByItsCoreIdWhenItHasOne() {
        val sent = message(FlareTextContent("我发的"), id = "cli-9").copy(serverId = "srv-9")
        assertEquals("srv-9", flareReplyTarget(sent, strings).messageId)
    }

    /** A body with nothing to read still names a message: the strip and the quote are never blank. */
    @Test fun replyTargetNeverHasABlankSummary() {
        assertEquals(strings.previewMessage, flareReplyTarget(message(FlareTextContent("   ")), strings).summary)
        assertEquals("", flareMessagePreviewText(FlareTextContent("   "), strings))
    }

    @Test fun hostWordsReplaceTheDefaults() {
        val en = FlareStrings { previewImage = "[Image]" }
        assertEquals("[图片]", flareMessagePreviewText(FlareImageContent(url = "u"), strings))
        assertEquals("[Image]", flareMessagePreviewText(FlareImageContent(url = "u"), en))
    }

    @Test fun aBodyWithoutARendererReadsAsItsLabelThenItsType() {
        assertEquals("上一条消息", flareMessagePreviewText(FlareGenericContent("quote", "上一条消息"), strings))
        assertEquals(strings.previewQuote, flareMessagePreviewText(FlareGenericContent("quote", ""), strings))
        assertEquals(strings.previewRichText, flareMessagePreviewText(FlareGenericContent("rich_text", ""), strings))
        assertEquals(strings.previewUnknown, flareMessagePreviewText(FlareGenericContent("no_such_type", ""), strings))
    }

    /** A single forwarded message is not a count; an album says how many even at one. */
    @Test fun countedBodiesReadTheirCountOnlyWhenThereIsOne() {
        assertEquals(strings.previewForward, flareMessagePreviewText(FlareGenericContent("forward", "", itemCount = 1), strings))
        assertEquals("[转发] 2 条消息", flareMessagePreviewText(FlareGenericContent("forward", "", itemCount = 2), strings))
        assertEquals(strings.previewImageGroup, flareMessagePreviewText(FlareGenericContent("image_group", ""), strings))
        assertEquals("[多图] 1 张", flareMessagePreviewText(FlareGenericContent("image_group", "", itemCount = 1), strings))
    }

    @Test fun aSystemLineReadsItsOwnWordsFirst() {
        assertEquals("群名称已更新", flareMessagePreviewText(FlareNotificationContent("群名称已更新"), strings))
        assertEquals(strings.previewSystem, flareMessagePreviewText(FlareNotificationContent(""), strings))
        assertEquals(strings.previewNotification, flareMessagePreviewText(FlareGenericContent("notification", ""), strings))
    }

    @Test fun nothingSummarizesToNothing() {
        assertEquals("", flareMessagePreviewText(null, strings))
        assertEquals(strings.previewMessage, flareMessageReplySummary(null, strings))
    }
}
