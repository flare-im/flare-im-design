import Foundation
import SwiftUI
import WebKit
#if canImport(UIKit)
import UIKit
import UIKit.UIGestureRecognizerSubclass
#elseif canImport(AppKit)
import AppKit
#endif

// The web bundle host (L3) for SwiftUI and UIKit. Spec: Plugin/PluginBundleHost (`FlarePluginBundleHost`).
//
// A plugin's web bundle runs in a WKWebView of its own:
// - files come only from the engine's verified cache, through a `WKURLSchemeHandler` on `flare-plugin://{pluginKey}/`
//   that serves exactly the files the engine listed (anything else is 403) with the engine's CSP and
//   `Access-Control-Allow-Origin: *` (Vite's module scripts are fetched in CORS mode);
// - the data store is `WKWebsiteDataStore.nonPersistent()`: no cookies, and web storage ends with the page;
// - the bridge is a `WKScriptMessageHandlerWithReply` named `flareBridge` (the plugin web SDK's iOS transport). It is
//   installed in the page's content world because each web view holds one bundle and only that world can reach it; a
//   message from any other frame or origin is refused. Events reach the page through `window.__flareBridgeDeliver`;
// - top-level navigation away from the entry, new windows, downloads, sub-frames and media capture are refused;
//   external links go through the bridge's `ui.openExternal`, confirmed here, https only (D-13);
// - a terminated web content process shows the crash state with Reload; the third crash of a contribution in this run
//   of the app falls back to its declarative variant.
//
// The host only moves envelopes: every check of a request (hello gate, permissions, operations, rate limits) is the
// engine's (`plugin_bundle_bridge`). The host draws what the engine hands it back (`ui.toast`, `ui.confirm`,
// `ui.openExternal`, `ui.setTitle`, `ui.resize`, `ui.navigate`, `ui.close`, `clipboard.write`) with the kit's own
// components, and records touches natively for the user-gesture rule (never the bundle's claim).
//
// The engine calls go through ``FlarePluginBundleCalls``: the app (or the Flutter plugin) forwards each route to its
// core SDK and returns the answer as it came. ``FlarePluginBundleHostController`` owns the web view and the session and
// is usable without SwiftUI; ``FlarePluginBundleHost`` draws it in SwiftUI and ``FlarePluginBundleHostViewController``
// in UIKit (a Flutter platform view embeds the latter).

// MARK: - Runtime

/// The bundle runtime this host reports in `plugin.set_host_profile` (`bundleRuntime`).
public enum FlarePluginBundleRuntime {
    /// The bridge protocol version this host speaks.
    public static let bridge = 1
    /// The web engine's name in the profile.
    public static let engine = "wkwebview"
    /// The platform floor (D-17): below it the profile carries no runtime and Core never selects a bundle variant.
    public static let minimumMajor = 16
    /// The custom scheme the bundle's files are served on.
    public static let scheme = "flare-plugin"
    /// The name of the bridge's message handler (`window.webkit.messageHandlers.flareBridge`).
    public static let handlerName = "flareBridge"

    /// `{bridge, engine, engineMajor}` for an OS of major version `osMajor`; nil below the floor.
    public static func profile(osMajor: Int) -> [String: Any]? {
        guard osMajor >= minimumMajor else { return nil }
        return ["bridge": bridge, "engine": engine, "engineMajor": osMajor]
    }

    /// This device's runtime for the host profile; nil below iOS 16 and on macOS (where the kit is only smoke-built).
    public static var current: [String: Any]? {
        #if os(iOS)
        return profile(osMajor: ProcessInfo.processInfo.operatingSystemVersion.majorVersion)
        #else
        return nil
        #endif
    }
}

// MARK: - Requests and sessions

/// Where the bundle is shown (design 8.9): a page, a card's detail, or a composer "+" form.
public enum FlarePluginBundlePresentation: String, Sendable {
    case page
    case detail
    case composerForm
}

/// What to open: `plugin_bundle_open`'s request without the theme, which the host adds.
public struct FlarePluginBundleOpenRequest: Equatable {
    public var pluginId: String
    /// The contribution whose selected variant is the bundle (a page's id is its contribution id).
    public var contributionId: String
    /// A route inside the bundle; nil opens the contribution's own route.
    public var route: String?
    public var arguments: [String: PluginJSONValue]
    public var presentation: FlarePluginBundlePresentation
    public var conversationId: String?
    /// The conversation's type as the host names it (`single`, `group`); sent only with `conversationId`.
    public var conversationType: String?
    /// BCP-47 tag the bundle reads its strings by.
    public var locale: String

    public init(pluginId: String, contributionId: String, route: String? = nil,
                arguments: [String: PluginJSONValue] = [:], presentation: FlarePluginBundlePresentation = .page,
                conversationId: String? = nil, conversationType: String? = nil, locale: String) {
        self.pluginId = pluginId; self.contributionId = contributionId; self.route = route
        self.arguments = arguments; self.presentation = presentation
        self.conversationId = conversationId; self.conversationType = conversationType; self.locale = locale
    }

    /// The route's payload, with the theme mode (`light` or `dark`); the plugin web SDK owns the token defaults.
    public func payload(mode: String) -> [String: Any] {
        var payload: [String: Any] = [
            "pluginId": pluginId, "contributionId": contributionId,
            "arguments": flarePluginBundleJSON(.object(arguments)) ?? [String: Any](),
            "presentation": presentation.rawValue, "locale": locale,
            "theme": ["mode": mode, "tokens": [String: Any]()],
        ]
        if let route, !route.isEmpty { payload["route"] = route }
        if let conversationId, !conversationId.isEmpty {
            payload["conversation"] = ["id": conversationId, "type": conversationType ?? "single"]
        }
        return payload
    }
}

/// One file the engine lets the page load.
public struct FlarePluginBundleFile: Equatable, Sendable {
    public let contentType: String
    public let size: Int
}

