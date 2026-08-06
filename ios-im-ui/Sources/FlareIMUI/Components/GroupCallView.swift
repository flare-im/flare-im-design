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

    public init(participants: [CallParticipant], mode: FlareCallMode, state: FlareCallState,
                title: String? = nil, durationLabel: String? = nil, muted: Bool = false, cameraOn: Bool = true,
                speakerOn: Bool = false, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onMinimize: (() -> Void)? = nil) {
        self.participants = participants; self.mode = mode; self.state = state; self.title = title
        self.durationLabel = durationLabel; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.onHangup = onHangup; self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera
        self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera; self.onMinimize = onMinimize
    }

    private var cols: Int {
        let n = participants.count
        if n <= 1 { return 1 }; if n <= 4 { return 2 }; if n <= 9 { return 3 }; return 4
    }
    private var statusText: String {
        if state == .connected { return durationLabel ?? "已接通" }
        if state == .ringing { return "响铃中…" }
        return "呼叫中…"
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { onMinimize?() } label: {
                    Image(systemName: "chevron.down").font(.system(size: 20)).foregroundColor(.white)
                        .frame(width: 36, height: 36).background(Circle().fill(Color.white.opacity(0.12)))
                }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "群通话").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text("\(participants.count) 人已加入 · \(statusText)").font(.system(size: 12)).foregroundColor(.white.opacity(0.62))
                }
                Spacer()
            }.padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)

            let grid = Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
            ScrollView {
                LazyVGrid(columns: grid, spacing: 8) {
                    ForEach(participants) { p in tile(p) }
                }.padding(.horizontal, 12).padding(.top, 4)
            }

            CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                             onToggleMute: onToggleMute, onToggleCamera: onToggleCamera,
                             onToggleSpeaker: onToggleSpeaker, onSwitchCamera: onSwitchCamera, onHangup: onHangup)
                .padding(.vertical, 20).padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(.sRGB, red: 0.129, green: 0.114, blue: 0.188, opacity: 1),
                                    Color(.sRGB, red: 0.09, green: 0.075, blue: 0.122, opacity: 1),
                                    Color(.sRGB, red: 0.063, green: 0.047, blue: 0.09, opacity: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func tile(_ p: CallParticipant) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(p.isSelf ? Color(.sRGB, red: 0.486, green: 0.227, blue: 0.929, opacity: 0.16) : Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(p.speaking ? Color(.sRGB, red: 0.204, green: 0.82, blue: 0.498, opacity: 1) : .clear, lineWidth: 2))
                .aspectRatio(0.86, contentMode: .fit)
            AvatarView(userId: p.id, displayName: p.name, avatarURL: p.avatarURL, size: 56)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 5) {
                if p.muted {
                    Image(systemName: "mic.slash.fill").font(.system(size: 10)).foregroundColor(.white)
                        .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
                } else if p.cameraOff && mode == .video {
                    Image(systemName: "video.slash.fill").font(.system(size: 10)).foregroundColor(.white)
                        .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
                }
                Text(p.isSelf ? "\(p.name)（我）" : p.name).font(.system(size: 12)).foregroundColor(.white).lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
            }.padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
