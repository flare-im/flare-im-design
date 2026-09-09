import XCTest
@testable import FlareIMUI
final class TransferQueueTests:XCTestCase {
 func testRetryOnlyActionableFailures() {
  let items=[FlareTransferQueueItem(id:"a",name:"a",state:.failed,statusText:"failed",actionLabels:[.retry:"重试"]),
    FlareTransferQueueItem(id:"b",name:"b",state:.failed,statusText:"busy",actionLabels:[.retry:"重试"],busy:true),
    FlareTransferQueueItem(id:"c",name:"c",state:.cancelled,statusText:"cancelled",actionLabels:[.retry:"重试"]),
    FlareTransferQueueItem(id:"d",name:"d",state:.completed,statusText:"completed",actionLabels:[.retry:"重试"]),
    FlareTransferQueueItem(id:"e",name:"e",state:.failed,statusText:"unavailable",actionLabels:[.retry:" "])]
  XCTAssertEqual(retryableTransferIds(items),["a"])
  XCTAssertEqual(retryableTransferIds([]),[])
 }
}