/// An open bundle page as `plugin_bundle_open` answered it: `{sessionId, origin, root, entry, csp, files}`.
public struct FlarePluginBundleSession: Equatable {
    public let sessionId: String
    /// `flare-plugin://{pluginKey}`.
    public let origin: String
    /// The plugin key: the origin's host, lowercase.
    public let host: String
    /// The cache directory of the verified files.
    public let root: URL
    public let entry: String
    /// The policy every response carries.
    public let csp: String
    /// The only files the scheme handler serves, by path.
    public let files: [String: FlarePluginBundleFile]

    public init?(openAnswer answer: [String: Any]) {
        let prefix = FlarePluginBundleRuntime.scheme + "://"
        guard let sessionId = answer["sessionId"] as? String, !sessionId.isEmpty, sessionId.utf8.count <= 128,
              let origin = answer["origin"] as? String, origin.hasPrefix(prefix),
              let root = answer["root"] as? String, !root.isEmpty,
              let entry = answer["entry"] as? String, FlarePluginBundleRules.isBundlePath(entry),
              let csp = answer["csp"] as? String, !csp.isEmpty,
              let list = answer["files"] as? [Any] else { return nil }
        let host = String(origin.dropFirst(prefix.count))
        guard !host.isEmpty, host.utf8.count <= 64,
              host.unicodeScalars.allSatisfy(FlarePluginBundleRules.isLowerAlphanumeric) else { return nil }
        var files: [String: FlarePluginBundleFile] = [:]
        for item in list {
            guard let file = item as? [String: Any], let path = file["path"] as? String,
                  FlarePluginBundleRules.isBundlePath(path),
                  let type = file["contentType"] as? String, !type.isEmpty,
                  let size = (file["size"] as? NSNumber)?.intValue, size >= 0 else { return nil }
            files[path] = FlarePluginBundleFile(contentType: type, size: size)
        }
        guard files[entry] != nil else { return nil }
        self.sessionId = sessionId; self.origin = origin; self.host = host
        self.root = URL(fileURLWithPath: root, isDirectory: true).standardizedFileURL
        self.entry = entry; self.csp = csp; self.files = files
    }

    /// `flare-plugin://{pluginKey}/{entry}`.
    public var entryURL: URL? { URL(string: "\(origin)/\(entry)") }
}

// MARK: - Engine calls

/// The engine routes the host calls, each with its payload; the answer is the engine's object as it came. The app
/// forwards them to its core SDK (`capability.<route>` with `{payload}`); the kit builds every payload and reads every
/// answer, so the app never parses a bridge envelope.
public struct FlarePluginBundleCalls {
    public typealias Dispatch = @MainActor (_ route: String, _ payload: [String: Any]) async throws -> [String: Any]

    /// The route names, as the engine dispatches them.
    public enum Route {
        public static let open = "plugin_bundle_open"
        public static let bridge = "plugin_bundle_bridge"
        public static let hostResult = "plugin_bundle_host_result"
        public static let hostEvent = "plugin_bundle_host_event"
        public static let close = "plugin_bundle_close"
        public static let prefetch = "plugin_bundle_prefetch"
    }

    private let dispatch: Dispatch

    public init(dispatch: @escaping Dispatch) { self.dispatch = dispatch }

    @MainActor func open(_ payload: [String: Any]) async throws -> [String: Any] {
        try await dispatch(Route.open, payload)
    }

    @MainActor func bridge(sessionId: String, envelope: String, userGesture: Bool) async throws -> [String: Any] {
        try await dispatch(Route.bridge, ["sessionId": sessionId, "envelope": envelope, "userGesture": userGesture])
    }

    @MainActor func hostResult(sessionId: String, id: String, result: [String: Any]?, error: String?) async throws -> [String: Any] {
        var payload: [String: Any] = ["sessionId": sessionId, "id": id]
        if let error { payload["error"] = error } else { payload["result"] = result ?? [String: Any]() }
        return try await dispatch(Route.hostResult, payload)
    }

    @MainActor func hostEvent(_ event: String, payload: [String: Any], sessionId: String) async throws -> [String: Any] {
        try await dispatch(Route.hostEvent, ["event": event, "payload": payload, "sessionId": sessionId])
    }

    @MainActor func close(sessionId: String) async {
        _ = try? await dispatch(Route.close, ["sessionId": sessionId])
    }

    /// `plugin_bundle_prefetch`: entry bundles fetched ahead while the device is on Wi-Fi and idle. The number fetched.
    @MainActor public func prefetch(wifi: Bool, idle: Bool) async -> Int {
        let answer = try? await dispatch(Route.prefetch, ["wifi": wifi, "idle": idle])
        return (answer?["fetched"] as? NSNumber)?.intValue ?? 0
    }
}

// MARK: - What the host does for the app

/// Where `ui.navigate` asks to go.
public enum FlarePluginBundleNavigationTarget: Equatable {
    /// A declarative page of the same plugin.
    case page(String, arguments: PluginJSONValue)
    /// Another route of the same bundle.
    case bundleRoute(String, arguments: PluginJSONValue)
}

/// Why the host gives the contribution back to its declarative variant.
public enum FlarePluginBundleFallback: Equatable {
    /// The bundle could not be opened (not offered, not downloadable, refused).
    case unavailable
    /// The page crashed ``FlarePluginBundleCrashLedger/limit`` times in this run of the app.
    case crashed
    /// The engine closed the page: `withdrawn`, `suspended`, `disabled`, `replaced` or `signedOut`.
    case closed(String)
}

/// The app's part: where a navigation goes, what a close does, and what replaces the bundle when it cannot run.
public struct FlarePluginBundleHostActions {
    /// Opens the target; false when the app cannot (answered `not_found`).
    public var navigate: (@MainActor (FlarePluginBundleNavigationTarget) -> Bool)?
    /// `ui.close`: the bundle is done; `result` is what it handed back (a composer form's operation result).
    public var close: (@MainActor (_ result: PluginJSONValue?) -> Void)?
    /// The contribution should show its declarative variant instead.
    public var fallback: (@MainActor (FlarePluginBundleFallback) -> Void)?

