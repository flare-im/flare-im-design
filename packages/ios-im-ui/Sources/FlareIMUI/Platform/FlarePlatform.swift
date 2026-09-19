import Foundation
import SwiftUI

// Layer 5 — Platform Contract (shared truth: spec/platform-contract.json).
// One capability record, one adapter interface and one error model. The host
// declares what it can do and performs the native work (PhotosPicker,
// fileImporter, ShareLink …); components read capabilities through
// `@Environment(\.flarePlatform)` and never branch on platform identity.

public enum FlarePlatformKind: String, Sendable { case web, tauri, ios, android, flutter }

public enum FlareCapabilitySupport: String, Sendable { case supported, fallback, unsupported }

public enum FlarePointerKind: String, Sendable { case fine, coarse, mixed, unknown }

public enum FlarePlatformErrorCode: String, Sendable {
    case unsupported = "UNSUPPORTED"
    case cancelled = "CANCELLED"
    case permissionDenied = "PERMISSION_DENIED"
    case timeout = "TIMEOUT"
    case failed = "FAILED"
}

public struct FlarePlatformCapabilities: Equatable, Sendable {
    public var pointer: FlarePointerKind
    public var hover: Bool
    public var contextMenu: Bool
    public var keyboardShortcut: Bool
    /// Contextual layers present as bottom sheets (phone form factor).
    public var bottomSheet: Bool
    public var nativeBack: Bool
    public var safeArea: Bool
    public var filePicker: FlareCapabilitySupport
    public var imagePicker: FlareCapabilitySupport
    public var share: FlareCapabilitySupport

    public init(pointer: FlarePointerKind = .unknown, hover: Bool = false, contextMenu: Bool = false,
                keyboardShortcut: Bool = false, bottomSheet: Bool = false, nativeBack: Bool = false,
                safeArea: Bool = false, filePicker: FlareCapabilitySupport = .unsupported,
                imagePicker: FlareCapabilitySupport = .unsupported, share: FlareCapabilitySupport = .unsupported) {
        self.pointer = pointer; self.hover = hover; self.contextMenu = contextMenu
        self.keyboardShortcut = keyboardShortcut; self.bottomSheet = bottomSheet
        self.nativeBack = nativeBack; self.safeArea = safeArea
        self.filePicker = filePicker; self.imagePicker = imagePicker; self.share = share
    }

    /// What an iPhone / iPad determines on its own: coarse pointer, sheet-first
    /// below the compact width, safe area always; a hardware pointer (iPad
    /// trackpad) turns hover / context menus on. Pickers stay unsupported until
    /// the host adapter declares them.
    public static func ios(width: CGFloat = .infinity, hasPointer: Bool = false) -> FlarePlatformCapabilities {
        FlarePlatformCapabilities(
            pointer: hasPointer ? .mixed : .coarse,
            hover: hasPointer, contextMenu: hasPointer, keyboardShortcut: hasPointer,
            bottomSheet: width < 600, nativeBack: false, safeArea: true
        )
    }
}

/// The contract's error model; `cause` keeps the original error.
public struct FlarePlatformError: Error, Equatable, CustomStringConvertible {
    public let code: FlarePlatformErrorCode
    public let message: String?
    public let cause: Error?

    public init(_ code: FlarePlatformErrorCode, message: String? = nil, cause: Error? = nil) {
        self.code = code; self.message = message; self.cause = cause
    }

    public static func == (lhs: FlarePlatformError, rhs: FlarePlatformError) -> Bool {
        lhs.code == rhs.code && lhs.message == rhs.message
    }

    public var description: String { "FlarePlatformError(\(code.rawValue)\(message.map { ": \($0)" } ?? ""))" }
}

/// `.success(value)` or `.failure(error)` — the only two shapes an adapter operation returns.
public typealias FlarePlatformResult<T> = Result<T, FlarePlatformError>

