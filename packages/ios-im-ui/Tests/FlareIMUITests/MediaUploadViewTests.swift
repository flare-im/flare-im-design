import SwiftUI
import XCTest
@testable import FlareIMUI

final class MediaUploadViewTests: XCTestCase {
    private func item(_ state: FlareMediaUploadState, thumbnail: Bool = false, locked: Bool = false) -> FlareMediaUploadItem {
        FlareMediaUploadItem(id: UUID().uuidString, name: "a", state: state,
                             thumbnail: thumbnail ? Image(systemName: "photo") : nil, disabled: locked)
    }

    func testEachActionFollowsTheItemState() {
        XCTAssertFalse(MediaUploadView.allows(.remove, item(.uploading), disabled: false))
        XCTAssertTrue(MediaUploadView.allows(.remove, item(.failed), disabled: false))
        XCTAssertTrue(MediaUploadView.allows(.retry, item(.failed), disabled: false))
        XCTAssertFalse(MediaUploadView.allows(.retry, item(.uploaded), disabled: false))
        XCTAssertFalse(MediaUploadView.allows(.preview, item(.uploaded), disabled: false))
        XCTAssertTrue(MediaUploadView.allows(.preview, item(.uploaded, thumbnail: true), disabled: false))
        // Busy locks everything; a locked item only itself.
        XCTAssertFalse(MediaUploadView.allows(.remove, item(.selected), disabled: true))
        XCTAssertFalse(MediaUploadView.allows(.retry, item(.failed, locked: true), disabled: false))
    }

    func testTheAddTileWaitsForUploadsAndStopsAtTheLimit() {
        XCTAssertTrue(MediaUploadView.showsAdd([], maxCount: 9))
        XCTAssertTrue(MediaUploadView.showsAdd([item(.failed)], maxCount: nil))
        XCTAssertFalse(MediaUploadView.showsAdd([], maxCount: 0))
        XCTAssertFalse(MediaUploadView.showsAdd([item(.uploaded), item(.uploading)], maxCount: 9))
        XCTAssertFalse(MediaUploadView.showsAdd((0..<9).map { _ in item(.uploaded) }, maxCount: 9))
    }
}
