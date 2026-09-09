import XCTest
@testable import FlareIMUI

final class RelationActionBarTests: XCTestCase {
    private let all = FlareRelationCapabilities(add: true, accept: true, reject: true,
                                                remove: true, block: true, unblock: true,
                                                message: true)

    private func ids(_ relation: FlareRelationState,
                     _ caps: FlareRelationCapabilities?) -> [FlareRelationAction] {
        relationActions(relation, capabilities: caps).map(\.action)
    }

    func testNothingWithoutCapabilities() {
        for relation in FlareRelationState.allCases {
            XCTAssertEqual(ids(relation, .init()), [])
            XCTAssertEqual(ids(relation, nil), [])
        }
    }

    func testNoneOffersAddAsPrimaryPlusBlock() {
        XCTAssertEqual(ids(.none, all), [.add, .block])
        let entries = relationActions(.none, capabilities: all)
        XCTAssertEqual(entries.first, FlareRelationActionEntry(.add, primary: true))
        XCTAssertEqual(entries.last, FlareRelationActionEntry(.block))
    }

    func testPendingOutNeverReOffersAdd() {
        XCTAssertEqual(ids(.pendingOut, all), [.block])
        XCTAssertEqual(ids(.pendingOut, .init(add: true)), [])
        XCTAssertTrue(relationShowsPending(.pendingOut))
        for relation in FlareRelationState.allCases where relation != .pendingOut {
            XCTAssertFalse(relationShowsPending(relation))
        }
        XCTAssertFalse(relationShowsPending(nil))
    }

    func testPendingInOffersAcceptRejectBlock() {
        XCTAssertEqual(ids(.pendingIn, all), [.accept, .reject, .block])
        let entries = relationActions(.pendingIn, capabilities: all)
        XCTAssertEqual(entries.filter(\.primary).map(\.action), [.accept])
        XCTAssertTrue(entries.filter(\.destructive).isEmpty)
    }

    func testFriendsMarksRemoveAndBlockDestructive() {
        XCTAssertEqual(ids(.friends, all), [.message, .remove, .block])
        let entries = relationActions(.friends, capabilities: all)
        XCTAssertEqual(entries.filter(\.primary).map(\.action), [.message])
        XCTAssertEqual(entries.filter(\.destructive).map(\.action), [.remove, .block])
    }

    func testBlockedOffersUnblockAndNothingElse() {
        XCTAssertEqual(ids(.blocked, all), [.unblock])
        XCTAssertEqual(relationActions(.blocked, capabilities: all).first,
                       FlareRelationActionEntry(.unblock, primary: true))
        XCTAssertEqual(ids(.blocked, .init(add: true, message: true)), [])
    }

    func testMissingCapabilityRemovesOnlyItsOwnEntry() {
        XCTAssertEqual(ids(.none, .init(block: true)), [.block])
        XCTAssertEqual(ids(.none, .init(add: true)), [.add])
        XCTAssertEqual(ids(.pendingIn, .init(accept: true, block: true)), [.accept, .block])
        XCTAssertEqual(ids(.pendingIn, .init(reject: true)), [.reject])
        XCTAssertEqual(ids(.friends, .init(remove: true, block: true)), [.remove, .block])
        XCTAssertEqual(ids(.friends, .init(message: true)), [.message])
    }

    func testAbsentRelationDegradesToNone() {
        XCTAssertEqual(relationActions(nil, capabilities: all).map(\.action), [.add, .block])
    }

    func testLabelsFollowTextProps() {
        let view = RelationActionBarView(relation: .friends, capabilities: all,
                                         removeText: "Remove friend", messageText: "Message")
        XCTAssertEqual(view.label(for: .remove), "Remove friend")
        XCTAssertEqual(view.label(for: .message), "Message")
        XCTAssertEqual(view.label(for: .block), "加入黑名单")
    }

    func testEachActionHasItsOwnSymbol() {
        let symbols = Set(FlareRelationAction.allCases.map(RelationActionBarView.symbol(for:)))
        XCTAssertEqual(symbols.count, FlareRelationAction.allCases.count)
    }
}
