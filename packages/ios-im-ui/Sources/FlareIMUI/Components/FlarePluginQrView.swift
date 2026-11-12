import SwiftUI

public struct FlareScanSurfaceHints: Equatable, Sendable {
    public let secure: Bool
    public let maxBrightness: Bool
    public init(secure: Bool, maxBrightness: Bool) { self.secure = secure; self.maxBrightness = maxBrightness }
}
/// A plugin supplies only an opaque token; the trusted host binds its plugin id to encoding.
public struct FlarePluginQrView: View {
    private let token: String?
    private let ttlMs: Double?
    private let caption: String?
    private let encodeQr: (@Sendable (String) async throws -> String)?
    @State private var payload: String?
    @State private var expired = false
    @State private var failed = false
    @State private var expiresAt: Double?
    @Environment(\.flareStrings) private var strings
    @Environment(\.scenePhase) private var scenePhase
    public init(token: String?, ttlMs: Double? = nil, caption: String? = nil, encodeQr: (@Sendable (String) async throws -> String)? = nil) { self.token = token; self.ttlMs = ttlMs; self.caption = caption; self.encodeQr = encodeQr }
    public var body: some View {
        VStack {
            if token?.isEmpty == false {
                if let payload, scenePhase == .active, expiresAt == nil || ProcessInfo.processInfo.systemUptime < expiresAt! { FlareQrMatrix(payload: payload, label: caption ?? strings.qrCode) }
                else if expired || (expiresAt.map { ProcessInfo.processInfo.systemUptime >= $0 } ?? false) { Text(strings.scanCodeExpired) }
                else if failed { Text(strings.qrCardUnavailable) }
                else { ProgressView(strings.scanPreparing) }
                if let caption { Text(caption) }
            }
        }.task(id: "\(token ?? "")/\(ttlMs ?? -1)") {
            payload = nil; expired = false; failed = false; expiresAt = nil
            guard let token, !token.isEmpty else { return }
            let receivedAt = ProcessInfo.processInfo.systemUptime
            guard ttlMs == nil || (ttlMs!.isFinite && ttlMs! > 0) else { expired = true; return }
            expiresAt = ttlMs.map { receivedAt + $0 / 1000 }
            do {
                guard let encodeQr else { failed = true; return }
                let url = try await encodeQr(token)
                guard !Task.isCancelled else { return }
                let remaining = ttlMs.map { $0 - (ProcessInfo.processInfo.systemUptime - receivedAt) * 1000 }
                guard remaining == nil || remaining! > 0 else { expired = true; return }
                payload = url
                if let remaining {
                    try await Task.sleep(nanoseconds: UInt64(min(remaining, 86_400_000) * 1_000_000))
                    guard !Task.isCancelled else { return }
                    payload = nil; expired = true
                }
            } catch { if !Task.isCancelled { failed = true } }
        }.onChange(of: scenePhase) { phase in
            if phase == .active, let expiresAt, ProcessInfo.processInfo.systemUptime >= expiresAt {
                payload = nil; expired = true
            }
        }
    }
}
