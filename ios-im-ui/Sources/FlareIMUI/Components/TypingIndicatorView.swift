import SwiftUI

// MARK: - TypingIndicator

/// Typing indicator — bouncing dots, single / multi-typer copy.
/// Spec: Message/TypingIndicator (`TypingIndicatorView`).
public enum TypingVariant: Sendable { case bubble, inline }

public struct TypingIndicatorView: View {
    private let names: [String]
    private let userId: String?
    private let avatarURL: String?
    private let variant: TypingVariant
    @Environment(\.colorScheme) private var scheme
    @State private var animating = false

    public init(names: [String] = [], userId: String? = nil, avatarURL: String? = nil,
                variant: TypingVariant = .bubble) {
        self.names = names; self.userId = userId; self.avatarURL = avatarURL; self.variant = variant
    }

    private var label: String {
        let n = names.filter { !$0.isEmpty }
        if n.isEmpty { return "正在输入…" }
        if n.count == 1 { return "\(n[0]) 正在输入…" }
        return "\(n.count) 人正在输入…"
    }

    private func dots(_ colors: FlareColors) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill((variant == .bubble ? colors.primary.opacity(0.65) : colors.textTertiary))
                    .frame(width: 6, height: 6)
                    .offset(y: animating ? -4 : 0)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15), value: animating)
            }
        }
        .onAppear { animating = true }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let body = HStack(spacing: 8) {
            if variant == .inline || !names.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
            }
            dots(colors)
        }
        .padding(variant == .bubble ? EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14) : EdgeInsets())
        .background(
            variant == .bubble
                ? AnyView(RoundedRectangle(cornerRadius: 16).fill(colors.bgPrimary)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.borderPrimary, lineWidth: 1)))
                : AnyView(Color.clear)
        )

        if variant == .inline {
            body
        } else {
            HStack(alignment: .bottom, spacing: FlareSizes.spacingSm) {
                AvatarView(userId: names.first ?? (userId ?? "typing"),
                           displayName: names.first ?? (userId ?? "typing"), avatarURL: avatarURL, size: 32)
                body
            }
        }
    }
}
