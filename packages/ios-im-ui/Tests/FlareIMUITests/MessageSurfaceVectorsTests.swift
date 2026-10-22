import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The message surface, meta placement, receipt and grouping rules against the tables the four kits run
/// (`spec/message-surface-vectors.json`, `message-meta-placement-vectors.json`, `message-receipt-vectors.json`,
/// `message-grouping-vectors.json`), and the drawn rows that follow from them.
final class MessageSurfaceVectorsTests: XCTestCase {
    private let zh = FlareStrings()
    private let en = FlareStrings.english

    private func table(_ name: String) throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/\(name)"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    private func string(_ value: PluginJSONValue?) -> String? { value?.stringValue }
    private func bool(_ value: PluginJSONValue?) -> Bool { value?.boolValue ?? false }
    private func int(_ value: PluginJSONValue?) -> Int? { value?.numberValue.map { Int($0) } }

    // MARK: Surface (C1)

    func testSurfaceFollowsTheSharedTable() throws {
        let table = try table("message-surface-vectors.json")
        XCTAssertEqual((table["surfaces"]?.arrayValue ?? []).compactMap(\.stringValue),
                       FlareMessageSurface.allCases.map(\.rawValue))
        let cases = table["cases"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 43, "the shared table lost cases")
        for vector in cases {
            let id = string(vector["id"]) ?? "?"
            let input = vector["input"] ?? .null
            let registered = try string(input["registered"]).map {
                try XCTUnwrap(FlareMessageRegisteredSurface(rawValue: $0), id)
            }
            let facts = FlareMessageSurfaceInput(
                contentType: string(input["contentType"]) ?? "", subtype: string(input["subtype"]),
                hasQuote: bool(input["hasQuote"]), hasCaption: bool(input["hasCaption"]),
                loneEmoji: bool(input["loneEmoji"]), recalled: bool(input["recalled"]), deleted: bool(input["deleted"]),
                registered: registered)
            XCTAssertEqual(flareMessageSurface(facts).rawValue, string(vector["surface"]), id)
        }
        // The defaults table and the kit's own content all land where the table puts them.
        for (surface, types) in table["defaults"]?.objectValue ?? [:] {
            for type in (types.arrayValue ?? []).compactMap(\.stringValue) {
                XCTAssertEqual(flareMessageSurface(FlareMessageSurfaceInput(contentType: type)).rawValue, surface, type)
            }
        }
    }

