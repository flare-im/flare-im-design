import Foundation
import XCTest
import CoreImage
@testable import FlareIMUI

final class QrExportDecodeTests: XCTestCase {
    func testExportedCodeDecodesToTheSameCanonicalUrl() throws {
        let value = "https://scan.example.test/u/0123456789ABCDEFGHIJKLZ"
        let data = try XCTUnwrap(FlareQrExport.pngData(payload: value))
        let image = try XCTUnwrap(CIImage(data: data))
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
        let code = try XCTUnwrap(detector.features(in: image).first as? CIQRCodeFeature)
        XCTAssertEqual(code.messageString, value)
    }
}
