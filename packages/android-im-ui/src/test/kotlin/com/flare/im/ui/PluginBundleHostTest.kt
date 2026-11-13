package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The Android bundle host's rules: the runtime floor, the session it accepts, the interceptor, the bridge answers. */
class PluginBundleHostTest {
    private val origin = "https://abcdefghijklmnopqrstuvwxyz.plugin.flare.invalid"
    private val csp = "default-src 'none'; script-src $origin; connect-src 'none'; frame-ancestors 'none'"

    private fun answer(
        origin: String = this.origin,
        entry: String = "index.html",
        files: String = """[{"path":"index.html","contentType":"text/html; charset=utf-8","size":120},
            {"path":"assets/app.js","contentType":"application/javascript","size":4096},
            {"path":"bundle.json","contentType":"application/json","size":200}]""",
        csp: String = this.csp,
    ) = """{"sessionId":"s-1","origin":"$origin","root":"/data/plugin_bundles/abc","entry":"$entry","csp":"$csp",
        "files":$files,"hello":{"bridge":1}}"""

    private val session = assertNotNull(FlarePluginBundleSession.fromJson(answer()))

    @Test fun runtimeProfileNeedsWebView111AndTheListener() {
        assertEquals(128, webViewMajorOf("128.0.6613.40"))
        assertEquals(111, webViewMajorOf(" 111.0.5563.116 "))
        assertNull(webViewMajorOf("dev"))
        assertNull(webViewMajorOf("0.1"))
        assertNull(FlarePluginBundleRuntime.profileFor(110, true))
        assertNull(FlarePluginBundleRuntime.profileFor(128, false))
        assertNull(FlarePluginBundleRuntime.profileFor(null, true))
        assertEquals(
            mapOf("bridge" to 1, "engine" to "webview", "engineMajor" to 111),
            FlarePluginBundleRuntime.profileFor(111, true),
        )
    }

    @Test fun sessionReadsTheOpenAnswer() {
        assertEquals("s-1", session.sessionId)
        assertEquals("abcdefghijklmnopqrstuvwxyz.plugin.flare.invalid", session.host)
        assertEquals("$origin/index.html", session.entryUrl)
        assertEquals(setOf("index.html", "assets/app.js", "bundle.json"), session.files.keys)
        assertEquals(4096L, session.files.getValue("assets/app.js").size)
    }

    @Test fun sessionRefusesWhatCannotBeServedSafely() {
        // Not the bundle origin shape.
        assertNull(FlarePluginBundleSession.fromJson(answer(origin = "http://abc.plugin.flare.invalid")))
        assertNull(FlarePluginBundleSession.fromJson(answer(origin = "https://evil.example")))
        assertNull(FlarePluginBundleSession.fromJson(answer(origin = "https://ABC1.plugin.flare.invalid")))
        assertNull(FlarePluginBundleSession.fromJson(answer(origin = "https://abc.plugin.flare.invalid:8443")))
        assertNull(FlarePluginBundleSession.fromJson(answer(origin = "https://abc.plugin.flare.invalid/x")))
        // An entry the files do not list, or not a bundle path.
        assertNull(FlarePluginBundleSession.fromJson(answer(entry = "main.html")))
        assertNull(FlarePluginBundleSession.fromJson(answer(entry = "../index.html")))
        // No policy.
        assertNull(FlarePluginBundleSession.fromJson(answer(csp = "")))
        assertNull(FlarePluginBundleSession.fromJson("""{"sessionId":"s"}"""))
        assertNull(FlarePluginBundleSession.fromJson("not json"))
        // A listed file with a bad path is dropped, not served.
        val odd = assertNotNull(FlarePluginBundleSession.fromJson(answer(files =
            """[{"path":"index.html","contentType":"text/html","size":1},{"path":".env","contentType":"text/plain","size":1},
                {"path":"A.js","contentType":"application/javascript","size":1}]""")))
        assertEquals(setOf("index.html"), odd.files.keys)
    }

    @Test fun bundlePaths() {
        assertTrue(validBundlePath("assets/index-3f2a.js"))
        assertTrue(validBundlePath("a/b_c/d.e-f.woff2"))
        listOf("", "/index.html", "a//b", "a/./b", "../a", ".hidden", "a/.git/x", "A.js", "a b", "a\\b", "x".repeat(257))
            .forEach { assertFalse(validBundlePath(it), it) }
    }

