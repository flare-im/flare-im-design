package com.flare.im.ui

import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Confirm and prompt presenter: one dialog at a time, busy while the host's work runs, errors keep it open for a retry. */
class FlareDialogStateTest {
    private suspend fun FlareDialogState.until(condition: (FlareDialogRequest?) -> Boolean) {
        withTimeout(2_000) { while (!condition(request)) yield() }
    }

    @Test fun aConfirmationResolvesTrueOnConfirmAndFalseOnCancel() = runBlocking {
        val state = FlareDialogState()
        val confirmed = async { state.confirm(FlareConfirmOptions("删除好友", "确定删除？", target = "陈默")) }
        state.until { it != null }
        assertEquals("陈默", state.request?.confirm?.target)
        state.accept()
        assertTrue(confirmed.await())
        assertNull(state.request)

        val cancelled = async { state.confirm(FlareConfirmOptions("删除好友", "确定删除？")) }
        state.until { it != null }
        state.cancel()
        assertFalse(cancelled.await())
        assertNull(state.request)
    }

    @Test fun aFailedActionKeepsTheDialogOpenWithItsErrorAndConfirmRetries() = runBlocking {
        val state = FlareDialogState()
        var attempts = 0
        val confirmed = async {
            state.confirm(FlareConfirmOptions("移出群聊", "移出后对方将不再接收本群消息。", action = {
                attempts += 1
                if (attempts == 1) error("移出失败，请重试。")
            }))
        }
        state.until { it != null }
        state.accept()
        state.until { it?.error != null }
        assertEquals("移出失败，请重试。", state.request?.error)
        assertFalse(state.request!!.busy)
        // Cancel is ignored while busy, and confirming again runs the action again.
        state.accept()
        assertTrue(confirmed.await())
        assertEquals(2, attempts)
        assertNull(state.request)
    }

    @Test fun cancelAndConfirmAreIgnoredWhileTheActionRuns() = runBlocking {
        val state = FlareDialogState()
        val gate = kotlinx.coroutines.CompletableDeferred<Unit>()
        val confirmed = async { state.confirm(FlareConfirmOptions("退出群聊", "确定退出？", action = { gate.await() })) }
        state.until { it != null }
        state.accept()
        state.until { it?.busy == true }
        state.cancel()
        state.accept()
        assertNotNull(state.request)
        // A newer request made while busy resolves as cancelled at once.
        assertFalse(state.confirm(FlareConfirmOptions("另一个", "不会出现")))
        gate.complete(Unit)
        assertTrue(confirmed.await())
    }

    @Test fun aPromptReturnsTheTrimmedValueAndWaitsForTextUnlessEmptyIsAllowed() = runBlocking {
        val state = FlareDialogState()
        val submitted = mutableListOf<String>()
        val value = async {
            state.prompt(FlarePromptOptions("修改备注", value = "老陈", maxLength = 20, submit = { submitted += it }))
        }
        state.until { it != null }
        assertEquals("老陈", state.request?.prompt?.value)
        state.accept("   ")
        assertFalse(state.request!!.busy)
        state.accept("  陈默  ")
        assertEquals("陈默", value.await())
        assertEquals(listOf("陈默"), submitted)

        val cleared = async { state.prompt(FlarePromptOptions("修改备注", allowEmpty = true)) }
        state.until { it != null }
        state.accept("  ")
        assertEquals("", cleared.await())
    }

    @Test fun aFailedSubmitKeepsThePromptOpenAndARetrySucceeds() = runBlocking {
        val state = FlareDialogState()
        var fail = true
        val value = async {
            state.prompt(FlarePromptOptions("评论", submit = { if (fail) throw IllegalStateException("发送失败") }))
        }
        state.until { it != null }
        state.accept("好看")
        state.until { it?.error != null }
        assertEquals("发送失败", state.request?.error)
        fail = false
        state.accept("好看")
        assertEquals("好看", value.await())
    }

    @Test fun aNewerRequestReplacesAnIdleOne() = runBlocking {
        val state = FlareDialogState()
        val first = async { state.confirm(FlareConfirmOptions("第一个", "说明")) }
        state.until { it?.confirm?.title == "第一个" }
        val second = async { state.prompt(FlarePromptOptions("第二个")) }
        state.until { it?.prompt?.title == "第二个" }
        assertFalse(first.await())
        state.accept("值")
        assertEquals("值", second.await())
        assertNull(state.request)
    }

    @Test fun cancellingTheAskingCoroutineClosesItsDialog() = runBlocking {
        val state = FlareDialogState()
        val asking = async { state.confirm(FlareConfirmOptions("删除动态", "确定删除？")) }
        state.until { it != null }
        asking.cancel()
        state.until { it == null }
        assertNull(state.request)
    }
}
