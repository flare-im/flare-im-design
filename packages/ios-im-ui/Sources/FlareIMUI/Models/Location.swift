import Foundation

/// The map service a tenant chose for locations (`chat.location`'s `provider`). It decides which web map a location
/// opens on the web; the native kits open the platform's own maps.
public enum FlareLocationProvider: String, Sendable, Equatable, CaseIterable {
    case osm
    case amap
}

/// A point on the map, WGS-84, as a location message stores it.
public struct FlareLocationCoordinate: Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude; self.longitude = longitude
    }
}

/// What reverse geocoding a coordinate gives: the place's name and its address line.
public struct FlareLocationAddress: Sendable, Equatable {
    public let title: String
    public let address: String
    public init(title: String, address: String = "") {
        self.title = title; self.address = address
    }
}

/// One place: a row of ``LocationPickerView``'s list, and what the picker sends. `distanceM` is how far it is from
/// the picker's centre, when the search knows.
public struct FlareLocationPlace: Identifiable, Sendable, Equatable {
    /// The id of the picker's first row, the user's own position.
    public static let currentId = "current"

    public let id: String
    public let title: String
    public let address: String
    public let latitude: Double
    public let longitude: Double
    public let distanceM: Double?
    public init(id: String, title: String, address: String = "", latitude: Double, longitude: Double,
                distanceM: Double? = nil) {
        self.id = id; self.title = title; self.address = address
        self.latitude = latitude; self.longitude = longitude; self.distanceM = distanceM
    }

    public var coordinate: FlareLocationCoordinate { .init(latitude: latitude, longitude: longitude) }
}

/// The location rules every kit shares (`spec/location-vectors.json`): the default links a location opens, the
/// coordinate line shown when there is no map, and a place's distance.
public enum FlareLocationFormat {
    /// The zoom the OpenStreetMap link opens at (`osmZoom`).
    public static let osmZoom = 17

    /// Whether the pair is a coordinate: finite, latitude within ±90 and longitude within ±180.
    public static func isValid(latitude: Double?, longitude: Double?) -> Bool {
        guard let latitude, let longitude, latitude.isFinite, longitude.isFinite else { return false }
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    /// A coordinate in a link: fixed to 6 decimals, trailing zeros and a trailing point dropped, `-0` written `0`.
    public static func coordinate(_ value: Double) -> String {
        var text = String(format: "%.6f", value)
        if text.contains(".") {
            while text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
        }
        return text == "-0" ? "0" : text
    }

    /// The title as a link carries it: trimmed, then UTF-8 percent-encoded except `A-Z a-z 0-9 - . _ ~`, in capital
    /// hex. Nil for a blank title.
    public static func encodedTitle(_ title: String?) -> String? {
        guard let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        var out = ""
        for byte in trimmed.utf8 {
            switch byte {
            case UInt8(ascii: "A")...UInt8(ascii: "Z"), UInt8(ascii: "a")...UInt8(ascii: "z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "-"), UInt8(ascii: "."), UInt8(ascii: "_"), UInt8(ascii: "~"):
                out.append(Character(Unicode.Scalar(byte)))
            default:
                out += String(format: "%%%02X", byte)
            }
        }
        return out
    }

    /// The web map for `provider`: OpenStreetMap's marker link, or Amap's marker (told the point is WGS-84). Nil for
    /// an invalid coordinate.
    public static func webLink(latitude: Double, longitude: Double, title: String? = nil,
                               provider: FlareLocationProvider = .osm) -> String? {
        guard isValid(latitude: latitude, longitude: longitude) else { return nil }
        let lat = coordinate(latitude), lng = coordinate(longitude)
        switch provider {
        case .osm:
            return "https://www.openstreetmap.org/?mlat=\(lat)&mlon=\(lng)#map=\(osmZoom)/\(lat)/\(lng)"
        case .amap:
            let name = encodedTitle(title).map { "&name=\($0)" } ?? ""
            return "https://uri.amap.com/marker?position=\(lng),\(lat)\(name)&coordinate=wgs84&callnative=0"
        }
    }

    /// Apple Maps at the point, named by the title, else by the coordinate pair. Nil for an invalid coordinate.
    public static func appleLink(latitude: Double, longitude: Double, title: String? = nil) -> String? {
        guard isValid(latitude: latitude, longitude: longitude) else { return nil }
        let pair = "\(coordinate(latitude)),\(coordinate(longitude))"
        return "http://maps.apple.com/?ll=\(pair)&q=\(encodedTitle(title) ?? pair)"
    }

    /// The `geo:` URI Android's map apps take, with the title as the pin's label when there is one. Nil for an
    /// invalid coordinate.
    public static func geoLink(latitude: Double, longitude: Double, title: String? = nil) -> String? {
        guard isValid(latitude: latitude, longitude: longitude) else { return nil }
        let pair = "\(coordinate(latitude)),\(coordinate(longitude))"
        return "geo:\(pair)?q=\(pair)\(encodedTitle(title).map { "(\($0))" } ?? "")"
    }

    /// The coordinate line shown without a map: each number fixed to 5 decimals, joined by ", ". Nil for an invalid
    /// coordinate.
    public static func label(latitude: Double, longitude: Double) -> String? {
        guard isValid(latitude: latitude, longitude: longitude) else { return nil }
        func fixed(_ value: Double) -> String {
            let text = String(format: "%.5f", value)
            return text == "-0.00000" ? "0.00000" : text
        }
        return "\(fixed(latitude)), \(fixed(longitude))"
    }

    /// A place's distance: whole metres below 1000 (rounded half up), else kilometres to one decimal. Nil for a
    /// missing, negative or non-finite value.
    public static func distance(_ meters: Double?) -> String? {
        guard let meters, meters.isFinite, meters >= 0 else { return nil }
        let rounded = meters.rounded(.toNearestOrAwayFromZero)
        if rounded < 1000 { return "\(Int(rounded))m" }
        return String(format: "%.1fkm", meters / 1000)
    }

    /// What the picker asks `previewUrl` for: the map area's logical size times the screen scale clamped to 1...2,
    /// each rounded half up — device pixels (`spec/location-vectors.json` previewSize).
    public static func previewPixels(width: Double, height: Double, scale: Double) -> (width: Int, height: Int) {
        let factor = min(max(scale.isFinite ? scale : 1, 1), 2)
        func pixels(_ points: Double) -> Int {
            guard points.isFinite, points > 0 else { return 0 }
            return Int((points * factor).rounded(.toNearestOrAwayFromZero))
        }
        return (pixels(width), pixels(height))
    }
}
