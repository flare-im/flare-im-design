package com.flare.im.ui
import kotlin.test.*
class TransferQueueTest {
 @Test fun retryOnlyActionableFailures() {
  val failed=FlareTransferQueueItem("a","a",FlareTransferState.Failed,"failed",actionLabels=mapOf(FlareTransferAction.Retry to "重试"))
  assertEquals(listOf("a"),retryableTransferIds(listOf(failed,failed.copy(id="b",busy=true),failed.copy(id="c",state=FlareTransferState.Cancelled),failed.copy(id="d",state=FlareTransferState.Completed),failed.copy(id="e",actionLabels=mapOf(FlareTransferAction.Retry to " ")))))
  assertEquals(emptyList(),retryableTransferIds(emptyList()))
 }
}
