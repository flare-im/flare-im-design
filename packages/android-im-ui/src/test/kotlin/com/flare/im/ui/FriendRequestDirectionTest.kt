package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** Friend requests carry their direction; an outgoing one reads as pending with a withdraw label. */
class FriendRequestDirectionTest {
    @Test fun requestsAreIncomingUnlessSaidOtherwise() {
        assertEquals(FriendRequestDirection.Incoming, FriendRequest("r1", "Ann").direction)
        assertEquals(FriendRequestDirection.Outgoing, FriendRequest("r2", "Kai", direction = FriendRequestDirection.Outgoing).direction)
    }

    @Test fun outgoingCopyIsLocalizable() {
        val zh = FlareStrings()
        assertEquals("等待验证", zh.newFriendRequestsPending)
        assertEquals("撤回", zh.newFriendRequestsWithdraw)
        val en = FlareStrings {
            newFriendRequestsPending = "Pending"
            newFriendRequestsWithdraw = "Withdraw"
            bottomSheetLabel = "Bottom sheet"
        }
        assertEquals("Pending", en.newFriendRequestsPending)
        assertEquals("Withdraw", en.newFriendRequestsWithdraw)
        assertEquals("Bottom sheet", en.bottomSheetLabel)
        assertEquals("底部面板", zh.bottomSheetLabel)
    }
}
