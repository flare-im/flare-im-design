package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Native rule: a control exists only when the host supplied its callback. */
class CallbackAffordanceTest {
    @Test fun toastCloseFollowsOnClose() {
        assertTrue(toastCloseVisible(hasOnClose = true))
        assertFalse(toastCloseVisible(hasOnClose = false))
    }

    @Test fun messageStatusResendOnlyForFailedWithCallback() {
        assertTrue(messageStatusResendable(FlareMessageDeliveryStatus.Failed, hasOnResend = true))
        assertFalse(messageStatusResendable(FlareMessageDeliveryStatus.Failed, hasOnResend = false))
        for (s in listOf(FlareMessageDeliveryStatus.Pending, FlareMessageDeliveryStatus.Sent, FlareMessageDeliveryStatus.Read)) {
            assertFalse(messageStatusResendable(s, hasOnResend = true), "$s must not be resendable")
        }
    }

    @Test fun newFriendRequestRowTapFollowsOnView() {
        assertTrue(newFriendRequestRowTappable(hasOnView = true))
        assertFalse(newFriendRequestRowTappable(hasOnView = false))
    }

    @Test fun retryAndSelectStringsExist() {
        val s = FlareStrings()
        assertTrue(s.retry.isNotEmpty()); assertTrue(s.select.isNotEmpty()); assertTrue(s.close.isNotEmpty())
        assertEquals("Retry", FlareStrings(retry = "Retry").retry)
    }
}
