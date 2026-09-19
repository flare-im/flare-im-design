package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** The shared layout table (`spec/image-group-layout-vectors.json`) and what the album body builds on it. */
class ImageGroupMessageTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/image-group-layout-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/image-group-layout-vectors.json not found")
    }

    @Test fun everyCountLaysOutAsTheTableSays() {
        val table = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        assertEquals(FLARE_IMAGE_GROUP_MAX_VISIBLE, (table["maxVisible"] as Double).toInt())
        val cases = table["cases"] as List<*>
        assertTrue(cases.size >= 13)
        for (raw in cases) {
            val case = raw as Map<*, *>
            val count = (case["count"] as Double).toInt()
            assertEquals(
                FlareImageGroupLayout((case["columns"] as Double).toInt(), (case["visible"] as Double).toInt(), (case["more"] as Double).toInt()),
                flareImageGroupLayout(count),
                "$count image(s)",
            )
        }
    }

    @Test fun tilesAreNamedByPositionAndTheCoveredOneCountsWhatIsNotDrawn() {
        val strings = FlareStrings()
        val layout = flareImageGroupLayout(12)
        assertEquals("第 1 张图片，共 12 张", flareImageGroupTileLabel(0, 12, layout, strings))
        assertEquals("第 9 张图片，共 12 张，另有 4 张未显示", flareImageGroupTileLabel(8, 12, layout, strings))
        assertEquals(false, layout.covers(7))
    }

    @Test fun anAlbumTapGoesToTheHostOrPreviewsTheTileImage() {
        val album = FlareImageGroupContent(listOf(FlareImageContent("https://cdn/a.jpg"), FlareImageContent("https://cdn/b.jpg")))
        assertEquals(FlareContentTap.Host, flareContentTap(album, hasMediaHandler = true, hasFileHandler = false))
        assertEquals(FlareContentTap.PreviewAlbumImage, flareContentTap(album, hasMediaHandler = false, hasFileHandler = false))
    }

    @Test fun anAlbumSummarisesAsItsCount() {
        val strings = FlareStrings()
        assertEquals(strings.previewImageGroup, flareMessagePreviewText(FlareImageGroupContent(emptyList()), strings))
        assertEquals(strings.previewImageGroupCount(2), flareMessagePreviewText(FlareImageGroupContent(List(2) { FlareImageContent("") }), strings))
    }
}
