package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ReauthPromptTest {
    @Test fun actionsPerReasonAndBusy() {
        for (reason in FlareReauthReason.entries) for (busy in listOf(false, true)) {
            val reauthAllowed = reason != FlareReauthReason.AccountDisabled
            val both = reauthActions(reason, hasReauth = true, hasLogout = true, busy = busy)
            assertEquals(FlareReauthActionState(visible = reauthAllowed, enabled = reauthAllowed && !busy), both.reauthenticate, "$reason busy=$busy")
            assertEquals(FlareReauthActionState(visible = true, enabled = !busy), both.logout, "$reason busy=$busy")
            assertEquals(reauthAllowed, both.primary, "$reason busy=$busy")
            val none = reauthActions(reason, hasReauth = false, hasLogout = false, busy = busy)
            assertEquals(FlareReauthActionState(visible = false, enabled = false), none.reauthenticate)
            assertEquals(FlareReauthActionState(visible = false, enabled = false), none.logout)
            assertFalse(none.primary)
        }
    }
    @Test fun busyDefaultsToFalse() {
        assertTrue(reauthActions(FlareReauthReason.SessionExpired, hasReauth = true, hasLogout = false).reauthenticate.enabled)
    }
    @Test fun toneAndIconPerReason() {
        assertEquals(listOf(FlareReauthTone.Info, FlareReauthTone.Warning, FlareReauthTone.Warning, FlareReauthTone.Danger), FlareReauthReason.entries.map(::reauthTone))
        assertEquals(listOf("clock", "devices", "lock", "block"), FlareReauthReason.entries.map(::reauthIcon))
    }
}