    @Test fun interceptorServesOnlyListedFilesOfItsOwnOrigin() {
        assertEquals("index.html", (pluginBundleServe("$origin/", "GET", session) as PluginBundleServe.File).file.path)
        assertEquals("index.html", (pluginBundleServe(origin, "GET", session) as PluginBundleServe.File).file.path)
        assertEquals("assets/app.js", (pluginBundleServe("$origin/assets/app.js?v=1#x", "GET", session) as PluginBundleServe.File).file.path)
        assertEquals("assets/app.js", (pluginBundleServe("https://ABCDEFGHIJKLMNOPQRSTUVWXYZ.plugin.flare.invalid:443/assets/app.js", "get", session) as PluginBundleServe.File).file.path)
        val forbidden = listOf(
            "$origin/assets/missing.js" to "GET",
            "$origin/assets/app.js" to "POST",
            "$origin/assets/app.js" to "HEAD",
            "http://abcdefghijklmnopqrstuvwxyz.plugin.flare.invalid/assets/app.js" to "GET",
            "https://other.plugin.flare.invalid/assets/app.js" to "GET",
            "https://example.com/assets/app.js" to "GET",
            "$origin:8443/assets/app.js" to "GET",
            "https://user@abcdefghijklmnopqrstuvwxyz.plugin.flare.invalid/index.html" to "GET",
            "$origin/assets/../bundle.json" to "GET",
            "$origin/assets/%61pp.js" to "GET",
            "$origin/Assets/app.js" to "GET",
            "file:///data/plugin_bundles/abc/index.html" to "GET",
            "data:text/html,hi" to "GET",
            "$origin/assets//app.js" to "GET",
        )
        for ((url, method) in forbidden) assertEquals(PluginBundleServe.Forbidden, pluginBundleServe(url, method, session), "$method $url")
    }

    @Test fun everyAnswerCarriesThePolicyAndOpenCors() {
        val headers = pluginBundleHeaders(csp)
        assertEquals(csp, headers["Content-Security-Policy"])
        assertEquals("*", headers["Access-Control-Allow-Origin"])
        assertEquals("nosniff", headers["X-Content-Type-Options"])
        assertEquals("no-referrer", headers["Referrer-Policy"])
        assertTrue(csp.contains("connect-src 'none'"))
    }

    @Test fun mimeAndCharset() {
        assertEquals("text/html" to "utf-8", pluginBundleMime("text/html; charset=utf-8"))
        assertEquals("text/css" to "utf-8", pluginBundleMime("text/css"))
        assertEquals("application/javascript" to "utf-8", pluginBundleMime("application/javascript"))
        assertEquals("image/png" to null, pluginBundleMime("image/png"))
        assertEquals("font/woff2" to null, pluginBundleMime("font/woff2"))
    }

    @Test fun navigationStaysOnTheBundleOrigin() {
        assertTrue(pluginBundleNavigationAllowed("$origin/index.html", session))
        assertFalse(pluginBundleNavigationAllowed("https://example.com/", session))
        assertFalse(pluginBundleNavigationAllowed("javascript:alert(1)", session))
        assertFalse(pluginBundleNavigationAllowed("intent://x#Intent;end", session))
        assertFalse(pluginBundleNavigationAllowed("$origin/index.html", null))
    }

    @Test fun externalLinksAreHttpsOnly() {
        assertTrue(flarePluginBundleExternalUrl("https://help.example.com/guide?a=1"))
        listOf("http://example.com", "javascript:alert(1)", "intent://x", "https://", "https://u:p@example.com",
            "mailto:a@example.com", "file:///etc/hosts", "https://example.com/" + "a".repeat(2100))
            .forEach { assertFalse(flarePluginBundleExternalUrl(it), it) }
    }

    @Test fun engineClosingAndCrashing() {
        assertEquals(FlarePluginBundleState.Fallback("withdrawn"), pluginBundleClosedState("withdrawn"))
        assertEquals(FlarePluginBundleState.Fallback("disabled"), pluginBundleClosedState("disabled"))
        assertEquals(FlarePluginBundleState.Suspended, pluginBundleClosedState("evicted"))
        assertEquals(FlarePluginBundleState.Closed, pluginBundleClosedState("signedOut"))
        assertEquals(FlarePluginBundleState.Crashed(1), pluginBundleCrashState(1))
        assertEquals(FlarePluginBundleState.Crashed(2), pluginBundleCrashState(2))
        assertEquals(FlarePluginBundleState.Fallback("crashed"), pluginBundleCrashState(3))
        assertEquals(30_000L, PLUGIN_BUNDLE_BACKGROUND_MS)
    }

    @Test fun bridgeAnswers() {
        val envelope = """{"bridge":1,"id":"r-1","type":"response","result":{}}"""
        assertEquals(PluginBundleBridgeAnswer.Envelope(envelope), pluginBundleBridgeAnswer(pluginJson(mapOf("envelope" to envelope))))
        val host = assertIs<PluginBundleBridgeAnswer.Host>(pluginBundleBridgeAnswer(
            """{"host":{"id":"r-2","method":"ui.confirm","params":{"title":"Delete?","destructive":true}}}""",
        ))
        assertEquals("r-2", host.request.id)
        assertEquals("ui.confirm", host.request.method)
        assertEquals(true, host.request.params["destructive"])
        assertNull(pluginBundleBridgeAnswer("""{"host":{"method":"ui.toast"}}"""))
        assertNull(pluginBundleBridgeAnswer("[]"))
    }

