import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The capability components and the protected media block against spec/capability-ui-vectors.json.
final class CapabilityComponentsTests: XCTestCase {
    private func vectors() throws -> [String: Any] {
        let file = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/capability-ui-vectors.json")
        return try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
    }
    private func cases(_ section: String) throws -> [[String: Any]] {
        ((try vectors()[section] as? [String: Any])?["cases"] as? [[String: Any]]) ?? []
    }
    private func json(_ any: Any) throws -> PluginJSONValue {
        try JSONDecoder().decode(PluginJSONValue.self, from: JSONSerialization.data(withJSONObject: any, options: .fragmentsAllowed))
    }
    private func hex(_ text: String) -> Data {
        var out = Data(); var i = text.startIndex
        while i < text.endIndex, let j = text.index(i, offsetBy: 2, limitedBy: text.endIndex) {
            out.append(UInt8(text[i..<j], radix: 16)!); i = j
        }
        return out
    }

    func testConsentAndLabels() throws {
        for c in try cases("consentDecision") {
            let answer = FlareCapabilityConsentDecision(rawValue: c["decision"] as! String)!.answer
            XCTAssertEqual(answer, c["answer"] as? [String: String])
        }
        for c in try cases("capabilityLabel") {
            let params = try (c["params"] as? [String: Any]).map { try json($0).objectValue ?? [:] }
            XCTAssertEqual(FlareCapabilityRules.labelKey(capability: c["capability"] as! String, params: params), c["key"] as? String)
            XCTAssertNotEqual(FlareCapabilityRules.label(.english, capability: c["capability"] as! String, params: params),
                              c["capability"] as? String)
        }
        for c in try cases("consentAllowsAlways") {
            XCTAssertEqual(FlareCapabilityRules.allowsAlways(c["capability"] as! String), c["always"] as? Bool)
        }
    }

    func testPaymentRules() throws {
        for c in try cases("paymentAmount") {
            XCTAssertEqual(FlarePaymentRules.amountText(c["amount"] as! String, currency: c["currency"] as! String),
                           c["text"] as? String, "\(c)")
        }
        for c in try cases("paymentCountdown") {
            let r = FlarePaymentRules.countdown(remainingMs: Int64((c["remainingMs"] as! NSNumber).int64Value))
            XCTAssertEqual(r.text, c["text"] as? String)
            XCTAssertEqual(r.expired, c["expired"] as? Bool)
        }
    }

    func testDocumentRules() throws {
        for c in try cases("documentFrame") {
            XCTAssertEqual(FlareDocumentSide(rawValue: c["side"] as! String)!.frameAspect,
                           CGFloat((c["aspect"] as! NSNumber).doubleValue), accuracy: 0.001)
        }
        let compression = try vectors()["documentCompression"] as! [String: Any]
        let plan = (compression["plan"] as! [[NSNumber]]).map { ($0[0].intValue, $0[1].doubleValue) }
        XCTAssertEqual(plan.map(\.0), FlareDocumentRules.compressionPlan.map(\.edge))
        XCTAssertEqual(plan.map(\.1), FlareDocumentRules.compressionPlan.map(\.quality))
        for c in compression["fileName"] as! [[String: String]] {
            XCTAssertEqual(FlareDocumentSide(rawValue: c["side"]!)!.fileName, c["name"])
        }
        for c in try cases("documentAccept") {
            XCTAssertEqual(FlareDocumentRules.acceptsJpeg(c["accept"] as! [String]), c["ok"] as? Bool)
        }
        for c in try cases("jpegExif") {
            XCTAssertEqual(FlareDocumentRules.jpegHasExif(hex(c["hex"] as! String)), c["exif"] as? Bool, "\(c)")
        }
    }

