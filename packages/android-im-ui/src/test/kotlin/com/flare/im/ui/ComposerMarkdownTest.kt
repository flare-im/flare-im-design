package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** The format strip edits the text as Vue `useMarkdownShortcuts` does: wrap or prefix the selection, sample when empty. */
class ComposerMarkdownTest {
    @Test fun aSelectionIsWrappedAndAnEmptyOneGetsTheSampleSelected() {
        assertEquals(ComposerMarkdownEdit("a **bc** d", 4, 6), composerWrapSelection("a bc d", 2, 4, "**", "**", "粗体"))
        assertEquals(ComposerMarkdownEdit("x**粗体**", 3, 5), composerWrapSelection("x", 1, 1, "**", "**", "粗体"))
    }

    @Test fun aLineMarkerGoesToTheStartOfTheSelectedLine() {
        assertEquals(ComposerMarkdownEdit("one\n> two", 7, 9), composerPrefixLine("one\ntwo", 5, 7, "> "))
        assertEquals(ComposerMarkdownEdit("## hi", 3, 3), composerPrefixLine("hi", 0, 0, "## "))
    }

    @Test fun aDividerReplacesTheSelection() {
        assertEquals(ComposerMarkdownEdit("a\n---\nc", 6, 6), composerInsertAtSelection("abc", 1, 2, "\n---\n"))
    }
}
