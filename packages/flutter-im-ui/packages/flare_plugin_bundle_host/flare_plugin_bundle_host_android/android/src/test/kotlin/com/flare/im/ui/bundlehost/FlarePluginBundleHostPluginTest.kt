package com.flare.im.ui.bundlehost

import com.flare.im.ui.FlarePluginBundleHostAnswer
import com.flare.im.ui.FlarePluginBundlePresentation
import com.flare.im.ui.FlarePluginBundleResult
import com.flare.im.ui.FlarePluginBundleState
import org.junit.Assert.assertEquals
import org.junit.Test

/** The pure mappings between the kit's host and the Dart widget; the WebView itself needs a device. */
class FlarePluginBundleHostPluginTest {
    @Test
    fun statesReachDartByName() {
        assertEquals(mapOf("state" to "opening"), bundleStateArguments(FlarePluginBundleState.Opening))
        assertEquals(mapOf("state" to "ready"), bundleStateArguments(FlarePluginBundleState.Ready))
        assertEquals(mapOf("state" to "suspended"), bundleStateArguments(FlarePluginBundleState.Suspended))
        assertEquals(mapOf("state" to "crashed", "count" to 2), bundleStateArguments(FlarePluginBundleState.Crashed(2)))
        assertEquals(
            mapOf("state" to "fallback", "reason" to "withdrawn"),
            bundleStateArguments(FlarePluginBundleState.Fallback("withdrawn")),
        )
        assertEquals(mapOf("state" to "closed"), bundleStateArguments(FlarePluginBundleState.Closed))
    }

    @Test
    fun engineAnswersAreJsonTextOrUnavailable() {
        assertEquals(FlarePluginBundleResult.Answer("{\"sessionId\":\"s\"}"), engineAnswer("{\"sessionId\":\"s\"}"))
        assertEquals(FlarePluginBundleResult.Failure("unavailable"), engineAnswer(null))
        assertEquals(FlarePluginBundleResult.Failure("unavailable"), engineAnswer(""))
        assertEquals(FlarePluginBundleResult.Failure("unavailable"), engineAnswer(mapOf("sessionId" to "s")))
    }

    @Test
    fun refusalReasonsAreKeptOnlyWhenTheyAreReasons() {
        assertEquals("not_offered", engineFailureReason("not_offered"))
        assertEquals("unsupported", engineFailureReason("unsupported"))
        assertEquals("unavailable", engineFailureReason(""))
        assertEquals("unavailable", engineFailureReason(null))
        assertEquals("unavailable", engineFailureReason("sdk.plugin_bundle.rejected"))
        assertEquals("unavailable", engineFailureReason("Not Offered"))
    }

    @Test
    fun hostAnswersFromDart() {
        assertEquals(FlarePluginBundleHostAnswer.Done("{\"confirmed\":true}"), bundleHostAnswerOf(mapOf("result" to "{\"confirmed\":true}")))
        assertEquals(FlarePluginBundleHostAnswer.Done("{}"), bundleHostAnswerOf(mapOf("result" to null)))
        assertEquals(FlarePluginBundleHostAnswer.Done("{}"), bundleHostAnswerOf(mapOf("result" to "[1]")))
        assertEquals(FlarePluginBundleHostAnswer.Failed("cancelled"), bundleHostAnswerOf(mapOf("error" to "cancelled")))
        assertEquals(FlarePluginBundleHostAnswer.Failed("unavailable"), bundleHostAnswerOf(mapOf("error" to "Bad Code")))
        assertEquals(FlarePluginBundleHostAnswer.Failed("unavailable"), bundleHostAnswerOf(null))
        assertEquals(FlarePluginBundleHostAnswer.Failed("unavailable"), bundleHostAnswerOf("{}"))
    }

    @Test
    fun presentationsByWireName() {
        assertEquals(FlarePluginBundlePresentation.Page, bundlePresentationOf("page"))
        assertEquals(FlarePluginBundlePresentation.Detail, bundlePresentationOf("detail"))
        assertEquals(FlarePluginBundlePresentation.ComposerForm, bundlePresentationOf("composerForm"))
        assertEquals(FlarePluginBundlePresentation.Page, bundlePresentationOf("sheet"))
        assertEquals(FlarePluginBundlePresentation.Page, bundlePresentationOf(null))
    }
}
