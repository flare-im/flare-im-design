package com.flare.im.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Real emulator interactions; all device/session data are local fixtures. */
class SceneInteractionTest {
    @get:Rule val compose = createComposeRule()

    @Test fun devicePermissionAndBusyGuard() {
        val permission = mutableStateOf(FlareCapabilityState.Denied)
        val busy = mutableStateOf(false)
        var chosen = ""
        compose.setContent { MaterialTheme {
            CallDevicePicker(
                groups=listOf(FlareCallDeviceGroup(FlareCallDeviceKind.Microphone,"麦克风",selectedId="removed",devices=listOf(FlareCallDevice("usb","USB 麦克风")),busy=busy.value)),
                permission=permission.value,permissionText="权限说明",onSelect={_,id->chosen=id},
            )
        } }
        compose.onNodeWithText("选择设备").assertIsNotEnabled()
        compose.runOnIdle { permission.value=FlareCapabilityState.Available }
        compose.onNodeWithText("选择设备").performClick()
        compose.onNodeWithText("USB 麦克风").performClick()
        compose.runOnIdle { assertEquals("usb",chosen); busy.value=true }
        compose.onNodeWithText("选择设备").assertIsNotEnabled()
    }

    @Test fun currentSessionCannotBeRevoked() {
        var revoked=""
        compose.setContent { MaterialTheme {
            DeviceSessions(items=listOf(
                FlareDeviceSessionEntry(FlareSceneEntry("self","本机","当前",actions=listOf(FlareSceneAction("revoke","退出登录"))),current=true),
                FlareDeviceSessionEntry(FlareSceneEntry("other","其他设备","最近活跃",actions=listOf(FlareSceneAction("revoke","退出登录")))),
            ),onAction={id,_->revoked=id})
        } }
        compose.onAllNodesWithText("退出登录").assertCountEquals(1)
        compose.onNodeWithText("退出登录").performClick()
        compose.runOnIdle { assertEquals("other",revoked) }
    }

    @Test fun failedCallCanRecoverAndHangup() {
        var recovered=0;var ended=0
        compose.setContent { MaterialTheme {
            CallView(peerName="测试联系人",mode=FlareCallMode.Audio,state=FlareCallState.Failed,recoveryText="重新连接",onRecover={recovered++},onHangup={ended++})
        } }
        compose.onNodeWithText("重新连接").performScrollTo().performClick()
        compose.onNodeWithContentDescription("挂断").performScrollTo().performClick()
        compose.runOnIdle { assertEquals(1,recovered);assertEquals(1,ended) }
    }
}
