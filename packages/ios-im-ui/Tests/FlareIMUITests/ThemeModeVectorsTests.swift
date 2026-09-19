import Foundation
import SwiftUI
import XCTest
@testable import FlareIMUI

/// The shared theme table (`spec/theme-mode-vectors.json`): the host holds the person's choice and the kit
/// resolves it. The same file is read by the Vue, Flutter and Compose tests.
final class ThemeModeVectorsTests: XCTestCase {
    private struct Table: Decodable { let cases: [Vector] }
    private struct Vector: Decodable {
        let id: String
        let mode: String
        let systemDark: Bool
        let dark: Bool
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/theme-mode-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testEveryCaseResolvesTheSameWayHere() throws {
        let cases = try table().cases
        XCTAssertEqual(cases.count, FlareThemeMode.allCases.count * 2, "the shared table lost cases")
        for vector in cases {
            let mode = try XCTUnwrap(FlareThemeMode(rawValue: vector.mode), vector.id)
            XCTAssertEqual(flareThemeIsDark(mode, systemDark: vector.systemDark), vector.dark, vector.id)
        }
    }

    func testTheStringsCarryTheThreeLabels() {
        let strings = FlareStrings()
        XCTAssertEqual([strings.themeSystem, strings.themeLight, strings.themeDark], ["跟随系统", "浅色", "深色"])
    }
}
