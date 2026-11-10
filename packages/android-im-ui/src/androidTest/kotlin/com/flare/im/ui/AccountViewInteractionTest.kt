package com.flare.im.ui

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.Density
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.junit.Assert.assertTrue
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/** Real Compose interactions on fictional resolved account data, with no SDK/network calls. */
class AccountViewInteractionTest {
    @Test fun resolvedRecordPagesSharePhoneAndDesktopLayouts() {
        val ids = listOf("history", "cashflow_history", "recharge_history", "withdrawal_history", "history_detail", "cashflow_detail")
        val cases = ids.map { fixture("wallet-record-vectors.json", it) }
        val selected = mutableStateOf(0)
        compose.setContent {
            val wide = selected.value == 1 || selected.value == 4
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density / if (wide) 3f else 1f, 1f)) {
                FlareThemeProvider(mode = if (wide) FlareThemeMode.Dark else FlareThemeMode.Light) {
                    Box(Modifier.width(if (wide) 1100.dp else 390.dp)) {
                        FlarePluginPage(page = cases[selected.value].first, view = cases[selected.value].second,
                            onFilter = {}, onRefresh = {}, onLoadMore = {}, onAction = { _, _ -> })
                    }
                }
            }
        }
        ids.forEachIndexed { index, id ->
            compose.runOnIdle { selected.value = index }
            list().performScrollToIndex(0)
            capture("wallet-records-$id-android-${if (index == 1 || index == 4) "desktop-dark" else "phone-light"}.png")
        }
    }
    private fun recordPage() = PluginPageViewModel.fromJson("""{
      "available":true,"title":"充值与提现记录","nextCursor":"next","data":{"revision":"original"},
      "presentation":{"renderer":"account","props":{"layout":"ledger","groupByDate":false,"rowBadgePlacement":"separate","rowBadgeLabel":"订单状态","rowEntryAction":"details"},"actions":{}},
      "inputs":[{"id":"kind","kind":"select","label":"业务类型","choices":[{"value":"deposit","label":"充值"},{"value":"withdrawal","label":"提现"}]},{"id":"status","kind":"select","label":"状态","choices":[{"value":"pending","label":"待审核"},{"value":"done","label":"已完成"}]}],
      "blocks":[{"kind":"rows","source":"test.records","filters":["kind","status"],"columns":[{"label":"申请金额"},{"label":"类型"},{"label":"钱包"}],
        "actions":[{"id":"details","label":"查看详情"}],"rows":[{"key":"request-1","badge":{"text":"待审核","tone":"warning"},"cells":[{"text":"CNY 12345678901234567890.123456789"},{"text":"充值"},{"text":"零钱钱包"}],"actions":[{"id":"details","input":{"requestId":"opaque-request"}}]}]}]}""")
    @Test fun recordStatusKeepsItsTitleAndFiltersRequestTheServer() {
        val changed = mutableListOf<Map<String, Any?>>()
        val opened = mutableListOf<PluginPageActionPayload>()
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Light) { Box(Modifier.width(320.dp)) {
            FlarePluginPage(page = ref, view = recordPage(), filters = mapOf("status" to "pending"),
                onFilter = { changed += it }, onAction = { _, payload -> opened += payload })
        } } }
        compose.onNodeWithText("业务类型").assertIsDisplayed()
        compose.onNodeWithText("状态").assertIsDisplayed()
        compose.onNodeWithText("提现").performClick()
        compose.runOnIdle { assertEquals(mapOf("status" to "pending", "kind" to "withdrawal"), changed.single()) }
        list().performScrollToNode(hasText("零钱钱包"))
        compose.onNodeWithText("零钱钱包").assertIsDisplayed()
        compose.onNodeWithText("零钱钱包").performClick()
        compose.runOnIdle {
            assertEquals(mapOf("revision" to "original"), opened.single().data)
            assertEquals(PluginActionRow("request-1", mapOf("requestId" to "opaque-request")), opened.single().row)
        }
        capture("wallet-records-android-phone-light.png")
    }
    @Test fun fastIdenticalPagingFailureUsesItsOwnTokenAndRetainsFinancialState() {
        val token = mutableStateOf(0)
        val refreshing = mutableStateOf(false)
        var pages = 0
        var retries = 0
        compose.setContent { FlareThemeProvider { FlarePluginPage(page = ref, view = recordPage(),
            pagingToken = token.value, refreshing = refreshing.value, error = "同一分页错误",
            busyActionId = "financial", actionError = "支付待确认", settleToken = 0,
            onLoadMore = { pages++; token.value++ }, onRefresh = { retries++ }) } }
        val label = FlareStrings().myInviteLoadMore
        repeat(2) { list().performScrollToNode(hasText(label)); compose.onNodeWithText(label).performClick(); compose.waitForIdle() }
        compose.runOnIdle { assertEquals(2, pages); refreshing.value = true }
        list().performScrollToNode(hasText(label)); compose.onNodeWithText(label).assertIsNotEnabled()
        compose.runOnIdle { refreshing.value = false }
        list().performScrollToNode(hasText("支付待确认")); compose.onNodeWithText("支付待确认").assertExists()
        list().performScrollToNode(hasText("同一分页错误")); compose.onNodeWithText(FlareStrings().retry).performClick()
        compose.runOnIdle { assertEquals(1, retries); assertEquals(2, pages) }
    }
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
    private fun fixture(file: String, id: String): Pair<PluginPageRef, PluginPageViewModel> {
        val json = InstrumentationRegistry.getInstrumentation().context.assets.open(file).bufferedReader().use { it.readText() }
        val table = FlareJson.parse(json) as Map<*, *>
        val item = (table["cases"] as List<*>).map { it as Map<*, *> }
            .first { it["id"] == id && it["locale"] == "zh-CN" }
        return PluginPageRef("flare.wallet", item["page"] as String) to
            PluginPageViewModel(PluginViewModel.fromMap(item["view"] as Map<*, *>), mapOf("revision" to "original"))
    }
    private fun inlineFixture() = PluginPageViewModel.fromJson("""{
      "available":true,"title":"资料核对","data":{"revision":"original"},
      "presentation":{"renderer":"account","props":{"layout":"flow","sectionTitle":"申请信息"},"actions":{"submit":"submit"}},
      "actions":[{"id":"submit","label":"提交资料","style":"primary","form":["amount","memo"]}],
      "inputs":[{"id":"amount","kind":"text","label":"金额","required":true},{"id":"memo","kind":"text","label":"备注"}]}
    """)
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
    @Test fun compactWalletKeepsActionsReachableAtNarrowWidth() {
        val view = wallet().let { it.copy(view = it.view.copy(
            actions = listOf(PluginViewAction("add", "充值", PluginActionStyle.Primary), PluginViewAction("take", "提现"), PluginViewAction("methods", "收款方式"), PluginViewAction("history", "充值与提现记录")),
            presentation = mapOf("renderer" to "account", "props" to mapOf("layout" to "wallet", "summaryTitle" to "钱包", "servicesTitle" to "钱包服务"),
                "actions" to mapOf("primary" to "add", "secondary" to "take", "tertiary" to "methods")))) }
        val sent = mutableListOf<String>()
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Dark) { Box(Modifier.width(320.dp)) {
            FlarePluginPage(page = ref, view = view, actionError = "状态更新失败", onAction = { id, _ -> sent += id })
        } } }
        listOf("充值", "提现", "收款方式").forEach { label ->
            val node = compose.onNodeWithText(label)
            node.assertIsDisplayed()
            val bounds = node.getUnclippedBoundsInRoot()
            assertTrue(bounds.left.value >= 0 && bounds.right.value <= 320)
            node.assertTouchHeightIsEqualTo(FlareSizes.touchTarget)
        }
        capture("wallet-android-phone-dark.png")
        compose.onNodeWithText("收款方式").performClick()
        compose.runOnIdle { assertEquals(listOf("methods"), sent) }
        list().performScrollToNode(hasText("状态更新失败"))
        compose.onAllNodesWithText("状态更新失败").assertCountEquals(1)
    }
    @Test fun flowUsesReceiptAndFormWithoutAnEmptyLedger() {
        val flow = PluginPageViewModel.fromJson("""{"available":true,"title":"充值","fields":[{"label":"申请金额","value":"¥123.45"}],
          "presentation":{"renderer":"account","props":{"layout":"flow","stepLabel":"填写充值金额","sectionTitle":"充值信息","description":"核对信息后继续"},"actions":{"submit":"submit"}},
          "actions":[{"id":"submit","label":"继续充值","form":["amount"]}],"inputs":[{"id":"amount","kind":"text","label":"金额","required":true}]}""")
        val sent = mutableListOf<PluginPageActionPayload>()
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Light) { FlarePluginPage(page = ref, view = flow, onAction = { _, payload -> sent += payload }) } }
        compose.onNodeWithText("¥123.45").assertExists()
        compose.onNodeWithText("填写充值金额").assertExists()
        compose.onNodeWithText("充值信息").assertExists()
        compose.onNodeWithText("暂无交易记录").assertDoesNotExist()
        capture("wallet-flow-android-phone-light.png")
        compose.onNodeWithText("金额").assertIsDisplayed()
        compose.onNodeWithText("取消").assertDoesNotExist()
        compose.onNodeWithText("继续充值").performClick()
        compose.runOnIdle { assertTrue(sent.isEmpty()) }
        compose.onNodeWithText("金额").assertIsDisplayed()
        capture("wallet-flow-form-android-phone-light.png")
    }
    @Test fun walletContentStaysCenteredAndCappedOnWideDesktop() {
        val mode = mutableStateOf(FlareThemeMode.Light)
        val view = wallet().let { it.copy(view = it.view.copy(actions = listOf(
            PluginViewAction("add", "充值", PluginActionStyle.Primary), PluginViewAction("take", "提现"), PluginViewAction("methods", "收款方式"), PluginViewAction("history", "充值与提现记录")),
            presentation = mapOf("renderer" to "account", "props" to mapOf("layout" to "wallet", "summaryTitle" to "钱包", "servicesTitle" to "钱包服务"),
                "actions" to mapOf("primary" to "add", "secondary" to "take", "tertiary" to "methods")))) }
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density / 3f, 1f)) {
                FlareThemeProvider(mode = mode.value) { Box(Modifier.width(1100.dp)) { FlarePluginPage(page = ref, view = view, onAction = { _, _ -> }) } }
            }
        }
        val bounds = list().getUnclippedBoundsInRoot()
        assertTrue((bounds.right - bounds.left).value <= FlareSizes.directoryContentMaxWidth.value + 0.5f)
        assertTrue(bounds.left.value > 0)
        capture("wallet-android-desktop-light.png")
        compose.runOnIdle { mode.value = FlareThemeMode.Dark }
        capture("wallet-android-desktop-dark.png")
    }
    @Test fun openingFlowKeepsTheColumnMeaningVisible() {
        val flow = PluginPageViewModel.fromJson("""{"available":true,"title":"开户进度","presentation":{"renderer":"account","props":{"layout":"flow","sectionTitle":"开户申请"},"actions":{}},
          "blocks":[{"kind":"rows","source":"test.openings","columns":[{"label":"实例名称"},{"label":"模板"},{"label":"状态"},{"label":"原因"}],
          "rows":[{"key":"opening","cells":[{"text":"工资钱包"},{"text":"definition-fixture"},{"text":"pending"},{"text":"等待审核"}]}]}]}""")
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Light) { FlarePluginPage(page = ref, view = flow) } }
        listOf("实例名称", "工资钱包", "模板", "状态", "原因", "等待审核").forEach { compose.onNodeWithText(it).assertIsDisplayed() }
        capture("wallet-openings-android-phone-light.png")
    }
    @Test fun multipleWalletCardsKeepAmountsAndOriginalRowBinding() {
        val (page, source) = fixture("wallet-card-vectors.json", "multipleWallets")
        // This exercises the generic local-detail fallback independently of future fixture navigation.
        val presentation = source.view.presentation.orEmpty().toMutableMap()
        presentation["props"] = (presentation["props"] as? Map<*, *>).orEmpty().filterKeys { it != "rowEntryAction" }
        val view = source.copy(view = source.view.copy(presentation = presentation))
        val wide = mutableStateOf(false)
        val phoneWidth = mutableStateOf(390.dp)
        val sent = mutableListOf<PluginPageActionPayload>()
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density / if (wide.value) 3f else 1f, 1f)) {
                FlareThemeProvider(mode = if (wide.value) FlareThemeMode.Dark else FlareThemeMode.Light) {
                    Box(Modifier.width(if (wide.value) 1100.dp else phoneWidth.value)) {
                        FlarePluginPage(page = page, view = view, onAction = { _, payload -> sent += payload })
                    }
                }
            }
        }
        compose.onAllNodesWithText("我的钱包").assertCountEquals(1)
        compose.onAllNodesWithText("零钱钱包").assertCountEquals(1)
        compose.onNodeWithText("旅行钱包").assertIsDisplayed()
        compose.onNodeWithContentDescription("1000.00").assertExists()
        compose.onNodeWithContentDescription("88.50").assertExists()
        compose.onNodeWithText("900.00").assertDoesNotExist()
        capture("wallet-multiple-android-phone-light.png")
        compose.runOnIdle { phoneWidth.value = 320.dp }
        capture("wallet-multiple-android-phone-320-light.png")
        compose.runOnIdle { phoneWidth.value = 390.dp }
        compose.onNodeWithContentDescription("隐藏余额").performClick()
        compose.onNodeWithContentDescription("1000.00").assertDoesNotExist()
        compose.onNodeWithText("USD · cash").assertDoesNotExist()
        compose.onNodeWithContentDescription("显示余额").performClick()
        compose.onNodeWithText("账户信息").performClick()
        compose.onNodeWithText("900.00").assertExists()
        compose.onNodeWithContentDescription("1000.00").assertExists()
        compose.onNodeWithText("账户信息").performClick()
        compose.runOnIdle { wide.value = true }
        val first = compose.onNodeWithText("零钱钱包").getUnclippedBoundsInRoot()
        val second = compose.onNodeWithText("旅行钱包").getUnclippedBoundsInRoot()
        assertEquals(first.top.value, second.top.value, 0.5f)
        assertTrue(second.left > first.left)
        capture("wallet-multiple-android-desktop-dark.png")
        compose.onNodeWithText("旅行钱包").performClick()
        compose.onNode(hasText("钱包") and hasClickAction()).performClick()
        compose.runOnIdle {
            assertEquals(1, sent.size)
            assertEquals(page, sent.single().page)
            assertEquals(mapOf("revision" to "original"), sent.single().data)
            assertEquals(PluginActionRow("wallet-usd-fixture", mapOf("walletId" to "wallet-usd-fixture")), sent.single().row)
        }
    }
    @Test fun realWalletFlowsShowTheirFormsWithoutOpeningASheet() {
        val current = mutableStateOf(fixture("wallet-flow-vectors.json", "recharge"))
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Light) {
            FlarePluginPage(page = current.value.first, view = current.value.second, onAction = { _, _ -> })
        } }
        for ((id, submit) in listOf("recharge" to "提交充值申请", "withdrawal" to "核对提现", "payout_profiles" to "保存收款资料")) {
            compose.runOnIdle { current.value = fixture("wallet-flow-vectors.json", id) }
            list().performScrollToIndex(0)
            compose.onAllNodes(hasSetTextAction()).onFirst().assertExists()
            compose.onAllNodesWithText(submit).assertCountEquals(1)
            compose.onNodeWithText("取消").assertDoesNotExist()
            capture("wallet-$id-inline-android-phone-light.png")
            list().performScrollToNode(hasText(submit))
            compose.onNodeWithText(submit).assertIsDisplayed()
            capture("wallet-$id-inline-bottom-android-phone-light.png")
        }
    }
    @Test fun inlineSubmitLocksSynchronouslyKeepsFailedDraftAndResetsAfterSuccess() {
        val error = mutableStateOf<String?>(null)
        val errors = mutableStateOf(emptyList<PluginFormError>())
        val settle = mutableStateOf(0)
        val sent = mutableListOf<PluginPageActionPayload>()
        compose.setContent { FlareThemeProvider(mode = FlareThemeMode.Light) {
            FlarePluginPage(page = ref, view = inlineFixture(), actionError = error.value, formErrors = errors.value,
                settleToken = settle.value, onAction = { _, payload -> sent += payload })
        } }
        compose.onAllNodes(hasSetTextAction())[0].performTextInput(" 123.4500 ")
        compose.onAllNodes(hasSetTextAction())[1].performTextInput(" 原申请 ")
        val submit = compose.onNodeWithText("提交资料").fetchSemanticsNode().config[SemanticsActions.OnClick].action!!
        compose.runOnIdle { submit(); submit() }
        compose.runOnIdle {
            assertEquals(1, sent.size)
            assertEquals(mapOf("amount" to "123.4500", "memo" to "原申请"), sent.single().formValues)
            assertEquals(mapOf("revision" to "original"), sent.single().data)
        }
        compose.onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsProperties.EditableText))[0].assertIsNotEnabled()
        compose.runOnIdle {
            error.value = "结果待确认"
            errors.value = listOf(PluginFormError("amount", PluginFormIssue.OutOfRange))
            settle.value = 1
        }
        compose.onAllNodesWithText("结果待确认").assertCountEquals(1)
        compose.onAllNodes(hasSetTextAction())[0].assertIsEnabled().assertTextContains("123.4500", substring = true)
        compose.onAllNodes(hasSetTextAction())[1].assertTextContains("原申请", substring = true)
        capture("wallet-inline-error-retained-android-phone-light.png")
        compose.onAllNodes(hasSetTextAction())[0].performTextReplacement("22.00")
        compose.onNodeWithText("提交资料").performClick()
        compose.runOnIdle {
            assertEquals(2, sent.size)
            error.value = null; errors.value = emptyList(); settle.value = 2
        }
        compose.onAllNodes(hasSetTextAction())[0].assertIsEnabled().assertTextEquals("")
        compose.onAllNodes(hasSetTextAction())[1].assertTextEquals("")
    }
    @Test fun otherBusyAndReadOnlyViewsCannotSubmitAnInlineForm() {
        val busy = mutableStateOf<String?>("other")
        val readOnly = mutableStateOf(false)
        val callback = mutableStateOf(true)
        val sent = mutableListOf<String>()
        compose.setContent { FlareThemeProvider {
            val model = inlineFixture().let { it.copy(view = it.view.copy(unavailableReason = if (readOnly.value) PluginUnavailableReason.UnboundCopy else null)) }
            FlarePluginPage(page = ref, view = model, busyActionId = busy.value,
                onAction = if (callback.value) ({ id, _ -> sent += id }) else null)
        } }
        compose.onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsProperties.EditableText))[0].assertIsNotEnabled()
        compose.onNodeWithText("提交资料").assertIsNotEnabled()
        compose.runOnIdle { busy.value = null }
        compose.onAllNodes(hasSetTextAction())[0].assertIsEnabled()
        compose.runOnIdle { readOnly.value = true }
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        compose.onNodeWithText("提交资料").assertDoesNotExist()
        compose.runOnIdle { readOnly.value = false; callback.value = false }
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        compose.onNodeWithText("提交资料").assertIsNotEnabled()
        compose.runOnIdle { assertTrue(sent.isEmpty()) }
    }
    @Test fun passwordConfirmationAndMenuActionsKeepTheirOriginalGuards() {
        val mode = mutableStateOf("password")
        val sent = mutableListOf<String>()
        compose.setContent { FlareThemeProvider {
            val password = mode.value == "password"
            val action = PluginViewAction("guarded", "继续流程", confirm = if (mode.value == "confirm") "请核对申请" else null, form = listOf("value"))
            val view = PluginViewModel(true, "", actions = if (mode.value == "menu") emptyList() else listOf(action),
                menuActions = if (mode.value == "menu") listOf(action) else emptyList(),
                inputs = listOf(PluginInput("value", if (password) PluginInputKind.Password else PluginInputKind.Text, if (password) "密码" else "资料")))
            PluginView(view, embedded = true, inlineFormActionId = "guarded", onAction = { id, _ -> sent += id })
        } }
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        compose.onNodeWithText("继续流程").performClick()
        compose.onNodeWithText("密码").assertExists()
        compose.onNodeWithText("取消").performClick()
        compose.runOnIdle { mode.value = "confirm" }
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        compose.onNodeWithText("继续流程").performClick()
        compose.onNodeWithText("请核对申请").assertExists()
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        compose.onNodeWithText("取消").performClick()
        compose.runOnIdle { mode.value = "menu" }
        compose.onAllNodes(hasSetTextAction()).assertCountEquals(0)
        compose.onNodeWithText("继续流程").performClick()
        compose.onNodeWithText("资料").assertExists()
        compose.runOnIdle { assertTrue(sent.isEmpty()) }
    }

    private fun capture(name: String, root: SemanticsNodeInteraction? = null) {
        val file = File(InstrumentationRegistry.getInstrumentation().targetContext.getExternalFilesDir(null), name)
        compose.waitForIdle()
        // A modal sheet owns another Android window; capture the display so its compositor is included.
        val bitmap = if (root != null) InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()
            else compose.onAllNodes(isRoot()).onLast().captureToImage().asAndroidBitmap()
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        assertTrue(file.length() > 0)
    }
}
