import SwiftUI
import WebKit
import XCTest
@testable import FlareIMUI

/// The web bundle host's rules and its half of the bridge, without a web view: what the scheme handler serves and how,
/// which navigations it allows, how envelopes are carried, the runtime floor, and what the host draws for the engine.
/// Spec: Plugin/PluginBundleHost.
final class PluginBundleHostTests: XCTestCase {
    private let csp = "default-src 'none'; script-src flare-plugin://abc; connect-src 'none'; frame-ancestors 'none'"

    private func answer(entry: String = "index.html") -> [String: Any] {
        ["sessionId": "s-1", "origin": "flare-plugin://abc", "root": "/tmp/plugin_bundles/0f0f", "entry": entry,
         "csp": csp, "hello": [String: Any](),
         "files": [["path": "index.html", "contentType": "text/html", "size": 120],
                   ["path": "assets/app.js", "contentType": "text/javascript", "size": 4096],
                   ["path": "bundle.json", "contentType": "application/json", "size": 200]]]
    }

    // MARK: Runtime

    func testTheRuntimeIsReportedOnlyFromIOS16() {
        XCTAssertNil(FlarePluginBundleRuntime.profile(osMajor: 15), "below the floor no bundleRuntime (D-17)")
        let profile = FlarePluginBundleRuntime.profile(osMajor: 17)
        XCTAssertEqual(profile?["bridge"] as? Int, 1)
        XCTAssertEqual(profile?["engine"] as? String, "wkwebview")
        XCTAssertEqual(profile?["engineMajor"] as? Int, 17)
        #if os(macOS)
        XCTAssertNil(FlarePluginBundleRuntime.current, "the macOS smoke host offers no runtime")
        #endif
    }

    // MARK: Session

    func testAnOpenAnswerBecomesASession() throws {
        let session = try XCTUnwrap(FlarePluginBundleSession(openAnswer: answer()))
        XCTAssertEqual(session.sessionId, "s-1")
        XCTAssertEqual(session.host, "abc")
        XCTAssertEqual(session.entryURL?.absoluteString, "flare-plugin://abc/index.html")
        XCTAssertEqual(session.files["assets/app.js"], FlarePluginBundleFile(contentType: "text/javascript", size: 4096))
    }

    func testAnOpenAnswerWithoutTheEntryOrWithAnotherSchemeIsRefused() {
        XCTAssertNil(FlarePluginBundleSession(openAnswer: answer(entry: "main.html")), "the entry is not a listed file")
        var https = answer(); https["origin"] = "https://abc.plugin.flare.invalid"
        XCTAssertNil(FlarePluginBundleSession(openAnswer: https), "only the flare-plugin origin on iOS")
        var upper = answer(); upper["origin"] = "flare-plugin://ABC"
        XCTAssertNil(FlarePluginBundleSession(openAnswer: upper))
        var noFiles = answer(); noFiles["files"] = nil
        XCTAssertNil(FlarePluginBundleSession(openAnswer: noFiles), "no allowlist, nothing served")
        var badPath = answer()
        badPath["files"] = [["path": "../etc/passwd", "contentType": "text/plain", "size": 1],
                            ["path": "index.html", "contentType": "text/html", "size": 1]]
        XCTAssertNil(FlarePluginBundleSession(openAnswer: badPath))
    }

    // MARK: Paths and files

    func testBundlePathsFollowTheProtocolRule() {
        for good in ["index.html", "assets/app-1x2.js", "a/b/c.css", "bundle.json"] {
            XCTAssertTrue(FlarePluginBundleRules.isBundlePath(good), good)
        }
        for bad in ["", "/index.html", "a//b.js", "../x.js", "a/../b.js", ".hidden", "a/.env", "Index.html",
                    "a b.js", "a\\b.js", String(repeating: "a", count: 257)] {
            XCTAssertFalse(FlarePluginBundleRules.isBundlePath(bad), bad)
        }
    }

