import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Plugin host capability components — pure rules shared by ``FlareCapabilityConsent``, ``FlareDocumentCapture`` and
/// ``FlarePaymentConfirmation`` (spec/capability-ui-vectors.json; docs/design/plugin-client-hot-delivery.md 7).
///
/// The kit draws what the engine asks the host (`plugin.capability_request`: consent, captureDocument,
/// confirmPayment). It never runs a request itself: the host listens, shows the component and answers the engine
/// with what the component hands back.
public enum FlareCapabilityConsentDecision: String, Sendable, CaseIterable {
    case once, always, deny

    /// What the host answers the engine's consent request with (`plugin.capability_complete` result):
    /// `{decision: "once" | "always" | "deny"}`. The engine keeps only "always"; "once" lets this request through
    /// and keeps nothing, so the host never revokes anything to emulate it.
    public var answer: [String: String] { ["decision": rawValue] }
}

public enum FlareCapabilityRules {
    /// The FlareStrings field naming what a plugin asks to use; an unknown capability is the generic line.
    public static func labelKey(capability: String, params: [String: PluginJSONValue]? = nil) -> String {
        switch capability {
        case "documentCapture": return "capabilityDocumentCapture"
        case "paymentConfirmation": return "capabilityPaymentConfirmation"
        case "locationOnce":
            return params?["precision"]?.stringValue == "fine" ? "capabilityLocationFine" : "capabilityLocationCoarse"
        case "camera": return "capabilityCamera"
        case "microphone": return "capabilityMicrophone"
        case "rtcSession": return "capabilityRtcSession"
        default: return "capabilityGeneric"
        }
    }

    /// The text of ``labelKey(capability:params:)`` in `strings`.
    public static func label(_ strings: FlareStrings, capability: String, params: [String: PluginJSONValue]? = nil) -> String {
        switch labelKey(capability: capability, params: params) {
        case "capabilityDocumentCapture": return strings.capabilityDocumentCapture
        case "capabilityPaymentConfirmation": return strings.capabilityPaymentConfirmation
        case "capabilityLocationFine": return strings.capabilityLocationFine
        case "capabilityLocationCoarse": return strings.capabilityLocationCoarse
        case "capabilityCamera": return strings.capabilityCamera
        case "capabilityMicrophone": return strings.capabilityMicrophone
        case "capabilityRtcSession": return strings.capabilityRtcSession
        default: return strings.capabilityGeneric
        }
    }

    /// Whether the consent offers "Always allow": a one-time location is confirmed every time.
    public static func allowsAlways(_ capability: String) -> Bool { capability != "locationOnce" }
}

// MARK: Payment confirmation

/// The order the engine hands the host (`confirmPayment.order`).
public struct FlarePaymentOrder: Codable, Equatable, Sendable {
    public let orderId: String
    /// Decimal string, up to 18 fraction digits.
    public let amount: String
    public let currency: String
    public let payee: String
    public let title: String
    /// Server clock.
    public let expiresAtMs: Int64
    /// The plugin's transient operation; the kit never reads it.
    public let operation: String?

    public init(orderId: String, amount: String, currency: String, payee: String, title: String, expiresAtMs: Int64,
                operation: String? = nil) {
        self.orderId = orderId; self.amount = amount; self.currency = currency; self.payee = payee; self.title = title
        self.expiresAtMs = expiresAtMs; self.operation = operation
    }
}

public enum FlarePaymentRules {
    private static let prefix = ["CNY": "¥", "USD": "$", "EUR": "€", "GBP": "£", "JPY": "JP¥", "HKD": "HK$"]

    /// The amount as the confirmation draws it: the currency's symbol (or the code after the number), the integer
    /// part grouped by three, the fraction exactly as written. Never a Double. nil: not a plain non-negative decimal.
    public static func amountText(_ amount: String, currency: String) -> String? {
        let parts = amount.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 1 || parts.count == 2 else { return nil }
        let whole = parts[0]
        guard !whole.isEmpty, whole.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
        var fraction: Substring?
        if parts.count == 2 {
            let f = parts[1]
            guard !f.isEmpty, f.count <= 18, f.utf8.allSatisfy({ (48...57).contains($0) }) else { return nil }
            fraction = f
        }
        var grouped = ""
        for (i, ch) in whole.enumerated() {
            if i > 0, (whole.count - i) % 3 == 0 { grouped.append(",") }
            grouped.append(ch)
        }
        let number = fraction.map { "\(grouped).\($0)" } ?? grouped
        let code = currency.trimmingCharacters(in: .whitespaces).uppercased()
        if let symbol = prefix[code] { return symbol + number }
        return code.isEmpty ? number : "\(number) \(code)"
    }

