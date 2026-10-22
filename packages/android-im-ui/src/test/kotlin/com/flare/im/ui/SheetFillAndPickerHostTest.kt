package com.flare.im.ui

import java.io.File
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

/**
 * The bottom sheet's fill mode and the content's own-header declaration, and what LocationPicker takes from its host:
 * `sending`, the permission step before each locate and the map size in device pixels
 * (`spec/location-vectors.json` previewSize).
 */
class SheetFillAndPickerHostTest {
    private val here = FlareLocationCoordinate(30.2741, 120.1551)

    // ── sheet fill ──

    @Test fun theTitleGivesWayOnlyToAFilledSheetWhoseContentBringsItsHeader() {
        assertTrue(flareSheetDrawsTitle("位置", titleHidden = false, fill = false, ownHeader = false))
        assertTrue(flareSheetDrawsTitle("位置", titleHidden = false, fill = false, ownHeader = true), "without fill nothing changes")
        assertTrue(flareSheetDrawsTitle("位置", titleHidden = false, fill = true, ownHeader = false))
        assertFalse(flareSheetDrawsTitle("位置", titleHidden = false, fill = true, ownHeader = true))
        assertFalse(flareSheetDrawsTitle("位置", titleHidden = true, fill = false, ownHeader = false))
        assertFalse(flareSheetDrawsTitle(null, titleHidden = false, fill = true, ownHeader = false))
    }

    @Test fun theSlotCountsTheDeclarationsOfItsContent() {
        val slot = FlareSheetHeaderSlot(fill = true)
        assertTrue(slot.fill)
        assertFalse(slot.owned)
        slot.owners += 1
        assertTrue(slot.owned, "a declaration in the content")
        slot.owners += 1
        slot.owners -= 1
        assertTrue(slot.owned, "one leaving keeps the other's")
        slot.owners -= 1
        assertFalse(slot.owned, "withdrawn when the content leaves")
        assertFalse(FlareSheetHeaderSlot(fill = false).fill)
    }

    // ── location picker: sending ──

    @Test fun sendingIsAStatusOfThePicker() {
        val model = FlareLocationPickerModel().located(here)
        assertTrue(FlareLocationPickerStatus.Sending in model.statuses(sending = true))
        assertFalse(FlareLocationPickerStatus.Sending in model.statuses(sending = false))
        assertEquals(model.statuses, model.statuses(sending = false))
        assertTrue(FlareLocationPickerStatus.Sending in FlareLocationPickerStatus.entries)
    }

    // ── location picker: permission ──

    @Test fun thePermissionStepComesFirstAndIsNotTimed() = runBlocking {
        val calls = AtomicInteger()
        val request: suspend () -> FlareLocationCoordinate = { calls.incrementAndGet(); here }

        assertNull(flareLocatePosition({ false }, request, 5000), "false is denied")
        assertEquals(0, calls.get(), "without permission the position is never asked for")
        assertNull(flareLocatePosition({ error("denied") }, request, 5000), "a throw is denied")
        assertEquals(0, calls.get())

        // The prompt is up longer than the timeout: its wait does not count.
        val slowPrompt = flareLocatePosition({ delay(300); true }, request, 100)
        assertEquals(here, slowPrompt)
        assertEquals(1, calls.get())

        assertEquals(here, flareLocatePosition(null, request, 5000), "no permission step: asked for at once")
        assertNull(flareLocatePosition({ true }, { delay(2000); here }, 50), "the timeout still runs once granted")
        assertNull(flareLocatePosition(null, { FlareLocationCoordinate(120.0, 30.0) }, 5000), "an invalid fix is denied")
    }

    // ── location picker: map size ──

    private fun vectors(): Map<*, *> {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/location-vectors.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            dir = dir.parentFile
        }
        error("spec/location-vectors.json not found above ${File(".").absolutePath}")
    }

    @Test fun thePreviewSizeIsDevicePixelsNeverDp() {
        val rows = vectors()["previewSize"] as List<*>
        assertTrue(rows.size >= 7, "the shared table lost cases: ${rows.size}")
        for (raw in rows) {
            val row = raw as Map<*, *>
            val id = row["id"] as String
            val input = row["input"] as Map<*, *>
            val output = row["output"] as Map<*, *>
            val (width, height) = FlareLocationFormat.previewPixels(
                (input["width"] as Number).toDouble(), (input["height"] as Number).toDouble(),
                (input["scale"] as Number? ?: 1).toDouble(),
            )
            assertEquals((output["width"] as Number).toInt(), width, id)
            assertEquals((output["height"] as Number).toInt(), height, id)
        }
    }
}
