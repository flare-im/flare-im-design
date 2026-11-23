package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import androidx.compose.ui.unit.dp

/** The small rules of docs/plugin-experience.md that have no shared vector table yet: ledger rows, the PIN, calls. */
class PluginExperienceRulesTest {
    @Test fun aLedgerRowReadsItsKindFromTheSign() {
        assertEquals(PluginLedgerKind.Income, pluginLedgerKind("+¥1.00"))
        assertEquals(PluginLedgerKind.Expense, pluginLedgerKind("-¥2.00"))
        assertEquals(PluginLedgerKind.Expense, pluginLedgerKind("−¥2.00"))
        assertEquals(PluginLedgerKind.Internal, pluginLedgerKind("¥3.00"))
        // R10: spending reads with U+2212, never a hyphen; anything else stays as written.
        assertEquals("−¥2.00", pluginSignedAmount("-¥2.00"))
        assertEquals("+¥1.00", pluginSignedAmount("+¥1.00"))
        // §12.24: a signed (or money) first cell no longer makes a ledger; only a declared icon draws records.
        val signed = PluginRowsBlock("history", listOf(PluginRowsColumn("金额")), listOf(PluginRow("a", listOf(PluginRowCell("+¥1.00")))))
        assertFalse(pluginRowsAreRecords(signed))
        assertFalse(pluginRowsAreRecords(signed.copy(rows = listOf(PluginRow("a", listOf(PluginRowCell("1.00",
            format = PluginValueFormat.Money("100", 2, currency = "CNY"))))))))
        assertTrue(pluginRowsAreRecords(signed.copy(icon = "red-packet")))
    }

    @Test fun aRecordIconTheKitDoesNotKnowFallsBackToTheSignsGlyph() {
        assertEquals("red-packet", pluginLedgerIconName(PluginLedgerKind.Income, "red-packet"))
        assertEquals("arrow-down", pluginLedgerIconName(PluginLedgerKind.Income, "no-such-icon"))
        assertEquals("send", pluginLedgerIconName(PluginLedgerKind.Expense, "no-such-icon"))
        assertEquals("refresh", pluginLedgerIconName(PluginLedgerKind.Internal, null))
    }

    @Test fun onlyALeadingHyphenBecomesTheMinusSign() {
        // A hyphen inside a date or an id is not a sign (Flutter once swapped the first "-" anywhere).
        assertEquals(" −¥2.00", pluginSignedAmount(" -¥2.00"))
        assertEquals("−1-2", pluginSignedAmount("-1-2"))
        assertEquals("2026-11-18", pluginSignedAmount("2026-11-18"))
        assertEquals("ORD-001", pluginSignedAmount("ORD-001"))
        val block = PluginRowsBlock("history", listOf(PluginRowsColumn("金额"), PluginRowsColumn("单号"), PluginRowsColumn("日期")),
            listOf(PluginRow("a", listOf(PluginRowCell("-¥2.00"), PluginRowCell("ORD-001"), PluginRowCell("2026-11-18")))))
        val line = pluginLedgerLine(block, block.rows[0], 0L, FlareStrings())
        assertEquals("ORD-001", line.title)
        assertTrue(line.line.orEmpty().contains("2026-11-18"), "the date keeps its hyphens: ${line.line}")
    }

    @Test fun aSixDigitPasswordIsAPin() {
        assertTrue(pluginPinInput(PluginInput("pin", PluginInputKind.Password, "支付密码", maxLength = 6)))
        assertFalse(pluginPinInput(PluginInput("pin", PluginInputKind.Password, "密码", maxLength = 32)))
        assertFalse(pluginPinInput(PluginInput("code", PluginInputKind.Text, "代码", maxLength = 6)))
        assertEquals("123456", pluginPinDigits("12a3４5 6789"))
        // 5.10: only a value of digits (or none yet) draws the cells; anything else would lose its other characters.
        val pin = PluginInput("pin", PluginInputKind.Password, "支付密码", maxLength = 6)
        assertTrue(pluginPinInput(pin, "1234"))
        assertTrue(pluginPinInput(pin, ""))
        assertFalse(pluginPinInput(pin, "ab12"))
    }

    @Test fun pinCellsShrinkOnANarrowPanel() {
        // §12.19: 320 wide leaves 288 inside the panel; six cells and five sm gaps fit.
        val cell = flarePinCellWidth(288.dp)
        assertTrue(cell * FLARE_PIN_LENGTH + FlareSizes.spacingSm * (FLARE_PIN_LENGTH - 1) <= 288.dp)
        assertEquals(FlareSizes.componentPinCellWidth, flarePinCellWidth(600.dp))
        assertEquals(FlareSizes.componentPinCellMinWidth, flarePinCellWidth(100.dp))
    }