    /// A JPEG with EXIF, GPS and orientation 6 comes out upright, within the limit, with no metadata.
    func testProcessingStripsMetadataAndAppliesOrientation() async throws {
        let width = 3000, height = 2000
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.setFillColor(CGColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let source = NSMutableData()
        let destination = CGImageDestinationCreateWithData(source, UTType.jpeg.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, [
            kCGImagePropertyOrientation: 6,
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "secret"],
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 31.2],
        ] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        XCTAssertTrue(FlareDocumentRules.jpegHasExif(source as Data))
        let file = try await FlareDocumentRules.process(source as Data, side: .front, maxBytes: 400 * 1024)
        XCTAssertEqual(file.fileName, "document-front.jpg")
        XCTAssertEqual(file.contentType, "image/jpeg")
        XCTAssertLessThanOrEqual(file.bytes.count, 400 * 1024)
        XCTAssertFalse(FlareDocumentRules.jpegHasExif(file.bytes))
        let out = CGImageSourceCreateWithData(file.bytes as CFData, nil)!
        let properties = CGImageSourceCopyPropertiesAtIndex(out, 0, nil) as? [CFString: Any] ?? [:]
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        let image = CGImageSourceCreateImageAtIndex(out, 0, nil)!
        XCTAssertGreaterThan(image.height, image.width, "orientation 6 is baked into the pixels")
        XCTAssertLessThanOrEqual(max(image.width, image.height), 2048)
    }

    func testProcessingRefusesWhatTheInputDoesNotTake() async {
        do {
            _ = try await FlareDocumentRules.process(Data([1, 2, 3]), side: .back, maxBytes: 1000, accept: ["image/png"])
            XCTFail("accepted")
        } catch { XCTAssertEqual(error as? FlareDocumentProcessError, .notAccepted) }
        do {
            _ = try await FlareDocumentRules.process(Data([1, 2, 3]), side: .back, maxBytes: 1000)
            XCTFail("decoded garbage")
        } catch { XCTAssertEqual(error as? FlareDocumentProcessError, .failed) }
    }

