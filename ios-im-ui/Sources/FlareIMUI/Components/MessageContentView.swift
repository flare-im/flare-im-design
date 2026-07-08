import SwiftUI

/// Context passed to every content renderer.
public struct FlareContentContext {
    public let isSelf: Bool
    public let previewMode: Bool
    public let senderName: String?
    public let mediaState: FlareMediaDownloadState?
    public let onMediaAction: ((FlareMessageContent) -> Void)?

    public init(
        isSelf: Bool,
        previewMode: Bool = false,
        senderName: String? = nil,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageContent) -> Void)? = nil
    ) {
        self.isSelf = isSelf
        self.previewMode = previewMode
        self.senderName = senderName
        self.mediaState = mediaState
        self.onMediaAction = onMediaAction
    }
}

public typealias FlareContentBuilder = (FlareMessageContent, FlareContentContext) -> AnyView

/// Registry for product content types (`vote`, `task`…). Built-in types are
/// rendered directly by ``MessageContentView``; register a builder to add or
/// override a type.
public enum FlareContentRegistry {
    private static var builders: [String: FlareContentBuilder] = [:]
    public static func register(_ type: String, _ builder: @escaping FlareContentBuilder) {
        builders[type] = builder
    }
    public static func unregister(_ type: String) { builders.removeValue(forKey: type) }
    public static func lookup(_ type: String) -> FlareContentBuilder? { builders[type] }
}

/// Content-type dispatcher — renders a message body by type. Spec:
/// Message/MessageContentView (`MessageContentView`).
public struct MessageContentView: View {
    private let content: FlareMessageContent
    private let ctx: FlareContentContext
    @Environment(\.colorScheme) private var scheme

    public init(
        content: FlareMessageContent,
        isSelf: Bool = false,
        previewMode: Bool = false,
        senderName: String? = nil,
        mediaState: FlareMediaDownloadState? = nil,
        onMediaAction: ((FlareMessageContent) -> Void)? = nil
    ) {
        self.content = content
        self.ctx = FlareContentContext(
            isSelf: isSelf, previewMode: previewMode, senderName: senderName,
            mediaState: mediaState, onMediaAction: onMediaAction)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let onBubble = ctx.isSelf ? Color.white : colors.textPrimary

        if let custom = FlareContentRegistry.lookup(content.type) {
            custom(content, ctx)
        } else {
            switch content {
            case let c as FlareTextContent:
                Text(c.text)
                    .font(.system(size: FlareSizes.fontSizeXl))
                    .lineSpacing(4)
                    .foregroundColor(onBubble)
            case let c as FlareEmojiContent:
                Text(c.emoji).font(.system(size: 34))
            case let c as FlareStickerContent:
                mediaThumb(c.url, side: 96, colors: colors, fallback: "square.on.square")
            case let c as FlareImageContent:
                imageBody(c.thumbnailURL ?? c.url, colors: colors)
            case let c as FlareVideoContent:
                videoBody(c, colors: colors)
            case let c as FlareAudioContent:
                Label(Self.duration(c.durationSec), systemImage: "speaker.wave.2")
                    .foregroundColor(onBubble)
            case let c as FlareFileContent:
                fileBody(c, fg: onBubble, colors: colors)
            case let c as FlareLocationContent:
                locationBody(c, fg: onBubble, colors: colors)
            case let c as FlareCardContent:
                cardBody(c, colors: colors)
            case let c as FlarePlaceholderContent:
                chip(c.label, colors: colors)
            case let c as FlareGenericContent:
                chip("[\(c.label)]", colors: colors)
            default:
                chip("[\(content.type)]", colors: colors)
            }
        }
    }

