import SwiftUI

// MARK: - TypingIndicator

/// Typing indicator — bouncing dots, single / multi-typer copy.
/// Spec: Message/TypingIndicator (`TypingIndicatorView`).
public enum TypingVariant: Sendable { case bubble, inline }

public struct TypingIndicatorView: View {
    private let names: [String]
    private let userId: String?
    private let avatarURL: String?
    private let variant: TypingVariant
    @Environment(\.colorScheme) private var scheme
    @State private var animating = false

    public init(names: [String] = [], userId: String? = nil, avatarURL: String? = nil,
                variant: TypingVariant = .bubble) {
        self.names = names; self.userId = userId; self.avatarURL = avatarURL; self.variant = variant
    }

    private var label: String {
        let n = names.filter { !$0.isEmpty }
        if n.isEmpty { return "正在输入…" }
        if n.count == 1 { return "\(n[0]) 正在输入…" }
        return "\(n.count) 人正在输入…"
    }

    private func dots(_ colors: FlareColors) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill((variant == .bubble ? colors.primary.opacity(0.65) : colors.textTertiary))
                    .frame(width: 6, height: 6)
                    .offset(y: animating ? -4 : 0)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15), value: animating)
            }
        }
        .onAppear { animating = true }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let body = HStack(spacing: 8) {
            if variant == .inline || !names.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
            }
            dots(colors)
        }
        .padding(variant == .bubble ? EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14) : EdgeInsets())
        .background(
            variant == .bubble
                ? AnyView(RoundedRectangle(cornerRadius: 16).fill(colors.bgPrimary)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.borderPrimary, lineWidth: 1)))
                : AnyView(Color.clear)
        )

        if variant == .inline {
            body
        } else {
            HStack(alignment: .bottom, spacing: FlareSizes.spacingSm) {
                AvatarView(userId: names.first ?? (userId ?? "typing"),
                           displayName: names.first ?? (userId ?? "typing"), avatarURL: avatarURL, size: 32)
                body
            }
        }
    }
}

// MARK: - UnreadDivider

/// Unread divider — the "N new messages" line. Spec: Message/UnreadDivider.
public struct UnreadDividerView: View {
    private let count: Int
    @Environment(\.colorScheme) private var scheme
    public init(count: Int = 0) { self.count = count }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let text = count > 0 ? "\(count) 条新消息" : "新消息"
        HStack(spacing: FlareSizes.spacingMd) {
            Rectangle().fill(colors.primary.opacity(0.24)).frame(height: 1)
            Text(text).font(.system(size: FlareSizes.fontSizeSm, weight: .medium)).foregroundColor(colors.primary)
            Rectangle().fill(colors.primary.opacity(0.24)).frame(height: 1)
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
    }
}

// MARK: - ScrollToLatest

/// Scroll-to-latest pill — floating back-to-bottom + unread badge.
public struct ScrollToLatestView: View {
    private let count: Int
    private let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    public init(count: Int = 0, onTap: (() -> Void)? = nil) { self.count = count; self.onTap = onTap }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Button { onTap?() } label: {
            HStack(spacing: 6) {
                if count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: FlareSizes.fontSizeMd, weight: .semibold)).foregroundColor(colors.primary)
                }
                Image(systemName: "arrow.down").font(.system(size: 20)).foregroundColor(.white)
                    .frame(width: 30, height: 30).background(Circle().fill(colors.primary))
            }
            .padding(.leading, count > 0 ? 12 : 8).padding(.trailing, 6).padding(.vertical, 6)
            .background(Capsule().fill(colors.bgPrimary))
            .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ProfileCard

/// Mini profile card — avatar popover + message / voice / video.
/// Spec: Profile/ProfileCard (`ProfileCardView`).
public struct ProfileCardView: View {
    private let user: Contact
    private let onMessage: (() -> Void)?
    private let onCall: (() -> Void)?
    private let onVideo: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(user: Contact, onMessage: (() -> Void)? = nil, onCall: (() -> Void)? = nil, onVideo: (() -> Void)? = nil) {
        self.user = user; self.onMessage = onMessage; self.onCall = onCall; self.onVideo = onVideo
    }

