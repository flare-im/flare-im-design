import SwiftUI

// MARK: - GroupCallView

/// Group (multi-party) call — participant grid + controls.
/// Spec: Call/GroupCallView (`GroupCallView`).
public struct GroupCallView: View {
    private let participants: [CallParticipant]
    private let mode: FlareCallMode
    private let state: FlareCallState
    private let title: String?
    private let durationLabel: String?
    private let muted: Bool
    private let cameraOn: Bool
    private let speakerOn: Bool
    private let onHangup: (() -> Void)?
    private let onToggleMute: (() -> Void)?
    private let onToggleCamera: (() -> Void)?
    private let onToggleSpeaker: (() -> Void)?
    private let onSwitchCamera: (() -> Void)?
    private let onMinimize: (() -> Void)?
    private let onAddMember: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(participants: [CallParticipant], mode: FlareCallMode, state: FlareCallState,
                title: String? = nil, durationLabel: String? = nil, muted: Bool = false, cameraOn: Bool = true,
                speakerOn: Bool = false, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onMinimize: (() -> Void)? = nil, onAddMember: (() -> Void)? = nil) {
        self.participants = participants; self.mode = mode; self.state = state; self.title = title
        self.durationLabel = durationLabel; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.onHangup = onHangup; self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera
        self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera; self.onMinimize = onMinimize
        self.onAddMember = onAddMember
    }

    private var cols: Int {
        let n = participants.count
        if n <= 1 { return 1 }; if n <= 4 { return 2 }; if n <= 9 { return 3 }; return 4
    }
    private var statusText: String {
        if state == .reconnecting { return strings.callReconnecting }
        if state == .failed { return strings.callFailed }
        if state == .connected { return durationLabel ?? strings.callConnected }
        if state == .ringing { return strings.callRinging }
        return strings.callCalling
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { onMinimize?() } label: {
                    Image(systemName: flareIconSymbol("collapse")).font(.system(size: 20)).foregroundColor(.white)
                        .frame(width: 36, height: 36).background(Circle().fill(Color.white.opacity(0.12)))
                        .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .flareCompactLayout(width: 36, height: 36)
                .accessibilityLabel(strings.callMinimize)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? strings.groupCall).font(.system(size: 16, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text(strings.joinedCount(participants.count, statusText)).font(.system(size: 12)).foregroundColor(.white.opacity(0.62))
                }
                Spacer()
            }.padding(.horizontal, 16).padding(.top, FlareSizes.spacing2md).padding(.bottom, 4)

            let grid = Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
            ScrollView {
                LazyVGrid(columns: grid, spacing: 8) {
                    ForEach(participants) { p in tile(p) }
                }.padding(.horizontal, 12).padding(.top, 4)
            }

            CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                             onToggleMute: onToggleMute, onToggleCamera: onToggleCamera,
                             onToggleSpeaker: onToggleSpeaker, onSwitchCamera: onSwitchCamera, onHangup: onHangup,
                             onAddMember: onAddMember)
                .padding(.vertical, 20).padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(.sRGB, red: 0.094, green: 0.094, blue: 0.106, opacity: 1),
                                    Color(.sRGB, red: 0.063, green: 0.063, blue: 0.071, opacity: 1),
                                    Color(.sRGB, red: 0.035, green: 0.035, blue: 0.043, opacity: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func tile(_ p: CallParticipant) -> some View {
        let colors = FlareColors.of(.dark, brand: flareBrandTheme)
        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(p.isSelf ? colors.primary.opacity(0.16) : Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(p.speaking ? Color(.sRGB, red: 0.204, green: 0.82, blue: 0.498, opacity: 1) : .clear, lineWidth: 2))
                .aspectRatio(0.86, contentMode: .fit)
            AvatarView(userId: p.id, displayName: p.name, avatarURL: p.avatarURL, size: 56)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 5) {
                if p.muted {
                    Image(systemName: flareIconSymbol("mic-off")).font(.system(size: FlareSizes.fontSize2xs)).foregroundColor(.white)
                        .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
                } else if p.cameraOff && mode == .video {
                    Image(systemName: flareIconSymbol("camera-off")).font(.system(size: FlareSizes.fontSize2xs)).foregroundColor(.white)
                        .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
                }
                Text(p.isSelf ? strings.selfSuffix(p.name) : p.name).font(.system(size: 12)).foregroundColor(.white).lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
            }.padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
