import Foundation

/// The only durable value a file field may submit. URLs and host bytes never enter a form value.
public struct PluginFileValue: Codable, Equatable, Sendable {
    public let fileId: String
    public init(fileId: String) { self.fileId = fileId }
    public var json: PluginJSONValue { .object(["fileId": .string(fileId)]) }
    public static func read(_ value: PluginJSONValue?) -> Self? {
        guard let object = value?.objectValue, object.count == 1,
              let id = object["fileId"]?.stringValue, !id.isEmpty,
              id == id.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return Self(fileId: id)
    }
}

public enum PluginFilePhase: String, Codable, Sendable { case empty, selected, uploading, uploaded, failed }

/// Controlled, transient presentation state. `scope` plus `generation` fences every asynchronous result.
public struct PluginFileState: Equatable, Sendable {
    public let scope: String
    public let generation: Int
    public var phase: PluginFilePhase
    public var value: PluginFileValue?
    public var fileName: String?
    public var progress: Double?
    public var error: String?
    public var preview: Bool
    public var previewLoading: Bool
    public init(scope: String, generation: Int, phase: PluginFilePhase = .empty, value: PluginFileValue? = nil,
                fileName: String? = nil, progress: Double? = nil, error: String? = nil,
                preview: Bool = false, previewLoading: Bool = false) {
        self.scope = scope; self.generation = generation; self.phase = phase; self.value = value
        self.fileName = fileName; self.progress = progress; self.error = error
        self.preview = preview; self.previewLoading = previewLoading
    }
}

public enum PluginFileActionKind: String, Sendable { case choose, retry, cancel, replace, remove, preview, invalidate }

public struct PluginFileAction: Sendable {
    public let action: PluginFileActionKind
    public let inputId: String
    public let input: PluginInput
    public let scope: String
    public let generation: Int
    public let formValues: [String: PluginJSONValue]
    public init(action: PluginFileActionKind, input: PluginInput, scope: String, generation: Int,
                formValues: [String: PluginJSONValue]) {
        self.action = action; self.inputId = input.id; self.input = input
        self.scope = scope; self.generation = generation; self.formValues = formValues
    }
}
