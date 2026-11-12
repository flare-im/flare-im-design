package com.flare.im.ui
import kotlin.test.*
class PermissionPromptTest {
    @Test fun actionVisibilityForEveryKindAndState() {
        for (kind in FlarePermissionKind.values()) {
            for (state in FlarePermissionState.values()) {
                val a = permissionActions(state, hasRequest = true, hasOpenSettings = true, hasDismiss = true)
                assertEquals(state == FlarePermissionState.Undetermined, a.request, "$kind/$state request")
                assertEquals(state == FlarePermissionState.Denied, a.openSettings, "$kind/$state openSettings")
                assertEquals(state != FlarePermissionState.Granted, a.dismiss, "$kind/$state dismiss"); assertTrue(a.enabled)
                val copy = defaultPermissionCopy(kind, state)
                assertTrue(copy.title.isNotEmpty())
                assertEquals(state != FlarePermissionState.Granted, copy.description.isNotEmpty(), "$kind/$state description")
                assertEquals(state == FlarePermissionState.Undetermined || state == FlarePermissionState.Denied, copy.primaryLabel.isNotEmpty(), "$kind/$state primaryLabel")
                assertTrue(defaultPermissionStateLabel(state).isNotEmpty())
                assertTrue(permissionIconName(kind) in flareIconNames, "$kind icon must resolve")
                assertTrue(permissionStateIconName(state) in flareIconNames, "$state icon must resolve")
            }
        }
    }
    @Test fun iconNamesPerKindAndState() {
        assertEquals(
            listOf("mic", "camera", "notification", "storage", "image", "people", "location", "screen-share"),
            FlarePermissionKind.values().map(::permissionIconName),
        )
        assertEquals(
            listOf("info", "error", "lock", "warning", "success"),
            FlarePermissionState.values().map(::permissionStateIconName),
        )
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
    @Test fun grantedDrawsNothingAndASoftAskOnlyWhatThePersonCanActOn() {
        assertEquals(
            listOf(FlarePermissionState.Undetermined, FlarePermissionState.Denied, FlarePermissionState.Restricted, FlarePermissionState.Unavailable),
            FlarePermissionState.values().filter { permissionPromptShows(it) },
        )
        assertEquals(
            listOf(FlarePermissionState.Undetermined, FlarePermissionState.Denied),
            FlarePermissionState.values().filter { permissionPromptShows(it, softAsk = true) },
        )
    }
    @Test fun notificationSoftAskHasItsOwnCopy() {
        val ask = defaultPermissionSoftAskCopy(FlarePermissionKind.Notifications, FlarePermissionState.Undetermined)
        assertEquals("及时收到新消息", ask.title)
        assertEquals("开启通知后，应用不在前台时也能收到新消息提醒。", ask.description)
        assertEquals("开启通知", ask.primaryLabel)
        val denied = defaultPermissionSoftAskCopy(FlarePermissionKind.Notifications, FlarePermissionState.Denied, strings = flareStringsEnglish())
        assertEquals("Open Settings", denied.primaryLabel)
        assertTrue("Settings" in denied.description)
        // Any other kind keeps its own copy in a soft-ask.
        assertEquals(
            defaultPermissionCopy(FlarePermissionKind.Camera, FlarePermissionState.Undetermined),
            defaultPermissionSoftAskCopy(FlarePermissionKind.Camera, FlarePermissionState.Undetermined),
        )
    }
}
