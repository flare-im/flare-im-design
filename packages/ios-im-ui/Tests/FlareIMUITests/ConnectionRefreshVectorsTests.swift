import Foundation
import XCTest
@testable import FlareIMUI

/// The shared reconnect table (`spec/reconnect-refresh-vectors.json`): connection phases in, the work the
/// transition creates out. The Vue, Flutter and Compose kits run the same file.
final class ConnectionRefreshVectorsTests: XCTestCase {
    private struct Table: Decodable { let cases: [Vector] }
    private struct Vector: Decodable { let name: String; let phases: [String]; let expect: [Work] }
    private struct Work: Decodable { let dropStaleBeliefs: Bool; let resubscribe: Bool; let reread: Bool }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/reconnect-refresh-vectors.json")))
    }

    func testEveryTransitionAsksForTheSameThingHere() throws {
        for vector in try table().cases {
            let refresh = FlareConnectionRefresh()
            let seen = vector.phases.map { name -> FlareReconnectWork in
                guard let phase = FlareConnectionPhase(rawValue: name) else {
                    XCTFail("unknown phase \(name)")
                    return .none
                }
                return refresh.observe(phase)
            }
            let expected = vector.expect.map {
                FlareReconnectWork(dropStaleBeliefs: $0.dropStaleBeliefs, resubscribe: $0.resubscribe, reread: $0.reread)
            }
            XCTAssertEqual(seen, expected, vector.name)
        }
    }
}
