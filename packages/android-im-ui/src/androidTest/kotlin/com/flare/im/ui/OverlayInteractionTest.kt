package com.flare.im.ui

import android.provider.Settings
import android.view.KeyEvent
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.click
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasAnyAncestor
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isDialog
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import kotlin.math.abs

/**
 * The overlay family as a host uses it: Drawer and Modal open and close, the token scrim closes them, system back
 * and Escape step back or close, a locked overlay ignores them, the drawer docks to its inline edge under RTL and
 * leaves a scrim gutter, BottomSheet's automatic presentation picks sheet or Modal from the form factor, bodies
 * are bounded, and toasts show above an open overlay.
 */
class OverlayInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val strings = FlareStrings()
    private val instrumentation = InstrumentationRegistry.getInstrumentation()

    private fun press(keyCode: Int) {
        instrumentation.sendKeyDownUpSync(keyCode)
        compose.waitForIdle()
    }

    private fun pane(name: String) = compose.onNode(SemanticsMatcher.expectValue(SemanticsProperties.PaneTitle, name))

    /** The dialog window's root: it spans the whole display, scrim included. */
    private fun window() = compose.onNode(isDialog())

    private fun formFactor(widthDp: Int) = object : FlarePlatformAdapter {
        override val capabilities = FlarePlatformCapabilities.android(widthDp = widthDp)
    }

    private fun near(expected: Dp, actual: Dp, what: String) =
        assertTrue("$what: expected $expected, was $actual", abs(expected.value - actual.value) <= 1f)

    private var closes = 0
    private var backs = 0

    private data class DrawerCase(
        val dismissible: Boolean = true,
        val showBack: Boolean = false,
        val placement: FlareDrawerPlacement = FlareDrawerPlacement.End,
        val direction: LayoutDirection = LayoutDirection.Ltr,
    )

    /** The drawer under test; a new case (or a reopen) composes a fresh drawer. setContent runs once per test. */
    private var drawer by mutableStateOf<DrawerCase?>(null)
    private var composed = false

    private fun showDrawer(case: DrawerCase = DrawerCase()) {
        if (composed) {
            compose.runOnIdle { drawer = null }
            compose.runOnIdle { drawer = case }
            compose.waitForIdle()
            return
        }
        composed = true
        drawer = case
        compose.setContent { MaterialTheme {
            drawer?.let { current ->
                key(current) {
                    CompositionLocalProvider(LocalLayoutDirection provides current.direction) {
                        Drawer(
                            onClose = { closes++; drawer = null },
                            title = "群详情",
                            placement = current.placement,
                            dismissible = current.dismissible,
                            showBack = current.showBack,
                            onBack = { backs++ },
                        ) { Text("抽屉内容") }
                    }
                }
            }
        } }
        compose.waitForIdle()
    }

    @Test fun aDrawerIsADialogPaneNamedByItsTitleAndItsCloseButtonClosesIt() {
        showDrawer()
        window().assertExists()
        pane("群详情").assertExists()
        compose.onNodeWithText("抽屉内容").assertIsDisplayed()
        // One close control: the header button. The scrim is not announced a second time.
        compose.onAllNodesWithContentDescription(strings.close).assertCountEquals(1)
        compose.onNodeWithContentDescription(strings.close).performClick()
        compose.waitForIdle()
        window().assertDoesNotExist()
        assertEquals(1, closes)
    }

    @Test fun aTapOnTheScrimGutterClosesTheDrawerButATapInsideDoesNot() {
        showDrawer()
        compose.onNodeWithText("抽屉内容").performClick()
        compose.waitForIdle()
        assertEquals(0, closes)
        // An end drawer in LTR leaves the scrim on the left.
        window().performTouchInput { click(Offset(10f, centerY)) }
        compose.waitForIdle()
        window().assertDoesNotExist()
        assertEquals(1, closes)
    }

    @Test fun systemBackAndEscapeCloseADrawerWithoutABackControl() {
        showDrawer()
        press(KeyEvent.KEYCODE_BACK)
        window().assertDoesNotExist()
        assertEquals(1, closes)

        showDrawer()
        press(KeyEvent.KEYCODE_ESCAPE)
        window().assertDoesNotExist()
        assertEquals(2, closes)
    }

    @Test fun withABackControlBackAndEscapeStepBackInsteadOfClosing() {
        showDrawer(DrawerCase(showBack = true))
        compose.onNodeWithContentDescription(strings.back).assertIsEnabled()
        press(KeyEvent.KEYCODE_BACK)
        press(KeyEvent.KEYCODE_ESCAPE)
        compose.onNodeWithContentDescription(strings.back).performClick()
        compose.waitForIdle()
        assertEquals(3, backs)
        assertEquals(0, closes)
        pane("群详情").assertExists()
    }

    @Test fun aLockedDrawerIgnoresBackEscapeAndTheScrimAndDisablesItsControls() {
        showDrawer(DrawerCase(dismissible = false, showBack = true))
        compose.onNodeWithContentDescription(strings.close).assertIsNotEnabled()
        compose.onNodeWithContentDescription(strings.back).assertIsNotEnabled()
        press(KeyEvent.KEYCODE_BACK)
        press(KeyEvent.KEYCODE_ESCAPE)
        window().performTouchInput { click(Offset(10f, centerY)) }
        compose.waitForIdle()
        compose.onNodeWithText("抽屉内容").assertIsDisplayed()
        assertEquals(0, backs)
        assertEquals(0, closes)
    }

    @Test fun theDrawerDocksToItsInlineEdgeAndLeavesAScrimGutter() {
        for ((placement, direction) in listOf(
            FlareDrawerPlacement.End to LayoutDirection.Ltr,
            FlareDrawerPlacement.End to LayoutDirection.Rtl,
            FlareDrawerPlacement.Start to LayoutDirection.Ltr,
        )) {
            showDrawer(DrawerCase(placement = placement, direction = direction))
            val screen = window().getUnclippedBoundsInRoot()
            val panel = pane("群详情").getUnclippedBoundsInRoot()
            val onRight = flareDrawerSlidesFromRight(placement, direction)
            if (onRight) near(screen.right, panel.right, "$placement/$direction docks right")
            else near(screen.left, panel.left, "$placement/$direction docks left")
            near(flareDrawerWidth(FlareSizes.componentSheetWidth, screen.right - screen.left), panel.right - panel.left, "width")
            assertTrue("a touch target of scrim remains", (screen.right - screen.left) - (panel.right - panel.left) >= FlareSizes.touchTarget - 1.dp)
            near(screen.bottom - screen.top, panel.bottom - panel.top, "full height")
        }
    }

    @Test fun aModalIsCenteredClampedAndLockedWhileBusy() {
        var busy by mutableStateOf(true)
        compose.setContent { MaterialTheme {
            var open by remember { mutableStateOf(true) }
            if (open) Modal(onClose = { closes++; open = false }, title = "全局搜索", busy = busy, footer = { Text("底部按钮") }) {
                Text("模态内容")
            }
        } }
        compose.waitForIdle()
        val screen = window().getUnclippedBoundsInRoot()
        val box = pane("全局搜索").getUnclippedBoundsInRoot()
        near(flareModalWidth(FlareSizes.componentSheetDialogWidth, screen.right - screen.left), box.right - box.left, "width")
        near((screen.left + screen.right) / 2, (box.left + box.right) / 2, "centered")
        compose.onNodeWithText("底部按钮").assertIsDisplayed()
        compose.onNodeWithContentDescription(strings.close).assertIsNotEnabled()
        press(KeyEvent.KEYCODE_BACK)
        window().performTouchInput { click(Offset(10f, 10f)) }
        compose.waitForIdle()
        assertEquals(0, closes)

        busy = false
        compose.onNodeWithContentDescription(strings.close).assertIsEnabled()
        press(KeyEvent.KEYCODE_ESCAPE)
        window().assertDoesNotExist()
        assertEquals(1, closes)
    }

    @Composable
    private fun AutoSheet(widthDp: Int) {
        FlarePlatformProvider(formFactor(widthDp)) {
            BottomSheet(onClose = {}, title = "选择成员") {
                LazyColumn(Modifier.weight(1f, fill = false)) { items(200) { Text("成员 $it") } }
            }
        }
    }

    @Test fun onAPhoneAnAutoSheetSitsOnTheBottomEdgeAndBoundsItsLazyContent() {
        compose.setContent { MaterialTheme { AutoSheet(widthDp = 390) } }
        compose.waitForIdle()
        val screen = window().getUnclippedBoundsInRoot()
        val sheet = pane("选择成员").getUnclippedBoundsInRoot()
        near(screen.bottom, sheet.bottom, "bottom edge")
        // A lazy list with weight inside the sheet is measured, not collapsed to nothing.
        compose.onNodeWithText("成员 0").assertIsDisplayed()
        assertTrue("capped below the window", sheet.bottom - sheet.top < screen.bottom - screen.top)
    }

    @Test fun offThePhoneAnAutoSheetHandsItsContentToACenteredModal() {
        compose.setContent { MaterialTheme { AutoSheet(widthDp = 1024) } }
        compose.waitForIdle()
        val screen = window().getUnclippedBoundsInRoot()
        val box = pane("选择成员").getUnclippedBoundsInRoot()
        // Centered in the window after the bars, so clear of both edges rather than on the bottom one.
        assertTrue("clear of the bottom edge", screen.bottom - box.bottom >= FlareSizes.spacingXl - 1.dp)
        assertTrue("clear of the top edge", box.top - screen.top >= FlareSizes.spacingXl - 1.dp)
        compose.onNodeWithText("成员 0").assertIsDisplayed()
        // Sheet chrome: no close button; the scrim stays the announced close action.
        compose.onAllNodesWithContentDescription(strings.close).assertCountEquals(1)
    }

    @Test fun dangerConfirmStacksItsKeysOnAPhoneAndLinesThemUpOnWideLayouts() {
        var widthDp by mutableStateOf(390)
        compose.setContent { MaterialTheme {
            key(widthDp) {
                FlarePlatformProvider(formFactor(widthDp)) {
                    DangerConfirm(title = "删除好友", description = "删除后将清空聊天记录。", target = "Ann", confirmText = "删除", cancelText = "取消", onConfirm = {}, onCancel = {})
                }
            }
        } }
        for ((width, stacked) in listOf(390 to true, 1024 to false)) {
            compose.runOnIdle { widthDp = width }
            compose.waitForIdle()
            val cancel = compose.onNodeWithText("取消").getUnclippedBoundsInRoot()
            val confirm = compose.onNodeWithText("删除").getUnclippedBoundsInRoot()
            if (stacked) assertTrue("confirm under cancel at $width", confirm.top >= cancel.bottom - 1.dp)
            else near(cancel.top, confirm.top, "one row at $width")
        }
    }

    @Test fun toastsShowAboveAnOpenOverlayAndReturnToTheHostWhenItCloses() {
        val toasts = FlareToastState()
        var open by mutableStateOf(true)
        compose.setContent { MaterialTheme {
            FlareToastHost(state = toasts) {
                Box(Modifier.fillMaxSize())
                if (open) Drawer(onClose = { open = false }, title = "群详情") { Text("抽屉内容") }
            }
        } }
        compose.waitForIdle()
        compose.runOnIdle { toasts.show("保存失败", durationMs = 0) }
        // Drawn once, in the drawer's window above the scrim, with a working close control.
        compose.onAllNodesWithText("保存失败").assertCountEquals(1)
        compose.onNode(hasText("保存失败") and hasAnyAncestor(isDialog())).assertIsDisplayed()
        val toastClose = hasContentDescription(strings.close) and
            hasAnyAncestor(SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite))
        compose.onNode(toastClose).performClick()
        compose.onAllNodesWithText("保存失败").assertCountEquals(0)

        compose.runOnIdle { toasts.show("已复制", durationMs = 0) }
        compose.onNode(hasText("已复制") and hasAnyAncestor(isDialog())).assertIsDisplayed()
        open = false
        compose.waitForIdle()
        window().assertDoesNotExist()
        compose.onAllNodesWithText("已复制").assertCountEquals(1)
        compose.onNode(hasText("已复制") and !hasAnyAncestor(isDialog())).assertIsDisplayed()
    }

    @Test fun theCommandPaletteFitsANarrowWindow() {
        compose.setContent { MaterialTheme {
            CommandPalette(
                open = true, query = "", groups = emptyList(), label = "命令", placeholder = "搜索命令", emptyText = "没有命令",
                onQueryChange = {}, onInvoke = {}, onClose = {},
            )
        } }
        compose.waitForIdle()
        val screenWidth = instrumentation.targetContext.resources.configuration.screenWidthDp.dp
        val palette = pane("命令").getUnclippedBoundsInRoot()
        assertTrue("never wider than the window minus its margins", palette.right - palette.left <= screenWidth - FlareSizes.spacingXl * 2 + 1.dp)
        assertTrue("never wider than the token cap", palette.right - palette.left <= FlareSizes.bubbleMaxWidth + 1.dp)
    }

    /** With animations on, the drawer plays its slide out and only then tells the host. */
    @Test fun aDrawerStillClosesWithAnimationsOn() {
        val resolver = instrumentation.targetContext.contentResolver
        val previous = Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)
        fun scale(value: Float) {
            instrumentation.uiAutomation.executeShellCommand("settings put global animator_duration_scale $value").close()
            val deadline = System.currentTimeMillis() + 5_000
            while (Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) != value &&
                System.currentTimeMillis() < deadline) Thread.sleep(50)
        }
        scale(1f)
        try {
            val closed = mutableStateOf(false)
            compose.setContent { MaterialTheme {
                if (!closed.value) Drawer(onClose = { closed.value = true }, title = "群详情") { Text("抽屉内容") }
            } }
            compose.onNodeWithText("抽屉内容").assertIsDisplayed()
            compose.onNodeWithContentDescription(strings.close).performClick()
            compose.waitUntil(5_000) { closed.value }
            window().assertDoesNotExist()
        } finally {
            scale(previous)
        }
    }
}
