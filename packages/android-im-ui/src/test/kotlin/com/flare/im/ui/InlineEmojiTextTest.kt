package com.flare.im.ui

import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame
import kotlin.test.assertTrue

/**
 * `[key]` emoji-pack tokens inside a plain text body (Vue `PlainTextEmojiRich`): a bundled key draws its
 * emoji inline, an unknown key stays the bracket text, and the token keeps its characters so mention runs
 * and links do not move.
 */
class InlineEmojiTextTest {
    private val bundled = setOf("smile", "cry_loudly")

    @Test fun onlyBundledKeysBecomeInlineEmoji() {
        val runs = flareInlineEmojiRuns("[smile] 走了 [not_a_key] [cry_loudly]") { it in bundled }
        assertEquals(listOf("smile", "cry_loudly"), runs.map { it.key })
        assertEquals(0 to 7, runs[0].start to runs[0].end)
        // The run covers exactly the token, brackets included.
        val text = "[smile] 走了 [not_a_key] [cry_loudly]"
        assertEquals("[smile]", text.substring(runs[0].start, runs[0].end))
        assertEquals("[cry_loudly]", text.substring(runs[1].start, runs[1].end))
    }

    @Test fun textWithoutATokenNeverAsksForTheCatalog() {
        assertTrue(flareMayHoldEmojiTokens("收到 [smile]"))
        assertEquals(false, flareMayHoldEmojiTokens("收到"))
        // Not a pack token: uppercase, spaces and non-Latin keys are left alone.
        assertEquals(false, flareMayHoldEmojiTokens("[Smile]"))
        assertEquals(false, flareMayHoldEmojiTokens("[微笑]"))
    }

    @Test fun theTokenKeepsItsCharactersSoMentionsAndLinksDoNotMove() {
        val text = "@陈默 [smile] 看这个"
        val mention = SpanStyle(fontWeight = FontWeight.Medium)
        val styled = buildAnnotatedString {
            withStyle(mention) { append("@陈默") }
            append(text.substring(3))
        }
        val runs = flareInlineEmojiRuns(text) { it in bundled }
        val inline = withInlineEmoji(styled, runs)
        // Same characters, same length: the mention run still covers the name and nothing shifted.
        assertEquals(text, inline.text)
        assertEquals(styled.spanStyles.single().start to styled.spanStyles.single().end, inline.spanStyles.single().start to inline.spanStyles.single().end)
        // The token carries the inline-emoji placeholder for its key.
        val placeholder = inline.getStringAnnotations(0, inline.length).single { it.item == flareInlineEmojiId("smile") }
        assertEquals(4 to 11, placeholder.start to placeholder.end)
        assertEquals("[smile]", text.substring(placeholder.start, placeholder.end))
    }

    @Test fun textWithNoRunIsLeftExactlyAsItWas() {
        val plain = AnnotatedString("收到 [not_a_key]")
        assertSame(plain, withInlineEmoji(plain, emptyList()))
    }
}
