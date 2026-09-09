import SwiftUI

/// Unified search field. Spec: General/SearchBar (`SearchBarView`).
public struct SearchBarView: View {
    @Binding private var text: String
    private let placeholder: String
    private let loading: Bool
    private let onSubmit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(text: Binding<String>, placeholder: String = "搜索", loading: Bool = false, onSubmit: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.loading = loading; self.onSubmit = onSubmit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: "magnifyingglass").font(.system(size: 20)).foregroundColor(colors.textTertiary)
            TextField(placeholder, text: $text).font(.system(size: FlareSizes.fontSizeLg))
                .textFieldStyle(.plain).onSubmit { onSubmit?() }
            if loading {
                ProgressView().controlSize(.mini)
            } else if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle").foregroundColor(colors.textTertiary) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingSm)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
    }
}

/// General text input. Spec: General/Input (`InputView`).
public struct InputView: View {
    @Binding private var text: String
    private let placeholder: String
    private let multiline: Bool
    private let maxLength: Int?
    private let disabled: Bool
    private let clearable: Bool
    private let secure: Bool
    private let onSubmit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @FocusState private var focused: Bool

    public init(text: Binding<String>, placeholder: String = "", multiline: Bool = false,
                maxLength: Int? = nil, disabled: Bool = false, clearable: Bool = false,
                /// Mask the value (password entry). Forces single-line.
                secure: Bool = false,
                onSubmit: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.multiline = multiline
        self.maxLength = maxLength; self.disabled = disabled; self.clearable = clearable
        self.secure = secure; self.onSubmit = onSubmit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                // Field font is pinned to fontSizeLg (14) and the placeholder is drawn in
                // textTertiary (Android / Flutter parity); multiline starts at one line.
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: FlareSizes.fontSizeLg))
                            .foregroundColor(colors.textTertiary)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }
                    Group {
                        if secure {
                            SecureField("", text: $text).focused($focused).onSubmit { onSubmit?() }
                        } else if multiline {
                            TextField("", text: $text, axis: .vertical).lineLimit(1...6).focused($focused)
                        } else {
                            TextField("", text: $text).focused($focused).onSubmit { onSubmit?() }
                        }
                    }
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textPrimary)
                }
                if clearable && !text.isEmpty && !disabled && !secure {
                    Button { text = "" } label: { Image(systemName: "xmark.circle").foregroundColor(colors.textTertiary) }
                        .buttonStyle(.plain)
                }
            }
            .textFieldStyle(.plain)
            .disabled(disabled)
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingSm)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(focused ? colors.primary : colors.borderPrimary, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.15), value: focused)
            .onChange(of: text) { newValue in
                if let m = maxLength, newValue.count > m { text = String(newValue.prefix(m)) }
            }
            if let m = maxLength {
                Text("\(text.count)/\(m)")
                    .font(.system(size: FlareSizes.fontSizeXs))
                    .foregroundColor(text.count >= m ? colors.error : colors.textTertiary)
            }
        }
    }
}

/// Primary call-to-action button. Spec: General/Button (`PrimaryButtonView`).
/// Full-width, brand-filled pill with an optional leading icon and a built-in busy state
/// (spinner + `loadingLabel`). Used for the primary action on a screen (sign-in, submit, …).
public struct PrimaryButtonView: View {
    private let title: String
    private let loadingLabel: String
    private let systemImage: String?
    private let loading: Bool
    private let disabled: Bool
    private let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    public init(_ title: String, systemImage: String? = nil, loading: Bool = false,
                loadingLabel: String? = nil, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.systemImage = systemImage; self.loading = loading
        self.loadingLabel = loadingLabel ?? title; self.disabled = disabled; self.action = action
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Button(action: action) {
            Group {
                if loading {
                    HStack(spacing: FlareSizes.spacingSm) {
                        ProgressView().tint(.white)
                        Text(loadingLabel)
                    }
                } else if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.primary))
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading)
        .opacity(disabled ? 0.55 : 1)
    }
}

