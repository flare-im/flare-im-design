import SwiftUI

/// What a document slot shows. Spec: DocumentSlot `state`.
public enum FlareDocumentSlotState: Equatable, Sendable {
    /// Nothing taken yet: the side's outline and "tap to take a photo".
    case empty
    /// The photo is there: a success badge and "retake".
    case captured
    /// The photo is uploading: progress 0–100 over it.
    case uploading(Double)
    /// The upload failed: an error border and "tap to try again".
    case failed
}

/// One capture tile for an ID photo (front, back, holding). Spec: DocumentSlot (`FlareDocumentSlot`),
/// docs/plugin-experience.md §6.3.
///
/// - Sized by the grid: as wide as its cell, 16:10 and never under ``FlareSizes/componentDocumentSlotHeight``
///   (taller still when larger text needs it).
/// - Empty: `bgSecondary` with a 1.5 dashed `borderPrimary` outline, the side's ID outline, the camera, `label` and
///   "点击拍摄". Captured: `image` covers the tile with a success badge and a "重拍" strip. Uploading: `image` under a
///   progress ring and percent. Failed: an error border and "上传失败，点按重试".
/// - A tap on an empty or captured slot calls `onCapture` (take, retake: the host opens ``FlareDocumentCapture``); on
///   a failed one `onRetry` (the host uploads again).
/// - VoiceOver reads one button: `label`, the state ("已拍摄") and, once taken, "重拍" as the hint.
public struct FlareDocumentSlot: View {
    private let side: FlareDocumentSide
    private let label: String
    private let state: FlareDocumentSlotState
    private let image: Image?
    private let imageUrl: URL?
    private let disabled: Bool
    private let onCapture: (() -> Void)?
    private let onRetry: (() -> Void)?
    @ScaledMetric(relativeTo: .subheadline) private var labelSize = FlareSizes.fontSizeLg
    @ScaledMetric(relativeTo: .caption) private var captionSize = FlareSizes.fontSizeSm
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - image: The photo, for captured, uploading and failed.
    ///   - imageUrl: The photo's address when the host holds it as a file (or https/data) instead of an `image`.
    ///   - disabled: Not tappable (the form is submitting).
    public init(side: FlareDocumentSide, label: String, state: FlareDocumentSlotState = .empty, image: Image? = nil,
                imageUrl: URL? = nil,
                disabled: Bool = false, onCapture: (() -> Void)? = nil, onRetry: (() -> Void)? = nil) {
        self.side = side; self.label = label; self.state = state; self.image = image; self.imageUrl = imageUrl
        self.disabled = disabled; self.onCapture = onCapture; self.onRetry = onRetry
    }

    /// What a tap does in `state`: retry a failed upload, otherwise take (or retake) the photo; nothing while
    /// uploading.
    private var tapAction: (() -> Void)? {
        switch state {
        case .empty, .captured: return onCapture
        case .failed: return onRetry
        case .uploading: return nil
        }
    }

    /// The tile's height for `width`: 16:10, at least ``FlareSizes/componentDocumentSlotHeight``.
    static func height(width: CGFloat) -> CGFloat { max(width * 10 / 16, FlareSizes.componentDocumentSlotHeight) }

    /// Upload progress as a whole percent, held to 0...100.
    static func percent(_ progress: Double) -> Int { Int(min(max(progress, 0), 100).rounded()) }

    /// "正在上传 42%".
    static func uploadingText(_ progress: Double, strings: FlareStrings) -> String {
        strings.documentSlotUploading.replacingOccurrences(of: "{percent}", with: String(percent(progress)))
    }

