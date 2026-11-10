package com.flare.im.ui

import kotlin.test.*
import androidx.compose.ui.unit.dp

class AccountViewTest {
    @Test fun legacyNoLayoutRetainsOriginalNoteOnlyIncludingBlankNotes() {
        val warning = PluginNoteBlock(text = "Original recovery note", tone = PluginTone.Warning)
        val blank = PluginNoteBlock(text = " \n ", tone = PluginTone.Warning)
        val status = PluginStatusBlock(text = "Original status stays in information", tone = PluginTone.Danger)
        val view = PluginViewModel(true, "Legacy account", fields = listOf(PluginViewField("Balance", "1000.00")), blocks = listOf(status, warning, blank))
        assertEquals(listOf(warning, blank), accountUrgentBlocks(view))
        assertEquals(listOf(status), view.blocks.filterNot { it in accountUrgentBlocks(view) })
    }

    @Test fun sharedLayoutFixturesKeepAllUrgentTextAndOpaqueRows() {
        val fixtures = SpecTables.table("account-layout-vectors.json").items("cases")
        assertEquals(6, fixtures.size)
        fixtures.forEach { fixture ->
            val view = PluginViewModel.fromMap(fixture.obj("view")!!)
            val expected = fixture.obj("expected")!!
            fun text(block: PluginBlock) = when (block) { is PluginStatusBlock -> block.text; is PluginNoteBlock -> block.text; else -> "" }
            val expectedUrgent = (expected["urgentTexts"] as List<*>).filterIsInstance<String>()
            if (fixture.str("layout") == "flow") {
                assertEquals(expectedUrgent, view.blocks.map(::text).filter { it in expectedUrgent })
            } else {
                val urgent = accountUrgentBlocks(view)
                assertEquals(expectedUrgent, urgent.map(::text))
                val information = view.blocks.filterNot { it is PluginRowsBlock || it in urgent }.map(::text).filter { it.isNotEmpty() }
                assertTrue(information.containsAll((expected["informationTexts"] as List<*>).filterIsInstance<String>()))
                assertTrue(urgent.map(::text).none { it in information })
            }
            val entries = accountEntries(view)
            assertEquals(expected["uniqueRowKeys"], entries.map { it.row.key })
            entries.forEach { entry ->
                val original = view.blocks.filterIsInstance<PluginRowsBlock>().flatMap { it.rows }.first { it.key == entry.row.key }
                assertEquals(original.cells.first().text, entry.amount)
                assertEquals(original.actions, entry.row.actions)
            }
        }
    }
    @Test fun viewportBoundaryAndInvalidCapsKeepTheSharedLayoutContract() {
        val vectors = SpecTables.table("account-layout-vectors.json").items("viewports")
        vectors.forEach { v ->
            val inner = (v["innerWidth"] as Number).toFloat().dp
            assertEquals((v["walletColumns"] as Number).toInt(), accountWalletColumnCount(inner, 2))
            assertEquals(1, accountWalletColumnCount(inner, 1))
        }
        assertEquals(2, accountWalletColumnCount(2000.dp, 20))
        listOf(null, 0.dp, (-1).dp, Float.NaN.dp, Float.POSITIVE_INFINITY.dp).forEach { assertNull(flareContentMaxWidth(it)) }
        assertEquals(880.dp, flareContentMaxWidth(880.dp))
    }

    @Test fun urgentNoticesKeepNonblankStatusAndNoteInDeclaredOrder() {
        val warning = PluginStatusBlock(text = "Keep the original request", tone = PluginTone.Warning)
        val danger = PluginStatusBlock(text = "Review the existing result", tone = PluginTone.Danger)
        val note = PluginNoteBlock(text = "Recovery notice", tone = PluginTone.Warning)
        val info = PluginStatusBlock(text = "Information", tone = PluginTone.Info)
        val neutral = PluginNoteBlock(text = "Rules", tone = PluginTone.Neutral)
        val blank = PluginStatusBlock(text = " \n ", tone = PluginTone.Warning)
        val view = PluginViewModel(true, "Account", blocks = listOf(warning, info, danger, neutral, note, blank), presentation = mapOf("props" to mapOf("layout" to "wallet")))
        assertEquals(listOf(warning, danger, note), accountUrgentBlocks(view))
        assertEquals(listOf(info, neutral, blank), view.blocks.filterNot { it in accountUrgentBlocks(view) })
    }

