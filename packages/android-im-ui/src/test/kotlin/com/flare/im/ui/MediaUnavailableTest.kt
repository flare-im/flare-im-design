package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * A picture, a video or a voice message the host has no address for (it hands the kit [FlareGenericContent] under the
 * media's wire type) is still that kind of message: the content view draws [MediaUnavailableMessage] with these words
 * and icons, in the host's language, never the unsupported card. The other three kits draw the same body.
 */
class MediaUnavailableTest {
    private fun line(content: FlareGenericContent, strings: FlareStrings) =
        mediaUnavailableLine(flareMessageContentType(content).first, strings)

    @Test fun mediaWithoutAnAddressSaysItIsNotAvailableInBothLanguages() {
        val zh = FlareStrings()
        val en = flareStringsEnglish()
        assertEquals("image" to "图片暂时无法加载", line(FlareGenericContent("image", "图片"), zh))
        assertEquals("video" to "视频暂时无法加载", line(FlareGenericContent("video", "视频"), zh))
        assertEquals("mic" to "语音暂时无法加载", line(FlareGenericContent("audio", "语音"), zh))
        assertEquals("mic" to "语音暂时无法加载", line(FlareGenericContent("voice", ""), zh))
        assertEquals("image" to "Image isn't available right now", line(FlareGenericContent("image", ""), en))
        assertEquals("video" to "Video isn't available right now", line(FlareGenericContent("video", ""), en))
        assertEquals("mic" to "Voice message isn't available right now", line(FlareGenericContent("audio", ""), en))
    }

    @Test fun anyOtherTypeIsLeftToTheUnsupportedCard() {
        assertNull(line(FlareGenericContent("flare.poll.v9", "投票"), FlareStrings()))
        assertNull(line(FlareGenericContent("thread", ""), FlareStrings()))
    }
}