    public init(navigate: (@MainActor (FlarePluginBundleNavigationTarget) -> Bool)? = nil,
                close: (@MainActor (_ result: PluginJSONValue?) -> Void)? = nil,
                fallback: (@MainActor (FlarePluginBundleFallback) -> Void)? = nil) {
        self.navigate = navigate; self.close = close; self.fallback = fallback
    }
}

// MARK: - Rules

/// The host's pure rules: bundle paths, what the scheme handler serves, which navigations it allows.
public enum FlarePluginBundleRules {
    /// The largest envelope the host forwards (the engine refuses above 64 KiB with the request id).
    public static let maxEnvelopeBytes = 128 * 1024
    /// How long a touch counts as the user's gesture.
    public static let gestureWindow: TimeInterval = 5
    /// How long a page stays in the background before it is destroyed (design 8.8).
    public static let backgroundLimit: TimeInterval = 30

    /// `[a-z0-9._/-]`, at most 256 bytes, no empty, `.` or `..` segment, no segment starting with `.`.
    public static func isBundlePath(_ path: String) -> Bool {
        guard !path.isEmpty, path.utf8.count <= 256,
              path.unicodeScalars.allSatisfy({ isLowerAlphanumeric($0) || [46, 95, 47, 45].contains($0.value) })
        else { return false }
        return path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy { !$0.isEmpty && !$0.hasPrefix(".") }
    }

    /// `[a-z0-9]`.
    static func isLowerAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
        (97...122).contains(scalar.value) || (48...57).contains(scalar.value)
    }

    /// The bundle path a `flare-plugin://` address names: nil for another scheme or host, or a path that is not one.
    public static func bundlePath(of url: URL, host: String) -> String? {
        guard url.scheme?.lowercased() == FlarePluginBundleRuntime.scheme, url.host?.lowercased() == host,
              url.user == nil, url.password == nil, url.port == nil else { return nil }
        let path = String(url.path.drop(while: { $0 == "/" }))
        return isBundlePath(path) ? path : nil
    }

    /// The file `url` names, inside `session.root`, with what the engine says it is; nil for anything else.
    public static func resolve(_ url: URL, in session: FlarePluginBundleSession) -> (url: URL, file: FlarePluginBundleFile)? {
        guard let path = bundlePath(of: url, host: session.host), let file = session.files[path] else { return nil }
        let target = session.root.appendingPathComponent(path).standardizedFileURL
        let base = session.root.path.hasSuffix("/") ? session.root.path : session.root.path + "/"
        guard target.path.hasPrefix(base) else { return nil }
        return (target, file)
    }

    /// The headers of a served file.
    public static func headers(for file: FlarePluginBundleFile, csp: String) -> [String: String] {
        var headers = commonHeaders(csp: csp)
        headers["Content-Type"] = file.contentType
        headers["Content-Length"] = String(file.size)
        return headers
    }

    /// The headers of every answer, a refusal included.
    public static func commonHeaders(csp: String) -> [String: String] {
        ["Content-Security-Policy": csp,
         "Access-Control-Allow-Origin": "*",
         "X-Content-Type-Options": "nosniff",
         "Referrer-Policy": "no-referrer",
         "Cache-Control": "no-store"]
    }

    /// Only the entry, in the main frame, on this bundle's origin: the first load and a reload. Every other
    /// navigation (a link, a form, `window.top.location`, another scheme) is refused.
    public static func allowsNavigation(to url: URL?, mainFrame: Bool, host: String, entry: String) -> Bool {
        guard mainFrame, let url, let path = bundlePath(of: url, host: host) else { return false }
        return path == entry
    }

    /// An envelope's text: the object the SDK posted (or its JSON text), at most ``maxEnvelopeBytes``.
    public static func envelopeText(_ body: Any) -> String? {
        if let text = body as? String { return text.utf8.count <= maxEnvelopeBytes ? text : nil }
        guard body is [String: Any], JSONSerialization.isValidJSONObject(body),
              let data = try? JSONSerialization.data(withJSONObject: body), data.count <= maxEnvelopeBytes else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The script that hands `envelope` to the page's `window.__flareBridgeDeliver`, the text as a JSON string literal.
    public static func deliveryScript(_ envelope: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: [envelope]),
              var literal = String(data: data, encoding: .utf8), literal.count >= 2 else { return nil }
        literal = String(literal.dropFirst().dropLast())
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        return "(function(e){var d=window.__flareBridgeDeliver;if(typeof d==='function'){d(e);}})(\(literal));void 0;"
    }

    /// Whether `text` is an https address `ui.openExternal` may open (no userinfo, no spaces).
    public static func isExternalURL(_ text: String) -> URL? {
        guard text.utf8.count <= 2048, !text.contains(where: { $0.isWhitespace || $0 == "\\" }),
              let url = URL(string: text), url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else { return nil }
        return url
    }
}

/// Crashes per contribution in this run of the app (design 8.8: the third falls back to the declarative variant).
@MainActor
public enum FlarePluginBundleCrashLedger {
    public static let limit = 3
    private static var counts: [String: Int] = [:]

    private static func key(_ pluginId: String, _ contributionId: String) -> String { "\(pluginId)\u{1F}\(contributionId)" }

    /// The contribution crashed `limit` times in this run: open its declarative variant without trying the bundle.
    public static func isBlocked(pluginId: String, contributionId: String) -> Bool {
        (counts[key(pluginId, contributionId)] ?? 0) >= limit
    }

    static func recordCrash(pluginId: String, contributionId: String) -> Int {
        let k = key(pluginId, contributionId)
        counts[k, default: 0] += 1
        return counts[k] ?? 0
    }

    static func reset(pluginId: String, contributionId: String) {
        counts[key(pluginId, contributionId)] = nil
    }
}

/// Routes the engine's `plugin.bundle_event` (event 7004, `{sessionId, envelope?, close?}`) to the page it is for.
@MainActor
public enum FlarePluginBundleEvents {
    /// The core event code.
    public static let eventCode = 7004

