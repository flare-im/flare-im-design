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
        // No delivered glyph: delivery without a read is the single check (spec/message-receipt-vectors.json).
        assertEquals(
            FlareMessageDeliveryStatus.Sent,
            FlareMessageLifecycle(delivery = FlareMessageLifecycleDeliveryState.Delivered).visualStatus,
        )
        assertEquals(
            listOf("Pending", "Sending", "Sent", "Read", "Failed"),
            FlareMessageDeliveryStatus.entries.map { it.name },
        )
    }
}
