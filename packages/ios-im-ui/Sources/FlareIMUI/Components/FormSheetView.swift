import SwiftUI

/// Shared editable sheet. Hosts supply fields, validation and persistence
/// callbacks. Spec: Overlay/FormSheet — `onConfirm` / `onClose` mirror the
/// contract's confirm / close events. Present it with
/// ``SwiftUI/View/flareBottomSheet(item:title:onDismiss:content:)`` (the sheet fits the form), or in a
/// `.sheet`, where it sets medium and large detents itself.
public struct FormSheetView<Content: View>: View {
    private let title: String
    private let confirmLabel: String
    private let cancelLabel: String
    private let busy: Bool
    private let confirmEnabled: Bool
    private let onConfirm: () -> Void
    private let onClose: () -> Void
    private let content: Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareBottomSheetHosted) private var hosted

    public init(title: String, confirmLabel: String, cancelLabel: String,
                busy: Bool = false, confirmEnabled: Bool = true,
                onConfirm: @escaping () -> Void, onClose: @escaping () -> Void,
                @ViewBuilder content: () -> Content) {
        self.title = title; self.confirmLabel = confirmLabel; self.cancelLabel = cancelLabel
        self.busy = busy; self.confirmEnabled = confirmEnabled
        self.onConfirm = onConfirm; self.onClose = onClose; self.content = content()
    }
    public var body: some View {
        #if os(iOS)
        if hosted {
            panel
        } else {
            panel.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
        #else
        panel
        #endif
    }
    private var panel: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            ScrollView { content.frame(maxWidth: .infinity, alignment: .leading).disabled(busy) }
            HStack(spacing: FlareSizes.spacingMd) {
                ButtonView(label: cancelLabel, variant: .secondary, size: .lg, disabled: busy, block: true, action: onClose)
                ButtonView(label: confirmLabel, size: .lg, loading: busy, disabled: !confirmEnabled, block: true, action: onConfirm)
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: 480, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .foregroundColor(FlareColors.of(scheme, brand: flareBrandTheme).textPrimary)
        .background(FlareColors.of(scheme, brand: flareBrandTheme).bgPrimary)
        .interactiveDismissDisabled(busy)
    }
}
