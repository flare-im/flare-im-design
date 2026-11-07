import SwiftUI

/// The network and line diagnostics page's body. Spec: Feedback/AccessDiagnostics (`AccessDiagnosticsView`).
///
/// The host passes what `access.getStatus` and `access.listAccessPoints` returned; what the page says is
/// ``flareAccessDiagnostics(_:accessPoints:)``'s call (`spec/access-diagnostics-vectors.json`, the same in every kit).
/// The view holds no SDK: it reports intent and draws what the host feeds back, and it never touches the clipboard.
/// An action is drawn only when the host passes its handler. Recovery comes first while recovering, because that is
/// what the page is open for then.
public struct AccessDiagnosticsView: View {
    private let status: FlareAccessStatus?
    private let accessPoints: [FlareAccessPoint]
    private let refreshing: Bool
    private let refreshOutcome: String?
    private let importing: Bool
    private let importOutcome: String?
    private let importCode: String?
    private let exporting: Bool
    private let exportOutcome: String?
    private let onPin: ((String) -> Void)?
    private let onUnpin: (() -> Void)?
    private let onRefresh: (() -> Void)?
    private let onImportRecovery: ((String) -> Void)?
    private let onExportDiagnostics: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @State private var link = ""

    /// - Parameters:
    ///   - status: what `access.getStatus` returned; nil until the host has read it.
    ///   - accessPoints: what `access.listAccessPoints` returned.
    ///   - refreshing: `access.refresh` is in flight.
    ///   - refreshOutcome: the `outcome` of the last `access.refresh`.
    ///   - importing: `access.importRecovery` is in flight.
    ///   - importOutcome: the `outcome` of the last `access.importRecovery`.
    ///   - importCode: its `code` when rejected.
    ///   - exporting: the host is gathering and copying the diagnostics.
    ///   - exportOutcome: the host's word on the clipboard, `copied` or `failed`.
    ///   - onPin: pin this access point (`access.pin`).
    ///   - onUnpin: let go of the pin (`access.unpin`).
    ///   - onRefresh: refresh the manifest now (`access.refresh`).
    ///   - onImportRecovery: import this recovery link (`access.importRecovery`), already trimmed.
    ///   - onExportDiagnostics: copy the diagnostics (`access.exportDiagnostics`, then the clipboard).
    public init(status: FlareAccessStatus?, accessPoints: [FlareAccessPoint] = [],
                refreshing: Bool = false, refreshOutcome: String? = nil,
                importing: Bool = false, importOutcome: String? = nil, importCode: String? = nil,
                exporting: Bool = false, exportOutcome: String? = nil,
                onPin: ((String) -> Void)? = nil, onUnpin: (() -> Void)? = nil, onRefresh: (() -> Void)? = nil,
                onImportRecovery: ((String) -> Void)? = nil, onExportDiagnostics: (() -> Void)? = nil) {
        self.status = status; self.accessPoints = accessPoints
        self.refreshing = refreshing; self.refreshOutcome = refreshOutcome
        self.importing = importing; self.importOutcome = importOutcome; self.importCode = importCode
        self.exporting = exporting; self.exportOutcome = exportOutcome
        self.onPin = onPin; self.onUnpin = onUnpin; self.onRefresh = onRefresh
        self.onImportRecovery = onImportRecovery; self.onExportDiagnostics = onExportDiagnostics
    }