    func testProtectedMediaSourcesAndReason() throws {
        for c in try cases("protectedMediaSource") {
            XCTAssertEqual(FlarePluginProtectedMedia.source(c["url"] as? String) != nil, c["native"] as? Bool, "\(c)")
        }
        XCTAssertEqual(FlarePluginProtectedMedia.url(result: .object(["url": .string("https://h/p?grant=g")]), urlPath: "/url"),
                       "https://h/p?grant=g")
        let own = try JSONDecoder().decode(PluginBlock.self, from: Data(#"""
            {"kind":"protected-media","label":"My documents","items":[{"id":"m1","label":"Front","mediaType":"image/jpeg","input":{"applicationId":"a1"}}],
             "action":{"id":"viewDocument","label":"View"},"inputName":"materialId","urlPath":"/url"}
            """#.utf8))
        guard case .protectedMedia(let block) = own else { return XCTFail("not decoded") }
        XCTAssertFalse(block.asksReason)
        let read = PluginProtectedMediaBlockView.read(block, item: block.items[0], reason: "")
        XCTAssertEqual(read?.formValues, ["materialId": .string("m1")])
        let console = try JSONDecoder().decode(PluginProtectedMediaBlock.self, from: Data(#"""
            {"items":[{"id":"m1","label":"Front"}],"action":{"id":"read","label":"Read"},"inputName":"materialId","reasonInput":"reason","urlPath":"/url"}
            """#.utf8))
        XCTAssertTrue(console.asksReason)
        XCTAssertEqual(PluginProtectedMediaBlockView.read(console, item: console.items[0], reason: "audit")?.formValues,
                       ["materialId": .string("m1"), "reason": .string("audit")])
        for c in try cases("protectedMediaReason") {
            let reasonInput = c["reasonInput"] as? String
            let b = PluginProtectedMediaBlock(items: [], inputName: "m", reasonInput: reasonInput, urlPath: "/u")
            XCTAssertEqual(b.asksReason, c["asks"] as? Bool)
        }
        let section = try JSONDecoder().decode(PluginBlock.self, from: Data(#"""
            {"kind":"section","label":"S","blocks":[{"kind":"protected-media","items":[],"inputName":"m","urlPath":"/u"}]}
            """#.utf8))
        if case .section(let s) = section { XCTAssertTrue(s.blocks.isEmpty, "never inside a section") }
    }

    func testProtectedImageSessionKeepsNothingOnDisk() {
        let configuration = PluginProtectedImage.session.configuration
        XCTAssertNil(configuration.urlCache)
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertEqual(configuration.requestCachePolicy, .reloadIgnoringLocalAndRemoteCacheData)
    }

    func testLocationInput() throws {
        for c in try cases("locationInput") {
            let value = try c["value"].flatMap { $0 is NSNull ? nil : try json($0) }
            let fix = PluginLocationValue.read(value, precision: PluginLocationPrecision(rawValue: c["precision"] as! String))
            XCTAssertEqual(fix != nil, c["ok"] as? Bool, "\(c)")
            if let fix { XCTAssertEqual(fix.text, c["text"] as? String) }
        }
        let input = try JSONDecoder().decode(PluginInput.self, from: Data(#"{"id":"place","kind":"location","label":"Where","required":true,"precision":"coarse"}"#.utf8))
        XCTAssertEqual(input.precision, .coarse)
        XCTAssertThrowsError(try JSONDecoder().decode(PluginInput.self, from: Data(#"{"id":"p","kind":"location","label":"W"}"#.utf8)))
        let fix = PluginLocationValue(latitude: 31.23, longitude: 121.47, accuracyM: 1000, precision: .coarse)
        XCTAssertEqual(PluginFormRules.check(input, nil), .required)
        XCTAssertNil(PluginFormRules.check(input, fix.json))
        XCTAssertEqual(PluginFormRules.values([input], ["place": fix.json])["place"], fix.json)
        let fine = PluginInput(id: "place", kind: .location, label: "W", precision: .fine)
        XCTAssertEqual(PluginFormRules.draftValue(fine, values: ["place": fix.json]), .null)
    }

    @MainActor func testConsentOffersOnlyWhatItMay() throws {
        // The inspector reads the view's own environment, so the checks use the default strings.
        let strings = FlareStrings()
        var decisions: [FlareCapabilityConsentDecision] = []
        let view = FlareCapabilityConsent(pluginName: "Realname", capability: "documentCapture", purpose: "Verify",
                                          onDecide: { decisions.append($0) })
        let tree = try view.inspect()
        XCTAssertNoThrow(try tree.find(text: FlareCapabilityConsent.title(strings, pluginName: "Realname")))
        XCTAssertNoThrow(try tree.find(text: strings.capabilityDocumentCapture))
        try tree.find(button: strings.capabilityConsentAllowAlways).tap()
        try tree.find(button: strings.capabilityConsentDeny).tap()
        XCTAssertEqual(decisions, [.always, .deny])
        let location = try FlareCapabilityConsent(pluginName: "C", capability: "locationOnce",
                                                  params: ["precision": .string("fine")]).inspect()
        XCTAssertThrowsError(try location.find(button: strings.capabilityConsentAllowAlways))
        XCTAssertNoThrow(try location.find(button: strings.capabilityConsentAllowOnce))
    }

    func testPaymentConfirmOnlyBeforeExpiry() {
        let order = FlarePaymentOrder(orderId: "o", amount: "1234.50", currency: "CNY", payee: "Wallet", title: "T",
                                      expiresAtMs: 10_000)
        XCTAssertTrue(FlarePaymentConfirmation.confirmEnabled(order: order, nowMs: 5_000, busy: false, confirmDisabled: false))
        XCTAssertFalse(FlarePaymentConfirmation.confirmEnabled(order: order, nowMs: 10_000, busy: false, confirmDisabled: false))
        XCTAssertFalse(FlarePaymentConfirmation.confirmEnabled(order: order, nowMs: 5_000, busy: true, confirmDisabled: false))
        let bad = FlarePaymentOrder(orderId: "o", amount: "1e5", currency: "CNY", payee: "P", title: "", expiresAtMs: 10_000)
        XCTAssertFalse(FlarePaymentConfirmation.confirmEnabled(order: bad, nowMs: 0, busy: false, confirmDisabled: false))
    }
}
