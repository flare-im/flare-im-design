import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A protected media block (spec Message/PluginView, protected-media): private material read one item at a time.
/// Nothing is fetched until the viewer asks; a block that declares a reason input first asks why, the owner's own
/// page reads with one tap. The host runs the read (`onRead`) and hands the address back in `states`.
///
/// The kit fetches the picture itself, into memory only: an ephemeral session with no URL cache and no cookie or
/// credential store, so the grant address never reaches a disk cache. The picture has no context menu, no drag and no
/// share or save key, and is marked privacy-sensitive.
///
/// The items are 16:10 thumbnails, three to a row (docs/plugin-experience.md §6.1): a blurred stand-in with the `eye`
/// until the host's read returns the address; a tap reads it, and the picture opens full screen on the media stage
/// (a read item opens again on a tap). A failed read says so under the thumbnails.
struct PluginProtectedMediaBlockView: View {
    let block: PluginProtectedMediaBlock
    let states: [String: PluginProtectedMediaState]
    let busy: Bool
    let onRead: ((PluginProtectedMediaRead) -> Void)?
    @State private var asking: PluginProtectedItem?
    /// The item the viewer asked to see: it opens full screen once its read returns.
    @State private var requested: String?
    @State private var viewing: PluginProtectedItem?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// The items in rows of three.
    static func rows(_ items: [PluginProtectedItem]) -> [[PluginProtectedItem]] {
        stride(from: 0, to: items.count, by: 3).map { Array(items[$0..<min($0 + 3, items.count)]) }
    }

    /// The read the block hands the host for `item` with `reason` (empty when none is asked).
    static func read(_ block: PluginProtectedMediaBlock, item: PluginProtectedItem, reason: String) -> PluginProtectedMediaRead? {
        guard let action = block.action else { return nil }
        var values: [String: PluginJSONValue] = [block.inputName: .string(item.id)]
        if let reasonInput = block.reasonInput { values[reasonInput] = .string(reason) }
        return PluginProtectedMediaRead(action: action, item: item, reason: reason, urlPath: block.urlPath,
                                        formValues: values)
    }

