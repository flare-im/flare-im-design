package com.flare.im.ui

import android.content.ActivityNotFoundException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.runBlocking
import kotlin.coroutines.cancellation.CancellationException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

// Contract tests for Layer 5 (spec/platform-contract.json vectors). A scripted
// adapter plays each native outcome; the assertions are on the contract's
// normalization and result shape, not on any real picker — the capability
// matrix records this as PASS_TEST, never PASS_RUNTIME.
class FlarePlatformTest {
    private enum class Outcome { success, cancelled, unsupported, denied, timeout, failed }

    private class Scripted(private val outcome: Outcome) : FlarePlatformAdapter {
        override val capabilities = FlarePlatformCapabilities(
            filePicker = FlareCapabilitySupport.Supported,
            imagePicker = FlareCapabilitySupport.Supported,
            share = FlareCapabilitySupport.Supported,
        )

        private suspend fun <T> play(value: T): FlarePlatformResult<T> = when (outcome) {
            Outcome.success -> FlarePlatformResult.Ok(value)
            // PickVisualMedia / OpenDocument deliver a null uri when dismissed; the host maps it.
            Outcome.cancelled -> FlarePlatformResult.failure(FlarePlatformErrorCode.CANCELLED, "picker dismissed")
            Outcome.unsupported -> throw UnsupportedOperationException("No Activity found to handle Intent")
            Outcome.denied -> throw SecurityException("Permission Denial: reading content uri")
            Outcome.timeout -> CompletableDeferred<FlarePlatformResult<T>>().await()
            Outcome.failed -> throw IllegalStateException("native surface crashed")
        }

        override suspend fun pickFiles(options: FlarePickFilesOptions) =
            play(listOf(FlarePickedFile("spec.pdf", size = 4, mimeType = "application/pdf", uri = "content://docs/1")))

        override suspend fun pickImages(options: FlarePickImagesOptions) =
            play(listOf(FlarePickedFile("shot.png", mimeType = "image/png", uri = "content://media/1")))

        override suspend fun share(payload: FlareSharePayload) = play(Unit)
    }

    private fun run(operation: String, outcome: Outcome): FlarePlatformResult<Any?> = runBlocking {
        val adapter = Scripted(outcome)
        callFlarePlatform<Any?>(timeoutMs = 20) {
            when (operation) {
                "pickFiles" -> adapter.pickFiles()
                "pickImages" -> adapter.pickImages()
                else -> adapter.share(FlareSharePayload(text = "hi"))
            }
        }
    }

    private val expected = mapOf(
        Outcome.cancelled to FlarePlatformErrorCode.CANCELLED,
        Outcome.unsupported to FlarePlatformErrorCode.UNSUPPORTED,
        Outcome.denied to FlarePlatformErrorCode.PERMISSION_DENIED,
        Outcome.timeout to FlarePlatformErrorCode.TIMEOUT,
        Outcome.failed to FlarePlatformErrorCode.FAILED,
    )

    // Vector ids: pickFiles.success pickFiles.cancelled pickFiles.unsupported
    // pickFiles.denied pickFiles.timeout pickFiles.failed pickImages.success
    // pickImages.cancelled pickImages.unsupported pickImages.denied
    // pickImages.timeout pickImages.failed share.success share.cancelled
    // share.unsupported share.denied share.timeout share.failed
    @Test fun everyOperationOutcomeVectorNormalizes() {
        for (operation in listOf("pickFiles", "pickImages", "share")) {
            val ok = run(operation, Outcome.success)
            assertTrue(ok.isOk, "$operation.success")
            if (operation != "share") {
                @Suppress("UNCHECKED_CAST")
                val files = ok.valueOrNull as List<FlarePickedFile>
                assertEquals(if (operation == "pickFiles") "spec.pdf" else "shot.png", files.single().name)
            }
            for ((outcome, code) in expected) {
                val id = "$operation.${outcome.name}"
                val result = run(operation, outcome)
                assertFalse(result.isOk, id)
                assertEquals(code, result.code, id)
                assertNotNull(result.errorOrNull?.message, "$id keeps a message")
            }
        }
    }

    @Test fun errorModelMapsAndroidThrowables() {
        assertEquals(FlarePlatformErrorCode.CANCELLED, normalizeFlarePlatformError(CancellationException("user backed out")).code)
        assertEquals(FlarePlatformErrorCode.PERMISSION_DENIED, normalizeFlarePlatformError(SecurityException("denied")).code)
        assertEquals(FlarePlatformErrorCode.UNSUPPORTED, normalizeFlarePlatformError(UnsupportedOperationException("no")).code)
        assertEquals(FlarePlatformErrorCode.UNSUPPORTED, normalizeFlarePlatformError(ActivityNotFoundException()).code)
        assertNotNull(normalizeFlarePlatformError(ActivityNotFoundException()).message, "framework exceptions without a message still keep one")
        assertEquals(FlarePlatformErrorCode.TIMEOUT, normalizeFlarePlatformError(IllegalStateException("request timed out")).code)
        assertEquals(FlarePlatformErrorCode.FAILED, normalizeFlarePlatformError(RuntimeException("boom")).code)
        val passthrough = FlarePlatformError(FlarePlatformErrorCode.TIMEOUT, "kept")
        assertSame(passthrough, normalizeFlarePlatformError(passthrough))
    }

    @Test fun unsupportedAdapterAnswersUnsupportedEverywhere() = runBlocking {
        val adapter = FlareUnsupportedPlatformAdapter()
        assertEquals(FlarePlatformErrorCode.UNSUPPORTED, adapter.pickFiles().code)
        assertEquals(FlarePlatformErrorCode.UNSUPPORTED, adapter.pickImages().code)
        assertEquals(FlarePlatformErrorCode.UNSUPPORTED, adapter.share(FlareSharePayload()).code)
        assertNull(adapter.onNativeBack { true })
        assertEquals(FlareCapabilitySupport.Unsupported, adapter.capabilities.filePicker)
        assertTrue(adapter.capabilities.nativeBack)
    }

    @Test fun androidCapabilitiesFollowFormFactorAndPointer() {
        val phone = FlarePlatformCapabilities.android(widthDp = 390)
        assertEquals(FlarePointerKind.Coarse, phone.pointer)
        assertTrue(phone.bottomSheet)
        assertFalse(phone.hover)
        val tabletWithMouse = FlarePlatformCapabilities.android(widthDp = 1024, hasPointer = true)
        assertEquals(FlarePointerKind.Mixed, tabletWithMouse.pointer)
        assertFalse(tabletWithMouse.bottomSheet)
        assertTrue(tabletWithMouse.contextMenu)
    }
}