    func testTheKitsContentTypesAndWireSpellingsMapOntoTheTable() {
        func surface(_ content: FlareMessageContent, quote: Bool = false, lifecycle: FlareMessageLifecycle? = nil,
                     registry: [String: FlareMessageRegisteredSurface] = [:]) -> FlareMessageSurface {
            FlareMessageData(id: "m", senderId: "u", senderName: "U", content: content, lifecycle: lifecycle,
                             replyTo: quote ? FlareReplyTarget(senderName: "A", summary: "x", messageId: "q") : nil)
                .surface(registry: registry)
        }
        XCTAssertEqual(surface(FlareTextContent("hi")), .bubble)
        XCTAssertEqual(surface(FlareTextContent("👍")), .bareMedia, "a lone emoji is bare")
        XCTAssertEqual(surface(FlareTextContent("👍 ok")), .bubble)
        XCTAssertEqual(surface(FlareTextContent("👍"), quote: true), .bubble)
        XCTAssertEqual(surface(FlareTextContent("1")), .bubble, "a digit is text, not an emoji")
        XCTAssertEqual(surface(FlareImageContent(url: "u")), .bareMedia)
        XCTAssertEqual(surface(FlareVideoContent(url: "u")), .bareMedia)
        XCTAssertEqual(surface(FlareImageGroupContent(images: [])), .bubble)
        XCTAssertEqual(surface(FlareLocationContent(name: "西湖")), .card)
        XCTAssertEqual(surface(FlareCardContent(title: "Ann")), .card)
        XCTAssertEqual(surface(FlareLinkCardContent(url: "https://a.b", title: "t")), .card)
        XCTAssertEqual(surface(FlarePollContent(id: "p", title: "t")), .card)
        XCTAssertEqual(surface(FlareTaskContent(id: "t", title: "t")), .card)
        XCTAssertEqual(surface(FlareCalendarContent(id: "c", title: "t")), .card)
        XCTAssertEqual(surface(FlareMiniAppContent(appId: "a", title: "t")), .card)
        XCTAssertEqual(surface(FlareAnnouncementContent(id: "a", title: "t")), .card)
        XCTAssertEqual(surface(FlareGenericContent(contentType: "merged_forward", label: "l")), .card)
        XCTAssertEqual(surface(FlareGenericContent(contentType: "rich_text", label: "l")), .bubble)
        XCTAssertEqual(surface(FlareGenericContent(contentType: "custom", label: "l", subtype: "flare.plugin.message.v1")),
                       .card, "every plugin card is a card without registering")
        XCTAssertEqual(surface(FlareNotificationContent("x")), .centered)
        XCTAssertEqual(surface(FlareTextContent("x"), lifecycle: FlareMessageLifecycle(mutation: .deleted)), .centered)
        XCTAssertEqual(surface(FlareTextContent("x"), lifecycle: FlareMessageLifecycle(mutation: .recalled)), .centered)
        // A registration under type:subtype wins over one under the type.
        let gif = FlareGenericContent(contentType: "custom", label: "l", subtype: "acme.gif")
        XCTAssertEqual(surface(gif, registry: ["custom:acme.gif": .bareMedia, "custom": .card]), .bareMedia)
        XCTAssertEqual(surface(gif, quote: true, registry: ["custom:acme.gif": .bareMedia]), .bubble)
        XCTAssertEqual(surface(FlareGenericContent(contentType: "hologram", label: "l")), .bubble)
        XCTAssertEqual(surface(FlareGenericContent(contentType: "hologram", label: "l"), registry: ["hologram": .card]), .card)
    }

    // MARK: Meta placement (C2)

    func testMetaPlacementToneAndRetryFollowTheSharedTable() throws {
        let table = try table("message-meta-placement-vectors.json")
        XCTAssertEqual((table["placements"]?.arrayValue ?? []).compactMap(\.stringValue),
                       FlareMessageMetaPlacement.allCases.map(\.rawValue))
        let cases = table["cases"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 17)
        for vector in cases {
            let id = string(vector["id"]) ?? "?"
            let surface = try XCTUnwrap(FlareMessageSurface(rawValue: string(vector["surface"]) ?? ""), id)
            let status = try XCTUnwrap(FlareMessageDeliveryStatus(rawValue: string(vector["status"]) ?? ""), id)
            let isSelf = bool(vector["self"])
            let placement = flareMessageMetaPlacement(surface: surface, contentType: string(vector["contentType"]) ?? "")
            let expect = vector["expect"] ?? .null
            XCTAssertEqual(placement.rawValue, string(expect["placement"]), "\(id) placement")
            XCTAssertEqual(flareMessageMetaTone(placement: placement, isSelf: isSelf, status: status).rawValue,
                           string(expect["tone"]), "\(id) tone")
            XCTAssertEqual(flareMessageRetryForm(placement: placement, isSelf: isSelf, status: status)?.rawValue,
                           string(expect["retry"]), "\(id) retry")
        }
        XCTAssertEqual(zh.messageSendFailedRetry, "发送失败，重试")
    }

    // MARK: Receipt (C3)

