import SwiftUI

/// How a ``SearchBarView`` takes part in interaction.
enum SearchBarRole: Equatable {
    /// A live text field with a clear button.
    case field
    /// Read-only with `onActivate`: the whole bar is one button that opens search.
    case entry
    /// Read-only without a handler: display only, no control.
    case display
}

/// Unified search field. Spec: General/SearchBar (`SearchBarView`).
public struct SearchBarView: View {
    @Binding private var text: String
    private let placeholder: String?
    private let loading: Bool
    private let readOnly: Bool
    private let onSubmit: (() -> Void)?
    private let onActivate: (() -> Void)?
    @ScaledMetric private var fieldSize: CGFloat = FlareSizes.fontSizeLg
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - readOnly: An entry that opens search instead of taking input: the same bar (icon plus
    ///     the value or placeholder) with no caret, focus or clear button.
    ///   - onActivate: With `readOnly`, the whole bar is one button (labelled with the placeholder
    ///     or "Search") that calls this on tap, Return or Space. Without it the bar is display only.
    public init(text: Binding<String>, placeholder: String? = nil, loading: Bool = false,
                readOnly: Bool = false, onSubmit: (() -> Void)? = nil, onActivate: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.loading = loading
        self.readOnly = readOnly; self.onSubmit = onSubmit; self.onActivate = onActivate
    }

    static func role(readOnly: Bool, onActivate: (() -> Void)?) -> SearchBarRole {
        guard readOnly else { return .field }
        return onActivate == nil ? .display : .entry
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        switch Self.role(readOnly: readOnly, onActivate: onActivate) {
        case .field:
            bar(colors) {
                TextField(placeholder ?? strings.search, text: $text).font(.system(size: fieldSize))
                    .frame(minHeight: 48)
                    .textFieldStyle(.plain).onSubmit { onSubmit?() }
                if loading {
                    ProgressView().controlSize(.mini)
                } else if !text.isEmpty {
                    Button { text = "" } label: { Image(systemName: "xmark.circle").foregroundColor(colors.textTertiary).frame(width: 48, height: 48) }
                        .buttonStyle(.plain).accessibilityLabel(strings.clearSearch)
                }
            }
        case .entry:
            Button { onActivate?() } label: { readOnlyBar(colors).contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(placeholder ?? strings.search)
                .accessibilityValue(text)
                .accessibilityAddTraits(.isButton)
        case .display:
            readOnlyBar(colors).accessibilityElement(children: .combine)
        }
    }

    /// Icon plus the value, or the placeholder in the tertiary tone.
    private func readOnlyBar(_ colors: FlareColors) -> some View {
        bar(colors) {
            Text(text.isEmpty ? (placeholder ?? strings.search) : text)
                .font(.system(size: fieldSize))
                .foregroundColor(text.isEmpty ? colors.textTertiary : colors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading)
            if loading { ProgressView().controlSize(.mini) }
        }
    }

    private func bar<Field: View>(_ colors: FlareColors, @ViewBuilder field: () -> Field) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: "magnifyingglass").font(.system(size: 20)).foregroundColor(colors.textTertiary)
            field()
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
    private let revealable: Bool
    private let onSubmit: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var fieldSize: CGFloat = FlareSizes.fontSizeLg
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @FocusState private var focused: Bool
    /// Unmasking is the person's own, momentary choice: it lives in the field and is never reported.
    @State private var revealed = false

    public init(text: Binding<String>, placeholder: String = "", multiline: Bool = false,
                maxLength: Int? = nil, disabled: Bool = false, clearable: Bool = false,
                /// Mask the value (password entry). Forces single-line.
                secure: Bool = false,
                /// A secure field the person can unmask: the field draws the reveal key itself, named by the kit.
                revealable: Bool = false,
                onSubmit: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.multiline = multiline
        self.maxLength = maxLength; self.disabled = disabled; self.clearable = clearable
        self.secure = secure; self.revealable = revealable; self.onSubmit = onSubmit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                // Field font is pinned to fontSizeLg (14) and the placeholder is drawn in
                // textTertiary (Android / Flutter parity); multiline starts at one line.
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: fieldSize))
                            .foregroundColor(colors.textTertiary)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                    }
                    Group {
                        if secure && !revealed {
                            SecureField("", text: $text).focused($focused).onSubmit { onSubmit?() }
                        } else if multiline {
                            TextField("", text: $text, axis: .vertical).lineLimit(1...6).focused($focused)
                        } else {
                            TextField("", text: $text).focused($focused).onSubmit { onSubmit?() }
                        }
                    }
                    .font(.system(size: fieldSize))
                    .foregroundColor(colors.textPrimary)
                }
                // Both field keys are icon-only controls, so each reserves a full touch target (FR-077);
                // only one is ever drawn, since a masked field is not clearable.
                if clearable && !text.isEmpty && !disabled && !secure {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle").foregroundColor(colors.textTertiary)
                            .flareTouchTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strings.clear)
                }
                if secure && revealable && !multiline && !disabled {
                    Button { revealed.toggle() } label: {
                        Image(systemName: flareIconSymbol(revealed ? "eye-off" : "eye")).foregroundColor(colors.textTertiary)
                            .flareTouchTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(revealed ? strings.inputHide : strings.inputReveal)
                    .accessibilityAddTraits(revealed ? .isSelected : [])
                }
            }
            .textFieldStyle(.plain)
            .disabled(disabled)
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingSm)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(focused ? colors.borderSelected : colors.borderPrimary, lineWidth: 1)
                    // The border is decoration drawn over the row: without this it takes the taps
                    // meant for the keys inside it (FR-150).
                    .allowsHitTesting(false)
            )
            .animation(.easeOut(duration: 0.15), value: focused)
            .onChange(of: text) { newValue in
                if let m = maxLength, newValue.count > m { text = String(newValue.prefix(m)) }
            }
            if let m = maxLength {
                Text("\(text.count)/\(m)")
                    .font(.system(size: FlareSizes.fontSizeXs))
                    .foregroundColor(text.count >= m ? colors.errorText : colors.textTertiary)
            }
        }
    }
}

