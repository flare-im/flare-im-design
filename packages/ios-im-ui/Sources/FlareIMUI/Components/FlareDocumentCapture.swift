import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The document capture a host shows for the engine's captureDocument request (design 7.2 and 7.5; spec
/// Message/DocumentCapture).
///
/// The camera is the host's (AVFoundation): it passes its live `preview` and a `capture` that takes a still, so the
/// kit never asks for camera permission. The kit draws the viewfinder on the dark media stage (both themes): an ID-1
/// frame (``FlareSizes/componentDocumentFrameRatio``) for front and back, a face oval above a card frame for holding,
/// white corner marks and the stage shaded outside; the hint for the side and the glare line; album, the shutter
/// and cancel; review with retake and use. It processes the photo: ImageIO bakes the orientation into the pixels and writes a JPEG with no
/// metadata that fits `maxBytes` (``FlareDocumentRules/process(_:side:maxBytes:accept:)``). `onDone` hands over the
/// file the host answers the engine with (`{file}`).
public struct FlareDocumentCapture: View {
    private let side: FlareDocumentSide
    private let maxBytes: Int
    private let accept: [String]
    private let preview: AnyView?
    private let capture: (() async -> Data?)?
    private let pickPhoto: (() async -> Data?)?
    private let cameraUnavailable: Bool
    private let onDone: ((FlareCapturedDocument) -> Void)?
    private let onCancel: (() -> Void)?

