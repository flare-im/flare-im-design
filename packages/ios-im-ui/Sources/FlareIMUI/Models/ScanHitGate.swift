import Foundation

public struct FlareScanPoint: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}
public struct FlareScanMarkerBounds: Equatable, Sendable {
    public let left: Double
    public let top: Double
    public let width: Double
    public let height: Double
}
/// Decoder coordinates are untrusted; missing corners keep the choice keyboard-accessible.
public func flareScanMarkerBounds(_ corners: [FlareScanPoint]) -> FlareScanMarkerBounds {
    let points = corners.filter { $0.x.isFinite && $0.y.isFinite }
    let left = max(0, min(1, points.map(\.x).min() ?? 0))
    let top = max(0, min(1, points.map(\.y).min() ?? 0))
    let right = max(left, min(1, points.map(\.x).max() ?? 1))
    let bottom = max(top, min(1, points.map(\.y).max() ?? 1))
    return .init(left: left, top: top, width: right - left, height: bottom - top)
}

public func flareScanPluginCanRefresh(visible: Bool, foreground: Bool, loading: Bool, refreshing: Bool, busy: Bool, interaction: Bool) -> Bool {
    visible && foreground && !loading && !refreshing && !busy && !interaction
}
public struct FlareScanCode: Equatable, Sendable {
    public let raw: String
    public let corners: [FlareScanPoint]
    public init(raw: String, corners: [FlareScanPoint] = []) { self.raw = raw; self.corners = corners }
}
public enum FlareScanHit: Equatable, Sendable {
    case ignore
    case lock(code: FlareScanCode, ready: Bool)
    case choose(codes: [FlareScanCode])
}
/// Camera-independent, deterministic arbitration; see spec/scan-gate-vectors.json.
public final class FlareScanHitGate {
    private var phase = "idle"
    private var startedAt: Double = 0
    private var lastAt = -Double.infinity
    private var candidates: [FlareScanCode] = []
    private var suppressed: Set<String> = []
    private var absentSince: [String: Double] = [:]
    private var selected: String?
    public init() {}

    public func observe(codes: [FlareScanCode], tsMs: Double) -> FlareScanHit {
        guard tsMs.isFinite, tsMs >= lastAt else { return .ignore }
        lastAt = tsMs
        let visible = Set(codes.filter { !$0.raw.isEmpty }.map(\.raw))
        for raw in suppressed {
            if let absentAt = absentSince[raw], tsMs - absentAt >= 1500 { suppressed.remove(raw); absentSince.removeValue(forKey: raw) }
            else if visible.contains(raw) { absentSince.removeValue(forKey: raw) }
            else if let absentAt = absentSince[raw] {
                if tsMs - absentAt >= 1500 { suppressed.remove(raw); absentSince.removeValue(forKey: raw) }
            } else { absentSince[raw] = tsMs }
        }
        guard phase != "busy", phase != "choosing" else { return .ignore }
        let available = codes.filter { !$0.raw.isEmpty && !suppressed.contains($0.raw) }
        if phase == "idle" {
            guard let first = available.first else { return .ignore }
            phase = "collecting"; startedAt = tsMs; candidates = []
            for code in available { merge(code) }
            return .lock(code: first, ready: false)
        }
        for code in available { merge(code) }
        guard tsMs - startedAt >= 150 else { return .ignore }
        if candidates.count > 1 { phase = "choosing"; return .choose(codes: candidates) }
        guard let code = candidates.first else { return .ignore }
        phase = "busy"; selected = code.raw
        return .lock(code: code, ready: true)
    }
    private func merge(_ code: FlareScanCode) {
        if let index = candidates.firstIndex(where: { $0.raw == code.raw }) { candidates[index] = code }
        else { candidates.append(code) }
    }
    public func select(_ raw: String) -> FlareScanHit {
        guard phase == "choosing", let code = candidates.first(where: { $0.raw == raw }) else { return .ignore }
        phase = "busy"; selected = raw
        return .lock(code: code, ready: true)
    }
    public func dismiss() {
        for raw in selected.map({ [$0] }) ?? candidates.map(\.raw) { suppressed.insert(raw); absentSince.removeValue(forKey: raw) }
        candidates = []; selected = nil; phase = "idle"
    }
}
