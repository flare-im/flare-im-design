import SwiftUI

/// Audio vs video call — spec union `'audio' | 'video'`.
public enum FlareCallMode: Sendable { case audio, video }
/// Call state — spec union `'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed' | 'ended'`.
public enum FlareCallState: Sendable { case calling, ringing, connected, reconnecting, failed, ended }

// MARK: - Stage

/// The call stage (docs/plugin-experience.md §3.0): one dark ground in both themes, the stage tint fading out over
/// the top 40%. Every call surface draws on it.
struct CallStageBackground: View {
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        LinearGradient(stops: [.init(color: c.callStageTint, location: 0),
                               .init(color: c.callStageTint.opacity(0), location: 0.4)],
                       startPoint: .top, endPoint: .bottom)
            .background(c.callStage)
    }
}

/// The call's breathing motion (§7): 1.6 s in and out; still under reduced motion.
private struct CallBreathing: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inhaled = false

    func body(content: Content) -> some View {
        content
            .opacity(inhaled ? 0.35 : 1)
            .scaleEffect(inhaled ? 1.08 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: inhaled)
            .onAppear { inhaled = !reduceMotion }
            .onChange(of: reduceMotion) { inhaled = !$0 }
    }
}

extension View {
    /// Breathes as the call's rings and the reconnecting dot do (§7); still under reduced motion.
    func flareCallBreathing() -> some View { modifier(CallBreathing()) }

    /// A device key is a switch to VoiceOver ("麦克风，已关闭"): the toggle trait where the OS has it.
    @ViewBuilder func flareCallToggle(_ isToggle: Bool) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            accessibilityAddTraits(isToggle ? .isToggle : [])
        } else {
            self
        }
    }

    /// The focus ring follows `shape`, never a square round a round key (§3.2). The Mac draws it from the focus-effect
    /// shape; iOS from the hit shape, which the round keys set themselves.
    func flareCallFocusShape<S: Shape>(_ shape: S) -> some View {
        #if os(macOS)
        return contentShape(.focusEffect, shape)
        #else
        return self
        #endif
    }
}

private struct FlareCallInWindowKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// The call sits in ``CallSurfaceView``'s floating window (iPad, Mac) rather than on the full screen: the avatar
    /// is `componentCallAvatarSizeWindow` and the name 20/600 (§3.3).
    var flareCallInWindow: Bool {
        get { self[FlareCallInWindowKey.self] }
        set { self[FlareCallInWindowKey.self] = newValue }
    }

    /// The surface's keys for the call view's top row (``CallWindowChrome``).
    var flareCallWindow: CallWindowChrome {
        get { self[CallWindowChromeKey.self] }
        set { self[CallWindowChromeKey.self] = newValue }
    }
}

/// A key's ground (§7, §12.10): `fill` at rest, `hover` under a pointer (else `pressed`), `pressed` while held at 0.98
/// (the colour only under reduced motion), changing in `motion.fast`; the whole key at `FlareOpacity.disabled` while
/// disabled. `size` is the ground's side, centred in a label that may be the larger touch target; nil fills the label.
struct FlarePressStyle: ButtonStyle {
    let fill: Color
    let pressed: Color
    var size: CGFloat?
    var hover: Color?
    var shape = AnyShape(Circle())

    func makeBody(configuration: Configuration) -> some View {
        Key(configuration: configuration, style: self)
    }

    private struct Key: View {
        let configuration: ButtonStyleConfiguration
        let style: FlarePressStyle
        @State private var hovering = false
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let ground = configuration.isPressed ? style.pressed
                : hovering && isEnabled ? style.hover ?? style.pressed : style.fill
            configuration.label
                .background(style.shape.fill(ground).frame(width: style.size, height: style.size))
                .scaleEffect(configuration.isPressed && !reduceMotion ? FlareSizes.componentPressScale : 1)
                .opacity(isEnabled ? 1 : FlareOpacity.disabled)
                .animation(FlareMotion.fastAnimation, value: configuration.isPressed)
                .animation(FlareMotion.fastAnimation, value: hovering)
                .onHover { hovering = $0 }
        }
    }
}

/// A 36 disc on the stage's top row — minimize, the window's expand key (§3.1): `callControl`, its hover and pressed
/// colour, a 44 target.
struct CallTopKey: View {
    let icon: String
    let label: String
    let action: () -> Void
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// 36, as the dock's keys.
    static let side = FlareSizes.componentCallDockKeySize

    var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        Button(action: action) {
            Image(systemName: flareIconSymbol(icon)).font(.system(size: FlareSizes.iconSizeMd)).foregroundColor(c.callOnStage)
                .frame(width: Self.side, height: Self.side)
                .flareTouchTarget()
                .flareCallFocusShape(Circle())
        }
        .buttonStyle(FlarePressStyle(fill: c.callControl, pressed: c.callControlHover, size: Self.side))
        .flareCompactLayout(width: Self.side, height: Self.side)
        .accessibilityLabel(label)
    }
}