public extension Result where Failure == FlarePlatformError {
    var isOk: Bool { if case .success = self { return true } else { return false } }
    var valueOrNil: Success? { try? get() }
    var errorOrNil: FlarePlatformError? { if case let .failure(error) = self { return error } else { return nil } }
    var code: FlarePlatformErrorCode? { errorOrNil?.code }
    static func unsupported(_ operation: String) -> Self {
        .failure(FlarePlatformError(.unsupported, message: "\(operation) is not provided by this host"))
    }
}

public struct FlarePickedFile: Equatable, Sendable {
    public let name: String
    public let size: Int?
    public let mimeType: String?
    /// Native filesystem path when the platform exposes one.
    public let path: String?
    /// A URL / uri string when the platform exposes one instead of a path.
    public let uri: String?
    public init(name: String, size: Int? = nil, mimeType: String? = nil, path: String? = nil, uri: String? = nil) {
        self.name = name; self.size = size; self.mimeType = mimeType; self.path = path; self.uri = uri
    }
}

public struct FlarePickFilesOptions: Sendable {
    public let multiple: Bool
    /// MIME types or extensions, e.g. ["image/*", ".pdf"].
    public let accept: [String]
    public init(multiple: Bool = false, accept: [String] = []) { self.multiple = multiple; self.accept = accept }
}

public struct FlarePickImagesOptions: Sendable {
    public let multiple: Bool
    public let video: Bool
    public init(multiple: Bool = false, video: Bool = false) { self.multiple = multiple; self.video = video }
}

public struct FlareSharePayload: Sendable {
    public let title: String?
    public let text: String?
    public let url: String?
    public let files: [FlarePickedFile]
    public init(title: String? = nil, text: String? = nil, url: String? = nil, files: [FlarePickedFile] = []) {
        self.title = title; self.text = text; self.url = url; self.files = files
    }
}

public struct FlareSafeAreaInsets: Equatable, Sendable {
    public let top: CGFloat, right: CGFloat, bottom: CGFloat, left: CGFloat
    public init(top: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0) {
        self.top = top; self.right = right; self.bottom = bottom; self.left = left
    }
}

/// Host-implemented native operations. Every operation defaults to
/// UNSUPPORTED, so a host implements only what it can do and declares it in
/// `capabilities`.
public protocol FlarePlatformAdapter {
    var kind: FlarePlatformKind { get }
    var capabilities: FlarePlatformCapabilities { get }
    func pickFiles(_ options: FlarePickFilesOptions) async -> FlarePlatformResult<[FlarePickedFile]>
    func pickImages(_ options: FlarePickImagesOptions) async -> FlarePlatformResult<[FlarePickedFile]>
    func share(_ payload: FlareSharePayload) async -> FlarePlatformResult<Void>
    /// Returns the unsubscribe, or nil when the host has no native back to intercept.
    func onNativeBack(_ handler: @escaping () -> Bool) -> (() -> Void)?
    func safeAreaInsets() -> FlareSafeAreaInsets
}

public extension FlarePlatformAdapter {
    var kind: FlarePlatformKind { .ios }
    func pickFiles(_ options: FlarePickFilesOptions) async -> FlarePlatformResult<[FlarePickedFile]> { .unsupported("pickFiles") }
    func pickImages(_ options: FlarePickImagesOptions) async -> FlarePlatformResult<[FlarePickedFile]> { .unsupported("pickImages") }
    func share(_ payload: FlareSharePayload) async -> FlarePlatformResult<Void> { .unsupported("share") }
    func onNativeBack(_ handler: @escaping () -> Bool) -> (() -> Void)? { nil }
    func safeAreaInsets() -> FlareSafeAreaInsets { FlareSafeAreaInsets() }
}

/// The adapter in effect when the host installs none: nothing native is available.
public struct FlareUnsupportedPlatformAdapter: FlarePlatformAdapter {
    public let capabilities: FlarePlatformCapabilities
    public init(capabilities: FlarePlatformCapabilities = .ios()) { self.capabilities = capabilities }
}