    private final class Entry { weak var controller: FlarePluginBundleHostController?; init(_ c: FlarePluginBundleHostController) { controller = c } }
    private static var live: [String: Entry] = [:]

    static func register(_ controller: FlarePluginBundleHostController, sessionId: String) {
        live = live.filter { $0.value.controller != nil }
        live[sessionId] = Entry(controller)
    }

    static func unregister(sessionId: String) { live[sessionId] = nil }

    static func controller(_ sessionId: String) -> FlarePluginBundleHostController? { live[sessionId]?.controller }

    /// Hands the event to its page: an envelope is delivered, a `close` ends the page. False when no page on screen
    /// holds the session (the engine has already closed it on its side).
    @discardableResult
    public static func receive(_ payload: Any?) -> Bool {
        guard let event = payload as? [String: Any], let sessionId = event["sessionId"] as? String,
              let controller = controller(sessionId) else { return false }
        if let envelope = event["envelope"] as? String { controller.deliver(envelope: envelope) }
        if let reason = event["close"] as? String { controller.end(reason: reason) }
        return true
    }
}

// MARK: - Controller

/// One bundle page: its session, its web view and the host's half of the bridge. Usable without SwiftUI: a UIKit or
/// Flutter host calls ``start()``, shows ``webView``, reports ``setVisible(_:)`` and ends with ``close()``.
@MainActor
public final class FlarePluginBundleHostController: ObservableObject {
    public enum Phase: Equatable {
        case idle
        case opening
        case loading
        case ready
        /// The web content process terminated; ``reload()`` opens it again.
        case crashed
        /// Destroyed while hidden (background, memory, a newer page took its place); opens again when shown.
        case suspended
        /// It could not be opened; ``reload()`` tries again.
        case failed
        /// The engine closed it (`withdrawn`, `suspended`, `disabled`, `replaced`, `signedOut`) or the host did.
        case ended(String)
    }

    @Published public private(set) var phase: Phase = .idle
    /// The bundle's `ui.setTitle`.
    @Published public private(set) var title: String?
    /// The bundle's `ui.resize` height, while ``resizable``.
    @Published public private(set) var preferredHeight: CGFloat?
    @Published public private(set) var webView: WKWebView?
    public private(set) var session: FlarePluginBundleSession? {
        didSet { lifetime.sessionId = session?.sessionId }
    }

    public private(set) var request: FlarePluginBundleOpenRequest
    public var actions: FlarePluginBundleHostActions
    /// The kit feedback that draws `ui.toast`, `ui.confirm` and the external link confirmation; without one those
    /// requests are answered `unavailable`.
    public weak var feedback: FlareFeedback?
    public var strings = FlareStrings()
    /// Only a half-height sheet honours `ui.resize`.
    public var resizable = false
    /// Lets Safari's Web Inspector attach (debug builds only).
    public var inspectable = false

    private let calls: FlarePluginBundleCalls
    private var mode = "light"
    private var visible = false
    private var inBackground = false
    private var lastTouch: Date?
    private var generation = 0
    private var delegate: FlarePluginBundleWebDelegate?
    private var backgroundTimer: Task<Void, Never>?
    /// Ends the session and drops the observers when the controller goes away without ``close()``.
    private let lifetime: FlarePluginBundleLifetime

    /// - Parameter session: a session the app already opened (it tried the bundle before choosing the host); nil
    ///   opens one in ``start()``.
    public init(request: FlarePluginBundleOpenRequest, calls: FlarePluginBundleCalls,
                actions: FlarePluginBundleHostActions = FlarePluginBundleHostActions(),
                session: FlarePluginBundleSession? = nil) {
        self.request = request; self.calls = calls; self.actions = actions
        lifetime = FlarePluginBundleLifetime(calls: calls)
        self.session = session
        lifetime.sessionId = session?.sessionId
        observeApplication()
    }

    /// Opens the bundle with `request` and returns the session, or nil when the contribution has no bundle here
    /// (not offered, below the runtime, blocked by crashes, refused, not downloadable). The app calls it first and
    /// shows the declarative variant on nil.
    public static func open(_ request: FlarePluginBundleOpenRequest, calls: FlarePluginBundleCalls,
                            dark: Bool) async -> FlarePluginBundleSession? {
        guard !FlarePluginBundleCrashLedger.isBlocked(pluginId: request.pluginId, contributionId: request.contributionId),
              let answer = try? await calls.open(request.payload(mode: dark ? "dark" : "light")) else { return nil }
        guard let session = FlarePluginBundleSession(openAnswer: answer) else {
            if let id = answer["sessionId"] as? String { await calls.close(sessionId: id) }
            return nil
        }
        return session
    }

    /// Opens (or reopens) the page and loads it. Does nothing while it is opening, loading or shown.
    public func start() async {
        switch phase {
        case .opening, .loading, .ready, .ended: return
        case .idle, .crashed, .suspended, .failed: break
        }
        generation += 1
        let mine = generation
        if let session, webView == nil, phase == .idle {
            // The app's own open: load what it was handed.
            return load(session)
        }
        phase = .opening
        if let old = session { session = nil; FlarePluginBundleEvents.unregister(sessionId: old.sessionId); await calls.close(sessionId: old.sessionId) }
        guard mine == generation else { return }
        let opened = await Self.open(request, calls: calls, dark: mode == "dark")
        guard mine == generation else {
            if let opened { await calls.close(sessionId: opened.sessionId) }
            return
        }
        guard let opened else {
            phase = .failed
            actions.fallback?(.unavailable)
            return
        }
        session = opened
        load(opened)
    }

    /// The crash or failure state's Reload.
    public func reload() async {
        teardownWebView()
        if case .ended = phase { return }
        phase = .failed
        await start()
    }

