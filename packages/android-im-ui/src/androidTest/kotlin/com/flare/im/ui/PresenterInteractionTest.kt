package com.flare.im.ui

import android.view.KeyEvent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasAnyDescendant
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isDialog
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Kit presenters as a host uses them: the modal BottomSheet and the toast stack. */
class PresenterInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()

    private fun pressSystemBack() = InstrumentationRegistry.getInstrumentation().sendKeyDownUpSync(KeyEvent.KEYCODE_BACK)

    private var closes = 0

    private fun showSheet(dismissible: Boolean = true) {
        compose.setContent { MaterialTheme {
            var open by remember { mutableStateOf(true) }
            if (open) BottomSheet(onClose = { closes++; open = false }, title = "消息操作", dismissible = dismissible) {
                Text("面板内容")
            }
        } }
        compose.waitForIdle()
    }

    @Test fun theSheetIsADialogPaneNamedByItsTitle() {
        showSheet()
        compose.onNode(isDialog()).assertExists()
        compose.onNode(SemanticsMatcher.expectValue(SemanticsProperties.PaneTitle, "消息操作")).assertExists()
        compose.onNodeWithText("面板内容").assertIsDisplayed()
    }

    @Test fun systemBackClosesADismissibleSheet() {
        showSheet()
        pressSystemBack()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        assertEquals(1, closes)
    }

    @Test fun aTapOnTheScrimClosesButATapInsideDoesNot() {
        showSheet()
        compose.onNodeWithText("面板内容").performClick()
        compose.waitForIdle()
        assertEquals(0, closes)
        compose.onNodeWithContentDescription(strings.close).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        assertEquals(1, closes)
    }

    @Test fun aSheetThatIsNotDismissibleIgnoresBackAndHasNoScrimTarget() {
        showSheet(dismissible = false)
        compose.onNodeWithContentDescription(strings.close).assertDoesNotExist()
        pressSystemBack()
        compose.waitForIdle()
        compose.onNodeWithText("面板内容").assertIsDisplayed()
        assertEquals(0, closes)
    }

    @Test fun toastsStackUpToThreeInAPoliteLiveRegion() {
        val toasts = FlareToastState()
        compose.setContent { MaterialTheme { FlareToastHost(state = toasts) { Box(Modifier.fillMaxSize()) } } }
        compose.runOnIdle { (1..4).forEach { toasts.show("提示 $it") } }
        compose.onNodeWithText("提示 1").assertDoesNotExist()
        (2..4).forEach { compose.onNodeWithText("提示 $it").assertIsDisplayed() }
        compose.onNode(
            SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite) and hasAnyDescendant(hasText("提示 4")),
        ).assertExists()
        compose.onAllNodesWithContentDescription(strings.close).assertCountEquals(3).onFirst().performClick()
        compose.onNodeWithText("提示 2").assertDoesNotExist()
        compose.onAllNodesWithContentDescription(strings.close).assertCountEquals(2)
    }

    @Test fun toastsTimeOutAndTheirActionDismissesThem() {
        var undone = 0
        compose.setContent { MaterialTheme {
            FlareToastHost {
                val toast = LocalFlareToast.current
                Button(label = "删除", onClick = {
                    toast.show("已删除", actionLabel = "撤销", onAction = { undone++ }, durationMs = 0)
                    toast.show("网络异常", tone = FlareStatusTone.Danger)
                })
            }
        } }
        compose.onNodeWithText("删除").performClick()
        compose.onNodeWithText("网络异常").assertIsDisplayed()
        compose.mainClock.advanceTimeBy(4_500)
        compose.onNodeWithText("网络异常").assertIsDisplayed()
        compose.mainClock.advanceTimeBy(2_000)
        compose.onNodeWithText("网络异常").assertDoesNotExist()
        compose.onNodeWithText("已删除").assertIsDisplayed()
        compose.onNodeWithText("撤销").performClick()
        compose.onAllNodesWithText("已删除").assertCountEquals(0)
        assertEquals(1, undone)
    }

    @Test fun theConfirmPresenterShowsBusyThenTheErrorAndConfirmingAgainRetries() {
        var attempts = 0
        var result: Boolean? = null
        compose.setContent { MaterialTheme {
            FlareToastHost {
                val dialogs = LocalFlareDialog.current
                val scope = rememberCoroutineScope()
                Button(label = "退出群聊", onClick = {
                    scope.launch {
                        result = dialogs.confirm(FlareConfirmOptions("退出群聊", "退出后将不再接收该群消息。", target = "设计评审组", confirmText = "退出", action = {
                            attempts += 1
                            if (attempts == 1) error("退出失败，请重试。")
                        }))
                    }
                })
            }
        } }
        compose.onNodeWithText("退出群聊").performClick()
        compose.onNode(isDialog()).assertExists()
        compose.onNodeWithText("设计评审组").assertIsDisplayed()
        compose.onNodeWithText("退出").performClick()
        compose.onNodeWithText("退出失败，请重试。").assertIsDisplayed()
        compose.onNode(isDialog()).assertExists()
        compose.onNodeWithText("退出").performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        assertEquals(2, attempts)
        assertEquals(true, result)
    }

    @Test fun thePromptKeepsTheDraftWithTheErrorAndReturnsTheValueOnRetry() {
        var fail = true
        var result: String? = null
        compose.setContent { MaterialTheme {
            FlareToastHost {
                val dialogs = LocalFlareDialog.current
                val scope = rememberCoroutineScope()
                Button(label = "修改备注", onClick = {
                    scope.launch {
                        result = dialogs.prompt(FlarePromptOptions("修改备注", value = "", placeholder = "备注名", maxLength = 20, confirmText = "保存", submit = {
                            if (fail) error("保存失败，请重试。")
                        }))
                    }
                })
            }
        } }
        compose.onNodeWithText("修改备注").performClick()
        compose.onNodeWithText("保存").assertIsNotEnabled()
        compose.onNode(hasSetTextAction()).performTextInput(" 老陈 ")
        compose.onNodeWithText("保存").performClick()
        compose.onNodeWithText("保存失败，请重试。").assertIsDisplayed()
        compose.onNode(hasSetTextAction() and hasText(" 老陈 ")).assertExists()
        fail = false
        compose.onNodeWithText("保存").performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        assertEquals("老陈", result)
    }

    @Test fun cancellingThePromptResolvesNull() {
        var result: String? = "unset"
        compose.setContent { MaterialTheme {
            FlareToastHost {
                val dialogs = LocalFlareDialog.current
                val scope = rememberCoroutineScope()
                Button(label = "评论", onClick = { scope.launch { result = dialogs.prompt(FlarePromptOptions("评论", placeholder = "说点什么…")) } })
            }
        } }
        compose.onNodeWithText("评论").performClick()
        compose.onNode(hasSetTextAction()).performTextReplacement("草稿")
        compose.onNodeWithText(strings.cancel).performClick()
        compose.waitForIdle()
        compose.onNode(isDialog()).assertDoesNotExist()
        assertEquals(null, result)
    }
}
