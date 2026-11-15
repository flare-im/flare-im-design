import XCTest
@testable import FlareIMUI

/// A page action's native target writing into a form input, against spec/plugin-native-into-vectors.json.
final class PluginNativeIntoTests: XCTestCase {
    private func cases() throws -> [[String: Any]] {
        let file = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/plugin-native-into-vectors.json")
        let root = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        return root["cases"] as! [[String: Any]]
    }

    func testANativeTargetRunsThroughTheInputItNames() throws {
        for c in try cases() {
            let raw = c["input"] as! [String: Any]
            let input = PluginInput(id: raw["id"] as! String,
                                    kind: PluginInputKind(rawValue: raw["kind"] as! String)!, label: "")
            let target = try (c["target"] as? [String: Any]).map {
                try JSONDecoder().decode(PluginActionTarget.self, from: JSONSerialization.data(withJSONObject: $0))
            }
            XCTAssertEqual(PluginFormRules.nativeIntoKey(target, input), c["key"] as? String, "\(c)")
        }
    }

    func testActionsCarryTheirTarget() throws {
        let json = #"{"id":"scan","label":"Scan","target":{"kind":"native","capability":"documentCapture","params":{"side":"front"},"into":"front"}}"#
        let action = try JSONDecoder().decode(PluginViewAction.self, from: Data(json.utf8))
        XCTAssertEqual(action.target?.kind, "native")
        XCTAssertEqual(action.target?.capability, "documentCapture")
        XCTAssertEqual(action.target?.into, "front")
        XCTAssertEqual(action.target?.params?["side"], .string("front"))
        // An unreadable target is no target; the action still reads.
        let odd = try JSONDecoder().decode(PluginViewAction.self, from: Data(#"{"id":"a","label":"A","target":7}"#.utf8))
        XCTAssertNil(odd.target)
    }

    func testANativeRequestHasANewTokenEachTime() {
        let target = PluginActionTarget(kind: "native", capability: "locationOnce",
                                        params: ["precision": .string("coarse")], into: "area")
        XCTAssertNotEqual(PluginNativeIntoRequest(target: target), PluginNativeIntoRequest(target: target))
    }
}
