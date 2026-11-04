import Foundation
import SwiftUI

// MARK: - Invite contracts
//
// Pure logic shared by the four platforms behind the registration form's invite-code field
// (`InviteCodeFieldView`) and the "my invite" card (`MyInvitePanelView`). Vectors:
// spec/invite-vectors.json. The host owns the network: it runs the pre-check, fetches the code,
// the stats and the invitees, and performs copy. Nothing here has a side
// effect. The alphabet is Crockford base32 without I / L / O / U, so what a person types is
// corrected the way the server reads it (O→0, I/L→1) before it is shown.

/// Tenant invite mode: `off` hides the field, `optional` and `required` show it.
public enum FlareInviteCodeMode: String, Sendable { case off, optional, required }

/// Result of the host's pre-check for one code.
public struct FlareInviteCodeCheckResult: Equatable, Sendable {
    public let valid: Bool
    /// Masked display name of the inviter the code resolves to.
    public let inviterDisplayName: String?
    public init(valid: Bool, inviterDisplayName: String? = nil) {
        self.valid = valid; self.inviterDisplayName = inviterDisplayName
    }
}

/// The invite-code field's state vector.
public enum FlareInviteCodeFieldState: String, Sendable { case off, idle, typing, checking, valid, invalid, disabled }

/// Referral counts per depth for the current person.
public struct FlareReferralStats: Equatable, Sendable {
    public let direct: Int
    public let l2: Int
    public let l3: Int
    public let total: Int
    public init(direct: Int, l2: Int, l3: Int, total: Int) {
        self.direct = direct; self.l2 = l2; self.l3 = l3; self.total = total
    }
    public func of(_ depth: FlareReferralDepth) -> Int {
        switch depth {
        case .direct: return direct
        case .l2: return l2
        case .l3: return l3
        case .total: return total
        }
    }
}

/// One person in an invitation tree; `joinedAt` is epoch milliseconds.
public struct FlareInvitee: Identifiable, Equatable, Sendable {
    public var id: String { userId }
    public let userId: String
    public let displayName: String
    public let avatarURL: String?
    public let joinedAt: Int64
    public let hasChildren: Bool
    public init(userId: String, displayName: String, avatarURL: String? = nil, joinedAt: Int64,
                hasChildren: Bool = false) {
        self.userId = userId; self.displayName = displayName; self.avatarURL = avatarURL; self.joinedAt = joinedAt
        self.hasChildren = hasChildren
    }
}

public struct FlareInviteeBranchPage: Sendable {
    public let invitees: [FlareInvitee]
    public let nextCursor: String?

    public init(invitees: [FlareInvitee], nextCursor: String? = nil) {
        self.invitees = invitees
        self.nextCursor = nextCursor
    }
}

/// The current person's upstream invitation relationship.
public enum FlareInviteInviter: Equatable, Sendable {
    case person(userId: String, displayName: String, avatarURL: String?)
    case none
    case unavailable
}

/// Delay between the last keystroke and the check request.
public let flareInviteCheckDebounce: TimeInterval = 0.4

/// Normalize like Social registration, retaining invalid input for validation.
public func normalizeInviteCode(_ raw: String?) -> String {
    var out = ""
    for scalar in (raw ?? "").unicodeScalars {
        if scalar.properties.isWhitespace || scalar == "-" { continue }
        let value = scalar.value
        let uppercase = (97...122).contains(value) ? Unicode.Scalar(value - 32)! : scalar
        switch uppercase {
        case "O": out.append("0")
        case "I", "L": out.append("1")
        case "U": out.append("V")
        default: out.unicodeScalars.append(uppercase)
        }
    }
    return out
}

/// One state at a time, in priority order: `off` beats everything, `disabled` beats what the host
/// says about the value, a host error beats a check result, an in-flight check beats a stale result,
/// then the result itself, then whether anything has been typed.
public func inviteCodeFieldState(mode: FlareInviteCodeMode, value: String, checking: Bool = false,
                                 checkResult: FlareInviteCodeCheckResult? = nil, error: String? = nil,
                                 disabled: Bool = false) -> FlareInviteCodeFieldState {
    if mode == .off { return .off }
    if disabled { return .disabled }
    if let error, !error.isEmpty { return .invalid }
    if checking { return .checking }
    if let checkResult { return checkResult.valid ? .valid : .invalid }
    return value.isEmpty ? .idle : .typing
}