    /// The host is done with the page (its close button, the view went away for good): the session ends.
    public func close() async {
        generation += 1
        backgroundTimer?.cancel(); backgroundTimer = nil
        teardownWebView()
        if case .ended = phase {} else { phase = .ended("closed") }
        FlarePluginBundleCrashLedger.reset(pluginId: request.pluginId, contributionId: request.contributionId)
        if let session {
            self.session = nil
            FlarePluginBundleEvents.unregister(sessionId: session.sessionId)
            await calls.close(sessionId: session.sessionId)
        }
    }

    /// The page is on screen or not (`visibility.changed`); a suspended page opens again once shown.
    public func setVisible(_ visible: Bool) {
        guard self.visible != visible else { return }
        self.visible = visible
        if visible, !inBackground, phase == .suspended { Task { await start() } }
        sendHostEvent("visibility.changed", ["visible": visible && !inBackground])
    }

    /// The app's appearance changed (`theme.changed`).
    public func setTheme(dark: Bool) {
        let mode = dark ? "dark" : "light"
        guard mode != self.mode else { return }
        self.mode = mode
        sendHostEvent("theme.changed", ["mode": mode, "tokens": [String: Any]()])
    }

    /// The app's language changed (`locale.changed`); a page opened later reads it too.
    public func setLocale(_ locale: String) {
        guard locale != request.locale, !locale.isEmpty else { return }
        request.locale = locale
        sendHostEvent("locale.changed", ["locale": locale])
    }

    /// An event envelope the engine sent (`plugin.bundle_event`).
    public func deliver(envelope: String) {
        guard let webView, phase == .loading || phase == .ready,
              let script = FlarePluginBundleRules.deliveryScript(envelope) else { return }
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    /// The engine closed the page (`close` of `plugin.bundle_event`). A page a newer one evicted opens again when
    /// shown; any other reason gives the contribution back to its declarative variant.
    public func end(reason: String) {
        generation += 1
        teardownWebView()
        if let session { FlarePluginBundleEvents.unregister(sessionId: session.sessionId) }
        session = nil
        if reason == "evicted" {
            phase = .suspended
            if visible, !inBackground { Task { await start() } }
            return
        }
        phase = .ended(reason)
        actions.fallback?(.closed(reason))
    }

    // MARK: Web view

    private func load(_ session: FlarePluginBundleSession) {
        teardownWebView()
        guard let url = session.entryURL else {
            phase = .failed
            actions.fallback?(.unavailable)
            return
        }
        FlarePluginBundleEvents.register(self, sessionId: session.sessionId)
        let view = makeWebView(session)
        webView = view
        phase = .loading
        view.load(URLRequest(url: url))
    }

    private func makeWebView(_ session: FlarePluginBundleSession) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.setURLSchemeHandler(FlarePluginBundleSchemeHandler(session: session),
                                          forURLScheme: FlarePluginBundleRuntime.scheme)
        // The page's own world: each web view holds one bundle, and the plugin web SDK reaches the handler there.
        configuration.userContentController.addScriptMessageHandler(
            FlarePluginBundleMessageHandler(controller: self, host: session.host),
            contentWorld: .page, name: FlarePluginBundleRuntime.handlerName)
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        #if os(iOS)
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.dataDetectorTypes = []
        #endif
        if #available(iOS 15.4, macOS 12.3, *) { configuration.preferences.isElementFullscreenEnabled = false }
        let view = WKWebView(frame: .zero, configuration: configuration)
        let delegate = FlarePluginBundleWebDelegate(controller: self, host: session.host, entry: session.entry)
        self.delegate = delegate
        view.navigationDelegate = delegate
        view.uiDelegate = delegate
        view.allowsLinkPreview = false
        view.allowsBackForwardNavigationGestures = false
        if #available(iOS 16.4, macOS 13.3, *) { view.isInspectable = inspectable }
        #if os(iOS)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        #endif
        view.addGestureRecognizer(FlarePluginBundleTouchRecorder { [weak self] in self?.lastTouch = Date() })
        return view
    }

    private func teardownWebView() {
        guard let view = webView else { return }
        view.stopLoading()
        view.navigationDelegate = nil
        view.uiDelegate = nil
        view.configuration.userContentController.removeAllScriptMessageHandlers()
        webView = nil
        delegate = nil
    }

    private var webViewId: ObjectIdentifier? { webView.map { ObjectIdentifier($0) } }

    private var userGesture: Bool {
        lastTouch.map { Date().timeIntervalSince($0) < FlarePluginBundleRules.gestureWindow } ?? false
    }

    func didFinish(_ view: ObjectIdentifier) {
        guard webViewId == view, phase == .loading else { return }
        phase = .ready
        sendHostEvent("visibility.changed", ["visible": visible && !inBackground])
    }

    func didFail(_ view: ObjectIdentifier) {
        guard webViewId == view, phase == .loading else { return }
        teardownWebView()
        phase = .failed
    }

    func didCrash(_ view: ObjectIdentifier) {
        guard webViewId == view else { return }
        teardownWebView()
        let count = FlarePluginBundleCrashLedger.recordCrash(pluginId: request.pluginId, contributionId: request.contributionId)
        phase = .crashed
        if count >= FlarePluginBundleCrashLedger.limit { actions.fallback?(.crashed) }
    }

    // MARK: Bridge

    /// One request from the page: forwarded to the engine as it came; the engine's answer goes back as it came, or,
    /// for what the host draws, after the host did it.
    func receive(envelope: String, from view: ObjectIdentifier?) async -> (Any?, String?) {
        guard let session, view != nil, webViewId == view,
              phase == .loading || phase == .ready else { return (nil, "unavailable") }
        let mine = generation
        do {
            let answer = try await calls.bridge(sessionId: session.sessionId, envelope: envelope, userGesture: userGesture)
            if let reply = answer["envelope"] as? String { return (reply, nil) }
            guard let host = answer["host"] as? [String: Any], let id = host["id"] as? String,
                  let method = host["method"] as? String, mine == generation else { return (nil, "unavailable") }
            let outcome = await perform(method, params: host["params"] as? [String: Any] ?? [:])
            let settled = try await calls.hostResult(sessionId: session.sessionId, id: id,
                                                     result: outcome.result, error: outcome.error)
            // The reply goes back first; then the host acts on it (`ui.close`).
            if let after = outcome.after { Task { @MainActor in after() } }
            guard let reply = settled["envelope"] as? String else { return (nil, "unavailable") }
            return (reply, nil)
        } catch {
            return (nil, "unavailable")
        }
    }

