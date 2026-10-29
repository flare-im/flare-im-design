import SwiftUI

// MARK: - CallRecordCard

/// The call record in the chat timeline — the media icon, one viewer-relative status line, the media name and at
/// most one action. Spec: Call/CallRecordCard (`CallRecordCardView`); the rules are the shared table
/// `spec/call-record-vectors.json` (``FlareCallRecordRules``).
///
/// Presentational only: the host maps the call plugin's record and the viewer's own facts onto these values and owns
/// what `onJoin` and `onCallBack` do. `canJoin` (a group call in progress the viewer is not in) and `canCallBack`
/// (calls available for this conversation) are the host's decisions; `disabled` (the plugin is unavailable) keeps
/// the record and drops the action, and `busy` shows the action in progress without taking another tap.
///
/// The card is the message's card surface (the kit card shell at the compact card width): the timeline draws no
/// bubble around it, and a quoted reply sits inside the shell.
public struct CallRecordCardView: View {
    private let media: FlareCallMode
    private let scope: FlareCallRecordScope
    private let state: FlareCallRecordState
    private let endReason: FlareCallEndReason?
    private let durationSeconds: Int?
    private let joinedCount: Int?
    private let viewerIsInitiator: Bool
    private let canJoin: Bool
    private let canCallBack: Bool
    private let disabled: Bool
    private let busy: Bool
    private let onJoin: (() -> Void)?
    private let onCallBack: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(media: FlareCallMode, scope: FlareCallRecordScope, state: FlareCallRecordState,
                endReason: FlareCallEndReason? = nil, durationSeconds: Int? = nil, joinedCount: Int? = nil,
                viewerIsInitiator: Bool, canJoin: Bool, canCallBack: Bool, disabled: Bool = false, busy: Bool = false,
                onJoin: (() -> Void)? = nil, onCallBack: (() -> Void)? = nil) {
        self.media = media; self.scope = scope; self.state = state; self.endReason = endReason
        self.durationSeconds = durationSeconds; self.joinedCount = joinedCount
        self.viewerIsInitiator = viewerIsInitiator; self.canJoin = canJoin; self.canCallBack = canCallBack
        self.disabled = disabled; self.busy = busy; self.onJoin = onJoin; self.onCallBack = onCallBack
    }

    /// The status line this card shows.
    var status: FlareCallRecordStatus {
        FlareCallRecordRules.status(scope: scope, state: state, viewerIsInitiator: viewerIsInitiator,
                                    endReason: endReason, durationSeconds: durationSeconds, joinedCount: joinedCount)
    }

    /// The action this card offers, or nil.
    var action: FlareCallRecordAction? {
        FlareCallRecordRules.action(scope: scope, state: state, canJoin: canJoin, canCallBack: canCallBack,
                                    disabled: disabled)
    }

    var statusText: String {
        FlareCallRecordRules.text(status, strings: strings, joinedCount: joinedCount, durationSeconds: durationSeconds)
    }

    var mediaText: String { media == .video ? strings.callRecordVideo : strings.callRecordVoice }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let danger = FlareCallRecordRules.tone(status) == .danger
        let accent = danger ? colors.error : colors.primary
        let ink = danger ? colors.errorText : colors.primaryText
        FlareMessageCardShell(padded: true) {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().fill(accent.opacity(FlareOpacity.tintWeak))
                    IconView(media == .video ? "video" : "phone", size: FlareSizes.iconSizeMd, color: ink)
                }
                .frame(width: FlareSizes.controlHeightMd, height: FlareSizes.controlHeightMd)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    Text(statusText)
                        .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                        .foregroundColor(danger ? colors.errorText : colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(mediaText)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // One element for what the card says; the action names itself.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(mediaText)
                .accessibilityValue(statusText)
                if let action {
                    ButtonView(label: action == .join ? strings.callRecordJoin : strings.callRecordCallBack,
                               variant: .secondary, size: .sm, loading: busy,
                               action: action == .join ? onJoin : onCallBack)
                        .fixedSize()
                }
            }
        }
        .frame(maxWidth: FlareSizes.componentRichCardCompactWidth, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}
