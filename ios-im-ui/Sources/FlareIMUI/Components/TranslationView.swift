import SwiftUI

// MARK: - Translation

/// Translation bubble — machine-translated text with original toggle.
/// Spec: Message/Translation (`TranslationView`).
public struct TranslationView: View {
    private let translated: String
    private let original: String?
    private let provider: String?
    private let pending: Bool
    @Environment(\.colorScheme) private var scheme
    @State private var showOriginal = false
    @State private var spinning = false

    public init(translated: String, original: String? = nil, provider: String? = nil, pending: Bool = false) {
        self.translated = translated; self.original = original; self.provider = provider; self.pending = pending
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            Rectangle().fill(colors.primary.opacity(0.4)).frame(width: 2)
            content(colors)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func content(_ colors: FlareColors) -> some View {
        if pending {
            HStack(spacing: 6) {
                Image(systemName: "globe").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    .rotationEffect(.degrees(spinning ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: spinning)
                Text("翻译中…").font(.system(size: 14)).foregroundColor(colors.textTertiary)
            }
            .onAppear { spinning = true }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(translated).font(.system(size: 14)).foregroundColor(colors.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "globe").font(.system(size: 11)).foregroundColor(colors.textTertiary)
                    Text(provider != nil ? "由 \(provider!) 翻译" : "已翻译")
                        .font(.system(size: 11)).foregroundColor(colors.textTertiary)
                    Spacer(minLength: FlareSizes.spacingMd)
                    if original != nil {
                        Button { showOriginal.toggle() } label: {
                            HStack(spacing: 3) {
                                Text(showOriginal ? "隐藏原文" : "显示原文")
                                    .font(.system(size: 11, weight: .medium))
                                Image(systemName: "chevron.down").font(.system(size: 9))
                                    .rotationEffect(.degrees(showOriginal ? 180 : 0))
                            }.foregroundColor(colors.primary)
                        }.buttonStyle(.plain)
                    }
                }
                if let original, showOriginal {
                    Divider().overlay(colors.borderPrimary)
                    Text(original).font(.system(size: 13)).foregroundColor(colors.textSecondary)
                }
            }
        }
    }
}