    struct HostOutcome {
        var result: [String: Any]?
        var error: String?
        var after: (@MainActor () -> Void)?
        static var done: HostOutcome { HostOutcome(result: [:]) }
        static func failed(_ code: String) -> HostOutcome { HostOutcome(result: nil, error: code) }
    }

    /// What the host draws for the engine (`{host: {id, method, params}}`). Error codes are those
    /// `plugin_bundle_host_result` takes: `cancelled`, `unavailable`, `gesture_required`, `timeout`, `not_found`.
    func perform(_ method: String, params: [String: Any]) async -> HostOutcome {
        switch method {
        case "ui.setTitle":
            title = (params["title"] as? String).map { String($0.prefix(128)) }
            return .done
        case "ui.toast":
            guard let feedback, let message = params["message"] as? String else { return .failed("unavailable") }
            let variant: ToastVariant
            switch params["kind"] as? String {
            case "success": variant = .success
            case "error": variant = .error
            default: variant = .info
            }
            feedback.toast(String(message.prefix(512)), variant: variant)
            return .done
        case "ui.confirm":
            guard let feedback, let heading = params["title"] as? String else { return .failed("unavailable") }
            let confirmed = await feedback.confirm(FlareConfirmOptions(
                title: heading, description: params["message"] as? String ?? "",
                confirmText: params["confirmLabel"] as? String))
            return HostOutcome(result: ["confirmed": confirmed])
        case "ui.resize":
            guard resizable, let height = (params["height"] as? NSNumber)?.doubleValue, height > 0 else {
                return .failed("unavailable")
            }
            preferredHeight = CGFloat(min(height, 4096))
            return .done
        case "ui.openExternal":
            guard let feedback, let text = params["url"] as? String,
                  let url = FlarePluginBundleRules.isExternalURL(text) else { return .failed("unavailable") }
            let confirmed = await feedback.confirm(FlareConfirmOptions(
                title: strings.pluginBundleExternalTitle, description: strings.pluginBundleExternalMessage,
                target: url.absoluteString, confirmText: strings.pluginBundleExternalOpen))
            guard confirmed else { return .failed("cancelled") }
            flarePluginBundleOpenExternal(url)
            return .done
        case "clipboard.write":
            guard let text = params["text"] as? String else { return .failed("unavailable") }
            flarePluginBundleCopy(text)
            return .done
        case "ui.navigate":
            guard let navigate = actions.navigate else { return .failed("unavailable") }
            let arguments = flarePluginBundleValue(params["arguments"]) ?? .object([:])
            let target: FlarePluginBundleNavigationTarget
            if let page = params["page"] as? String {
                target = .page(page, arguments: arguments)
            } else if let route = params["bundleRoute"] as? String {
                target = .bundleRoute(route, arguments: arguments)
            } else {
                return .failed("not_found")
            }
            return navigate(target) ? .done : .failed("not_found")
        case "ui.close":
            let result = flarePluginBundleValue(params["result"])
            return HostOutcome(result: [:], error: nil, after: { [weak self] in
                guard let self else { return }
                self.actions.close?(result)
                Task { await self.close() }
            })
        default:
            return .failed("unavailable")
        }
    }

    private func sendHostEvent(_ event: String, _ payload: [String: Any]) {
        guard let session, phase == .loading || phase == .ready else { return }
        let calls = self.calls
        Task { @MainActor in
            guard let answer = try? await calls.hostEvent(event, payload: payload, sessionId: session.sessionId),
                  let deliveries = answer["deliveries"] as? [[String: Any]] else { return }
            for delivery in deliveries {
                guard let id = delivery["sessionId"] as? String, let envelope = delivery["envelope"] as? String else { continue }
                FlarePluginBundleEvents.controller(id)?.deliver(envelope: envelope)
            }
        }
    }

    // MARK: Background

    private func observeApplication() {
        #if os(iOS)
        let center = NotificationCenter.default
        lifetime.observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil,
                                            queue: .main) { [weak self] _ in
            Task { @MainActor in self?.enteredBackground() }
        })
        lifetime.observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil,
                                            queue: .main) { [weak self] _ in
            Task { @MainActor in self?.enteredForeground() }
        })
        lifetime.observers.append(center.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil,
                                            queue: .main) { [weak self] _ in
            Task { @MainActor in self?.memoryWarning() }
        })
        #endif
    }

    private func enteredBackground() {
        inBackground = true
        sendHostEvent("visibility.changed", ["visible": false])
        backgroundTimer?.cancel()
        backgroundTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(FlarePluginBundleRules.backgroundLimit * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.suspend()
        }
    }

    private func enteredForeground() {
        inBackground = false
        backgroundTimer?.cancel(); backgroundTimer = nil
        guard visible else { return }
        if phase == .suspended { Task { await start() } } else { sendHostEvent("visibility.changed", ["visible": true]) }
    }

    private func memoryWarning() {
        if inBackground || !visible { Task { await suspend() } }
    }

    /// Destroys the web view and ends the session; the page's `ui.saveState` comes back in the next hello.
    private func suspend() async {
        guard phase == .loading || phase == .ready else { return }
        generation += 1
        teardownWebView()
        phase = .suspended
        if let session {
            self.session = nil
            FlarePluginBundleEvents.unregister(sessionId: session.sessionId)
            await calls.close(sessionId: session.sessionId)
        }
        if visible, !inBackground { await start() }
    }
}

/// What outlives the controller's own teardown: the open session, closed when the controller is released without
/// ``FlarePluginBundleHostController/close()``, and the notification observers.
final class FlarePluginBundleLifetime {
    private let calls: FlarePluginBundleCalls
    var sessionId: String?
    var observers: [NSObjectProtocol] = []

