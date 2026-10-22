import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The red packet family's state matrix: the card, the open-packet layer, the details page, the composer and the
/// payment confirmation. Copy is read from the strings table, never repeated here, so a translation does not
/// break the tests and a missing field does.
final class RedPacketComponentsTests: XCTestCase {
    private let zh = FlareStrings()
    private let en = FlareStrings.english

    // MARK: Card

    func testCardStatusFollowsTheContractOrder() {
        func status(_ state: FlareRedPacketCardState, label: String? = nil, busy: Bool = false,
                    disabled: Bool = false) -> String {
            FlareRedPacketCardRules.status(state: state, statusLabel: label, busy: busy, disabled: disabled).text(zh)
        }
        XCTAssertEqual(status(.claimed, label: "Created", busy: true), zh.packetBusy)
        XCTAssertEqual(status(.claimed, label: "Created"), "Created")
        XCTAssertEqual(status(.claimed), zh.packetStateClaimed)
        XCTAssertEqual(status(.viewable), zh.packetView)
        XCTAssertEqual(status(.finished, disabled: true), zh.packetFinished)
        XCTAssertEqual(status(.expired, disabled: true), zh.packetStateExpired)
        XCTAssertEqual(status(.refunded), zh.packetRefunded)
        XCTAssertEqual(status(.unopened, disabled: true), zh.packetUnavailable)
        XCTAssertEqual(status(.unopened), zh.packetTapToClaim)
        XCTAssertEqual(zh.packetFinished, "已被领完")
        XCTAssertEqual(zh.packetTapToClaim, "领取红包")
    }

    // MARK: Shared vectors

    private struct Vectors: Decodable {
        struct Text: Decodable { let id: String; let input: String; let output: String }
        struct Count: Decodable { let id: String; let input: String; let output: Int }
        struct Card: Decodable {
            let id: String
            let state: String
            let statusLabel: String?
            let busy: Bool?
            let disabled: Bool?
            let status: String
            let tappable: Bool
            let dimmed: Bool
        }
        struct Faded: Decodable {
            struct Stop: Decodable { let token: String; let base: String; let faded: String }
            struct Mode: Decodable { let target: String; let ink: String; let stops: [Stop] }
            let mix: Double
            let target: String
            let ink: String
            let minTextContrast: Double
            let textStops: [String]
            let stops: [Stop]
            let dark: Mode
        }
        struct Composer: Decodable {
            let id: String
            let kinds: [String]
            let kind: String
            let amountLabel: String
            let showsCount: Bool
            let showsRecipient: Bool
        }
        struct CardState: Decodable {
            struct View: Decodable { let status: String; let claimedByMe: Bool?; let tapAction: String? }
            let id: String
            let view: View
            let state: String
        }
        struct Badge: Decodable {
            struct Pair: Decodable { let zh: String; let en: String }
            let id: String
            let kind: String
            let recipientName: String?
            let badge: String?
            let zh: String?
            let en: String?
            let recipient: Pair?
        }
        struct OpenSheet: Decodable {
            let id: String
            let state: String
            let canViewDetails: Bool?
            let coin: Bool
            let details: Bool
        }
        struct Amount: Decodable {
            struct Case: Decodable { let minor: String; let exponent: Int; let currency: String; let text: String?; let money: String? }
            let symbols: [String: String]
            let cases: [Case]
        }
        struct Detail: Decodable {
            struct Expect: Decodable {
                let amount: String?; let deposited: Bool; let headline: String?; let summary: String?
                let claims: Bool; let note: String?
            }
            struct Case: Decodable {
                let id: String
                let designatedName: String?
                let details: FlareRedPacketDetailsView
                let expect: Expect
            }
            let nowMs: Int64
            let utcOffsetMinutes: Int
            let cases: [Case]
            let claimRows: [ClaimRow]
        }
        struct ClaimRow: Decodable {
            struct Claim: Decodable { let id: String; let name: String; let amountMinor: String; let claimedAtMs: Int64; let best: Bool }
            struct Expect: Decodable { let amount: String; let time: String; let best: Bool }
            let claim: Claim
            let currency: String
            let currencyExponent: Int
            let expect: Expect
        }
        let amountInput: [Text]
        let countInput: [Count]
        let cardState: [CardState]
        let card: [Card]
        let cardBadge: [Badge]
        /// zh / en copy by status, and `keys` (status → FlareStrings field).
        let cardCopy: [String: [String: String]]
        let openSheet: [OpenSheet]
        let amount: Amount
        let detail: Detail
        let faded: Faded
        let composer: [Composer]
    }

    /// `#RRGGBB` as a colour, and a colour back as `#RRGGBB`.
    private func color(_ hex: String) -> Color {
        let value = Int(hex.dropFirst(), radix: 16) ?? 0
        return Color(.sRGB, red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255,
                     blue: Double(value & 0xFF) / 255, opacity: 1)
    }

    private func channels(_ c: Color) -> [Int] {
        let rgb = RedPacketPalette.rgb(c)
        return [rgb.r, rgb.g, rgb.b].map { Int(($0 * 255).rounded()) }
    }

    /// The token colour a vector names, read from the kit's generated tokens.
    private func token(_ name: String, _ colors: FlareColors) -> Color? {
        switch name {
        case "colors.redPacket.start": return colors.redPacketStart
        case "colors.redPacket.middle": return colors.redPacketMiddle
        case "colors.redPacket.end": return colors.redPacketEnd
        case "colors.redPacket.gold": return colors.redPacketGold
        case "colors.redPacket.goldDeep": return colors.redPacketGoldDeep
        default: return nil
        }
    }