/// What ``CallSurfaceView`` gives the call view inside it (§3.1): its expand key, drawn at the end of the call view's
/// top row beside minimize and the encrypted note, and the surface's own minimize.
struct CallWindowChrome {
    var expandKey: AnyView?
    var onMinimize: (() -> Void)?
}

private struct CallWindowChromeKey: EnvironmentKey {
    static let defaultValue = CallWindowChrome()
}

/// End-to-end encrypted: lock 16 and `callEncrypted` as a caption on the stage (§3.1).
struct CallEncryptedBadge: View {
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @ScaledMetric(relativeTo: .caption) private var textSize = FlareSizes.fontSizeSm

    var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingXs) {
            IconView("lock", size: FlareSizes.iconSizeSm, color: c.callOnStageSecondary)
            Text(strings.callEncrypted).font(.system(size: textSize)).foregroundColor(c.callOnStageSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The failed state's keys in place of the control bar (§3.3): close (hangs up, secondary) and redial (primary,
/// drawn when the host can redial). Equal halves of the width on a phone, `componentCallFailedActionWidth` each
/// elsewhere.
struct CallFailedActions: View {
    let redialText: String
    let redialIcon: String
    let onClose: (() -> Void)?
    let onRedial: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @ScaledMetric(relativeTo: .body) private var textSize = FlareSizes.fontSizeXl
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    private var compact: Bool {
        #if os(iOS)
        return sizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingLg) {
            key(strings.close, icon: nil, fg: c.callOnStage, bg: c.callControl, hover: c.callControlHover,
                pressed: c.callControlHover, action: onClose)
            if onRedial != nil {
                key(redialText, icon: redialIcon, fg: c.callOnStage, bg: c.primary, hover: c.primaryHover,
                    pressed: c.primaryActive, action: onRedial)
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
    }

    private func key(_ text: String, icon: String?, fg: Color, bg: Color, hover: Color, pressed: Color,
                     action: (() -> Void)?) -> some View {
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
        return Button { action?() } label: {
            HStack(spacing: FlareSizes.spacingXs) {
                if let icon { IconView(icon, size: FlareSizes.iconSizeMd, color: fg) }
                // The 44pt target belongs to the label: a borderless button is hit by its label only.
                Text(text).font(.system(size: textSize, weight: .semibold)).foregroundColor(fg).flareTouchTarget()
            }
            .frame(minWidth: compact ? nil : FlareSizes.componentCallFailedActionWidth,
                   maxWidth: compact ? .infinity : FlareSizes.componentCallFailedActionWidth, minHeight: FlareSizes.controlHeightLg)
            .contentShape(shape)
            .flareCallFocusShape(shape)
        }
        .buttonStyle(FlarePressStyle(fill: bg, pressed: pressed, hover: hover, shape: AnyShape(shape)))
        .disabled(action == nil)
    }
}

// MARK: - Controls

/// Call control bar. Spec: Call/CallControls (`CallControlsView`), docs/plugin-experience.md §3.3.
///
/// Order: microphone, speaker (both modes), the host's `devices` key, then camera and flip (video; flip on a phone only)
/// or "switch to video" (audio), then add member, then hang up with 「挂断」 under it. M and V toggle microphone and
/// camera, ⌘⇧H (⌃⇧H on iPad) hangs up. `onAddMember` and `onStartVideo` draw their keys only when the host passes
/// them; "switch to video" is drawn in an audio call only and asks the host to turn the call into a video call.
///
/// `devices` is the host's own device key on the control disc — on iOS the system route picker (`AVRoutePickerView`).
/// `disabled` (no media session yet) turns every key but hang up off. On a phone with more than four keys besides hang
/// up, hang up takes a row of its own at `componentCallHangupSize`; elsewhere it closes the row one gap further out.
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
    private let onStartVideo: (() -> Void)?
    private let disabled: Bool
    private let devices: AnyView?
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @ScaledMetric(relativeTo: .caption) private var labelSize = FlareSizes.fontSizeSm
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init(muted: Bool = false, cameraOn: Bool = true, speakerOn: Bool = false, mode: FlareCallMode = .video,
                onToggleMute: (() -> Void)? = nil, onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onHangup: (() -> Void)? = nil, onAddMember: (() -> Void)? = nil,
                onStartVideo: (() -> Void)? = nil, disabled: Bool = false, devices: AnyView? = nil) {
        self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn; self.mode = mode
        self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera; self.onToggleSpeaker = onToggleSpeaker
        self.onSwitchCamera = onSwitchCamera; self.onHangup = onHangup; self.onAddMember = onAddMember
        self.onStartVideo = onStartVideo; self.disabled = disabled; self.devices = devices
    }

    /// A device toggle's value: whether the device (microphone, camera, speaker) is on — so a muted
    /// microphone reads "off", as on the Vue and Compose kits.
    static func deviceState(on: Bool, _ strings: FlareStrings) -> String {
        on ? strings.callDeviceOn : strings.callDeviceOff
    }

    /// Whether hang up takes a row of its own: on a phone, past four other keys (§3.3).
    static func hangupOnOwnRow(otherKeys: Int, compact: Bool) -> Bool {
        compact && otherKeys > 4
    }

    /// The flip key is a phone's (§3.3: "手机视频时"): a video call in a compact width.
    static func showsFlip(mode: FlareCallMode, compact: Bool) -> Bool {
        mode == .video && compact
    }

    private var otherKeys: Int {
        (mode == .video ? 3 : 2 + (onStartVideo == nil ? 0 : 1)) + (Self.showsFlip(mode: mode, compact: compact) ? 1 : 0)
            + (devices == nil ? 0 : 1) + (onAddMember == nil ? 0 : 1)
    }

    private var compact: Bool {
        #if os(iOS)
        return sizeClass == .compact
        #else
        return false
        #endif
    }

    public var body: some View {
        let ownRow = Self.hangupOnOwnRow(otherKeys: otherKeys, compact: compact)
        VStack(spacing: FlareSizes.spacingLg) {
            HStack(alignment: .top, spacing: compact ? FlareSizes.spacingLg : FlareSizes.spacing2xl) {
                ctrl(muted ? "mic-off" : "mic", strings.microphone, muted, onToggleMute,
                     state: Self.deviceState(on: !muted, strings), key: "m")
                ctrl(speakerOn ? "speaker" : "speaker-off", strings.speaker, speakerOn, onToggleSpeaker,
                     state: Self.deviceState(on: speakerOn, strings))
                if let devices { devicesKey(devices) }
                if mode == .video {
                    ctrl(cameraOn ? "video" : "camera-off", strings.camera, !cameraOn, onToggleCamera,
                         state: Self.deviceState(on: cameraOn, strings), key: "v")
                    if Self.showsFlip(mode: mode, compact: compact) {
                        ctrl("switch-camera", strings.flipCamera, false, onSwitchCamera)
                    }
                } else if let onStartVideo {
                    ctrl("video", strings.callSwitchToVideo, false, onStartVideo)
                }
                if let onAddMember {
                    ctrl("person-add", strings.addMember, false, onAddMember)
                }
                if !ownRow {
                    // A desktop bar sets hang up apart by one more gap.
                    hangup(size: FlareSizes.componentCallControlSize).padding(.leading, compact ? 0 : FlareSizes.spacing2xl)
                }
            }
            if ownRow { hangup(size: FlareSizes.componentCallHangupSize) }
        }
    }

    /// One control: the kit icon `icon` on the 56pt disc, named by the device or action `label`, with the device's
    /// on/off `state` as the value (a device toggle; an action has none); `on` fills the disc (a muted microphone, a
    /// camera that is off, a speaker that is on). `key` is its hardware-keyboard letter (§3.3: M, V), named in the help
    /// text, on the full screen and in the window alike.
    private func ctrl(_ icon: String, _ label: String, _ on: Bool, _ action: (() -> Void)?, state: String = "",
                      key: KeyEquivalent? = nil) -> some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        let size = FlareSizes.componentCallControlSize
        let off = disabled || action == nil
        return VStack(spacing: FlareSizes.spacingXs) {
            Button { action?() } label: {
                Image(systemName: flareIconSymbol(icon)).font(.system(size: FlareSizes.fontSize5xl))
                    .foregroundColor(on ? c.callOnControlActive : c.callOnStage)
                    .frame(width: size, height: size)
                    // Hit area and focus ring follow the disc, not a square (§3.2).
                    .contentShape(Circle())
                    .flareCallFocusShape(Circle())
            }
            .buttonStyle(FlarePressStyle(fill: on ? c.callControlActive : c.callControl,
                                         pressed: on ? c.callControlActive : c.callControlHover, size: size))
            .disabled(off)
            .keyboardShortcut(key.map { KeyboardShortcut($0, modifiers: []) })
            .help(key.map { "\(label) (\(String($0.character).uppercased()))" } ?? label)
            .accessibilityLabel(label)
            .accessibilityValue(state)
            .flareCallToggle(!state.isEmpty)
            Text(label).font(.system(size: labelSize)).foregroundColor(c.callOnStageSecondary)
                .multilineTextAlignment(.center).lineLimit(2)
                .frame(width: size)
                .opacity(off ? FlareOpacity.disabled : 1)
                .accessibilityHidden(true)
        }
    }

    /// The host's device key on the control disc.
    private func devicesKey(_ devices: AnyView) -> some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        let size = FlareSizes.componentCallControlSize
        return devices
            .frame(width: size, height: size)
            .background(Circle().fill(c.callControl))
            .clipShape(Circle())
            .disabled(disabled)
            .opacity(disabled ? FlareOpacity.disabled : 1)
    }

    /// Hang up with 「挂断」 under it (§12.17), as the other keys carry their names.
    private func hangup(size: CGFloat) -> some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        return VStack(spacing: FlareSizes.spacingXs) {
            Button { onHangup?() } label: {
                Image(systemName: flareIconSymbol("end-call")).font(.system(size: FlareSizes.fontSize5xl))
                    .foregroundColor(c.callOnStage)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .flareCallFocusShape(Circle())
            }
            .buttonStyle(FlarePressStyle(fill: c.callHangup, pressed: c.callHangupPressed, size: size))
            .disabled(onHangup == nil)
            // Never a single key: a stray letter must not end the call.
            .keyboardShortcut(Self.hangupShortcut)
            .help("\(strings.hangUp) (\(Self.hangupShortcutLabel))")
            .accessibilityLabel(strings.hangUp)
            Text(strings.hangUp).font(.system(size: labelSize)).foregroundColor(c.callOnStageSecondary)
                .multilineTextAlignment(.center).lineLimit(2)
                .frame(width: size)
                .opacity(onHangup == nil ? FlareOpacity.disabled : 1)
                .accessibilityHidden(true)
        }
    }

    #if os(macOS)
    static var hangupShortcut: KeyboardShortcut { KeyboardShortcut("h", modifiers: [.command, .shift]) }
    static let hangupShortcutLabel = "⌘⇧H"
    #else
    // iPadOS keeps ⌘⇧H for Home, so the iPad hangs up on ⌃⇧H.
    static var hangupShortcut: KeyboardShortcut { KeyboardShortcut("h", modifiers: [.control, .shift]) }
    static let hangupShortcutLabel = "⌃⇧H"
    #endif
}

