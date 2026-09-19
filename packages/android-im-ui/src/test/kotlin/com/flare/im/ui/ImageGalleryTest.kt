package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The shared gallery table (`spec/image-gallery-vectors.json`) and what a tap on a picture presents. */
class ImageGalleryTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/image-gallery-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/image-gallery-vectors.json not found")
    }

    private fun message(raw: Map<*, *>): FlareMessageData {
        val refs = (raw["images"] as? List<*>).orEmpty().map { it as String }
        val content = when (raw["kind"]) {
            "image" -> FlareImageContent(refs.first())
            "imageGroup" -> FlareImageGroupContent(refs.map { FlareImageContent(it) })
            "sticker" -> FlareStickerContent("https://cdn.example/s.webp")
            "video" -> FlareVideoContent("https://cdn.example/v.mp4")
            else -> FlareTextContent("明天见")
        }
        val lifecycle = if (raw["recalled"] == true) FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled) else null
        return FlareMessageData(id = raw["id"] as String, senderId = "u", senderName = "U", content = content, lifecycle = lifecycle)
    }

    @Test fun everyCaseBuildsTheGalleryTheTableSays() {
        val cases = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["cases"] as List<*>
        assertTrue(cases.size >= 4)
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val items = flareImageGalleryItems((case["messages"] as List<*>).map { message(it as Map<*, *>) })
            assertEquals(case["items"], items.map { "${it.messageId}#${it.index}" }, id)
            for (rawOpen in case["opens"] as List<*>) {
                val open = rawOpen as Map<*, *>
                val start = flareImageGalleryStart(items, open["message"] as String, (open["index"] as Double).toInt())
                assertEquals((open["start"] as Double?)?.toInt(), start, "$id ${open["message"]}#${open["index"]}")
            }
        }
    }

    private val timeline = listOf(
        FlareMessageData("m1", "u", "U", FlareImageContent("https://cdn/1.jpg")),
        FlareMessageData("m2", "u", "U", FlareImageGroupContent(listOf(FlareImageContent("https://cdn/2.jpg"), FlareImageContent("", thumbnailUrl = "https://cdn/3t.jpg")))),
    )

    @Test fun aTapInATimelineOpensTheGalleryElseThePictureAlone() {
        val gallery = FlareTimelineGallery(flareImageGalleryItems(timeline), download = null)
        assertEquals(
            FlareMediaPresentation.Gallery(listOf("https://cdn/1.jpg", "https://cdn/2.jpg", "https://cdn/3t.jpg"), 2),
            flareImagePresentation(gallery, "m2", 1, "https://cdn/3t.jpg"),
        )
        assertEquals(FlareMediaPresentation.Image("https://cdn/x.jpg"), flareImagePresentation(null, "m2", 1, "https://cdn/x.jpg"))
        assertEquals(FlareMediaPresentation.Image("https://cdn/x.jpg"), flareImagePresentation(gallery, "m9", 0, "https://cdn/x.jpg"))
        assertEquals(FlareMediaPresentation.Image("https://cdn/x.jpg"), flareImagePresentation(gallery, null, 0, "https://cdn/x.jpg"))
    }

    /**
     * The download key follows what is on screen: a gallery page downloads its own picture with the message it belongs
     * to — never the tapped body's picture — and a picture alone keeps the key its body was given.
     */
    @Test fun aGalleryPageDownloadsItsOwnPictureAndAPictureAloneItsBodysKey() {
        val saved = mutableListOf<String>()
        val gallery = FlareTimelineGallery(flareImageGalleryItems(timeline)) { saved += "${it.messageId}#${it.index}" }
        val opened = flareImagePresentation(gallery, "m2", 1, "https://cdn/3t.jpg", onDownload = { saved += "body" })
        val pages = assertIs<FlareMediaPresentation.Gallery>(opened).onDownload
        assertNotNull(pages)
        pages(2)
        pages(0)
        assertEquals(listOf("m2#1", "m1#0"), saved)

        val silent = flareImagePresentation(FlareTimelineGallery(gallery.items, download = null), "m2", 1, "https://cdn/3t.jpg", onDownload = { saved += "body" })
        assertNull(assertIs<FlareMediaPresentation.Gallery>(silent).onDownload)

        saved.clear()
        val alone = assertIs<FlareMediaPresentation.Image>(flareImagePresentation(gallery, "m9", 0, "https://cdn/x.jpg", onDownload = { saved += "body" }))
        assertNotNull(alone.onDownload).invoke()
        assertEquals(listOf("body"), saved)
        assertNull(assertIs<FlareMediaPresentation.Image>(flareImagePresentation(null, "m2", 1, "https://cdn/x.jpg")).onDownload)
    }
}
