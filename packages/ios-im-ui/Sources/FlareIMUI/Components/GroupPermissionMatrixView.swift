import SwiftUI

/// The five settings the matrix edits — one key per real backend field
/// (`FlareGroupDetailModel`: joinPolicy, muteAll, onlyAdminCanAtAll,
/// onlyAdminCanPin, shareCardPermission). Nothing here is invented.
public enum FlareGroupPermissionKey: String, CaseIterable, Sendable {
    case joinPolicy, muteAll, onlyAdminCanAtAll, onlyAdminCanPin, shareCardPermission
}

/// `toggle` renders a switch (flag value); `choice` renders a radio group (policy value).
public enum FlareGroupPermissionRowKind: Sendable {
    case toggle, choice
}

/// A row's value and a change's payload — the Swift spelling of the cross-platform
/// `boolean | FlareGroupJoinPolicy | null` union. `.policy(nil)` is a join policy the host does not
/// know; a change always carries a policy.
public enum FlareGroupPermissionValue: Equatable, Sendable {
    case flag(Bool)
    case policy(FlareGroupJoinPolicy?)

    public var boolValue: Bool { if case let .flag(v) = self { return v } else { return false } }
    public var policyValue: FlareGroupJoinPolicy? { if case let .policy(v) = self { return v } else { return nil } }
}

/// The subset of the group model this panel edits.
public struct FlareGroupPermissionSettings: Sendable {
    public let muteAll: Bool
    public let onlyAdminCanAtAll: Bool
    public let onlyAdminCanPin: Bool
    public let shareCardPermission: Bool
    /// How people join the group; nil when the host does not know.
    public let joinPolicy: FlareGroupJoinPolicy?

    public init(muteAll: Bool = false, onlyAdminCanAtAll: Bool = false,
                onlyAdminCanPin: Bool = false, shareCardPermission: Bool = true,
                joinPolicy: FlareGroupJoinPolicy? = nil) {
        self.muteAll = muteAll; self.onlyAdminCanAtAll = onlyAdminCanAtAll
        self.onlyAdminCanPin = onlyAdminCanPin; self.shareCardPermission = shareCardPermission
        self.joinPolicy = joinPolicy
    }
}

/// One rendered row.
public struct FlareGroupPermissionRow: Equatable, Sendable {
    public let key: FlareGroupPermissionKey
    public let kind: FlareGroupPermissionRowKind
    public let value: FlareGroupPermissionValue
    /// Viewer may change this row; `false` renders a read-only value, never a dead switch.
    public let editable: Bool
    /// This row's command is in flight — the row alone locks, its siblings stay usable.
    public let busy: Bool
    /// Why this row's last command failed; kept until the host dismisses it.
    public let error: String?

    public static func == (lhs: FlareGroupPermissionRow, rhs: FlareGroupPermissionRow) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value && lhs.editable == rhs.editable
            && lhs.busy == rhs.busy && lhs.error == rhs.error
    }
}

/// The rows to render, in canonical order — same rule set as the other platforms.
///
/// `editable` carries permission only (`canManage`), so a read-only panel keeps
/// showing values instead of disabled controls; `busy` and `error` are per key,
/// so one failed setting neither hides nor reverts the ones that succeeded. An
/// unknown `joinPolicy` stays nil rather than misreporting the group's real state.
public func groupPermissionRows(_ settings: FlareGroupPermissionSettings,
                                canManage: Bool,
                                busyKeys: [String] = [],
                                errors: [String: String] = [:]) -> [FlareGroupPermissionRow] {
    let busy = Set(busyKeys)
    return FlareGroupPermissionKey.allCases.map { key in
        let value: FlareGroupPermissionValue
        switch key {
        case .joinPolicy: value = .policy(settings.joinPolicy)
        case .muteAll: value = .flag(settings.muteAll)
        case .onlyAdminCanAtAll: value = .flag(settings.onlyAdminCanAtAll)
        case .onlyAdminCanPin: value = .flag(settings.onlyAdminCanPin)
        case .shareCardPermission: value = .flag(settings.shareCardPermission)
        }
        return FlareGroupPermissionRow(
            key: key,
            kind: key == .joinPolicy ? .choice : .toggle,
            value: value,
            editable: canManage,
            busy: busy.contains(key.rawValue),
            error: errors[key.rawValue]
        )
    }
}

