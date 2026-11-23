import Combine
import FlareIMUI
import Network
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import AppKit
import FlutterMacOS
import SwiftUI
#endif

// The Apple side of flare_plugin_bundle_host: the SwiftUI kit's host in a Flutter platform view.
// The kit host does the sandbox (its own WKWebView, the `flare-plugin://` scheme handler, a
// non-persistent store), the bridge, the lifecycle and the drawing of the host requests (toast, confirm, the external
// link confirmation, the copy); its engine calls (FlarePluginBundleCalls) go back to Dart over the
// `flare_plugin_bundle_host` channel, where the app's core SDK runs them. What only the app can do (navigate, close, fall
// back to the declarative variant) and the bundle's title go to the Dart widget over the view's own channel.

let bundleChannelName = "flare_plugin_bundle_host"
let bundleViewType = "flare_plugin_bundle_host/view"

private var bundleRuntime: [String: Any]? {
    #if os(macOS)
    // Ventura ships WebKit with Safari 16.1. Advertise the supported baseline.
    return FlarePluginBundleRuntime.profile(osMajor: FlarePluginBundleRuntime.minimumMajor)
    #else
    return FlarePluginBundleRuntime.current
    #endif
}

public final class FlarePluginBundleHostPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(macOS)
        let messenger = registrar.messenger
        #else
        let messenger = registrar.messenger()
        #endif
        let channel = FlutterMethodChannel(name: bundleChannelName, binaryMessenger: messenger)
        let plugin = FlarePluginBundleHostPlugin(channel: channel)
        registrar.addMethodCallDelegate(plugin, channel: channel)
        registrar.register(BundleViewFactory(messenger: messenger, engine: channel), withId: bundleViewType)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "runtime":
            result(bundleRuntime.flatMap(bundleJSONText))
        case "event":
            let payload = (call.arguments as? [String: Any])?["payload"] as? String
            Task { @MainActor in
                result(payload.flatMap(bundleJSONObject).map { FlarePluginBundleEvents.receive($0) } ?? false)
            }
        case "unmetered":
            BundleNetwork.unmetered { result($0) }
        case "signedIn", "signedOut":
            // Every page runs in a non-persistent data store that ends with it: nothing is kept per user.
            result(false)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - JSON text

/// An object as JSON text; nil when it is not JSON.
func bundleJSONText(_ object: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(object),
          let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
    return String(data: data, encoding: .utf8)
}

/// JSON text as an object; nil when it is not one.
func bundleJSONObject(_ text: String) -> [String: Any]? {
    guard let data = text.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
}

/// A kit JSON value as JSON text.
func bundleValueText(_ value: PluginJSONValue) -> String? {
    guard let data = try? JSONEncoder().encode(value) else { return nil }
    return String(data: data, encoding: .utf8)
}