/// The code the host should pre-check for `value`, or nil when no request should be made: a partial
/// code is never sent, a disabled or hidden field never asks.
public func inviteCodeToCheck(value: String,
                              mode: FlareInviteCodeMode = .optional, disabled: Bool = false) -> String? {
    if mode == .off || disabled { return nil }
    let code = normalizeInviteCode(value)
    let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    return (4...12).contains(code.utf8.count) && code.allSatisfy(alphabet.contains) ? code : nil
}

public enum FlareReferralDepth: String, Sendable { case direct, l2, l3, total }

/// Which rows the panel lists for `stats`, honouring the tenant's visibility depth (0 disables stats, 1–3 otherwise).
/// `total` is always the last row once stats exist.
public func referralDepthRows(_ stats: FlareReferralStats?, maxDepthShown: Int = 3) -> [FlareReferralDepth] {
    guard stats != nil, maxDepthShown > 0 else { return [] }
    let depth = min(3, max(1, maxDepthShown))
    var rows: [FlareReferralDepth] = [.direct]
    if depth >= 2 { rows.append(.l2) }
    if depth >= 3 { rows.append(.l3) }
    rows.append(.total)
    return rows
}

public enum FlareInviteCooldownUnit: String, Sendable { case minute, hour, day }

public struct FlareInviteCooldown: Equatable, Sendable {
    public let unit: FlareInviteCooldownUnit
    public let count: Int
    public init(unit: FlareInviteCooldownUnit, count: Int) { self.unit = unit; self.count = count }
}

public struct FlareRegenerateAvailability: Equatable, Sendable {
    /// The control is drawn at all (the tenant allows regenerating).
    public let shown: Bool
    /// The control can be pressed now.
    public let enabled: Bool
    /// Time left before it can, in the coarsest whole unit that is not zero.
    public let remaining: FlareInviteCooldown?
    public init(shown: Bool, enabled: Bool, remaining: FlareInviteCooldown? = nil) {
        self.shown = shown; self.enabled = enabled; self.remaining = remaining
    }
}

/// Whether regenerating is offered, and if so whether it is still cooling down. The remaining time
/// rounds *up* so the control never re-enables before the server would.
public func regenerateAvailability(canRegenerate: Bool, availableAt: Int64?, now: Int64) -> FlareRegenerateAvailability {
    if !canRegenerate { return FlareRegenerateAvailability(shown: false, enabled: false) }
    let remainingMs = availableAt.map { $0 - now } ?? 0
    if remainingMs <= 0 { return FlareRegenerateAvailability(shown: true, enabled: true) }
    let minute = 60_000.0, hour = 60 * minute, day = 24 * hour
    let ms = Double(remainingMs)
    let remaining: FlareInviteCooldown
    if ms < hour {
        remaining = FlareInviteCooldown(unit: .minute, count: max(1, Int((ms / minute).rounded(.up))))
    } else if ms < day {
        remaining = FlareInviteCooldown(unit: .hour, count: Int((ms / hour).rounded(.up)))
    } else {
        remaining = FlareInviteCooldown(unit: .day, count: Int((ms / day).rounded(.up)))
    }
    return FlareRegenerateAvailability(shown: true, enabled: false, remaining: remaining)
}

/// `YYYY-MM-DD` for a calendar date — the same on every platform.
public func formatInviteJoinedDate(year: Int, month: Int, day: Int) -> String {
    String(format: "%04d-%02d-%02d", year, month, day)
}

/// `YYYY-MM-DD` of an epoch-millisecond instant in the device's calendar.
public func inviteJoinedDateLabel(_ epochMs: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000)
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return formatInviteJoinedDate(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
}