    @Test fun anAmountReadsItsCurrencyByName() {
        val locale = java.util.Locale.US
        val yuan = java.util.Currency.getInstance("CNY").getDisplayName(locale)
        assertEquals("1,000.00 $yuan", FlarePaymentRules.spokenAmount("¥1,000.00", locale))
        assertEquals("+88.88 $yuan", FlarePaymentRules.spokenAmount("+¥88.88", locale))
        // The longer symbol wins: JP¥ is yen, HK$ is not dollars.
        assertEquals("5 ${java.util.Currency.getInstance("JPY").getDisplayName(locale)}", FlarePaymentRules.spokenAmount("JP¥5", locale))
        assertEquals("7.00 ${java.util.Currency.getInstance("HKD").getDisplayName(locale)}", FlarePaymentRules.spokenAmount("HK$7.00", locale))
        assertEquals("100.00 XYZ", FlarePaymentRules.spokenAmount("100.00 XYZ", locale))
    }

    @Test fun documentSlotsSitTwoOrThreeARowAndSayWhatATapDoes() {
        assertEquals(2, pluginDocumentColumns(phone = true))
        assertEquals(3, pluginDocumentColumns(phone = false))
        val s = FlareStrings()
        assertEquals("证件正面, ${s.documentSlotCaptured}", flareDocumentSlotDescription("证件正面", FlareDocumentSlotState.Captured, null, s))
        assertEquals(s.documentCaptureRetake, flareDocumentSlotClickLabel(FlareDocumentSlotState.Captured, s))
        assertEquals(s.retry, flareDocumentSlotClickLabel(FlareDocumentSlotState.Failed, s))
        assertEquals(null, flareDocumentSlotClickLabel(FlareDocumentSlotState.Uploading, s))
    }

    @Test fun aStepSaysWhereItIsInTheRow() {
        val s = FlareStrings()
        assertEquals("第 2 步，共 4 步, 核对资料, ${s.pluginViewStepCurrent}",
            pluginStepSpoken(PluginStep("核对资料", PluginStepState.Current), 1, 4, s))
    }

    @Test fun aPressedButtonTakesItsPressedFill() {
        val c = FlareColors.Light
        assertEquals(c.primaryHover to c.primaryActive, buttonFeedbackFills(FlareButtonVariant.Primary, FlareButtonAppearance.Standard, c))
        assertEquals(c.errorHover to c.errorActive, buttonFeedbackFills(FlareButtonVariant.Danger, FlareButtonAppearance.Standard, c))
        assertEquals(c.bgHover to c.bgHover, buttonFeedbackFills(FlareButtonVariant.Secondary, FlareButtonAppearance.Standard, c))
        assertEquals(c.bgHover to c.bgHover, buttonFeedbackFills(FlareButtonVariant.Primary, FlareButtonAppearance.Text, c))
    }

    @Test fun servicesGroupIntoListCards() {
        val a = PluginViewAction("a", "交易记录", group = "common")
        val b = PluginViewAction("b", "充值记录", group = "records")
        val c = PluginViewAction("c", "收款方式")
        assertEquals(listOf(PluginActionList("common", listOf(a, c)), PluginActionList("records", listOf(b))), pluginActionLists(listOf(a, b, c)))
        assertEquals(listOf(PluginActionList(null, listOf(c))), pluginActionLists(listOf(c)))
        assertEquals(emptyList<PluginActionList>(), pluginActionLists(emptyList()))
    }

    @Test fun blocksStandLgApartAndGroups2xl() {
        val text = PluginViewPart.Block(0, PluginTextBlock("a"))
        val section = PluginViewPart.Block(1, PluginSectionBlock(blocks = emptyList()))
        assertEquals(FlareSizes.spacingLg, pluginPartGap(text, text))
        assertEquals(FlareSizes.spacing2xl, pluginPartGap(text, section))
        assertEquals(FlareSizes.spacing2xl, pluginPartGap(section, text))
        // A message card keeps its own rhythm.
        assertEquals(FlareSizes.spacingMd, pluginPartGap(text, section, page = false))
    }

    @Test fun thePreviewSnapsToTheNearestCorner() {
        // A 400 × 800 stage, a 112 × 149 preview 16 from the edges, starting at the top end corner (1).
        assertEquals(1, callPreviewCorner(1, 0f, 0f, 400f, 800f, 112f, 149f, 16f))
        assertEquals(0, callPreviewCorner(1, -300f, 0f, 400f, 800f, 112f, 149f, 16f))
        assertEquals(3, callPreviewCorner(1, 0f, 500f, 400f, 800f, 112f, 149f, 16f))
        assertEquals(2, callPreviewCorner(1, -300f, 500f, 400f, 800f, 112f, 149f, 16f))
    }

