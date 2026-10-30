import Foundation
@testable import FlareIMUI

/// A table under `spec/`, read as JSON values. Every case runs whatever its `platforms` say: the rules hold on
/// every kit.
enum SpecVectors {
    static func table(_ name: String) throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/\(name)"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }
}

extension PluginJSONValue {
    var intValue: Int? { numberValue.map { Int($0) } }
}
