import XCTest
@testable import FlareIMUI

final class ScreenShareTests: XCTestCase {
    private func shown(_ state: FlareScreenShareState, busy: Bool = false, all: Bool = true) -> [FlareScreenShareAction] {
        let actions = screenShareActions(state, hasStart: all, hasStop: all, hasCancel: all, busy: busy)
        return FlareScreenShareAction.allCases.filter(actions.contains)
    }

    private let visible: [FlareScreenShareState: [FlareScreenShareAction]] = [
        .idle: [.start], .requesting: [.cancel], .sharing: [.stop], .viewing: [], .unavailable: [],
    ]

    func testEveryStateExposesOnlyStateAppropriateActions() {
        for state in FlareScreenShareState.allCases {
            XCTAssertEqual(shown(state), visible[state], "\(state)")
        }
    }

    func testBusyKeepsButtonsVisibleButDisabled() {
        for state in FlareScreenShareState.allCases {
            XCTAssertEqual(shown(state, busy: true), visible[state], "\(state) busy")
            XCTAssertFalse(screenShareActions(state, hasStart: true, hasStop: true, hasCancel: true, busy: true).enabled)
            XCTAssertTrue(screenShareActions(state, hasStart: true, hasStop: true, hasCancel: true).enabled)
        }
    }

    func testMissingHostCallbacksHideEveryAction() {
        for state in FlareScreenShareState.allCases {
            XCTAssertEqual(shown(state, all: false), [], "\(state) no callbacks")
        }
    }

    func testViewerCannotStopAndUnavailableOffersNothing() {
        let viewing = screenShareActions(.viewing, hasStart: true, hasStop: true, hasCancel: true)
        XCTAssertFalse(viewing.stop)
        XCTAssertFalse(viewing.start)
        XCTAssertTrue(screenShareActions(.unavailable, hasStart: true, hasStop: true, hasCancel: true).isEmpty)
        XCTAssertFalse(screenShareActions(.sharing, hasStart: true, hasStop: true, hasCancel: true).start)
        for state in FlareScreenShareState.allCases {
            XCTAssertEqual(screenShareActions(state, hasStart: true, hasStop: true, hasCancel: true).cancel,
                           state == .requesting, "\(state) cancel")
        }
    }

    func testToneAndIconPerState() {
        XCTAssertEqual(screenShareTone(.idle), .neutral)
        XCTAssertEqual(screenShareTone(.requesting), .warning)
        XCTAssertEqual(screenShareTone(.sharing), .success)
        XCTAssertEqual(screenShareTone(.viewing), .info)
        XCTAssertEqual(screenShareTone(.unavailable), .neutral)
        XCTAssertEqual(FlareScreenShareState.allCases.map(screenShareIconName),
                       ["devices", "refresh", "video", "eye", "block"])
        for state in FlareScreenShareState.allCases {
            XCTAssertNotNil(flareIconMap[screenShareIconName(state)], "\(state) icon resolves")
        }
    }

    func testViewBuildsForEveryState() {
        for state in FlareScreenShareState.allCases {
            let view = ScreenShareView(state: state, sourceLabel: "整个屏幕", presenterName: "林可",
                                       detail: "上行带宽受限，画面已降帧", busy: false,
                                       onStart: {}, onStop: {}, onCancel: {})
            _ = view.body
            let busyView = ScreenShareView(state: state, busy: true, onStart: {}, onStop: {}, onCancel: {})
            _ = busyView.body
        }
    }
}