    enum Phase: Equatable { case viewfinder, processing, review(FlareCapturedDocument), error(FlareDocumentProcessError) }
    @State private var phase: Phase = .viewfinder
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(side: FlareDocumentSide, maxBytes: Int, accept: [String] = [], preview: AnyView? = nil,
                capture: (() async -> Data?)? = nil, pickPhoto: (() async -> Data?)? = nil,
                cameraUnavailable: Bool = false, onDone: ((FlareCapturedDocument) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.side = side; self.maxBytes = maxBytes; self.accept = accept; self.preview = preview
        self.capture = capture; self.pickPhoto = pickPhoto; self.cameraUnavailable = cameraUnavailable
        self.onDone = onDone; self.onCancel = onCancel
    }

    /// The side's name, as the document input names it.
    public static func sideLabel(_ strings: FlareStrings, _ side: FlareDocumentSide) -> String {
        switch side {
        case .front: return strings.pluginFormDocumentFront
        case .back: return strings.pluginFormDocumentBack
        case .holding: return strings.pluginFormDocumentHolding
        }
    }

    private var hint: String {
        switch side {
        case .front: return strings.documentCaptureHintFront
        case .back: return strings.documentCaptureHintBack
        case .holding: return strings.documentCaptureHintHolding
        }
    }

    private func take(_ source: (() async -> Data?)?) {
        guard let source, phase != .processing else { return }
        Task { @MainActor in
            guard let photo = await source() else { return }
            phase = .processing
            do {
                phase = .review(try await FlareDocumentRules.process(photo, side: side, maxBytes: maxBytes, accept: accept))
            } catch let error as FlareDocumentProcessError {
                phase = .error(error)
            } catch {
                phase = .error(.failed)
            }
        }
    }

    private func errorText(_ error: FlareDocumentProcessError) -> String {
        switch error {
        case .tooLarge: return strings.documentCaptureTooLarge
        case .notAccepted: return strings.documentCaptureNotAccepted
        case .failed: return strings.documentCaptureFailed
        }
    }

    @ViewBuilder private func reviewImage(_ data: Data) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit() }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFit() }
        #endif
    }

    /// The corner marks' stroke (spec §6.4: ``FlareSizes/spacing2xl`` long).
    static let cornerMarkWidth = FlareSizes.componentCaptureFrameStroke

    /// The viewfinder's guides in a stage of `size`. Front and back: one ID-1 frame, the stage's width less a
    /// ``FlareSizes/spacing2xl`` gutter each side (smaller when the stage is short). Holding: a face oval half the
    /// width above an ID-1 card frame 60% wide, lower and to the right; the pair scaled down to fit a short stage.
    static func guides(side: FlareDocumentSide, in size: CGSize) -> (card: CGRect, face: CGRect?) {
        let inset = FlareSizes.spacing2xl
        let ratio = FlareSizes.componentDocumentFrameRatio
        let room = CGSize(width: max(0, size.width - 2 * inset), height: max(0, size.height - 2 * inset))
        guard side == .holding else {
            let width = min(room.width, room.height * ratio)
            let height = width / ratio
            return (CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height), nil)
        }
        // Laid out for a unit width (the stage's), then scaled to fit the room.
        let faceWidth: CGFloat = 0.5, faceHeight = faceWidth * 4 / 3
        let cardWidth: CGFloat = 0.6, cardHeight = cardWidth / ratio, gap: CGFloat = 0.04
        let unitHeight = faceHeight + gap + cardHeight
        let scale = min(size.width, room.height / unitHeight)
        let top = (size.height - unitHeight * scale) / 2
        let face = CGRect(x: (size.width - faceWidth * scale) / 2, y: top,
                          width: faceWidth * scale, height: faceHeight * scale)
        let cardX = min((size.width - cardWidth * scale) / 2 + 0.1 * scale, size.width - inset - cardWidth * scale)
        let card = CGRect(x: max(inset, cardX), y: face.maxY + gap * scale,
                          width: cardWidth * scale, height: cardHeight * scale)
        return (card, face)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // A camera stage stays dark in both themes (the media stage tokens).
        let light = colors.mediaOnStage
        let camera = capture != nil && !cameraUnavailable
        VStack(spacing: FlareSizes.spacingMd) {
            if case .error(let error) = phase {
                StatusBannerView(text: errorText(error), tone: .danger)
                    .accessibilityIdentifier("flare-doc-error")
            }
            ZStack {
                colors.mediaStage
                if case .review(let file) = phase {
                    reviewImage(file.bytes)
                        .accessibilityLabel(Self.sideLabel(strings, side))
                        .accessibilityIdentifier("flare-doc-review")
                } else {
                    if let preview { preview }
                    GeometryReader { proxy in
                        viewfinder(Self.guides(side: side, in: proxy.size), size: proxy.size, colors)
                    }
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("flare-doc-frame")
                    if cameraUnavailable {
                        VStack(spacing: FlareSizes.spacingSm) {
                            IconView("camera-off", size: FlareSizes.iconSizeXl, color: light)
                            Text(strings.documentCaptureCameraUnavailable)
                                .font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(light)
                                .multilineTextAlignment(.center)
                        }
                        .padding(FlareSizes.spacing2xl)
                    } else if phase == .processing {
                        ProgressView().controlSize(.large).tint(light)
                    }
                }
            }
            // §6.4: on a pointer (PC, iPad) the camera picture is 16:10; a phone gives it the whole stage.
            .modifier(FlareCapturePreviewFrame(pointer: FlarePluginPage.refreshKeyInHeader))
            .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
            Group {
                switch phase {
                case .processing:
                    Text(strings.documentCaptureProcessing).font(.system(size: FlareSizes.fontSizeXl))
                case .viewfinder, .error:
                    VStack(spacing: FlareSizes.spacingXs) {
                        Text(hint).font(.system(size: FlareSizes.fontSizeXl))
                        Text(strings.documentCaptureHintGlare).font(.system(size: FlareSizes.fontSizeMd))
                            .opacity(FlareOpacity.muted)
                    }
                case .review: EmptyView()
                }
            }
            .foregroundColor(light)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            if case .review(let file) = phase {
                HStack(spacing: FlareSizes.spacingMd) {
                    ButtonView(label: strings.documentCaptureRetake, variant: .secondary, size: .lg, block: true) {
                        phase = .viewfinder
                    }
                    ButtonView(label: strings.documentCaptureUse, size: .lg, block: true) {
                        phase = .viewfinder
                        onDone?(file)
                    }
                }
            } else if camera {
                HStack(spacing: FlareSizes.spacingMd) {
                    Group {
                        if pickPhoto != nil {
                            ButtonView(label: strings.documentCaptureFromAlbum, variant: .quiet, size: .md,
                                       disabled: phase == .processing, icon: "image") { take(pickPhoto) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    shutter(colors, disabled: phase == .processing)
                    Group {
                        if let onCancel {
                            ButtonView(label: strings.cancel, variant: .quiet, size: .md, action: onCancel)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                VStack(spacing: FlareSizes.spacingSm) {
                    if pickPhoto != nil {
                        ButtonView(label: strings.documentCaptureFromAlbum, size: .lg, disabled: phase == .processing,
                                   block: true, icon: "image") { take(pickPhoto) }
                    }
                    if let onCancel {
                        ButtonView(label: strings.cancel, variant: .quiet, size: .lg, block: true, action: onCancel)
                    }
                }
            }
        }
        .padding(FlareSizes.spacingLg)
        // §6.4: a pointer's capture is a dialog `component.capturePreviewWidth` wide.
        .frame(maxWidth: FlarePluginPage.refreshKeyInHeader ? FlareSizes.componentCapturePreviewWidth : .infinity)
        .frame(maxWidth: .infinity)
        .background(colors.mediaStage.ignoresSafeArea())
        // The stage is dark in both themes: the kit buttons on it take their dark look.
        .environment(\.colorScheme, .dark)
        .onChange(of: side) { _ in phase = .viewfinder }
    }

    /// The shade outside the guides, the face oval and the white corner marks of the card frame.
    private func viewfinder(_ guides: (card: CGRect, face: CGRect?), size: CGSize, _ colors: FlareColors) -> some View {
        let card = guides.card, mark = FlareSizes.spacing2xl
        // Each corner and the directions its two arms run in.
        let corners: [(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat)] = [
            (card.minX, card.minY, 1, 1), (card.maxX, card.minY, -1, 1),
            (card.minX, card.maxY, 1, -1), (card.maxX, card.maxY, -1, -1),
        ]
        return ZStack {
            Path { path in
                path.addRect(CGRect(origin: .zero, size: size))
                path.addRoundedRect(in: card, cornerSize: CGSize(width: FlareSizes.radiusMd, height: FlareSizes.radiusMd))
                if let face = guides.face { path.addEllipse(in: face) }
            }
            .fill(colors.mediaStageShade, style: FillStyle(eoFill: true))
            if let face = guides.face {
                Ellipse().stroke(colors.mediaOnStage, lineWidth: FlareSizes.spacing3xs)
                    .frame(width: face.width, height: face.height)
                    .position(x: face.midX, y: face.midY)
            }
            Path { path in
                for (x, y, dx, dy) in corners {
                    path.move(to: CGPoint(x: x, y: y + dy * mark))
                    path.addLine(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + dx * mark, y: y))
                }
            }
            .stroke(colors.mediaOnStage, style: StrokeStyle(lineWidth: Self.cornerMarkWidth, lineCap: .square))
        }
    }

    /// A white disc inside a white ring 4 wide, ``FlareSizes/componentCaptureShutterSize`` across.
    private func shutter(_ colors: FlareColors, disabled: Bool) -> some View {
        Button { take(capture) } label: {
            ZStack {
                Circle().strokeBorder(colors.mediaOnStage, lineWidth: FlareSizes.spacingXs)
                Circle().fill(colors.mediaOnStage).padding(FlareSizes.spacingXs * 2)
            }
            .frame(width: FlareSizes.componentCaptureShutterSize, height: FlareSizes.componentCaptureShutterSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(strings.documentCaptureShoot)
    }
}

/// The capture's camera frame: 16:10 on a pointer, the whole stage on a phone.
private struct FlareCapturePreviewFrame: ViewModifier {
    let pointer: Bool
    func body(content: Content) -> some View {
        if pointer {
            content.aspectRatio(FlareSizes.componentCapturePreviewRatio, contentMode: .fit).frame(maxWidth: .infinity)
        } else {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
