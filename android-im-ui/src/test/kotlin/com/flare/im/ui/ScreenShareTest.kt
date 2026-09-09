package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ScreenShareTest {
    private fun shown(state: FlareScreenShareState, busy: Boolean = false, all: Boolean = true): List<FlareScreenShareAction> {
        val actions = screenShareActions(state, hasStart = all, hasStop = all, hasCancel = all, busy = busy)
        return FlareScreenShareAction.values().filter { it in actions }
    }

    private val visible = mapOf(
        FlareScreenShareState.Idle to listOf(FlareScreenShareAction.Start),
        FlareScreenShareState.Requesting to listOf(FlareScreenShareAction.Cancel),
        FlareScreenShareState.Sharing to listOf(FlareScreenShareAction.Stop),
        FlareScreenShareState.Viewing to emptyList(),
        FlareScreenShareState.Unavailable to emptyList(),
    )

    @Test fun everyStateExposesOnlyStateAppropriateActions() {
        for (state in FlareScreenShareState.values()) {
            assertEquals(visible[state], shown(state), "$state")
        }
    }

    @Test fun busyKeepsButtonsVisibleButDisabled() {
        for (state in FlareScreenShareState.values()) {
            assertEquals(visible[state], shown(state, busy = true), "$state busy")
            assertFalse(screenShareActions(state, hasStart = true, hasStop = true, hasCancel = true, busy = true).enabled, "$state busy")
            assertTrue(screenShareActions(state, hasStart = true, hasStop = true, hasCancel = true).enabled, "$state idle")
        }
    }

    @Test fun missingHostCallbacksHideEveryAction() {
        for (state in FlareScreenShareState.values()) {
            assertEquals(emptyList(), shown(state, all = false), "$state no callbacks")
        }
    }

    @Test fun viewerCannotStopAndUnavailableOffersNothing() {
        val viewing = screenShareActions(FlareScreenShareState.Viewing, hasStart = true, hasStop = true, hasCancel = true)
        assertFalse(viewing.stop)
        assertFalse(viewing.start)
        assertTrue(screenShareActions(FlareScreenShareState.Unavailable, hasStart = true, hasStop = true, hasCancel = true).isEmpty())
        assertFalse(screenShareActions(FlareScreenShareState.Sharing, hasStart = true, hasStop = true, hasCancel = true).start)
        for (state in FlareScreenShareState.values()) {
            assertEquals(
                state == FlareScreenShareState.Requesting,
                screenShareActions(state, hasStart = true, hasStop = true, hasCancel = true).cancel,
                "$state cancel",
            )
        }
    }

    @Test fun toneAndIconPerState() {
        assertEquals(FlareStatusTone.Neutral, screenShareTone(FlareScreenShareState.Idle))
        assertEquals(FlareStatusTone.Warning, screenShareTone(FlareScreenShareState.Requesting))
        assertEquals(FlareStatusTone.Success, screenShareTone(FlareScreenShareState.Sharing))
        assertEquals(FlareStatusTone.Info, screenShareTone(FlareScreenShareState.Viewing))
        assertEquals(FlareStatusTone.Neutral, screenShareTone(FlareScreenShareState.Unavailable))
        assertEquals(
            listOf("devices", "refresh", "video", "eye", "block"),
            FlareScreenShareState.values().map(::screenShareIconName),
        )
        for (state in FlareScreenShareState.values()) {
            assertTrue(screenShareIconName(state) in flareIconNames, "${screenShareIconName(state)} is a kit icon")
        }
    }
}
