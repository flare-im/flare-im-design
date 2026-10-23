package com.flare.im.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasAnyAncestor
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isDialog
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/**
 * FlarePluginPage and the PluginView parts it draws, driven like a reader: page actions carry the page, its data and
 * the row; a repeated row key draws once and load more asks once; filter tabs set the host's filters and wait while the
 * page reloads; badges draw between the name and the text; the choices cap holds the rest back; unavailable pages say
 * why. Views are the shapes of spec/plugin-view-vectors.json (pageViews, entries-badges, poll-max-selections).
 */
class PluginPageInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val walletRef = PluginPageRef("flare.redpacket", "flare.redpacket.wallet")
    private val tasksRef = PluginPageRef("x.tasks", "x.tasks.mine")

    private fun rowsJson(rows: String) = """{"kind":"rows","source":"flare.redpacket.wallet",
        "columns":[{"label":"金额","format":"text"},{"label":"对方","format":"text"},{"label":"时间","format":"time"}],
        "rows":[$rows],
        "actions":[{"id":"open","label":"查看","target":{"kind":"page","page":"flare.redpacket.packet"},"input":{"packetId":"/packetId"}}],
        "filters":["kind"],"emptyText":"还没有明细"}"""

    private val walletRows = """
        {"key":"l1","cells":[{"text":"+¥1.00"},{"text":"Alice"},{"text":"1792546200000","timeMs":1792546200000}],"actions":[{"id":"open","input":{"packetId":"p1"}}],"badge":{"text":"收到红包","tone":"success"}},
        {"key":"l2","cells":[{"text":"-¥5.00"},{"text":""},{"text":"1792459800000","timeMs":1792459800000}],"actions":[{"id":"open","input":{"packetId":"p2"}}],"badge":{"text":"发出红包","tone":"neutral"}}"""

    private fun wallet(rows: String = walletRows, cursor: String? = "c2") = PluginPageViewModel.fromJson(
        """{"available":true,"title":"钱包","fields":[{"label":"可用余额","value":"¥128.50"}],
            "actions":[{"id":"history","label":"全部明细","target":{"kind":"page","page":"flare.redpacket.history"}}],
            "blocks":[${rowsJson(rows)}],
            "inputs":[{"id":"kind","kind":"select","label":"类型","choices":[{"value":"send","label":"发出"},{"value":"claim","label":"收到"}]}],
            ${if (cursor != null) "\"nextCursor\":\"$cursor\"," else ""}
            "data":{"balanceText":"¥128.50","currency":"CNY"}}""",
    )

    private val tasks = PluginPageViewModel.fromJson(
        """{"available":true,"title":"我的任务","fields":[],
            "actions":[{"id":"new","label":"新建任务","style":"primary","form":["title"],"target":{"kind":"operation","operation":"x.tasks.create"}}],
            "blocks":[{"kind":"rows","source":"x.tasks.list","columns":[{"label":"任务","format":"text"}],
              "rows":[{"key":"t1","cells":[{"text":"写周报"}],"actions":[{"id":"rename","input":{"taskId":"t1"}},{"id":"remove","input":{"taskId":"t1"}}]},
                      {"key":"t2","cells":[{"text":"订会议室"}],"actions":[{"id":"remove","input":{"taskId":"t2"}}]}],
              "actions":[{"id":"rename","label":"改名","form":["title"],"target":{"kind":"operation","operation":"x.tasks.rename"},"input":{"taskId":"/taskId"}},
                         {"id":"remove","label":"删除","style":"danger","confirm":"确定删除这个任务吗？","target":{"kind":"operation","operation":"x.tasks.remove"},"input":{"taskId":"/taskId"}}],
              "filters":[]}],
            "inputs":[{"id":"title","kind":"text","label":"标题","required":true,"maxLength":40}],
            "data":{"owner":"u_bob0002"}}""",
    )

    private fun list() = compose.onNode(hasScrollToIndexAction())

    @Test fun pageActionsCarryThePageItsDataAndTheRow() {
        val sent = mutableListOf<Pair<String, PluginPageActionPayload>>()
        compose.setContent {
            FlareThemeProvider {
                FlarePluginPage(page = walletRef, title = "钱包", view = wallet(), onAction = { id, payload -> sent += id to payload })
            }
        }
        list().performScrollToNode(hasText("全部明细"))
        compose.onNodeWithText("全部明细").performClick()
        // The second row's key: the page, its data and that row's bound input.
        compose.onAllNodesWithText("查看")[1].performClick()
        compose.runOnIdle {
            val data = mapOf<String, Any?>("balanceText" to "¥128.50", "currency" to "CNY")
            assertEquals(listOf("history" to PluginPageActionPayload(walletRef, data),
                "open" to PluginPageActionPayload(walletRef, data, row = PluginActionRow("l2", mapOf("packetId" to "p2")))), sent)
        }
    }

    @Test fun aRowActionConfirmsFirstAndAFormAddsItsValuesToTheRow() {
        val sent = mutableListOf<Pair<String, PluginPageActionPayload>>()
        compose.setContent {
            FlareThemeProvider {
                FlarePluginPage(page = tasksRef, view = tasks, onAction = { id, payload -> sent += id to payload })
            }
        }
        // 订会议室's delete asks first; nothing goes out until the reader confirms.
        compose.onAllNodesWithText("删除")[1].performClick()
        compose.onNodeWithText("确定删除这个任务吗？").assertExists()
        compose.runOnIdle { assertTrue(sent.isEmpty()) }
        compose.onNode(hasText("删除") and hasClickAction() and hasAnyAncestor(isDialog())).performClick()
        compose.waitForIdle()
        // 写周报's rename collects the title, trimmed, beside its row.
        compose.onNodeWithText("改名").performClick()
        compose.onNode(hasSetTextAction() and hasAnyAncestor(isDialog())).performTextInput("  周报（终稿） ")
        compose.onNode(hasText(FlareStrings().pluginViewSubmit) and hasClickAction() and hasAnyAncestor(isDialog())).performClick()
        compose.runOnIdle {
            val data = mapOf<String, Any?>("owner" to "u_bob0002")
            assertEquals(listOf(
                "remove" to PluginPageActionPayload(tasksRef, data, row = PluginActionRow("t2", mapOf("taskId" to "t2"))),
                "rename" to PluginPageActionPayload(tasksRef, data, row = PluginActionRow("t1", mapOf("taskId" to "t1")),
                    formValues = mapOf("title" to "周报（终稿）")),
            ), sent)
        }
    }

    @Test fun aRepeatedRowKeyDrawsOnceAndTheNextPageIsAskedOnce() {
        val asked = mutableListOf<String>()
        var view by mutableStateOf(wallet(walletRows + """,{"key":"l1","cells":[{"text":"+¥9.99"},{"text":""},{"text":""}],"actions":[]}"""))
        compose.setContent {
            FlareThemeProvider {
                FlarePluginPage(page = walletRef, view = view, onLoadMore = { asked += it })
            }
        }
        // A lazy list with a repeated key would throw: the first l1 stays, the second is not drawn.
        compose.onNodeWithText("+¥1.00", useUnmergedTree = true).assertExists()
        compose.onNodeWithText("+¥9.99", useUnmergedTree = true).assertDoesNotExist()
        list().performScrollToNode(hasText(FlareStrings().myInviteLoadMore))
        compose.onNodeWithText(FlareStrings().myInviteLoadMore).performClick()
        compose.onNodeWithText(FlareStrings().myInviteLoadMore).performClick()
        compose.runOnIdle { assertEquals(listOf("c2"), asked) }
        // The merged view: the new row follows, the last page draws no key.
        compose.runOnIdle {
            view = wallet(walletRows + """,{"key":"l6","cells":[{"text":"-¥2.00"},{"text":"Bob"},{"text":""}],"actions":[]}""", cursor = null)
        }
        list().performScrollToNode(hasText("-¥2.00"))
        compose.onNodeWithText("-¥2.00", useUnmergedTree = true).assertExists()
        compose.onNodeWithText(FlareStrings().myInviteLoadMore).assertDoesNotExist()
    }

    @Test fun filterTabsSetTheHostsFiltersAndWaitWhileThePageReloads() {
        val chosen = mutableListOf<Map<String, Any?>>()
        var filters by mutableStateOf<Map<String, Any?>>(mapOf("keyword" to "团建"))
        var refreshing by mutableStateOf(false)
        compose.setContent {
            FlareThemeProvider {
                FlarePluginPage(page = walletRef, view = wallet(), filters = filters, refreshing = refreshing,
                    onRefresh = {}, onFilter = { chosen += it })
            }
        }
        compose.onNodeWithText("全部").assertIsSelected()
        compose.onNodeWithText("收到").performClick()
        // The tab already chosen emits nothing.
        compose.onNodeWithText("全部").performClick()
        compose.runOnIdle { assertEquals(listOf(mapOf<String, Any?>("keyword" to "团建", "kind" to "claim")), chosen) }
        compose.runOnIdle { filters = mapOf("kind" to "claim"); refreshing = true }
        compose.onNodeWithText("收到").assertIsSelected()
        compose.onNodeWithText("发出").assertIsNotEnabled()
        compose.runOnIdle { refreshing = false }
        compose.onNodeWithText("发出").assertIsEnabled()
    }

    @Test fun aBadgeDrawsAfterTheNameAndBeforeTheTextAndLeadsARow() {
        val entries = PluginViewModel.fromJson(
            """{"available":true,"title":"红包明细","fields":[],"actions":[],"blocks":[{"kind":"entries","numbered":false,"total":1,"more":false,
               "items":[{"index":1,"text":"+¥1.00","name":"Alice","badge":{"text":"收到红包","tone":"success"}}]}]}""",
        )
        compose.setContent { FlareThemeProvider { PluginView(view = entries) } }
        val name = compose.onNodeWithText("Alice", useUnmergedTree = true).getUnclippedBoundsInRoot()
        val badge = compose.onNodeWithText("收到红包", useUnmergedTree = true).getUnclippedBoundsInRoot()
        val text = compose.onNodeWithText("+¥1.00", useUnmergedTree = true).getUnclippedBoundsInRoot()
        assertTrue("the badge follows the name", badge.left >= name.right)
        assertTrue("the text follows the badge", text.left >= badge.right)
    }

    @Test fun theCapHoldsTheRestBackAndAnUntickFreesThem() {
        val poll = PluginViewModel.fromJson(
            """{"available":true,"title":"周末去哪儿？","fields":[],"actions":[],"blocks":[{"kind":"choices",
               "options":[{"index":0,"label":"爬山","selected":false},{"index":1,"label":"看展","selected":false},{"index":2,"label":"露营","selected":false},{"index":3,"label":"桌游","selected":false}],
               "multiple":true,"voted":false,"closed":false,"showResults":false,"inputName":"selection","maxSelections":2,
               "action":{"id":"vote","label":"投票","target":{"kind":"operation","operation":"vote"},"input":{}}}]}""",
        )
        val sent = mutableListOf<List<Int>?>()
        var embedded by mutableStateOf(false)
        compose.setContent {
            FlareThemeProvider {
                // A vote pauses the block until the next view: each round is a fresh card or sheet.
                key(embedded) { PluginView(view = poll, embedded = embedded, onAction = { _, payload -> sent += payload.selection }) }
            }
        }
        for (inSheet in listOf(false, true)) {
            compose.runOnIdle { embedded = inSheet }
            compose.onNodeWithText("最多选 2 项").assertExists()
            compose.onNodeWithContentDescription("爬山").performClick()
            compose.onNodeWithContentDescription("露营").performClick()
            compose.onNodeWithContentDescription("看展").assertIsNotEnabled()
            compose.onNodeWithContentDescription("桌游").assertIsNotEnabled()
            compose.onNodeWithContentDescription("露营").assertIsEnabled()
            // Unticking one frees the rest.
            compose.onNodeWithContentDescription("爬山").performClick()
            compose.onNodeWithContentDescription("看展").assertIsEnabled()
            compose.onNodeWithContentDescription("桌游").performClick()
            compose.onNodeWithText("投票").performClick()
            compose.runOnIdle { assertEquals(listOf(2, 3), sent.last()) }
        }
        compose.runOnIdle { assertEquals(2, sent.size) }
    }

    @Test fun anUnavailablePageSaysWhyAndOnlyAnUnreachableCatalogRetries() {
        var reason by mutableStateOf("catalog_unreachable")
        var retries = 0
        compose.setContent {
            FlareThemeProvider {
                FlarePluginPage(
                    page = walletRef, title = "钱包",
                    view = PluginPageViewModel.fromJson("""{"available":false,"title":"","fields":[],"actions":[],"unavailableReason":"$reason"}"""),
                    onRefresh = {}, onRetry = { retries++ },
                )
            }
        }
        compose.onNodeWithText("钱包").assertExists()
        compose.onNodeWithText(FlareStrings().pluginViewUnavailableCatalogUnreachable).assertExists()
        compose.onNodeWithText(FlareStrings().retry).performClick()
        compose.runOnIdle { assertEquals(1, retries); reason = "disabled" }
        compose.onNodeWithText(FlareStrings().pluginViewUnavailableDisabled).assertExists()
        compose.onNodeWithText(FlareStrings().retry).assertDoesNotExist()
        compose.onNodeWithContentDescription(FlareStrings().pluginPageRefresh).assertDoesNotExist()
    }
}
