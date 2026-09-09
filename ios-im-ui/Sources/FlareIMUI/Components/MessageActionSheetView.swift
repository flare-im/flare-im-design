import SwiftUI

/// One attachment/action tile in ``MessageActionSheetView``.
public struct FlareComposerAction: Identifiable {
    public let id: String
    public let label: String
    public let systemImage: String
    public init(id: String, label: String, systemImage: String) {
        self.id = id; self.label = label; self.systemImage = systemImage
    }
}

/// The attachment "+" action grid — image, file, card, vote, location, etc.
/// Spec: Composer/MessageActionSheet (`MessageActionSheetView`). Emits the
/// chosen action; the host builds the content message.
public struct MessageActionSheetView: View {
    private let actions: [FlareComposerAction]?
    private let onAction: ((FlareComposerAction) -> Void)?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareStrings) private var strings

    /// Attachment tiles built from host-overridable copy. Pass a different
    /// ``FlareStrings`` (or the environment value) to relabel them.
    public static func actions(for strings: FlareStrings) -> [FlareComposerAction] {
        [
            .init(id: "image", label: strings.actionImage, systemImage: "photo"),
            .init(id: "camera", label: strings.actionCamera, systemImage: "camera"),
            .init(id: "file", label: strings.actionFile, systemImage: "folder"),
            .init(id: "location", label: strings.actionLocation, systemImage: "mappin.and.ellipse"),
            .init(id: "card", label: strings.actionCard, systemImage: "person.crop.rectangle"),
            .init(id: "vote", label: strings.actionVote, systemImage: "checkmark.square"),
            .init(id: "task", label: strings.actionTask, systemImage: "checklist"),
            .init(id: "schedule", label: strings.actionSchedule, systemImage: "calendar"),
        ]
    }

    /// Default tiles with the kit's built-in copy. Prefer leaving `actions` unset so the
    /// view resolves them from the environment instead.
    public static let defaultActions: [FlareComposerAction] = actions(for: FlareStrings())

    public init(
        actions: [FlareComposerAction]? = nil,
        onAction: ((FlareComposerAction) -> Void)? = nil
    ) {
        self.actions = actions
        self.onAction = onAction
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let actions = self.actions ?? Self.actions(for: strings)
        LazyVGrid(columns: columns, spacing: FlareSizes.spacingLg) {
            ForEach(actions) { action in
                Button { onAction?(action) } label: {
                    VStack(spacing: FlareSizes.spacingXs) {
                        ZStack {
                            RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary)
                                .frame(width: 52, height: 52)
                            Image(systemName: action.systemImage).font(.system(size: 24))
                                .foregroundColor(colors.textPrimary)
                        }
                        Text(action.label).font(.system(size: FlareSizes.fontSizeXs))
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FlareSizes.spacingLg)
        .background(colors.bgPrimary)
    }
}
