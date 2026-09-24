import SwiftUI

/// A member's role in the group.
public enum FlareGroupMemberRole: String, CaseIterable, Sendable {
    case owner, admin, member
}

/// Management actions a ``MemberRoleSheetView`` can emit; names match the
/// cross-platform contract (Vue `action` payload / Flutter / Compose enums).
public enum FlareMemberRoleAction: String, CaseIterable, Sendable {
    case promote, demote, mute, unmute, transferOwner, remove
}

/// The member the sheet acts on; `id` must be stable and is echoed in the callback.
public struct FlareGroupMemberSnapshot: Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let role: FlareGroupMemberRole
    public let muted: Bool

    public init(id: String, name: String, role: FlareGroupMemberRole,
                avatarURL: String? = nil, muted: Bool = false) {
        self.id = id; self.name = name; self.role = role
        self.avatarURL = avatarURL; self.muted = muted
    }
}

/// Host-declared capabilities. `false` → the action is not rendered.
public struct FlareMemberRoleCapabilities: Sendable {
    public let promote, demote, mute, unmute, remove, transferOwner: Bool
    public init(promote: Bool = false, demote: Bool = false, mute: Bool = false,
                unmute: Bool = false, remove: Bool = false, transferOwner: Bool = false) {
        self.promote = promote; self.demote = demote; self.mute = mute
        self.unmute = unmute; self.remove = remove; self.transferOwner = transferOwner
    }
}

/// One host-supplied mute duration option; the kit ships no durations of its own.
public struct FlareMemberMuteDuration: Identifiable, Sendable {
    public let id: String
    public let label: String
    public init(id: String, label: String) { self.id = id; self.label = label }
}

/// One displayable action; `danger` entries render in the trailing danger group.
public struct FlareMemberRoleActionEntry: Equatable, Sendable {
    public let action: FlareMemberRoleAction
    public let danger: Bool
    public init(_ action: FlareMemberRoleAction, danger: Bool = false) {
        self.action = action; self.danger = danger
    }
}

/// Ordered management actions for `member` as seen by `viewerRole` — the same
/// rule set as the other platforms. Rank rules come first, capabilities only
/// narrow further:
///
///  - the owner is untouchable — no promote / demote / mute / remove / transfer;
///  - a plain member sees nothing (the sheet then says it has no rights);
///  - an admin cannot act on a peer admin and can never transfer ownership;
///  - only the owner can transfer ownership;
///  - promote only applies to a member, demote only to an admin;
///  - mute / unmute are mutually exclusive by `member.muted`.
///
/// `mute` still needs host-supplied durations — a sheet with none hides the row.
public func memberRoleActions(_ member: FlareGroupMemberSnapshot,
                              viewerRole: FlareGroupMemberRole,
                              capabilities: FlareMemberRoleCapabilities) -> [FlareMemberRoleActionEntry] {
    if member.role == .owner { return [] }
    if viewerRole == .member { return [] }
    if viewerRole == .admin && member.role == .admin { return [] }
    var out: [FlareMemberRoleActionEntry] = []
    if capabilities.promote && member.role == .member { out.append(.init(.promote)) }
    if capabilities.demote && member.role == .admin { out.append(.init(.demote)) }
    if capabilities.mute && !member.muted { out.append(.init(.mute)) }
    if capabilities.unmute && member.muted { out.append(.init(.unmute)) }
    if capabilities.transferOwner && viewerRole == .owner { out.append(.init(.transferOwner, danger: true)) }
    if capabilities.remove { out.append(.init(.remove, danger: true)) }
    return out
}

/// Management menu for ONE group member: change role, mute, remove, transfer
/// ownership. Owns no positioning — place it in `.sheet` or a popover, exactly
/// like ``ConversationActionSheetView``. It only emits intent: the second
/// confirmation for remove / transferOwner is the host's job (DangerConfirm),
/// and mute durations come from the host. Spec: Contacts/MemberRoleSheet.
public struct MemberRoleSheetView: View {
    let member: FlareGroupMemberSnapshot
    let viewerRole: FlareGroupMemberRole
    let capabilities: FlareMemberRoleCapabilities
    let muteDurations: [FlareMemberMuteDuration]
    let busy: Bool
    let ownerRoleText, adminRoleText, memberRoleText, mutedText: String?
    let promoteText, demoteText, muteText, unmuteText: String?
    let removeText, transferOwnerText, dangerGroupText: String?
    let emptyText, ownerProtectedText: String?
    let onAction: ((String, FlareMemberRoleAction, String?) -> Void)?
    let onClose: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var muteOpen = false