// MARK: - CallView

/// In-call screen. Spec: Call/CallView (`CallView`), docs/plugin-experience.md §3.3. Video track injected by host.
///
/// `onMinimize` (else the surrounding ``CallSurfaceView``'s) draws the collapse control at the top leading corner (the
/// same 36-point disc as ``GroupCallView``); the host shrinks the call into its ``CallDockView``. Without one the
/// control is not drawn. `encrypted` draws the lock and `callEncrypted` at the top trailing side, followed in a window
/// by the window's expand key — one row (§3.1). In a window the avatar is 80 and the name 20/600.
///
/// `peerMuted` adds mic-off 14 and 「对方已静音」 after the status line; `peerSpeaking` draws the
/// speaking ring round the peer's avatar. Reconnecting dims the stage's video by 40% (its last frame stays).
/// `localVideo` is the host's own camera, drawn as a 9:16
/// picture-in-picture at the top trailing corner in video mode; dragged, it settles in the nearest corner, and tapped
/// it swaps places with the peer's video. Once a video call is connected the peer's name and status move into the top
/// bar, which fades after 4 s without a touch or pointer move (never under reduced motion or VoiceOver).
///
/// `onStartVideo` draws the control bar's "switch to video" key in an audio call; the host turns the call into video.
/// `controlsDisabled` (no media session yet) turns every key but hang up off; `devices` is the control bar's host
/// device key. `.failed` swaps the control bar for close (`onClose`, else `onHangup`) and redial (`onRecover`,
/// `recoveryText` else `callRedial`); `.ended` reads `callEnded` with `durationLabel`, turns every key off and is read
/// out; the host closes it after 1.5 s.
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
    private let onMinimize: (() -> Void)?
    private let peerMuted: Bool
    private let peerSpeaking: Bool
    private let localVideo: AnyView?
    private let onStartVideo: (() -> Void)?
    private let controlsDisabled: Bool
    private let encrypted: Bool
    private let devices: AnyView?
    private let onClose: (() -> Void)?
    @State private var swapped = false
    @State private var previewCorner: Alignment = .topTrailing
    @GestureState private var previewDrag: CGSize = .zero
    @State private var chromeHidden = false
    @State private var idleTick = 0
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverOn
    @Environment(\.flareCallInWindow) private var inWindow
    @Environment(\.flareCallWindow) private var window
    @ScaledMetric(relativeTo: .title) private var nameSize = FlareSizes.fontSize5xl
    @ScaledMetric(relativeTo: .title) private var windowNameSize = FlareSizes.fontSize4xl
    @ScaledMetric(relativeTo: .body) private var statusSize = FlareSizes.fontSizeXl
    @ScaledMetric(relativeTo: .headline) private var barNameSize = FlareSizes.fontSizeXl
    @ScaledMetric(relativeTo: .subheadline) private var barStatusSize = FlareSizes.fontSizeMd

    /// §3.3: reconnecting keeps the video's last frame under the stage colour at 40%.
    static let reconnectingDim = FlareOpacity.dim

    public init(peerName: String, mode: FlareCallMode, state: FlareCallState, durationLabel: String? = nil,
                peerAvatarURL: String? = nil, muted: Bool = false, cameraOn: Bool = true, speakerOn: Bool = false,
                video: AnyView? = nil, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil, onSwitchCamera: (() -> Void)? = nil,
                statusDetail: String? = nil, recoveryText: String? = nil, onRecover: (() -> Void)? = nil,
                onMinimize: (() -> Void)? = nil, peerMuted: Bool = false, peerSpeaking: Bool = false,
                localVideo: AnyView? = nil, onStartVideo: (() -> Void)? = nil, controlsDisabled: Bool = false,
                encrypted: Bool = false, devices: AnyView? = nil, onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        self.statusDetail = statusDetail; self.recoveryText = recoveryText; self.onRecover = onRecover
        self.onMinimize = onMinimize
        self.peerName = peerName; self.mode = mode; self.state = state; self.durationLabel = durationLabel
        self.peerAvatarURL = peerAvatarURL; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.video = video; self.onHangup = onHangup; self.onToggleMute = onToggleMute
        self.onToggleCamera = onToggleCamera; self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera
        self.peerMuted = peerMuted; self.peerSpeaking = peerSpeaking; self.localVideo = localVideo
        self.onStartVideo = onStartVideo; self.controlsDisabled = controlsDisabled; self.encrypted = encrypted
        self.devices = devices
    }

    /// Whether the speaking ring goes round the peer's avatar: the peer speaks and is not muted. The avatar, and so
    /// the ring, is not drawn while the peer's video covers it.
    static func showsSpeakingRing(speaking: Bool, muted: Bool) -> Bool {
        speaking && !muted
    }

    /// The peer block's top inset inside the safe area: below the corner preview while it is drawn, so the preview
    /// never covers the avatar on a narrow screen; 72 otherwise.
    static func peerTopInset(localPreview: Bool) -> CGFloat {
        localPreview ? FlareSizes.spacingLg * 2 + previewHeight : 72
    }

    /// The corner preview's height: 9:16 at `componentCallPreviewWidth`.
    static let previewHeight = FlareSizes.componentCallPreviewWidth * 16 / 9

    /// The corner a dragged preview settles in: the quarter of the stage its centre was let go in.
    static func previewCorner(center: CGPoint, in size: CGSize) -> Alignment {
        switch (center.x < size.width / 2, center.y < size.height / 2) {
        case (true, true): return .topLeading
        case (false, true): return .topTrailing
        case (true, false): return .bottomLeading
        case (false, false): return .bottomTrailing
        }
    }

    /// `callEnded` with the call's length; without one the line stops at "通话已结束".
    static func endedText(durationLabel: String?, _ strings: FlareStrings) -> String {
        guard let durationLabel, !durationLabel.isEmpty else {
            return strings.callEnded.replacingOccurrences(of: " · {duration}", with: "")
        }
        return strings.callEnded.replacingOccurrences(of: "{duration}", with: durationLabel)
    }

    /// The status line. A failed call reads the host's reason, else `callFailed`.
    private var statusText: String {
        switch state {
        case .reconnecting: return strings.callReconnecting
        case .failed: return statusDetail ?? strings.callFailed
        case .connected: return durationLabel ?? strings.callConnected
        case .ringing: return strings.callRinging
        case .calling: return mode == .video ? strings.callWaitingAnswer : strings.callCalling
        case .ended: return Self.endedText(durationLabel: durationLabel, strings)
        }
    }

    /// A connected video call with the peer on screen: the name and status sit in the top bar, which may fade.
    private var live: Bool { mode == .video && state == .connected && video != nil }
    private var canFade: Bool { live && !reduceMotion && !voiceOverOn }
    /// The host's minimize, else the surface's.
    private var minimize: (() -> Void)? { onMinimize ?? window.onMinimize }

    public var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        let preview = mode == .video && localVideo != nil
        // Swapped, the host's own camera fills the stage and the peer sits in the corner.
        let flip = swapped && video != nil
        let big = flip ? localVideo : video
        let small = flip ? video : localVideo
        ZStack {
            CallStageBackground().ignoresSafeArea()
            if mode == .video, let big {
                big.overlay {
                    if state == .reconnecting {
                        c.callStage.opacity(Self.reconnectingDim).allowsHitTesting(false).accessibilityHidden(true)
                    }
                }
            }
            VStack(spacing: 0) {
                ScrollView {
                    if !live { peerBlock(c, preview: preview) }
                }
                .overlay { if preview, let small { previewTile(small, c) } }
                controlBar.padding(.top, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacing2xl)
            }
            topBar(c, preview: preview)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { wake() })
        .onContinuousHover { _ in wake() }
        .task(id: [idleTick, canFade ? 1 : 0]) {
            guard canFade else { chromeHidden = false; return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(FlareMotion.slowAnimation) { chromeHidden = true }
        }
        .onAppear { announceEnd() }
        .onChange(of: state) { _ in announceEnd(); wake() }
    }

    /// The peer in the middle of the stage: avatar (unless the peer's video covers it), name, status and detail.
    private func peerBlock(_ c: FlareColors, preview: Bool) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            if mode == .audio || video == nil { peerAvatar(c) }
            Text(peerName).font(.system(size: inWindow ? windowNameSize : nameSize, weight: .semibold))
                .foregroundColor(c.callOnStage)
                .multilineTextAlignment(.center)
            statusLine(c, size: statusSize)
            if state != .failed, let statusDetail {
                Text(statusDetail).font(.system(size: statusSize)).foregroundColor(c.callOnStage)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, FlareSizes.spacingLg).padding(.top, Self.peerTopInset(localPreview: preview))
    }

    /// The status line: the reconnecting dot (8, pulsing), the status — a failure in `callErrorText` — and, while the
    /// peer is muted, mic-off 14 and 「对方已静音」 after it (§3.3, §12.17).
    private func statusLine(_ c: FlareColors, size: CGFloat) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            if state == .reconnecting {
                Circle().fill(c.warning).frame(width: FlareSizes.spacingSm, height: FlareSizes.spacingSm)
                    .flareCallBreathing().accessibilityHidden(true)
            }
            Text(statusText).font(.system(size: size).monospacedDigit())
                .foregroundColor(state == .failed ? c.callErrorText : c.callOnStageSecondary)
                .multilineTextAlignment(.center)
            if peerMuted {
                HStack(spacing: FlareSizes.spacingXs) {
                    // §3.3: mic-off 14, the size of the words beside it.
                    IconView("mic-off", size: FlareSizes.iconSizeXs, color: c.callOnStageSecondary)
                    Text(strings.callPeerMuted).font(.system(size: size)).foregroundColor(c.callOnStageSecondary)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(strings.callPeerMuted)
            }
        }
    }

    /// One row (§3.1): minimize at the leading end; the encrypted note (under the name while live) and the window's
    /// expand key at the trailing end; while live the peer's name and status in the middle. Fades when idle.
    @ViewBuilder private func topBar(_ c: FlareColors, preview: Bool) -> some View {
        if minimize != nil || encrypted || live || window.expandKey != nil {
            VStack {
                ZStack {
                    HStack(spacing: FlareSizes.spacingSm) {
                        if let minimize { CallTopKey(icon: "collapse", label: strings.callMinimize, action: minimize) }
                        Spacer()
                        if encrypted && !live { CallEncryptedBadge() }
                        if let expand = window.expandKey { expand }
                    }
                    if live {
                        VStack(spacing: FlareSizes.spacing3xs) {
                            Text(peerName).font(.system(size: barNameSize, weight: .semibold)).foregroundColor(c.callOnStage)
                                .lineLimit(1)
                            statusLine(c, size: barStatusSize)
                            if encrypted { CallEncryptedBadge() }
                        }
                        .padding(.horizontal, FlareSizes.touchTargetMin + FlareSizes.spacingSm)
                    }
                }
                .padding(.top, FlareSizes.spacingLg)
                // The row is the window's drag area (§3.1): it takes the touch, not the stage scrolling under it.
                .contentShape(Rectangle())
                Spacer()
            }
            .padding(.leading, FlareSizes.spacingLg)
            // The bar keeps clear of a preview in the top trailing corner.
            .padding(.trailing, FlareSizes.spacingLg
                     + (preview && previewCorner == .topTrailing ? FlareSizes.componentCallPreviewWidth + FlareSizes.spacingSm : 0))
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .accessibilityHidden(chromeHidden)
        }
    }

    /// The corner picture (9:16, `componentCallPreviewWidth` wide, `radiusLg`): dragged, it settles in the nearest corner; tapped,
    /// it swaps places with the stage's video.
    private func previewTile(_ small: AnyView, _ c: FlareColors) -> some View {
        let w = FlareSizes.componentCallPreviewWidth, h = Self.previewHeight, inset = FlareSizes.spacingLg
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
        return GeometryReader { geo in
            small
                .frame(width: w, height: h)
                .background(c.callStage)
                .clipShape(shape)
                .contentShape(shape)
                .onTapGesture { if video != nil { swapped.toggle() } }
                .gesture(
                    DragGesture(minimumDistance: 8, coordinateSpace: .global)
                        .updating($previewDrag) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            let x = (previewCorner.horizontal == .leading ? inset + w / 2 : geo.size.width - inset - w / 2)
                                + value.translation.width
                            let y = (previewCorner.vertical == .top ? inset + h / 2 : geo.size.height - inset - h / 2)
                                + value.translation.height
                            previewCorner = Self.previewCorner(center: CGPoint(x: x, y: y), in: geo.size)
                        }
                )
                .accessibilityLabel(strings.callSwapVideo)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { if video != nil { swapped.toggle() } }
                .padding(inset)
                .frame(width: geo.size.width, height: geo.size.height, alignment: previewCorner)
                .offset(previewDrag)
                .animation(reduceMotion ? nil : FlareMotion.normalAnimation, value: previewCorner)
        }
    }

    /// A touch or a pointer move brings the faded top bar back and restarts its 4 s.
    private func wake() {
        if chromeHidden { chromeHidden = false }
        idleTick &+= 1
    }

    @ViewBuilder private var controlBar: some View {
        if state == .failed {
            CallFailedActions(redialText: recoveryText ?? strings.callRedial, redialIcon: mode == .video ? "video" : "phone",
                              onClose: onClose ?? onHangup, onRedial: onRecover)
        } else {
            // Ended: every key is off, hang up too.
            CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                             onToggleMute: onToggleMute, onToggleCamera: onToggleCamera, onToggleSpeaker: onToggleSpeaker,
                             onSwitchCamera: onSwitchCamera, onHangup: state == .ended ? nil : onHangup,
                             onStartVideo: onStartVideo, disabled: controlsDisabled || state == .ended, devices: devices)
        }
    }

    private func announceEnd() {
        if state == .ended { flareAnnounce(statusText) }
    }

    private func peerAvatar(_ c: FlareColors) -> some View {
        AvatarView(userId: peerName, displayName: peerName, avatarURL: peerAvatarURL,
                   size: inWindow ? FlareSizes.componentCallAvatarSizeWindow : FlareSizes.componentCallAvatarSize)
            .overlay {
                // Just outside the avatar; an overlay leaves the layout where it was.
                if Self.showsSpeakingRing(speaking: peerSpeaking, muted: peerMuted) {
                    Circle().strokeBorder(c.callSpeaking, lineWidth: 3).padding(-3)
                } else if state == .calling || state == .ringing {
                    Circle().strokeBorder(c.callOnStage.opacity(0.2), lineWidth: 2).padding(-4).flareCallBreathing()
                }
            }
    }

}

