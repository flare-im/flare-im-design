package com.flare.im.ui
import kotlin.test.*
class TransferProgressTest {
    @Test fun recoveryAndCompletedActions() {
        assertEquals(listOf(FlareTransferAction.Retry), FlareTransferState.Failed.actions)
        assertEquals(listOf(FlareTransferAction.Open), FlareTransferState.Completed.actions)
        assertEquals(listOf(FlareTransferAction.Pause, FlareTransferAction.Cancel), FlareTransferState.Transferring.actions)
        assertEquals(listOf(FlareTransferAction.Resume, FlareTransferAction.Cancel), FlareTransferState.Paused.actions)
        assertEquals(listOf(FlareTransferAction.Cancel), FlareTransferState.Queued.actions)
        assertEquals(listOf(FlareTransferAction.Retry), FlareTransferState.Cancelled.actions)
    }
    @Test fun measuredProgress() {
        assertNull(FlareTransferState.Transferring.normalizedProgress(Float.NaN))
        assertNull(FlareTransferState.Transferring.normalizedProgress(null))
        assertEquals(0f, FlareTransferState.Transferring.normalizedProgress(0f))
        assertEquals(1f, FlareTransferState.Transferring.normalizedProgress(2f))
        assertEquals(1f, FlareTransferState.Completed.normalizedProgress(null))
    }
}