    init(calls: FlarePluginBundleCalls) { self.calls = calls }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        guard let sessionId else { return }
        let calls = self.calls
        Task { @MainActor in await calls.close(sessionId: sessionId) }
    }
}

// MARK: - WebKit delegates

/// Serves the bundle's verified files and nothing else.
@MainActor
final class FlarePluginBundleSchemeHandler: NSObject, WKURLSchemeHandler {
    private let session: FlarePluginBundleSession
    private var stopped = Set<ObjectIdentifier>()
    private static let queue = DispatchQueue(label: "com.flare.im.plugin-bundle.files", qos: .userInitiated)

    init(session: FlarePluginBundleSession) { self.session = session }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let request = urlSchemeTask.request
        guard let url = request.url, ["GET", "HEAD"].contains(request.httpMethod ?? "GET"),
              let resolved = FlarePluginBundleRules.resolve(url, in: session) else {
            return refuse(urlSchemeTask)
        }
        let id = ObjectIdentifier(urlSchemeTask)
        let file = resolved.file, fileURL = resolved.url, csp = session.csp
        let head = request.httpMethod == "HEAD"
        Self.queue.async {
            let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe)
            Task { @MainActor in
                // A stopped task takes no more callbacks (WebKit raises on one).
                guard !self.stopped.contains(id) else { self.stopped.remove(id); return }
                guard let data, data.count == file.size,
                      let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                                     headerFields: FlarePluginBundleRules.headers(for: file, csp: csp))
                else { return self.refuse(urlSchemeTask) }
                urlSchemeTask.didReceive(response)
                if !head { urlSchemeTask.didReceive(data) }
                urlSchemeTask.didFinish()
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        stopped.insert(ObjectIdentifier(urlSchemeTask))
    }

    private func refuse(_ task: WKURLSchemeTask) {
        guard let url = task.request.url ?? URL(string: session.origin),
              let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: "HTTP/1.1",
                                             headerFields: FlarePluginBundleRules.commonHeaders(csp: session.csp)) else {
            return task.didFailWithError(URLError(.noPermissionsToReadFile))
        }
        task.didReceive(response)
        task.didReceive(Data())
        task.didFinish()
    }
}

/// `window.webkit.messageHandlers.flareBridge`: the page's requests, refused from any other frame or origin.
@MainActor
final class FlarePluginBundleMessageHandler: NSObject, WKScriptMessageHandlerWithReply {
    private weak var controller: FlarePluginBundleHostController?
    private let host: String

    init(controller: FlarePluginBundleHostController, host: String) { self.controller = controller; self.host = host }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        let origin = message.frameInfo.securityOrigin
        guard message.frameInfo.isMainFrame, origin.protocol == FlarePluginBundleRuntime.scheme, origin.host == host,
              let envelope = FlarePluginBundleRules.envelopeText(message.body), let controller else {
            return (nil, "unavailable")
        }
        return await controller.receive(envelope: envelope, from: message.webView.map { ObjectIdentifier($0) })
    }
}

/// Keeps the page on its entry and tells the controller how loading went.
@MainActor
final class FlarePluginBundleWebDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    private weak var controller: FlarePluginBundleHostController?
    private let host: String
    private let entry: String

    init(controller: FlarePluginBundleHostController, host: String, entry: String) {
        self.controller = controller; self.host = host; self.entry = entry
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if #available(iOS 14.5, macOS 11.3, *), navigationAction.shouldPerformDownload { return .cancel }
        return FlarePluginBundleRules.allowsNavigation(
            to: navigationAction.request.url, mainFrame: navigationAction.targetFrame?.isMainFrame == true,
            host: host, entry: entry) ? .allow : .cancel
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        navigationResponse.isForMainFrame && navigationResponse.canShowMIMEType ? .allow : .cancel
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        controller?.didFinish(ObjectIdentifier(webView))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        controller?.didFail(ObjectIdentifier(webView))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        controller?.didFail(ObjectIdentifier(webView))
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        controller?.didCrash(ObjectIdentifier(webView))
    }

    /// `window.open` and `target=_blank` open nothing.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        nil
    }

    @available(iOS 15.0, macOS 12.0, *)
    func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
                 initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision {
        .deny
    }
}

/// Records the user's touches on the page for the gesture rule (`clipboard.write`, `host.capability`) without taking
/// part in the page's own gestures.
#if os(iOS)
final class FlarePluginBundleTouchRecorder: UIGestureRecognizer, UIGestureRecognizerDelegate {
    private let onTouch: @MainActor () -> Void

    init(onTouch: @escaping @MainActor () -> Void) {
        self.onTouch = onTouch
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouch()
        state = .failed
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
#elseif os(macOS)
final class FlarePluginBundleTouchRecorder: NSGestureRecognizer {
    private let onTouch: @MainActor () -> Void

    init(onTouch: @escaping @MainActor () -> Void) {
        self.onTouch = onTouch
        super.init(target: nil, action: nil)
        delaysPrimaryMouseButtonEvents = false
    }

    required init?(coder: NSCoder) { nil }

    override func mouseDown(with event: NSEvent) {
        onTouch()
        state = .failed
    }
}
#endif

private func flarePluginBundleOpenExternal(_ url: URL) {
    #if os(iOS)
    UIApplication.shared.open(url)
    #elseif os(macOS)
    NSWorkspace.shared.open(url)
    #endif
}

private func flarePluginBundleCopy(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
}

/// A kit JSON value as Foundation objects.
func flarePluginBundleJSON(_ value: PluginJSONValue) -> Any? {
    guard let data = try? JSONEncoder().encode(value) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
}

/// Foundation objects as a kit JSON value; nil for nil or anything that is not JSON.
func flarePluginBundleValue(_ object: Any?) -> PluginJSONValue? {
    guard let object, !(object is NSNull),
          let data = try? JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed]) else { return nil }
    return try? JSONDecoder().decode(PluginJSONValue.self, from: data)
}

// MARK: - Strings

