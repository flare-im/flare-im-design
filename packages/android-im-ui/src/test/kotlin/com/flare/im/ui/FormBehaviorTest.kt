package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * DoD 20 — the vector table of spec/form-keyboard-contract.json. The four
 * platforms run the same ids; tooling/check-form-keyboard.mjs fails when one of
 * them stops exercising a vector.
 */
class FormBehaviorTest {
    private data class Vector(
        val id: String,
        val key: String,
        val intent: FlareFormKeyboardIntent,
        val shift: Boolean = false,
        val composing: Boolean = false,
        val popupOpen: Boolean = false,
        val submitOnEnter: Boolean = false,
    )

    private val vectors = listOf(
        Vector("enter.submits", "Enter", FlareFormKeyboardIntent.Submit, submitOnEnter = true),
        Vector("enter.withoutSubmitMode", "Enter", FlareFormKeyboardIntent.None),
        Vector("enter.composing", "Enter", FlareFormKeyboardIntent.None, composing = true, submitOnEnter = true),
        Vector("tab.forward", "Tab", FlareFormKeyboardIntent.TabForward),
        Vector("tab.backward", "Tab", FlareFormKeyboardIntent.TabBackward, shift = true),
        Vector("tab.composing", "Tab", FlareFormKeyboardIntent.None, composing = true),
        Vector("escape.closesPopup", "Escape", FlareFormKeyboardIntent.ClosePopup, popupOpen = true),
        Vector("escape.withoutPopup", "Escape", FlareFormKeyboardIntent.None),
        Vector("escape.composing", "Escape", FlareFormKeyboardIntent.None, composing = true, popupOpen = true),
        Vector("arrowDown.nextOption", "ArrowDown", FlareFormKeyboardIntent.NextOption, popupOpen = true),
        Vector("arrowUp.previousOption", "ArrowUp", FlareFormKeyboardIntent.PreviousOption, popupOpen = true),
        Vector("arrowDown.composing", "ArrowDown", FlareFormKeyboardIntent.None, composing = true, popupOpen = true),
        Vector("arrowDown.withoutPopup", "ArrowDown", FlareFormKeyboardIntent.None),
        Vector("home.firstOption", "Home", FlareFormKeyboardIntent.FirstOption, popupOpen = true),
        Vector("end.lastOption", "End", FlareFormKeyboardIntent.LastOption, popupOpen = true),
        Vector("pageDown.pageForward", "PageDown", FlareFormKeyboardIntent.PageForward, popupOpen = true),
        Vector("pageUp.pageBackward", "PageUp", FlareFormKeyboardIntent.PageBackward, popupOpen = true),
        Vector("unknownKey", "F13", FlareFormKeyboardIntent.None, popupOpen = true),
    )

    @Test fun everyVectorResolvesToItsIntent() {
        for (v in vectors) {
            assertEquals(
                v.intent,
                resolveFormKeyboardIntent(v.key, shift = v.shift, composing = v.composing, popupOpen = v.popupOpen, submitOnEnter = v.submitOnEnter),
                v.id,
            )
        }
    }

    @Test fun theImeGetsEveryKeyWhileACompositionIsOpen() {
        // The guard is unconditional on purpose: a composing Tab must not move
        // focus out from under a half-typed word, and Escape belongs to the IME.
        for (key in listOf("Enter", "Tab", "Escape", "ArrowDown", "ArrowUp", "Home", "End", "PageDown", "PageUp")) {
            assertEquals(
                FlareFormKeyboardIntent.None,
                resolveFormKeyboardIntent(key, shift = true, composing = true, popupOpen = true, submitOnEnter = true),
                key,
            )
        }
    }

    @Test fun aCappedFieldClampsInsteadOfDroppingTheUpdate() {
        // Dropping left the IME composing against a value the state no longer
        // held, and CJK input lost characters at the boundary.
        assertEquals("晚点同步", composerTextWithinLimit("晚点同步", null))
        assertEquals("晚点同步", composerTextWithinLimit("晚点同步", 8))
        assertEquals("晚点", composerTextWithinLimit("晚点同步", 2))
        assertEquals("", composerTextWithinLimit("晚点同步", 0))
    }

    @Test fun theKeyNameIsCaseInsensitive() {
        assertEquals(FlareFormKeyboardIntent.Submit, resolveFormKeyboardIntent("enter", submitOnEnter = true))
        assertEquals(FlareFormKeyboardIntent.NextOption, resolveFormKeyboardIntent("ARROWDOWN", popupOpen = true))
    }
}
