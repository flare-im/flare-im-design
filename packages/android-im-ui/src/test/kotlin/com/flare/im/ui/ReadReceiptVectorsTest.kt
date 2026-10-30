package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** ReadReceiptSheet against spec/read-receipt-vectors.json: tab numbers, the body, the rows and the list's tail. */
class ReadReceiptVectorsTest {
    private val table = SpecTables.table("read-receipt-vectors.json")
    private val cases = table.items("cases").filter { (it["platforms"] as List<*>).contains("compose") }

    private fun column(name: String?): FlareReadReceiptColumn? = when (name) {
        "read" -> FlareReadReceiptColumn.Read
        "unread" -> FlareReadReceiptColumn.Unread
        else -> null
    }

    private fun presentation(input: Map<*, *>, tab: FlareReadReceiptColumn) = flareReadReceiptPresentation(
        state = when (input.str("state")) {
            "loading" -> FlareReadReceiptState.Loading
            "error" -> FlareReadReceiptState.Error
            "unavailable" -> FlareReadReceiptState.Unavailable
            else -> FlareReadReceiptState.Ready
        },
        readers = input.int("readers") ?: 0,
        unread = input.int("unread") ?: 0,
        readCount = input.int("readCount"),
        unreadCount = input.int("unreadCount"),
        readHasMore = input.bool("readHasMore") ?: false,
        unreadHasMore = input.bool("unreadHasMore") ?: false,
        loadingMore = column(input.str("loadingMore")),
        loadMoreFailed = column(input.str("loadMoreFailed")),
        tab = tab,
    )

    private fun facts(view: FlareReadReceiptPresentation): Map<String, Any?> = mapOf(
        "body" to view.body.name.lowercase(),
        "rows" to view.rows,
        "tail" to view.tail.name.replaceFirstChar { it.lowercase() },
    )

    @Test fun everyCaseDrawsWhatTheVectorSays() {
        assertTrue(cases.isNotEmpty(), "the table lists compose cases")
        for (case in cases) {
            val id = case.str("id")
            val input = case.obj("input")!!
            val expect = case.obj("expect")!!
            val tab = column(input.str("initialTab")) ?: FlareReadReceiptColumn.Read
            val view = presentation(input, tab)
            val tabs = (expect["tabs"] as? List<*>)?.map { tabFact ->
                val fact = tabFact as Map<*, *>
                column(fact.str("value")) to fact.int("count")
            }
            assertEquals(tabs, view.tabs, "$id tabs")
            assertEquals(facts(view), mapOf("body" to expect.str("body"), "rows" to expect.int("rows"), "tail" to expect.str("tail")), id)
            assertEquals(column(expect.str("empty")), view.empty, "$id empty")
            for (step in case.items("taps")) {
                val then = step.obj("then") ?: continue
                val next = presentation(input, column(step.str("tap")!!.removePrefix("tab:"))!!)
                assertEquals(mapOf("body" to then.str("body"), "rows" to then.int("rows"), "tail" to then.str("tail")), facts(next), "$id then")
            }
        }
    }

    @Test fun theNewCopyMatchesTheSharedSource() {
        val en = flareStringsEnglish()
        val zh = FlareStrings()
        for ((key, pair) in mapOf(
            "readReceiptLoadFailed" to (zh.readReceiptLoadFailed to en.readReceiptLoadFailed),
            "readReceiptUnavailable" to (zh.readReceiptUnavailable to en.readReceiptUnavailable),
            "readReceiptLoadMore" to (zh.readReceiptLoadMore to en.readReceiptLoadMore),
            "readReceiptLoadMoreFailed" to (zh.readReceiptLoadMoreFailed to en.readReceiptLoadMoreFailed),
        )) {
            assertEquals((table.obj("strings")!!.obj("zh")!!).str(key), pair.first, key)
            assertEquals((table.obj("strings")!!.obj("en")!!).str(key), pair.second, key)
        }
    }
}