public extension FlareStrings {
    /// The words for a bridge error's `messageKey` (`plugin.bridge.<code>`); nil for a key the kit has none for.
    func pluginBridgeMessage(forKey key: String) -> String? {
        switch key {
        case "plugin.bridge.invalidEnvelope": return self.pluginBridgeErrorInvalidEnvelope
        case "plugin.bridge.unsupportedBridge": return self.pluginBridgeErrorUnsupportedBridge
        case "plugin.bridge.notReady": return self.pluginBridgeErrorNotReady
        case "plugin.bridge.methodNotFound": return self.pluginBridgeErrorMethodNotFound
        case "plugin.bridge.invalidParams": return self.pluginBridgeErrorInvalidParams
        case "plugin.bridge.payloadTooLarge": return self.pluginBridgeErrorPayloadTooLarge
        case "plugin.bridge.permissionDenied": return self.pluginBridgeErrorPermissionDenied
        case "plugin.bridge.rateLimited": return self.pluginBridgeErrorRateLimited
        case "plugin.bridge.cancelled": return self.pluginBridgeErrorCancelled
        case "plugin.bridge.gestureRequired": return self.pluginBridgeErrorGestureRequired
        case "plugin.bridge.quotaExceeded": return self.pluginBridgeErrorQuotaExceeded
        case "plugin.bridge.notFound": return self.pluginBridgeErrorNotFound
        case "plugin.bridge.unavailable": return self.pluginBridgeErrorUnavailable
        case "plugin.bridge.timeout": return self.pluginBridgeErrorTimeout
        case "plugin.bridge.operationFailed": return self.pluginBridgeErrorOperationFailed
        case "plugin.bridge.revoked": return self.pluginBridgeErrorRevoked
        case "plugin.bridge.internal": return self.pluginBridgeErrorInternal
        default: return nil
        }
    }
}

// MARK: - SwiftUI

/// Draws a bundle page: the web view once it has loaded, the kit's states around it (opening, crashed with Reload,
/// could not open, closed). With `onClose` it carries its own header (``FlareScreen``: the bundle's title, else
/// `title`, and a close key), for a ``FullScreenView``; without, it fills the page it is placed in and the app's own
/// navigation shows ``FlarePluginBundleHostController/title``.
///
/// It hands the controller the environment's ``FlareFeedback`` and copy, reports the page shown or hidden, and
/// follows the colour scheme. The app ends the session (``FlarePluginBundleHostController/close()``) when the page is
/// gone for good; `onClose` does it before calling back.
public struct FlarePluginBundleHost: View {
    @ObservedObject private var controller: FlarePluginBundleHostController
    private let title: String?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareFeedback) private var feedback
    @Environment(\.flareStrings) private var strings

    public init(controller: FlarePluginBundleHostController, title: String? = nil, onClose: (() -> Void)? = nil) {
        _controller = ObservedObject(wrappedValue: controller)
        self.title = title; self.onClose = onClose
    }

    public var body: some View {
        Group {
            if let onClose {
                FlareScreen(title: controller.title ?? title ?? "", onBack: {
                    Task { await controller.close(); onClose() }
                }, surface: .surface, scroll: false, backLabel: strings.close) { content }
            } else {
                content
            }
        }
        .onAppear {
            controller.feedback = feedback
            controller.strings = strings
            controller.setTheme(dark: scheme == .dark)
            controller.setVisible(true)
            Task { await controller.start() }
        }
        .onDisappear { controller.setVisible(false) }
        .onChange(of: scheme) { controller.setTheme(dark: $0 == .dark) }
    }

    private var content: some View {
        ZStack {
            if let webView = controller.webView {
                FlarePluginBundleWebView(webView: webView)
                    .id(ObjectIdentifier(webView))
                    .opacity(controller.phase == .ready ? 1 : 0)
                    .accessibilityHidden(controller.phase != .ready)
            }
            state
        }
        .frame(maxWidth: .infinity, maxHeight: controller.resizable ? controller.preferredHeight ?? .infinity : .infinity)
    }

    @ViewBuilder private var state: some View {
        switch controller.phase {
        case .idle, .opening, .loading, .suspended:
            EmptyStateView(title: strings.pluginBundleOpening, loading: true)
        case .crashed:
            EmptyStateView(title: strings.pluginBundleCrashed, description: strings.pluginBundleCrashedHint,
                           actionText: strings.pluginBundleReload, icon: "warning", tone: .error,
                           onAction: { Task { await controller.reload() } })
        case .failed:
            EmptyStateView(title: strings.pluginBundleUnavailable, actionText: strings.retry, icon: "warning",
                           tone: .error, onAction: { Task { await controller.reload() } })
        case .ended:
            EmptyStateView(title: strings.pluginBundleClosed, icon: "info")
        case .ready:
            EmptyView()
        }
    }
}

#if os(iOS)
struct FlarePluginBundleWebView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#elseif os(macOS)
struct FlarePluginBundleWebView: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif

// MARK: - UIKit

#if os(iOS)
/// The bundle page for a UIKit host (and the Flutter plugin's iOS platform view): ``FlarePluginBundleHost`` with a
/// feedback host of its own, so `ui.toast`, `ui.confirm` and the external link confirmation are the kit's.
public final class FlarePluginBundleHostViewController: UIViewController {
    public let controller: FlarePluginBundleHostController
    private let hosting: UIHostingController<AnyView>

    /// - Parameters:
    ///   - strings: the kit copy (`FlareStrings.english` for English).
    ///   - onClose: give the page its own header with a close key (a full-screen presentation); nil for none.
    public init(controller: FlarePluginBundleHostController, strings: FlareStrings = FlareStrings(),
                title: String? = nil, onClose: (() -> Void)? = nil) {
        self.controller = controller
        let feedback = FlareFeedback()
        hosting = UIHostingController(rootView: AnyView(
            FlarePluginBundleHost(controller: controller, title: title, onClose: onClose)
                .flareStrings(strings)
                .flareFeedbackHost(feedback)))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        addChild(hosting)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}
#endif
