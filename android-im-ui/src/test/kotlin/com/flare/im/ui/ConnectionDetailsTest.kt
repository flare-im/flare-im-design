package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class ConnectionDetailsTest {
    private fun actions(state: FlareConnectionState, busy: Boolean = false, all: Boolean = true) =
        availableConnectionActions(state, hasReconnect = all, hasReauth = all, hasDiagnostics = all, busy = busy)

    @Test fun everyStateExposesOnlyStateAppropriateActions() {
        val c = FlareConnectionAction.CopyDiagnostics
        assertEquals(listOf(c), actions(FlareConnectionState.Connected))
        assertEquals(listOf(c), actions(FlareConnectionState.Connecting))
        assertEquals(listOf(FlareConnectionAction.Reconnect, c), actions(FlareConnectionState.Reconnecting))
        assertEquals(listOf(FlareConnectionAction.Reconnect, c), actions(FlareConnectionState.Offline))
        assertEquals(listOf(FlareConnectionAction.Reauth, c), actions(FlareConnectionState.SessionExpired))
        assertEquals(listOf(FlareConnectionAction.Reauth, c), actions(FlareConnectionState.Kicked))
        assertEquals(emptyList(), actions(FlareConnectionState.SdkUnready))
    }

    @Test fun busyOrMissingCapabilitiesExposeNothing() {
        for (state in FlareConnectionState.values()) {
            assertEquals(emptyList(), actions(state, busy = true), "$state busy")
            assertEquals(emptyList(), actions(state, all = false), "$state no capabilities")
        }
    }

    @Test fun reconnectAndReauthNeverCross() {
        assertFalse(FlareConnectionAction.Reconnect in actions(FlareConnectionState.Connected))
        assertFalse(FlareConnectionAction.Reconnect in actions(FlareConnectionState.Connecting))
        assertFalse(FlareConnectionAction.Reauth in actions(FlareConnectionState.Offline))
        assertFalse(FlareConnectionAction.Reauth in actions(FlareConnectionState.Reconnecting))
    }

    @Test fun toneAndProgressPerState() {
        assertEquals(FlareStatusTone.Success, connectionTone(FlareConnectionState.Connected))
        assertEquals(FlareStatusTone.Warning, connectionTone(FlareConnectionState.Connecting))
        assertEquals(FlareStatusTone.Warning, connectionTone(FlareConnectionState.Reconnecting))
        assertEquals(FlareStatusTone.Danger, connectionTone(FlareConnectionState.Offline))
        assertEquals(FlareStatusTone.Danger, connectionTone(FlareConnectionState.SessionExpired))
        assertEquals(FlareStatusTone.Danger, connectionTone(FlareConnectionState.Kicked))
        assertEquals(FlareStatusTone.Neutral, connectionTone(FlareConnectionState.SdkUnready))
        assertEquals(
            listOf(FlareConnectionState.Connecting, FlareConnectionState.Reconnecting),
            FlareConnectionState.values().filter(::connectionInProgress),
        )
    }
}