    private var meta: String {
        var parts = ["Flare ID · \(user.id)"]
        if let r = user.region, !r.isEmpty { parts.append(r) }
        return parts.joined(separator: " · ")
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: user.id, displayName: user.name, avatarURL: user.avatarURL, size: 56, presence: user.presence)
                Text(user.name).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
            }
            if let s = user.signature, !s.isEmpty {
                Text(s).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textSecondary).padding(.top, FlareSizes.spacingMd)
            }
            Text(meta).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1).padding(.top, FlareSizes.spacingSm)
            if !user.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(user.tags, id: \.self) { t in
                        Text(t).font(.system(size: FlareSizes.fontSizeXs)).foregroundColor(colors.primary)
                            .padding(.horizontal, 9).padding(.vertical, 2)
                            .background(Capsule().fill(colors.bgSelected))
                    }
                }.padding(.top, 10)
            }
            HStack(spacing: FlareSizes.spacingSm) {
                action(colors, "message", "发消息", onMessage, primary: true)
                action(colors, "phone", nil, onCall)
                action(colors, "video", nil, onVideo)
            }.padding(.top, FlareSizes.spacingLg)
        }
        .padding(FlareSizes.spacingLg)
        .frame(width: 260)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func action(_ colors: FlareColors, _ icon: String, _ label: String?, _ onTap: (() -> Void)?, primary: Bool = false) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 17))
                if let label { Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)) }
            }
            .foregroundColor(primary ? .white : colors.textPrimary)
            .frame(maxWidth: primary ? .infinity : 44, minHeight: 38)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(primary ? colors.primary : colors.bgSecondary))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GroupMemberGrid

/// Group member grid — avatars + owner / admin badges + add-member tile.
/// Spec: Contacts/GroupMemberGrid (`GroupMemberGridView`).
public struct GroupMemberGridView: View {
    private let members: [Contact]
    private let ownerId: String?
    private let adminIds: [String]
    private let showAdd: Bool
    private let columns: Int
    private let onSelect: ((String) -> Void)?
    private let onAddMember: (() -> Void)?
    private let title: String
    private let ownerLabel: String
    private let adminLabel: String
    private let addLabel: String
    private let memberCountText: (Int) -> String
    @Environment(\.colorScheme) private var scheme

    public init(members: [Contact], ownerId: String? = nil, adminIds: [String] = [], showAdd: Bool = true,
                columns: Int = 5, onSelect: ((String) -> Void)? = nil, onAddMember: (() -> Void)? = nil,
                title: String = "群成员", ownerLabel: String = "群主", adminLabel: String = "管理员",
                addLabel: String = "加成员", memberCountText: @escaping (Int) -> String = { "\($0) 名成员" }) {
        self.members = members; self.ownerId = ownerId; self.adminIds = adminIds; self.showAdd = showAdd
        self.columns = columns; self.onSelect = onSelect; self.onAddMember = onAddMember
        self.title = title; self.ownerLabel = ownerLabel; self.adminLabel = adminLabel
        self.addLabel = addLabel; self.memberCountText = memberCountText
    }

    private func role(_ m: Contact) -> String? {
        if m.id == ownerId { return ownerLabel }
        if adminIds.contains(m.id) { return adminLabel }
        return nil
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                Text(memberCountText(members.count)).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
            }
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(members) { m in cell(colors, m) }
                if showAdd { addCell(colors) }
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func cell(_ colors: FlareColors, _ m: Contact) -> some View {
        Button { onSelect?(m.id) } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottom) {
                    AvatarView(userId: m.id, displayName: m.name, avatarURL: m.avatarURL, size: 48)
                    if let r = role(m) {
                        Text(r).font(.system(size: 10)).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(m.id == ownerId ? colors.warning : colors.textTertiary))
                            .offset(y: 6)
                    }
                }
                Text(m.name).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func addCell(_ colors: FlareColors) -> some View {
        Button { onAddMember?() } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 22)).foregroundColor(colors.textTertiary)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(colors.borderHover, style: StrokeStyle(lineWidth: 1, dash: [4])))
                Text(addLabel).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GroupCallView