/// Group permission panel — the "group settings" section of group management.
///
/// The host owns the values: switching a row only calls `onChange`, and the
/// displayed value flips when the host writes the confirmed settings back. Each
/// row has its own busy and its own failure, so a partial failure keeps the rows
/// that succeeded. Spec: Contacts/GroupPermissionMatrix.
public struct GroupPermissionMatrixView: View {
    let settings: FlareGroupPermissionSettings
    let canManage: Bool
    let busyKeys: [String]
    let errors: [String: String]
    let title, readOnlyHintText: String?
    let joinPolicyLabel, joinPolicyDescription: String?
    let joinInviteText, joinApprovalText, joinOpenText, unknownJoinPolicyText: String?
    let muteAllLabel, muteAllDescription: String?
    let onlyAdminCanAtAllLabel, onlyAdminCanAtAllDescription: String?
    let onlyAdminCanPinLabel, onlyAdminCanPinDescription: String?
    let shareCardPermissionLabel, shareCardPermissionDescription: String?
    let onText, offText, busyText, retryText, dismissErrorText: String?
    let onChange: ((FlareGroupPermissionKey, FlareGroupPermissionValue) -> Void)?
    let onDismissError: ((FlareGroupPermissionKey) -> Void)?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    /// What this panel last asked for, per key, so "retry" resends the same
    /// intent. Not optimistic state: the rendered value stays the host's.
    @State private var lastAttempt: [FlareGroupPermissionKey: FlareGroupPermissionValue] = [:]

    public init(settings: FlareGroupPermissionSettings,
                canManage: Bool = false,
                busyKeys: [String] = [],
                errors: [String: String] = [:],
                title: String? = nil,
                readOnlyHintText: String? = nil,
                joinPolicyLabel: String? = nil,
                joinPolicyDescription: String? = nil,
                joinInviteText: String? = nil,
                joinApprovalText: String? = nil,
                joinOpenText: String? = nil,
                unknownJoinPolicyText: String? = nil,
                muteAllLabel: String? = nil,
                muteAllDescription: String? = nil,
                onlyAdminCanAtAllLabel: String? = nil,
                onlyAdminCanAtAllDescription: String? = nil,
                onlyAdminCanPinLabel: String? = nil,
                onlyAdminCanPinDescription: String? = nil,
                shareCardPermissionLabel: String? = nil,
                shareCardPermissionDescription: String? = nil,
                onText: String? = nil,
                offText: String? = nil,
                busyText: String? = nil,
                retryText: String? = nil,
                dismissErrorText: String? = nil,
                onChange: ((FlareGroupPermissionKey, FlareGroupPermissionValue) -> Void)? = nil,
                onDismissError: ((FlareGroupPermissionKey) -> Void)? = nil) {
        self.settings = settings; self.canManage = canManage; self.busyKeys = busyKeys
        self.errors = errors; self.title = title; self.readOnlyHintText = readOnlyHintText
        self.joinPolicyLabel = joinPolicyLabel; self.joinPolicyDescription = joinPolicyDescription
        self.joinInviteText = joinInviteText; self.joinApprovalText = joinApprovalText
        self.joinOpenText = joinOpenText; self.unknownJoinPolicyText = unknownJoinPolicyText
        self.muteAllLabel = muteAllLabel; self.muteAllDescription = muteAllDescription
        self.onlyAdminCanAtAllLabel = onlyAdminCanAtAllLabel
        self.onlyAdminCanAtAllDescription = onlyAdminCanAtAllDescription
        self.onlyAdminCanPinLabel = onlyAdminCanPinLabel
        self.onlyAdminCanPinDescription = onlyAdminCanPinDescription
        self.shareCardPermissionLabel = shareCardPermissionLabel
        self.shareCardPermissionDescription = shareCardPermissionDescription
        self.onText = onText; self.offText = offText; self.busyText = busyText
        self.retryText = retryText; self.dismissErrorText = dismissErrorText
        self.onChange = onChange; self.onDismissError = onDismissError
    }

    /// Editing needs both the permission and a host callback to honour it.
    var canEdit: Bool { canManage && onChange != nil }

    public func labelFor(_ key: FlareGroupPermissionKey) -> String {
        switch key {
        case .joinPolicy: return copy.joinPolicyLabel
        case .muteAll: return copy.muteAllLabel
        case .onlyAdminCanAtAll: return copy.onlyAdminCanAtAllLabel
        case .onlyAdminCanPin: return copy.onlyAdminCanPinLabel
        case .shareCardPermission: return copy.shareCardPermissionLabel
        }
    }

    public func descriptionFor(_ key: FlareGroupPermissionKey) -> String {
        switch key {
        case .joinPolicy: return copy.joinPolicyDescription
        case .muteAll: return copy.muteAllDescription
        case .onlyAdminCanAtAll: return copy.onlyAdminCanAtAllDescription
        case .onlyAdminCanPin: return copy.onlyAdminCanPinDescription
        case .shareCardPermission: return copy.shareCardPermissionDescription
        }
    }