    public init(member: FlareGroupMemberSnapshot,
                viewerRole: FlareGroupMemberRole,
                capabilities: FlareMemberRoleCapabilities = .init(),
                muteDurations: [FlareMemberMuteDuration] = [],
                busy: Bool = false,
                ownerRoleText: String? = nil,
                adminRoleText: String? = nil,
                memberRoleText: String? = nil,
                mutedText: String? = nil,
                promoteText: String? = nil,
                demoteText: String? = nil,
                muteText: String? = nil,
                unmuteText: String? = nil,
                removeText: String? = nil,
                transferOwnerText: String? = nil,
                dangerGroupText: String? = nil,
                emptyText: String? = nil,
                ownerProtectedText: String? = nil,
                onAction: ((String, FlareMemberRoleAction, String?) -> Void)? = nil,
                onClose: (() -> Void)? = nil) {
        self.member = member; self.viewerRole = viewerRole; self.capabilities = capabilities
        self.muteDurations = muteDurations; self.busy = busy
        self.ownerRoleText = ownerRoleText; self.adminRoleText = adminRoleText
        self.memberRoleText = memberRoleText; self.mutedText = mutedText
        self.promoteText = promoteText; self.demoteText = demoteText
        self.muteText = muteText; self.unmuteText = unmuteText
        self.removeText = removeText; self.transferOwnerText = transferOwnerText
        self.dangerGroupText = dangerGroupText; self.emptyText = emptyText
        self.ownerProtectedText = ownerProtectedText
        self.onAction = onAction; self.onClose = onClose
    }

    public func labelFor(_ action: FlareMemberRoleAction) -> String {
        switch action {
        case .promote: return copy.promoteText
        case .demote: return copy.demoteText
        case .mute: return copy.muteText
        case .unmute: return copy.unmuteText
        case .transferOwner: return copy.transferOwnerText
        case .remove: return copy.removeText
        }
    }

    /// One glyph per concept: promote and demote are the admin role, mute and unmute are silence (the
    /// row label says which), and neither removal nor ownership borrows sign-out or favourites.
    static func symbol(for action: FlareMemberRoleAction) -> String {
        switch action {
        case .promote, .demote: return flareIconSymbol("admin")
        case .mute, .unmute: return flareIconSymbol("silence")
        case .transferOwner: return flareIconSymbol("transfer-owner")
        case .remove: return flareIconSymbol("remove-member")
        }
    }

    /// mute needs host durations; with none supplied the row is not offered at all.
    public var visibleEntries: [FlareMemberRoleActionEntry] {
        memberRoleActions(member, viewerRole: viewerRole, capabilities: capabilities)
            .filter { $0.action != .mute || !muteDurations.isEmpty }
    }

    /// The owner is protected by rank, not by missing capabilities — say which it is.
    public var emptyReason: String { member.role == .owner ? copy.ownerProtectedText : copy.emptyText }

    var roleText: String {
        switch member.role {
        case .owner: return copy.ownerRoleText
        case .admin: return copy.adminRoleText
        case .member: return copy.memberRoleText
        }
    }

