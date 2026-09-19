package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Mentioning from the composer: where "@" opens the picker, what a pick writes, and the picker's rows and keys. */
class ComposerMentionsTest {
    private val chen = MentionCandidate("u_chen", "陈默")
    private val chenxi = MentionCandidate("u_chenxi", "陈曦")
    private val xu = MentionCandidate("u_xu", "徐知远", detail = "设计")

    @Test fun anAtTypedAtTheStartOfAWordOpensThePickerButNotInsideAWord() {
        assertEquals(0, composerTypedMentionAt("", "@"))
        assertEquals(3, composerTypedMentionAt("你好 ", "你好 @"))
        assertEquals(3, composerTypedMentionAt("hi  there", "hi @ there"))
        // An email address, a paste of several characters and a deletion are not a typed mention.
        assertNull(composerTypedMentionAt("me", "me@"))
        assertNull(composerTypedMentionAt("", "@陈"))
        assertNull(composerTypedMentionAt("@", ""))
    }

    @Test fun aPickReplacesTheTypedAtOrGoesAtTheEnd() {
        assertEquals("你好 @陈默 ", composerTextWithMention("你好 @", "陈默", typedAt = 3))
        assertEquals("@陈默 看这里", composerTextWithMention("@看这里", "陈默", typedAt = 0))
        // Opened from the mention key, or the typed "@" is gone: the mention goes at the end.
        assertEquals("你好 @陈默 ", composerTextWithMention("你好", "陈默", typedAt = null))
        assertEquals("你好 @陈默 ", composerTextWithMention("你好 ", "陈默", typedAt = 5))
    }

    @Test fun thePickerFiltersByNameOrDetailWithEveryoneFirst() {
        val candidates = listOf(xu, chen, chenxi)
        val everyone = FlareStrings().everyone
        assertEquals(listOf(everyone, "徐知远", "陈默", "陈曦"), mentionPickerResults(candidates, true, everyone, "").map { it.name })
        assertEquals(listOf("陈默", "陈曦"), mentionPickerResults(candidates, true, everyone, " 陈 ").map { it.name })
        assertEquals(listOf("徐知远"), mentionPickerResults(candidates, false, everyone, "设计").map { it.name })
        assertEquals(listOf(everyone), mentionPickerResults(candidates, true, everyone, "所有").map { it.name })
    }

    @Test fun pickingEveryoneWritesTheWordTheCoreReadsAsMentionAll() {
        // The core parses only all / everyone / 全员 / 所有人 as a mention of everyone (content/mention.rs).
        val everyone = mentionPickerResults(listOf(xu), allowEveryone = true, everyoneName = FlareStrings().everyone, query = "").first()
        assertEquals(true, everyone.isEveryone)
        assertEquals("@所有人 ", composerTextWithMention("", everyone.name, typedAt = 0))
        assertEquals("大家看 @所有人 ", composerTextWithMention("大家看 @", everyone.name, typedAt = 4))
    }

    @Test fun thePickerKeysMoveWrapPickAndCloseButIgnoreAnImeCommit() {
        assertEquals(MentionPickerAction.Highlight(1), mentionPickerAction(MentionPickerInput.Down, false, count = 2, active = 0))
        assertEquals(MentionPickerAction.Highlight(0), mentionPickerAction(MentionPickerInput.Down, false, count = 2, active = 1))
        assertEquals(MentionPickerAction.Highlight(1), mentionPickerAction(MentionPickerInput.Up, false, count = 2, active = 0))
        assertEquals(MentionPickerAction.Pick(1), mentionPickerAction(MentionPickerInput.Enter, false, count = 2, active = 1))
        assertNull(mentionPickerAction(MentionPickerInput.Enter, composing = true, count = 2, active = 0))
        assertNull(mentionPickerAction(MentionPickerInput.Enter, false, count = 0, active = 0))
        assertEquals(MentionPickerAction.Close, mentionPickerAction(MentionPickerInput.Escape, composing = true, count = 0, active = 0))
    }
}
