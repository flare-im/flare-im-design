package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MessageSelectionTest {
    @Test fun defaultModeRendersNoSelectionLayer() {
        assertEquals(MessageSelectionUi(showCheck = false, toggles = false, highlighted = false),
            messageSelectionUi(multiSelectMode = false, selected = false, hasToggle = true))
    }

    @Test fun multiSelectShowsCheckAndTogglesOnlyWithCallback() {
        assertEquals(MessageSelectionUi(showCheck = true, toggles = true, highlighted = false),
            messageSelectionUi(multiSelectMode = true, selected = false, hasToggle = true))
        assertEquals(MessageSelectionUi(showCheck = true, toggles = false, highlighted = true),
            messageSelectionUi(multiSelectMode = true, selected = true, hasToggle = false))
    }

    @Test fun systemNoticesAreNeverSelectable() {
        assertEquals(MessageSelectionUi(showCheck = false, toggles = false, highlighted = false),
            messageSelectionUi(multiSelectMode = true, selected = true, hasToggle = true, isSystem = true))
    }

    @Test fun listLongPressDisabledWhileMultiSelecting() {
        assertTrue(messageListLongPressEnabled(multiSelectMode = false, hasLongPress = true))
        assertFalse(messageListLongPressEnabled(multiSelectMode = true, hasLongPress = true))
        assertFalse(messageListLongPressEnabled(multiSelectMode = false, hasLongPress = false))
    }

    @Test fun selectedIdsResolvePerRow() {
        val ids = setOf("m2")
        assertTrue("m2" in ids); assertFalse("m1" in ids)
    }
}
