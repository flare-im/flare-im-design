import SwiftUI
import XCTest
import ViewInspector
@testable import FlareIMUI

@MainActor final class ScanResultDismissTests: XCTestCase {
    func testPausedCaptureCanBeResumedExplicitly() throws {
        var calls = 0
        let view = ScanViewfinderView(state: "paused", capabilities: .init(), onClose: {}, onRetry: { calls += 1 }) { EmptyView() }
        try view.inspect().find(button: FlareStrings().retry).tap()
        XCTAssertEqual(calls, 1)
    }
    func testDismissIsExplicitAndDisabledWhileBusy() throws {
        var calls = 0
        let ready = ScanResultSheetView(phase: "ready", header: .init(title: "Person"), onAction: { _, _ in }, onDismiss: { calls += 1 })
        try ready.inspect().find(button: FlareStrings().close).tap()
        XCTAssertEqual(calls, 1)
        let busy = ScanResultSheetView(phase: "acting", header: .init(title: "Person"), busy: true, onAction: { _, _ in }, onDismiss: { calls += 1 })
        XCTAssertTrue(try busy.inspect().find(button: FlareStrings().close).isDisabled())
    }
    func testImageFailureHasItsOwnStatusAndRetainsRetryAndAlbum() throws {
        var retries = 0, picks = 0
        let strings = FlareStrings()
        let view = ScanViewfinderView(state: "imageError", capabilities: .init(live: false, album: true), onClose: {}, onPickImage: { picks += 1 }, onRetry: { retries += 1 }) { EmptyView() }
        XCTAssertNoThrow(try view.inspect().find(text: strings.scanImageError))
        XCTAssertThrowsError(try view.inspect().find(text: strings.scanNoCodeInImage))
        XCTAssertThrowsError(try view.inspect().find(text: strings.scanCameraError))
        try view.inspect().find(button: strings.retry).tap()
        try view.inspect().find(button: strings.scanAlbum).tap()
        XCTAssertEqual(retries, 1); XCTAssertEqual(picks, 1)
    }
}