func inviteDepthLabel(_ strings: FlareStrings, _ depth: FlareReferralDepth) -> String {
    switch depth {
    case .direct: return strings.myInviteDirect
    case .l2: return strings.myInviteLevel2
    case .l3: return strings.myInviteLevel3
    case .total: return strings.myInviteTotal
    }
}

func inviteCooldownText(_ strings: FlareStrings, _ remaining: FlareInviteCooldown) -> String {
    let unit: String
    switch remaining.unit {
    case .minute: unit = strings.myInviteUnitMinutes
    case .hour: unit = strings.myInviteUnitHours
    case .day: unit = strings.myInviteUnitDays
    }
    return strings.myInviteCooldown.replacingOccurrences(of: "{time}", with: unit.replacingOccurrences(of: "{n}", with: String(remaining.count)))
}

// MARK: - InviteCodeField

/// The registration form's invite-code field. Spec: Form/InviteCodeField (`InviteCodeFieldView`).
///
/// The tenant decides whether it exists (`mode`), the person types or pastes a code, the field
/// normalizes it the way the server reads it (the binding holds the normalized code) and — once
/// the code is complete — asks the host to pre-check it through `onCheck`. The host owns the
/// request: it sets `checking`, then hands back `checkResult` (or an `error` it has already
/// localized). The field never touches the network.
public struct InviteCodeFieldView: View {
    @Binding private var text: String
    private let mode: FlareInviteCodeMode
    private let prefill: String?
    private let checking: Bool
    private let checkResult: FlareInviteCodeCheckResult?
    private let error: String?
    private let disabled: Bool
    private let label: String?
    private let placeholder: String?
    private let onCheck: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var prefillApplied = false
    @State private var lastRequested: String?
    @State private var pending: Task<Void, Never>?

    public init(text: Binding<String>, mode: FlareInviteCodeMode = .optional, prefill: String? = nil,
                checking: Bool = false, checkResult: FlareInviteCodeCheckResult? = nil, error: String? = nil,
                disabled: Bool = false,
                label: String? = nil, placeholder: String? = nil, onCheck: ((String) -> Void)? = nil) {
        self._text = text; self.mode = mode; self.prefill = prefill; self.checking = checking
        self.checkResult = checkResult; self.error = error; self.disabled = disabled
        self.label = label; self.placeholder = placeholder; self.onCheck = onCheck
    }

