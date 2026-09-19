package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

class MessageLifecycleTest {
    @Test
    fun lifecycleProjectsToCompleteVisualStatus() {
        assertEquals(FlareMessageDeliveryStatus.Sent, FlareMessageLifecycle().visualStatus)
        assertEquals(
            FlareMessageDeliveryStatus.Failed,
            FlareMessageLifecycle(transfer = FlareTransferState.Failed).visualStatus,
        )
        assertEquals(
            FlareMessageDeliveryStatus.Read,
            FlareMessageLifecycle(read = FlareMessageReadState.Read).visualStatus,
        )
        assertEquals(
            FlareMessageDeliveryStatus.Sending,
            FlareMessageLifecycle(send = FlareMessageSendState.Sending).visualStatus,
        )
        assertEquals(
            FlareMessageDeliveryStatus.Delivered,
            FlareMessageLifecycle(delivery = FlareMessageLifecycleDeliveryState.Delivered).visualStatus,
        )
    }
}
