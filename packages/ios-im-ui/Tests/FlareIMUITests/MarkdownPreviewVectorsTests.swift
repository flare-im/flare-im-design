import Foundation
import XCTest
@testable import FlareIMUI

/// The shared markdown table (`spec/markdown-preview-vectors.json`): what a markdown message reads as in a
/// conversation row, a reply strip or a quote. Vue is the reference implementation; this kit answers to the
/// same file.
final class MarkdownPreviewVectorsTests: XCTestCase {
    private struct Table: Decodable { let cases: [Vector] }
    private struct Vector: Decodable {
        let id: String
        let markdown: String
        let expected: [String: String]
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/markdown-preview-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testEveryCaseReadsTheSameHere() throws {
        let table = try table()
        XCTAssertGreaterThanOrEqual(table.cases.count, 20)
        let strings = [
            "zh-CN": FlareStrings(),
            "en-US": FlareStrings(previewImage: "[Image]", previewImageNamed: { "[Image] \($0)" }),
        ]
        for vector in table.cases {
            for (locale, s) in strings {
                guard let expected = vector.expected[locale] else {
                    XCTFail("\(vector.id) has no \(locale) expectation")
                    continue
                }
                XCTAssertEqual(
                    flareMarkdownToPlainText(vector.markdown, strings: s), expected,
                    "\(vector.id) @ \(locale)")
            }
        }
    }
}
