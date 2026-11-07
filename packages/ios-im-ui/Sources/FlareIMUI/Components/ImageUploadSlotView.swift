import SwiftUI

/// Controlled presentation only. Hosts retain picker bytes and own every transfer intent.
public enum FlareImageUploadState: Sendable, Equatable { case empty, uploading, uploaded, failed }

/// Rectangular image input shared by document, avatar and other image forms.
/// A preview is transient host content, never a remote-read or persistence capability.
public struct ImageUploadSlotView: View {
    private let title: String
    private let state: FlareImageUploadState
    private let statusText: String
    private let actionText: String
    private let retryText: String
    private let disabled: Bool
    private let icon: String
    private let preview: AnyView?
    private let onChoose: (() -> Void)?
    private let onRetry: (() -> Void)?
    private let previewLabel: String?
    private let previewLoading: Bool
    private let previewDisabled: Bool
    private let onPreview: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @Environment(\.flareStrings) private var strings
    @FocusState private var focused: Bool
    @ScaledMetric private var titleSize: CGFloat = FlareSizes.fontSizeMd
    @ScaledMetric private var detailSize: CGFloat = FlareSizes.fontSizeSm

    public init(title: String, state: FlareImageUploadState, statusText: String,
                actionText: String, retryText: String, disabled: Bool = false,
                icon: String = "camera", preview: AnyView? = nil,
                onChoose: (() -> Void)? = nil, onRetry: (() -> Void)? = nil,
                previewLabel: String? = nil, previewLoading: Bool = false,
                previewDisabled: Bool = false, onPreview: (() -> Void)? = nil) {
        self.title = title; self.state = state; self.statusText = statusText
        self.actionText = actionText; self.retryText = retryText; self.disabled = disabled
        self.icon = icon; self.preview = preview; self.onChoose = onChoose; self.onRetry = onRetry
        self.previewLabel = previewLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.previewLoading = previewLoading; self.previewDisabled = previewDisabled; self.onPreview = onPreview
    }

    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }
    private var previewMode: Bool { state == .uploaded && previewLabel?.isEmpty == false }
    private var tint: Color {
        switch state {
        case .uploaded: return colors.success
        case .failed: return colors.error
        default: return colors.textSecondary
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Text(title).font(.system(size: titleSize, weight: .medium))
                .foregroundColor(colors.textPrimary).lineLimit(2)
            if previewMode {
                Button { onPreview?() } label: { slot }
                    .buttonStyle(.plain).disabled(previewDisabled || previewLoading || onPreview == nil).focused($focused)
                    .accessibilityLabel(title)
                    .accessibilityValue(previewLoading ? strings.loading : statusText)
                    .accessibilityHint(previewLabel ?? "")
            } else if let onChoose, state != .uploaded && state != .uploading {
                Button(action: onChoose) { slot }
                    .buttonStyle(.plain).disabled(disabled).focused($focused)
                    .accessibilityLabel(title).accessibilityValue(statusText).accessibilityHint(actionText)
            } else {
                slot.accessibilityElement(children: .ignore)
                    .accessibilityLabel(title).accessibilityValue(statusText)
            }
            if state == .failed, let onRetry {
                ButtonView(label: retryText, variant: .text, size: .sm,
                    disabled: disabled, maintainTouchTarget: true, action: onRetry)
            }
        }
    }

    private var slot: some View {
        ZStack {
            if let preview {
                preview.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(FlareSizes.spacingSm)
            } else if state != .uploading && !previewLoading {
                VStack(spacing: FlareSizes.spacingSm) {
                    FlareIconImage(name: previewMode ? "image" : state == .uploaded ? "success" : icon, size: FlareSizes.iconSizeXl)
                        .foregroundColor(tint).accessibilityHidden(true)
                    Text(previewMode ? previewLabel ?? "" : state == .empty ? actionText : statusText)
                        .font(.system(size: detailSize)).foregroundColor(tint)
                }
            }
            if state == .uploading || previewLoading { ProgressView().tint(colors.primary).accessibilityLabel(strings.loading) }
            if preview != nil || state == .uploading || previewLoading {
                VStack { Spacer(minLength: 0)
                    Text(previewMode ? "\(statusText) · \(previewLabel ?? "")" : statusText).font(.system(size: detailSize)).foregroundColor(tint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
                        .background(colors.bgElevated)
                }
            }
        }
        .frame(maxWidth: .infinity).aspectRatio(1.6, contentMode: .fit)
        .frame(minHeight: FlareSizes.touchTarget)
        .background(colors.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
            .stroke(focused ? colors.primary : state == .failed ? colors.error : colors.borderPrimary, lineWidth: 1))
        .contentShape(Rectangle())
    }
}
