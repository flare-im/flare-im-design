import SwiftUI

/// Where one entry of ``MediaUploadView`` is: picked and waiting, on its way up, up, or failed.
public enum FlareMediaUploadState: Sendable, Equatable { case selected, uploading, uploaded, failed }

/// One entry of ``MediaUploadView``, in the host's order. `thumbnail` is a transient local picture the host made from
/// the bytes it picked; the view never fetches anything.
public struct FlareMediaUploadItem: Identifiable {
    public let id: String
    /// Read with each of its actions ("移除文件: 图片 1"); a file row shows it.
    public var name: String
    public var state: FlareMediaUploadState
    /// 0...1 while uploading; nil is indeterminate.
    public var progress: Double?
    /// The host's words for the state ("待发送"); nil uses the kit's.
    public var statusText: String?
    public var thumbnail: Image?
    /// Locks this entry while the others stay usable.
    public var disabled: Bool

    public init(id: String, name: String, state: FlareMediaUploadState, progress: Double? = nil,
                statusText: String? = nil, thumbnail: Image? = nil, disabled: Bool = false) {
        self.id = id; self.name = name; self.state = state; self.progress = progress
        self.statusText = statusText; self.thumbnail = thumbnail; self.disabled = disabled
    }
}

/// Several picked pictures or files with their upload state — the SwiftUI counterpart of Vue `FlareMediaUpload`
/// (Spec: Media/MediaUpload). `.images` is a three-column grid of square tiles ending in an add tile; `.files` is a
/// list of rows. A file list's optional title sits over the items with the count "n / maxCount" at its end, the hint
/// under it; a picture grid draws only the count (its title names it for VoiceOver).
///
/// Controlled: the host picks, uploads, keeps the bytes and orders the items; the view reports intents by item id. An
/// action is offered only when the host handles it: `onRemove` on an item that is not uploading, `onRetry` on a failed
/// one, `onPreview` on a tile with a thumbnail. The add tile (`onAdd`) is hidden while an item uploads and at
/// `maxCount`. `disabled` (the host is busy) locks every action; an item's own `disabled` locks only that item.
public struct MediaUploadView: View {
    public enum Layout: Sendable { case images, files }
    enum Action { case remove, retry, preview }

    private let title: String?
    private let hint: String?
    private let items: [FlareMediaUploadItem]
    private let layout: Layout
    private let maxCount: Int?
    private let disabled: Bool
    private let onAdd: (() -> Void)?
    private let onRemove: ((String) -> Void)?
    private let onRetry: ((String) -> Void)?
    private let onPreview: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @Environment(\.flareStrings) private var strings
    @ScaledMetric private var titleSize: CGFloat = FlareSizes.fontSizeMd
    @ScaledMetric private var detailSize: CGFloat = FlareSizes.fontSizeSm

    public init(title: String? = nil, hint: String? = nil, items: [FlareMediaUploadItem], layout: Layout = .images,
                maxCount: Int? = nil, disabled: Bool = false, onAdd: (() -> Void)? = nil,
                onRemove: ((String) -> Void)? = nil, onRetry: ((String) -> Void)? = nil,
                onPreview: ((String) -> Void)? = nil) {
        self.title = title; self.hint = hint; self.items = items; self.layout = layout; self.maxCount = maxCount
        self.disabled = disabled; self.onAdd = onAdd; self.onRemove = onRemove; self.onRetry = onRetry
        self.onPreview = onPreview
    }

    /// Whether `item` offers `action` now (the Vue kit's rule).
    static func allows(_ action: Action, _ item: FlareMediaUploadItem, disabled: Bool) -> Bool {
        guard !disabled, !item.disabled else { return false }
        switch action {
        case .remove: return item.state != .uploading
        case .retry: return item.state == .failed
        case .preview: return item.thumbnail != nil
        }
    }