/// Compact equal-width segmented selector (分段选择器). Spec: General/SegmentedControl.
/// Mutually-exclusive `options`; the selected segment is surfaced on a raised chip.
public struct SegmentedControlView: View {
    private let options: [String]
    private let selectedIndex: Int
    private let onSelect: ((Int) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(options: [String], selectedIndex: Int, onSelect: ((Int) -> Void)? = nil) {
        self.options = options; self.selectedIndex = selectedIndex; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, label in
                let active = i == selectedIndex
                Button { onSelect?(i) } label: {
                    Text(label)
                        .font(.system(size: 14, weight: active ? .semibold : .medium))
                        .foregroundColor(active ? colors.primary : colors.textSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                .fill(active ? colors.bgPrimary : Color.clear)
                                .shadow(color: active ? Color.black.opacity(0.12) : .clear, radius: 4, y: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1))
        .animation(.easeOut(duration: 0.15), value: selectedIndex)
    }
}

/// Screen-level large-title header — the quiet top bar for a tab surface
/// (inbox / directory / me). Spec: Layout/ScreenHeader. Distinct from ChatHeaderView.
public struct ScreenHeaderView<Actions: View>: View {
    private let title: String
    private let actions: Actions
    @Environment(\.colorScheme) private var scheme

    public init(title: String, @ViewBuilder actions: () -> Actions = { EmptyView() }) {
        self.title = title; self.actions = actions()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 12) {
            Text(title).font(.system(size: 24, weight: .bold)).foregroundColor(colors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            actions
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
    }
}

/// Visual tone for `EmptyStateView`.
/// - `normal`: the default look (tertiary icon/spinner, primary title).
/// - `error`: surfaces a failure — the default icon (and loading spinner) and the title use the
///   danger/error color. A caller-provided custom `systemImage` is still rendered but recolored to
///   the error tint; the description stays tertiary but wraps long raw error strings.
public enum EmptyStateTone { case normal, error }

/// Empty-state placeholder. Spec: General/EmptyState (`EmptyStateView`).
///
/// Optional rich variants (all backward-compatible):
/// - `loading`: render a brand spinner in place of the icon (title/description/action still show).
/// - `onTap`: make the WHOLE placeholder tappable (distinct from the action button — the action
///   button consumes its own taps so it doesn't double-fire).
/// - `tone`: `.normal` (default) or `.error` (danger-colored icon/spinner + title, long-error wrap).
public struct EmptyStateView: View {
    private let title: String
    private let description: String?
    private let actionText: String?
    private let systemImage: String
    private let loading: Bool
    private let tone: EmptyStateTone
    private let onAction: (() -> Void)?
    private let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(title: String, description: String? = nil, actionText: String? = nil,
                systemImage: String = "tray", loading: Bool = false,
                tone: EmptyStateTone = .normal,
                onAction: (() -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.title = title; self.description = description; self.actionText = actionText
        self.systemImage = systemImage; self.loading = loading; self.tone = tone
        self.onAction = onAction; self.onTap = onTap
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let isError = tone == .error
        let accent = isError ? colors.error : colors.textTertiary
        VStack(spacing: FlareSizes.spacingSm) {
            if loading {
                ProgressView().controlSize(.large)
                    .tint(isError ? colors.error : colors.primary).frame(height: 44)
            } else {
                Image(systemName: systemImage).font(.system(size: 44)).foregroundColor(accent)
            }
            Text(title).font(.system(size: FlareSizes.fontSize2xl))
                .foregroundColor(isError ? colors.error : colors.textPrimary)
            if let description {
                Text(description).font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionText {
                // Outlined primary action (Android / Flutter parity), not the platform bordered style.
                Button { onAction?() } label: {
                    Text(actionText)
                        .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                        .foregroundColor(colors.primary)
                        .padding(.horizontal, 18)
                        .frame(height: 36)
                        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.primary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, FlareSizes.spacingSm)
            }
        }
        .padding(FlareSizes.spacing2xl)
        .contentShape(Rectangle())
        .modifier(TapPlaceholderModifier(onTap: onTap))
    }
}

/// Applies a whole-placeholder tap gesture only when `onTap` is provided, leaving the
/// default (non-interactive) placeholder untouched otherwise.
private struct TapPlaceholderModifier: ViewModifier {
    let onTap: (() -> Void)?
    func body(content: Content) -> some View {
        if let onTap {
            content.onTapGesture { onTap() }
        } else {
            content
        }
    }
}
