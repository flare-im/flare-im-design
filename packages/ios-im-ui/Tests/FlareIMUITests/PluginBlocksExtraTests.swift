import SwiftUI
import XCTest
@testable import FlareIMUI

/// Vocabulary 2 against `spec/plugin-view-vectors.json` (formats2, blocks2, moneyInput, upgradeNotice): the facts the
/// four kits share, plus decoding of every new block, input and the upgrade placeholder.
final class PluginBlocksExtraTests: XCTestCase {
    private func json(_ text: String) throws -> PluginJSONValue {
        try JSONDecoder().decode(PluginJSONValue.self, from: Data(text.utf8))
    }

    // MARK: Formats

    func testCountsAndDurationsAreWrittenInTheViewersWords() throws {
        let table = try PluginVectors.table()
        let cases = try XCTUnwrap(table["formats2"]?["cases"]?.arrayValue)
        for item in cases {
            let format = try? PluginVectors.decode(PluginValueFormat.self, item["format"])
            let text = try XCTUnwrap(item["text"]?.stringValue)
            XCTAssertEqual(PluginFormatRules.text(text, format, FlareStrings()), item["zh"]?.stringValue, "\(item)")
            XCTAssertEqual(PluginFormatRules.text(text, format, .english), item["en"]?.stringValue, "\(item)")
        }
    }

