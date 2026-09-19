import Foundation
import XCTest
@testable import FlareIMUI

/// FR-056: one conversation-kind vocabulary for every kit and every component.
final class ConversationKindTests: XCTestCase {
    func testTheKitEnumIsTheSharedVocabulary() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/conversation-kind.json")
        struct Vocabulary: Decodable { let kinds: [String] }
        let vocabulary = try JSONDecoder().decode(Vocabulary.self, from: Data(contentsOf: url))
        XCTAssertEqual(FlareConversationKind.allCases.map(\.rawValue), vocabulary.kinds)
    }
}