    static func symbol(for key: FlareGroupPermissionKey) -> String {
        switch key {
        case .joinPolicy: return "lock"
        case .muteAll: return flareIconSymbol("silence")
        case .onlyAdminCanAtAll: return "at"
        case .onlyAdminCanPin: return "pin"
        case .shareCardPermission: return "square.and.arrow.up"
        }
    }

    /// The join policy choices in display order (open, approval, invite).
    var joinOptions: [(value: FlareGroupJoinPolicy, label: String)] {
        FlareGroupJoinPolicy.allCases.map { policy in
            switch policy {
            case .open: return (policy, copy.joinOpenText)
            case .approval: return (policy, copy.joinApprovalText)
            case .invite: return (policy, copy.joinInviteText)
            }
        }
    }

    /// The policy's name; an unknown (nil) policy reads the unknown-policy copy.
    public func joinPolicyText(_ value: FlareGroupJoinPolicy?) -> String {
        joinOptions.first { $0.value == value }?.label ?? copy.unknownJoinPolicyText
    }

    private func dispatch(_ row: FlareGroupPermissionRow, _ value: FlareGroupPermissionValue) {
        guard canEdit, !row.busy else { return }
        lastAttempt[row.key] = value
        onChange?(row.key, value)
    }

    /// A choice row can be retried only when we know what was attempted; its
    /// options stay live either way.
    func retryValue(_ row: FlareGroupPermissionRow) -> FlareGroupPermissionValue? {
        if let attempted = lastAttempt[row.key] { return attempted }
        return row.kind == .toggle ? .flag(!row.value.boolValue) : nil
    }

    /// Copy in effect: an explicit parameter wins, otherwise the `flareStrings` provider.
    struct Copy {
        let title, readOnlyHintText, joinPolicyLabel, joinPolicyDescription: String
        let joinInviteText, joinApprovalText, joinOpenText, unknownJoinPolicyText: String
        let muteAllLabel, muteAllDescription, onlyAdminCanAtAllLabel, onlyAdminCanAtAllDescription: String
        let onlyAdminCanPinLabel, onlyAdminCanPinDescription, shareCardPermissionLabel, shareCardPermissionDescription: String
        let onText, offText, busyText, retryText: String
        let dismissErrorText: String
    }
    func resolveCopy(_ strings: FlareStrings) -> Copy {
        Copy(
            title: title ?? strings.groupPermissionMatrixTitle,
            readOnlyHintText: readOnlyHintText ?? strings.groupPermissionMatrixReadOnlyHint,
            joinPolicyLabel: joinPolicyLabel ?? strings.groupPermissionMatrixJoinPolicy,
            joinPolicyDescription: joinPolicyDescription ?? strings.groupPermissionMatrixJoinPolicyDescription,
            joinInviteText: joinInviteText ?? strings.groupPermissionMatrixJoinInvite,
            joinApprovalText: joinApprovalText ?? strings.groupPermissionMatrixJoinApproval,
            joinOpenText: joinOpenText ?? strings.groupPermissionMatrixJoinOpen,
            unknownJoinPolicyText: unknownJoinPolicyText ?? strings.groupPermissionMatrixUnknownJoinPolicy,
            muteAllLabel: muteAllLabel ?? strings.groupPermissionMatrixMuteAll,
            muteAllDescription: muteAllDescription ?? strings.groupPermissionMatrixMuteAllDescription,
            onlyAdminCanAtAllLabel: onlyAdminCanAtAllLabel ?? strings.groupPermissionMatrixOnlyAdminCanAtAll,
            onlyAdminCanAtAllDescription: onlyAdminCanAtAllDescription ?? strings.groupPermissionMatrixOnlyAdminCanAtAllDescription,
            onlyAdminCanPinLabel: onlyAdminCanPinLabel ?? strings.groupPermissionMatrixOnlyAdminCanPin,
            onlyAdminCanPinDescription: onlyAdminCanPinDescription ?? strings.groupPermissionMatrixOnlyAdminCanPinDescription,
            shareCardPermissionLabel: shareCardPermissionLabel ?? strings.groupPermissionMatrixShareCardPermission,
            shareCardPermissionDescription: shareCardPermissionDescription ?? strings.groupPermissionMatrixShareCardPermissionDescription,
            onText: onText ?? strings.groupPermissionMatrixOn,
            offText: offText ?? strings.groupPermissionMatrixOff,
            busyText: busyText ?? strings.groupPermissionMatrixBusy,
            retryText: retryText ?? strings.retry,
            dismissErrorText: dismissErrorText ?? strings.groupPermissionMatrixDismissError
        )
    }
    private var copy: Copy { resolveCopy(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let rows = groupPermissionRows(settings, canManage: canEdit, busyKeys: busyKeys, errors: errors)
        VStack(alignment: .leading, spacing: 0) {
            head(colors)
            ForEach(Array(rows.enumerated()), id: \.element.key) { index, row in
                if index > 0 {
                    Rectangle().fill(colors.borderSecondary).frame(height: 1)
                }
                rowView(row, colors: colors)
            }
        }
        .padding(FlareSizes.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .fill(colors.bgPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                        .stroke(colors.borderPrimary, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(copy.title)
    }

    private func head(_ colors: FlareColors) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingSm) {
            Text(copy.title)
                .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                .foregroundColor(colors.textPrimary)
            Spacer(minLength: 0)
            if !canEdit {
                HStack(spacing: 4) {
                    Image(systemName: "lock").font(.system(size: 12))
                    Text(copy.readOnlyHintText).font(.system(size: FlareSizes.fontSizeSm))
                }
                .foregroundColor(colors.textTertiary)
            }
        }
        .padding(.bottom, FlareSizes.spacingSm)
    }

    @ViewBuilder
    private func rowView(_ row: FlareGroupPermissionRow, colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().fill(colors.primary.opacity(0.10)).frame(width: 32, height: 32)
                    Image(systemName: Self.symbol(for: row.key))
                        .font(.system(size: 16))
                        .foregroundColor(colors.primaryText)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(labelFor(row.key))
                        .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                        .foregroundColor(colors.textPrimary)
                    Text(descriptionFor(row.key))
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: FlareSizes.spacingSm)
                if row.busy { busyView(colors) }
                if row.kind == .toggle {
                    if row.editable {
                        switchButton(row, colors: colors)
                    } else {
                        Text(row.value.boolValue ? copy.onText : copy.offText)
                            .font(.system(size: FlareSizes.fontSizeMd))
                            .foregroundColor(colors.textSecondary)
                    }
                } else if !row.editable {
                    Text(joinPolicyText(row.value.policyValue))
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(minHeight: FlareSizes.touchTarget)

            if row.kind == .choice, row.editable {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(joinOptions, id: \.value) { option in
                            choiceButton(row, option: option, colors: colors)
                        }
                    }
                    if row.value.policyValue == nil {
                        Text(copy.unknownJoinPolicyText)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.warningText)
                    }
                }
                .padding(.leading, 44)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(labelFor(row.key))
            }