    /// The state the view is in for the current props — what the spec's state vector names.
    public var state: FlareInviteCodeFieldState {
        inviteCodeFieldState(mode: mode, value: text, checking: checking, checkResult: checkResult,
                             error: error, disabled: disabled)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let state = self.state
        if state != .off {
            // A stale result for another code must not be shown as this code's verdict.
            let resultMatches = checkResult == nil || inviteCodeToCheck(value: text) != nil
            let inviter = checkResult?.inviterDisplayName?.trimmingCharacters(in: .whitespaces) ?? ""
            let errorLine: String? = {
                if let error, !error.isEmpty { return error }
                if text.count >= 4 && inviteCodeToCheck(value: text) == nil { return strings.inviteCodeInvalid }
                if state == .invalid && resultMatches { return strings.inviteCodeInvalid }
                return nil
            }()
            FormFieldView(label: label ?? strings.inviteCodeLabel, required: mode == .required, error: errorLine) {
                VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
                    InputView(text: normalizedBinding, placeholder: placeholder ?? strings.inviteCodePlaceholder,
                              disabled: disabled, monospace: true)
                        .autocorrectionDisabled()
                    if state == .checking {
                        HStack(spacing: FlareSizes.spacing2xs) {
                            ProgressView().controlSize(.small)
                            Text(strings.inviteCodeChecking)
                                .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.updatesFrequently)
                    } else if state == .valid && resultMatches {
                        HStack(spacing: FlareSizes.spacing2xs) {
                            IconView("success", size: FlareSizes.iconSizeSm, color: colors.successText)
                            Text(inviter.isEmpty ? strings.inviteCodeValid : strings.inviteCodeInviter.replacingOccurrences(of: "{name}", with: inviter))
                                .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.successText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .onAppear(perform: applyPrefill)
            .onChange(of: prefill) { _ in applyPrefill() }
            .onChange(of: text) { next in scheduleCheck(next) }
            .onDisappear { pending?.cancel() }
        }
    }

    /// The binding the input edits: every write is normalized before it reaches the host.
    private var normalizedBinding: Binding<String> {
        Binding(get: { text }, set: { raw in
            let next = normalizeInviteCode(raw)
            if next != text { text = next }
        })
    }

    // Deep-link prefill: applied once, while the field is empty, and checked like a paste. A person
    // who clears the field afterwards is not re-filled.
    private func applyPrefill() {
        guard !prefillApplied, mode != .off, let prefill, !prefill.isEmpty, text.isEmpty else { return }
        let next = normalizeInviteCode(prefill)
        guard !next.isEmpty else { return }
        prefillApplied = true
        text = next
        scheduleCheck(next)
    }

    // Debounced pre-check: one request about 400 ms after the last change, and only for a complete
    // code. Every change cancels the wait that was running.
    private func scheduleCheck(_ value: String) {
        pending?.cancel()
        pending = nil
        guard let code = inviteCodeToCheck(value: value, mode: mode, disabled: disabled) else {
            lastRequested = nil
            return
        }
        if code == lastRequested { return }
        lastRequested = nil
        pending = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(flareInviteCheckDebounce * 1_000_000_000))
            guard !Task.isCancelled else { return }
            lastRequested = code
            onCheck?(code)
        }
    }
}

// MARK: - MyInvitePanel

/// The invite code, a registration QR when configured, and referral information.
public struct MyInvitePanelView: View {
    private let code: String
    private let shareURL: String?
    private let stats: FlareReferralStats?
    private let maxDepthShown: Int
    private let invitees: [FlareInvitee]
    private let showProfiles: Bool
    private let hasMore: Bool
    private let loadingMore: Bool
    private let loading: Bool
    private let title: String?
    private let onCopy: ((String) -> Void)?
    private let onLoadMore: (() -> Void)?
    private let onSelect: ((String) -> Void)?
    private let onLoadChildren: ((String, String?) async throws -> FlareInviteeBranchPage)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @ScaledMetric(relativeTo: .title3) private var inviteCodeSize = FlareSizes.fontSize3xl
    @State private var qrCache = FlareQRCodeCache()