    /// What VoiceOver reads after the label.
    static func stateText(_ state: FlareDocumentSlotState, strings: FlareStrings) -> String {
        switch state {
        case .empty: return strings.documentSlotTapToCapture
        case .captured: return strings.documentSlotCaptured
        case .uploading(let progress): return uploadingText(progress, strings: strings)
        case .failed: return strings.documentSlotUploadFailed
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusCard)
        Button { tapAction?() } label: {
            DocumentSlotFrame { face(colors) }
                .clipShape(shape)
                .overlay(border(colors, shape))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(disabled || tapAction == nil)
        .accessibilityLabel(label)
        .accessibilityValue(Self.stateText(state, strings: strings))
        // 「证件正面，已拍摄」, then what a tap does: retake.
        .accessibilityHint(state == .captured ? strings.documentCaptureRetake : "")
    }

    @ViewBuilder private func border(_ colors: FlareColors, _ shape: RoundedRectangle) -> some View {
        switch state {
        case .empty:
            shape.strokeBorder(colors.borderPrimary,
                               style: StrokeStyle(lineWidth: 1.5, dash: [FlareSizes.spacingXs, FlareSizes.spacingXs]))
        case .failed: shape.strokeBorder(colors.error, lineWidth: 1.5)
        case .captured, .uploading: EmptyView()
        }
    }

    private func face(_ colors: FlareColors) -> some View {
        ZStack {
            colors.bgSecondary
            if let image, state != .empty {
                // An overlay: the photo covers the tile without sizing it.
                Color.clear.overlay(image.resizable().scaledToFill())
            } else if let imageUrl, state != .empty {
                Color.clear.overlay(AsyncImage(url: imageUrl) { $0.resizable().scaledToFill() } placeholder: { Color.clear })
            }
            switch state {
            case .empty:
                DocumentOutlineShape(side: side)
                    .stroke(colors.borderPrimary, lineWidth: 1)
                    .padding(FlareSizes.spacingMd)
                VStack(spacing: FlareSizes.spacingXs) {
                    IconView("camera", size: FlareSizes.iconSizeLg, color: colors.textSecondary)
                    Text(label)
                        .font(.system(size: labelSize, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                    Text(strings.documentSlotTapToCapture)
                        .font(.system(size: captionSize))
                        .foregroundColor(colors.textTertiary)
                }
                .multilineTextAlignment(.center)
                .padding(FlareSizes.spacingSm)
            case .captured:
                VStack(spacing: 0) {
                    HStack {
                        Spacer(minLength: 0)
                        IconView("success", size: FlareSizes.iconSizeMd, color: colors.success)
                            .background(Circle().fill(colors.bgPrimary))
                    }
                    .padding(FlareSizes.spacingSm)
                    Spacer(minLength: 0)
                    HStack(spacing: FlareSizes.spacingXs) {
                        IconView("refresh", size: FlareSizes.iconSizeSm, color: colors.mediaOnStage)
                        Text(strings.documentCaptureRetake)
                            .font(.system(size: captionSize, weight: .medium))
                            .foregroundColor(colors.mediaOnStage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FlareSizes.spacingSm)
                    .background(LinearGradient(colors: [.clear, colors.mediaStageShade], startPoint: .top,
                                               endPoint: .bottom))
                }
            case .uploading(let progress):
                colors.mediaStageShade
                VStack(spacing: FlareSizes.spacingXs) {
                    ZStack {
                        Circle().stroke(colors.mediaOnStage.opacity(FlareOpacity.tintStrong),
                                        lineWidth: FlareSizes.spacing3xs)
                        Circle().trim(from: 0, to: Double(Self.percent(progress)) / 100)
                            .stroke(colors.mediaOnStage,
                                    style: StrokeStyle(lineWidth: FlareSizes.spacing3xs, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: FlareSizes.iconSizeXl, height: FlareSizes.iconSizeXl)
                    Text(Self.uploadingText(progress, strings: strings))
                        .font(.system(size: captionSize, weight: .medium).monospacedDigit())
                        .foregroundColor(colors.mediaOnStage)
                }
            case .failed:
                if image != nil || imageUrl != nil { colors.mediaStageShade }
                VStack(spacing: FlareSizes.spacingXs) {
                    IconView("error", size: FlareSizes.iconSizeLg, color: colors.error)
                    Text(strings.documentSlotUploadFailed)
                        .font(.system(size: captionSize))
                        .foregroundColor(image == nil && imageUrl == nil ? colors.errorText : colors.mediaOnStage)
                        .multilineTextAlignment(.center)
                }
                .padding(FlareSizes.spacingSm)
            }
        }
    }
}

/// Lays the slot out at ``FlareDocumentSlot/height(width:)`` for the width it is offered, or taller when its content
/// (larger text) needs it.
private struct DocumentSlotFrame: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let offered = proposal.width ?? .infinity
        let width = offered.isFinite ? offered : FlareSizes.componentDocumentSlotHeight * 16 / 10
        let content = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: max(FlareDocumentSlot.height(width: width), content))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for view in subviews { view.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size)) }
    }
}

/// The empty slot's outline of the side: an ID-1 card with the portrait on the right (front) or the emblem on the
/// left (back); for holding, a person beside a small card. Decoration only.
struct DocumentOutlineShape: Shape {
    let side: FlareDocumentSide

    func path(in rect: CGRect) -> Path {
        let ratio = FlareSizes.componentDocumentFrameRatio
        let h = min(rect.height, rect.width / ratio), w = h * ratio
        let card = CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
        let corner = CGSize(width: h * 0.08, height: h * 0.08)
        var path = Path()
        switch side {
        case .front:
            path.addRoundedRect(in: card, cornerSize: corner)
            path.addRoundedRect(in: CGRect(x: card.maxX - w * 0.3, y: card.minY + h * 0.2, width: w * 0.2,
                                           height: h * 0.55), cornerSize: corner)
        case .back:
            path.addRoundedRect(in: card, cornerSize: corner)
            path.addEllipse(in: CGRect(x: card.minX + w * 0.08, y: card.minY + h * 0.12, width: h * 0.3, height: h * 0.3))
        case .holding:
            let r = h * 0.16
            let head = CGPoint(x: card.midX - w * 0.15, y: card.minY + h * 0.3)
            path.addEllipse(in: CGRect(x: head.x - r, y: head.y - r, width: r * 2, height: r * 2))
            path.move(to: CGPoint(x: head.x - r * 2.2, y: card.maxY))
            path.addQuadCurve(to: CGPoint(x: head.x + r * 2.2, y: card.maxY),
                              control: CGPoint(x: head.x, y: head.y + r * 0.6))
            let small = w * 0.3
            path.addRoundedRect(in: CGRect(x: card.midX + w * 0.1, y: card.midY, width: small, height: small / ratio),
                                cornerSize: corner)
        }
        return path
    }
}
