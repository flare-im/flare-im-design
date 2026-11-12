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
/// kit never asks for camera permission. The kit draws the viewfinder frame for the side, the hint, review with use
/// and retake, and processes the photo: ImageIO bakes the orientation into the pixels and writes a JPEG with no
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

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // A camera stage stays dark in both themes.
        let stage = Color.black.opacity(0.94), light = Color.white.opacity(0.92)
        let camera = capture != nil && !cameraUnavailable
        VStack(spacing: FlareSizes.spacingMd) {
            ZStack {
                stage
                if case .review(let file) = phase {
                    reviewImage(file.bytes)
                        .accessibilityLabel(Self.sideLabel(strings, side))
                        .accessibilityIdentifier("flare-doc-review")
                } else {
                    if let preview { preview }
                    RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                        .stroke(light, lineWidth: 2)
                        .aspectRatio(side.frameAspect, contentMode: .fit)
                        .padding(FlareSizes.spacingLg)
                        .accessibilityHidden(true)
                        .accessibilityIdentifier("flare-doc-frame")
                    if cameraUnavailable {
                        VStack {
                            Spacer()
                            Text(strings.documentCaptureCameraUnavailable)
                                .font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(light)
                                .multilineTextAlignment(.center)
                                .padding(FlareSizes.spacingLg)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
            Group {
                switch phase {
                case .processing: Text(strings.documentCaptureProcessing).foregroundColor(colors.textSecondary)
                case .error(let error):
                    Text(errorText(error)).foregroundColor(colors.errorText).accessibilityIdentifier("flare-doc-error")
                case .viewfinder: Text(hint).foregroundColor(colors.textSecondary)
                case .review: EmptyView()
                }
            }
            .font(.system(size: FlareSizes.fontSizeMd))
            .multilineTextAlignment(.center)
            VStack(spacing: FlareSizes.spacingSm) {
                if case .review(let file) = phase {
                    ButtonView(label: strings.documentCaptureUse, size: .lg, block: true) {
                        phase = .viewfinder
                        onDone?(file)
                    }
                    ButtonView(label: strings.documentCaptureRetake, variant: .secondary, size: .lg, block: true) {
                        phase = .viewfinder
                    }
                } else {
                    if camera {
                        ButtonView(label: strings.documentCaptureShoot, size: .lg, loading: phase == .processing,
                                   block: true) { take(capture) }
                    }
                    if pickPhoto != nil {
                        ButtonView(label: strings.documentCaptureFromAlbum, variant: camera ? .secondary : .primary,
                                   size: .lg, disabled: phase == .processing, block: true) { take(pickPhoto) }
                    }
                }
            }
        }
        .padding(FlareSizes.spacingLg)
        .onChange(of: side) { _ in phase = .viewfinder }
    }
}