    /// Light and dark: the mix target, the ink, every faded stop, and the ink's contrast on the text stops.
    func testSpentCardsFadeAsTheSharedTableSays() throws {
        let table = try vectors().faded
        XCTAssertEqual(Double(FlareSizes.componentRedPacketFadedMix), table.mix, accuracy: 0.0001)
        let modes: [(ColorScheme, Vectors.Faded.Mode)] = [
            (.light, .init(target: table.target, ink: table.ink, stops: table.stops)), (.dark, table.dark),
        ]
        for (scheme, mode) in modes {
            let colors = FlareColors.of(scheme, brand: .violet)
            XCTAssertEqual(channels(colors.redPacketFadedMixTarget), channels(color(mode.target)), "\(scheme)")
            XCTAssertEqual(channels(colors.redPacketFadedInk), channels(color(mode.ink)), "\(scheme)")
            XCTAssertEqual(mode.stops.count, 5)
            for stop in mode.stops {
                let base = try XCTUnwrap(token(stop.token, colors), stop.token)
                XCTAssertEqual(channels(base), channels(color(stop.base)), stop.token)
                for (got, want) in zip(channels(RedPacketPalette.fade(base, colors)), channels(color(stop.faded))) {
                    XCTAssertLessThanOrEqual(abs(got - want), 1, "\(scheme) \(stop.token)")
                }
            }
            for name in table.textStops {
                let faded = RedPacketPalette.fade(try XCTUnwrap(token(name, colors), name), colors)
                XCTAssertGreaterThanOrEqual(RedPacketPalette.contrast(colors.redPacketFadedInk, faded),
                                            table.minTextContrast, "\(scheme): the spent card's text on \(name)")
            }
        }
    }

    func testComposerRowsFollowTheSharedTable() throws {
        typealias Composer = RedPacketComposerView<EmptyView>
        let table = try vectors().composer
        XCTAssertGreaterThanOrEqual(table.count, 6)
        for vector in table {
            let kinds = try vector.kinds.map { try XCTUnwrap(FlareRedPacketKind(rawValue: $0), vector.id) }
            let shown = Composer.shownKind(try XCTUnwrap(FlareRedPacketKind(rawValue: vector.kind)), kinds: kinds)
            let label: String
            switch vector.amountLabel {
            case "total": label = zh.packetFieldTotal
            case "each": label = zh.packetFieldEach
            case "amount": label = zh.packetFieldAmount
            default: XCTFail("unknown label \(vector.amountLabel) in \(vector.id)"); continue
            }
            XCTAssertEqual(Composer.amountLabel(kind: shown, kinds: kinds, strings: zh), label, vector.id)
            XCTAssertEqual(Composer.showsCount(kind: shown, kinds: kinds), vector.showsCount, vector.id)
            XCTAssertEqual(shown == .exclusive, vector.showsRecipient, vector.id)
        }
    }