    /// Copy in effect: an explicit parameter wins, otherwise the `flareStrings` provider.
    struct Copy {
        let ownerRoleText, adminRoleText, memberRoleText, mutedText: String
        let promoteText, demoteText, muteText, unmuteText: String
        let removeText, transferOwnerText, dangerGroupText, emptyText: String
        let ownerProtectedText: String
    }
    func resolveCopy(_ strings: FlareStrings) -> Copy {
        Copy(
            ownerRoleText: ownerRoleText ?? strings.groupOwner,
            adminRoleText: adminRoleText ?? strings.groupAdmin,
            memberRoleText: memberRoleText ?? strings.memberRoleSheetMemberRole,
            mutedText: mutedText ?? strings.memberRoleSheetMuted,
            promoteText: promoteText ?? strings.memberRoleSheetPromote,
            demoteText: demoteText ?? strings.memberRoleSheetDemote,
            muteText: muteText ?? strings.memberRoleSheetMute,
            unmuteText: unmuteText ?? strings.memberRoleSheetUnmute,
            removeText: removeText ?? strings.memberRoleSheetRemove,
            transferOwnerText: transferOwnerText ?? strings.memberRoleSheetTransferOwner,
            dangerGroupText: dangerGroupText ?? strings.memberRoleSheetDangerGroup,
            emptyText: emptyText ?? strings.memberRoleSheetEmpty,
            ownerProtectedText: ownerProtectedText ?? strings.memberRoleSheetOwnerProtected
        )
    }
    private var copy: Copy { resolveCopy(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let entries = visibleEntries
        let primary = entries.filter { !$0.danger }
        let danger = entries.filter(\.danger)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            head(colors)
            if entries.isEmpty {
                Text(emptyReason)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(FlareSizes.spacingMd)
            }
            if !primary.isEmpty { group(primary, colors: colors, danger: false) }
            if !danger.isEmpty { group(danger, colors: colors, danger: true) }
        }
        .padding(.horizontal, FlareSizes.spacingSm)
        .padding(.vertical, FlareSizes.spacingXs)
        .onChange(of: member.id) { _ in muteOpen = false }
        .onChange(of: busy) { if $0 { muteOpen = false } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(member.name)
        .modifier(MemberRoleEscape(onClose: onClose))
    }

    private func head(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: member.id, displayName: member.name,
                       avatarURL: member.avatarURL, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(roleText)
                        .font(.system(size: FlareSizes.fontSizeSm,
                                      weight: member.role == .member ? .regular : .semibold))
                        .foregroundColor(member.role == .member ? colors.textSecondary : colors.primaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                                .fill(member.role == .member ? colors.bgSecondary : colors.primary.opacity(0.12))
                        )
                    if member.muted {
                        HStack(spacing: 3) {
                            Image(systemName: flareIconSymbol("silence")).font(.system(size: 11))
                            Text(copy.mutedText).font(.system(size: FlareSizes.fontSizeSm))
                        }
                        .foregroundColor(colors.warningText)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
    }

    private func group(_ entries: [FlareMemberRoleActionEntry], colors: FlareColors,
                       danger: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if danger {
                Text(copy.dangerGroupText)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.vertical, FlareSizes.spacingXs)
            }
            ForEach(entries, id: \.action) { entry in
                row(entry, colors: colors)
                if entry.action == .mute && muteOpen { durations(colors) }
            }
        }
        .padding(.vertical, FlareSizes.spacingXs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radius2xl).fill(colors.bgPrimary))
        .overlay(alignment: .top) {
            if danger { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
        }
    }

    private func durations(_ colors: FlareColors) -> some View {
        let enabled = !busy && onAction != nil
        return HStack(spacing: 6) {
            ForEach(muteDurations) { duration in
                Button { if enabled { onAction?(member.id, .mute, duration.id) } } label: {
                    Text(duration.label)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(minHeight: FlareSizes.touchTarget)
                        .background(
                            RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                .fill(colors.bgSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                        .stroke(colors.borderPrimary, lineWidth: 1)
                                )
                        )
                        .opacity(enabled ? 1 : 0.5)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .accessibilityLabel(duration.label)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 56)
        .padding(.trailing, FlareSizes.spacingMd)
        .padding(.bottom, FlareSizes.spacingSm)
    }

    private func row(_ entry: FlareMemberRoleActionEntry, colors: FlareColors) -> some View {
        let enabled = !busy && onAction != nil
        let accent = entry.danger ? colors.error : colors.primary
        let fg = enabled ? (entry.danger ? colors.errorText : colors.textPrimary) : colors.textDisabled
        let iconFg = enabled ? accent : colors.textDisabled
        let iconBg = enabled ? accent.opacity(entry.danger ? 0.12 : 0.10) : colors.bgDisabled
        let expandable = entry.action == .mute
        return Button {
            if expandable { muteOpen.toggle() } else { onAction?(member.id, entry.action, nil) }
        } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().fill(iconBg).frame(width: 44, height: 44)
                    Image(systemName: Self.symbol(for: entry.action))
                        .font(.system(size: 20))
                        .foregroundColor(iconFg)
                }
                Text(labelFor(entry.action))
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(fg)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if expandable {
                    Image(systemName: muteOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(colors.textTertiary)
                }
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingSm)
            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
        }
        .buttonStyle(MemberRoleRowStyle(highlight: colors.bgHover))
        .disabled(!enabled)
        .accessibilityLabel(labelFor(entry.action))
    }
}

/// Escape (hardware keyboard on macOS / iPad) closes the menu; a no-op elsewhere.
struct MemberRoleEscape: ViewModifier {
    let onClose: (() -> Void)?
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onExitCommand { onClose?() }
        #else
        content
        #endif
    }
}

/// Pressed / hovered / keyboard-focused rows share the neutral hover surface.
struct MemberRoleRowStyle: ButtonStyle {
    let highlight: Color
    @State private var hovered = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: FlareSizes.radiusXl)
                    .fill(configuration.isPressed || hovered ? highlight : Color.clear)
            )
            .onHover { hovered = $0 }
    }
}
