package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Core mention entities (code point offsets) become text-body spans (UTF-16 indices) and their looks. */
class TextMentionsTest {
    private fun FlareTextMentionSpan.text(of: String) = of.substring(start, start + length)

    @Test fun mapsCodePointOffsetsAndMarksTheReaderAndEveryone() {
        val text = "@林夏 看一下 @所有人"
        val spans = textMentionSpans(
            text,
            listOf(
                FlareMentionEntity(FlareMentionEntity.USER, start = 0, length = 3, userId = "u_me"),
                FlareMentionEntity(FlareMentionEntity.ALL, start = 8, length = 4),
            ),
            currentUserId = "u_me",
        )
        assertEquals(listOf(FlareTextMentionSpan(0, 3, self = true), FlareTextMentionSpan(8, 4, all = true)), spans)
        assertEquals(listOf("@林夏", "@所有人"), spans.map { it.text(text) })
    }

    @Test fun anEmojiBeforeAMentionMovesItByCodePointsNotUtf16Units() {
        // 👍 is one code point in two UTF-16 units.
        val thumbs = "👍 @周屿 好"
        val one = textMentionSpans(thumbs, listOf(FlareMentionEntity(FlareMentionEntity.USER, start = 2, length = 3, userId = "u_zhou")), "u_me")
        assertEquals("@周屿", one.single().text(thumbs))
        assertEquals(3, one.single().start)
        assertEquals(false, one.single().self)

        // A family emoji is five code points (three people joined by two ZWJ) in eight UTF-16 units.
        val family = "👨‍👩‍👧 @Ann"
        val two = textMentionSpans(family, listOf(FlareMentionEntity(FlareMentionEntity.USER, start = 6, length = 4, userId = "ann")), "ann")
        assertEquals("@Ann", two.single().text(family))
        assertEquals(9, two.single().start)
        assertTrue(two.single().self)
    }

    @Test fun invalidSpansAreIgnored() {
        val text = "hello @a"
        fun spans(vararg mentions: FlareMentionEntity) = textMentionSpans(text, mentions.toList(), "a")
        // Not on an "@": dropped rather than highlighting the wrong words.
        assertEquals(emptyList(), spans(FlareMentionEntity(FlareMentionEntity.USER, start = 0, length = 3, userId = "a")))
        // Negative start, too short, or past the code point count.
        assertEquals(emptyList(), spans(FlareMentionEntity(FlareMentionEntity.USER, start = -1, length = 2, userId = "a")))
        assertEquals(emptyList(), spans(FlareMentionEntity(FlareMentionEntity.USER, start = 6, length = 1, userId = "a")))
        assertEquals(emptyList(), spans(FlareMentionEntity(FlareMentionEntity.USER, start = 6, length = 3, userId = "a")))
        assertEquals(emptyList(), spans(FlareMentionEntity(FlareMentionEntity.USER, start = Int.MAX_VALUE, length = Int.MAX_VALUE)))
        assertEquals(emptyList(), textMentionSpans("", listOf(FlareMentionEntity(FlareMentionEntity.ALL, start = 0, length = 2))))
        // Host-built spans outside the text never reach the renderer.
        assertEquals(listOf(FlareTextMentionSpan(6, 2)), drawableMentionSpans(text, listOf(FlareTextMentionSpan(6, 2), FlareTextMentionSpan(7, 5), FlareTextMentionSpan(-1, 2))))
    }

    @Test fun overlappingSpansKeepTheFirstInTextOrder() {
        val text = "@Ann @Bob"
        val spans = textMentionSpans(
            text,
            listOf(
                FlareMentionEntity(FlareMentionEntity.USER, start = 5, length = 4, userId = "bob"),
                FlareMentionEntity(FlareMentionEntity.USER, start = 0, length = 4, userId = "ann"),
                FlareMentionEntity(FlareMentionEntity.USER, start = 0, length = 9, userId = "both"),
                FlareMentionEntity(FlareMentionEntity.MULTI, start = 5, length = 4, userIds = listOf("x", "me")),
            ),
            currentUserId = "me",
        )
        assertEquals(listOf("@Ann", "@Bob"), spans.map { it.text(text) })
        assertEquals(listOf(false, false), spans.map { it.self })
    }

    @Test fun aMultiMentionMarksTheReaderAndNoReaderMarksNobody() {
        val text = "@设计组 周会"
        val multi = listOf(FlareMentionEntity(FlareMentionEntity.MULTI, start = 0, length = 4, userIds = listOf("u1", "u_me")))
        assertTrue(textMentionSpans(text, multi, "u_me").single().self)
        assertEquals(false, textMentionSpans(text, multi, null).single().self)
        assertEquals(false, textMentionSpans(text, multi, "").single().self)
    }

    @Test fun onlyTheReaderAndEveryoneGetTheGroundAndNeverInAnOutgoingBubble() {
        val spans = listOf(FlareTextMentionSpan(0, 3), FlareTextMentionSpan(4, 3, self = true), FlareTextMentionSpan(8, 4, all = true))
        assertEquals(spans.drop(1), mentionGrounds(spans, self = false))
        assertEquals(emptyList(), mentionGrounds(spans, self = true))
    }

    @Test fun theTextContentCarriesSpans() {
        val content = FlareTextContent("@Ann hi", mentions = listOf(FlareTextMentionSpan(0, 4)))
        assertEquals("text", content.type)
        assertEquals(emptyList(), FlareTextContent("plain").mentions)
    }
}