/// Compact equal-width segmented selector (分段选择器). Spec: General/SegmentedControl.
/// Mutually-exclusive `options`; the selected segment is surfaced on a raised chip.
public struct SegmentedControlView: View {
    private let options: [String]
    private let selectedIndex: Int
    private let onSelect: ((Int) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(options: [String], selectedIndex: Int, onSelect: ((Int) -> Void)? = nil) {
        self.options = options; self.selectedIndex = selectedIndex; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, label in
                let active = i == selectedIndex
                Button { onSelect?(i) } label: {
                    Text(label)
                        .font(.system(size: 14, weight: active ? .semibold : .medium))
                        .foregroundColor(active ? colors.primaryText : colors.textSecondary)
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
public struct ScreenHeaderView<Leading: View, Actions: View>: View {
    private let title: String
    private let leading: Leading
    private let actions: Actions
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// - Parameters:
    ///   - leading: What the screen is reached through — back, a profile avatar, a picker — before
    ///     the title. An omitted one takes no room.
    ///   - actions: Trailing controls. Declared last so a bare trailing closure still means actions.
    public init(title: String,
                @ViewBuilder leading: () -> Leading = { EmptyView() },
                @ViewBuilder actions: () -> Actions = { EmptyView() }) {
        self.title = title; self.leading = leading(); self.actions = actions()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: 12) {
            leading
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
    /// Semantic kit icon name (``flareIconNames``); an unknown name draws the registry's fallback glyph.
    private let icon: String
    private let loading: Bool
    private let tone: EmptyStateTone
    private let onAction: (() -> Void)?
    private let onTap: (() -> Void)?
    /// Host controls under the text — what to do about the screen being empty. The kit owns the row
    /// (centred, one gap); the host owns the controls. `actionText` stays the one-button shorthand.
    private let actions: AnyView?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(title: String, description: String? = nil, actionText: String? = nil,
                icon: String = "folder", loading: Bool = false,
                tone: EmptyStateTone = .normal,
                actions: AnyView? = nil,
                onAction: (() -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.title = title; self.description = description; self.actionText = actionText
        self.icon = icon; self.loading = loading; self.tone = tone; self.actions = actions
        self.onAction = onAction; self.onTap = onTap
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let isError = tone == .error
        let accent = isError ? colors.error : colors.textTertiary
        VStack(spacing: FlareSizes.spacingSm) {
            if loading {
                ProgressView().controlSize(.large)
                    .tint(isError ? colors.errorText : colors.primaryText).frame(height: 44)
            } else {
                Image(systemName: flareIconSymbol(icon)).font(.system(size: 44)).foregroundColor(accent)
            }
            Text(title).font(.system(size: FlareSizes.fontSize2xl))
                .foregroundColor(isError ? colors.errorText : colors.textPrimary)
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
                        .foregroundColor(colors.primaryText)
                        .padding(.horizontal, 18)
                        .frame(height: 36)
                        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.primary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, FlareSizes.spacingSm)
            }
            if let actions {
                HStack(spacing: FlareSizes.spacingSm) { actions }
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
