package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/**
 * The download key of a picture, a video and a file, checked without a UI: one key in the file card, the image preview
 * and the video player that follows where the media stands on this device — a download, nothing to press while it
 * downloads, a folder once it is saved — and hands the host the media it belongs to.
 */
class MediaDownloadKeyTest {
    private val zh = FlareStrings()
    private val en = FlareStrings { download = "Download"; showInFolder = "Show in folder"; downloading = "Downloading"; downloaded = "Downloaded" }

    private fun key(
        canDownload: Boolean = true,
        downloading: Boolean = false,
        saved: Boolean = false,
        canReveal: Boolean = true,
        strings: FlareStrings = zh,
    ) = mediaDownloadKey(strings, canDownload, downloading, saved, canReveal)

    @Test fun theKeyIsADownloadThenNothingWhileItRunsThenTheFolder() {
        assertEquals(FlareIconControlSpec("download", "download", "下载"), key())
        // The progress ring stands where the key was: nothing to press twice.
        assertNull(key(downloading = true))
        assertEquals(FlareIconControlSpec("reveal", "folder", "在文件夹中显示"), key(saved = true))
        assertEquals("Show in folder", key(saved = true, strings = en)?.label)
        // Every glyph is the icon library's.
        listOf(key(), key(saved = true)).forEach { assertNotNull(it); kotlin.test.assertTrue(it.icon in flareIconNames, it.icon) }
    }

    @Test fun thereIsNoKeyWithoutADownloadHandlerAndNeverASpentOne() {
        assertNull(key(canDownload = false))
        assertNull(key(canDownload = false, saved = true))
        // Saved, but the host cannot show it: the key downloads again rather than drawing a dead "downloaded" mark.
        assertEquals("download", key(saved = true, canReveal = false)?.id)
    }

    @Test fun theViewersAndTheFileCardShareTheKey() {
        for (saved in listOf(false, true)) {
            val preview = imagePreviewControls(zh, canDownload = true, downloading = false, saved = saved, canReveal = true)
            val player = videoPlayerControls(zh, canDownload = true, downloading = false, saved = saved, canReveal = true)
            assertEquals(key(saved = saved), preview.last())
            assertEquals(key(saved = saved), player.last())
        }
        // While the download runs only close is a key; once saved the folder stands at the top right.
        assertEquals(listOf("close"), imagePreviewControls(zh, canDownload = true, downloading = true, saved = false, canReveal = true).map { it.id })
        assertEquals(listOf("close", "reveal"), videoPlayerControls(zh, canDownload = true, downloading = false, saved = true, canReveal = true).map { it.id })
    }

    @Test fun theFileCardSaysItsSizeTypeAndState() {
        assertEquals("8.5 KB · TXT", fileMessageSubtitle(zh, "8.5 KB", "TXT", null))
        assertEquals("8.5 KB · TXT", fileMessageSubtitle(zh, "8.5 KB", "TXT", FlareMediaDownloadState(FlareMediaDownloadStatus.Failed)))
        assertEquals("8.5 KB · TXT · 下载中", fileMessageSubtitle(zh, "8.5 KB", "TXT", FlareMediaDownloadState(FlareMediaDownloadStatus.Downloading)))
        assertEquals("8.5 KB · TXT · 下载中 40%", fileMessageSubtitle(zh, "8.5 KB", "TXT", FlareMediaDownloadState(FlareMediaDownloadStatus.Downloading, 40)))
        assertEquals("8.5 KB · TXT · 已下载", fileMessageSubtitle(zh, "8.5 KB", "TXT", FlareMediaDownloadState(FlareMediaDownloadStatus.Done)))
        assertEquals("2 MB · Downloaded", fileMessageSubtitle(en, "2 MB", null, FlareMediaDownloadState(FlareMediaDownloadStatus.Done)))
        assertEquals("", fileMessageSubtitle(zh, "", null, null))
    }

    @Test fun theFileTypeIsTheNamesExtension() {
        assertEquals("TXT", flareFileExtension("连调测试.txt"))
        assertEquals("GZ", flareFileExtension("backup.tar.gz"))
        assertEquals("PDF", flareFileExtension(" spec.pdf "))
        assertNull(flareFileExtension("README"))
        assertNull(flareFileExtension("notes.markdown1"))
        assertNull(flareFileExtension("trailing."))
    }

    @Test fun aVideoOfUnknownLengthHasNoBadge() {
        assertEquals("", videoDurationLabel(0))
        assertEquals("", videoDurationLabel(-3))
        assertEquals("00:08", videoDurationLabel(8))
        assertEquals("01:15", videoDurationLabel(75))
    }

    @Test fun thePlayersKeysHandBackTheVideoAndNameItsMessage() {
        val video = FlareVideoContent("https://cdn/v.mp4", durationSec = 12)
        val intents = mutableListOf<String>()
        val opened = flareVideoPresentation(
            "https://cdn/v.mp4", video, messageId = "v1",
            onReveal = { intents += "reveal ${(it as FlareVideoContent).url}" },
        ) { intents += "download ${(it as FlareVideoContent).url}" }
        assertEquals("v1", opened.messageId)
        assertNotNull(opened.onDownload).invoke()
        assertNotNull(opened.onReveal).invoke()
        assertEquals(listOf("download https://cdn/v.mp4", "reveal https://cdn/v.mp4"), intents)
        assertNull(flareVideoPresentation("https://cdn/v.mp4", video, onDownload = null).onReveal)
    }

    @Test fun aGalleryPageShowsItsOwnPictureInItsFolder() {
        val timeline = listOf(
            FlareMessageData("m1", "u", "U", FlareImageContent("https://cdn/1.jpg")),
            FlareMessageData("m2", "u", "U", FlareImageContent("https://cdn/2.jpg")),
        )
        val shown = mutableListOf<String>()
        val gallery = FlareTimelineGallery(flareImageGalleryItems(timeline), reveal = { shown += "reveal ${it.messageId}" }) { shown += "download ${it.messageId}" }
        val opened = assertIs<FlareMediaPresentation.Gallery>(flareImagePresentation(gallery, "m1", 0, "https://cdn/1.jpg"))
        assertEquals(listOf("m1", "m2"), opened.messageIds)
        assertNotNull(opened.onReveal).invoke(1)
        assertNotNull(opened.onDownload).invoke(0)
        assertEquals(listOf("reveal m2", "download m1"), shown)
        // No download handler, no key at all: the folder is what the download key becomes.
        val silent = assertIs<FlareMediaPresentation.Gallery>(
            flareImagePresentation(FlareTimelineGallery(gallery.items, reveal = { shown += "x" }, download = null), "m1", 0, "https://cdn/1.jpg"),
        )
        assertNull(silent.onReveal)
        // A picture alone keeps its body's keys and names its message.
        val alone = assertIs<FlareMediaPresentation.Image>(flareImagePresentation(null, "m9", 0, "https://cdn/x.jpg", onDownload = {}, onReveal = { shown += "body" }))
        assertEquals("m9", alone.messageId)
        assertNotNull(alone.onReveal).invoke()
        assertEquals("body", shown.last())
    }

    @Test fun aDownloadStateSaysWhetherTheMediaIsSaved() {
        assertEquals(false, FlareMediaDownloadState().isSaved)
        assertEquals(true, FlareMediaDownloadState(FlareMediaDownloadStatus.Done).isSaved)
        assertEquals(true, FlareMediaDownloadState(FlareMediaDownloadStatus.Downloading, 10).isDownloading)
        assertEquals(false, FlareMediaDownloadState(FlareMediaDownloadStatus.Failed).isSaved)
    }
}
