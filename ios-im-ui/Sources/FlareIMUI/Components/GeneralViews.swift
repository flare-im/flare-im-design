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
            Image(systemName: "magnifyingglass").foregroundColor(colors.textTertiary)
            TextField(placeholder, text: $text).textFieldStyle(.plain).onSubmit { onSubmit?() }
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
    private let onSubmit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(text: Binding<String>, placeholder: String = "", multiline: Bool = false,
                maxLength: Int? = nil, disabled: Bool = false, clearable: Bool = false,
                onSubmit: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.multiline = multiline
        self.maxLength = maxLength; self.disabled = disabled; self.clearable = clearable; self.onSubmit = onSubmit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                if multiline {
                    TextField(placeholder, text: $text, axis: .vertical).lineLimit(2...6)
                } else {
                    TextField(placeholder, text: $text).onSubmit { onSubmit?() }
                }
                if clearable && !text.isEmpty && !disabled {
                    Button { text = "" } label: { Image(systemName: "xmark.circle").foregroundColor(colors.textTertiary) }
                        .buttonStyle(.plain)
                }
            }
            .textFieldStyle(.plain)
            .disabled(disabled)
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingSm)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
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

/// Empty-state placeholder. Spec: General/EmptyState (`EmptyStateView`).
public struct EmptyStateView: View {
    private let title: String
    private let description: String?
    private let actionText: String?
    private let systemImage: String
    private let onAction: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(title: String, description: String? = nil, actionText: String? = nil,
                systemImage: String = "tray", onAction: (() -> Void)? = nil) {
        self.title = title; self.description = description; self.actionText = actionText
        self.systemImage = systemImage; self.onAction = onAction
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: systemImage).font(.system(size: 44)).foregroundColor(colors.textTertiary)
            Text(title).font(.system(size: FlareSizes.fontSize2xl)).foregroundColor(colors.textPrimary)
            if let description {
                Text(description).font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textTertiary).multilineTextAlignment(.center)
            }
            if let actionText {
                Button(actionText) { onAction?() }.buttonStyle(.bordered).padding(.top, FlareSizes.spacingSm)
            }
        }
        .padding(FlareSizes.spacing2xl)
    }
}