    /// `spec/red-packet-vectors.json`, the table the four kits run.
    private func vectors() throws -> Vectors {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Vectors.self, from: Data(contentsOf: root.appendingPathComponent("spec/red-packet-vectors.json")))
    }

    func testCardStateFollowsTheSharedTable() throws {
        let table = try vectors().cardState
        XCTAssertGreaterThanOrEqual(table.count, 11, "the shared table lost cases")
        for vector in table {
            let status = try XCTUnwrap(FlareRedPacketStatus(rawValue: vector.view.status), vector.id)
            let tap = try vector.view.tapAction.map { try XCTUnwrap(FlareRedPacketTapAction(rawValue: $0), vector.id) }
            XCTAssertEqual(flareRedPacketCardState(status: status, claimedByMe: vector.view.claimedByMe ?? false,
                                                   tapAction: tap).rawValue, vector.state, vector.id)
        }
    }

    func testCardFollowsTheSharedTable() throws {
        let table = try vectors().card
        XCTAssertGreaterThanOrEqual(table.count, 11, "the shared table lost cases")
        for vector in table {
            let state = try XCTUnwrap(FlareRedPacketCardState(rawValue: vector.state), vector.id)
            let expected: String
            switch vector.status {
            case "busy": expected = zh.packetBusy
            case "statusLabel": expected = try XCTUnwrap(vector.statusLabel, vector.id)
            case "tapToOpen": expected = zh.packetTapToClaim
            case "view": expected = zh.packetView
            case "claimed": expected = zh.packetStateClaimed
            case "finished": expected = zh.packetFinished
            case "expired": expected = zh.packetStateExpired
            case "refunded": expected = zh.packetRefunded
            case "unavailable": expected = zh.packetUnavailable
            default: XCTFail("unknown status \(vector.status) in \(vector.id)"); continue
            }
            XCTAssertEqual(FlareRedPacketCardRules.status(state: state, statusLabel: vector.statusLabel,
                                                          busy: vector.busy ?? false,
                                                          disabled: vector.disabled ?? false).text(zh),
                           expected, vector.id)
            XCTAssertEqual(FlareRedPacketCardRules.faded(state), vector.dimmed, vector.id)
            let card = RedPacketCardView(blessing: "Hello", state: state, disabled: vector.disabled ?? false,
                                         busy: vector.busy ?? false, statusLabel: vector.statusLabel, onOpen: {})
            XCTAssertEqual(card.canOpen, vector.tappable, vector.id)
        }
        // The card copy of the shared table is the kit's.
        let copy: [(String, String)] = [(zh.packetTapToClaim, "领取红包"), (zh.packetView, "查看红包"),
                                        (zh.packetStateClaimed, "已领取"), (zh.packetFinished, "已被领完"),
                                        (zh.packetStateExpired, "已过期"), (zh.packetRefunded, "已退回"),
                                        (zh.packetBusy, "处理中…"), (zh.packetUnavailable, "暂不可用")]
        for (kit, table) in copy { XCTAssertEqual(kit, table) }
        // And the English preset matches the shared table's English.
        let english = try XCTUnwrap(try vectors().cardCopy["en"])
        let englishCopy: [(String, String?)] = [
            (en.packetTapToClaim, english["tapToOpen"]), (en.packetView, english["view"]),
            (en.packetStateClaimed, english["claimed"]), (en.packetFinished, english["finished"]),
            (en.packetStateExpired, english["expired"]), (en.packetRefunded, english["refunded"]),
            (en.packetBusy, english["busy"]), (en.packetUnavailable, english["unavailable"]),
        ]
        for (kit, table) in englishCopy { XCTAssertEqual(kit, table) }
    }

    @MainActor
    func testTheCardNeverShowsAnAmountAndCarriesTheBadgeAndTheRecipient() throws {
        let table = try vectors().cardBadge
        XCTAssertGreaterThanOrEqual(table.count, 5)
        for vector in table {
            let kind = try XCTUnwrap(FlareRedPacketKind(rawValue: vector.kind), vector.id)
            XCTAssertEqual(FlareRedPacketCardRules.badge(kind, strings: zh), vector.zh, vector.id)
            XCTAssertEqual(FlareRedPacketCardRules.recipient(kind, name: vector.recipientName, strings: zh),
                           vector.recipient?.zh, vector.id)
            XCTAssertEqual(FlareRedPacketCardRules.badge(kind, strings: en), vector.en, "\(vector.id) en")
            XCTAssertEqual(FlareRedPacketCardRules.recipient(kind, name: vector.recipientName, strings: en),
                           vector.recipient?.en, "\(vector.id) en")
            let tree = try RedPacketCardView(blessing: "恭喜发财", kind: kind, recipientName: vector.recipientName,
                                             state: .claimed, onOpen: {}).inspect()
            if let badge = vector.zh { XCTAssertNoThrow(try tree.find(text: badge), vector.id) }
            if let recipient = vector.recipient?.zh { XCTAssertNoThrow(try tree.find(text: recipient), vector.id) }
            // No digit, no currency: the card has no amount to draw.
            let texts = tree.findAll(ViewType.Text.self).compactMap { try? $0.string() }
            XCTAssertFalse(texts.contains { $0.contains("¥") || $0.rangeOfCharacter(from: .decimalDigits) != nil },
                           "\(vector.id): \(texts)")
        }
    }

    func testAmountsFormatFromMinorUnitsAsTheSharedTableSays() throws {
        let table = try vectors().amount
        XCTAssertEqual(table.symbols, FlareRedPacketMoney.symbols)
        XCTAssertGreaterThanOrEqual(table.cases.count, 12)
        for vector in table.cases {
            XCTAssertEqual(FlareRedPacketMoney.text(minor: vector.minor, exponent: vector.exponent), vector.text,
                           vector.minor)
            XCTAssertEqual(FlareRedPacketMoney.money(minor: vector.minor, exponent: vector.exponent,
                                                     currency: vector.currency), vector.money, vector.minor)
        }
    }

    func testFieldsFormatAsTheSharedTableSays() throws {
        let table = try vectors()
        XCTAssertGreaterThanOrEqual(table.amountInput.count, 13)
        for vector in table.amountInput {
            XCTAssertEqual(RedPacketInput.amount(vector.input), vector.output, vector.id)
        }
        XCTAssertGreaterThanOrEqual(table.countInput.count, 7)
        for vector in table.countInput {
            XCTAssertEqual(RedPacketInput.count(vector.input), vector.output, vector.id)
        }
        XCTAssertEqual(RedPacketInput.countText(0), "")
        XCTAssertEqual(RedPacketInput.countText(12), "12")
    }

    func testOnlyAnUnopenedOrViewableCardKeepsItsFullColour() {
        XCTAssertFalse(FlareRedPacketCardRules.faded(.unopened))
        XCTAssertFalse(FlareRedPacketCardRules.faded(.viewable))
        for state in [FlareRedPacketCardState.claimed, .finished, .expired, .refunded] {
            XCTAssertTrue(FlareRedPacketCardRules.faded(state), "\(state)")
        }
    }

    @MainActor
    func testEveryCardStateOpensButBusyDisabledAndUnhandledDoNot() throws {
        var opened: [FlareRedPacketCardState] = []
        for state in FlareRedPacketCardState.allCases {
            try RedPacketCardView(blessing: "Hello", state: state, onOpen: { opened.append(state) })
                .inspect().find(ViewType.Button.self).tap()
        }
        XCTAssertEqual(opened, FlareRedPacketCardState.allCases)
        for card in [
            RedPacketCardView(blessing: "Hello", state: .finished, busy: true, onOpen: { opened.append(.finished) }),
            RedPacketCardView(blessing: "Hello", state: .expired, disabled: true, onOpen: { opened.append(.expired) }),
            RedPacketCardView(blessing: "Hello", state: .expired),
        ] {
            let button = try card.inspect().find(ViewType.Button.self)
            XCTAssertTrue(button.isDisabled())
            XCTAssertThrowsError(try button.tap())
        }
        XCTAssertEqual(opened.count, FlareRedPacketCardState.allCases.count)
    }

    @MainActor
    func testCardShowsTheKindOnTheBrandRowAndNamesItForVoiceOver() throws {
        let card = RedPacketCardView(blessing: "Hello", kind: .exclusive, recipientName: "Bob", state: .expired,
                                     onOpen: {})
        let view = try card.inspect()
        XCTAssertNoThrow(try view.find(text: zh.packetBadgeExclusive))
        XCTAssertNoThrow(try view.find(text: "给 Bob"))
        XCTAssertNoThrow(try view.find(text: zh.packetBrand))
        XCTAssertNoThrow(try view.find(text: zh.packetStateExpired))
        let button = try view.find(ViewType.Button.self)
        XCTAssertEqual(try button.accessibilityLabel().string(), "Hello, \(zh.packetBadgeExclusive), 给 Bob")
        XCTAssertEqual(try button.accessibilityValue().string(), zh.packetStateExpired)
        XCTAssertThrowsError(try RedPacketCardView(blessing: "Hello", kind: .normal).inspect()
            .find(text: zh.packetBadgeLucky), "a normal packet has no badge")
    }

    // MARK: Open sheet

    func testOpenSheetCopyForEveryState() {
        func headline(_ state: FlareRedPacketOpenState, _ message: String? = nil) -> String {
            RedPacketOpenSheet.headline(state: state, blessing: "Wish", message: message, strings: zh)
        }
        func hint(_ state: FlareRedPacketOpenState, _ message: String? = nil) -> String? {
            RedPacketOpenSheet.hint(state: state, message: message, strings: zh)
        }
        XCTAssertEqual(headline(.ready), "Wish")
        XCTAssertEqual(headline(.opening), "Wish")
        XCTAssertEqual(headline(.error), "Wish")
        XCTAssertEqual(headline(.finished), zh.packetMissed)
        XCTAssertEqual(headline(.expired), zh.packetExpiredNotice)
        XCTAssertEqual(headline(.notEligible), zh.packetNotEligible)
        XCTAssertEqual(headline(.notEligible, "Only Ann"), "Only Ann")
        XCTAssertEqual(headline(.finished, "Gone"), "Gone", "the host's message replaces the kit's copy")
        XCTAssertEqual(headline(.expired, "Refunded"), "Refunded")
        XCTAssertEqual(headline(.expired, ""), zh.packetExpiredNotice, "an empty message is no message")
        XCTAssertEqual(headline(.ready, "Only Ann"), "Wish")
        for state in FlareRedPacketOpenState.allCases where state != .error {
            XCTAssertNil(hint(state, "Only Ann"), "\(state)")
        }
        XCTAssertEqual(hint(.error), zh.packetOpenFailed)
        XCTAssertEqual(hint(.error, ""), zh.packetOpenFailed)
        XCTAssertEqual(hint(.error, "Network"), "Network")

        let withButton = FlareRedPacketOpenState.allCases.filter(RedPacketOpenSheet.showsOpenButton)
        XCTAssertEqual(withButton, [.ready, .opening, .error])
        let withDetails = FlareRedPacketOpenState.allCases.filter { RedPacketOpenSheet.showsDetails($0) }
        XCTAssertEqual(withDetails, [.finished, .expired], "a viewer the packet is not for gets no details")
    }

    func testOpenSheetKeysFollowTheSharedTable() throws {
        let table = try vectors().openSheet
        XCTAssertGreaterThanOrEqual(table.count, 8)
        for vector in table {
            let state = try XCTUnwrap(FlareRedPacketOpenState(rawValue: vector.state), vector.id)
            XCTAssertEqual(RedPacketOpenSheet.showsOpenButton(state), vector.coin, vector.id)
            XCTAssertEqual(RedPacketOpenSheet.showsDetails(state, canViewDetails: vector.canViewDetails ?? true),
                           vector.details, vector.id)
        }
    }

    func testEnvelopeKeepsAGutterOnNarrowWindows() {
        XCTAssertEqual(RedPacketOpenSheet.envelopeWidth(window: 1024), FlareSizes.componentRedPacketEnvelopeWidth)
        XCTAssertEqual(RedPacketOpenSheet.envelopeWidth(window: 320), 320 - 2 * FlareSizes.spacingXl)
        XCTAssertEqual(RedPacketOpenSheet.envelopeWidth(window: 10), 0)
    }

    @MainActor
    func testReadySheetOpensAndCloses() throws {
        var events: [String] = []
        let sheet = RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", kindLabel: "Lucky",
                                       onOpen: { events.append("open") }, onViewDetails: { events.append("details") },
                                       onClose: { events.append("close") })
        let view = try sheet.inspect()
        XCTAssertNoThrow(try view.find(text: zh.packetFromSender("Ann")))
        XCTAssertNoThrow(try view.find(text: "Lucky"))
        XCTAssertNoThrow(try view.find(text: "Wish"))
        try view.find(button: zh.packetOpenAction).tap()
        try closeButton(view).tap()
        XCTAssertEqual(events, ["open", "close"])
        XCTAssertThrowsError(try view.find(button: zh.packetViewDetails), "nothing to explain while it can be opened")
    }

    @MainActor
    func testOpeningSheetTakesNoSecondTap() throws {
        var opens = 0
        let sheet = RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", state: .opening,
                                       onOpen: { opens += 1 }, onClose: {})
        let button = try sheet.inspect().find(ViewType.Button.self, where: {
            (try? $0.accessibilityLabel().string()) == self.zh.packetOpenAction
        })
        XCTAssertTrue(button.isDisabled())
        XCTAssertEqual(try button.accessibilityValue().string(), zh.packetBusy)
        XCTAssertThrowsError(try button.tap())
        XCTAssertEqual(opens, 0)
    }

    @MainActor
    func testUnavailableSheetsExplainAndLeadToTheDetailsOnlyWhenTheViewerMayLook() throws {
        let cases: [(FlareRedPacketOpenState, String, Bool, Bool)] = [
            (.finished, zh.packetMissed, true, true), (.expired, zh.packetExpiredNotice, true, true),
            (.finished, zh.packetMissed, false, false), (.notEligible, "仅 Bo 可领取", true, false),
        ]
        for (state, copy, canViewDetails, offersDetails) in cases {
            var details = 0
            let sheet = RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", state: state,
                                           message: state == .notEligible ? "仅 Bo 可领取" : nil,
                                           canViewDetails: canViewDetails,
                                           onOpen: {}, onViewDetails: { details += 1 }, onClose: {})
            let view = try sheet.inspect()
            XCTAssertNoThrow(try view.find(text: copy), "\(state)")
            XCTAssertThrowsError(try view.find(text: "Wish"), "\(state) replaces the blessing")
            XCTAssertThrowsError(try view.find(button: zh.packetOpenAction), "\(state) has nothing to open")
            if offersDetails {
                try view.find(button: zh.packetViewDetails).tap()
                XCTAssertEqual(details, 1, "\(state)")
            } else {
                XCTAssertThrowsError(try view.find(button: zh.packetViewDetails), "\(state) offers no details")
            }
        }
    }

    @MainActor
    func testErrorSheetKeepsTheButtonForAnotherTry() throws {
        var opens = 0
        let sheet = RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", state: .error,
                                       onOpen: { opens += 1 }, onClose: {})
        let view = try sheet.inspect()
        XCTAssertNoThrow(try view.find(text: zh.packetOpenFailed))
        try view.find(button: zh.packetOpenAction).tap()
        XCTAssertEqual(opens, 1)
    }

    @MainActor
    private func closeButton(_ view: InspectableView<ViewType.ClassifiedView>) throws -> InspectableView<ViewType.Button> {
        try view.find(ViewType.Button.self, where: { (try? $0.accessibilityLabel().string()) == self.zh.close })
    }

    // MARK: Details

    func testDetailsFollowTheSharedTableForEveryRoleAndStatus() throws {
        let table = try vectors().detail
        XCTAssertGreaterThanOrEqual(table.cases.count, 15)
        for vector in table.cases {
            let shown = FlareRedPacketDetailRules.presentation(vector.details, designatedName: vector.designatedName,
                                                               nowMs: table.nowMs, strings: zh,
                                                               utcOffsetMinutes: table.utcOffsetMinutes)
            XCTAssertEqual(shown.amount, vector.expect.amount, "\(vector.id) amount")
            XCTAssertEqual(shown.deposited, vector.expect.deposited, "\(vector.id) deposited")
            XCTAssertEqual(shown.headline, vector.expect.headline, "\(vector.id) headline")
            XCTAssertEqual(shown.summary, vector.expect.summary, "\(vector.id) summary")
            XCTAssertEqual(shown.claims, vector.expect.claims, "\(vector.id) claims")
            XCTAssertEqual(shown.note, vector.expect.note, "\(vector.id) note")
        }
    }

    func testClaimRowsFormatTheirAmountAndTimeAsTheSharedTableSays() throws {
        let table = try vectors()
        XCTAssertGreaterThanOrEqual(table.detail.claimRows.count, 3)
        for vector in table.detail.claimRows {
            let claim = FlareRedPacketClaim(id: vector.claim.id, name: vector.claim.name, amountMinor: vector.claim.amountMinor,
                                            claimedAtMs: vector.claim.claimedAtMs, best: vector.claim.best)
            let row = FlareRedPacketDetailRules.claimRow(claim, currency: vector.currency, exponent: vector.currencyExponent,
                                                         nowMs: table.detail.nowMs, strings: zh,
                                                         utcOffsetMinutes: table.detail.utcOffsetMinutes)
            XCTAssertEqual(row.amount, vector.expect.amount, vector.claim.id)
            XCTAssertEqual(row.time, vector.expect.time, vector.claim.id)
            XCTAssertEqual(claim.best, vector.expect.best)
        }
    }

    private func detailCase(_ id: String) throws -> (FlareRedPacketDetailsView, String?, PluginViewClock) {
        let table = try vectors().detail
        let vector = try XCTUnwrap(table.cases.first { $0.id == id }, id)
        return (vector.details, vector.designatedName, PluginViewClock(nowMs: table.nowMs, utcOffsetMinutes: table.utcOffsetMinutes))
    }

    @MainActor
    private func detailPage(_ id: String, claims: [FlareRedPacketClaim] = [], title: String? = nil,
                            onBack: (() -> Void)? = nil) throws -> RedPacketDetailView {
        let (details, name, clock) = try detailCase(id)
        return RedPacketDetailView(senderName: "Cy", senderAvatar: nil, details: details, designatedName: name,
                                   claims: claims, title: title, onBack: onBack, clock: clock)
    }

    @MainActor
    func testTheClaimersPageShowsTheirAmountTheClaimsAndTheBestLuck() throws {
        let claims = [
            FlareRedPacketClaim(id: "u1", name: "Ann", amountMinor: "230", claimedAtMs: 1_792_632_660_000),
            FlareRedPacketClaim(id: "u2", name: "Bo", amountMinor: "412", claimedAtMs: 1_792_632_700_000, best: true),
        ]
        let view = try detailPage("claimer-completed", claims: claims).inspect()
        for text in [zh.packetFromSender("Cy"), zh.packetBadgeLucky, "恭喜发财，大吉大利", "¥2.30", zh.packetDeposited,
                     "已领取 5/5 个", "Ann", "Bo", "09:31", "¥4.12"] {
            XCTAssertNoThrow(try view.find(text: text), text)
        }
        XCTAssertEqual(view.findAll(ViewType.Text.self, where: { try $0.string() == self.zh.packetBestLuck }).count, 1)
        XCTAssertThrowsError(try view.find(text: zh.packetNoClaims))
    }

    @MainActor
    func testANonDesignatedViewerSeesOnlyWhoMayOpenIt() throws {
        let claims = [FlareRedPacketClaim(id: "u1", name: "Ann", amountMinor: "230", claimedAtMs: 1_792_632_660_000)]
        let view = try detailPage("ineligible-named", claims: claims).inspect()
        XCTAssertNoThrow(try view.find(text: "仅 Bob 可领取"))
        XCTAssertThrowsError(try view.find(text: "Ann"), "no claim list unless the server lists it")
        XCTAssertThrowsError(try view.find(text: zh.packetDeposited))
        let texts = view.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        XCTAssertFalse(texts.contains { $0.contains("¥") }, "no amount reached this viewer: \(texts)")
    }

    @MainActor
    func testTheSendersPageShowsTheTotalsAndTheRefundLine() throws {
        let view = try detailPage("sender-expired").inspect()
        XCTAssertNoThrow(try view.find(text: "已领取 2/5 个，共 ¥3.88/¥10.00"))
        XCTAssertNoThrow(try view.find(text: "已退回 ¥6.12 · 09:00"))
        XCTAssertNoThrow(try view.find(text: zh.packetNoClaims), "a listed but empty claim list says so")
    }

    @MainActor
    func testDetailsDrawTheirOwnTitleBarOnlyWithAWayBack() throws {
        var backs = 0
        let plain = try detailPage("sender-open").inspect()
        XCTAssertThrowsError(try plain.find(text: zh.packetDetailTitle))
        let barred = try detailPage("sender-open", onBack: { backs += 1 }).inspect()
        XCTAssertNoThrow(try barred.find(text: zh.packetDetailTitle))
        try barred.find(ViewType.Button.self, where: { (try? $0.accessibilityLabel().string()) == self.zh.back }).tap()
        XCTAssertEqual(backs, 1)
        let titled = try detailPage("sender-open", title: "Details", onBack: {}).inspect()
        XCTAssertNoThrow(try titled.find(text: "Details"))
    }

    // MARK: Composer

    func testAmountLabelFollowsTheKind() {
        typealias Composer = RedPacketComposerView<EmptyView>
        let group = FlareRedPacketKind.allCases
        XCTAssertEqual(Composer.amountLabel(kind: .lucky, kinds: group, strings: zh), zh.packetFieldTotal)
        XCTAssertEqual(Composer.amountLabel(kind: .normal, kinds: group, strings: zh), zh.packetFieldEach)
        XCTAssertEqual(Composer.amountLabel(kind: .normal, kinds: [.normal], strings: zh), zh.packetFieldAmount)
        XCTAssertEqual(Composer.amountLabel(kind: .exclusive, kinds: group, strings: zh), zh.packetFieldAmount)
        XCTAssertEqual(Composer.shownKind(.lucky, kinds: [.normal]), .normal, "a kind not offered shows as the first")
        XCTAssertEqual(Composer.shownKind(.exclusive, kinds: FlareRedPacketKind.allCases), .exclusive)
    }

    @MainActor
    func testDirectChatComposerHasOnlyTheAmountGreetingAndSubmit() throws {
        var submits = 0
        let view = try RedPacketComposerView(kinds: [.normal], kind: .normal, amount: "", total: "¥0.00",
                                             onAmountChange: { _ in }, onCountChange: { _ in },
                                             onSubmit: { submits += 1 }).inspect()
        XCTAssertThrowsError(try view.find(SegmentedControlView.self), "one kind needs no switch")
        XCTAssertNoThrow(try view.find(text: zh.packetFieldAmount))
        XCTAssertThrowsError(try view.find(text: zh.packetFieldEach))
        XCTAssertThrowsError(try view.find(text: zh.packetFieldCount), "a direct chat's packet has one share")
        XCTAssertThrowsError(try view.find(text: zh.packetFieldRecipient))
        XCTAssertNoThrow(try view.find(text: zh.packetDefaultGreeting))
        XCTAssertNoThrow(try view.find(text: "¥0.00"))
        try view.find(button: zh.packetSubmit).tap()
        XCTAssertEqual(submits, 1)
    }

    @MainActor
    func testGroupComposerSwitchesKindsAndShowsTheirRows() throws {
        var picked: [FlareRedPacketKind] = []
        let lucky = try RedPacketComposerView(kinds: FlareRedPacketKind.allCases, kind: .lucky, amount: "5",
                                              count: 3, total: "¥5.00", onKindChange: { picked.append($0) },
                                              onCountChange: { _ in }).inspect()
        let switcher = try lucky.find(SegmentedControlView.self)
        XCTAssertEqual(try switcher.accessibilityLabel().string(), zh.packetKindPicker)
        XCTAssertNoThrow(try lucky.find(text: zh.packetFieldTotal))
        XCTAssertNoThrow(try lucky.find(text: zh.packetFieldCount))
        XCTAssertThrowsError(try lucky.find(text: "Picker"))
        let segments = switcher.findAll(ViewType.Button.self)
        XCTAssertEqual(segments.count, 3)
        try segments[2].tap()
        try segments[0].tap()
        XCTAssertEqual(picked, [.exclusive], "the current kind is not reported again")

        let exclusive = try RedPacketComposerView(kinds: FlareRedPacketKind.allCases, kind: .exclusive, amount: "",
                                                  total: "¥0.00") {
            Text("Picker")
        }.inspect()
        XCTAssertNoThrow(try exclusive.find(text: zh.packetFieldRecipient))
        XCTAssertNoThrow(try exclusive.find(text: "Picker"))
        XCTAssertThrowsError(try exclusive.find(text: zh.packetFieldCount))
    }

    @MainActor
    func testGreetingChangesGoToTheHost() throws {
        var greetings: [String] = []
        let view = try RedPacketComposerView(kinds: [.normal], kind: .normal, amount: "1", greeting: "",
                                             total: "¥1.00", onGreetingChange: { greetings.append($0) }).inspect()
        let field = try view.find(ViewType.TextField.self, where: {
            (try? $0.accessibilityLabel().string()) == self.zh.packetGreetingLabel
        })
        try field.setInput("Hi")
        XCTAssertEqual(greetings, ["Hi"])
    }

    @MainActor
    func testBusyComposerShowsErrorAndTakesNoSubmit() throws {
        var submits = 0
        let view = try RedPacketComposerView(kinds: [.normal], kind: .normal, amount: "1", total: "¥1.00",
                                             error: "Too much", busy: true, submitLabel: "Send",
                                             onSubmit: { submits += 1 }).inspect()
        XCTAssertNoThrow(try view.find(text: "Too much"))
        let submit = try view.find(button: "Send")
        XCTAssertTrue(submit.isDisabled())
        XCTAssertThrowsError(try submit.tap())
        XCTAssertEqual(submits, 0)
    }

    @MainActor
    func testALockedComposerIsReadOnlyWithoutProgress() throws {
        var submits = 0
        let view = try RedPacketComposerView(kinds: FlareRedPacketKind.allCases, kind: .lucky, amount: "5", count: 3,
                                             total: "¥5.00", locked: true, onCountChange: { _ in },
                                             onSubmit: { submits += 1 }).inspect()
        let submit = try view.find(button: zh.packetSubmit)
        XCTAssertTrue(submit.isDisabled())
        XCTAssertThrowsError(try submit.tap())
        XCTAssertThrowsError(try view.find(ViewType.ProgressView.self), "locked is not busy: no progress")
        XCTAssertEqual(submits, 0)
    }

    @MainActor
    func testTheKindSwitchMarksTheChosenKindInTheRedPacketAccent() throws {
        let control = try SegmentedControlView(options: ["A", "B"], selectedIndex: 0, accent: .red).inspect()
        XCTAssertEqual(try control.find(text: "A").attributes().foregroundColor(), .red)
        XCTAssertNotEqual(try control.find(text: "B").attributes().foregroundColor(), .red)
        let plain = try SegmentedControlView(options: ["A", "B"], selectedIndex: 0).inspect()
        XCTAssertEqual(try plain.find(text: "A").attributes().foregroundColor(),
                       FlareColors.of(.light, brand: .violet).primaryText)
    }

    // MARK: Pay confirm

    @MainActor
    func testPayConfirmNeedsEnoughBalance() throws {
        var events: [String] = []
        let view = try RedPacketPayConfirmView(amount: "¥5.00", methodLabel: "Wallet (¥3.00)", insufficient: true,
                                               onConfirm: { events.append("confirm") },
                                               onCancel: { events.append("cancel") }).inspect()
        XCTAssertNoThrow(try view.find(text: "¥5.00"))
        XCTAssertNoThrow(try view.find(text: "Wallet (¥3.00)"))
        XCTAssertNoThrow(try view.find(text: zh.packetInsufficient))
        let confirm = try view.find(button: zh.packetPayConfirm)
        XCTAssertTrue(confirm.isDisabled())
        XCTAssertThrowsError(try confirm.tap())
        try view.find(button: zh.cancel).tap()
        XCTAssertEqual(events, ["cancel"])
    }

    @MainActor
    func testPayConfirmConfirmsAndLocksWhileBusy() throws {
        var events: [String] = []
        let ready = try RedPacketPayConfirmView(amount: "¥5.00", methodLabel: "Wallet (¥30.00)",
                                                onConfirm: { events.append("confirm") }, onCancel: {}).inspect()
        XCTAssertThrowsError(try ready.find(text: zh.packetInsufficient))
        try ready.find(button: zh.packetPayConfirm).tap()
        XCTAssertEqual(events, ["confirm"])
        let busy = try RedPacketPayConfirmView(amount: "¥5.00", methodLabel: "Wallet", busy: true,
                                               onConfirm: { events.append("again") },
                                               onCancel: { events.append("cancel") }).inspect()
        for label in [zh.packetPayConfirm, zh.cancel] {
            let button = try busy.find(button: label)
            XCTAssertTrue(button.isDisabled(), label)
            XCTAssertThrowsError(try button.tap(), label)
        }
        XCTAssertEqual(try busy.find(button: zh.packetPayConfirm).accessibilityValue().string(), zh.packetBusy)
        XCTAssertEqual(events, ["confirm"])
        XCTAssertTrue(RedPacketPayConfirmView.confirmEnabled(insufficient: false, busy: false, handled: true))
        XCTAssertFalse(RedPacketPayConfirmView.confirmEnabled(insufficient: true, busy: false, handled: true))
        XCTAssertFalse(RedPacketPayConfirmView.confirmEnabled(insufficient: false, busy: true, handled: true))
    }

    // MARK: Copy

    func testEnglishPresetCoversTheFamily() {
        XCTAssertEqual(zh.packetFromSender("Ann"), "Ann的红包")
        XCTAssertEqual(en.packetFromSender("Ann"), "Red packet from Ann")
        XCTAssertEqual(en.packetStateClaimed, "Opened")
        XCTAssertEqual(en.packetSubmit, "Put money in")
        XCTAssertEqual(en.packetInsufficient, "Insufficient balance")
        // Every field of the family has its own English copy.
        let pairs: [(String, String)] = [
            (zh.packetStateExpired, en.packetStateExpired), (zh.packetKindLucky, en.packetKindLucky),
            (zh.packetOpenAction, en.packetOpenAction), (zh.packetMissed, en.packetMissed),
            (zh.packetViewDetails, en.packetViewDetails), (zh.packetBestLuck, en.packetBestLuck),
            (zh.packetNoClaims, en.packetNoClaims), (zh.packetFieldEach, en.packetFieldEach),
            (zh.packetDefaultGreeting, en.packetDefaultGreeting), (zh.packetPayTitle, en.packetPayTitle),
            (zh.packetView, en.packetView), (zh.packetRefunded, en.packetRefunded),
            (zh.packetBadgeLucky, en.packetBadgeLucky), (zh.packetBadgeExclusive, en.packetBadgeExclusive),
            (zh.packetDeposited, en.packetDeposited), (zh.packetSummaryCount, en.packetSummaryCount),
        ]
        for (chinese, english) in pairs { XCTAssertNotEqual(chinese, english) }
    }

    #if os(macOS)
    // MARK: Hosted

    @MainActor
    func testCardsRenderEveryStateInsideTheCardWidth() throws {
        var images: [FlareRedPacketCardState: Data] = [:]
        for state in FlareRedPacketCardState.allCases {
            for scheme in [ColorScheme.light, .dark] {
                let view = RedPacketCardView(blessing: String(repeating: "恭喜发财 ", count: 8), kind: .exclusive,
                                             recipientName: "Bob", state: state, onOpen: {})
                    .frame(width: 390).environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 1
                let image = try XCTUnwrap(renderer.cgImage)
                XCTAssertGreaterThanOrEqual(image.height, Int(FlareSizes.touchTarget))
                if scheme == .light { images[state] = try XCTUnwrap(image.dataProvider?.data) as Data }
            }
        }
        XCTAssertNotEqual(images[.unopened], images[.expired], "a past packet is drawn faded")
    }

    /// A busy or unavailable card is drawn exactly like an open one showing the same status: no system dimming.
    @MainActor
    func testInertCardsKeepTheirColours() throws {
        func pixels<V: View>(_ view: V) throws -> Data {
            let renderer = ImageRenderer(content: view.frame(width: 300))
            renderer.scale = 1
            return try XCTUnwrap(try XCTUnwrap(renderer.cgImage).dataProvider?.data) as Data
        }
        XCTAssertEqual(try pixels(RedPacketCardView(blessing: "Hello", busy: true, onOpen: {})),
                       try pixels(RedPacketCardView(blessing: "Hello", statusLabel: zh.packetBusy, onOpen: {})))
        XCTAssertEqual(try pixels(RedPacketCardView(blessing: "Hello", disabled: true, onOpen: {})),
                       try pixels(RedPacketCardView(blessing: "Hello", statusLabel: zh.packetUnavailable, onOpen: {})))
    }

    /// A type registered as a card draws its own shell with nothing around it; an unregistered unknown type keeps the
    /// bubble's padding; a custom body is a card without registering.
    @MainActor
    func testARegisteredCardBodyLosesTheBubbleAndAnUnregisteredOneKeepsIt() throws {
        final class Edges { var left: [String: CGFloat] = [:] }
        let edges = Edges()
        let body: FlareContentBuilder = { content, _ in
            let label = (content as? FlareGenericContent)?.label ?? ""
            return AnyView(GeometryReader { proxy in
                let _ = { edges.left[label] = proxy.frame(in: .global).minX }()
                Color.red
            }.frame(width: 120, height: 60))
        }
        func bubble(_ label: String, type: String = "redpacket") -> MessageBubbleView {
            MessageBubbleView(message: FlareMessageData(id: label, senderId: "u1", senderName: "Ann",
                                                        content: FlareGenericContent(contentType: type, label: label)),
                              currentUserId: "me")
        }
        let page = VStack(spacing: 0) {
            bubble("card").flareContentRenderers(["redpacket": body], surfaces: ["redpacket": .card])
            bubble("framed").flareContentRenderers(["redpacket": body])
            bubble("custom", type: "custom").flareContentRenderers(["custom": body])
        }.frame(width: 390)
        _ = ImageRenderer(content: page).cgImage
        let card = try XCTUnwrap(edges.left["card"]), framed = try XCTUnwrap(edges.left["framed"])
        XCTAssertEqual(framed - card, FlareSizes.componentBubblePaddingX, accuracy: 0.5)
        XCTAssertEqual(try XCTUnwrap(edges.left["custom"]), card, accuracy: 0.5, "a custom body is a card")
        XCTAssertEqual(bubbleMessage("x").surface(registry: ["redpacket": .card]), .card)
        XCTAssertEqual(bubbleMessage("x").surface(), .bubble)
    }

    /// A custom renderer in a list hears the message's core id (the server's before the client's) and the conversation.
    @MainActor
    func testACustomRendererKnowsItsMessageAndConversation() {
        final class Seen { var contexts: [FlareContentContext] = [] }
        let seen = Seen()
        let body: FlareContentBuilder = { _, ctx in
            seen.contexts.append(ctx)
            return AnyView(Text("Packet"))
        }
        let rows = VStack {
            MessageBubbleView(message: FlareMessageData(id: "client-1", senderId: "u1", senderName: "Ann",
                                                        content: FlareGenericContent(contentType: "redpacket", label: "P"),
                                                        serverId: "server-1"), currentUserId: "me")
            MessageBubbleView(message: FlareMessageData(id: "client-2", senderId: "u1", senderName: "Ann",
                                                        content: FlareGenericContent(contentType: "redpacket", label: "P")),
                              currentUserId: "me")
        }
        .environment(\.flareMessageConversationId, "conv-1")
        .flareContentRenderers(["redpacket": body])
        _ = ImageRenderer(content: rows.frame(width: 390)).cgImage
        XCTAssertEqual(Set(seen.contexts.compactMap(\.messageId)), ["server-1", "client-2"])
        XCTAssertEqual(Set(seen.contexts.compactMap(\.conversationId)), ["conv-1"])
    }

    private func bubbleMessage(_ id: String) -> FlareMessageData {
        FlareMessageData(id: id, senderId: "u1", senderName: "Ann",
                         content: FlareGenericContent(contentType: "redpacket", label: "P"))
    }

    /// Hosts `view` in a borderless window and clicks at `point` (top-left origin).
    @MainActor
    private func click<V: View>(_ view: V, size: CGSize, at point: CGPoint) {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let location = NSPoint(x: point.x, y: size.height - point.y)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            guard let event = NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
                                                 timestamp: ProcessInfo.processInfo.systemUptime,
                                                 windowNumber: window.windowNumber, context: nil,
                                                 eventNumber: 0, clickCount: 1, pressure: 1) else { return }
            window.sendEvent(event)
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

    /// The layer is laid out deterministically for a short blessing: the envelope at its minimum height, the gap,
    /// then the 44pt close target, centred in the window.
    @MainActor
    func testHostedSheetClosesFromTheScrimAndTheCloseTargetButNotTheEnvelope() {
        final class Log { var events: [String] = [] }
        let size = CGSize(width: 390, height: 760)
        let layer = FlareSizes.componentRedPacketEnvelopeMinHeight + FlareSizes.spacingXl + FlareSizes.touchTargetMin
        let top = (size.height - layer) / 2
        let closeCentre = CGPoint(x: size.width / 2,
                                  y: top + FlareSizes.componentRedPacketEnvelopeMinHeight + FlareSizes.spacingXl
                                      + FlareSizes.touchTargetMin / 2)
        let coinCentre = CGPoint(x: size.width / 2,
                                 y: top + FlareSizes.componentRedPacketEnvelopeMinHeight * RedPacketMetrics.flapShare)
        func sheet(_ log: Log) -> RedPacketOpenSheet {
            RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", onOpen: { log.events.append("open") },
                               onClose: { log.events.append("close") })
        }
        let points: [(CGPoint, [String], String)] = [
            (CGPoint(x: 8, y: 8), ["close"], "the scrim"),
            (closeCentre, ["close"], "the close ring"),
            // The ring is drawn at 32pt; its target is 44pt.
            (CGPoint(x: closeCentre.x + 20, y: closeCentre.y), ["close"], "beside the ring, inside its target"),
            (CGPoint(x: size.width / 2, y: top + 24), [], "the envelope's flap"),
            (coinCentre, ["open"], "the open button on the flap's edge"),
            (CGPoint(x: coinCentre.x, y: coinCentre.y + FlareSizes.componentRedPacketOpenButtonSize / 2 - 6),
             ["open"], "the button's lower half, over the envelope's body"),
        ]
        for (point, expected, place) in points {
            let log = Log()
            click(sheet(log), size: size, at: point)
            XCTAssertEqual(log.events, expected, place)
        }
    }

    @MainActor
    func testHostedSegmentsTakeTapsAcrossTheTouchTarget() {
        final class Picked { var index: Int? }
        let size = CGSize(width: 300, height: 120)
        for dy: CGFloat in [-20, 0, 20] {
            let picked = Picked()
            let control = SegmentedControlView(options: ["A", "B"], selectedIndex: 0, onSelect: { picked.index = $0 })
            click(control, size: size, at: CGPoint(x: size.width * 0.75, y: size.height / 2 + dy))
            XCTAssertEqual(picked.index, 1, "dy \(dy)")
        }
    }
    #endif
}
