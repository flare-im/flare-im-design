package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.test.platform.app.InstrumentationRegistry
import android.graphics.Bitmap
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class PluginTextActionsInteractionTest {
    @get:Rule val compose = createComposeRule()
    private fun card(actions: Boolean = true) = PluginViewModel.fromJson("""{
      "available":true,"title":"接龙","detail":true,
      "blocks":[{"kind":"text","text":"周五下午茶，一起点点心"}],
      "actions":${if (actions) """[{"id":"join","label":"参与接龙","style":"primary"},{"id":"end","label":"结束接龙","style":"danger"}]""" else "[]"}}
    """)
    private fun capture(name: String) {
        val bitmap = compose.onRoot().captureToImage().asAndroidBitmap()
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        File(context.filesDir, name).outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }
    @Test fun compactFooterKeepsTouchTargetsAndIndependentCallbacks() {
        val sent = mutableListOf<String>(); var opened = 0
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Light) { Box(Modifier.width(390.dp)) {
            PluginView(view = card(), onAction = { id, _ -> sent += id }, onOpenDetail = { opened++ })
        } } }
        val join = compose.onNodeWithText("参与接龙").getUnclippedBoundsInRoot()
        val end = compose.onNodeWithText("结束接龙").getUnclippedBoundsInRoot()
        val detail = compose.onNodeWithText("查看详情").getUnclippedBoundsInRoot()
        assertTrue(kotlin.math.abs((join.top.value + join.bottom.value - detail.top.value - detail.bottom.value) / 2) < 1f)
        assertTrue(join.right <= end.left && end.right <= detail.left)
        // Dp conversion of pixel bounds can round 48 to 47.99999.
        for (rect in listOf(join, end, detail)) { assertTrue("touch height: $rect", (rect.bottom - rect.top).value + 0.001f >= 48f); assertTrue("touch width: $rect", (rect.right - rect.left).value + 0.001f >= 48f) }
        capture("plugin-card-light.png")
        compose.onNodeWithText("参与接龙").performClick()
        compose.onNodeWithText("查看详情").performClick()
        compose.runOnIdle { assertEquals(listOf("join"), sent); assertEquals(1, opened) }
    }
    @Test fun detailsWithoutFooterActionsStaysInHeader() {
        compose.setContent { FlareThemeProvider { PluginView(view = card(false), onOpenDetail = {}) } }
        val title = compose.onNodeWithText("接龙").getUnclippedBoundsInRoot()
        val detail = compose.onNodeWithText("查看详情").getUnclippedBoundsInRoot()
        assertTrue(kotlin.math.abs((title.top.value + title.bottom.value - detail.top.value - detail.bottom.value) / 2) < 1f)
    }
    @Test fun narrowDarkBusyAndFailureRecoverWithoutLosingActions() {
        val busy = mutableStateOf(true); var sent = 0
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Dark) { Box(Modifier.width(220.dp)) {
            PluginView(view = card(), busy = busy.value, error = "暂时失败，请重试", onAction = { _, _ -> sent++ }, onOpenDetail = {})
        } } }
        compose.onNodeWithText("参与接龙").assertIsNotEnabled()
        compose.onNodeWithText("查看详情").assertIsNotEnabled()
        compose.onNodeWithText("暂时失败，请重试").assertExists()
        capture("plugin-card-dark.png")
        compose.runOnIdle { busy.value = false }
        compose.onNodeWithText("参与接龙").assertIsEnabled().performClick()
        compose.runOnIdle { assertEquals(1, sent) }
    }
}
