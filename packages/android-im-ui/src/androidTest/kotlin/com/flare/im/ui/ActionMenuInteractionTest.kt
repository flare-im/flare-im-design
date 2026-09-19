package com.flare.im.ui

import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.click
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.pressKey
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** ActionMenu as a host wires it: open from a trigger, choose, disabled rows, checkable rows, naming, back, Escape, outside taps and focus. */
class ActionMenuInteractionTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()

    private val menuName = "群聊操作"
    private val isButton = SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Button)
    private val isCheckbox = SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Checkbox)

    private val items = listOf(
        FlareActionItem("notify", "通知方式", icon = "notification", group = "prefs"),
        FlareActionItem("pin", "置顶群聊", icon = "pin", group = "prefs", pressed = true),
        FlareActionItem("mute", "消息免打扰", icon = "mute", group = "prefs", pressed = false),
        FlareActionItem("export", "导出聊天记录", icon = "download", group = "data", enabled = false, disabledReason = "仅群主可导出"),
        FlareActionItem("hidden", "隐藏的操作", visible = false),
        FlareActionItem("report", "举报", icon = "warning", group = "danger", danger = true, badge = "3", accessibilityLabel = "举报这个群聊"),
    )

    @Composable
    private fun Host(events: MutableList<String>, menuItems: List<FlareActionItem> = items) {
        var expanded by remember { mutableStateOf(false) }
        Box {
            Button(label = "更多", onClick = { expanded = true })
            ActionMenu(
                expanded = expanded,
                items = menuItems,
                onDismiss = { events += "dismiss"; expanded = false },
                onSelect = { events += "select:$it" },
                label = menuName,
            )
        }
    }

    @Test fun choosingARowClosesTheMenuBeforeReportingItsId() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme { Host(events) } }
        compose.onNodeWithText("更多").performClick()
        compose.onNodeWithContentDescription(menuName).assertExists()
        compose.onNodeWithText("通知方式").assert(isButton).assertIsEnabled().performClick()
        compose.runOnIdle { assertEquals(listOf("dismiss", "select:notify"), events) }
        compose.onAllNodesWithText("通知方式").assertCountEquals(0)
    }

    @Test fun aDisabledRowIsShownWithItsReasonAndNeverReports() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme { Host(events) } }
        compose.onNodeWithText("更多").performClick()
        val export = compose.onNode(hasText("导出聊天记录") and hasText("仅群主可导出"))
        export.assertIsDisplayed().assertIsNotEnabled()
        export.performClick()
        compose.runOnIdle { assertEquals(emptyList<String>(), events) }
        compose.onNodeWithText("通知方式").assertIsDisplayed()
    }

    @Test fun pressedRowsAreCheckableAndPlainRowsAreNot() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme { Host(events) } }
        compose.onNodeWithText("更多").performClick()
        compose.onNodeWithText("置顶群聊").assert(isCheckbox).assertIsOn()
        compose.onNodeWithText("消息免打扰").assert(isCheckbox).assertIsOff().performClick()
        compose.runOnIdle { assertEquals(listOf("dismiss", "select:mute"), events) }
        compose.onNodeWithText("更多").performClick()
        compose.onNodeWithText("通知方式").assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.ToggleableState))
    }

    @Test fun theMenuIsNamedHiddenItemsAreLeftOutAndARowCanBeRenamed() {
        compose.setContent { MaterialTheme { Host(mutableListOf()) } }
        compose.onNodeWithText("更多").performClick()
        compose.onNode(SemanticsMatcher.expectValue(SemanticsProperties.PaneTitle, menuName)).assertExists()
        compose.onAllNodesWithText("隐藏的操作").assertCountEquals(0)
        compose.onNodeWithContentDescription("举报这个群聊").assert(isButton).assertHasClickAction()
            .assert(hasText("举报") and hasText("3"))
    }

    @Test fun aMenuWithNothingVisibleNeverOpens() {
        compose.setContent { MaterialTheme {
            Box {
                ActionMenu(expanded = true, items = emptyList(), onDismiss = {}, onSelect = {}, label = "空菜单")
                ActionMenu(expanded = true, items = listOf(FlareActionItem("x", "看不见", visible = false)), onDismiss = {}, onSelect = {}, label = "全隐藏")
            }
        } }
        compose.onNodeWithContentDescription("空菜单").assertDoesNotExist()
        compose.onNodeWithContentDescription("全隐藏").assertDoesNotExist()
    }

    @Test fun backClosesTheMenuWithoutChoosing() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme { Host(events) } }
        compose.onNodeWithText("更多").performClick()
        compose.onNodeWithText("通知方式").assertIsDisplayed()
        // The menu is a focusable popup: once it holds window focus, system back goes to it, not the activity.
        compose.waitUntil(timeoutMillis = 5_000) { compose.runOnUiThread { !compose.activity.hasWindowFocus() } }
        InstrumentationRegistry.getInstrumentation().sendKeyDownUpSync(KeyEvent.KEYCODE_BACK)
        compose.runOnIdle { assertEquals(listOf("dismiss"), events) }
        compose.onAllNodesWithText("通知方式").assertCountEquals(0)
    }

    @Test fun escapeClosesTheMenuWithoutChoosing() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme { Host(events) } }
        compose.onNodeWithText("更多").performClick()
        compose.onNodeWithText("通知方式").assertIsDisplayed()
        compose.waitUntil(timeoutMillis = 5_000) { compose.runOnUiThread { !compose.activity.hasWindowFocus() } }
        InstrumentationRegistry.getInstrumentation().sendKeyDownUpSync(KeyEvent.KEYCODE_ESCAPE)
        compose.runOnIdle { assertEquals(listOf("dismiss"), events) }
        compose.onAllNodesWithText("通知方式").assertCountEquals(0)
    }

    @Test fun aTapBesideTheCardClosesTheMenuWithoutChoosing() {
        val events = mutableListOf<String>()
        compose.setContent { MaterialTheme { Host(events) } }
        compose.onNodeWithText("更多").performClick()
        compose.waitUntil(timeoutMillis = 5_000) { compose.runOnUiThread { !compose.activity.hasWindowFocus() } }
        // Just below the card: inside the popup window's shadow room, outside the menu itself.
        compose.onNodeWithContentDescription(menuName).performTouchInput {
            click(androidx.compose.ui.geometry.Offset(centerX, height + FlareSizes.spacingXs.toPx()))
        }
        compose.runOnIdle { assertEquals(listOf("dismiss"), events) }
        compose.onAllNodesWithText("通知方式").assertCountEquals(0)
    }

    @OptIn(ExperimentalTestApi::class)
    @Test fun keyboardFocusStartsOnTheFirstEnabledRowAndReturnsToTheTrigger() {
        val events = mutableListOf<String>()
        val menuItems = listOf(
            FlareActionItem("export", "导出聊天记录", enabled = false, disabledReason = "仅群主可导出"),
            FlareActionItem("notify", "通知方式"),
            FlareActionItem("pin", "置顶群聊", pressed = false),
        )
        compose.setContent { MaterialTheme { Host(events, menuItems) } }
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.setInTouchMode(false)
        try {
            // The mode change reaches the window asynchronously; focus requests only count once it has.
            compose.waitUntil(timeoutMillis = 5_000) { compose.runOnUiThread { !compose.activity.window.decorView.isInTouchMode } }
            val trigger = compose.onNodeWithText("更多")
            trigger.performSemanticsAction(SemanticsActions.RequestFocus)
            trigger.assertIsFocused()
            trigger.performKeyInput { pressKey(Key.Enter) }
            compose.onNodeWithText("通知方式").assertIsFocused()
            // Escape closes it and focus is back on the trigger.
            compose.onNodeWithText("通知方式").performKeyInput { pressKey(Key.Escape) }
            compose.runOnIdle { assertEquals(listOf("dismiss"), events) }
            compose.onAllNodesWithText("通知方式").assertCountEquals(0)
            trigger.assertIsFocused()
            // Choosing closes it the same way, without leaving focus on a removed row.
            trigger.performKeyInput { pressKey(Key.Enter) }
            compose.onNodeWithText("通知方式").assertIsFocused().performKeyInput { pressKey(Key.Enter) }
            compose.runOnIdle { assertEquals(listOf("dismiss", "dismiss", "select:notify"), events) }
            compose.onAllNodesWithText("通知方式").assertCountEquals(0)
            trigger.assertIsFocused()
        } finally {
            instrumentation.setInTouchMode(true)
        }
    }
}
