import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import ImageIO

// MARK: - QRCard

/// QR card — personal add-me card: avatar, name and the user's QR code.
///
/// The kit encodes `qrPayload` with CoreImage (error correction M, UTF-8 bytes, 4-module quiet
/// zone) and draws it with nearest-neighbour scaling, dark on a light panel in both color
/// schemes, so any scanner reads it. Without a payload — or with one too long for a QR code —
/// the frame says "QR code unavailable" instead; the card never draws a look-alike matrix.
/// Spec: Profile/QRCard (`QRCardView`).
public struct QRCardView: View {
    private let name: String
    private let subtitle: String?
    private let avatarURL: String?
    private let qrPayload: String?
    private let phase: String
    private let refreshInMs: Double?
    private let onRefresh: (() -> Void)?
    private let onSave: (() -> Void)?
    private let onShare: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var cache = FlareQRCodeCache()

    public init(name: String, subtitle: String? = nil, avatarURL: String? = nil, qrPayload: String? = nil, phase: String = "ready", refreshInMs: Double? = nil, onRefresh: (() -> Void)? = nil, onSave: (() -> Void)? = nil, onShare: (() -> Void)? = nil) {
        self.name = name; self.subtitle = subtitle; self.avatarURL = avatarURL; self.qrPayload = qrPayload
        self.phase = phase; self.refreshInMs = refreshInMs; self.onRefresh = onRefresh; self.onSave = onSave; self.onShare = onShare
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let code = cache.image(for: ["ready", "offline"].contains(phase) && (refreshInMs == nil || refreshInMs! > 0) ? qrPayload : nil)
        VStack(spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: name, displayName: name, avatarURL: avatarURL, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 16, weight: .semibold)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 12)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            FlareQRCodeFrame(code: code, label: "\(strings.qrCode), \(name)")
                // The VStack contributes the other 12 points below the identity row.
                .padding(.top, 4)

            if code != nil {
                Text(strings.scanToAddMe).font(.system(size: 12)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
            HStack {
                if code == nil && !["loading", "refreshing"].contains(phase), let onRefresh { ButtonView(label: strings.retry, variant: .quiet, action: onRefresh) }
                if code != nil, let onSave { ButtonView(label: strings.scanSaveCode, variant: .quiet, action: onSave) }
                if code != nil, let onShare { ButtonView(label: strings.scanShareCode, variant: .quiet, action: onShare) }
            }
        }
        .padding(18)
        .frame(width: 240)
        // The shadow belongs to the card shape only: on the whole stack it would also blur
        // behind the code's modules and grey its light ground.
        .background(RoundedRectangle(cornerRadius: 16).fill(colors.bgPrimary)
            .shadow(color: Color.black.opacity(0.14), radius: 24, y: 10)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.borderPrimary, lineWidth: 1)))
    }
}

public struct FlareQrMatrix: View {
    private let payload: String?
    private let label: String
    @State private var cache = FlareQRCodeCache()
    public init(payload: String?, label: String) { self.payload = payload; self.label = label }
    public var body: some View { FlareQRCodeFrame(code: cache.image(for: payload), label: label) }
}

/// Export uses the exact same matrix and quiet zone as the on-screen QR component.
public enum FlareQrExport {
    public static func pngData(payload: String, pixelsPerModule: Int = 8) -> Data? {
        guard (1...32).contains(pixelsPerModule), let mask = FlareQRCode.maskImage(for: payload),
              let context = CGContext(data: nil, width: mask.width * pixelsPerModule,
                height: mask.height * pixelsPerModule, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(rect)
        context.interpolationQuality = .none
        context.clip(to: rect, mask: mask)
        context.setFillColor(CGColor(gray: 0, alpha: 1)); context.fill(rect)
        guard let image = context.makeImage() else { return nil }
        let data = NSMutableData()
        guard let output = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(output, image, nil)
        guard CGImageDestinationFinalize(output) else { return nil }
        return data as Data
    }
}

/// The scannable square and its light quiet zone, shared by contact and invite cards.
struct FlareQRCodeFrame: View {
    let code: CGImage?
    let label: String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let frame = RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
        Group {
            if let code {
                // Scanners expect dark modules on a light ground, so the code keeps the light
                // palette whatever the color scheme is. The quiet zone is the code's margin.
                let light = flareBrandTheme.light
                codeImage(code, color: light.textPrimary)
                    .aspectRatio(1, contentMode: .fit)
                    .background(frame.fill(light.bgPrimary))
            } else {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Text(strings.qrCardUnavailable)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                            .multilineTextAlignment(.center)
                    )
                    .padding(FlareSizes.spacing2md)
                    .background(frame.fill(colors.bgSecondary))
            }
        }
        .overlay(frame.stroke(colors.borderPrimary, lineWidth: 1))
    }

    /// The code at a whole number of device pixels per module, centred, no interpolation.
    private func codeImage(_ code: CGImage, color: Color) -> some View {
        GeometryReader { proxy in
            // The whole quiet zone stays on the rounded light panel: a square corner clears a
            // corner arc of radius r once it sits r·(1 − 1/√2) inside.
            let inset = FlareSizes.radiusLg * (1 - 1 / CGFloat(2).squareRoot())
            let side = min(proxy.size.width, proxy.size.height) - 2 * inset
            let count = CGFloat(code.width)
            let pixels = (side * displayScale / count).rounded(.down)
            let module = pixels >= 1 ? pixels / displayScale : side / count
            Image(decorative: code, scale: 1)
                .renderingMode(.template)
                .interpolation(.none)
                .antialiased(false)
                .resizable()
                .foregroundColor(color)
                .frame(width: module * count, height: module * count)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityAddTraits(.isImage)
    }
}

/// QR rendering for ``QRCardView``: CoreImage's generator at error correction level M, returned
/// as one pixel per module with a 4-module quiet zone — dark modules opaque, everything else
/// transparent, so the view tints it with a palette color.
enum FlareQRCode {
    static let quietZone = 4

    /// nil for an empty payload or one longer than a version 40 code holds.
    static func maskImage(for payload: String) -> CGImage? {
        guard !payload.isEmpty else { return nil }
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(payload.utf8)
        generator.correctionLevel = "M"
        guard let code = generator.outputImage else { return nil }
        // The generator draws black modules on white with a one-module margin. Inverting and
        // then masking to alpha leaves dark modules opaque; the rest of the widened extent is
        // transparent, which completes the quiet zone.
        let mask = code.applyingFilter("CIColorInvert").applyingFilter("CIMaskToAlpha")
        let margin = CGFloat(quietZone - 1)
        return CIContext(options: [.cacheIntermediates: false])
            .createCGImage(mask, from: code.extent.insetBy(dx: -margin, dy: -margin))
    }
}

/// Keeps the last encoded payload so view updates with the same payload do not encode again.
final class FlareQRCodeCache {
    private var payload: String?
    private var image: CGImage?

    func image(for payload: String?) -> CGImage? {
        if payload != self.payload {
            self.payload = payload
            image = payload.flatMap(FlareQRCode.maskImage(for:))
        }
        return image
    }
}