    @Test fun payoutKindFixturesKeepDynamicChoicesAndHistoricalManagement() {
        val fixtures = SpecTables.table("wallet-payout-kind-vectors.json").items("cases")
        assertEquals(6, fixtures.size)
        fixtures.forEach { fixture ->
            val view = PluginViewModel.fromMap(fixture.obj("view")!!)
            val kind = view.inputs.first { it.id == "kind" }
            val expected = when (fixture.str("variant")) {
                "all4" -> listOf("bankCard", "alipay", "wechat", "address")
                "alipay_only" -> listOf("alipay")
                else -> emptyList()
            }
            assertEquals(expected, kind.choices.orEmpty().map { it.value })
            assertNull(kind.default)
            assertEquals("", PluginFormRules.draft(view.inputs, null)["kind"])
            val labels = if (fixture.str("locale") == "en-US") mapOf("bankCard" to "Bank card", "alipay" to "Alipay", "wechat" to "WeChat", "address" to "Payout address")
                else mapOf("bankCard" to "银行卡", "alipay" to "支付宝", "wechat" to "微信", "address" to "收款地址")
            assertEquals(expected.map { labels.getValue(it) }, kind.choices.orEmpty().map { it.label })
            val row = accountEntries(view).first().row
            assertEquals("fixture-existing-bank", row.key)
            assertEquals(setOf("default", "remove"), row.actions.map { it.id }.toSet())
            row.actions.forEach { action ->
                assertEquals(mapOf("id" to "fixture-existing-bank", "expectedRevision" to "1"), action.input)
            }
            if (fixture.str("variant") == "empty") {
                assertTrue(accountPresentation(view).primary.isEmpty())
                assertTrue(view.blocks.filterIsInstance<PluginStatusBlock>().any { it.tone == PluginTone.Warning && it.text.isNotBlank() })
                assertNull(accountFlowResult(view))
            } else {
                assertEquals(listOf("save"), accountPresentation(view).primary.map { it.id })
            }
        }
    }
    @Test fun unavailableFormNoticeRequiresDeclaredFormAndNoVisiblePrimaryOrResult() {
        val props = mapOf("layout" to "flow", "formTitle" to "Apply", "formUnavailableDescription" to "Applications are unavailable; existing records remain available.", "resultTone" to "success")
        val base = PluginViewModel(true, "Flow", presentation = mapOf("props" to props))
        assertEquals(AccountFlowResult(props.getValue("formUnavailableDescription"), FlareStatusTone.Neutral), accountFlowResult(base))
        listOf(props + ("layout" to "wallet"), props + ("formTitle" to " \n "), props - "formTitle", props - "formUnavailableDescription", props + ("formUnavailableDescription" to " "))
            .forEach { assertNull(accountFlowResult(base.copy(presentation = mapOf("props" to it)))) }
        val result = base.copy(presentation = mapOf("props" to (props + mapOf("resultDescription" to "Review the original request.", "resultTone" to "warning"))))
        assertEquals(AccountFlowResult("Review the original request.", FlareStatusTone.Warning), accountFlowResult(result))
        val resultWithoutForm = result.copy(presentation = mapOf("props" to ((props - "formTitle") + mapOf("resultDescription" to "Review the original request.", "resultTone" to "warning"))))
        assertEquals(accountFlowResult(result), accountFlowResult(resultWithoutForm))
        listOf(PluginViewAction("protected", "Verify", style = PluginActionStyle.Primary, form = listOf("password")),
            PluginViewAction("protected", "Confirm", style = PluginActionStyle.Primary, confirm = "Confirm original request"))
            .forEach { assertNull(accountFlowResult(base.copy(actions = listOf(it)))) }
        val slot = base.copy(actions = listOf(PluginViewAction("continue", "Continue")), presentation = mapOf("props" to props, "actions" to mapOf("submit" to "continue")))
        assertNull(accountFlowResult(slot))
        listOf(PluginTone.Warning, PluginTone.Danger).forEach { tone ->
            val blocks = listOf(PluginStatusBlock(text = "Review the channel", tone = tone))
            assertNull(accountFlowResult(base.copy(blocks = blocks)))
            assertEquals(accountFlowResult(result), accountFlowResult(result.copy(blocks = blocks)))
        }
        listOf<PluginBlock>(
            PluginStatusBlock(label = "Status", text = " \n ", tone = PluginTone.Warning),
            PluginStatusBlock(text = "For information", tone = PluginTone.Info),
            PluginStatusBlock(text = "Account information", tone = PluginTone.Neutral),
            PluginStatusBlock(text = "Recorded", tone = PluginTone.Success),
            PluginNoteBlock(text = "Informational note", tone = PluginTone.Info),
            PluginNoteBlock(text = "Warning note", tone = PluginTone.Warning),
            PluginNoteBlock(text = "Danger note", tone = PluginTone.Danger),
        ).forEach { block -> assertEquals(accountFlowResult(base), accountFlowResult(base.copy(blocks = listOf(block)))) }
    }
    @Test fun inlineFormMetadataIsOptionalAndBlankDoesNotChangeItsLayout() {
        assertNull(pluginInlineFormHeading(null))
        assertNull(pluginInlineFormHeading(""))
        assertNull(pluginInlineFormHeading(" \n\t "))
        assertEquals("Add account", pluginInlineFormHeading(" Add account\n"))
    }
    @Test fun flowResultUsesOnlyDeclaredTextAndSemanticTone() {
        val base = PluginViewModel(true, "Receipt", fields = listOf(PluginViewField("Status", "completed")))
        assertNull(accountFlowResult(base))
        listOf("success" to FlareStatusTone.Success, "warning" to FlareStatusTone.Warning,
            "danger" to FlareStatusTone.Danger, "info" to FlareStatusTone.Info, "neutral" to FlareStatusTone.Neutral).forEach { (raw, tone) ->
            val view = base.copy(presentation = mapOf("props" to mapOf("resultTitle" to "Review pending", "resultDescription" to "Submission does not mean funds arrived.", "resultTone" to raw)))
            assertEquals(AccountFlowResult("Review pending\nSubmission does not mean funds arrived.", tone), accountFlowResult(view))
        }
        val titleOnly = base.copy(presentation = mapOf("props" to mapOf("resultTitle" to "Original request", "resultDescription" to "", "resultTone" to "invalid")))
        assertEquals(AccountFlowResult("Original request", FlareStatusTone.Neutral), accountFlowResult(titleOnly))
        val descriptionOnly = base.copy(presentation = mapOf("props" to mapOf("resultTitle" to "", "resultDescription" to "Use the original request.")))
        assertEquals(AccountFlowResult("Use the original request.", FlareStatusTone.Neutral), accountFlowResult(descriptionOnly))
        assertNull(accountFlowResult(base.copy(presentation = mapOf("props" to mapOf("resultTone" to "success")))))
    }
    @Test fun scopedHistoryKeepsTheServerWalletContextAndOriginalDetailBinding() {
        val fixtures = SpecTables.table("wallet-scoped-history-vectors.json").items("cases")
        assertEquals(4, fixtures.size)
        fixtures.forEach { fixture ->
            val view = PluginViewModel.fromMap(fixture.obj("view")!!)
            val props = view.presentation?.get("props") as Map<*, *>
            assertEquals(fixture.obj("sourceData")!!["walletContext"], props["contextLabel"])
            assertTrue(view.fields.isEmpty())
            accountEntries(view).forEach { entry ->
                val action = assertNotNull(accountEntryAction(view, entry, false, true))
                assertEquals(fixture.obj("arguments")!!["walletId"], (action.second.input as Map<*, *>)["walletId"])
                assertEquals(entry.row.actions.single().input, action.second.input)
            }
        }
    }
    @Test fun walletEntryUsesOnlyItsDeclaredBoundActionAndPreservesTheWalletInput() {
        val original = PluginViewModel.fromMap(SpecTables.table("wallet-card-vectors.json").items("cases").first().obj("view")!!)
        val id = accountEntries(original).first().row.actions.first().id
        val view = original.copy(presentation = mapOf("renderer" to "account", "props" to mapOf("layout" to "wallet", "rowEntryAction" to id)))
        val entries = accountEntries(view)
        assertEquals(listOf("wallet-cny-fixture", "wallet-usd-fixture"), entries.map { (accountEntryAction(view, it, false, true)!!.second.input as Map<*, *>)["walletId"] })
        val entry = entries.last()
        assertNull(accountEntryAction(view, entry, true, true))
        assertNull(accountEntryAction(view, entry, false, false))
        assertNull(accountEntryAction(view.copy(available = false), entry, false, true))
        assertNull(accountEntryAction(view.copy(unavailableReason = PluginUnavailableReason.UnboundCopy), entry, false, true))
        assertNull(accountEntryAction(view.copy(presentation = mapOf("props" to mapOf("layout" to "wallet"))), entry, false, true))
        assertNull(accountEntryAction(view, entry.copy(row = entry.row.copy(actions = emptyList())), false, true))
        assertNull(accountEntryAction(view, entry.copy(block = entry.block.copy(actions = emptyList())), false, true))
        listOf(PluginViewAction(id, "Guarded", confirm = "Confirm"), PluginViewAction(id, "Guarded", form = listOf("amount"))).forEach {
            assertNull(accountEntryAction(view, entry.copy(block = entry.block.copy(actions = listOf(it))), false, true))
        }
    }
    @Test fun walletShortcutSlotsKeepOneDeclaredGroupWithoutDuplicatingServices() {
        val primary = PluginViewAction("send", "Continue")
        val history = PluginViewAction("ledger", "All entries")
        val deposits = PluginViewAction("credits", "Incoming")
        val withdrawals = PluginViewAction("debits", "Outgoing")
        val security = PluginViewAction("security", "Security")
        val view = PluginViewModel(true, "Account", actions = listOf(primary, history, deposits, security), menuActions = listOf(withdrawals),
            presentation = mapOf("props" to mapOf("layout" to "wallet"), "actions" to mapOf("primary" to "send", "shortcutPrimary" to "ledger", "shortcutSecondary" to "credits", "shortcutTertiary" to "debits")))
        assertEquals(listOf(primary), accountPresentation(view).primary)
        assertEquals(listOf(history, deposits, withdrawals), accountPresentation(view).shortcuts)
        assertEquals(listOf(security), accountPresentation(view).services)
        assertTrue(accountPresentation(view.copy(unavailableReason = PluginUnavailableReason.UnboundCopy)).shortcuts.isEmpty())
        val unresolved = view.copy(presentation = mapOf("props" to mapOf("layout" to "wallet"), "actions" to mapOf("primary" to "send", "shortcutPrimary" to "send", "shortcutSecondary" to "missing", "shortcutTertiary" to "ledger")))
        assertEquals(listOf(history), accountPresentation(unresolved).shortcuts)
        assertEquals(listOf(deposits, security, withdrawals), accountPresentation(unresolved).services)
    }
    @Test fun resolvedRecordFixturesKeepTitlesStatusesAmountsAndDetailBindings() {
        val fixtures = SpecTables.table("wallet-record-vectors.json").items("cases")
        assertEquals(22, fixtures.size)
        fixtures.forEach { fixture ->
            val view = PluginViewModel.fromMap(fixture.obj("view")!!)
            if ((view.presentation?.get("props") as? Map<*, *>)?.get("layout") == "ledger") accountEntries(view).forEach { entry ->
                assertTrue(entry.separateBadge)
                assertEquals(entry.row.cells[1].text, entry.title)
                assertEquals(entry.row.cells[0].text, entry.amount)
                val action = assertNotNull(accountEntryAction(view, entry, false, true))
                assertEquals("detail", action.first.id)
                assertEquals(entry.row.actions.first { it.id == "detail" }.input, action.second.input)
            }
        }
    }
    @Test fun separateStatusKeepsTitleAmountAndBoundDetailAction() {
        val amount = "CNY 12345678901234567890.123456789"
        val row = PluginRow("request-1", listOf(PluginRowCell(amount), PluginRowCell("提现"), PluginRowCell("零钱钱包")),
            listOf(PluginRowAction("details", mapOf("requestId" to "opaque-request"))), PluginBadge("待审核", PluginTone.Warning))
        val block = PluginRowsBlock("test.records", listOf(PluginRowsColumn("申请金额"), PluginRowsColumn("类型"), PluginRowsColumn("钱包")), listOf(row), listOf(PluginViewAction("details", "详情")))
        val model = PluginViewModel(true, "记录", blocks = listOf(block), presentation = mapOf("renderer" to "account", "props" to mapOf("layout" to "ledger", "rowBadgePlacement" to "separate", "rowBadgeLabel" to "状态", "rowEntryAction" to "details")))
        val entry = accountEntries(model).single()
        assertEquals("提现", entry.title); assertEquals("零钱钱包", entry.subtitle); assertEquals(amount, entry.amount)
        assertEquals(PluginTone.Warning, entry.row.badge?.tone)
        assertNull(accountEntryAction(model, entry, true, true)); assertNull(accountEntryAction(model, entry, false, false))
        assertEquals(mapOf("requestId" to "opaque-request"), accountEntryAction(model, entry, false, true)?.second?.input)
        assertNull(accountEntryAction(model, entry.copy(block = block.copy(actions = listOf(PluginViewAction("details", "详情", confirm = "确认")))), false, true))
        assertEquals("待审核", accountEntries(model.copy(presentation = null)).single().title)
    }
    @Test fun inlineEligibilityAndSynchronousSettlement() {
        val action = PluginViewAction("submit", "核对", form = listOf("amount"))
        val view = PluginViewModel(true, "", actions = listOf(action), inputs = listOf(PluginInput("amount", PluginInputKind.Text, "金额")))
        assertEquals(action, pluginInlineFormAction(view, "submit", true))
        assertNull(pluginInlineFormAction(view, "submit", false))
        listOf(view.copy(available = false), view.copy(unavailableReason = PluginUnavailableReason.UnboundCopy),
            view.copy(actions = emptyList(), menuActions = listOf(action)), view.copy(inputs = emptyList()),
            view.copy(actions = listOf(action.copy(confirm = "请确认"))),
            view.copy(inputs = listOf(PluginInput("amount", PluginInputKind.Password, "密码"))))
            .forEach { assertNull(pluginInlineFormAction(it, "submit", true)) }
        var state = PluginInlineFormState().begin()!!
        assertNull(state.begin())
        state = state.settle(PluginHostSignal(), PluginHostSignal(error = "结果待确认", settleToken = 1), "submit")
        assertFalse(state.pending); assertTrue(state.submitted); assertEquals(0, state.revision)
        state = state.begin()!!.settle(PluginHostSignal(settleToken = 1), PluginHostSignal(settleToken = 2), "submit")
        assertFalse(state.submitted); assertEquals(1, state.revision)
    }
    @Test fun multipleWalletsKeepIndependentAmountsAndBindings() {
        val view = PluginViewModel.fromMap(SpecTables.table("wallet-card-vectors.json").items("cases").first().obj("view")!!)
        val entries = accountEntries(view)
        assertEquals(listOf("零钱钱包", "旅行钱包"), entries.map { it.walletTitle })
        assertEquals(listOf("1000.00", "88.50"), entries.map { it.amount })
        assertEquals(listOf("余额", "余额"), entries.map { it.walletCaption })
        assertEquals("900.00", view.fields.first().value)
        assertEquals(listOf("wallet-cny-fixture", "wallet-usd-fixture"), entries.map { (it.row.actions.first().input as? Map<*, *>)?.get("walletId") })
    }
    private fun view() = PluginViewModel.fromMap(SpecTables.table("account-view-vectors.json").obj("view")!!)
    @Test fun exactAmountsAndBindingsSurvivePresentation() {
        val entries = accountEntries(view())
        assertEquals(listOf("+¥88.88", "-¥52.00", "+¥3.00", "+¥200.00", "+$0.88"), entries.map { it.amount })
        assertEquals("收到红包", entries.first().title)
        assertEquals("周五快乐", entries.first().subtitle)
        assertEquals(mapOf("packetId" to "packet-01"), entries.first().row.actions.single().input)
        assertTrue(entries[3].row.actions.isEmpty())
    }
    @Test fun duplicateKeysAndUnknownDatesDoNotInventData() {
        val block = view().blocks.filterIsInstance<PluginRowsBlock>().single()
        assertEquals(block.rows.size, accountEntries(view().copy(blocks = listOf(block.copy(rows = block.rows + block.rows.first())))).size)
        val entry = accountEntries(PluginViewModel(true, "", blocks = listOf(PluginRowsBlock("unknown", emptyList(), listOf(PluginRow("x", emptyList())))))).single()
        assertNull(entry.timeMs); assertEquals("", entry.amount)
    }
    @Test fun pageActionRetainsOriginalDataAndRowInput() {
        val view = view(); val entry = accountEntries(view).first()
        val original = mapOf("revision" to "original")
        val payload = PluginPageActionPayload.of(PluginPageRef("test.account", "wallet"), PluginPageViewModel(view, original),
            PluginActionPayload(row = PluginActionRow(entry.row.key, entry.row.actions.single().input)))
        assertEquals(original, payload.data); assertEquals("tx-01", payload.row!!.key)
    }
    @Test fun slotsOnlyOrderVisibleActionsAndKeepTheirGuards() {
        val guarded = PluginViewAction("submit", "提现", PluginActionStyle.Primary, "确认提现", listOf("amount", "password"))
        val service = PluginViewAction("history", "查看记录")
        val presentation = mapOf("renderer" to "account", "props" to mapOf("layout" to "wallet"),
            "actions" to mapOf("primary" to "submit", "secondary" to "missing", "tertiary" to "submit"))
        val view = PluginViewModel(true, "钱包", actions = listOf(service, guarded), presentation = presentation)
        val projected = accountPresentation(view)
        assertEquals(AccountLayout.Wallet, projected.layout)
        assertEquals(listOf(guarded), projected.primary)
        assertEquals(listOf(service), projected.services)
        assertFalse(projected.groupByDate)
        assertTrue(accountPresentation(view.copy(presentation = mapOf("props" to mapOf("layout" to "wallet", "groupByDate" to true)))).groupByDate)
        assertTrue(accountPresentation(view.copy(unavailableReason = PluginUnavailableReason.UnboundCopy)).primary.isEmpty())
        assertTrue(accountPresentation(view.copy(available = false)).services.isEmpty())
    }
    @Test fun flowOnlyPromotesItsDeclaredPrimaryAndDefaultsToLedger() {
        val one = PluginViewAction("one", "继续")
        val two = PluginViewAction("two", "返回")
        val flow = view().copy(actions = listOf(two, one), presentation = mapOf("props" to mapOf("layout" to "flow"),
            "actions" to mapOf("submit" to "one", "secondary" to "two")))
        assertEquals(listOf(one), accountPresentation(flow).primary)
        assertEquals(listOf(two), accountPresentation(flow).services)
        val authorized = flow.copy(actions = listOf(two, PluginViewAction("authorized", "提交提现", PluginActionStyle.Primary)))
        assertEquals(listOf("authorized"), accountPresentation(authorized).primary.map { it.id })
        assertEquals(listOf(two), accountPresentation(authorized).services)
        assertEquals(AccountLayout.Ledger, accountPresentation(view()).layout)
    }
    @Test fun rustWalletFixturesKeepTheDeclaredSubmitAndVisibleActions() {
        val fixtures = SpecTables.table("wallet-flow-vectors.json").items("cases")
        assertEquals(44, fixtures.size)
        var recoveries = 0
        fixtures.forEach { fixture ->
            val view = PluginViewModel.fromMap(fixture.obj("view")!!)
            val projected = accountPresentation(view)
            val grouped = projected.primary + projected.shortcuts + projected.services
            assertEquals((view.actions + view.menuActions).map { it.id }.toSet(), grouped.map { it.id }.toSet())
            assertEquals(grouped.size, grouped.map { it.id }.toSet().size)
            if (projected.layout == AccountLayout.Wallet) assertFalse(projected.groupByDate)
            if (fixture.str("id") == "openings" && fixture.str("locale") == "zh-CN") {
                val rows = view.blocks.filterIsInstance<PluginRowsBlock>().first()
                val fields = PluginViewFormat.rowFields(rows, rows.rows.first(), 0, FlareStrings(), 0)
                assertEquals(listOf("模板", "状态", "原因"), fields.map { it.label })
                assertEquals("等待审核", fields.last().value)
            }
            if (fixture.str("id") == "recovery") {
                recoveries++
                assertEquals("retry", (view.presentation?.get("actions") as? Map<*, *>)?.get("submit"))
                assertEquals("retry", projected.primary.first().id)
                assertNull(projected.primary.first().style)
            }
        }
        assertEquals(2, recoveries)
    }
    @Test fun defaultStyleRecoveryActionUsesSubmitSlot() {
        val retry = PluginViewAction("retry", "重试原操作")
        val back = PluginViewAction("back", "返回钱包")
        val view = PluginViewModel(true, "待确认操作", actions = listOf(back, retry),
            presentation = mapOf("renderer" to "account", "props" to mapOf("layout" to "flow"), "actions" to mapOf("submit" to "retry")))
        assertEquals(listOf(retry), accountPresentation(view).primary)
        assertEquals(listOf(back), accountPresentation(view).services)
    }
}
