package com.flare.im.ui
import kotlin.test.*
class PermissionPromptTest {
    @Test fun actionVisibilityForEveryKindAndState() {
        for (kind in FlarePermissionKind.values()) {
            for (state in FlarePermissionState.values()) {
                val a = permissionActions(state, hasRequest = true, hasOpenSettings = true, hasDismiss = true)
                assertEquals(state == FlarePermissionState.Undetermined, a.request, "$kind/$state request")
                assertEquals(state == FlarePermissionState.Denied, a.openSettings, "$kind/$state openSettings")
                assertTrue(a.dismiss); assertTrue(a.enabled)
                val copy = defaultPermissionCopy(kind, state)
                assertTrue(copy.title.isNotEmpty()); assertTrue(copy.description.isNotEmpty())
                assertEquals(state == FlarePermissionState.Undetermined || state == FlarePermissionState.Denied, copy.primaryLabel.isNotEmpty(), "$kind/$state primaryLabel")
                assertTrue(defaultPermissionStateLabel(state).isNotEmpty())
                assertTrue(permissionIconName(kind) in flareIconNames, "$kind icon must resolve")
                assertTrue(permissionStateIconName(state) in flareIconNames, "$state icon must resolve")
            }
        }
    }
    @Test fun unsuppliedHandlersHiddenAndBusyDisables() {
        assertEquals(FlarePermissionActions(request = false, openSettings = false, dismiss = false, enabled = true),
            permissionActions(FlarePermissionState.Undetermined, hasRequest = false, hasOpenSettings = true, hasDismiss = false))
        assertEquals(FlarePermissionActions(request = false, openSettings = true, dismiss = true, enabled = false),
            permissionActions(FlarePermissionState.Denied, hasRequest = true, hasOpenSettings = true, hasDismiss = true, busy = true))
    }
    @Test fun featureLabelEmbeddedWithFallback() {
        assertTrue("发送语音消息" in defaultPermissionCopy(FlarePermissionKind.Microphone, FlarePermissionState.Undetermined, "发送语音消息").description)
        assertTrue("此功能" in defaultPermissionCopy(FlarePermissionKind.Microphone, FlarePermissionState.Denied, "  ").description)
        assertEquals("前往设置", defaultPermissionCopy(FlarePermissionKind.Notifications, FlarePermissionState.Denied).primaryLabel)
        assertEquals("允许", defaultPermissionCopy(FlarePermissionKind.Camera, FlarePermissionState.Undetermined).primaryLabel)
    }
}
