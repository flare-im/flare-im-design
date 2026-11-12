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
struct PluginProtectedMediaBlockView: View {
    let block: PluginProtectedMediaBlock
    let states: [String: PluginProtectedMediaState]
    let busy: Bool
    let onRead: ((PluginProtectedMediaRead) -> Void)?
    @State private var asking: PluginProtectedItem?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// The read the block hands the host for `item` with `reason` (empty when none is asked).
    static func read(_ block: PluginProtectedMediaBlock, item: PluginProtectedItem, reason: String) -> PluginProtectedMediaRead? {
        guard let action = block.action else { return nil }
        var values: [String: PluginJSONValue] = [block.inputName: .string(item.id)]
        if let reasonInput = block.reasonInput { values[reasonInput] = .string(reason) }
        return PluginProtectedMediaRead(action: action, item: item, reason: reason, urlPath: block.urlPath,
                                        formValues: values)
    }

    private func request(_ item: PluginProtectedItem) {
        guard !busy, let onRead else { return }
        if block.asksReason { asking = item } else if let read = Self.read(block, item: item, reason: "") { onRead(read) }
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if let label = block.label, !label.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeMd, weight: .medium)).foregroundColor(colors.textPrimary)
            }
            if block.items.isEmpty {
                Text(block.emptyText ?? strings.pluginViewEmpty)
                    .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            ForEach(block.items, id: \.id) { item in itemView(item, colors) }
            Text(block.asksReason ? strings.pluginProtectedMediaNotice : strings.pluginProtectedMediaOwnNotice)
                .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
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

    @ViewBuilder private func itemView(_ item: PluginProtectedItem, _ colors: FlareColors) -> some View {
        let state = states[item.id]
        let source = FlarePluginProtectedMedia.source(state?.url)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack(spacing: FlareSizes.spacingSm) {
                Text(item.label).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textPrimary)
                Spacer(minLength: FlareSizes.spacingSm)
                if let action = block.action, source == nil {
                    ButtonView(label: block.asksReason ? action.label : strings.pluginProtectedMediaView,
                               variant: .secondary, size: .sm, loading: state?.loading == true,
                               disabled: busy || onRead == nil || state?.loading == true) { request(item) }
                        .accessibilityIdentifier("plugin.media.\(item.id).read")
                }
            }
            if let source {
                if item.isImage {
                    PluginProtectedImage(url: source, label: item.label)
                        .frame(maxWidth: .infinity, maxHeight: FlareSizes.componentRichCardWidth)
                        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd))
                } else {
                    Text(strings.pluginProtectedMediaNotPreviewable)
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                }
            }
            if let error = state?.error {
                Text(error).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.errorText)
            }
        }
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
