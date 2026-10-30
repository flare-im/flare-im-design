import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// `spec/red-packet-vectors.json` `openSheetRefunded`, `amountInputExponent`, `amountPlaceholder` and `amountMinor`:
/// the refunded open sheet and the composer's amount in the currency's exponent.
final class RedPacketExponentAndRefundTests: XCTestCase {
    private func table() throws -> PluginJSONValue { try SpecVectors.table("red-packet-vectors.json") }

    func testTheAmountKeepsTheCurrencysDecimals() throws {
        let cases = try XCTUnwrap(try table()["amountInputExponent"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 9)
        for vector in cases {
            let id = vector["id"]?.stringValue ?? "?"
            let exponent = try XCTUnwrap(vector["exponent"]?.intValue, id)
            XCTAssertEqual(RedPacketInput.amount(try XCTUnwrap(vector["input"]?.stringValue), exponent: exponent),
                           vector["output"]?.stringValue, id)
        }
        // The cases of amountInput are exponent 2, the default.
        for vector in try XCTUnwrap(try table()["amountInput"]?.arrayValue) {
            let input = try XCTUnwrap(vector["input"]?.stringValue)
            XCTAssertEqual(RedPacketInput.amount(input, exponent: 2), RedPacketInput.amount(input), input)
        }
    }

    func testTheAmountTurnsIntoMinorUnitsWithoutFloatingPoint() throws {
        let cases = try XCTUnwrap(try table()["amountMinor"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 15)
        for vector in cases {
            let id = vector["id"]?.stringValue ?? "?"
            let minor = flareRedPacketAmountMinor(try XCTUnwrap(vector["input"]?.stringValue, id),
                                                  exponent: try XCTUnwrap(vector["exponent"]?.intValue, id))
            XCTAssertEqual(minor, vector["minor"]?.stringValue, id)
        }
    }

    @MainActor
    func testThePlaceholderHasTheCurrencysDecimals() throws {
        typealias Composer = RedPacketComposerView<EmptyView>
        let block = try XCTUnwrap(try table()["amountPlaceholder"])
        for vector in try XCTUnwrap(block["cases"]?.arrayValue) {
            let exponent = try XCTUnwrap(vector["exponent"]?.intValue)
            let placeholder = try XCTUnwrap(vector["placeholder"]?.stringValue)
            XCTAssertEqual(Composer.amountPlaceholder(exponent), placeholder, "exponent \(exponent)")
            let composer = Composer(kinds: [.normal], kind: .normal, amount: "", currencyExponent: exponent, total: "¥0",
                                    recipient: { EmptyView() })
            XCTAssertNoThrow(try composer.inspect().find(text: placeholder), "the field shows \(placeholder)")
        }
        XCTAssertEqual(RedPacketInput.exponent(9), 9)
        XCTAssertEqual(RedPacketInput.exponent(99), 12, "held to 0...12")
        XCTAssertEqual(RedPacketInput.exponent(-1), 0)
    }

    func testARefundedSheetIsLikeAnExpiredOne() throws {
        let cases = try XCTUnwrap(try table()["openSheetRefunded"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 2)
        for vector in cases {
            let id = vector["id"]?.stringValue ?? "?"
            let state = try XCTUnwrap(FlareRedPacketOpenState(rawValue: vector["state"]?.stringValue ?? ""), id)
            XCTAssertEqual(RedPacketOpenSheet.showsOpenButton(state), vector["coin"]?.boolValue, id)
            XCTAssertEqual(RedPacketOpenSheet.showsDetails(state, canViewDetails: vector["canViewDetails"]?.boolValue ?? true),
                           vector["details"]?.boolValue, id)
            for (language, strings) in [("zh", FlareStrings()), ("en", FlareStrings.english)] {
                XCTAssertEqual(RedPacketOpenSheet.headline(state: state, blessing: "Wish", message: nil, strings: strings),
                               vector["headline"]?[language]?.stringValue, "\(id) \(language)")
            }
        }
        XCTAssertEqual(RedPacketOpenSheet.headline(state: .refunded, blessing: "Wish", message: "只退回了一部分",
                                                   strings: FlareStrings()), "只退回了一部分", "the host's message wins")
    }

    @MainActor
    func testTheRefundedSheetDrawsItsNoticeAndTheDetailsKey() throws {
        let zh = FlareStrings()
        var details = 0
        let sheet = RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", state: .refunded,
                                       onOpen: {}, onViewDetails: { details += 1 }, onClose: {})
        let view = try sheet.inspect()
        XCTAssertNoThrow(try view.find(text: zh.packetRefundedNotice))
        XCTAssertThrowsError(try view.find(button: zh.packetOpenAction), "nothing to open")
        try view.find(button: zh.packetViewDetails).tap()
        XCTAssertEqual(details, 1)
    }
}