    func testOnlyListedFilesOfThisOriginAreServed() throws {
        let session = try XCTUnwrap(FlarePluginBundleSession(openAnswer: answer()))
        let served = FlarePluginBundleRules.resolve(URL(string: "flare-plugin://abc/assets/app.js?v=1")!, in: session)
        XCTAssertEqual(served?.url.path, "/tmp/plugin_bundles/0f0f/assets/app.js")
        XCTAssertEqual(served?.file.contentType, "text/javascript")
        for refused in ["flare-plugin://abc/assets/other.js", "flare-plugin://xyz/index.html",
                        "https://abc/index.html", "flare-plugin://abc/../index.html",
                        "flare-plugin://user@abc/index.html", "flare-plugin://abc:8080/index.html"] {
            XCTAssertNil(FlarePluginBundleRules.resolve(URL(string: refused)!, in: session), refused)
        }
    }

    func testEveryAnswerCarriesThePolicyAndCORS() {
        let headers = FlarePluginBundleRules.headers(for: FlarePluginBundleFile(contentType: "text/javascript", size: 9),
                                                     csp: csp)
        XCTAssertEqual(headers["Content-Security-Policy"], csp)
        XCTAssertEqual(headers["Access-Control-Allow-Origin"], "*", "module scripts are fetched in CORS mode")
        XCTAssertEqual(headers["Content-Type"], "text/javascript")
        XCTAssertEqual(headers["Content-Length"], "9")
        XCTAssertEqual(headers["X-Content-Type-Options"], "nosniff")
        XCTAssertEqual(FlarePluginBundleRules.commonHeaders(csp: csp)["Content-Security-Policy"], csp,
                       "a refusal carries the policy too")
    }

    // MARK: Navigation

    func testOnlyTheEntryLoadsInTheMainFrame() {
        let entry = URL(string: "flare-plugin://abc/index.html#/board")!
        XCTAssertTrue(FlarePluginBundleRules.allowsNavigation(to: entry, mainFrame: true, host: "abc", entry: "index.html"))
        XCTAssertFalse(FlarePluginBundleRules.allowsNavigation(to: entry, mainFrame: false, host: "abc", entry: "index.html"),
                       "no sub-frame")
        for away in ["https://example.com/", "flare-plugin://other/index.html", "flare-plugin://abc/assets/app.js",
                     "javascript:alert(1)", "about:blank", "data:text/html,hi"] {
            XCTAssertFalse(FlarePluginBundleRules.allowsNavigation(to: URL(string: away), mainFrame: true, host: "abc",
                                                                   entry: "index.html"), away)
        }
        XCTAssertFalse(FlarePluginBundleRules.allowsNavigation(to: nil, mainFrame: true, host: "abc", entry: "index.html"))
    }

    func testOnlyHttpsLinksMayOpenOutside() {
        XCTAssertNotNil(FlarePluginBundleRules.isExternalURL("https://example.com/a?b=c"))
        for bad in ["http://example.com", "javascript:alert(1)", "https://user:pw@example.com", "https:///x",
                    "https://exa mple.com", "flare-plugin://abc/index.html", "mailto:a@b.c"] {
            XCTAssertNil(FlarePluginBundleRules.isExternalURL(bad), bad)
        }
    }

    // MARK: Envelopes

    func testEnvelopesAreCarriedAsTextWithinTheLimit() throws {
        let text = try XCTUnwrap(FlarePluginBundleRules.envelopeText(
            ["bridge": 1, "id": "r-1", "type": "request", "method": "host.hello", "params": [String: Any]()]))
        let back = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        XCTAssertEqual(back["method"] as? String, "host.hello")
        XCTAssertEqual(FlarePluginBundleRules.envelopeText("{\"bridge\":1}"), "{\"bridge\":1}")
        XCTAssertNil(FlarePluginBundleRules.envelopeText([1, 2]), "an envelope is an object")
        XCTAssertNil(FlarePluginBundleRules.envelopeText(String(repeating: "x", count: FlarePluginBundleRules.maxEnvelopeBytes + 1)))
    }