    private func imageBody(_ url: String, colors: FlareColors) -> some View {
        ZStack {
            asyncImage(url, colors: colors, fallback: "photo")
                .frame(maxWidth: 240, maxHeight: 240)
            if ctx.mediaState?.isDownloading == true {
                Color.black.opacity(0.35)
                Text("\(ctx.mediaState?.progressPct ?? 0)%").foregroundColor(.white).bold()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        .onTapGesture { ctx.onMediaAction?(content) }
    }

    private func videoBody(_ c: FlareVideoContent, colors: FlareColors) -> some View {
        ZStack {
            if let poster = c.poster, !poster.isEmpty {
                asyncImage(poster, colors: colors, fallback: "film").frame(maxWidth: 240, maxHeight: 240)
            } else {
                colors.bgTertiary.frame(width: 200, height: 130)
            }
            Image(systemName: "play.circle.fill").font(.system(size: 44)).foregroundColor(.white.opacity(0.9))
        }
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        .onTapGesture { ctx.onMediaAction?(content) }
    }

    private func fileBody(_ c: FlareFileContent, fg: Color, colors: FlareColors) -> some View {
        HStack {
            Image(systemName: "doc").font(.system(size: 26)).foregroundColor(fg)
            VStack(alignment: .leading) {
                Text(c.name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                    .foregroundColor(fg).lineLimit(1).frame(maxWidth: 180, alignment: .leading)
                if c.sizeBytes > 0 {
                    Text(Self.bytes(c.sizeBytes)).font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(fg.opacity(0.7))
                }
            }
        }
        .onTapGesture { ctx.onMediaAction?(content) }
    }

    private func locationBody(_ c: FlareLocationContent, fg: Color, colors: FlareColors) -> some View {
        HStack {
            Image(systemName: "mappin.circle").font(.system(size: 22)).foregroundColor(colors.error)
            VStack(alignment: .leading) {
                Text(c.name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(fg)
                if !c.address.isEmpty {
                    Text(c.address).font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(fg.opacity(0.7)).lineLimit(1).frame(maxWidth: 200, alignment: .leading)
                }
            }
        }
    }

    private func cardBody(_ c: FlareCardContent, colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let img = c.imageURL, !img.isEmpty {
                asyncImage(img, colors: colors, fallback: "photo").frame(height: 120).clipped()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(c.title).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary).lineLimit(2)
                if let sub = c.subtitle, !sub.isEmpty {
                    Text(sub).font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textSecondary).lineLimit(2)
                }
                if let src = c.sourceLabel, !src.isEmpty {
                    Text(src).font(.system(size: FlareSizes.fontSizeXs)).foregroundColor(colors.textTertiary)
                }
            }
            .padding(FlareSizes.spacingMd)
        }
        .frame(maxWidth: 240)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary))
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderSecondary))
    }

    private func chip(_ label: String, colors: FlareColors) -> some View {
        Text(label)
            .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.bgTertiary))
    }

    private func mediaThumb(_ url: String, side: CGFloat, colors: FlareColors, fallback: String) -> some View {
        asyncImage(url, colors: colors, fallback: fallback).frame(width: side, height: side)
    }

    private func asyncImage(_ url: String, colors: FlareColors, fallback: String) -> some View {
        Group {
            if let u = URL(string: url), !url.isEmpty {
                AsyncImage(url: u) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    fallbackTile(colors: colors, symbol: fallback)
                }
            } else {
                fallbackTile(colors: colors, symbol: fallback)
            }
        }
    }

    private func fallbackTile(colors: FlareColors, symbol: String) -> some View {
        ZStack {
            colors.bgTertiary
            Image(systemName: symbol).font(.system(size: 32)).foregroundColor(colors.textTertiary)
        }
    }

    static func duration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    static func bytes(_ b: Int) -> String {
        if b < 1024 { return "\(b) B" }
        if b < 1024 * 1024 { return String(format: "%.1f KB", Double(b) / 1024) }
        if b < 1024 * 1024 * 1024 { return String(format: "%.1f MB", Double(b) / 1024 / 1024) }
        return String(format: "%.1f GB", Double(b) / 1024 / 1024 / 1024)
    }
}
