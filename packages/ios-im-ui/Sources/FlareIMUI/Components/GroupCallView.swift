import SwiftUI

// MARK: - GroupCallView

/// Group (multi-party) call — participant grid + controls.
/// Spec: Call/GroupCallView (`GroupCallView`), docs/plugin-experience.md §3.4.
///
/// `tile` renders a participant's video. It is asked only for a tile that shows video (a video call with the
/// participant's camera on); that tile when it returns nil, and every other tile, show the avatar. The tile keeps its
/// chrome over the video: the speaking ring, the mute or camera-off badge and the name.
///
/// Tapping a tile makes it the main view with the others in a strip of 96-high tiles below; tapping it again restores
/// the grid. `onSelectParticipant` hears every tap with the participant's id.
///
/// `onStartVideo` draws the control bar's "switch to video" key in an audio call; the host turns the call into video.
/// `statusDetail`, `recoveryText` / `onRecover`, `onClose`, `controlsDisabled`, `encrypted` and `devices` work as on
/// ``CallView``. A participant still `calling` shows the avatar at half strength and `callCalling`, and is not counted
/// in 「N 人已加入」. The minimize key is drawn only with `onMinimize` (or the surrounding ``CallSurfaceView``'s); in a
/// window the window's expand key closes the same top row.
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
    private let onStartVideo: (() -> Void)?
    private let statusDetail: String?
    private let recoveryText: String?
    private let onRecover: (() -> Void)?
    private let onSelectParticipant: ((String) -> Void)?
    private let controlsDisabled: Bool
    private let encrypted: Bool
    private let devices: AnyView?
    private let onClose: (() -> Void)?
    private let tile: ((CallParticipant) -> AnyView?)?
    @State private var selectedId: String?
    @Environment(\.flareCallWindow) private var window
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @ScaledMetric(relativeTo: .headline) private var titleSize = FlareSizes.fontSizeXl
    @ScaledMetric(relativeTo: .subheadline) private var metaSize = FlareSizes.fontSizeMd
    @ScaledMetric(relativeTo: .caption) private var chipSize = FlareSizes.fontSizeSm
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init(participants: [CallParticipant], mode: FlareCallMode, state: FlareCallState,
                title: String? = nil, durationLabel: String? = nil, muted: Bool = false, cameraOn: Bool = true,
                speakerOn: Bool = false, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onMinimize: (() -> Void)? = nil, onAddMember: (() -> Void)? = nil,
                onStartVideo: (() -> Void)? = nil, statusDetail: String? = nil, recoveryText: String? = nil,
                onRecover: (() -> Void)? = nil, onSelectParticipant: ((String) -> Void)? = nil,
                controlsDisabled: Bool = false, encrypted: Bool = false, devices: AnyView? = nil,
                onClose: (() -> Void)? = nil, tile: ((CallParticipant) -> AnyView?)? = nil) {
        self.onClose = onClose
        self.participants = participants; self.mode = mode; self.state = state; self.title = title
        self.durationLabel = durationLabel; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.onHangup = onHangup; self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera
        self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera; self.onMinimize = onMinimize
        self.onAddMember = onAddMember; self.onStartVideo = onStartVideo
        self.statusDetail = statusDetail; self.recoveryText = recoveryText; self.onRecover = onRecover
        self.onSelectParticipant = onSelectParticipant; self.controlsDisabled = controlsDisabled
        self.encrypted = encrypted; self.devices = devices; self.tile = tile
    }

    /// The host's video for `participant`'s tile. `tile` is asked only when the tile shows video — a video call with
    /// the participant's camera on, once they have answered; nil (no `tile`, or no stream yet) leaves the avatar.
    static func tileVideo(for participant: CallParticipant, mode: FlareCallMode,
                          tile: ((CallParticipant) -> AnyView?)?) -> AnyView? {
        guard mode == .video, !participant.cameraOff, !participant.calling else { return nil }
        return tile?(participant)
    }

    /// Tiles per row (§3.4, §12.16): 1 full; 2 side by side; 3 two over one; 4 2×2; 5–6 2×3 on a phone, 3×2
    /// elsewhere; 7–9 3×3; 10–12 3×4 on a phone, 4×3 elsewhere. A short last row is centred, never padded with an
    /// empty tile.
    static func gridRows(count: Int, compact: Bool) -> [Int] {
        guard count > 0 else { return [] }
        let perRow: Int
        switch count {
        case 1: perRow = 1
        case 2...4: perRow = 2
        case 5...6: perRow = compact ? 2 : 3
        case 7...9: perRow = 3
        // shortcut: past 12 (maxGroupParticipants) the grid only adds rows; give it a scroller if >12 is ever allowed.
        default: perRow = compact ? 3 : 4
        }
        return stride(from: 0, to: count, by: perRow).map { min(perRow, count - $0) }
    }

    /// 「N 人已加入」 counts the people on the call, not the ones still being called (§12.16).
    static func joinedCount(_ participants: [CallParticipant]) -> Int {
        participants.filter { !$0.calling }.count
    }

    /// The host's minimize, else the surface's.
    private var minimize: (() -> Void)? { onMinimize ?? window.onMinimize }

    private var compact: Bool {
        #if os(iOS)
        return sizeClass == .compact
        #else
        return false
        #endif
    }

    private var gap: CGFloat { compact ? FlareSizes.spacingXs : FlareSizes.spacingSm }

    /// The local tile's name.
    private var selfName: String { strings.callYou }

    private var statusText: String {
        switch state {
        case .reconnecting: return strings.callReconnecting
        case .failed: return statusDetail ?? strings.callFailed
        case .connected: return durationLabel ?? strings.callConnected
        case .ringing: return strings.callRinging
        case .calling: return strings.callCalling
        case .ended: return CallView.endedText(durationLabel: durationLabel, strings)
        }
    }

    public var body: some View {
        let c = FlareColors.of(.dark, brand: flareBrandTheme)
        VStack(spacing: 0) {
            header(c)
            stage(c).padding(.horizontal, FlareSizes.spacingMd).padding(.top, FlareSizes.spacingXs)
            controlBar.padding(.top, FlareSizes.spacingXl).padding(.bottom, FlareSizes.spacing2xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The stage runs under the system bars; the content stays inside them.
        .background(CallStageBackground().ignoresSafeArea())
        .onAppear { announceEnd() }
        .onChange(of: state) { _ in announceEnd() }
        // The enlarged participant left: back to the grid, and no re-enlarging if they rejoin.
        .onChange(of: participants.map(\.id)) { ids in
            if let selectedId, !ids.contains(selectedId) { self.selectedId = nil }
        }
    }

    private func announceEnd() {
        if state == .ended { flareAnnounce(statusText) }
    }

    private func header(_ c: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            if let minimize { CallTopKey(icon: "collapse", label: strings.callMinimize, action: minimize) }
            VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                Text(title ?? strings.groupCall).font(.system(size: titleSize, weight: .semibold)).foregroundColor(c.callOnStage)
                    .lineLimit(1)
                HStack(spacing: FlareSizes.spacingXs) {
                    if state == .reconnecting {
                        Circle().fill(c.warning).frame(width: FlareSizes.spacingSm, height: FlareSizes.spacingSm)
                            .flareCallBreathing().accessibilityHidden(true)
                    }
                    // Ended reads the end line alone, not a head-count of a call that is over.
                    Text(state == .ended ? statusText : strings.joinedCount(Self.joinedCount(participants), statusText))
                        .font(.system(size: metaSize).monospacedDigit())
                        .foregroundColor(state == .failed ? c.callErrorText : c.callOnStageSecondary)
                }
                if state != .failed, let statusDetail {
                    Text(statusDetail).font(.system(size: metaSize)).foregroundColor(c.callOnStage)
                }
            }
            Spacer()
            if encrypted { CallEncryptedBadge() }
            if let expand = window.expandKey { expand }
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacing2md).padding(.bottom, FlareSizes.spacingXs)
    }

    @ViewBuilder private func stage(_ c: FlareColors) -> some View {
        if let selected = participants.first(where: { $0.id == selectedId }) {
            let stripHeight = FlareSizes.componentCallStripTileHeight
            VStack(spacing: gap) {
                participantTile(selected, c)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: gap) {
                        ForEach(participants.filter { $0.id != selected.id }) { p in
                            participantTile(p, c).frame(width: stripHeight * 3 / 4, height: stripHeight)
                        }
                    }
                }
                .frame(height: stripHeight)
            }
        } else {
            GeometryReader { geo in
                let rows = Self.gridRows(count: participants.count, compact: compact)
                let cols = CGFloat(rows.max() ?? 1)
                let width = max(0, (geo.size.width - gap * (cols - 1)) / cols)
                let height = max(0, (geo.size.height - gap * CGFloat(rows.count - 1)) / CGFloat(max(rows.count, 1)))
                VStack(spacing: gap) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { row, count in
                        let start = rows.prefix(row).reduce(0, +)
                        HStack(spacing: gap) {
                            ForEach(participants[start..<start + count]) { p in
                                participantTile(p, c).frame(width: width, height: height)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder private var controlBar: some View {
        if state == .failed {
            CallFailedActions(redialText: recoveryText ?? strings.callRedial, redialIcon: mode == .video ? "video" : "phone",
                              onClose: onClose ?? onHangup, onRedial: onRecover)
        } else {
            CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                             onToggleMute: onToggleMute, onToggleCamera: onToggleCamera,
                             onToggleSpeaker: onToggleSpeaker, onSwitchCamera: onSwitchCamera,
                             onHangup: state == .ended ? nil : onHangup, onAddMember: onAddMember,
                             onStartVideo: onStartVideo, disabled: controlsDisabled || state == .ended, devices: devices)
        }
    }

    private func select(_ p: CallParticipant) {
        selectedId = selectedId == p.id ? nil : p.id
        onSelectParticipant?(p.id)
    }

    private func participantTile(_ p: CallParticipant, _ c: FlareColors) -> some View {
        let video = Self.tileVideo(for: p, mode: mode, tile: tile)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusCard)
        return Button { select(p) } label: {
            ZStack(alignment: .bottomLeading) {
                shape.fill(c.callTile)
                // The video fills the tile, under the speaking ring and the name chip.
                if let video {
                    video.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: FlareSizes.spacingXs) {
                        AvatarView(userId: p.id, displayName: p.name, avatarURL: p.avatarURL, size: FlareSizes.componentCallTileAvatar)
                            .opacity(p.calling ? 0.5 : 1)
                        if p.calling {
                            Text(strings.callCalling).font(.system(size: chipSize)).foregroundColor(c.callOnStageSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                chip(p, c).padding(FlareSizes.spacingSm)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(p.speaking ? c.callSpeaking : .clear, lineWidth: 2))
            .contentShape(shape)
            .flareCallFocusShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(p.isSelf ? selfName : p.name)
        .accessibilityValue(p.calling ? strings.callCalling : p.muted ? strings.muted : "")
        .accessibilityAddTraits(p.id == selectedId ? .isSelected : [])
    }

    /// The name chip at the tile's bottom leading corner, the mic-off (or camera-off) glyph before the name.
    private func chip(_ p: CallParticipant, _ c: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingXs) {
            if p.muted {
                IconView("mic-off", size: chipSize, color: c.callOnStage)
            } else if p.cameraOff && mode == .video {
                IconView("camera-off", size: chipSize, color: c.callOnStage)
            }
            Text(p.isSelf ? selfName : p.name).font(.system(size: chipSize)).foregroundColor(c.callOnStage).lineLimit(1)
        }
        .padding(.horizontal, FlareSizes.spacing2xs).padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(c.callChip))
    }
}