    func testDeliveryPassesTheEnvelopeAsAStringLiteral() throws {
        let envelope = "{\"bridge\":1,\"type\":\"event\",\"event\":\"theme.changed\",\"payload\":{\"x\":\"</script>'\\u2028\"}}\u{2028}"
        let script = try XCTUnwrap(FlarePluginBundleRules.deliveryScript(envelope))
        XCTAssertTrue(script.hasPrefix("(function(e){var d=window.__flareBridgeDeliver;"))
        XCTAssertFalse(script.contains("\u{2028}"), "line separators are escaped")
        // The literal between the call's parentheses is the envelope's JSON string.
        let start = try XCTUnwrap(script.range(of: "})(")).upperBound
        let end = try XCTUnwrap(script.range(of: ");void 0;", options: .backwards)).lowerBound
        let decoded = try JSONSerialization.jsonObject(with: Data(script[start..<end].utf8), options: [.fragmentsAllowed])
        XCTAssertEqual(decoded as? String, envelope)
    }

    // MARK: Open request

    func testTheOpenRequestCarriesTheThemeAndConversation() {
        let request = FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "p.page.board", route: "/week",
                                                   arguments: ["day": .number(3)], presentation: .detail,
                                                   conversationId: "c-1", conversationType: "group", locale: "en-US")
        let payload = request.payload(mode: "dark")
        XCTAssertEqual(payload["contributionId"] as? String, "p.page.board")
        XCTAssertEqual(payload["route"] as? String, "/week")
        XCTAssertEqual(payload["presentation"] as? String, "detail")
        XCTAssertEqual((payload["theme"] as? [String: Any])?["mode"] as? String, "dark")
        XCTAssertEqual((payload["conversation"] as? [String: Any])?["type"] as? String, "group")
        XCTAssertEqual((payload["arguments"] as? [String: Any])?["day"] as? Double, 3)
        let plain = FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "c", locale: "zh-CN").payload(mode: "light")
        XCTAssertNil(plain["route"]); XCTAssertNil(plain["conversation"])
        XCTAssertEqual(plain["presentation"] as? String, "page")
    }

    // MARK: Crashes and events

    @MainActor
    func testTheThirdCrashBlocksTheBundleUntilAReset() {
        let plugin = "p.\(UUID().uuidString)", contribution = "c"
        XCTAssertFalse(FlarePluginBundleCrashLedger.isBlocked(pluginId: plugin, contributionId: contribution))
        for _ in 1...3 { _ = FlarePluginBundleCrashLedger.recordCrash(pluginId: plugin, contributionId: contribution) }
        XCTAssertTrue(FlarePluginBundleCrashLedger.isBlocked(pluginId: plugin, contributionId: contribution))
        FlarePluginBundleCrashLedger.reset(pluginId: plugin, contributionId: contribution)
        XCTAssertFalse(FlarePluginBundleCrashLedger.isBlocked(pluginId: plugin, contributionId: contribution))
    }

    @MainActor
    func testAnEventForNoLivePageIsNotTaken() {
        XCTAssertFalse(FlarePluginBundleEvents.receive(["sessionId": "gone", "close": "withdrawn"]))
        XCTAssertFalse(FlarePluginBundleEvents.receive(nil))
        XCTAssertEqual(FlarePluginBundleEvents.eventCode, 7004)
    }

    @MainActor
    func testAnEngineCloseEndsThePageAndFallsBack() throws {
        var fallbacks: [FlarePluginBundleFallback] = []
        let session = try XCTUnwrap(FlarePluginBundleSession(openAnswer: answer()))
        let controller = FlarePluginBundleHostController(
            request: FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "c", locale: "en"),
            calls: FlarePluginBundleCalls { _, _ in [:] },
            actions: FlarePluginBundleHostActions(fallback: { fallbacks.append($0) }), session: session)
        FlarePluginBundleEvents.register(controller, sessionId: session.sessionId)
        XCTAssertTrue(FlarePluginBundleEvents.receive(["sessionId": "s-1", "close": "withdrawn"]))
        XCTAssertEqual(controller.phase, .ended("withdrawn"))
        XCTAssertEqual(fallbacks, [.closed("withdrawn")])
        XCTAssertNil(controller.session)
        XCTAssertFalse(FlarePluginBundleEvents.receive(["sessionId": "s-1", "close": "withdrawn"]), "unregistered")
    }

    @MainActor
    func testAnEvictedPageWaitsToBeShownAgain() throws {
        let session = try XCTUnwrap(FlarePluginBundleSession(openAnswer: answer()))
        var fallbacks = 0
        let controller = FlarePluginBundleHostController(
            request: FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "c", locale: "en"),
            calls: FlarePluginBundleCalls { _, _ in [:] },
            actions: FlarePluginBundleHostActions(fallback: { _ in fallbacks += 1 }), session: session)
        controller.end(reason: "evicted")
        XCTAssertEqual(controller.phase, .suspended)
        XCTAssertEqual(fallbacks, 0, "a newer page took its place; it is not withdrawn")
    }

    // MARK: Opening

    @MainActor
    func testOpenAsksTheEngineAndReturnsNothingWithoutABundle() async {
        var routes: [(String, [String: Any])] = []
        let refusing = FlarePluginBundleCalls { route, payload in
            routes.append((route, payload))
            throw URLError(.unsupportedURL)
        }
        let request = FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "c", locale: "en")
        let none = await FlarePluginBundleHostController.open(request, calls: refusing, dark: false)
        XCTAssertNil(none)
        XCTAssertEqual(routes.first?.0, "plugin_bundle_open")
        XCTAssertEqual(routes.first?.1["pluginId"] as? String, "p")

        let answer = self.answer()
        let opening = FlarePluginBundleCalls { _, _ in answer }
        let session = await FlarePluginBundleHostController.open(request, calls: opening, dark: true)
        XCTAssertEqual(session?.sessionId, "s-1")
    }

    @MainActor
    func testAMalformedOpenAnswerClosesTheSessionItOpened() async {
        var routes: [String] = []
        let calls = FlarePluginBundleCalls { route, _ in
            routes.append(route)
            return route == "plugin_bundle_open" ? ["sessionId": "s-9", "origin": "https://x"] : [:]
        }
        let session = await FlarePluginBundleHostController.open(
            FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "c", locale: "en"), calls: calls, dark: false)
        XCTAssertNil(session)
        XCTAssertEqual(routes, ["plugin_bundle_open", "plugin_bundle_close"])
    }

    @MainActor
    func testABlockedContributionIsNotOpened() async {
        let plugin = "p.\(UUID().uuidString)"
        for _ in 1...3 { _ = FlarePluginBundleCrashLedger.recordCrash(pluginId: plugin, contributionId: "c") }
        var asked = false
        let calls = FlarePluginBundleCalls { _, _ in asked = true; return [:] }
        let session = await FlarePluginBundleHostController.open(
            FlarePluginBundleOpenRequest(pluginId: plugin, contributionId: "c", locale: "en"), calls: calls, dark: false)
        XCTAssertNil(session)
        XCTAssertFalse(asked)
    }

    // MARK: What the host draws

    @MainActor
    private func controller(actions: FlarePluginBundleHostActions = FlarePluginBundleHostActions()) -> FlarePluginBundleHostController {
        FlarePluginBundleHostController(request: FlarePluginBundleOpenRequest(pluginId: "p", contributionId: "c", locale: "en"),
                                        calls: FlarePluginBundleCalls { _, _ in [:] }, actions: actions)
    }

    @MainActor
    func testTitleAndResize() async {
        let host = controller()
        _ = await host.perform("ui.setTitle", params: ["title": "Board"])
        XCTAssertEqual(host.title, "Board")
        let refused = await host.perform("ui.resize", params: ["height": 300])
        XCTAssertEqual(refused.error, "unavailable", "only a resizable sheet takes a height")
        host.resizable = true
        let taken = await host.perform("ui.resize", params: ["height": 9000])
        XCTAssertNil(taken.error)
        XCTAssertEqual(host.preferredHeight, 4096)
    }

    @MainActor
    func testWithoutFeedbackToastsAndConfirmationsAreUnavailable() async {
        let host = controller()
        let toast = await host.perform("ui.toast", params: ["message": "Saved", "kind": "success"])
        XCTAssertEqual(toast.error, "unavailable")
        let confirm = await host.perform("ui.confirm", params: ["title": "Delete?", "destructive": true])
        XCTAssertEqual(confirm.error, "unavailable")
        let external = await host.perform("ui.openExternal", params: ["url": "https://example.com"])
        XCTAssertEqual(external.error, "unavailable")
    }

    @MainActor
    func testAToastIsTheKitToast() async {
        let host = controller()
        let feedback = FlareFeedback(announce: { _ in })
        host.feedback = feedback
        let toast = await host.perform("ui.toast", params: ["message": "Saved", "kind": "success"])
        XCTAssertNil(toast.error)
        XCTAssertEqual(toast.result?.isEmpty, true)
        XCTAssertEqual(feedback.toasts.map(\.message), ["Saved"])
    }

    @MainActor
    func testAnInsecureExternalLinkIsNeverOffered() async {
        let host = controller()
        host.feedback = FlareFeedback(announce: { _ in })
        let outcome = await host.perform("ui.openExternal", params: ["url": "http://example.com"])
        XCTAssertEqual(outcome.error, "unavailable")
    }

    @MainActor
    func testNavigationGoesThroughTheApp() async {
        var targets: [FlarePluginBundleNavigationTarget] = []
        let host = controller(actions: FlarePluginBundleHostActions(navigate: { target in
            targets.append(target)
            if case .page(let page, _) = target { return page == "p.page.list" }
            return true
        }))
        let page = await host.perform("ui.navigate", params: ["page": "p.page.list", "arguments": ["id": "7"]])
        XCTAssertNil(page.error)
        let missing = await host.perform("ui.navigate", params: ["page": "p.page.none"])
        XCTAssertEqual(missing.error, "not_found")
        let route = await host.perform("ui.navigate", params: ["bundleRoute": "/week"])
        XCTAssertNil(route.error)
        XCTAssertEqual(targets, [.page("p.page.list", arguments: .object(["id": .string("7")])),
                                 .page("p.page.none", arguments: .object([:])),
                                 .bundleRoute("/week", arguments: .object([:]))])
        let unhandled = await controller().perform("ui.navigate", params: ["page": "x"])
        XCTAssertEqual(unhandled.error, "unavailable")
    }

    @MainActor
    func testCloseAnswersFirstThenHandsTheResultBack() async {
        var closed: [PluginJSONValue?] = []
        let host = controller(actions: FlarePluginBundleHostActions(close: { closed.append($0) }))
        let outcome = await host.perform("ui.close", params: ["result": ["data": ["posted": ["serverMsgId": "m"]]]])
        XCTAssertNil(outcome.error)
        XCTAssertTrue(closed.isEmpty, "the app hears of the close only after the bundle has its answer")
        outcome.after?()
        XCTAssertEqual(closed.count, 1)
        XCTAssertEqual(closed.first??["data"]?["posted"]?["serverMsgId"]?.stringValue, "m")
    }

    @MainActor
    func testAnUnknownHostMethodIsUnavailable() async {
        let outcome = await controller().perform("host.capability", params: [:])
        XCTAssertEqual(outcome.error, "unavailable")
    }

    // MARK: Copy

    func testEveryBridgeErrorKeyHasWordsInBothLanguages() {
        let codes = ["invalidEnvelope", "unsupportedBridge", "notReady", "methodNotFound", "invalidParams",
                     "payloadTooLarge", "permissionDenied", "rateLimited", "cancelled", "gestureRequired",
                     "quotaExceeded", "notFound", "unavailable", "timeout", "operationFailed", "revoked", "internal"]
        for strings in [FlareStrings(), FlareStrings.english] {
            for code in codes {
                let text = strings.pluginBridgeMessage(forKey: "plugin.bridge.\(code)")
                XCTAssertNotNil(text, code)
                XCTAssertFalse(text?.isEmpty ?? true, code)
            }
            XCTAssertNil(strings.pluginBridgeMessage(forKey: "plugin.bridge.other"))
        }
        XCTAssertNotEqual(FlareStrings().pluginBundleReload, FlareStrings.english.pluginBundleReload)
    }
}