    private var trimmedLink: String { link.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var importable: Bool { !trimmedLink.isEmpty && !importing }

    private func importLink() {
        if importable { onImportRecovery?(trimmedLink) }
    }

    /// The newest answer, else the page's lead notice, is what is announced.
    private func spoken(_ model: FlareAccessDiagnosticsModel) -> String? {
        flareAccessImportFeedback(importOutcome, code: importCode)?.text.label(strings)
            ?? flareAccessRefreshFeedback(refreshOutcome)?.text.label(strings)
            ?? flareAccessExportFeedback(exportOutcome)?.text.label(strings)
            ?? model.notices.first?.text.label(strings)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let model = flareAccessDiagnostics(status, accessPoints: accessPoints)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXl) {
            if !model.notices.isEmpty {
                VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                    ForEach(model.notices, id: \.text) { notice in
                        StatusBannerView(text: notice.text.label(strings), tone: notice.tone, pulse: notice.pulse)
                    }
                }
            }
            if model.state == .recovering {
                recovery(colors)
                current(model, colors)
                lines(model, colors)
            } else {
                current(model, colors)
                lines(model, colors)
                recovery(colors)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(strings.accessDiagnosticsTitle)
        .onChange(of: spoken(model)) { message in
            if let message { flareAnnounce(message) }
        }
        // An adopted link is done with: left in the field it would only invite a second import.
        .onChange(of: importOutcome) { outcome in
            if outcome == "adopted" { link = "" }
        }
    }

    private func section<Content: View>(_ title: String, _ colors: FlareColors,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            Text(title)
                .font(.system(size: FlareTextRoles.body.fontSize, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func current(_ model: FlareAccessDiagnosticsModel, _ colors: FlareColors) -> some View {
        section(strings.accessDiagnosticsCurrent, colors) {
            fact(strings.accessDiagnosticsAccessPoint, status?.accessPointId, colors)
            fact(strings.accessDiagnosticsRegion, status?.regionId, colors)
            fact(strings.accessDiagnosticsProtocol, flareAccessProtocolLabel(status?.protocol), colors)
            fact(strings.accessDiagnosticsRtt, model.rtt.label(strings), colors,
                 tone: model.rtt.grade.map(flareAccessRttTone))
            fact(strings.accessDiagnosticsSerial, status?.loaded == true ? status?.serial.map(String.init) : nil, colors)
            fact(strings.accessDiagnosticsSource, flareAccessSourceLabel(status?.source, strings: strings), colors)
            fact(strings.accessDiagnosticsManifest, manifestText(model.manifest), colors)
            fact(strings.connectionDevelopmentMode,
                 status?.developmentMode == true ? strings.accessDiagnosticsOn : strings.accessDiagnosticsOff, colors)
            if let reported = model.reportedAccessPointId {
                fact(strings.accessDiagnosticsReportedAccessPoint, reported, colors)
            }
            if let rounds = model.recoveryRounds {
                fact(strings.accessDiagnosticsRecoveryRounds, "\(rounds)", colors)
            }
        }
    }

    private func manifestText(_ manifest: FlareAccessManifestState) -> String {
        switch manifest {
        case .valid: return strings.accessDiagnosticsManifestValid
        case .stale: return strings.accessDiagnosticsManifestStale
        case .none: return strings.accessDiagnosticsManifestNone
        }
    }

    /// A label and its value on one line; a missing value is a dash, never a blank.
    private func fact(_ label: String, _ value: String?, _ colors: FlareColors, tone: FlareStatusTone? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingMd) {
            Text(label)
                .font(FlareTextRoles.body.font)
                .foregroundColor(colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if let value, let tone {
                    tag(value, tone: tone, colors)
                } else {
                    Text(value ?? "—")
                        .font(FlareTextRoles.body.font)
                        .foregroundColor(value == nil ? colors.textTertiary : colors.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func lines(_ model: FlareAccessDiagnosticsModel, _ colors: FlareColors) -> some View {
        section(strings.accessDiagnosticsLines, colors) {
            if model.regions.isEmpty {
                Text(strings.accessDiagnosticsNoLines)
                    .font(FlareTextRoles.body.font)
                    .foregroundColor(colors.textTertiary)
            }
            ForEach(model.regions, id: \.regionId) { region in
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    if let regionId = region.regionId {
                        Text(regionId)
                            .font(FlareTextRoles.caption.font)
                            .foregroundColor(colors.textSecondary)
                            .accessibilityAddTraits(.isHeader)
                    }
                    ForEach(Array(region.accessPoints.enumerated()), id: \.element.id) { index, row in
                        if index > 0 {
                            Rectangle().fill(colors.borderSecondary).frame(height: 1)
                        }
                        lineRow(row, colors)
                    }
                }
            }
        }
    }

    private func pinHandler(_ row: FlareAccessPointRow) -> (() -> Void)? {
        switch row.pin {
        case .pin: return onPin.map { pin in { pin(row.accessPointId) } }
        case .unpin: return onUnpin
        case nil: return nil
        }
    }

    private func lineRow(_ row: FlareAccessPointRow, _ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                FlareFlowLayout(spacing: FlareSizes.spacingXs, lineSpacing: FlareSizes.spacingXs) {
                    Text(row.accessPointId)
                        .font(.system(size: FlareTextRoles.body.fontSize, design: .monospaced))
                        .foregroundColor(colors.textPrimary)
                    if row.current { tag(strings.accessDiagnosticsCurrentTag, tone: .info, colors) }
                    if row.pinned { tag(strings.accessDiagnosticsPinnedTag, tone: .neutral, colors) }
                }
                if let host = row.host {
                    Text(host)
                        .font(FlareTextRoles.caption.font)
                        .foregroundColor(colors.textSecondary)
                }
                FlareFlowLayout(spacing: FlareSizes.spacingXs, lineSpacing: FlareSizes.spacingXs) {
                    tag(statusText(row.status), tone: row.statusTone, colors)
                    if let breaker = row.breaker {
                        tag(breaker == .open ? strings.accessDiagnosticsBreakerOpen : strings.accessDiagnosticsBreakerHalfOpen,
                            tone: row.breakerTone ?? .neutral, colors)
                    }
                    if let rtt = row.rtt.label(strings), let grade = row.rtt.grade {
                        tag(rtt, tone: flareAccessRttTone(grade), colors)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if let toggle = pinHandler(row) {
                let label = row.pin == .pin ? strings.accessDiagnosticsPin : strings.accessDiagnosticsUnpin
                ButtonView(label: label, variant: .secondary, size: .sm, maintainTouchTarget: true, action: toggle)
                    .accessibilityLabel("\(label) \(row.accessPointId)")
            }
        }
        .padding(.vertical, FlareSizes.spacingSm)
    }

    private func statusText(_ status: FlareAccessPointState) -> String {
        switch status {
        case .active: return strings.accessDiagnosticsStatusActive
        case .draining: return strings.accessDiagnosticsStatusDraining
        case .disabled: return strings.accessDiagnosticsStatusDisabled
        case .unknown: return strings.accessDiagnosticsStatusUnknown
        }
    }

    private func recovery(_ colors: FlareColors) -> some View {
        section(strings.accessDiagnosticsRecovery, colors) {
            if onRefresh != nil || onExportDiagnostics != nil {
                FlareFlowLayout(spacing: FlareSizes.spacingSm, lineSpacing: FlareSizes.spacingSm) {
                    if let onRefresh {
                        ButtonView(label: strings.accessDiagnosticsRefresh, variant: .secondary, loading: refreshing,
                                   maintainTouchTarget: true, action: onRefresh)
                    }
                    if let onExportDiagnostics {
                        ButtonView(label: strings.accessDiagnosticsExport, variant: .secondary, loading: exporting,
                                   maintainTouchTarget: true, action: onExportDiagnostics)
                    }
                }
            }
            if let feedback = flareAccessRefreshFeedback(refreshOutcome) {
                StatusBannerView(text: feedback.text.label(strings), tone: feedback.tone, dot: false)
            }
            if let feedback = flareAccessExportFeedback(exportOutcome) {
                StatusBannerView(text: feedback.text.label(strings), tone: feedback.tone, dot: false)
            }
            if onImportRecovery != nil {
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(strings.accessDiagnosticsImportLabel)
                        .font(FlareTextRoles.caption.font)
                        .foregroundColor(colors.textSecondary)
                    HStack(spacing: FlareSizes.spacingSm) {
                        InputView(text: $link, placeholder: strings.accessDiagnosticsImportPlaceholder,
                                  disabled: importing, monospace: true, onSubmit: importLink)
                            .accessibilityLabel(strings.accessDiagnosticsImportLabel)
                        ButtonView(label: strings.accessDiagnosticsImport, loading: importing, disabled: !importable,
                                   maintainTouchTarget: true, action: importLink)
                    }
                    Text(strings.accessDiagnosticsImportHint)
                        .font(FlareTextRoles.caption.font)
                        .foregroundColor(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let feedback = flareAccessImportFeedback(importOutcome, code: importCode) {
                        StatusBannerView(text: feedback.text.label(strings), tone: feedback.tone, dot: false)
                            .id(Self.importAnswerID)
                    }
                }
            }
        }
    }

    /// The kit tag's look in a status tone: the tone's ink on a faint tint of the tone, caption size. It is words,
    /// never a control.
    private func tag(_ text: String, tone: FlareStatusTone, _ colors: FlareColors) -> some View {
        let ink: Color
        let tint: Color
        switch tone {
        case .info: (ink, tint) = (colors.infoText, colors.info)
        case .success: (ink, tint) = (colors.successText, colors.success)
        case .warning: (ink, tint) = (colors.warningText, colors.warning)
        case .danger: (ink, tint) = (colors.errorText, colors.error)
        case .neutral: (ink, tint) = (colors.textSecondary, colors.textTertiary)
        }
        return Text(text)
            .font(.system(size: FlareTextRoles.caption.fontSize, weight: .medium))
            .foregroundColor(ink)
            .padding(.horizontal, FlareSizes.spacing2xs)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(tint.opacity(FlareOpacity.tintWeak)))
    }
}

public extension AccessDiagnosticsView {
    /// The `id` of the answer to a recovery link, for ``SwiftUI/View/flareShowsImportAnswer(_:lines:proxy:)``.
    static let importAnswerID = "flare.accessDiagnostics.importAnswer"
}

public extension View {
    /// Brings the answer to a recovery link into view. A link opens the page from outside, at its top, and the answer
    /// stands lower than a phone shows: unseen, a refused link would look like nothing happened. Put it on the
    /// `ScrollView` around ``AccessDiagnosticsView``, inside a `ScrollViewReader`. The page loads while the link is
    /// checked, so `lines` (how many arrived above, not what ticks) brings it back when they push it down again.
    func flareShowsImportAnswer(_ outcome: String?, lines: Int, proxy: ScrollViewProxy) -> some View {
        modifier(FlareImportAnswerFollower(outcome: outcome, lines: lines, proxy: proxy))
    }
}

private struct FlareImportAnswerFollower: ViewModifier {
    let outcome: String?
    let lines: Int
    let proxy: ScrollViewProxy

    func body(content: Content) -> some View {
        content
            .onAppear(perform: show)
            .onChange(of: outcome) { _ in show() }
            .onChange(of: lines) { _ in show() }
    }

    /// The answer is laid out in the next pass, not this one.
    private func show() {
        guard outcome != nil else { return }
        DispatchQueue.main.async {
            withAnimation { proxy.scrollTo(AccessDiagnosticsView.importAnswerID, anchor: .bottom) }
        }
    }
}