    @Test fun groupTilesLeaveNoEmptyCell() {
        assertEquals(listOf(1), groupCallRows(1))
        assertEquals(listOf(2), groupCallRows(2))
        assertEquals(listOf(2, 1), groupCallRows(3))
        assertEquals(listOf(2, 2), groupCallRows(4))
        assertEquals(listOf(2, 2, 1), groupCallRows(5))
        assertEquals(listOf(3, 3), groupCallRows(6, wide = true))
        assertEquals(listOf(3, 2), groupCallRows(5, wide = true))
        assertEquals(listOf(2, 2, 2), groupCallRows(6))
        assertEquals(listOf(3, 3, 1), groupCallRows(7))
        assertEquals(listOf(3, 3, 3), groupCallRows(9))
        // §12.16: up to 12 — three by four on a phone, four by three on a wide window.
        assertEquals(listOf(3, 3, 3, 1), groupCallRows(10))
        assertEquals(listOf(4, 4, 2), groupCallRows(10, wide = true))
        assertEquals(listOf(3, 3, 3, 3), groupCallRows(12))
        assertEquals(listOf(4, 4, 4), groupCallRows(12, wide = true))
        assertEquals(emptyList<Int>(), groupCallRows(0))
    }

    @Test fun aCallSaysItsStateOneWay() {
        val s = FlareStrings()
        val reason = "对方暂时无法接听"
        // Failed: the host's reason is the status line; without one, call failed.
        assertEquals(CallStatusText(reason, null), callStatusText(FlareCallState.Failed, FlareCallMode.Audio, null, reason, s))
        assertEquals(CallStatusText(s.callFailed, null), callStatusText(FlareCallState.Failed, FlareCallMode.Audio, null, " ", s))
        // Any other state: its own line, the host's detail under it, never twice.
        assertEquals(CallStatusText("03:24", "网络较差"), callStatusText(FlareCallState.Connected, FlareCallMode.Audio, "03:24", "网络较差", s))
        assertEquals(CallStatusText(s.callReconnecting, null),
            callStatusText(FlareCallState.Reconnecting, FlareCallMode.Audio, null, s.callReconnecting, s))
        assertEquals("通话已结束 · 03:24", callStatusText(FlareCallState.Ended, FlareCallMode.Audio, "03:24", null, s).line)
        // The dock (§12.17): short phrases on its one line, the host's text in its place.
        assertEquals(s.callDockWaiting, callDockStatus(FlareCallState.Ringing, FlareCallMode.Audio, null, null, s))
        assertEquals(s.callDockWaiting, callDockStatus(FlareCallState.Calling, FlareCallMode.Video, null, null, s))
        assertEquals(s.callReconnectingShort, callDockStatus(FlareCallState.Reconnecting, FlareCallMode.Audio, null, null, s))
        assertEquals(s.callInterrupted, callDockStatus(FlareCallState.Failed, FlareCallMode.Audio, null, null, s))
        assertEquals(reason, callDockStatus(FlareCallState.Failed, FlareCallMode.Audio, null, reason, s))
        assertEquals("03:24", callDockStatus(FlareCallState.Connected, FlareCallMode.Audio, "03:24", null, s))
        assertEquals("网络较差", callDockStatus(FlareCallState.Connected, FlareCallMode.Audio, "03:24", "网络较差", s))
    }

    @Test fun aHardwareKeyboardDrivesTheCall() {
        assertEquals("microphone", callControlShortcut(android.view.KeyEvent.KEYCODE_M, ctrl = false, shift = false, meta = false, alt = false))
        assertEquals("camera", callControlShortcut(android.view.KeyEvent.KEYCODE_V, ctrl = false, shift = false, meta = false, alt = false))
        assertEquals("hangUp", callControlShortcut(android.view.KeyEvent.KEYCODE_H, ctrl = true, shift = true, meta = false, alt = false))
        assertEquals("hangUp", callControlShortcut(android.view.KeyEvent.KEYCODE_H, ctrl = false, shift = true, meta = true, alt = false))
        // No single key hangs up, and a modified M is not the microphone.
        assertEquals(null, callControlShortcut(android.view.KeyEvent.KEYCODE_H, ctrl = false, shift = false, meta = false, alt = false))
        assertEquals(null, callControlShortcut(android.view.KeyEvent.KEYCODE_M, ctrl = true, shift = false, meta = false, alt = false))
    }

    @Test fun anActionThatSaysWhyItWaitsIsRead() {
        val action = pluginActionOf(mapOf("id" to "pay", "label" to "付款", "disabledReason" to "余额不足"))!!
        assertEquals("余额不足", action.disabledReason)
        assertEquals(null, pluginActionOf(mapOf("id" to "pay", "label" to "付款", "disabledReason" to " "))!!.disabledReason)
    }
}
