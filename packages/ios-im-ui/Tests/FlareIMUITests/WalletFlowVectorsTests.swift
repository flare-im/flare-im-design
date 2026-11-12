import Foundation
import XCTest
@testable import FlareIMUI

/// The wallet pages as plain blocks (spec/wallet-flow-vectors.json, the resolved views the wallet contract draws): every
/// block of every sample reads, the balance hero can be hidden and the transaction list groups by day.
final class WalletFlowVectorsTests: XCTestCase {
    func testEveryWalletSampleReadsWhole() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/wallet-flow-vectors.json"))
        let cases = try XCTUnwrap(try JSONDecoder().decode(PluginJSONValue.self, from: data)["cases"]?.arrayValue)
        XCTAssertFalse(cases.isEmpty)
        for sample in cases {
            let id = [sample["id"], sample["variant"], sample["locale"]].compactMap { $0?.stringValue }.joined(separator: "/")
            let raw = try XCTUnwrap(sample["view"])
            let view = try PluginVectors.decode(PluginViewModel.self, raw)
            XCTAssertEqual(view.blocks.count, raw["blocks"]?.arrayValue?.count ?? 0, id)
            let blocks = view.blocks.flatMap { block -> [PluginBlock] in
                if case .section(let section) = block { return [block] + section.blocks }
                return [block]
            }
            for block in blocks {
                if case .hero(let hero) = block { XCTAssertTrue(hero.maskable, "\(id): the balance hides") }
                if case .rows(let rows) = block, sample["page"]?.stringValue == "flare.wallet.page.history" {
                    XCTAssertTrue(rows.groupByDay, "\(id): grouped by day")
                }
            }
        }
    }
}
