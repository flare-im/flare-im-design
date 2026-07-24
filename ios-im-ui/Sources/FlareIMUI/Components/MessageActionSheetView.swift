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
        .init(id: "image", label: "图片", systemImage: "photo"),
        .init(id: "camera", label: "拍摄", systemImage: "camera"),
        .init(id: "file", label: "文件", systemImage: "folder"),
        .init(id: "location", label: "位置", systemImage: "mappin.and.ellipse"),
        .init(id: "card", label: "名片", systemImage: "person.crop.rectangle"),
        .init(id: "vote", label: "投票", systemImage: "checkmark.square"),
        .init(id: "task", label: "任务", systemImage: "checklist"),
        .init(id: "schedule", label: "日程", systemImage: "calendar"),
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