    private func request(_ item: PluginProtectedItem) {
        if FlarePluginProtectedMedia.source(states[item.id]?.url) != nil { viewing = item; return }
        guard !busy, let onRead else { return }
        requested = item.id
        if block.asksReason { asking = item } else if let read = Self.read(block, item: item, reason: "") { onRead(read) }
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if let label = block.label, !label.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeMd, weight: .medium)).foregroundColor(colors.textPrimary)
            }
            if block.items.isEmpty {
                // R8: the compact empty state in the block.
                EmptyStateView(title: block.emptyText ?? strings.pluginViewEmpty, icon: "admin", compact: true)
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(Self.rows(block.items).enumerated()), id: \.offset) { _, row in
                HStack(spacing: FlareSizes.spacingSm) {
                    ForEach(row, id: \.id) { item in thumbnail(item, colors) }
                    Spacer(minLength: 0)
                }
            }
            ForEach(block.items, id: \.id) { item in itemView(item, colors) }
            Text(block.asksReason ? strings.pluginProtectedMediaNotice : strings.pluginProtectedMediaOwnNotice)
                .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
        }
        .onChange(of: states) { next in
            guard let id = requested, FlarePluginProtectedMedia.source(next[id]?.url) != nil else { return }
            requested = nil
            viewing = block.items.first { $0.id == id }
        }
        .flareFullScreen(item: $viewing, label: viewing?.label, ground: .stage) { item in
            viewer(item, colors)
        }
        .flareBottomSheet(item: $asking, title: block.action?.label) { item in
            PluginFormView(
                inputs: [PluginInput(id: "reason", kind: .textarea, label: strings.pluginProtectedMediaReason,
                                     required: true, maxLength: 160)],
                submitLabel: block.action?.label,
                onSubmit: { values in
                    let reason = (values["reason"]?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    asking = nil
                    guard !reason.isEmpty, let read = Self.read(block, item: item, reason: reason) else { return }
                    onRead?(read)
                },
                onCancel: { asking = nil })
        }
    }

    /// One thumbnail: the blurred stand-in and the `eye` until read (a tap reads it), a spinner while reading, the
    /// `eye-off` once the picture is open below.
    private func thumbnail(_ item: PluginProtectedItem, _ colors: FlareColors) -> some View {
        let state = states[item.id]
        let read = FlarePluginProtectedMedia.source(state?.url) != nil
        let loading = state?.loading == true
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
        let height = FlareSizes.componentDocumentThumbHeight
        return Button { request(item) } label: {
            ZStack {
                read ? colors.bgSelected : colors.bgSecondary
                if loading {
                    ProgressView()
                } else if read {
                    IconView("eye-off", size: FlareSizes.iconSizeMd, color: colors.textSecondary)
                } else {
                    // Nothing is fetched before the read: a blurred card stands in for the picture.
                    DocumentOutlineShape(side: .front)
                        .stroke(colors.textTertiary, lineWidth: 1)
                        .padding(FlareSizes.spacingMd)
                        .blur(radius: FlareSizes.spacing3xs)
                    IconView("eye", size: FlareSizes.iconSizeMd, color: colors.textSecondary)
                }
            }
            .frame(maxWidth: height * 16 / 10)
            .frame(height: height)
            .clipShape(shape)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(loading || (!read && (busy || onRead == nil || block.action == nil)))
        // 「证件正面，点按查看」 until read; a reason-asking read names its action as the hint.
        .accessibilityLabel(read || loading ? item.label
                            : strings.pluginProtectedMediaTapToView.replacingOccurrences(of: "{label}", with: item.label))
        .accessibilityHint(read || loading || !block.asksReason ? "" : block.action?.label ?? "")
        .accessibilityIdentifier("plugin.media.\(item.id).read")
    }

    /// A failed read, under the thumbnails.
    @ViewBuilder private func itemView(_ item: PluginProtectedItem, _ colors: FlareColors) -> some View {
        if let error = states[item.id]?.error {
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                Text(item.label).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textPrimary)
                Text(error).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.errorText)
            }
        }
    }

    /// 6.1: a read item full screen on the media stage — its name and the close key over the picture (or why it
    /// cannot show).
    private func viewer(_ item: PluginProtectedItem, _ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingSm) {
                Text(item.label).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                    .foregroundColor(colors.mediaOnStage).lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                IconButtonView(icon: "close", accessibilityLabel: strings.close, tint: colors.mediaOnStage) { viewing = nil }
            }
            .padding(.horizontal, FlareSizes.spacingLg)
            Spacer(minLength: 0)
            if let source = FlarePluginProtectedMedia.source(states[item.id]?.url), item.isImage {
                PluginProtectedImage(url: source, label: item.label)
            } else {
                Text(strings.pluginProtectedMediaNotPreviewable)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.mediaOnStage)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, FlareSizes.spacingMd)
    }
}

/// Fetches into memory only and draws the picture with no way to save or share it.
struct PluginProtectedImage: View {
    let url: URL
    let label: String
    @State private var data: Data?
    @State private var failed = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// An ephemeral session: no URL cache, no cookies, no credential store — nothing of the grant reaches a disk.
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        return URLSession(configuration: configuration)
    }()

    static func load(_ url: URL) async -> Data? {
        if url.scheme == "data" { return try? Data(contentsOf: url) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpShouldHandleCookies = false
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true else { return nil }
        return data
    }

    var body: some View {
        Group {
            if let data, let image = Self.image(data) {
                image.resizable().scaledToFit()
                    .accessibilityLabel(label)
                    .privacySensitive()
                    // No touch reaches the picture: no long-press menu, no drag, no share or save.
                    .allowsHitTesting(false)
            } else if failed {
                Text(strings.pluginProtectedMediaUnavailable)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(FlareColors.of(scheme, brand: flareBrandTheme).errorText)
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            data = nil; failed = false
            let loaded = await Self.load(url)
            data = loaded; failed = loaded == nil
        }
    }

    static func image(_ data: Data) -> Image? {
        #if canImport(UIKit)
        return UIImage(data: data).map(Image.init(uiImage:))
        #elseif canImport(AppKit)
        return NSImage(data: data).map(Image.init(nsImage:))
        #else
        return nil
        #endif
    }
}