private func matches(_ pattern: String, _ text: String) -> Bool {
    text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
}

/// Map a thrown error to the contract's error model: `CancellationError` /
/// `NSUserCancelledError` / `NSURLErrorCancelled` → CANCELLED, `NSURLErrorTimedOut`
/// → TIMEOUT, Cocoa no-permission codes → PERMISSION_DENIED,
/// `NSFeatureUnsupportedError` → UNSUPPORTED, anything else FAILED (message
/// heuristics as a last resort).
public func normalizeFlarePlatformError(_ error: Error) -> FlarePlatformError {
    if let platform = error as? FlarePlatformError { return platform }
    let nsError = error as NSError
    let message = nsError.localizedDescription
    func result(_ code: FlarePlatformErrorCode) -> FlarePlatformError { FlarePlatformError(code, message: message, cause: error) }
    if error is CancellationError { return result(.cancelled) }
    switch (nsError.domain, nsError.code) {
    case (NSCocoaErrorDomain, NSUserCancelledError), (NSURLErrorDomain, NSURLErrorCancelled):
        return result(.cancelled)
    case (NSURLErrorDomain, NSURLErrorTimedOut):
        return result(.timeout)
    case (NSCocoaErrorDomain, NSFileReadNoPermissionError), (NSCocoaErrorDomain, NSFileWriteNoPermissionError):
        return result(.permissionDenied)
    case (NSCocoaErrorDomain, NSFeatureUnsupportedError):
        return result(.unsupported)
    default:
        break
    }
    let text = "\(nsError.domain) \(message)"
    if matches("time(d)? ?out", text) { return result(.timeout) }
    if matches("cancel(l)?ed|abort", text) { return result(.cancelled) }
    if matches("permission|denied|not allowed", text) { return result(.permissionDenied) }
    if matches("unsupported|not supported|not implemented", text) { return result(.unsupported) }
    return result(.failed)
}

/// Resolve to TIMEOUT when the native surface does not answer within `milliseconds`.
public func withFlarePlatformTimeout<T: Sendable>(
    milliseconds: UInt64,
    _ operation: @escaping @Sendable () async -> FlarePlatformResult<T>
) async -> FlarePlatformResult<T> {
    await withTaskGroup(of: FlarePlatformResult<T>.self) { group in
        group.addTask { await operation() }
        group.addTask {
            try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
            return .failure(FlarePlatformError(.timeout, message: "platform operation exceeded \(milliseconds)ms"))
        }
        let first = await group.next() ?? .failure(FlarePlatformError(.failed, message: "no result"))
        group.cancelAll()
        return first
    }
}

/// Run an adapter operation through the contract: a thrown error is normalized
/// and an optional timeout applies.
public func callFlarePlatform<T: Sendable>(
    timeoutMilliseconds: UInt64? = nil,
    _ operation: @escaping @Sendable () async throws -> FlarePlatformResult<T>
) async -> FlarePlatformResult<T> {
    let guarded: @Sendable () async -> FlarePlatformResult<T> = {
        do { return try await operation() } catch { return .failure(normalizeFlarePlatformError(error)) }
    }
    if let timeoutMilliseconds { return await withFlarePlatformTimeout(milliseconds: timeoutMilliseconds, guarded) }
    return await guarded()
}

private struct FlarePlatformKey: EnvironmentKey {
    static let defaultValue: any FlarePlatformAdapter = FlareUnsupportedPlatformAdapter()
}

public extension EnvironmentValues {
    /// The host adapter in effect (the unsupported fallback when none is installed).
    var flarePlatform: any FlarePlatformAdapter {
        get { self[FlarePlatformKey.self] }
        set { self[FlarePlatformKey.self] = newValue }
    }
}

public extension View {
    /// Installs the host's platform adapter for this subtree. Call once near the app root.
    func flarePlatform(_ adapter: any FlarePlatformAdapter) -> some View {
        environment(\.flarePlatform, adapter)
    }
}
