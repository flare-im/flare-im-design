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
/// The card is the message's card surface (the kit card shell, at most `richCardWidth` like every card): the
/// timeline draws no bubble around it, and a quoted reply sits inside the shell.
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
    @State private var confirmingCallBack = false
    @State private var callBackConfirmed = false
    @ScaledMetric(relativeTo: .body) private var statusFontSize = FlareSizes.fontSizeLg
    @ScaledMetric(relativeTo: .caption) private var mediaFontSize = FlareSizes.fontSizeSm
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

    private var canActivateCallBack: Bool {
        action == .callBack && !busy && onCallBack != nil
    }

    public var body: some View {
        FlareMessageCardShell(padded: false, fillWidth: false) {
            if action == .callBack {
                Button {
                    guard canActivateCallBack, !confirmingCallBack else { return }
                    callBackConfirmed = false
                    confirmingCallBack = true
                } label: {
                    recordContents
                }
                .buttonStyle(.plain)
                .disabled(!canActivateCallBack)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(mediaText)
                .accessibilityValue(statusText)
                .accessibilityHint(strings.callRecordCallBack)
            } else {
                recordContents
            }
        }
        .accessibilityElement(children: .contain)
        .flareModal(isPresented: $confirmingCallBack,
                    title: "\(strings.callRecordCallBack) · \(mediaText)",
                    footer: AnyView(CallRecordConfirmationActions(isPresented: $confirmingCallBack,
                                                                  enabled: canActivateCallBack) {
                        callBackConfirmed = true
                    }), onDismiss: {
                        guard callBackConfirmed else { return }
                        callBackConfirmed = false
                        guard canActivateCallBack else { return }
                        onCallBack?()
                    }) {
            Text(strings.callRecordConfirmCallBack)
        }
    }

    private var recordContents: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let danger = FlareCallRecordRules.tone(status) == .danger
        let accent = danger ? colors.error : colors.primary
        let ink = danger ? colors.errorText : colors.primaryText
        return HStack(spacing: FlareSizes.spacingSm) {
            ZStack {
                Circle().fill(accent.opacity(FlareOpacity.tintWeak))
                IconView(media == .video ? "video" : "phone", size: FlareSizes.iconSizeMd, color: ink)
            }
            .frame(width: FlareSizes.controlHeightSm, height: FlareSizes.controlHeightSm)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                Text(statusText)
                    .font(.system(size: statusFontSize, weight: .medium))
                    .foregroundColor(danger ? colors.errorText : colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: statusFontSize * FlareSizes.lineHeightSnug, alignment: .leading)
                Text(mediaText)
                    .font(.system(size: mediaFontSize))
                    .foregroundColor(colors.textTertiary)
                    .lineLimit(1)
                    .frame(minHeight: mediaFontSize * FlareSizes.lineHeightSnug, alignment: .leading)
            }
            // One element for what the card says; the action names itself.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mediaText)
            .accessibilityValue(statusText)
            if action == .join {
                ButtonView(label: strings.callRecordJoin,
                           variant: .secondary, size: .sm, loading: busy,
                           action: onJoin)
                    .fixedSize()
            }
        }
        .padding(.horizontal, FlareSizes.spacingSm)
        .padding(.vertical, canActivateCallBack ? FlareSizes.spacing2xs : FlareSizes.spacingXs)
        .frame(minHeight: action == .callBack ? FlareSizes.touchTarget : nil)
        .contentShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
    }
}

/// The modal owns dismissal; only a still-available, explicitly confirmed callback reaches the host.
struct CallRecordConfirmationActions: View {
    @Binding var isPresented: Bool
    let enabled: Bool
    let onConfirm: () -> Void
    @Environment(\.flareStrings) private var strings

    var body: some View {
        HStack(spacing: FlareSizes.spacingSm) {
            ButtonView(label: strings.cancel, variant: .secondary) { isPresented = false }
            ButtonView(label: strings.confirm, disabled: !enabled) {
                guard isPresented, enabled else { return }
                isPresented = false
                onConfirm()
            }
        }
    }
}
