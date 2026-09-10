import SwiftUI

/// Shared editable sheet. Hosts supply fields, validation and persistence callbacks.
public struct FormSheetView<Content: View>: View {
    private let title: String
    private let confirmLabel: String
    private let cancelLabel: String
    private let busy: Bool
    private let confirmEnabled: Bool
    private let onConfirm: () -> Void
    private let onCancel: () -> Void
    private let content: Content
    @Environment(\.colorScheme) private var scheme

    public init(title: String, confirmLabel: String, cancelLabel: String,
                busy: Bool = false, confirmEnabled: Bool = true,
                onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self.title = title; self.confirmLabel = confirmLabel; self.cancelLabel = cancelLabel
        self.busy = busy; self.confirmEnabled = confirmEnabled
        self.onConfirm = onConfirm; self.onCancel = onCancel; self.content = content()
    }
    public var body: some View {
        #if os(iOS)
        panel.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        #else
        panel
        #endif
    }
    private var panel: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            ScrollView { content.frame(maxWidth: .infinity, alignment: .leading).disabled(busy) }
            HStack(spacing: FlareSizes.spacingMd) {
                ButtonView(label: cancelLabel, variant: .secondary, size: .lg, disabled: busy, block: true, action: onCancel)
                ButtonView(label: confirmLabel, size: .lg, loading: busy, disabled: !confirmEnabled, block: true, action: onConfirm)
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: 480, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .foregroundColor(FlareColors.of(scheme).textPrimary)
        .background(FlareColors.of(scheme).bgPrimary)
        .interactiveDismissDisabled(busy)
    }
}
