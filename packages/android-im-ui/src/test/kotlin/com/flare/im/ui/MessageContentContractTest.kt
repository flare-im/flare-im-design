package com.flare.im.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MessageContentContractTest {
    @Test fun `message content projection covers RC kinds`() {
        assertEquals(26, FlareMessageContentKind.entries.size)
        assertEquals("image_group", resolveMessageContentContract(FlareMessageContentKind.MultiImage).wireType)
        assertNull(resolveMessageContentContract(FlareMessageContentKind.ReadOnce).wireType)
        assertTrue(FlareMessageContentKind.Code.capabilities.contains(FlareMessageContentCapability.HorizontalScroll))
    }
}