            if let error = row.error { errorView(row, message: error, colors: colors) }
        }
        .padding(.vertical, FlareSizes.spacingSm)
    }

    private func busyView(_ colors: FlareColors) -> some View {
        HStack(spacing: 5) {
            ProgressView().controlSize(.small)
            Text(copy.busyText)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(copy.busyText)
    }

    /// Hand-built track + knob rather than `SwitchView`: the value stays the
    /// host's, so a tap dispatches instead of flipping a local binding.
    private func switchButton(_ row: FlareGroupPermissionRow, colors: FlareColors) -> some View {
        let isOn = row.value.boolValue
        return Button { dispatch(row, .flag(!isOn)) } label: {
            Capsule()
                .fill(isOn ? colors.primary : colors.borderHover)
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: Color.black.opacity(0.28), radius: 3, y: 1)
                        .offset(x: isOn ? 9 : -9)
                )
                .opacity(row.busy ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(row.busy)
        .accessibilityLabel(labelFor(row.key))
        .accessibilityValue(isOn ? copy.onText : copy.offText)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    private func choiceButton(_ row: FlareGroupPermissionRow,
                              option: (value: FlareGroupJoinPolicy, label: String),
                              colors: FlareColors) -> some View {
        let selected = row.value.policyValue == option.value
        return Button { dispatch(row, .policy(option.value)) } label: {
            HStack(spacing: 5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .opacity(selected ? 1 : 0)
                Text(option.label)
                    .font(.system(size: FlareSizes.fontSizeMd,
                                  weight: selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? colors.primaryText : colors.textPrimary)
            .padding(.horizontal, FlareSizes.spacing2sm)
            .frame(minHeight: FlareSizes.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                    .fill(selected ? colors.bgSelected : colors.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                            .stroke(selected ? colors.borderSelected : colors.borderPrimary, lineWidth: 1)
                    )
            )
            .opacity(row.busy ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(row.busy)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private func errorView(_ row: FlareGroupPermissionRow, message: String,
                           colors: FlareColors) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12))
                .foregroundColor(colors.errorText)
            Text(message)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.errorText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if row.editable, !row.busy, let value = retryValue(row) {
                Button { dispatch(row, value) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                        Text(copy.retryText).font(.system(size: FlareSizes.fontSizeSm))
                    }
                    .foregroundColor(colors.textPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.retryText)
            }
            if let onDismissError {
                Button { onDismissError(row.key) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.dismissErrorText)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.error.opacity(0.08))
        )
        .padding(.leading, 44)
    }
}
