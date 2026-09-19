import Foundation
import XCTest
@testable import FlareIMUI

/// FR-100: moments privacy in words, not SDK codes.
final class MomentsPrivacyTests: XCTestCase {
    private struct Vocabulary: Decodable {
        let visibility: [String]
        let audienceMode: [String]
        let historyRange: [String]
    }

    func testTheKitEnumsAreTheSharedVocabulary() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/moments-privacy.json")
        let vocabulary = try JSONDecoder().decode(Vocabulary.self, from: Data(contentsOf: url))
        XCTAssertEqual(FlareMomentVisibility.allCases.map(\.rawValue), vocabulary.visibility)
        XCTAssertEqual(FlareMomentAudienceMode.allCases.map(\.rawValue), vocabulary.audienceMode)
        XCTAssertEqual(FlareMomentHistoryRange.allCases.map(\.rawValue), vocabulary.historyRange)
        XCTAssertEqual(FlareMomentVisibility.allCases.filter(flareMomentAudienceApplies).map(\.rawValue),
                       ["friends", "public"])
    }
}