    @Test fun deliveriesAndEvents() {
        val json = """{"deliveries":[{"sessionId":"s-1","envelope":"a"},{"sessionId":"s-2","envelope":"b"},{"sessionId":"s-1"}]}"""
        assertEquals(listOf("a"), pluginBundleDeliveries(json, "s-1"))
        assertEquals(emptyList(), pluginBundleDeliveries("{}", "s-1"))
        assertEquals(PluginBundleEvent("s-1", "e", null), pluginBundleEvent("""{"sessionId":"s-1","envelope":"e"}"""))
        assertEquals(PluginBundleEvent("s-1", null, "withdrawn"), pluginBundleEvent("""{"sessionId":"s-1","close":"withdrawn"}"""))
        assertNull(pluginBundleEvent("""{"close":"withdrawn"}"""))
        assertEquals("s-9", pluginBundleSessionIdOf("""{"sessionId":"s-9","origin":"x"}"""))
    }

    @Test fun openRequest() {
        val request = FlarePluginBundleOpenRequest(
            pluginId = "acme.task", contributionId = "acme.task.page.dashboard", argumentsJson = """{"week":3}""",
            presentation = FlarePluginBundlePresentation.Detail, conversationId = "c-1", conversationType = "group", locale = "zh-CN",
        )
        val json = FlareJson.parse(request.toJson(dark = true)) as Map<*, *>
        assertEquals("acme.task", json["pluginId"])
        assertEquals("detail", json["presentation"])
        assertEquals(mapOf("week" to 3.0), json["arguments"])
        assertEquals(mapOf("id" to "c-1", "type" to "group"), json["conversation"])
        assertEquals(mapOf("mode" to "dark", "tokens" to emptyMap<String, Any?>()), json["theme"])
        assertNull(json["route"])
        val plain = FlareJson.parse(FlarePluginBundleOpenRequest("p", "c", route = "/board", locale = "en").toJson(false)) as Map<*, *>
        assertEquals("page", plain["presentation"])
        assertEquals("/board", plain["route"])
        assertNull(plain["arguments"])
        assertNull(plain["conversation"])
        assertEquals("light", (plain["theme"] as Map<*, *>)["mode"])
    }

    @Test fun hostRequestShapes() {
        assertEquals(FlarePluginBundleNavigation.Page("p.history", null), pluginBundleNavigation(mapOf("page" to "p.history")))
        assertEquals(FlarePluginBundleNavigation.BundleRoute("/week"), pluginBundleNavigation(mapOf("bundleRoute" to "/week")))
        assertNull(pluginBundleNavigation(mapOf("page" to "a", "bundleRoute" to "/b")))
        assertNull(pluginBundleNavigation(emptyMap()))
        val confirm = assertNotNull(pluginBundleConfirm(mapOf("title" to "t".repeat(100), "message" to " ", "confirmLabel" to "Delete")))
        assertEquals(64, confirm.title.length)
        assertNull(confirm.message)
        assertNull(pluginBundleConfirm(mapOf("message" to "no title")))
        assertEquals(ToastVariant.Success, pluginBundleToastVariant("success"))
        assertEquals(ToastVariant.Error, pluginBundleToastVariant("error"))
        assertEquals(ToastVariant.Info, pluginBundleToastVariant(null))
    }

    @Test fun bridgeErrorTextCoversEveryCode() {
        val strings = FlareStrings()
        val codes = listOf(
            "invalid_envelope", "unsupported_bridge", "not_ready", "method_not_found", "invalid_params", "payload_too_large",
            "permission_denied", "rate_limited", "cancelled", "gesture_required", "quota_exceeded", "not_found",
            "unavailable", "timeout", "operation_failed", "revoked",
        )
        val texts = codes.map { flarePluginBridgeErrorText(it, strings) }
        assertEquals(codes.size, texts.toSet().size)
        assertTrue(strings.pluginBridgeErrorInternal !in texts)
        assertEquals(strings.pluginBridgeErrorPermissionDenied, flarePluginBridgeErrorText("plugin.bridge.permissionDenied", strings))
        assertEquals(strings.pluginBridgeErrorInternal, flarePluginBridgeErrorText("something_else", strings))
        assertNotEquals(strings.pluginBundleCrashed, flareStringsEnglish().pluginBundleCrashed)
    }
}