/// The open request the Dart widget sent (`{pluginId, contributionId, route?, arguments, presentation, conversation?,
/// locale}`); nil when it is not one.
func bundleOpenRequest(_ text: String?) -> FlarePluginBundleOpenRequest? {
    guard let text, let object = bundleJSONObject(text),
          let pluginId = object["pluginId"] as? String, !pluginId.isEmpty,
          let contributionId = object["contributionId"] as? String, !contributionId.isEmpty else { return nil }
    var arguments: [String: PluginJSONValue] = [:]
    if let raw = object["arguments"] as? [String: Any], JSONSerialization.isValidJSONObject(raw),
       let data = try? JSONSerialization.data(withJSONObject: raw),
       let decoded = try? JSONDecoder().decode([String: PluginJSONValue].self, from: data) {
        arguments = decoded
    }
    let conversation = object["conversation"] as? [String: Any]
    let route = (object["route"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    return FlarePluginBundleOpenRequest(
        pluginId: pluginId, contributionId: contributionId, route: route, arguments: arguments,
        presentation: FlarePluginBundlePresentation(rawValue: object["presentation"] as? String ?? "") ?? .page,
        conversationId: (conversation?["id"] as? String).flatMap { $0.isEmpty ? nil : $0 },
        conversationType: (conversation?["type"] as? String).flatMap { $0.isEmpty ? nil : $0 },
        locale: object["locale"] as? String ?? "")
}

/// A fallback as the Dart widget reads it.
func bundleFallbackReason(_ fallback: FlarePluginBundleFallback) -> String {
    switch fallback {
    case .unavailable: return "unavailable"
    case .crashed: return "crashed"
    case .closed(let reason): return reason
    }
}

/// `ui.navigate`'s target as the Dart widget reads it (the bridge's own params).
func bundleNavigationParams(_ target: FlarePluginBundleNavigationTarget) -> [String: Any] {
    func arguments(_ value: PluginJSONValue) -> Any {
        guard let text = bundleValueText(value), let object = bundleJSONObject(text) else { return [String: Any]() }
        return object
    }
    switch target {
    case .page(let page, let value): return ["page": page, "arguments": arguments(value)]
    case .bundleRoute(let route, let value): return ["bundleRoute": route, "arguments": arguments(value)]
    }
}

/// A refusal of the engine, with the reason Dart named (`not_offered`, ...).
struct BundleEngineError: Error {
    let reason: String
}

// MARK: - Network

enum BundleNetwork {
    /// Whether the device is on Wi-Fi without Low Data Mode, read once.
    static func unmetered(_ done: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "flare.plugin-bundle.network")
        var answered = false
        monitor.pathUpdateHandler = { path in
            guard !answered else { return }
            answered = true
            monitor.cancel()
            let wifi = path.status == .satisfied && !path.isExpensive && !path.isConstrained
                && path.usesInterfaceType(.wifi)
            DispatchQueue.main.async { done(wifi) }
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Platform view

final class BundleViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let engine: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger, engine: FlutterMethodChannel) {
        self.messenger = messenger
        self.engine = engine
    }

    #if os(iOS)
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        makeView(frame: frame, id: viewId, arguments: args)
    }
    #elseif os(macOS)
    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        makeView(frame: .zero, id: viewId, arguments: args)
    }
    #endif

    private func makeView(frame: CGRect, id: Int64, arguments args: Any?) -> BundlePlatformView {
        let channel = FlutterMethodChannel(name: "\(bundleViewType)/view_\(id)", binaryMessenger: messenger)
        let params = args as? [String: Any] ?? [:]
        return MainActor.assumeIsolated {
            BundlePlatformView(frame: frame, channel: channel, engine: engine, params: params)
        }
    }

    #if os(iOS)
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
    #elseif os(macOS)
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        FlutterStandardMessageCodec.sharedInstance()
    }
    #endif
}

/// The engine's routes, run by Dart: `engine` `{route, payload}` with the payload as JSON text; Dart answers the
/// engine's object as JSON text, or an error whose code is the refusal's reason.
@MainActor
func bundleCalls(_ engine: FlutterMethodChannel) -> FlarePluginBundleCalls {
    FlarePluginBundleCalls { route, payload in
        guard let text = bundleJSONText(payload) else { throw BundleEngineError(reason: "invalid_request") }
        return try await withCheckedThrowingContinuation { continuation in
            engine.invokeMethod("engine", arguments: ["route": route, "payload": text]) { reply in
                if let error = reply as? FlutterError {
                    continuation.resume(throwing: BundleEngineError(reason: error.code))
                } else if let text = reply as? String, let object = bundleJSONObject(text) {
                    continuation.resume(returning: object)
                } else {
                    // FlutterMethodNotImplemented, or no answer at all.
                    continuation.resume(throwing: BundleEngineError(reason: "unavailable"))
                }
            }
        }
    }
}

#if os(iOS)
typealias BundleNativeView = UIView
#elseif os(macOS)
typealias BundleNativeView = NSView
#endif

@MainActor
final class BundlePlatformView: BundleNativeView {
    private let channel: FlutterMethodChannel
    private var controller: FlarePluginBundleHostController?
    private var titleWatch: AnyCancellable?
    #if os(iOS)
    private var page: FlarePluginBundleHostViewController?
    #endif

    /// The last state for the widget's `attach` (a fallback before its handler was set would be lost).
    private var lastState: [String: Any] = ["state": "opening"]

