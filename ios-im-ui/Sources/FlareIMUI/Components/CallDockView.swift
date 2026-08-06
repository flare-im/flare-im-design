import SwiftUI

// MARK: - CallDock

/// Minimized call dock — capsule pill to return to an ongoing call.
/// Spec: Call/CallDock (`CallDockView`).
public struct CallDockView: View {
    private let title: String
    private let avatarURL: String?
    private let durationLabel: String?
    private let mode: FlareCallMode
    private let muted: Bool
    private let onExpand: (() -> Void)?
    private let onToggleMute: (() -> Void)?
    private let onHangup: (() -> Void)?
    @State private var pulsing = false

    public init(title: String, avatarURL: String? = nil, durationLabel: String? = nil,
                mode: FlareCallMode = .audio, muted: Bool = false,
                onExpand: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil, onHangup: (() -> Void)? = nil) {
        self.title = title; self.avatarURL = avatarURL; self.durationLabel = durationLabel
        self.mode = mode; self.muted = muted
        self.onExpand = onExpand; self.onToggleMute = onToggleMute; self.onHangup = onHangup
    }

    public var body: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            Button { onExpand?() } label: {
                HStack(spacing: FlareSizes.spacingMd) {
                    ZStack {
                        AvatarView(userId: title, displayName: title, avatarURL: avatarURL, size: 34)
                        Circle().stroke(Color(.sRGB, red: 0.204, green: 0.82, blue: 0.498, opacity: 1), lineWidth: 2)
                            .frame(width: 34, height: 34)
                            .scaleEffect(pulsing ? 1.18 : 1)
                            .opacity(pulsing ? 0 : 0.9)
                            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsing)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            .lineLimit(1).frame(maxWidth: 120, alignment: .leading)
                        HStack(spacing: 4) {
                            Image(systemName: mode == .video ? "video" : "phone").font(.system(size: 12))
                            Text(durationLabel ?? "通话中").font(.system(size: 12))
                        }.foregroundColor(.white.opacity(0.66))
                    }
                    Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            Button { onToggleMute?() } label: {
                Image(systemName: muted ? "mic.slash.fill" : "mic.fill").font(.system(size: 14))
                    .foregroundColor(muted ? Color(.sRGB, red: 0.098, green: 0.075, blue: 0.125, opacity: 1) : .white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(muted ? Color.white : Color.white.opacity(0.14)))
            }.buttonStyle(.plain)

            Button { onHangup?() } label: {
                Image(systemName: "phone.fill").font(.system(size: 14)).foregroundColor(.white)
                    .rotationEffect(.degrees(135))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(FlareColors.of(.dark).error))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 8)
        .background(
            Capsule().fill(
                LinearGradient(colors: [Color(.sRGB, red: 0.165, green: 0.141, blue: 0.220, opacity: 1),
                                        Color(.sRGB, red: 0.098, green: 0.075, blue: 0.125, opacity: 1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: Color.black.opacity(0.28), radius: 20, y: 8)
        .onAppear { pulsing = true }
    }
}
