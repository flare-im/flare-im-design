import SwiftUI

// MARK: - CallDock

/// Minimized call dock — capsule pill to return to an ongoing call.
/// Spec: Call/CallDock (`CallDockView`), docs/plugin-experience.md §3.5.
///
/// A capsule on the call stage, `componentCallDockHeight` high: the avatar (a breathing speaking ring while
/// connected), the title and a status line, then the microphone and hang-up keys. The status follows `state` in short
/// phrases (§12.17): connected shows `durationLabel`; calling and ringing `callDockWaiting`; reconnecting a warning dot
/// and `callReconnectingShort`; failed `callInterrupted` in `callErrorText`. `statusDetail` replaces the line.
public struct CallDockView: View {
    private let title: String
    private let avatarURL: String?
    private let durationLabel: String?
    private let mode: FlareCallMode
    private let muted: Bool
    private let onExpand: (() -> Void)?
    private let onToggleMute: (() -> Void)?
    private let onHangup: (() -> Void)?
    private let state: FlareCallState
    private let statusDetail: String?
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .subheadline) private var nameSize = FlareSizes.fontSizeLg
    @ScaledMetric(relativeTo: .caption) private var statusSize = FlareSizes.fontSizeSm

    /// §3.5: the 40 avatar, the 36 keys (``CallTopKey/side``) and the name's ``FlareSizes/componentCallDockNameMaxWidth``.
    static let avatarSide = FlareSizes.componentCallDockAvatarSize
    static let keySide = CallTopKey.side
    static let nameMaxWidth = FlareSizes.componentCallDockNameMaxWidth

    public init(title: String, avatarURL: String? = nil, durationLabel: String? = nil,
                mode: FlareCallMode = .audio, muted: Bool = false,
                onExpand: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil, onHangup: (() -> Void)? = nil,
                state: FlareCallState = .connected, statusDetail: String? = nil) {
        self.title = title; self.avatarURL = avatarURL; self.durationLabel = durationLabel
        self.mode = mode; self.muted = muted
        self.onExpand = onExpand; self.onToggleMute = onToggleMute; self.onHangup = onHangup
        self.state = state; self.statusDetail = statusDetail
    }

    private var statusText: String {
        if let statusDetail { return statusDetail }
        switch state {
        case .connected: return durationLabel ?? strings.callInProgress
        case .calling, .ringing: return strings.callDockWaiting
        case .reconnecting: return strings.callReconnectingShort
        case .failed: return strings.callInterrupted
        case .ended: return CallView.endedText(durationLabel: durationLabel, strings)
        }
    }

    public var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingSm) {
            Button { onExpand?() } label: {
                HStack(spacing: FlareSizes.spacingSm) {
                    AvatarView(userId: title, displayName: title, avatarURL: avatarURL, size: Self.avatarSide)
                        .overlay {
                            if state == .connected {
                                Circle().strokeBorder(c.callSpeaking, lineWidth: 2).padding(-2).flareCallBreathing()
                            }
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: nameSize, weight: .semibold)).foregroundColor(c.callOnStage)
                            .lineLimit(1).frame(maxWidth: Self.nameMaxWidth, alignment: .leading)
                            // Hug a short name (Vue `max-width`): a bare max frame would stretch the dock to the cap.
                            .fixedSize(horizontal: true, vertical: false)
                        HStack(spacing: FlareSizes.spacingXs) {
                            if state == .reconnecting {
                                Circle().fill(c.warning).frame(width: FlareSizes.spacingSm, height: FlareSizes.spacingSm).flareCallBreathing()
                            } else {
                                IconView(mode == .video ? "video" : "phone", size: statusSize, color: c.callOnStageSecondary)
                            }
                            Text(statusText).font(.system(size: statusSize).monospacedDigit()).lineLimit(1)
                                .foregroundColor(state == .failed ? c.callErrorText : c.callOnStageSecondary)
                        }
                    }
                }
                .frame(minHeight: FlareSizes.touchTargetMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Named by what it does — back to the full call — with the call's title as the value.
            .accessibilityLabel(strings.callReturn)
            .accessibilityValue(title)

            Button { onToggleMute?() } label: {
                Image(systemName: flareIconSymbol(muted ? "mic-off" : "mic")).font(.system(size: FlareSizes.fontSize3xl))
                    .foregroundColor(muted ? c.callOnControlActive : c.callOnStage)
                    .frame(width: Self.keySide, height: Self.keySide)
                    .flareTouchTarget()
                    .flareCallFocusShape(Circle())
            }
            .buttonStyle(FlarePressStyle(fill: muted ? c.callControlActive : c.callControl,
                                         pressed: muted ? c.callControlActive : c.callControlHover, size: Self.keySide))
            .flareCompactLayout(width: Self.keySide, height: Self.keySide)
            // Named by the device, valued by whether it is on (a muted microphone is off).
            .accessibilityLabel(strings.microphone)
            .accessibilityValue(CallControlsView.deviceState(on: !muted, strings))
            .flareCallToggle(true)

            // Hang up is its own glyph, not a rotated handset.
            Button { onHangup?() } label: {
                Image(systemName: flareIconSymbol("end-call")).font(.system(size: FlareSizes.fontSize3xl)).foregroundColor(c.callOnStage)
                    .frame(width: Self.keySide, height: Self.keySide)
                    .flareTouchTarget()
                    .flareCallFocusShape(Circle())
            }
            .buttonStyle(FlarePressStyle(fill: c.callHangup, pressed: c.callHangupPressed, size: Self.keySide))
            .flareCompactLayout(width: Self.keySide, height: Self.keySide)
            .accessibilityLabel(strings.hangUp)
        }
        .padding(.leading, FlareSizes.spacingXs).padding(.trailing, FlareSizes.spacingSm)
        .frame(minHeight: FlareSizes.componentCallDockHeight)
        .background(Capsule().fill(c.callStage))
        .flareShadow(FlareShadows.of(scheme).lg)
    }
}
