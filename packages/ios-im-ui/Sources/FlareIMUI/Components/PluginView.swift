import SwiftUI

public struct PluginViewField: Codable {
    public let label: String; public let value: String
    public init(label: String, value: String) { self.label = label; self.value = value }
}
public struct PluginViewAction: Codable {
    public let id: String; public let label: String
    public init(id: String, label: String) { self.id = id; self.label = label }
}
public struct PluginViewModel: Codable {
    public let available: Bool
    public let title: String
    public let fields: [PluginViewField]
    public let actions: [PluginViewAction]
    public init(available: Bool, title: String, fields: [PluginViewField] = [], actions: [PluginViewAction] = []) {
        self.available = available; self.title = title; self.fields = fields; self.actions = actions
    }
}
/// No plugin code or URL is executed by the renderer. Actions are opaque IDs.
public struct PluginView: View {
    private let view: PluginViewModel
    private let busy: Bool
    private let onAction: ((String) -> Void)?
    public init(view: PluginViewModel, busy: Bool = false, onAction: ((String) -> Void)? = nil) {
        self.view = view; self.busy = busy; self.onAction = onAction
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            Text(view.title).font(.headline)
            if view.available {
                ForEach(Array(view.fields.enumerated()), id: \.offset) { _, field in
                    VStack(alignment: .leading) { Text(field.label).font(.caption); Text(field.value) }
                }
                ForEach(view.actions, id: \.id) { action in
                    ButtonView(label: action.label, variant: .secondary, disabled: busy || onAction == nil) { onAction?(action.id) }
                }
            }
        }
    }
}
