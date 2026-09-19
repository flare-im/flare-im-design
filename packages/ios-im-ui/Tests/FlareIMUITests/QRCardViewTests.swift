import CoreImage
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-031: `QRCardView` encodes its payload into a real QR code.
final class QRCardViewTests: XCTestCase {
    /// RGBA bytes of `image`, row 0 at the top.
    private func rgba(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                                  bitsPerComponent: 8, bytesPerRow: image.width * 4, space: space,
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return bytes
    }

    /// Symbol sizes of the qrcodegen reference at level M for byte-mode payloads (1 byte → version 1,
    /// the 61-byte URL → version 4, 63 bytes of CJK → version 5, 2331 bytes → version 40).
    func testPayloadImageIsTheSymbolPlusAFourModuleQuietZone() throws {
        let cases: [(payload: String, modules: Int)] = [
            ("a", 21),
            ("https://flare.im/add-friend?uid=u_10293847&token=Zm9vYmFy2026", 33),
            ("扫一扫，加我为好友：Flare 即时通讯二维码名片", 37),
            (String(repeating: "x", count: 2331), 177),
        ]
        let quiet = FlareQRCode.quietZone
        XCTAssertEqual(quiet, 4)
        for (payload, modules) in cases {
            let image = try XCTUnwrap(FlareQRCode.maskImage(for: payload), "\(payload.utf8.count) bytes")
            let side = modules + 2 * quiet
            XCTAssertEqual(image.width, side, "\(payload.utf8.count) bytes")
            XCTAssertEqual(image.height, side, "\(payload.utf8.count) bytes")

            let bytes = try rgba(image)
            func opaque(_ x: Int, _ y: Int) -> Bool { bytes[(y * side + x) * 4 + 3] > 127 }
            // Quiet zone: four fully transparent modules on every side.
            for i in 0..<side {
                for q in 0..<quiet {
                    XCTAssertFalse(opaque(i, q) || opaque(i, side - 1 - q) || opaque(q, i) || opaque(side - 1 - q, i),
                                   "quiet zone module at \(i), \(q)")
                }
            }
            // The three finder patterns: dark 7 × 7 ring, light ring, dark 3 × 3 centre.
            for (fx, fy) in [(0, 0), (modules - 7, 0), (0, modules - 7)] {
                for dy in 0..<7 {
                    for dx in 0..<7 {
                        let ring = max(abs(dx - 3), abs(dy - 3))
                        XCTAssertEqual(opaque(quiet + fx + dx, quiet + fy + dy), ring != 2,
                                       "finder at \(fx), \(fy) module \(dx), \(dy)")
                    }
                }
            }
        }
    }

    func testEmptyOrOversizedPayloadHasNoImage() {
        XCTAssertNil(FlareQRCode.maskImage(for: ""))
        XCTAssertNil(FlareQRCode.maskImage(for: String(repeating: "x", count: 2332)))
    }

    @MainActor
    func testWithoutPayloadTheFrameSaysUnavailableAndDrawsNoCode() throws {
        let strings = FlareStrings()
        for payload in [nil, ""] as [String?] {
            let card = try QRCardView(name: "Alice", qrPayload: payload).inspect()
            XCTAssertEqual(try card.find(text: strings.qrCardUnavailable).string(), strings.qrCardUnavailable)
            XCTAssertThrowsError(try card.find(viewWithAccessibilityLabel: "\(strings.qrCode), Alice"))
            XCTAssertThrowsError(try card.find(ViewType.GeometryReader.self))
            XCTAssertThrowsError(try card.find(text: strings.scanToAddMe))
        }
    }

    @MainActor
    func testPayloadShowsALabelledCodeImageAndTheHint() throws {
        let strings = FlareStrings()
        let card = try QRCardView(name: "Alice", qrPayload: "flare://add/u_1").inspect()
        XCTAssertNoThrow(try card.find(viewWithAccessibilityLabel: "\(strings.qrCode), Alice"))
        XCTAssertNoThrow(try card.find(text: strings.scanToAddMe))
        XCTAssertThrowsError(try card.find(text: strings.qrCardUnavailable))
    }

    #if os(macOS)
    /// End to end: the rendered card decodes with CoreImage's detector in the dark scheme, at level M,
    /// with dark modules on the light panel.
    @MainActor
    func testRenderedCardScansInTheDarkScheme() throws {
        let payload = "https://flare.im/add-friend?token=ios-qr-card"
        let renderer = ImageRenderer(content: QRCardView(name: "Alice", qrPayload: payload)
            .padding(32)
            .background(FlareColors.of(.dark).bgSecondary)
            .environment(\.colorScheme, .dark))
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.cgImage)
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                                                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
        let features = detector.features(in: CIImage(cgImage: image)).compactMap { $0 as? CIQRCodeFeature }
        XCTAssertEqual(features.map(\.messageString), [payload])
        let feature = try XCTUnwrap(features.first)
        XCTAssertEqual(feature.symbolDescriptor?.errorCorrectionLevel, .levelM)

        // CoreImage feature coordinates start at the bottom left; the bitmap starts at the top left.
        let bytes = try rgba(image)
        func luminance(_ point: CGPoint) -> Int {
            let x = Int(point.x.rounded(.down)), y = image.height - 1 - Int(point.y.rounded(.down))
            let i = (y * image.width + x) * 4
            return (Int(bytes[i]) + Int(bytes[i + 1]) + Int(bytes[i + 2])) / 3
        }
        let bounds = feature.bounds
        let modules = CGFloat(try XCTUnwrap(feature.symbolDescriptor).symbolVersion * 4 + 17)
        let module = bounds.width / modules
        // Inside the top-left finder: dark. Two modules outside the symbol: the light quiet zone.
        XCTAssertLessThan(luminance(CGPoint(x: bounds.minX + module * 0.5, y: bounds.maxY - module * 0.5)), 80)
        XCTAssertGreaterThan(luminance(CGPoint(x: bounds.minX - module * 2, y: bounds.maxY - module * 0.5)), 200)
        XCTAssertGreaterThan(luminance(CGPoint(x: bounds.midX, y: bounds.maxY + module * 2)), 200)
    }
    #endif
}