    func testReceiptFollowsTheSharedTable() throws {
        let table = try table("message-receipt-vectors.json")
        XCTAssertEqual((table["statuses"]?.arrayValue ?? []).compactMap(\.stringValue),
                       FlareMessageDeliveryStatus.allCases.map(\.rawValue), "five states, no delivered")
        for (status, glyph) in table["glyphs"]?.objectValue ?? [:] {
            let state = try XCTUnwrap(FlareMessageDeliveryStatus(rawValue: status), status)
            XCTAssertEqual(flareMessageReceiptGlyph(state).rawValue, glyph.stringValue, status)
        }
        let cases = table["cases"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 14)
        for vector in cases {
            let id = string(vector["id"]) ?? "?"
            let receipt = flareMessageReceiptPresentation(
                conversationKind: try XCTUnwrap(FlareConversationKind(rawValue: string(vector["conversationKind"]) ?? ""), id),
                isSelf: bool(vector["self"]),
                status: try XCTUnwrap(FlareMessageDeliveryStatus(rawValue: string(vector["status"]) ?? ""), id),
                readSummary: readSummary(vector["readSummary"]))
            let expect = vector["expect"] ?? .null
            XCTAssertEqual(receipt.glyph?.rawValue, string(expect["glyph"]), "\(id) glyph")
            let summary = expect["summary"]
            if let summary, summary != .null {
                let line = try XCTUnwrap(receipt.summary, id)
                XCTAssertEqual(line.allRead, bool(summary["allRead"]), id)
                XCTAssertEqual(line.count, int(summary["count"]), id)
                XCTAssertEqual(line.text(zh), string(summary["zh"]), "\(id) zh")
                XCTAssertEqual(line.text(en), string(summary["en"]), "\(id) en")
            } else {
                XCTAssertNil(receipt.summary, id)
            }
        }
    }

    private func readSummary(_ value: PluginJSONValue?) -> FlareMessageReadSummary? {
        guard let value, value != .null else { return nil }
        return FlareMessageReadSummary(readCount: int(value["readCount"]) ?? 0,
                                       unreadCount: int(value["unreadCount"]) ?? 0, total: int(value["total"]) ?? 0)
    }

    func testTheRowsReadingUnitFollowsTheSharedTable() throws {
        let cases = try table("message-receipt-vectors.json")["accessibility"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 5)
        for vector in cases {
            let id = string(vector["id"]) ?? "?"
            let locale = string(vector["locale"]) ?? "zh-CN"
            let strings = locale.hasPrefix("zh") ? zh : en
            let label = flareMessageAccessibilityLabel(
                sender: string(vector["sender"]) ?? "", preview: string(vector["preview"]) ?? "",
                time: string(vector["time"]) ?? "", isSelf: bool(vector["self"]),
                status: try XCTUnwrap(FlareMessageDeliveryStatus(rawValue: string(vector["status"]) ?? ""), id),
                conversationKind: FlareConversationKind(rawValue: string(vector["conversationKind"]) ?? "") ?? .single,
                readSummary: readSummary(vector["readSummary"]), strings: strings,
                locale: Locale(identifier: locale))
            XCTAssertEqual(label, string(vector["expect"]), id)
        }
        // The bubble builds its label from its message: sender, the preview, the time, the status.
        let message = FlareMessageData(id: "m", senderId: "me", senderName: "我", content: FlareTextContent("好的"),
                                       timeLabel: "09:06", status: .read)
        XCTAssertEqual(MessageBubbleView.accessibilityLabel(message, isSelf: true, conversationKind: .single, strings: zh,
                                                            locale: Locale(identifier: "zh_CN")), "我，好的，09:06，已读")
    }