    /// An empty title lets a navigation screen supply its own heading.
    /// The optional `shareURL` is used only as the registration QR payload.
    public init(code: String, shareURL: String? = nil, stats: FlareReferralStats? = nil, maxDepthShown: Int = 3,
                invitees: [FlareInvitee] = [], showProfiles: Bool = true, hasMore: Bool = false,
                loadingMore: Bool = false, loading: Bool = false, title: String? = nil,
                onCopy: ((String) -> Void)? = nil, onLoadMore: (() -> Void)? = nil,
                onSelect: ((String) -> Void)? = nil,
                onLoadChildren: ((String, String?) async throws -> FlareInviteeBranchPage)? = nil) {
        self.code = code; self.shareURL = shareURL; self.stats = stats; self.maxDepthShown = maxDepthShown
        self.invitees = invitees; self.showProfiles = showProfiles; self.hasMore = hasMore
        self.loadingMore = loadingMore; self.loading = loading; self.title = title
        self.onCopy = onCopy; self.onLoadMore = onLoadMore; self.onSelect = onSelect
        self.onLoadChildren = onLoadChildren
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let heading = title ?? strings.myInviteTitle
        let standalone = heading.isEmpty

        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            if !standalone {
                Text(heading).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }

            codeCard(colors)
            statistics(colors)
            if showProfiles && maxDepthShown > 0 { relationshipsCard(colors, standalone: standalone) }
        }
        .padding(standalone ? 0 : FlareSizes.spacingMd)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
            .fill(standalone ? .clear : colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .stroke(standalone ? .clear : colors.borderPrimary, lineWidth: 1)))
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(standalone ? strings.myInviteTitle : heading)
    }

    private func codeCard(_ colors: FlareColors) -> some View {
        let hasCode = !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(spacing: FlareSizes.spacingLg) {
            if loading {
                RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                    .fill(colors.bgPrimary)
                    .frame(width: 160, height: 28)
                    .accessibilityLabel(strings.myInviteLoading)
            } else if hasCode {
                if let link = shareURL, !link.isEmpty, let image = qrCache.image(for: link) {
                    VStack(spacing: FlareSizes.spacingSm) {
                        FlareQRCodeFrame(code: image, label: strings.myInviteQrHint)
                            .frame(maxWidth: 196)
                        Text(strings.myInviteQrHint)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .accessibilityHidden(true)
                    }
                }
                inviteCodeRow(colors)
            } else {
                Text(strings.myInviteCodeUnavailable)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(FlareSizes.spacingMd)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
            .fill(colors.bgSecondary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.primary.opacity(0.08))))
    }

    private func inviteCodeRow(_ colors: FlareColors) -> some View {
        let identity = VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            Text(strings.myInviteCodeLabel)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.textSecondary)
            Text(code)
                .font(.system(size: inviteCodeSize, weight: .semibold, design: .monospaced))
                .foregroundColor(colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .textSelection(.enabled)
        }
        return Group {
            if let onCopy {
                let copy = ButtonView(label: strings.myInviteCopy, variant: .primary, size: .sm,
                                      icon: "copy", maintainTouchTarget: true) { onCopy(code) }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: FlareSizes.spacingMd) {
                        identity.fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 0)
                        copy
                    }
                    VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                        identity
                        copy.frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            } else {
                identity
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgPrimary))
    }

    @ViewBuilder
    private func statistics(_ colors: FlareColors) -> some View {
        let rows = referralDepthRows(stats, maxDepthShown: maxDepthShown)
        if !rows.isEmpty, let stats {
            Text(strings.myInviteStatsTitle).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                .foregroundColor(colors.textPrimary).accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FlareSizes.spacingSm), count: 2),
                      spacing: FlareSizes.spacingSm) {
                ForEach(rows, id: \.rawValue) { depth in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(inviteDepthLabel(strings, depth)).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                        Text(String(stats.of(depth)))
                            .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold)).monospacedDigit()
                            .foregroundColor(depth == .total ? colors.primaryText : colors.textPrimary)
                    }
                    .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgPrimary))
                    .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).stroke(colors.borderSecondary, lineWidth: 1))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func relationshipsCard(_ colors: FlareColors, standalone: Bool) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Text(strings.myInviteRelationships).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if loading && invitees.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: FlareSizes.spacingMd) {
                        Circle().fill(colors.bgSecondary).frame(width: FlareSizes.avatarSize, height: FlareSizes.avatarSize)
                        RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.bgSecondary).frame(width: 120, height: FlareSizes.iconSizeSm)
                    }
                    .frame(minHeight: FlareSizes.touchTarget)
                }
                .accessibilityHidden(true)
            } else if invitees.isEmpty {
                Text(strings.myInviteEmpty).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            } else {
                ForEach(Array(invitees.enumerated()), id: \.element.id) { index, invitee in
                    if index > 0 { Divider().overlay(colors.borderSecondary) }
                    InviteeBranchRow(invitee: invitee, remainingDepth: maxDepthShown - 1, colors: colors,
                                      onSelect: onSelect, onLoadChildren: onLoadChildren)
                }
                if hasMore {
                    ButtonView(label: strings.myInviteLoadMore, variant: .ghost, size: .sm, loading: loadingMore,
                               disabled: loadingMore, block: true) { onLoadMore?() }
                }
            }
        }
        .padding(standalone ? FlareSizes.spacingMd : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
            .fill(standalone ? colors.bgPrimary : .clear))
    }

}

