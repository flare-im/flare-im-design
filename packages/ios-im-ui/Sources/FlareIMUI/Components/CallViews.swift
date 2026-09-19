import SwiftUI

/// Audio vs video call — spec union `'audio' | 'video'`.
public enum FlareCallMode: Sendable { case audio, video }
/// Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed'`.
public enum FlareCallState: Sendable { case calling, ringing, connected, reconnecting, failed }

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
    private let onAddMember: (() -> Void)?
    @Environment(\.flareStrings) private var strings

    public init(muted: Bool = false, cameraOn: Bool = true, speakerOn: Bool = false, mode: FlareCallMode = .video,
                onToggleMute: (() -> Void)? = nil, onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onHangup: (() -> Void)? = nil, onAddMember: (() -> Void)? = nil) {
        self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn; self.mode = mode
        self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera; self.onToggleSpeaker = onToggleSpeaker
        self.onSwitchCamera = onSwitchCamera; self.onHangup = onHangup; self.onAddMember = onAddMember
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72, maximum: 112), spacing: FlareSizes.spacingLg)], spacing: FlareSizes.spacingLg) {
            ctrl(muted ? "mic-off" : "mic", strings.microphone, muted, onToggleMute,
                 state: Self.deviceState(on: !muted, strings))
            if mode == .video {
                ctrl(cameraOn ? "video" : "camera-off", strings.camera, !cameraOn, onToggleCamera,
                     state: Self.deviceState(on: cameraOn, strings))
                ctrl("switch-camera", strings.flipCamera, false, onSwitchCamera)
            } else {
                ctrl(speakerOn ? "speaker" : "speaker-off", strings.speaker, speakerOn, onToggleSpeaker,
                     state: Self.deviceState(on: speakerOn, strings))
            }
            if let onAddMember {
                ctrl("person-add", strings.addMember, false, onAddMember)
            }
            hangup
        }
    }

    /// A device toggle's value: whether the device (microphone, camera, speaker) is on — so a muted
    /// microphone reads "off", as on the Vue and Compose kits.
    static func deviceState(on: Bool, _ strings: FlareStrings) -> String {
        on ? strings.callDeviceOn : strings.callDeviceOff
    }

    /// One control: the kit icon `icon`, named by the device or action `label`, with the device's
    /// on/off `state` as the value; `on` fills the disc (a muted microphone, a camera that is off, a
    /// speaker that is on).
    private func ctrl(_ icon: String, _ label: String, _ on: Bool, _ action: (() -> Void)?, state: String = "") -> some View {
        VStack(spacing: 6) {
            Button { action?() } label: {
                Image(systemName: flareIconSymbol(icon)).font(.system(size: 24))
                    .foregroundColor(on ? .black : .white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(on ? Color.white : Color.white.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .disabled(action == nil)
            .accessibilityLabel(label)
            .accessibilityValue(state)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center).accessibilityHidden(true)
        }
    }

    private var hangup: some View {
        Button { onHangup?() } label: {
            Image(systemName: flareIconSymbol("end-call")).font(.system(size: 24)).foregroundColor(.white)
                .frame(width: 56, height: 56).background(Circle().fill(Color(.sRGB, red: 0.937, green: 0.267, blue: 0.267, opacity: 1)))
        }
        .buttonStyle(.plain)
        .disabled(onHangup == nil)
        .accessibilityLabel(strings.hangUp)
    }
}

/// In-call screen. Spec: Call/CallView (`CallView`). Video track injected by host.
public struct CallView: View {
    private let peerName: String
    private let mode: FlareCallMode
    private let state: FlareCallState
    private let statusDetail: String?
    private let recoveryText: String?
    private let onRecover: (() -> Void)?
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
    @Environment(\.flareStrings) private var strings

    public init(peerName: String, mode: FlareCallMode, state: FlareCallState, durationLabel: String? = nil,
                peerAvatarURL: String? = nil, muted: Bool = false, cameraOn: Bool = true, speakerOn: Bool = false,
                video: AnyView? = nil, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil, onSwitchCamera: (() -> Void)? = nil,
                statusDetail: String? = nil, recoveryText: String? = nil, onRecover: (() -> Void)? = nil) {
        self.statusDetail = statusDetail; self.recoveryText = recoveryText; self.onRecover = onRecover
        self.peerName = peerName; self.mode = mode; self.state = state; self.durationLabel = durationLabel
        self.peerAvatarURL = peerAvatarURL; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.video = video; self.onHangup = onHangup; self.onToggleMute = onToggleMute
        self.onToggleCamera = onToggleCamera; self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera
    }

    private var statusText: String {
        switch state {
        case .reconnecting: return strings.callReconnecting
        case .failed: return strings.callFailed
        case .connected: return durationLabel ?? strings.callConnected
        case .ringing: return strings.callRinging
        case .calling: return mode == .video ? strings.callWaitingAnswer : strings.callCalling
        }
    }

    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.066, green: 0.075, blue: 0.094, opacity: 1).ignoresSafeArea()
            if mode == .video, let video { video }
            ScrollView {
                VStack(spacing: FlareSizes.spacingSm) {
                    if mode == .audio || video == nil {
                        AvatarView(userId: peerName, displayName: peerName, avatarURL: peerAvatarURL, size: 96)
                    }
                    Text(peerName).font(.title).foregroundColor(.white).multilineTextAlignment(.center)
                    Text(statusText).font(.body).foregroundColor(.white.opacity(0.7))
                    if let statusDetail { Text(statusDetail).foregroundColor(.white).multilineTextAlignment(.center) }
                    if state == .failed, let recoveryText {
                        // The 44pt target belongs to the label: a borderless button is hit by its label only.
                        Button { onRecover?() } label: { Text(recoveryText).flareTouchTarget() }
                            .disabled(onRecover == nil).tint(.white)
                    }
                    CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                                     onToggleMute: onToggleMute, onToggleCamera: onToggleCamera, onToggleSpeaker: onToggleSpeaker,
                                     onSwitchCamera: onSwitchCamera, onHangup: onHangup)
                        .padding(.top, 32)
                }.padding(.horizontal, 16).padding(.top, 72).padding(.bottom, 48)
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
    @Environment(\.flareStrings) private var strings

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
                Text(mode == .video ? strings.incomingVideoCall : strings.incomingVoiceCall).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(.white.opacity(0.7))
            }.padding(.bottom, 120)
            VStack {
                Spacer()
                HStack {
                    action("end-call", strings.reject, Color(.sRGB, red: 0.937, green: 0.267, blue: 0.267, opacity: 1), onReject)
                    Spacer()
                    action(mode == .video ? "video" : "phone", strings.accept, Color(.sRGB, red: 0.133, green: 0.773, blue: 0.369, opacity: 1), onAccept)
                }
                .padding(.horizontal, 56).padding(.bottom, 56)
            }
        }
    }

    /// Reject / accept: the kit icon `icon` on a 64pt disc, named `label`; the caption under it repeats
    /// the name for sight only.
    private func action(_ icon: String, _ label: String, _ color: Color, _ handler: (() -> Void)?) -> some View {
        VStack(spacing: 8) {
            Button { handler?() } label: {
                Image(systemName: flareIconSymbol(icon)).font(.system(size: 24)).foregroundColor(.white)
                    .frame(width: 64, height: 64).background(Circle().fill(color))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.8)).accessibilityHidden(true)
        }
    }
}