    func testTheRowsActionsAreReplyTheMenuAndRetryWhileFailed() {
        var log: [String] = []
        let failed = FlareMessageData(id: "m", senderId: "me", senderName: "我", content: FlareTextContent("x"), status: .failed)
        let actions = MessageListView.accessibilityActions(
            failed, currentUserId: "me", strings: zh, reply: { _ in log.append("reply") }, menu: { _ in log.append("menu") },
            resend: { _ in log.append("retry") })
        XCTAssertEqual(actions.map(\.kind), [.reply, .menu, .retry])
        XCTAssertEqual(actions.map(\.name), [zh.messageActionReply, zh.more, zh.messageSendFailedRetry])
        actions.forEach { $0.perform() }
        XCTAssertEqual(log, ["reply", "menu", "retry"])
        let sent = FlareMessageData(id: "n", senderId: "me", senderName: "我", content: FlareTextContent("x"))
        XCTAssertEqual(MessageListView.accessibilityActions(sent, currentUserId: "me", strings: zh, reply: nil,
                                                            menu: { _ in }, resend: { _ in }).map(\.kind), [.menu])
    }

    // MARK: Grouping (C4)

    func testGroupingAndDatePillsFollowTheSharedTable() throws {
        let table = try table("message-grouping-vectors.json")
        let now = Int64(table["nowMs"]?.numberValue ?? 0)
        let offset = int(table["utcOffsetMinutes"])
        let cases = table["cases"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 15)
        for vector in cases {
            let name = string(vector["name"]) ?? "?"
            let items = try (vector["messages"]?.arrayValue ?? []).map { message in
                FlareMessageGroupingItem(
                    id: string(message["id"]) ?? "", senderId: string(message["senderId"]) ?? "",
                    atMs: Int64(message["atMs"]?.numberValue ?? 0),
                    surface: try XCTUnwrap(FlareMessageSurface(rawValue: string(message["surface"]) ?? ""), name))
            }
            let options = vector["options"]
            let rows = flareTimelineRows(
                items, currentUserId: string(vector["currentUserId"]) ?? "",
                conversationKind: FlareConversationKind(rawValue: string(vector["conversationKind"]) ?? "") ?? .single,
                unreadFromId: string(vector["unreadFromId"]),
                options: FlareMessageGroupingOptions(showIncomingAvatar: options?["showIncomingAvatar"]?.boolValue ?? true,
                                                     showSelfAvatar: options?["showSelfAvatar"]?.boolValue ?? false),
                nowMs: now, utcOffsetMinutes: offset)
            let expected = vector["rows"]?.arrayValue ?? []
            XCTAssertEqual(rows.count, expected.count, "\(name) row count")
            for (row, want) in zip(rows, expected) {
                switch row {
                case .date(_, let label):
                    XCTAssertEqual("date", string(want["kind"]), name)
                    XCTAssertEqual(label.rawValue, string(want["label"]), "\(name) date label")
                case .unread(let count):
                    XCTAssertEqual("unread", string(want["kind"]), name)
                    XCTAssertEqual(count, int(want["count"]), "\(name) unread count")
                case .message(let index, let position, let presentation):
                    let id = items[index].id
                    XCTAssertEqual("message", string(want["kind"]), name)
                    XCTAssertEqual(id, string(want["id"]), name)
                    XCTAssertEqual(position.rawValue, string(want["position"]), "\(name) \(id) position")
                    XCTAssertEqual(presentation.showAvatar, bool(want["showAvatar"]), "\(name) \(id) avatar")
                    XCTAssertEqual(presentation.showSenderName, bool(want["showSenderName"]), "\(name) \(id) name")
                    XCTAssertEqual(presentation.reserveAvatarSpace, bool(want["reserveAvatarSpace"]), "\(name) \(id) gutter")
                    XCTAssertEqual(presentation.avatarPlacement.rawValue, string(want["avatarPlacement"]), "\(name) \(id) side")
                    XCTAssertEqual(presentation.tail, bool(want["tail"]), "\(name) \(id) tail")
                }
            }
        }
    }

