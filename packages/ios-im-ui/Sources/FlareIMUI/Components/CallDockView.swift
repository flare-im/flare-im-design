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
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(title: String, avatarURL: String? = nil, durationLabel: String? = nil,
                mode: FlareCallMode = .audio, muted: Bool = false,
                onExpand: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil, onHangup: (() -> Void)? = nil) {
        self.title = title; self.avatarURL = avatarURL; self.durationLabel = durationLabel
        self.mode = mode; self.muted = muted
        self.onExpand = onExpand; self.onToggleMute = onToggleMute; self.onHangup = onHangup
    }

    public var body: some View {
        let colors = FlareColors.of(.dark, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingMd) {
            Button { onExpand?() } label: {
                HStack(spacing: FlareSizes.spacingMd) {
                    // 40pt ring in the success token (Android / Flutter parity) with a pulsing echo.
                    ZStack {
                        AvatarView(userId: title, displayName: title, avatarURL: avatarURL, size: 34)
                        Circle().stroke(colors.success, lineWidth: 2)
                            .frame(width: 40, height: 40)
                        Circle().stroke(colors.success, lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .scaleEffect(pulsing ? 1.18 : 1)
                            .opacity(pulsing ? 0 : 0.9)
                            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsing)
                    }
                    .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(colors.messageOutgoingForeground)
                            .lineLimit(1).frame(maxWidth: 120, alignment: .leading)
                        HStack(spacing: 4) {
                            Image(systemName: mode == .video ? "video" : "phone").font(.system(size: 12))
                            Text(durationLabel ?? strings.callInProgress).font(.system(size: 12))
                        }.foregroundColor(colors.messageOutgoingForeground.opacity(0.66))
                    }
                    Image(systemName: flareIconSymbol("expand")).font(.system(size: 16)).foregroundColor(colors.messageOutgoingForeground.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            // Named by what it does — back to the full call — with the call's title as the value.
            .accessibilityLabel(strings.callReturn)
            .accessibilityValue(title)

            Button { onToggleMute?() } label: {
                Image(systemName: flareIconSymbol(muted ? "mic-off" : "mic")).font(.system(size: 18))
                    .foregroundColor(muted ? colors.messageOutgoingBackground : colors.messageOutgoingForeground)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(muted ? colors.messageOutgoingForeground : colors.messageOutgoingForeground.opacity(0.14)))
                    .flareTouchTarget()
            }
            .buttonStyle(.plain)
            .flareCompactLayout(width: 36, height: 36)
            // Named by the device, valued by whether it is on (a muted microphone is off).
            .accessibilityLabel(strings.microphone)
            .accessibilityValue(CallControlsView.deviceState(on: !muted, strings))

            // Hang up is its own glyph, not a rotated handset.
            Button { onHangup?() } label: {
                Image(systemName: flareIconSymbol("end-call")).font(.system(size: 18)).foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(colors.error))
                    .flareTouchTarget()
            }
            .buttonStyle(.plain)
            .flareCompactLayout(width: 36, height: 36)
            .accessibilityLabel(strings.hangUp)
        }
        .padding(.horizontal, 8).padding(.vertical, 8)
        .background(Capsule().fill(colors.messageOutgoingBackground))
        .shadow(color: Color.black.opacity(0.28), radius: 20, y: 8)
        .onAppear { pulsing = true }
    }
}
