package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Toast presenter queue: the same limit, durations and dismissal rules as the web presenter. */
class FlareToastStateTest {
    @Test fun durationsFollowTheRenderedTone() {
        assertEquals(4_000, flareToastDurationMs(ToastVariant.Info, null, null))
        assertEquals(4_000, flareToastDurationMs(ToastVariant.Success, FlareStatusTone.Success, null))
        assertEquals(6_000, flareToastDurationMs(ToastVariant.Error, null, null))
        assertEquals(6_000, flareToastDurationMs(ToastVariant.Info, FlareStatusTone.Danger, null))
        // An explicit tone outranks the variant, and a loading toast is never danger.
        assertEquals(4_000, flareToastDurationMs(ToastVariant.Error, FlareStatusTone.Success, null))
        assertEquals(4_000, flareToastDurationMs(ToastVariant.Loading, FlareStatusTone.Danger, null))
        // A host duration wins; 0 (or less) keeps the toast until it is dismissed.
        assertEquals(1_500, flareToastDurationMs(ToastVariant.Error, null, 1_500))
        assertEquals(0, flareToastDurationMs(ToastVariant.Info, null, 0))
        assertEquals(0, flareToastDurationMs(ToastVariant.Info, null, -5))
    }

    @Test fun theStackKeepsTheNewestThree() {
        val state = FlareToastState()
        repeat(5) { state.show("toast $it") }
        assertEquals(FLARE_TOAST_LIMIT, state.entries.size)
        assertEquals(listOf("toast 2", "toast 3", "toast 4"), state.entries.map { it.message })
    }

    @Test fun showReturnsAnEarlyDismissForThatToast() {
        val state = FlareToastState()
        val dismissFirst = state.show("first")
        state.show("second", tone = FlareStatusTone.Danger)
        dismissFirst()
        assertEquals(listOf("second"), state.entries.map { it.message })
        assertEquals(6_000, state.entries.single().durationMs)
        dismissFirst()
        assertEquals(1, state.entries.size)
    }

    @Test fun runningTheActionDismissesTheToastAndRunsOnce() {
        val state = FlareToastState()
        var undone = 0
        state.show("Deleted", actionLabel = "Undo", onAction = { undone++ }, durationMs = 0)
        val entry = state.entries.single()
        assertEquals("Undo", entry.actionLabel)
        assertEquals(0, entry.durationMs)
        state.runAction(entry.id)
        state.runAction(entry.id)
        assertEquals(1, undone)
        assertTrue(state.entries.isEmpty())
    }

    @Test fun aPushedOutToastDropsItsAction() {
        val state = FlareToastState()
        var ran = false
        state.show("old", actionLabel = "Open", onAction = { ran = true })
        val oldId = state.entries.single().id
        repeat(FLARE_TOAST_LIMIT) { state.show("new $it") }
        state.runAction(oldId)
        assertFalse(ran)
        assertEquals(FLARE_TOAST_LIMIT, state.entries.size)
    }
}
