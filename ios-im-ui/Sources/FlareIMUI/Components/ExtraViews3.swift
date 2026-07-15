import SwiftUI

// MARK: - ForwardPicker

/// Forward picker — searchable chat list with single / multi-select + send.
/// Spec: Message/ForwardPicker (`ForwardPickerView`).
public struct ForwardPickerView: View {
    private let targets: [ForwardTarget]
    private let multiple: Bool
    private let dismissible: Bool
    private let onConfirm: (([String]) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var query: String = ""
    @State private var selected: Set<String> = []

    public init(targets: [ForwardTarget], multiple: Bool = true, dismissible: Bool = true,
                onConfirm: (([String]) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.targets = targets; self.multiple = multiple; self.dismissible = dismissible
        self.onConfirm = onConfirm; self.onClose = onClose
    }

    private var filtered: [ForwardTarget] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return targets }
        return targets.filter {
            $0.name.lowercased().contains(q) || ($0.subtitle?.lowercased().contains(q) ?? false)
        }
    }

    private func toggle(_ id: String) {
        if multiple {
            if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        } else {
            selected = selected.contains(id) ? [] : [id]
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Text("Forward to").font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if dismissible {
                    Button { onClose?() } label: {
                        Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)

            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                TextField("Search chats", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, FlareSizes.spacingMd).frame(height: 38)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .padding(.horizontal, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered) { t in row(colors, t) }
                }
            }
            .frame(maxHeight: 300)

            Divider().overlay(colors.borderPrimary)

            HStack(spacing: FlareSizes.spacingMd) {
                Text("\(selected.count) selected").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                Spacer()
                Button { onConfirm?(Array(selected)) } label: {
                    Text("Send").font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, FlareSizes.spacingLg).frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(
                                LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }
                .buttonStyle(.plain)
                .disabled(selected.isEmpty)
                .opacity(selected.isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        }
        .frame(width: 340)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func row(_ colors: FlareColors, _ t: ForwardTarget) -> some View {
        let isSel = selected.contains(t.id)
        return Button { toggle(t.id) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().stroke(colors.borderHover, lineWidth: 1).frame(width: 20, height: 20)
                    if isSel {
                        Circle().fill(colors.primary).frame(width: 20, height: 20)
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    }
                }
                AvatarView(userId: t.id, displayName: t.name, avatarURL: t.avatarURL, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let sub = t.subtitle, !sub.isEmpty {
                        Text(sub).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
            .background(isSel ? colors.bgSelected : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toast

/// Toast — transient pill with variant icon + optional action.
/// Spec: General/Toast (`ToastView`).
public enum ToastVariant: Sendable { case info, success, error, warning, loading }

public struct ToastView: View {
    private let message: String
    private let variant: ToastVariant
    private let actionLabel: String?
    private let onAction: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var animating = false

    public init(message: String, variant: ToastVariant = .info,
                actionLabel: String? = nil, onAction: (() -> Void)? = nil) {
        self.message = message; self.variant = variant
        self.actionLabel = actionLabel; self.onAction = onAction
    }

    private var icon: String {
        switch variant {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .loading: return "arrow.triangle.2.circlepath"
        }
    }

    private func tint(_ colors: FlareColors) -> Color {
        switch variant {
        case .info: return colors.primary
        case .success: return colors.success
        case .error: return colors.error
        case .warning: return colors.warning
        case .loading: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingMd) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(tint(colors))
                .rotationEffect(.degrees(variant == .loading && animating ? 360 : 0))
                .animation(variant == .loading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: animating)
            Text(message).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            if let label = actionLabel {
                Button { onAction?() } label: {
                    Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.primary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 14)
        .frame(maxWidth: 420)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.14), radius: 18, y: 6)
        .onAppear { if variant == .loading { animating = true } }
    }
}

// MARK: - CallDock

/// Minimized call dock — capsule pill to return to an ongoing call.
/// Spec: Call/CallDock (`CallDockView`).
public struct CallDockView: View {
    private let title: String
    private let avatarURL: String?
    private let durationLabel: String?
    private let mode: FlareCallMode
    private let muted: Bool
    private let onExpand: (() -> Void)?
    private let onToggleMute: (() -> Void)?
    private let onHangup: (() -> Void)?
    @State private var pulsing = false

    public init(title: String, avatarURL: String? = nil, durationLabel: String? = nil,
                mode: FlareCallMode = .audio, muted: Bool = false,
                onExpand: (() -> Void)? = nil, onToggleMute: (() -> Void)? = nil, onHangup: (() -> Void)? = nil) {
        self.title = title; self.avatarURL = avatarURL; self.durationLabel = durationLabel
        self.mode = mode; self.muted = muted
        self.onExpand = onExpand; self.onToggleMute = onToggleMute; self.onHangup = onHangup
    }

    public var body: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            Button { onExpand?() } label: {
                HStack(spacing: FlareSizes.spacingMd) {
                    ZStack {
                        AvatarView(userId: title, displayName: title, avatarURL: avatarURL, size: 34)
                        Circle().stroke(Color(.sRGB, red: 0.204, green: 0.82, blue: 0.498, opacity: 1), lineWidth: 2)
                            .frame(width: 34, height: 34)
                            .scaleEffect(pulsing ? 1.18 : 1)
                            .opacity(pulsing ? 0 : 0.9)
                            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulsing)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            .lineLimit(1).frame(maxWidth: 120, alignment: .leading)
                        HStack(spacing: 4) {
                            Image(systemName: mode == .video ? "video" : "phone").font(.system(size: 12))
                            Text(durationLabel ?? "Connected").font(.system(size: 12))
                        }.foregroundColor(.white.opacity(0.66))
                    }
                    Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            Button { onToggleMute?() } label: {
                Image(systemName: muted ? "mic.slash.fill" : "mic.fill").font(.system(size: 14))
                    .foregroundColor(muted ? Color(.sRGB, red: 0.098, green: 0.075, blue: 0.125, opacity: 1) : .white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(muted ? Color.white : Color.white.opacity(0.14)))
            }.buttonStyle(.plain)

            Button { onHangup?() } label: {
                Image(systemName: "phone.fill").font(.system(size: 14)).foregroundColor(.white)
                    .rotationEffect(.degrees(135))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(FlareColors.of(.dark).error))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 8)
        .background(
            Capsule().fill(
                LinearGradient(colors: [Color(.sRGB, red: 0.165, green: 0.141, blue: 0.220, opacity: 1),
                                        Color(.sRGB, red: 0.098, green: 0.075, blue: 0.125, opacity: 1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: Color.black.opacity(0.28), radius: 20, y: 8)
        .onAppear { pulsing = true }
    }
}

// MARK: - AnnouncementBanner

/// Announcement banner — group notice with expand / collapse + dismiss.
/// Spec: Chat/AnnouncementBanner (`AnnouncementBannerView`).
public struct AnnouncementBannerView: View {
    private let text: String
    private let author: String?
    private let collapsible: Bool
    private let dismissible: Bool
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var expanded = false

    public init(text: String, author: String? = nil, collapsible: Bool = true,
                dismissible: Bool = false, onClose: (() -> Void)? = nil) {
        self.text = text; self.author = author; self.collapsible = collapsible
        self.dismissible = dismissible; self.onClose = onClose
    }

    private var canToggle: Bool { collapsible && text.count > 40 }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            Image(systemName: "megaphone.fill").font(.system(size: 13)).foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 8).fill(
                    LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text("Announcement").font(.system(size: 12, weight: .semibold)).foregroundColor(colors.primary)
                    if let a = author, !a.isEmpty {
                        Text(" · \(a)").font(.system(size: 12)).foregroundColor(colors.textTertiary)
                    }
                }
                Text(text).font(.system(size: 13)).foregroundColor(colors.textPrimary)
                    .lineLimit(canToggle && !expanded ? 1 : nil)
                if canToggle {
                    Button { expanded.toggle() } label: {
                        HStack(spacing: 3) {
                            Text(expanded ? "Collapse" : "Expand").font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                            Image(systemName: "chevron.down").font(.system(size: 10))
                                .rotationEffect(.degrees(expanded ? 180 : 0))
                        }.foregroundColor(colors.primary)
                    }.buttonStyle(.plain)
                }
            }

            if dismissible {
                Button { onClose?() } label: {
                    Image(systemName: "xmark").font(.system(size: 13)).foregroundColor(colors.textTertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSelected)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.primary.opacity(0.22), lineWidth: 1)))
    }
}

// MARK: - DatePill

/// Date pill — centered floating day separator chip.
/// Spec: Message/DatePill (`DatePillView`).
public struct DatePillView: View {
    private let label: String
    private let floating: Bool
    @Environment(\.colorScheme) private var scheme

    public init(label: String, floating: Bool = false) {
        self.label = label; self.floating = floating
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack {
            Spacer()
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colors.textSecondary)
                .padding(.vertical, 3).padding(.horizontal, 12)
                .background(Capsule().fill(colors.bgPrimary.opacity(0.78))
                    .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1)))
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
            Spacer()
        }
    }
}
