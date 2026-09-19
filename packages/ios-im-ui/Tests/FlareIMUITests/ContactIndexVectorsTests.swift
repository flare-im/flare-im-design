import Foundation
import XCTest
@testable import FlareIMUI

/// FR-044: one index letter per character, on all four kits. Vue and SwiftUI read the platform's
/// pinyin collation; Flutter and Compose read the table generated from it. A kit that disagrees here
/// has a defect, not a dialect — 曾 was Z on Flutter and C everywhere else for three rounds, because
/// nothing compared them.
final class ContactIndexVectorsTests: XCTestCase {
    private struct Vectors: Decodable {
        let groups: [String: String]
        let letters: [String: String]
    }

    private func vectors() throws -> Vectors {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/contact-index-vectors.json")
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    func testReadsEveryCharacterTheWayTheSharedTableSays() throws {
        let table = try vectors()
        var wrong: [String] = []
        for (character, letter) in table.letters {
            let actual = ContactListView.indexLetter(name: character)
            if actual != letter { wrong.append("\(character): \(actual) (table says \(letter))") }
        }
        XCTAssertEqual(wrong.sorted(), [])
    }

    func testStillReadsTheCharactersTheOtherKitsUsedToMiss() throws {
        let table = try vectors()
        for character in try XCTUnwrap(table.groups["formerlyMissing"]) {
            XCTAssertNotEqual(ContactListView.indexLetter(name: String(character)), "#", "\(character)")
        }
    }
}