/// Group (multi-party) call — participant grid + controls.
/// Spec: Call/GroupCallView (`GroupCallView`).
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

    public init(participants: [CallParticipant], mode: FlareCallMode, state: FlareCallState,
                title: String? = nil, durationLabel: String? = nil, muted: Bool = false, cameraOn: Bool = true,
                speakerOn: Bool = false, onHangup: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil,
                onToggleCamera: (() -> Void)? = nil, onToggleSpeaker: (() -> Void)? = nil,
                onSwitchCamera: (() -> Void)? = nil, onMinimize: (() -> Void)? = nil) {
        self.participants = participants; self.mode = mode; self.state = state; self.title = title
        self.durationLabel = durationLabel; self.muted = muted; self.cameraOn = cameraOn; self.speakerOn = speakerOn
        self.onHangup = onHangup; self.onToggleMute = onToggleMute; self.onToggleCamera = onToggleCamera
        self.onToggleSpeaker = onToggleSpeaker; self.onSwitchCamera = onSwitchCamera; self.onMinimize = onMinimize
    }

    private var cols: Int {
        let n = participants.count
        if n <= 1 { return 1 }; if n <= 4 { return 2 }; if n <= 9 { return 3 }; return 4
    }
    private var statusText: String {
        if state == .connected { return durationLabel ?? "已接通" }
        if state == .ringing { return "响铃中…" }
        return "呼叫中…"
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { onMinimize?() } label: {
                    Image(systemName: "chevron.down").font(.system(size: 20)).foregroundColor(.white)
                        .frame(width: 36, height: 36).background(Circle().fill(Color.white.opacity(0.12)))
                }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? "群通话").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text("\(participants.count) 人已加入 · \(statusText)").font(.system(size: 12)).foregroundColor(.white.opacity(0.62))
                }
                Spacer()
            }.padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)

            let grid = Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
            ScrollView {
                LazyVGrid(columns: grid, spacing: 8) {
                    ForEach(participants) { p in tile(p) }
                }.padding(.horizontal, 12).padding(.top, 4)
            }

            CallControlsView(muted: muted, cameraOn: cameraOn, speakerOn: speakerOn, mode: mode,
                             onToggleMute: onToggleMute, onToggleCamera: onToggleCamera,
                             onToggleSpeaker: onToggleSpeaker, onSwitchCamera: onSwitchCamera, onHangup: onHangup)
                .padding(.vertical, 20).padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(.sRGB, red: 0.129, green: 0.114, blue: 0.188, opacity: 1),
                                    Color(.sRGB, red: 0.09, green: 0.075, blue: 0.122, opacity: 1),
                                    Color(.sRGB, red: 0.063, green: 0.047, blue: 0.09, opacity: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func tile(_ p: CallParticipant) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(p.isSelf ? Color(.sRGB, red: 0.486, green: 0.227, blue: 0.929, opacity: 0.16) : Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(p.speaking ? Color(.sRGB, red: 0.204, green: 0.82, blue: 0.498, opacity: 1) : .clear, lineWidth: 2))
                .aspectRatio(0.86, contentMode: .fit)
            AvatarView(userId: p.id, displayName: p.name, avatarURL: p.avatarURL, size: 56)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 5) {
                if p.muted {
                    Image(systemName: "mic.slash.fill").font(.system(size: 10)).foregroundColor(.white)
                        .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
                } else if p.cameraOff && mode == .video {
                    Image(systemName: "video.slash.fill").font(.system(size: 10)).foregroundColor(.white)
                        .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
                }
                Text(p.isSelf ? "\(p.name)（我）" : p.name).font(.system(size: 12)).foregroundColor(.white).lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.42)))
            }.padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
