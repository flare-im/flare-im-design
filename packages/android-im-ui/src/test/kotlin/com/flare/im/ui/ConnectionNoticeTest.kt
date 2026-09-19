package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The connection notice every shell shows: copy, tone, progress and the way back per phase. */
class ConnectionNoticeTest {
    private val zh = FlareStrings()

    @Test fun connectedShowsNothingAndAttemptsPulseInTheWarningTone() {
        assertNull(flareConnectionNotice(FlareConnectionPhase.Connected, zh))
        assertEquals(
            FlareConnectionNotice(FlareConnectionPhase.Connecting, "正在连接…", FlareStatusTone.Warning, pulse = true),
            flareConnectionNotice(FlareConnectionPhase.Connecting, zh),
        )
        assertEquals(
            FlareConnectionNotice(FlareConnectionPhase.Reconnecting, "连接已断开，正在重连…", FlareStatusTone.Warning, pulse = true),
            flareConnectionNotice(FlareConnectionPhase.Reconnecting, zh, reason = "网络切换"),
        )
        assertEquals(
            FlareConnectionNotice(FlareConnectionPhase.Offline, "网络不可用，恢复后会自动重连", FlareStatusTone.Warning, pulse = false),
            flareConnectionNotice(FlareConnectionPhase.Offline, zh),
        )
    }

    @Test fun disconnectedNamesTheReasonAndOffersReconnectOnlyWhenTheHostCan() {
        assertEquals(
            FlareConnectionNotice(FlareConnectionPhase.Disconnected, "连接已断开", FlareStatusTone.Warning, pulse = false),
            flareConnectionNotice(FlareConnectionPhase.Disconnected, zh, reason = "  "),
        )
        assertEquals(
            FlareConnectionNotice(
                FlareConnectionPhase.Disconnected, "连接已断开：服务器维护", FlareStatusTone.Warning, pulse = false,
                recovery = FlareConnectionRecovery.Reconnect, recoveryText = "重新连接",
            ),
            flareConnectionNotice(FlareConnectionPhase.Disconnected, zh, reason = "服务器维护", canReconnect = true),
        )
    }

    @Test fun kickedAndExpiredAreDangerAndAlwaysOfferToSignInAgain() {
        assertEquals(
            FlareConnectionNotice(
                FlareConnectionPhase.Kicked, "账号已在其他设备登录", FlareStatusTone.Danger, pulse = false,
                recovery = FlareConnectionRecovery.SignIn, recoveryText = "重新登录",
            ),
            flareConnectionNotice(FlareConnectionPhase.Kicked, zh, canReconnect = true),
        )
        // A kicked reason replaces the default text; an expired session keeps its own.
        assertEquals("在 iPad 上登录", flareConnectionNotice(FlareConnectionPhase.Kicked, zh, reason = "在 iPad 上登录")?.text)
        val expired = flareConnectionNotice(FlareConnectionPhase.Expired, zh, reason = "token expired")
        assertEquals("登录已过期" to FlareConnectionRecovery.SignIn, expired?.text to expired?.recovery)
    }

    @Test fun theCopyComesFromTheStringsTable() {
        val en = FlareStrings {
            connectionDisconnectedReason = { "Disconnected: $it" }
            connectionSignIn = "Sign in again"
            connectionKicked = "Your account signed in on another device"
        }
        assertEquals("Disconnected: maintenance", flareConnectionNotice(FlareConnectionPhase.Disconnected, en, reason = "maintenance")?.text)
        assertEquals("Your account signed in on another device" to "Sign in again", flareConnectionNotice(FlareConnectionPhase.Kicked, en).let { it?.text to it?.recoveryText })
    }
}