// MARK: - IncomingCall

/// How an incoming call shows — spec union `'fullscreen' | 'banner'`.
public enum FlareIncomingCallPresentation: Sendable { case fullscreen, banner }

/// Incoming call / invite. Spec: Call/IncomingCall (`IncomingCallView`), docs/plugin-experience.md §3.2.
///
/// `.fullscreen` (phones) fills the stage: the caller from the top 22% with a breathing ring, decline and accept on
/// 64-point discs at a quarter and three quarters of the width. `.banner` (iPad, Mac) is a 360-wide card at the
/// container's top trailing corner that leaves the rest of the window working. A video invitation adds the "answer
/// with audio" key when the host passes `onAcceptAudio`; as on the web (`acceptAudio`), the kit only reports the key,
/// and the host answers and keeps its own camera off — there is no audio-only answer in the SDK. VoiceOver hears who
/// is calling when it appears; on full screen its focus starts on accept.
public struct IncomingCallView: View {
    private let callerName: String
    private let mode: FlareCallMode
    private let callerAvatarURL: String?
    private let onAccept: (() -> Void)?
    private let onReject: (() -> Void)?
    private let presentation: FlareIncomingCallPresentation
    private let onAcceptAudio: (() -> Void)?
    @AccessibilityFocusState private var acceptFocused: Bool
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareCallInWindow) private var inWindow
    @ScaledMetric(relativeTo: .title) private var nameSize = FlareSizes.fontSize5xl
    @ScaledMetric(relativeTo: .body) private var inviteSize = FlareSizes.fontSizeXl
    @ScaledMetric(relativeTo: .caption) private var captionSize = FlareSizes.fontSizeSm
    @ScaledMetric(relativeTo: .subheadline) private var bannerInviteSize = FlareSizes.fontSizeMd

    public init(callerName: String, mode: FlareCallMode, callerAvatarURL: String? = nil,
                onAccept: (() -> Void)? = nil, onReject: (() -> Void)? = nil,
                presentation: FlareIncomingCallPresentation = .fullscreen, onAcceptAudio: (() -> Void)? = nil) {
        self.callerName = callerName; self.mode = mode; self.callerAvatarURL = callerAvatarURL
        self.onAccept = onAccept; self.onReject = onReject
        self.presentation = presentation; self.onAcceptAudio = onAcceptAudio
    }

    private var invite: String { mode == .video ? strings.incomingVideoCall : strings.incomingVoiceCall }

    public var body: some View {
        Group {
            if presentation == .banner { banner } else { fullscreen }
        }
        .onAppear {
            flareAnnounce("\(callerName) \(invite)")
            if presentation == .fullscreen { acceptFocused = true }
        }
    }

    private var fullscreen: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        let size = FlareSizes.componentCallHangupSize
        return GeometryReader { geo in
            VStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: callerName, displayName: callerName, avatarURL: callerAvatarURL,
                           size: inWindow ? FlareSizes.componentCallAvatarSizeWindow : FlareSizes.componentCallAvatarSize)
                    .overlay { Circle().strokeBorder(c.callOnStage.opacity(0.2), lineWidth: 2).padding(-4).flareCallBreathing() }
                    .padding(.top, geo.size.height * 0.22)
                Text(callerName).font(.system(size: nameSize, weight: .semibold)).foregroundColor(c.callOnStage)
                    .multilineTextAlignment(.center)
                Text(invite).font(.system(size: inviteSize)).foregroundColor(c.callOnStageSecondary)
                    .multilineTextAlignment(.center)
                Spacer(minLength: FlareSizes.spacing2xl)
                if mode == .video, let onAcceptAudio {
                    IconButtonView(icon: "phone", accessibilityLabel: strings.callAnswerAudio, size: .md,
                                   tint: c.callOnStage, background: c.callControl, action: onAcceptAudio)
                        .padding(.bottom, FlareSizes.spacing2xl)
                }
                HStack(spacing: 0) {
                    VStack(spacing: FlareSizes.spacingSm) {
                        disc("end-call", strings.callDecline, fill: c.callHangup, pressed: c.callHangupPressed, size: size, onReject)
                        caption(strings.callDecline, c)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: FlareSizes.spacingSm) {
                        disc(mode == .video ? "video" : "phone", strings.accept, fill: c.callAccept, pressed: c.callAcceptPressed,
                             size: size, onAccept)
                            .accessibilityFocused($acceptFocused)
                        caption(strings.accept, c)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, size)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, FlareSizes.spacingLg)
        }
        .background(CallStageBackground().ignoresSafeArea())
    }

    private var banner: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        // §3.2: the banner's 40 discs, the medium control height.
        let side = FlareSizes.controlHeightMd
        return HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: callerName, displayName: callerName, avatarURL: callerAvatarURL,
                       size: FlareSizes.componentCallIncomingBannerAvatar)
            VStack(alignment: .leading, spacing: 2) {
                Text(callerName).font(.system(size: inviteSize, weight: .semibold)).foregroundColor(c.callOnStage).lineLimit(1)
                Text(invite).font(.system(size: bannerInviteSize)).foregroundColor(c.callOnStageSecondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: FlareSizes.spacingSm) {
                if mode == .video, let onAcceptAudio {
                    disc("phone", strings.callAnswerAudio, fill: c.callControl, pressed: c.callControlHover, size: side, onAcceptAudio)
                }
                disc("end-call", strings.callDecline, fill: c.callHangup, pressed: c.callHangupPressed, size: side, onReject)
                disc(mode == .video ? "video" : "phone", strings.accept, fill: c.callAccept, pressed: c.callAcceptPressed,
                     size: side, onAccept)
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        // It grows past its height with Dynamic Type.
        .frame(width: FlareSizes.componentCallIncomingBannerWidth)
        .frame(minHeight: FlareSizes.componentCallIncomingBannerHeight)
        .background(CallStageBackground())
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
        .flareShadow(FlareShadows.of(scheme).lg)
        .accessibilityElement(children: .contain)
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    /// A round key: the kit icon `icon` on a `size` disc, named `label`. Below 44 points the target reaches past the disc.
    private func disc(_ icon: String, _ label: String, fill: Color, pressed: Color, size: CGFloat,
                      _ action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: flareIconSymbol(icon))
                .font(.system(size: size >= FlareSizes.componentCallControlSize ? FlareSizes.fontSize5xl : FlareSizes.fontSize3xl))
                .foregroundColor(FlareColors.of(.dark, brand: flareBrandTheme).callOnStage)
                .frame(width: size, height: size)
                .flareTouchTarget()
                .flareCallFocusShape(Circle())
        }
        .buttonStyle(FlarePressStyle(fill: fill, pressed: pressed, size: size))
        .flareCompactLayout(width: size, height: size)
        .disabled(action == nil)
        .accessibilityLabel(label)
    }

    /// The caption under a full-screen key repeats its name for sight only.
    private func caption(_ text: String, _ c: FlareColors) -> some View {
        Text(text).font(.system(size: captionSize)).foregroundColor(c.callOnStageSecondary).accessibilityHidden(true)
    }
}