private struct InviteeBranchRow: View {
    let invitee: FlareInvitee
    let remainingDepth: Int
    let colors: FlareColors
    let onSelect: ((String) -> Void)?
    let onLoadChildren: ((String, String?) async throws -> FlareInviteeBranchPage)?
    @Environment(\.flareStrings) private var strings
    @State private var expanded = false
    @State private var children: [FlareInvitee]?
    @State private var nextCursor: String?
    @State private var loading = false
    @State private var failed = false
    @State private var request = 0

    private var expandable: Bool {
        remainingDepth > 0 && invitee.hasChildren && onLoadChildren != nil
    }

    private var branchLabel: String {
        (expanded ? strings.myInviteCollapse : strings.myInviteExpand)
            .replacingOccurrences(of: "{name}", with: invitee.displayName)
    }

    private var branchIcon: String { expanded ? "chevron-down" : "chevron-right" }

    var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            if expandable && onSelect == nil {
                Button(action: toggleBranch) {
                    HStack(spacing: FlareSizes.spacingSm) {
                        identity
                        FlareIconImage(name: branchIcon, size: FlareSizes.iconSizeSm, weight: .medium)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal, FlareSizes.spacingSm)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(branchLabel)
            } else {
                HStack(spacing: FlareSizes.spacingSm) {
                    if let onSelect {
                        Button { onSelect(invitee.userId) } label: { identity }
                            .buttonStyle(.plain)
                            .accessibilityLabel(invitee.displayName)
                    } else {
                        identity.accessibilityElement(children: .combine)
                    }
                    if expandable {
                        IconButtonView(icon: branchIcon, accessibilityLabel: branchLabel, action: toggleBranch)
                    }
                }
            }
            if expanded && expandable {
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    ForEach(children ?? []) { child in
                        InviteeBranchRow(invitee: child, remainingDepth: remainingDepth - 1, colors: colors,
                                          onSelect: onSelect, onLoadChildren: onLoadChildren)
                    }
                    if loading {
                        HStack(spacing: FlareSizes.spacingSm) {
                            ProgressView().controlSize(.small)
                            Text(strings.myInviteLoading)
                        }
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textSecondary)
                        .accessibilityElement(children: .combine)
                    } else if failed {
                        ButtonView(label: strings.retry, variant: .ghost, size: .sm,
                                   maintainTouchTarget: true, action: requestPage)
                    } else if nextCursor != nil {
                        ButtonView(label: strings.myInviteLoadMore, variant: .ghost, size: .sm,
                                   maintainTouchTarget: true, action: requestPage)
                    } else if children?.isEmpty == true {
                        Text(strings.myInviteNoChildren)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .padding(.leading, FlareSizes.spacingMd)
                .overlay(alignment: .leading) { Rectangle().fill(colors.borderSecondary).frame(width: 1) }
                .padding(.leading, FlareSizes.spacingMd)
            }
        }
        .task(id: request) { await loadPage() }
    }

    private var identity: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: invitee.userId, displayName: invitee.displayName, avatarURL: invitee.avatarURL,
                       size: FlareSizes.avatarSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(invitee.displayName).font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                    .foregroundColor(colors.textPrimary)
                if invitee.joinedAt > 0 {
                    Text(strings.myInviteJoined.replacingOccurrences(
                        of: "{date}", with: inviteJoinedDateLabel(invitee.joinedAt)
                    ))
                    .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, FlareSizes.spacingXs)
        .frame(minHeight: FlareSizes.touchTarget)
        .contentShape(Rectangle())
    }

    private func toggleBranch() {
        expanded.toggle()
        if expanded && children == nil && !failed { requestPage() }
    }

    private func requestPage() {
        guard !loading else { return }
        loading = true
        failed = false
        request += 1
    }

    private func loadPage() async {
        guard loading, expandable, let onLoadChildren else { return }
        let cursor = nextCursor
        defer { loading = false }
        do {
            let page = try await onLoadChildren(invitee.userId, cursor)
            try Task.checkCancellation()
            let existing = children ?? []
            var seen = Set(existing.map(\.userId))
            children = existing + page.invitees.filter { seen.insert($0.userId).inserted }
            nextCursor = page.nextCursor == cursor ? nil : page.nextCursor
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }
}