    /// What is left of an order: whole seconds rounded up, mm:ss under an hour, h:mm:ss from an hour on.
    public static func countdown(remainingMs: Int64) -> (text: String, expired: Bool) {
        guard remainingMs > 0 else { return ("00:00", true) }
        let total = (remainingMs + 999) / 1000
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        let two = { (n: Int64) in n < 10 ? "0\(n)" : "\(n)" }
        return (hours > 0 ? "\(hours):\(two(minutes)):\(two(seconds))" : "\(two(minutes)):\(two(seconds))", false)
    }
}

// MARK: Document capture

/// Which side of a document the capture takes.
public enum FlareDocumentSide: String, Codable, Sendable, CaseIterable {
    case front, back, holding

    /// The viewfinder frame's width over height: an ID-1 card for front and back, 3:4 portrait for holding.
    public var frameAspect: CGFloat { self == .holding ? 0.75 : 1.585 }
    public var fileName: String { "document-\(rawValue).jpg" }
}

/// The photo the capture hands the host: `captureDocument`'s `{file}`.
public struct FlareCapturedDocument: Equatable, Sendable {
    public let fileName: String
    public let contentType: String
    public let bytes: Data
    /// The engine's `{file}` shape (bytes as a number list).
    public var json: [String: Any] { ["fileName": fileName, "contentType": contentType, "bytes": bytes.map { Int($0) }] }
}

public enum FlareDocumentProcessError: String, Error, Sendable { case tooLarge, failed, notAccepted }

public enum FlareDocumentRules {
    /// The (longest edge, JPEG quality) steps the kit tries until the photo fits; none fits: too large.
    public static let compressionPlan: [(edge: Int, quality: Double)] = [
        (2048, 0.86), (2048, 0.72), (2048, 0.58), (1600, 0.72), (1600, 0.58), (1280, 0.58), (1024, 0.5),
    ]

    /// Whether an accept list takes the kit's JPEG (an empty list takes anything).
    public static func acceptsJpeg(_ accept: [String]) -> Bool {
        accept.isEmpty || accept.contains { ["image/jpeg", "image/*", "*/*"].contains($0.trimmingCharacters(in: .whitespaces).lowercased()) }
    }

    /// Whether bytes are a JPEG with an APP1 Exif segment before the scan (the engine's jpeg_has_exif).
    public static func jpegHasExif(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        guard bytes.count >= 4, bytes[0] == 0xFF, bytes[1] == 0xD8 else { return false }
        var at = 2
        let exif: [UInt8] = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]
        while at + 4 <= bytes.count {
            guard bytes[at] == 0xFF else { return false }
            let marker = bytes[at + 1]
            if marker == 0xDA || marker == 0xD9 { return false }
            let length = Int(bytes[at + 2]) << 8 | Int(bytes[at + 3])
            guard length >= 2 else { return false }
            if marker == 0xE1, at + 10 <= bytes.count, Array(bytes[(at + 4)..<(at + 10)]) == exif { return true }
            at += 2 + length
        }
        return false
    }

    /// Re-encodes a photo to a JPEG that fits `maxBytes`. ImageIO makes an upright thumbnail of each step's edge
    /// (the orientation applied to the pixels) and writes it with no properties, so nothing of the original file
    /// (EXIF, GPS, TIFF, maker notes, thumbnails) survives. Runs off the main actor.
    public static func process(_ photo: Data, side: FlareDocumentSide, maxBytes: Int,
                               accept: [String] = []) async throws -> FlareCapturedDocument {
        guard acceptsJpeg(accept) else { throw FlareDocumentProcessError.notAccepted }
        let task = Task.detached(priority: .userInitiated) { () throws -> Data in
            guard let source = CGImageSourceCreateWithData(photo as CFData, nil),
                  CGImageSourceGetCount(source) > 0 else { throw FlareDocumentProcessError.failed }
            for step in compressionPlan {
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: step.edge,
                    kCGImageSourceShouldCacheImmediately: true,
                ]
                guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                    throw FlareDocumentProcessError.failed
                }
                let out = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil)
                else { throw FlareDocumentProcessError.failed }
                // Only the quality: no metadata dictionary, so no EXIF, GPS or TIFF block is written.
                CGImageDestinationAddImage(destination, image,
                                           [kCGImageDestinationLossyCompressionQuality: step.quality] as CFDictionary)
                guard CGImageDestinationFinalize(destination) else { throw FlareDocumentProcessError.failed }
                if out.length <= maxBytes { return out as Data }
            }
            throw FlareDocumentProcessError.tooLarge
        }
        let bytes = try await task.value
        guard !jpegHasExif(bytes) else { throw FlareDocumentProcessError.failed }
        return FlareCapturedDocument(fileName: side.fileName, contentType: "image/jpeg", bytes: bytes)
    }
}