    /// Whether there is room to add: nothing uploading, and fewer than `maxCount` items.
    static func showsAdd(_ items: [FlareMediaUploadItem], maxCount: Int?) -> Bool {
        !items.contains { $0.state == .uploading } && items.count < max(0, maxCount ?? .max)
    }

    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }
    private var adds: Bool { onAdd != nil && Self.showsAdd(items, maxCount: maxCount) }

    private func status(_ item: FlareMediaUploadItem) -> String {
        if let text = item.statusText, !text.isEmpty { return text }
        switch item.state {
        case .selected: return strings.pluginFileSelected
        case .uploading: return strings.pluginFileUploading
        case .uploaded: return strings.pluginFileUploaded
        case .failed: return strings.pluginFileFailed
        }
    }

    private func fraction(_ item: FlareMediaUploadItem) -> Double? {
        item.progress.flatMap { $0.isFinite ? min(1, max(0, $0)) : nil }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            // A picture grid shows only its count (Vue `is-images`): the title names the group for VoiceOver and the
            // hint is the file list's.
            let shownTitle = layout == .files ? title : nil
            if shownTitle != nil || maxCount != nil {
                HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingSm) {
                    if let shownTitle {
                        Text(shownTitle).font(.system(size: titleSize, weight: .medium)).foregroundColor(colors.textPrimary)
                    }
                    Spacer(minLength: 0)
                    if let maxCount {
                        Text(verbatim: "\(items.count) / \(maxCount)")
                            .font(.system(size: detailSize).monospacedDigit()).foregroundColor(colors.textSecondary)
                    }
                }
            }
            if layout == .files, let hint, !hint.isEmpty {
                Text(hint).font(.system(size: detailSize)).foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if layout == .images { grid } else { list }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title ?? "")
    }

    // MARK: Images

    @ViewBuilder private var grid: some View {
        if !items.isEmpty || adds {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FlareSizes.spacingSm), count: 3),
                      spacing: FlareSizes.spacingSm) {
                ForEach(items) { tile($0) }
                if adds { addTile }
            }
            .frame(maxWidth: FlareSizes.componentMediaImageMaxWidth)
        }
    }

    private func tile(_ item: FlareMediaUploadItem) -> some View {
        let text = status(item)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
        return Color.clear.aspectRatio(1, contentMode: .fit)
            .overlay(thumbnail(item, text))
            .overlay(alignment: .bottom) { strip(item, text) }
            .clipShape(shape)
            .overlay(shape.stroke(item.state == .failed ? colors.error : colors.borderSecondary, lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if item.state != .uploading, let onRemove {
                    IconButtonView(icon: "close", accessibilityLabel: "\(strings.pluginFileRemove): \(item.name)",
                                   size: .sm, variant: .tinted,
                                   disabled: !Self.allows(.remove, item, disabled: disabled)) { onRemove(item.id) }
                        .padding(FlareSizes.spacing3xs)
                }
            }
    }

    @ViewBuilder private func thumbnail(_ item: FlareMediaUploadItem, _ text: String) -> some View {
        let picture = colors.bgSecondary
            .overlay {
                if let image = item.thumbnail {
                    image.resizable().scaledToFill()
                } else {
                    FlareIconImage(name: "image", size: FlareSizes.iconSizeXl).foregroundColor(colors.textSecondary)
                }
            }
            .contentShape(Rectangle())
        if let onPreview, Self.allows(.preview, item, disabled: disabled) {
            Button { onPreview(item.id) } label: { picture }
                .buttonStyle(.plain)
                .accessibilityLabel("\(strings.pluginFilePreview): \(item.name)").accessibilityValue(text)
        } else {
            picture.accessibilityElement(children: .ignore)
                .accessibilityLabel(item.name).accessibilityValue(text)
        }
    }

    /// The tile's bottom strip: the progress while uploading, retry (or a warning) once failed.
    @ViewBuilder private func strip(_ item: FlareMediaUploadItem, _ text: String) -> some View {
        switch item.state {
        case .uploading:
            VStack(spacing: FlareSizes.spacingXs) {
                Text(fraction(item).map { "\(Int(($0 * 100).rounded()))%" } ?? text)
                    .font(.system(size: detailSize)).lineLimit(1)
                bar(item, text)
            }
            .foregroundColor(colors.textSecondary)
            .padding(FlareSizes.spacingXs)
            .frame(maxWidth: .infinity)
            .background(colors.bgPrimary.opacity(0.94))
            .allowsHitTesting(false)
        case .failed:
            Group {
                if let onRetry {
                    ButtonView(label: strings.retry, size: .sm, disabled: !Self.allows(.retry, item, disabled: disabled)) {
                        onRetry(item.id)
                    }
                    .accessibilityLabel("\(strings.retry): \(item.name)")
                } else {
                    FlareIconImage(name: "warning", size: FlareSizes.iconSizeLg).foregroundColor(colors.errorText)
                        .accessibilityHidden(true)
                }
            }
            .padding(FlareSizes.spacingXs)
            .frame(maxWidth: .infinity)
            .background(colors.bgPrimary.opacity(0.94))
        default:
            EmptyView()
        }
    }

    private var addTile: some View {
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
        return Button { onAdd?() } label: {
            shape.fill(colors.bgSecondary)
                .overlay(shape.stroke(colors.borderPrimary, style: StrokeStyle(lineWidth: 1, dash: [4])))
                .overlay(FlareIconImage(name: "add", size: FlareSizes.iconSizeLg).foregroundColor(colors.textSecondary))
                .aspectRatio(1, contentMode: .fit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
        .accessibilityLabel(title.map { "\(strings.pluginFormChooseImage): \($0)" } ?? strings.pluginFormChooseImage)
        .accessibilityHint(hint ?? "")
    }

    // MARK: Files

    @ViewBuilder private var list: some View {
        ForEach(items) { row($0) }
        if adds, let onAdd {
            ButtonView(label: strings.pluginFileChoose, variant: .secondary, size: .sm, disabled: disabled, icon: "add",
                       action: onAdd)
        }
    }

    private func row(_ item: FlareMediaUploadItem) -> some View {
        let text = status(item)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack(spacing: FlareSizes.spacingSm) {
                FlareIconImage(name: "file", size: FlareSizes.iconSizeLg).foregroundColor(colors.textSecondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    Text(item.name).font(.system(size: titleSize)).foregroundColor(colors.textPrimary)
                    Text(text).font(.system(size: detailSize))
                        .foregroundColor(item.state == .failed ? colors.errorText : colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                if item.state == .failed, let onRetry {
                    ButtonView(label: strings.retry, size: .sm, disabled: !Self.allows(.retry, item, disabled: disabled)) {
                        onRetry(item.id)
                    }
                    .accessibilityLabel("\(strings.retry): \(item.name)")
                }
                if item.state != .uploading, let onRemove {
                    ButtonView(label: strings.pluginFileRemove, variant: .text, size: .sm,
                               disabled: !Self.allows(.remove, item, disabled: disabled)) { onRemove(item.id) }
                        .accessibilityLabel("\(strings.pluginFileRemove): \(item.name)")
                }
            }
            if item.state == .uploading { bar(item, text) }
        }
        .padding(.bottom, FlareSizes.spacingSm)
        .overlay(alignment: .bottom) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
    }

    @ViewBuilder private func bar(_ item: FlareMediaUploadItem, _ text: String) -> some View {
        Group {
            if let value = fraction(item) { ProgressView(value: value) } else { ProgressView().controlSize(.small) }
        }
        .tint(colors.primaryText)
        .accessibilityLabel("\(item.name): \(text)")
    }
}
