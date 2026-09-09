package com.flare.im.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

private const val HINT = "当前版本无法显示这条消息"
private const val UNSUPPORTED = "不支持的消息类型"

class UnknownMessageTest {
    @Test
    fun summaryWinsAsBody() {
        val p = unknownMessagePresentation(
            contentType = "flare.poll.v2", summary = "[投票] 周会时间",
            hint = HINT, unsupportedText = UNSUPPORTED,
        )
        assertEquals("[投票] 周会时间", p.body)
        assertTrue(p.hasSummary)
    }

    @Test
    fun blankSummaryFallsBackToHint() {
        val p = unknownMessagePresentation(
            contentType = "flare.poll.v2", summary = "   ",
            hint = HINT, unsupportedText = UNSUPPORTED,
        )
        assertEquals(HINT, p.body)
        assertFalse(p.hasSummary)
    }

    @Test
    fun titleUsesLabelThenGenericWording() {
        assertEquals("投票", unknownMessagePresentation(label = "投票", hint = HINT, unsupportedText = UNSUPPORTED).title)
        assertEquals(UNSUPPORTED, unknownMessagePresentation(label = "  ", hint = HINT, unsupportedText = UNSUPPORTED).title)
    }

    @Test
    fun rawTypeStaysDiagnosticNeverBody() {
        val p = unknownMessagePresentation(contentType = "flare.poll.v2", hint = HINT, unsupportedText = UNSUPPORTED)
        assertEquals("flare.poll.v2", p.diagnostic)
        assertEquals(HINT, p.body)
    }

    @Test
    fun missingOrBlankTypeYieldsNoDiagnostic() {
        assertEquals("", unknownMessagePresentation(hint = HINT, unsupportedText = UNSUPPORTED).diagnostic)
        assertEquals("", unknownMessagePresentation(contentType = "  ", hint = HINT, unsupportedText = UNSUPPORTED).diagnostic)
    }

    @Test
    fun everyInputIsTrimmed() {
        val p = unknownMessagePresentation(
            contentType = " x.y ", label = " 投票 ", summary = " hi ",
            hint = HINT, unsupportedText = UNSUPPORTED,
        )
        assertEquals(listOf("投票", "hi", "x.y"), listOf(p.title, p.body, p.diagnostic))
    }
}