// MARK: Protected media

public enum FlarePluginProtectedMedia {
    /// The address of `url` a protected media block may draw: https (the server's grant address, `?grant=`) or
    /// data:image; never anything else.
    public static func source(_ url: String?) -> URL? {
        guard let url, !url.isEmpty else { return nil }
        if url.lowercased().hasPrefix("data:image/") { return URL(string: url) }
        guard let parsed = URL(string: url), parsed.scheme?.lowercased() == "https", parsed.host?.isEmpty == false
        else { return nil }
        return parsed
    }

    /// The address at `urlPath` (a JSON pointer) of a protected media action's result.
    public static func url(result: PluginJSONValue?, urlPath: String) -> String? {
        var value = result
        for key in urlPath.split(separator: "/", omittingEmptySubsequences: false).dropFirst() {
            value = value?[String(key)]
        }
        guard let text = value?.stringValue, !text.isEmpty else { return nil }
        return text
    }
}

// MARK: Location input

/// How precise a fix a location input takes.
public enum PluginLocationPrecision: String, Codable, Sendable, CaseIterable { case coarse, fine }

/// A location input's value (flare-plugin-protocol UiLocationValue): what the engine writes into the input when the
/// viewer's one-time location (locationOnce) completes, already truncated to the input's precision.
public struct PluginLocationValue: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let accuracyM: Int
    public let precision: PluginLocationPrecision

    public init(latitude: Double, longitude: Double, accuracyM: Int, precision: PluginLocationPrecision) {
        self.latitude = latitude; self.longitude = longitude; self.accuracyM = accuracyM; self.precision = precision
    }

    private static func places(_ value: Double) -> Int {
        if value == value.rounded() { return 0 }
        let text = "\(abs(value))"
        if text.contains("e") { return 99 }
        guard let dot = text.firstIndex(of: ".") else { return 0 }
        return text.distance(from: dot, to: text.endIndex) - 1
    }

    /// `value` as a location of `precision` (UiLocationValue::fits): the same precision, a point on the globe, at most
    /// 2 (coarse) or 5 (fine) decimal places and a whole accuracy of at least 1000 m or 1 m. Else nil.
    public static func read(_ value: PluginJSONValue?, precision: PluginLocationPrecision?) -> PluginLocationValue? {
        guard let precision, let value, value["precision"]?.stringValue == precision.rawValue,
              let lat = value["latitude"]?.numberValue, let lng = value["longitude"]?.numberValue,
              let accuracy = value["accuracyM"]?.numberValue,
              lat.isFinite, lng.isFinite, accuracy.isFinite,
              (-90...90).contains(lat), (-180...180).contains(lng) else { return nil }
        let (maxPlaces, floor): (Int, Double) = precision == .coarse ? (2, 1000) : (5, 1)
        guard places(lat) <= maxPlaces, places(lng) <= maxPlaces, accuracy == accuracy.rounded(), accuracy >= floor,
              accuracy <= Double(Int.max / 2) else { return nil }
        return PluginLocationValue(latitude: lat, longitude: lng, accuracyM: Int(accuracy), precision: precision)
    }

    public var json: PluginJSONValue {
        .object(["latitude": .number(latitude), "longitude": .number(longitude), "accuracyM": .number(Double(accuracyM)),
                 "precision": .string(precision.rawValue)])
    }

    /// The fix as the input shows it: "31.23°N, 121.47°E".
    public var text: String {
        func degrees(_ v: Double) -> String {
            let a = abs(v)
            return a == a.rounded() ? String(Int(a)) : "\(a)"
        }
        return "\(degrees(latitude))°\(latitude < 0 ? "S" : "N"), \(degrees(longitude))°\(longitude < 0 ? "W" : "E")"
    }
}

/// What a location input shows while the host locates: the host's state by input id.
public struct PluginLocationState: Equatable, Sendable {
    /// The fix the engine wrote (`{kind: "input", input, value}`).
    public var value: PluginLocationValue?
    public var locating: Bool
    public var error: String?
    public init(value: PluginLocationValue? = nil, locating: Bool = false, error: String? = nil) {
        self.value = value; self.locating = locating; self.error = error
    }
}

/// A location input's key: `locate` asks the host to run the page's locationOnce action into this input; `clear`
/// empties it (the host drops its state).
public struct PluginLocationAction: Equatable, Sendable {
    public enum Kind: String, Sendable { case locate, clear }
    public let action: Kind
    public let inputId: String
    public let input: PluginInput
    public let formValues: [String: PluginJSONValue]
}