    init(frame: CGRect, channel: FlutterMethodChannel, engine: FlutterMethodChannel, params: [String: Any]) {
        self.channel = channel
        super.init(frame: frame)
        channel.setMethodCallHandler { [weak self] call, result in
            MainActor.assumeIsolated { self?.handle(call, result: result) ?? result(FlutterMethodNotImplemented) }
        }
        guard bundleRuntime != nil, let request = bundleOpenRequest(params["request"] as? String) else {
            lastState = ["state": "fallback", "reason": "unsupported"]
            return
        }
        let navigable = params["navigable"] as? Bool ?? false
        let controller = FlarePluginBundleHostController(request: request, calls: bundleCalls(engine))
        let strings = (params["english"] as? Bool ?? false) ? FlareStrings.english : FlareStrings()
        self.controller = controller
        #if os(iOS)
        let page = FlarePluginBundleHostViewController(controller: controller, strings: strings)
        self.page = page
        backgroundColor = .clear
        let hosted: UIView = page.view
        #elseif os(macOS)
        let hosted = NSHostingView(rootView: FlarePluginBundleHost(controller: controller)
            .flareStrings(strings)
            .flareFeedbackHost(FlareFeedback()))
        #endif
        setDark(params["dark"] as? Bool ?? false)
        controller.actions = FlarePluginBundleHostActions(
            navigate: { [weak self] target in
                self?.channel.invokeMethod("navigate", arguments: ["params": bundleJSONText(bundleNavigationParams(target)) ?? "{}"])
                // The Dart widget opens it; whether it can is known up front.
                return navigable
            },
            close: { [weak self] result in
                var arguments: [String: Any] = [:]
                if let text = result.flatMap(bundleValueText) { arguments["result"] = text }
                self?.channel.invokeMethod("close", arguments: arguments)
            },
            fallback: { [weak self] fallback in
                let reason = bundleFallbackReason(fallback)
                self?.lastState = ["state": "fallback", "reason": reason]
                self?.channel.invokeMethod("fallback", arguments: ["reason": reason])
            })
        titleWatch = controller.$title.removeDuplicates().sink { [weak self] title in
            guard let title, !title.isEmpty else { return }
            self?.channel.invokeMethod("title", arguments: ["title": title])
        }
        hosted.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosted)
        NSLayoutConstraint.activate([
            hosted.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosted.topAnchor.constraint(equalTo: topAnchor),
            hosted.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        channel.setMethodCallHandler(nil)
        // The controller's lifetime ends the session when the page goes without `close()`; end it here explicitly.
        if let controller {
            Task { @MainActor in await controller.close() }
        }
    }

    #if os(iOS)
    /// Makes the kit host a child of the Flutter view controller, so its SwiftUI content gets appearance calls.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let page else { return }
        if window == nil {
            if page.parent != nil {
                page.willMove(toParent: nil)
                page.removeFromParent()
            }
            return
        }
        guard page.parent == nil, let parent = nearestViewController else { return }
        parent.addChild(page)
        page.didMove(toParent: parent)
    }
    #endif

    private func setDark(_ dark: Bool) {
        #if os(iOS)
        page?.overrideUserInterfaceStyle = dark ? .dark : .light
        #elseif os(macOS)
        appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        #endif
        controller?.setTheme(dark: dark)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "attach":
            result(lastState)
        case "setDark":
            setDark(args["dark"] as? Bool ?? false)
            result(nil)
        case "setLocale":
            if let locale = args["locale"] as? String, !locale.isEmpty { controller?.setLocale(locale) }
            result(nil)
        case "reload":
            if let controller { Task { await controller.reload() } }
            result(nil)
        case "pause", "resume":
            #if os(macOS)
            controller?.setVisible(call.method == "resume" && window != nil)
            #endif
            // The controller follows the app's foreground itself.
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

#if os(iOS)
extension BundlePlatformView: FlutterPlatformView {
    nonisolated func view() -> UIView { self }
}

private extension UIView {
    var nearestViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return nil
    }
}
#endif
