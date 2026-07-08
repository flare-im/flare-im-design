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
    private let actions: [FlareComposerAction]
    private let onAction: ((FlareComposerAction) -> Void)?

    @Environment(\.colorScheme) private var scheme

    public static let defaultActions: [FlareComposerAction] = [
        .init(id: "image", label: "Image", systemImage: "photo"),
        .init(id: "camera", label: "Camera", systemImage: "camera"),
        .init(id: "file", label: "File", systemImage: "folder"),
        .init(id: "location", label: "Location", systemImage: "mappin.and.ellipse"),
        .init(id: "card", label: "Contact", systemImage: "person.crop.rectangle"),
        .init(id: "vote", label: "Poll", systemImage: "checkmark.square"),
        .init(id: "task", label: "Task", systemImage: "checklist"),
        .init(id: "schedule", label: "Schedule", systemImage: "calendar"),
    ]

    public init(
        actions: [FlareComposerAction] = MessageActionSheetView.defaultActions,
        onAction: ((FlareComposerAction) -> Void)? = nil
    ) {
        self.actions = actions
        self.onAction = onAction
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    public var body: some View {
        let colors = FlareColors.of(scheme)
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