    func testTheListGroupsByTheSurfacesItDraws() {
        let messages = [
            FlareMessageData(id: "a", senderId: "u1", senderName: "U", content: FlareTextContent("hi"), sentAtMs: 1_000),
            FlareMessageData(id: "b", senderId: "u1", senderName: "U", content: FlareGenericContent(contentType: "custom", label: "c"),
                             sentAtMs: 2_000),
            FlareMessageData(id: "c", senderId: "u1", senderName: "U", content: FlareGenericContent(contentType: "custom", label: "c"),
                             sentAtMs: 3_000),
        ]
        let layouts = MessageListView.rowLayouts(messages, currentUserId: "me", conversationKind: .group, unreadFromId: nil,
                                                 options: FlareMessageGroupingOptions(), surfaces: [:],
                                                 timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(layouts.map(\.surface), [.bubble, .card, .card])
        XCTAssertEqual(layouts.map(\.position), [.single, .first, .last], "a card breaks the bubble's run")
        XCTAssertEqual(layouts.map(\.presentation.tail), [true, false, false], "cards never draw a tail")
        XCTAssertEqual(layouts.map { $0.date != nil }, [true, false, false])
    }

    // MARK: Drawn rows

    private func message(_ content: FlareMessageContent, self own: Bool = true, status: FlareMessageDeliveryStatus = .sent,
                         lifecycle: FlareMessageLifecycle? = nil, readSummary: FlareMessageReadSummary? = nil) -> FlareMessageData {
        FlareMessageData(id: "m1", senderId: own ? "me" : "u2", senderName: own ? "我" : "Ivy", content: content,
                         timeLabel: "09:05", status: status, readSummary: readSummary, lifecycle: lifecycle)
    }

    @MainActor
    func testACardDrawsItsMetaBelowAndAFailedCardOffersTheRetryKey() throws {
        var resent = 0
        let bubble = MessageBubbleView(message: message(FlareLocationContent(name: "西湖"), status: .failed),
                                       currentUserId: "me", onResend: { _ in resent += 1 })
        XCTAssertEqual(bubble.surface, .card)
        XCTAssertEqual(bubble.metaPlacement, .below)
        let tree = try bubble.inspect()
        XCTAssertEqual(try tree.find(MessageMetaView.self).actualView().placement, .below)
        try tree.find(button: zh.messageSendFailedRetry).tap()
        XCTAssertEqual(resent, 1)
        // A text bubble keeps its meta inside, at the end of the last line.
        let text = MessageBubbleView(message: message(FlareTextContent("hello")), currentUserId: "me")
        XCTAssertEqual(text.metaPlacement, .inline)
        XCTAssertEqual(try text.inspect().find(MessageMetaView.self).actualView().placement, .inline)
        XCTAssertNoThrow(try text.inspect().find(text: "hello"), "the reservation is a run of its own, the text stays")
        let file = MessageBubbleView(message: message(FlareFileContent(name: "a.pdf", url: "u")), currentUserId: "me")
        XCTAssertEqual(file.metaPlacement, .bubbleFooter)
    }

    @MainActor
    func testTheReadSummaryReplacesTheCheckAndOpensTheReceiptList() throws {
        var opened: [String] = []
        let summary = FlareMessageReadSummary(readCount: 2, unreadCount: 3, total: 5)
        let group = MessageBubbleView(message: message(FlareTextContent("开会了"), readSummary: summary),
                                      currentUserId: "me", conversationKind: .group,
                                      onReadReceiptOpen: { opened.append($0.id) })
        let tree = try group.inspect()
        try tree.find(button: "3 人未读").tap()
        XCTAssertEqual(opened, ["m1"])
        XCTAssertThrowsError(try tree.find(MessageStatusView.self), "the summary replaces the check")
        // A single chat ignores a summary; without a listener the summary is plain text.
        let single = try MessageBubbleView(message: message(FlareTextContent("x"), readSummary: summary),
                                           currentUserId: "me").inspect()
        XCTAssertThrowsError(try single.find(text: "3 人未读"))
        let plain = try MessageBubbleView(message: message(FlareTextContent("x"), readSummary: summary), currentUserId: "me",
                                          conversationKind: .group).inspect()
        XCTAssertNoThrow(try plain.find(text: "3 人未读"))
        XCTAssertThrowsError(try plain.find(button: "3 人未读"))
    }

    @MainActor
    func testADeletedMessageIsTheCentredNotice() throws {
        let tree = try MessageBubbleView(message: message(FlareTextContent("secret"),
                                                          lifecycle: FlareMessageLifecycle(mutation: .deleted)),
                                         currentUserId: "me").inspect()
        XCTAssertNoThrow(try tree.find(text: zh.messageDeleted))
        XCTAssertThrowsError(try tree.find(text: "secret"))
        XCTAssertEqual(zh.messageDeleted, "消息已删除")
    }

    func testAFailedPictureRetriesInsteadOfOpening() {
        var log: [String] = []
        ImageMessageView.tap(failed: true, retry: { log.append("retry") }, onTap: { log.append("open") })?()
        ImageMessageView.tap(failed: false, retry: { log.append("retry") }, onTap: { log.append("open") })?()
        XCTAssertEqual(log, ["retry", "open"])
        XCTAssertNotNil(ImageMessageView.tap(failed: true, retry: {}, onTap: nil), "a failed picture retries even without a tap")
    }

    @MainActor
    func testMultiSelectMakesTheContentInert() throws {
        var voted = 0
        let body = MessageContentView(content: FlarePollContent(id: "p", title: "去哪", options: ["A", "B"]),
                                      onVote: { _ in voted += 1 }, selectionMode: true)
        XCTAssertThrowsError(try body.inspect().find(button: "A"), "no option is a control in multi-select")
        let live = MessageContentView(content: FlarePollContent(id: "p", title: "去哪", options: ["A", "B"]),
                                      onVote: { _ in voted += 1 })
        try live.inspect().find(button: "A").tap()
        XCTAssertEqual(voted, 1)
        var opened = 0
        let card = MessageContentView(content: FlareCardContent(title: "Ann", userId: "u9"),
                                      onCardOpen: { _ in opened += 1 }, selectionMode: true)
        XCTAssertThrowsError(try card.inspect().find(ViewType.Button.self), "a contact card is not a control either")
        XCTAssertEqual(opened, 0)
    }

    @MainActor
    func testACustomRendererHearsTheSelectionModeAndTheSurface() {
        final class Seen { var contexts: [FlareContentContext] = [] }
        let seen = Seen()
        let body: FlareContentBuilder = { _, ctx in seen.contexts.append(ctx); return AnyView(Text("Card")) }
        let rows = VStack {
            MessageBubbleView(message: FlareMessageData(id: "a", senderId: "u1", senderName: "Ann",
                                                        content: FlareGenericContent(contentType: "custom", label: "P")),
                              currentUserId: "me", multiSelectMode: true)
        }
        .flareContentRenderers(["custom": body])
        _ = ImageRenderer(content: rows.frame(width: 390)).cgImage
        XCTAssertEqual(seen.contexts.map(\.selectionMode), [true])
        XCTAssertEqual(seen.contexts.map(\.surface), [.card])
    }

    /// The failed glyph sits on the failure surface, never on the outgoing fill: at least 3:1 (WCAG 1.4.11) in every
    /// brand and mode. On the outgoing fill it was about 1.5:1.
    func testTheFailedGlyphKeepsItsContrastOnTheFailureSurface() {
        for brand in FlareBrandTheme.allCases {
            for scheme in [ColorScheme.light, .dark] {
                let colors = FlareColors.of(scheme, brand: brand)
                XCTAssertGreaterThanOrEqual(RedPacketPalette.contrast(colors.messageStatusFailed, colors.messageFailedBackground),
                                            3, "\(brand) \(scheme)")
                XCTAssertGreaterThanOrEqual(RedPacketPalette.contrast(colors.messageFailedForeground, colors.messageFailedBackground),
                                            4.5, "\(brand) \(scheme) text")
            }
        }
    }

    func testThePointerMenuIsTheLongPressSheetsMenu() {
        let entries = messageMenuActions(FlareMessageActionAvailability(canReply: true, canForward: true, canDelete: true,
                                                                        canPin: true), strings: zh)
        let sections = FlareMessageContextMenu.sections(entries)
        XCTAssertEqual(sections.map { $0.map(\.id) }, messageMenuGroups(entries).map { $0.map(\.id) },
                       "the same entries, groups and order as the sheet")
        XCTAssertEqual(sections.last?.map(\.id), ["delete"])
        XCTAssertEqual(FlareMessageContextMenu.role(sections.last![0]), .destructive)
        XCTAssertNil(FlareMessageContextMenu.role(sections[0][0]))
        #if os(macOS)
        XCTAssertTrue(FlareMessageContextMenu.pointerIdiom, "macOS is a pointer")
        #endif
        XCTAssertFalse(FlareMessageContextMenu.longPressOpensSheet(pointerMenu: true), "the pointer menu takes the long press")
        XCTAssertTrue(FlareMessageContextMenu.longPressOpensSheet(pointerMenu: false))
        var chosen: [String] = []
        let menu = FlareMessageContextMenu(entries: { _ in entries }, perform: { _, id in chosen.append(id) })
        menu.perform(FlareMessageData(id: "m", senderId: "u", senderName: "U", content: FlareTextContent("x")), "reply")
        XCTAssertEqual(chosen, ["reply"])
    }

    #if os(macOS)
    // MARK: Hosted

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

    /// The failed glyph draws at 12pt; its retry target is the 44pt square around it.
    @MainActor
    func testTheRetryGlyphTakesTapsAcrossTheTouchTarget() {
        final class Count { var value = 0 }
        let size = CGSize(width: 200, height: 120)
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let reach = FlareSizes.touchTargetMin / 2 - 2
        for offset in [CGPoint.zero, CGPoint(x: reach, y: 0), CGPoint(x: 0, y: reach), CGPoint(x: -reach, y: -reach)] {
            let count = Count()
            click(MessageStatusView(status: .failed, variant: .compact, onResend: { count.value += 1 }), size: size,
                  at: CGPoint(x: centre.x + offset.x, y: centre.y + offset.y))
            XCTAssertEqual(count.value, 1, "offset \(offset)")
        }
        let outside = Count()
        click(MessageStatusView(status: .failed, variant: .compact, onResend: { outside.value += 1 }), size: size,
              at: CGPoint(x: centre.x + FlareSizes.touchTargetMin, y: centre.y))
        XCTAssertEqual(outside.value, 0, "beyond the target nothing retries")
    }

    /// The text key under a failed card and the read summary both take taps 20pt above and below their line.
    @MainActor
    func testTheMetaKeysTakeTapsAcrossTheTouchTarget() {
        final class Count { var value = 0 }
        let size = CGSize(width: 260, height: 120)
        for dy: CGFloat in [-18, 0, 18] {
            let resent = Count(), opened = Count()
            click(MessageMetaView(timestamp: "09:05", status: .failed, placement: .below,
                                  onResend: { resent.value += 1 }), size: size,
                  at: CGPoint(x: size.width / 2 - 30, y: size.height / 2 + dy))
            XCTAssertEqual(resent.value, 1, "retry dy \(dy)")
            click(MessageMetaView(timestamp: "09:05", status: .sent, placement: .below,
                                  readSummary: FlareMessageReadSummary(readCount: 1, unreadCount: 4, total: 5),
                                  conversationKind: .group, onReadReceiptOpen: { opened.value += 1 }), size: size,
                  at: CGPoint(x: size.width / 2 + 24, y: size.height / 2 + dy))
            XCTAssertEqual(opened.value, 1, "read summary dy \(dy)")
        }
    }

    /// In multi-select a click on a task's box selects the row; the task is not toggled.
    @MainActor
    func testAClickOnACardInMultiSelectSelectsTheRow() {
        final class Log { var toggled: [String] = []; var tasks = 0 }
        let log = Log()
        let size = CGSize(width: 390, height: 140)
        let row = MessageBubbleView(message: FlareMessageData(id: "t1", senderId: "u2", senderName: "Ivy",
                                                              content: FlareTaskContent(id: "t", title: "写周报")),
                                    currentUserId: "me", multiSelectMode: true,
                                    onToggleSelect: { log.toggled.append($0) },
                                    onTaskToggle: { _, _ in log.tasks += 1 })
        click(row, size: size, at: CGPoint(x: 120, y: size.height / 2))
        XCTAssertEqual(log.toggled, ["t1"])
        XCTAssertEqual(log.tasks, 0)
    }

    /// A custom card's own keys (a plugin card's) are inert in multi-select: the click selects the row.
    @MainActor
    func testACustomCardsKeysAreInertInMultiSelect() {
        final class Log { var toggled: [String] = []; var pressed = 0 }
        let size = CGSize(width: 390, height: 160)
        for selecting in [true, false] {
            let log = Log()
            let body: FlareContentBuilder = { _, _ in
                AnyView(Button { log.pressed += 1 } label: { Color.blue.frame(width: 200, height: 100) }.buttonStyle(.plain))
            }
            let row = MessageBubbleView(message: FlareMessageData(id: "c1", senderId: "u2", senderName: "Ivy",
                                                                  content: FlareGenericContent(contentType: "custom", label: "P")),
                                        currentUserId: "me", multiSelectMode: selecting,
                                        onToggleSelect: { log.toggled.append($0) })
                .flareContentRenderers(["custom": body])
            click(row, size: size, at: CGPoint(x: 160, y: size.height / 2))
            XCTAssertEqual(log.pressed, selecting ? 0 : 1, "selecting \(selecting)")
            XCTAssertEqual(log.toggled, selecting ? ["c1"] : [], "selecting \(selecting)")
        }
    }

    /// A card is one surface: no bubble fill is drawn around an outgoing card, while an outgoing text sits on it.
    @MainActor
    func testAnOutgoingCardHasNoBubbleAroundIt() throws {
        let colors = FlareColors.of(.light, brand: .violet)
        func countsOutgoingFill<V: View>(_ view: V) throws -> Int {
            let renderer = ImageRenderer(content: view.frame(width: 390).environment(\.colorScheme, .light))
            renderer.scale = 1
            let image = try XCTUnwrap(renderer.cgImage)
            let fill = RedPacketPalette.rgb(colors.messageOutgoingBackground)
            let data = try XCTUnwrap(image.dataProvider?.data) as Data
            let bytesPerPixel = image.bitsPerPixel / 8
            var hits = 0
            for y in 0..<image.height {
                for x in 0..<image.width {
                    let i = y * image.bytesPerRow + x * bytesPerPixel
                    let (r, g, b) = (Double(data[i]) / 255, Double(data[i + 1]) / 255, Double(data[i + 2]) / 255)
                    if abs(r - fill.r) < 0.02, abs(g - fill.g) < 0.02, abs(b - fill.b) < 0.02 { hits += 1 }
                }
            }
            return hits
        }
        let plugin: FlareContentBuilder = { _, _ in
            AnyView(PluginView(view: PluginViewModel(available: true, title: "周五团建去哪儿？",
                                                     blocks: [.note(PluginNoteBlock(text: "n"))])))
        }
        let card = MessageBubbleView(message: message(FlareGenericContent(contentType: "custom", label: "P")),
                                     currentUserId: "me").flareContentRenderers(["custom": plugin])
        let text = MessageBubbleView(message: message(FlareTextContent("hello there")), currentUserId: "me")
        XCTAssertEqual(try countsOutgoingFill(card), 0, "no coloured bubble around the plugin card")
        XCTAssertGreaterThan(try countsOutgoingFill(text), 100, "control: a text bubble is filled")
    }
    #endif
}
