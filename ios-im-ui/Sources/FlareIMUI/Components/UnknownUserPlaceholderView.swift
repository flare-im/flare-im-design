import SwiftUI

/// Why the host cannot show a real profile. Names match the cross-platform
/// contract (Vue `kind` prop / Flutter / Compose enums).
public enum FlareUnknownUserKind: String, CaseIterable, Sendable {
    case unknown, deactivated, blocked, unreachable
}

/// `row` inside lists, `card` on a detail surface.
public enum FlareUnknownUserDensity: String, Sendable {
    case row, card
}

/// Tone accompanies — never replaces — the icon and the title text.
public enum FlareUnknownUserTone: String, Sendable {
    case neutral, warning, danger
}

/// Icon + tone for one ``FlareUnknownUserKind``.
public struct FlareUnknownUserPresentation: Equatable, Sendable {
    public let kind: FlareUnknownUserKind
    public let tone: FlareUnknownUserTone
    public init(_ kind: FlareUnknownUserKind, tone: FlareUnknownUserTone) {
        self.kind = kind
        self.tone = tone
    }
}

/// Icon + tone for `kind`; an absent kind degrades to `.unknown` rather than
/// rendering blank, so a stale host value can never blank the row.
public func unknownUserPresentation(_ kind: FlareUnknownUserKind?) -> FlareUnknownUserPresentation {
    switch kind {
    case .deactivated: return .init(.deactivated, tone: .neutral)
    case .blocked: return .init(.blocked, tone: .danger)
    case .unreachable: return .init(.unreachable, tone: .warning)
    default: return .init(.unknown, tone: .neutral)
    }
}

/// Default budget for the diagnostic id line; long ids are middle-elided.
public let flareUnknownUserIdMaxLength = 24

/// The user id as it appears in the diagnostic slot: trimmed, and middle-elided
/// to `maxLength` characters (ellipsis included) so a 64-character id never
/// becomes the widest thing on screen. Never used as the title.
public func shortenUserId(_ userId: String?, maxLength: Int = flareUnknownUserIdMaxLength) -> String {
    let id = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let limit = maxLength < 8 ? 8 : maxLength
    let chars = Array(id)
    if chars.count <= limit { return id }
    let head = (limit - 1 + 1) / 2 // ceil((limit - 1) / 2)
    let tail = limit - 1 - head
    return String(chars[0..<head]) + "…" + String(chars[(chars.count - tail)...])
}

/// Placeholder for an account the host cannot describe: an id that resolved to
/// nothing, a deactivated account, a blocked one, or one that is simply not
/// contactable right now. Without it these rows render blank or, worse, show a
/// bare user id as the title. Pure display: no actions, no callbacks, no I/O.
/// Spec: Contacts/UnknownUserPlaceholder.
public struct UnknownUserPlaceholderView: View {
    /// The id the host failed to resolve. Diagnostic only — never the title.
    let userId: String
    let kind: FlareUnknownUserKind
    let density: FlareUnknownUserDensity
    /// Host-supplied supplement, e.g. where the id came from.
    let detail: String?
    let unknownText, deactivatedText, blockedText, unreachableText, idLabel: String
    let idMaxLength: Int

    @Environment(\.colorScheme) private var scheme

    public init(userId: String,
                kind: FlareUnknownUserKind,
                density: FlareUnknownUserDensity = .row,
                detail: String? = nil,
                unknownText: String = "未知用户",
                deactivatedText: String = "该账号已注销",
                blockedText: String = "该账号已被屏蔽",
                unreachableText: String = "暂时无法联系该账号",
                idLabel: String = "ID",
                idMaxLength: Int = flareUnknownUserIdMaxLength) {
        self.userId = userId
        self.kind = kind
        self.density = density
        self.detail = detail
        self.unknownText = unknownText
        self.deactivatedText = deactivatedText
        self.blockedText = blockedText
        self.unreachableText = unreachableText
        self.idLabel = idLabel
        self.idMaxLength = idMaxLength
    }

    /// Default title for the current kind — the heading a reader actually sees.
    public var title: String {
        switch unknownUserPresentation(kind).kind {
        case .deactivated: return deactivatedText
        case .blocked: return blockedText
        case .unreachable: return unreachableText
        case .unknown: return unknownText
        }
    }

    static func symbol(for kind: FlareUnknownUserKind) -> String {
        switch kind {
        case .unknown: return "questionmark.circle"
        case .deactivated: return "xmark.circle"
        case .blocked: return "nosign"
        case .unreachable: return "lock"
        }
    }

    /// The id is diagnostic, so it is read out after the reason, never before it.
    public var accessibilityText: String {
        let full = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let supplement = (detail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = [title]
        if !supplement.isEmpty { parts.append(supplement) }
        if !full.isEmpty { parts.append("\(idLabel) \(full)") }
        return parts.joined(separator: " · ")
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let presentation = unknownUserPresentation(kind)
        let card = density == .card
        let shortId = shortenUserId(userId, maxLength: idMaxLength)
        let supplement = (detail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let badge: Color = {
            switch presentation.tone {
            case .danger: return colors.error
            case .warning: return colors.warning
            case .neutral: return colors.textSecondary
            }
        }()

        let avatar = ZStack {
            Circle().fill(colors.bgDisabled)
            // Neutral silhouette, never an emoji.
            Image(systemName: "person")
                .font(.system(size: card ? 26 : 18))
                .foregroundColor(colors.textTertiary)
        }
        .frame(width: card ? 64 : FlareSizes.avatarSize, height: card ? 64 : FlareSizes.avatarSize)

        let details = VStack(alignment: card ? .center : .leading, spacing: 2) {
            HStack(spacing: 6) {
                ZStack {
                    Circle().fill(colors.bgDisabled).frame(width: 22, height: 22)
                    Image(systemName: Self.symbol(for: presentation.kind))
                        .font(.system(size: 12))
                        .foregroundColor(badge)
                }
                Text(title)
                    .font(.system(size: card ? FlareSizes.fontSize3xl : FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !supplement.isEmpty {
                Text(supplement)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !shortId.isEmpty {
                HStack(spacing: 5) {
                    Text(idLabel)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textTertiary)
                    // Ids stay LTR even in an RTL layout — they are opaque tokens.
                    Text(shortId)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
        .multilineTextAlignment(card ? .center : .leading)

        return Group {
            if card {
                VStack(spacing: FlareSizes.spacingSm) {
                    avatar
                    details
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, FlareSizes.spacingLg)
                .padding(.vertical, FlareSizes.spacingXl)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            } else {
                HStack(spacing: FlareSizes.spacingMd) {
                    avatar
                    details
                    Spacer(minLength: 0)
                }
                .frame(minHeight: FlareSizes.touchTarget)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}
