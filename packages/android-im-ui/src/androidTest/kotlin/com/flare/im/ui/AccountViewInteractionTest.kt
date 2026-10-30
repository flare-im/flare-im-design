package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertTrue
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Real Compose interactions on fictional resolved account data, with no SDK/network calls. */
class AccountViewInteractionTest {
    @get:Rule val compose = createComposeRule()
    private val ref = PluginPageRef("test.account", "test.wallet")
    private fun wallet(deposit: Boolean = false) = PluginPageViewModel.fromJson("""{
      "available":true,"title":"钱包","fields":[{"label":"可用余额","value":"¥1,288.66"},{"label":"托管中","value":"¥68.00"}],
      "data":{"revision":"original"},"blocks":[{"kind":"rows","source":"test.ledger",
      "columns":[{"label":"金额"},{"label":"备注"},{"label":"时间","format":"time"}],
      "actions":[{"id":"open","label":"查看红包"}],
      "rows":[{"key":"tx-01","badge":{"text":"${if (deposit) "入账" else "收到红包"}"},
      "cells":[{"text":"+¥88.88"},{"text":"周五快乐"},{"text":"","timeMs":1793001900000}],
      "actions":${if (deposit) "[]" else """[{"id":"open","input":{"packetId":"packet-01"}}]"""}}]}]}
    """)
    private fun list() = compose.onNode(hasScrollToIndexAction())
    @Test fun narrowDarkBalanceMaskAndRefreshFailureRetainLedger() {
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Dark) { Box(Modifier.width(320.dp)) {
            FlarePluginPage(page = ref, view = wallet(), appearance = FlarePluginPageAppearance.Account, error = "暂时无法更新")
        } } }
        compose.onNodeWithText("暂时无法更新").assertExists()
        compose.onNodeWithContentDescription("隐藏余额").performClick()
        compose.onNodeWithContentDescription("¥1,288.66").assertDoesNotExist()
        compose.onNodeWithText("¥68.00").assertDoesNotExist()
        list().performScrollToNode(hasText("+¥88.88"))
        compose.onNodeWithText("+¥88.88").assertExists()
        list().performScrollToNode(hasContentDescription("显示余额"))
        compose.onNodeWithContentDescription("显示余额").performClick()
        compose.onNodeWithContentDescription("¥1,288.66").assertExists()
    }
    @Test fun detailActionKeepsOriginalPageDataAndBoundRow() {
        val sent = mutableListOf<PluginPageActionPayload>()
        compose.setContent { FlareThemeProvider { FlarePluginPage(page = ref, view = wallet(), appearance = FlarePluginPageAppearance.Account,
            onAction = { _, payload -> sent += payload }) } }
        list().performScrollToNode(hasText("周五快乐"))
        compose.onNodeWithText("周五快乐").performClick()
        compose.onNodeWithText("tx-01").assertExists()
        val bounds = compose.onNodeWithText("查看红包").getUnclippedBoundsInRoot()
        assertTrue((bounds.bottom - bounds.top).value >= FlareSizes.touchTarget.value)
        compose.onNodeWithText("查看红包").performClick()
        compose.runOnIdle {
            assertEquals(PluginPageActionPayload(ref, mapOf("revision" to "original"), PluginActionRow("tx-01", mapOf("packetId" to "packet-01"))), sent.single())
        }
    }
    @Test fun entryWithoutPacketActionStillHasLocalDetailsAndClose() {
        compose.setContent { FlareThemeProvider { FlarePluginPage(page = ref, view = wallet(deposit = true), appearance = FlarePluginPageAppearance.Account) } }
        list().performScrollToNode(hasText("周五快乐"))
        compose.onNodeWithText("周五快乐").performClick()
        compose.onNodeWithText("tx-01").assertExists()
        compose.onNodeWithText("查看红包").assertDoesNotExist()
        compose.onAllNodesWithContentDescription("关闭").onLast().performClick()
        compose.onNodeWithText("tx-01").assertDoesNotExist()
    }
}
