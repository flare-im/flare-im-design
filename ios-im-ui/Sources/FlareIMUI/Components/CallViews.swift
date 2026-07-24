import SwiftUI

/// Audio vs video call — spec union `'audio' | 'video'`.
public enum FlareCallMode: Sendable { case audio, video }
/// Call state — spec union `'calling' | 'ringing' | 'connected'`.
public enum FlareCallState: Sendable { case calling, ringing, connected }

/// Call control bar. Spec: Call/CallControls (`CallControlsView`).
public struct CallControlsView: View {
    private let muted: Bool
    private let cameraOn: Bool
    private let speakerOn: Bool
    private let mode: FlareCallMode
    private let onToggleMute: (() -> Void)?
    private let onToggleCamera: (() -> Void)?
    private let onToggleSpeaker: (() -> Void)?
    private let onSwitchCamera: (() -> Void)?
    private let onHangup: (() -> Void)?

    public init(muted: Bool = false, cameraOn: Bool = true, speakerOn: Bool = false, mode: FlareCallMode = .video,
                onToggleMute: (() -> Void)? = nil, onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onHangup: (() -> Void)? = nil) {
        self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn; self.mode = mode
        self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera; self.onToggleSpeaker = onToggleSpeaker
        self.onSwitchCamera = onSwitchCamera; self.onHangup = onHangup
    }

    public var body: some View {
        HStack(spacing: FlareSizes.spacingLg) {
            ctrl(muted ? "mic.slash" : "mic", "麦克风", muted, onToggleMute)
            if mode == .video {
                ctrl(cameraOn ? "video" : "video.slash", "摄像头", !cameraOn, onToggleCamera)
                ctrl("arrow.triangle.2.circlepath.camera", "翻转", false, onSwitchCamera)
            } else {
                ctrl("speaker.wave.2", "扬声器", speakerOn, onToggleSpeaker)
            }
            hangup
        }
    }

    private func ctrl(_ icon: String, _ label: String, _ on: Bool, _ action: (() -> Void)?) -> some View {
        VStack(spacing: 6) {
            Button { action?() } label: {
                Image(systemName: icon).font(.system(size: 22))
                    .foregroundColor(on ? .black : .white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(on ? Color.white : Color.white.opacity(0.16)))
            }
            .buttonStyle(.plain)
            Text(label).font(.system(size: 11)).foregroundColor(.white.opacity(0.75))
        }
    }

    private var hangup: some View {
        Button { onHangup?() } label: {
            Image(systemName: "phone.down").font(.system(size: 22)).foregroundColor(.white)
                .frame(width: 56, height: 56).background(Circle().fill(Color(.sRGB, red: 0.937, green: 0.267, blue: 0.267, opacity: 1)))
        }
        .buttonStyle(.plain)
    }
}

/// In-call screen. Spec: Call/CallView (`CallView`). Video track injected by host.
public struct CallView: View {
    private let peerName: String
    private let mode: FlareCallMode
    private let state: FlareCallState
    private let durationLabel: String?
    private let peerAvatarURL: String?
    private let muted: Bool
    private let cameraOn: Bool
    private let speakerOn: Bool
    private let video: AnyView?
    private let onHangup: (() -> Void)?
    private let onToggleMute: (() -> Void)?
    private let onToggleCamera: (() -> Void)?
    private let onToggleSpeaker: (() -> Void)?
    private let onSwitchCamera: (() -> Void)?

    public init(peerName: String, mode: FlareCallMode, state: FlareCallState, durationLabel: String? = nil,
                peerAvatarURL: String? = nil, muted: Bool = false, cameraOn: Bool = true, speakerOn: Bool = false,
                video: AnyView? = nil, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil, onSwitchCamera: (() -> Void)? = nil) {
        self.peerName = peerName; self.mode = mode; self.state = state; self.durationLabel = durationLabel
        self.peerAvatarURL = peerAvatarURL; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.video = video; self.onHangup = onHangup; self.onToggleMute = onToggleMute
        self.onToggleCamera = onToggleCamera; self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera
    }

    private var statusText: String {
        switch state {
        case .connected: return durationLabel ?? "已接通"
        case .ringing: return "响铃中…"
        case .calling: return mode == .video ? "等待接听…" : "呼叫中…"
        }
    }

    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.066, green: 0.075, blue: 0.094, opacity: 1).ignoresSafeArea()
            if mode == .video, let video { video }
            VStack(spacing: FlareSizes.spacingSm) {
                if mode == .audio || video == nil {
                    AvatarView(userId: peerName, displayName: peerName, avatarURL: peerAvatarURL, size: 96)
                }
                Text(peerName).font(.system(size: FlareSizes.fontSize4xl, weight: .semibold)).foregroundColor(.white)
                Text(statusText).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 160)
            VStack {
                Spacer()
                CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                                 onToggleMute: onToggleMute, onToggleCamera: onToggleCamera, onToggleSpeaker: onToggleSpeaker,
                                 onSwitchCamera: onSwitchCamera, onHangup: onHangup)
                    .padding(.bottom, 48)
            }
        }
    }
}

/// Incoming call / invite. Spec: Call/IncomingCall (`IncomingCallView`).
public struct IncomingCallView: View {
    private let callerName: String
    private let mode: FlareCallMode
    private let callerAvatarURL: String?
    private let onAccept: (() -> Void)?
    private let onReject: (() -> Void)?

    public init(callerName: String, mode: FlareCallMode, callerAvatarURL: String? = nil,
                onAccept: (() -> Void)? = nil, onReject: (() -> Void)? = nil) {
        self.callerName = callerName; self.mode = mode; self.callerAvatarURL = callerAvatarURL
        self.onAccept = onAccept; self.onReject = onReject
    }

    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.066, green: 0.075, blue: 0.094, opacity: 1).ignoresSafeArea()
            VStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: callerName, displayName: callerName, avatarURL: callerAvatarURL, size: 104)
                Text(callerName).font(.system(size: FlareSizes.fontSize4xl, weight: .semibold)).foregroundColor(.white)
                Text(mode == .video ? "邀请你进行视频通话" : "邀请你进行语音通话").font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(.white.opacity(0.7))
            }.padding(.bottom, 120)
            VStack {
                Spacer()
                HStack {
                    action("phone.down", "拒绝", Color(.sRGB, red: 0.937, green: 0.267, blue: 0.267, opacity: 1), onReject)
                    Spacer()
                    action(mode == .video ? "video" : "phone", "接听", Color(.sRGB, red: 0.133, green: 0.773, blue: 0.369, opacity: 1), onAccept)
                }
                .padding(.horizontal, 56).padding(.bottom, 56)
            }
        }
    }

    private func action(_ icon: String, _ label: String, _ color: Color, _ handler: (() -> Void)?) -> some View {
        VStack(spacing: 8) {
            Button { handler?() } label: {
                Image(systemName: icon).font(.system(size: 24)).foregroundColor(.white)
                    .frame(width: 64, height: 64).background(Circle().fill(color))
            }.buttonStyle(.plain)
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.8))
        }
    }
}
