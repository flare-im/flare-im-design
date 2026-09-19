package com.flare.im.ui

import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Rule
import org.junit.Test

/** System back runs the innermost visible back control instead of leaving the activity. */
class NativeBackTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()

    private fun pressSystemBack() = compose.runOnUiThread { compose.activity.onBackPressedDispatcher.onBackPressed() }

    private fun hostHandlesBack(): Boolean = compose.runOnIdle { compose.activity.onBackPressedDispatcher.hasEnabledCallbacks() }

    @Test fun screenWithBackControlConsumesSystemBack() {
        val backs = mutableListOf<String>()
        compose.setContent { MaterialTheme { FlareScreen(title = "设置", onBack = { backs += "screen" }) { Text("正文") } } }
        pressSystemBack()
        compose.runOnIdle { assertEquals(listOf("screen"), backs) }
    }

    @Test fun innermostSurfaceWinsAndReleasesWhenGone() {
        val backs = mutableListOf<String>()
        val forwarding = mutableStateOf(true)
        compose.setContent { MaterialTheme {
            FlareScreen(title = "聊天", onBack = { backs += "chat" }, scroll = false) {
                ConversationHeader(identity = ConversationIdentity(id = "c1", title = "Ann"), showBack = true, onBack = { backs += "header" })
                if (forwarding.value) FlareScreen(title = "转发", onBack = { forwarding.value = false }) { Text("选择会话") }
            }
        } }
        pressSystemBack()
        compose.runOnIdle { assertFalse(forwarding.value) }
        pressSystemBack()
        compose.runOnIdle { assertEquals(listOf("header"), backs) }
    }

    @Test fun surfacesWithoutBackControlLeaveSystemBackToTheHost() {
        compose.setContent { MaterialTheme {
            FlareScreen(title = "消息") { Text("列表") }
            ConversationHeader(identity = ConversationIdentity(id = "c1", title = "Ann"), showBack = false, onBack = {})
            FlareGroupDetail(model = null)
        } }
        assertFalse(hostHandlesBack())
    }

    @Test fun hostWithoutNativeBackRegistersNothing() {
        val adapter = FlareUnsupportedPlatformAdapter(FlarePlatformCapabilities(nativeBack = false))
        compose.setContent { FlarePlatformProvider(adapter) { MaterialTheme { FlareScreen(title = "设置", onBack = {}) { Text("正文") } } } }
        assertFalse(hostHandlesBack())
    }
}