    func testAFieldOrACellKeepsItsFormatAndAnUnknownOneIsPlainText() throws {
        let field = try PluginVectors.decode(PluginViewField.self,
            try json(#"{"label":"Members","value":"12345","format":{"kind":"count","count":12345}}"#))
        XCTAssertEqual(field.format, .count(12345))
        let newer = try PluginVectors.decode(PluginViewField.self,
            try json(#"{"label":"X","value":"as sent","format":{"kind":"newer","value":1}}"#))
        XCTAssertNil(newer.format)
        XCTAssertEqual(newer.value, "as sent")
        let cell = try PluginVectors.decode(PluginRowCell.self,
            try json(#"{"text":"7500000","format":{"kind":"duration","ms":7500000}}"#))
        XCTAssertEqual(PluginFormatRules.text(cell.text, cell.format, FlareStrings()), "2 小时 5 分钟")
    }

    // MARK: Blocks

    func testEveryVocabulary2BlockDecodes() throws {
        let view = try PluginVectors.decode(PluginViewModel.self, try json(#"""
        {"available":true,"title":"Board","fields":[],"actions":[],"blocks":[
          {"kind":"section","label":"Overview","collapsed":true,"blocks":[
            {"kind":"stats","items":[{"label":"Open","value":"12","trend":{"text":"+3","direction":"up"},"tone":"success"},
                                     {"label":"Done","value":"12345","format":{"kind":"count","count":12345}}]},
            {"kind":"section","label":"nested","blocks":[{"kind":"divider"}]},
            {"kind":"brandNew","x":1}]},
          {"kind":"chart","chartKind":"bar","series":[{"label":"A","points":[{"label":"Mon","value":1,"text":"1"}]}],"emptyText":"None"},
          {"kind":"image","asset":"assets/cover.png","aspect":"16:9","alt":"Cover"},
          {"kind":"qr","value":"flare://pay/1","label":"Pay","refreshOperation":"qr.refresh","valuePath":"/code","expiresAtPath":"/exp","expiresAtMs":5000},
          {"kind":"hero","label":"Balance","value":"12.50","amount":true,"tone":"brand","actions":[{"id":"top-up","label":"Top up"}]},
          {"kind":"steps","items":[{"label":"Submitted","state":"done"},{"label":"Review","state":"current"},{"label":"Done","state":"skipped"}]},
          {"kind":"banner","tone":"danger","text":"Rejected","action":{"id":"retry","label":"Retry"}},
          {"kind":"timeline","items":[{"atMs":1000,"title":"Created","detail":"by Ann","status":{"text":"ok","tone":"success"}}],"emptyText":"Nothing"}
        ]}
        """#))
        XCTAssertEqual(view.blocks.map(\.kind), ["section", "chart", "image", "qr", "hero", "steps", "banner", "timeline"])
        guard case .section(let section) = view.blocks[0] else { return XCTFail("section") }
        XCTAssertEqual(section.label, "Overview")
        XCTAssertTrue(section.collapsed)
        XCTAssertEqual(section.blocks.map(\.kind), ["stats"], "a nested section and an unknown kind are dropped")
        guard case .stats(let stats) = section.blocks[0] else { return XCTFail("stats") }
        XCTAssertEqual(stats.items[0].trend, PluginTrend(text: "+3", direction: .up))
        XCTAssertEqual(stats.items[0].tone, .success)
        XCTAssertEqual(stats.items[1].format, .count(12345))
        guard case .chart(let chart) = view.blocks[1] else { return XCTFail("chart") }
        XCTAssertEqual(chart.chartKind, .bar)
        XCTAssertTrue(chart.hasPoints)
        guard case .image(let image) = view.blocks[2] else { return XCTFail("image") }
        XCTAssertEqual(image.source, PluginImageSource(asset: "assets/cover.png"))
        XCTAssertEqual(image.aspect, .wide)
        guard case .qr(let qr) = view.blocks[3] else { return XCTFail("qr") }
        XCTAssertEqual(qr.refresh, PluginQrRefresh(operation: "qr.refresh", valuePath: "/code", expiresAtPath: "/exp"))
        guard case .hero(let hero) = view.blocks[4] else { return XCTFail("hero") }
        XCTAssertEqual(hero.tone, .brand)
        XCTAssertEqual(hero.actions.map(\.id), ["top-up"])
        guard case .steps(let steps) = view.blocks[5] else { return XCTFail("steps") }
        XCTAssertEqual(steps.items.map(\.state), [.done, .current, .pending])
        guard case .banner(let banner) = view.blocks[6] else { return XCTFail("banner") }
        XCTAssertEqual(banner.tone, .danger)
        XCTAssertEqual(banner.action?.id, "retry")
        guard case .timeline(let timeline) = view.blocks[7] else { return XCTFail("timeline") }
        XCTAssertEqual(timeline.items.first?.status, PluginBadge(text: "ok", tone: .success))
        // Round trip.
        XCTAssertEqual(try PluginVectors.decode(PluginViewModel.self, try json(String(decoding: JSONEncoder().encode(view), as: UTF8.self))), view)
    }

    func testBlockRulesFollowTheSharedTable() throws {
        let table = try XCTUnwrap(try PluginVectors.table()["blocks2"])
        for item in table["steps"]?.arrayValue ?? [] {
            let state = try PluginVectors.decode(PluginStepState.self, item["state"])
            XCTAssertEqual(state.rawValue, item["expect"]?.stringValue)
        }
        for item in table["trend"]?.arrayValue ?? [] {
            XCTAssertEqual(try PluginVectors.decode(PluginTrendDirection.self, item["direction"]).rawValue, item["expect"]?.stringValue)
        }
        for item in table["bannerTone"]?.arrayValue ?? [] {
            XCTAssertEqual(try PluginVectors.decode(PluginBannerTone.self, item["tone"]).rawValue, item["expect"]?.stringValue)
        }
        for item in table["heroTone"]?.arrayValue ?? [] {
            XCTAssertEqual(try PluginVectors.decode(PluginHeroTone.self, item["tone"]).rawValue, item["expect"]?.stringValue)
        }
        for item in table["imageRatio"]?.arrayValue ?? [] {
            let aspect = try PluginVectors.decode(PluginImageAspect.self, item["aspect"])
            XCTAssertEqual(Double(aspect.ratio), item["expect"]?.numberValue ?? 0, accuracy: 1e-9)
        }
        for item in table["qr"]?.arrayValue ?? [] {
            let block = PluginQrBlock(value: "x", expiresAtMs: item["expiresAtMs"]?.numberValue.map { Int64($0) })
            let now = Int64(item["nowMs"]?.numberValue ?? 0)
            XCTAssertEqual(block.expired(nowMs: now), item["expired"]?.boolValue)
            XCTAssertEqual(block.refreshDelay(nowMs: now).map(Double.init), item["refreshMs"]?.numberValue)
        }
        for item in table["donut"]?.arrayValue ?? [] {
            let points = (item["values"]?.arrayValue ?? []).enumerated().map {
                PluginChartPoint(label: "\($0.offset)", value: $0.element.numberValue ?? 0, text: "")
            }
            let expected = (item["expect"]?.arrayValue ?? []).map {
                PluginDonutSlice(index: Int($0["index"]?.numberValue ?? -1), start: $0["start"]?.numberValue ?? -1,
                                 sweep: $0["sweep"]?.numberValue ?? -1)
            }
            XCTAssertEqual(PluginChartRules.donutSlices(points), expected)
        }
        for item in table["chartHasPoints"]?.arrayValue ?? [] {
            let series = try PluginVectors.decode([PluginChartSeries].self, item["series"])
            XCTAssertEqual(PluginChartBlock(chartKind: .bar, series: series).hasPoints, item["expect"]?.boolValue)
        }
        let flatten = try XCTUnwrap(table["flatten"])
        let blocks = try PluginVectors.decode([PluginLossyBlock].self, flatten["blocks"]).compactMap(\.block)
        XCTAssertEqual(PluginBlockWalk.flat(blocks).map(\.kind),
                       (flatten["expect"]?.arrayValue ?? []).compactMap { $0["kind"]?.stringValue })
    }

    func testSectionChildrenNameTheirUsersAndKeepTheirOwnChoicesState() throws {
        let view = try PluginVectors.decode(PluginViewModel.self, try json(#"""
        {"available":true,"title":"x","blocks":[{"kind":"section","blocks":[
          {"kind":"people","groups":[{"label":"Going","userIds":["u1","u2"],"count":2}]}]}]}
        """#))
        XCTAssertEqual(PluginViewFormat.userIds(in: view), ["u1", "u2"])
        XCTAssertNotEqual(PluginView.sectionChildIndex(section: 0, child: 0), 0)
        XCTAssertNotEqual(PluginView.sectionChildIndex(section: 1, child: 0), PluginView.sectionChildIndex(section: 0, child: 1))
    }

    // MARK: Inputs

    func testMoneyInputFollowsTheSharedTable() throws {
        let table = try XCTUnwrap(try PluginVectors.table()["moneyInput"])
        let input = try PluginVectors.decode(PluginInput.self, table["input"])
        XCTAssertEqual(input.money, PluginMoneyRules(currency: "CNY", scale: 2, min: "0.01", max: "200"))
        for item in table["normalize"]?.arrayValue ?? [] {
            XCTAssertEqual(PluginMoneyRulesCheck.amount(item["typed"]?.stringValue ?? ""), item["expect"]?.stringValue)
        }
        for item in table["check"]?.arrayValue ?? [] {
            let subject = item["input"].map { try? PluginVectors.decode(PluginInput.self, $0) } ?? input
            let checked = try XCTUnwrap(subject, "\(item)")
            XCTAssertEqual(PluginFormRules.check(checked, item["draft"]).map(\.rawValue), item["expect"]?.stringValue, "\(item)")
        }
        for item in table["values"]?.arrayValue ?? [] {
            let values = PluginFormRules.values([input], [input.id: item["draft"] ?? .null])
            XCTAssertEqual(values[input.id], item["expect"].flatMap { $0.isNull ? nil : $0 }, "\(item)")
        }
        for item in table["drafts"]?.arrayValue ?? [] {
            XCTAssertEqual(PluginFormRules.draftValue(input, values: [input.id: item["value"] ?? .null]),
                           .string(item["expect"]?.stringValue ?? ""))
        }
        for item in table["compare"]?.arrayValue ?? [] {
            let order = PluginMoneyRulesCheck.compare(item["a"]?.stringValue ?? "", item["b"]?.stringValue ?? "")
            XCTAssertEqual(order.rawValue, Int(item["expect"]?.numberValue ?? 9))
        }
    }

    func testImageAndDocumentInputsAreUploadsAndSayWhatTheyTake() throws {
        let file = #""file":{"accept":["image/jpeg","image/png"],"maxBytes":1048576,"upload":{"prepareOperation":"p","completeOperation":"c","purpose":"id"}}"#
        let image = try PluginVectors.decode(PluginInput.self, try json(#"{"id":"cover","kind":"image","label":"Cover",\#(file)}"#))
        let document = try PluginVectors.decode(PluginInput.self,
            try json(#"{"id":"front","kind":"document","label":"ID","side":"front",\#(file)}"#))
        XCTAssertTrue(image.kind.isUpload)
        XCTAssertEqual(document.side, .front)
        XCTAssertThrowsError(try PluginVectors.decode(PluginInput.self, try json(#"{"id":"x","kind":"image","label":"X"}"#)),
                             "an upload input needs its upload policy")
        XCTAssertThrowsError(try PluginVectors.decode(PluginInput.self, try json(#"{"id":"x","kind":"money","label":"X"}"#)),
                             "a money input needs its rules")
        let strings = FlareStrings()
        XCTAssertEqual(PluginFileUploadField.chooseText(image, strings), strings.pluginFormChooseImage)
        XCTAssertEqual(PluginFileUploadField.chooseText(document, strings), strings.pluginFormCaptureDocument)
        XCTAssertEqual(PluginFileUploadField.sideText(document, strings), strings.pluginFormDocumentFront)
        XCTAssertNil(PluginFileUploadField.sideText(image, strings))
        // A completed upload is submitted as its file reference, like a file input's.
        let state = PluginFormState(inputs: [image], values: [image.id: ["fileId": "f1"]])
        XCTAssertEqual(state.files[image.id]?.phase, .uploaded)
        XCTAssertEqual(PluginFormRules.values([image], state.draft)[image.id], ["fileId": "f1"])
        XCTAssertEqual(PluginFormRules.check(document, nil), nil)
    }

    // MARK: Upgrade

    func testUpgradeNoticeModeFollowsTheSharedTable() throws {
        for item in try PluginVectors.table()["upgradeNotice"]?.arrayValue ?? [] {
            let status = item["status"].flatMap { $0.isNull ? nil : try? PluginVectors.decode(PluginUpgradeStatus.self, $0) }
            XCTAssertEqual(PluginUpgradeMode.of(status, canUpdate: item["canUpdate"]?.boolValue ?? false).rawValue,
                           item["expect"]?.stringValue, "\(item)")
        }
    }

    func testAnUpgradePlaceholderDecodesWithItsBuildAndSaysSo() throws {
        let view = try PluginVectors.decode(PluginViewModel.self, try json(
            #"{"available":false,"title":"Task board","unavailableReason":"upgrade_required","minBuild":41020}"#))
        XCTAssertTrue(view.upgradeRequired)
        XCTAssertEqual(view.minBuild, 41020)
        let strings = FlareStrings()
        XCTAssertEqual(PluginViewFormat.reasonText(.upgradeRequired, strings), strings.pluginViewUnavailableUpgradeRequired)
        XCTAssertEqual(FlarePluginUpgradeNotice.cardText(.update, strings), strings.pluginViewUnavailableUpgradeRequired)
        XCTAssertEqual(FlarePluginUpgradeNotice.cardText(.notAvailable, strings), strings.pluginUpgradeNotAvailable)
        XCTAssertEqual(FlarePluginUpgradeNotice.pageText(.description, strings), strings.pluginUpgradeDescription)
        XCTAssertEqual(FlarePluginUpgradeNotice(status: PluginUpgradeStatus(available: true), onUpdate: {}).mode, .update)
        XCTAssertEqual(FlarePluginUpgradeNotice(status: PluginUpgradeStatus(available: true)).mode, .description,
                       "no handler, no key")
    }

    // MARK: Vocabulary

    func testTheDeclaredVocabularyIsWhatTheKitDraws() throws {
        let declared = try JSONDecoder().decode([String: PluginJSONValue].self, from: Data(PLUGIN_UI_VOCABULARY.utf8))
        let blocks = Set((declared["blocks"]?.arrayValue ?? []).compactMap(\.stringValue))
        XCTAssertEqual(blocks, FlarePluginUIVocabulary.blocks)
        XCTAssertFalse(blocks.contains("protected-media"), "the kit does not draw it, so it never reports it")
        XCTAssertEqual(Set(PluginInputKind.allCases.map(\.rawValue)), FlarePluginUIVocabulary.inputs)
        XCTAssertEqual(FlarePluginUIVocabulary.renderers, ["redPacket.card", "redPacket.pay", "payment.confirm"])
        for renderer in FlarePluginUIVocabulary.renderers {
            let view = PluginViewModel(available: true, title: "x",
                                       presentation: PluginPresentation(renderer: renderer, props: [:], actions: [:]))
            XCTAssertTrue(flareHasResolvedPresentation(view), renderer)
        }
    }
}

/// A block of a vector table, or nil for a kind the kit skips.
private struct PluginLossyBlock: Decodable {
    let block: PluginBlock?
    init(from decoder: Decoder) throws { block = try? PluginBlock(from: decoder) }
}
