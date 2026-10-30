package com.flare.im.ui

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * [FlareReadReceiptListState] against spec/read-receipt-list-vectors.json, step by step: each loader call is held
 * until the step answers it, so the order calls settle in is the table's. The holder runs on an unconfined scope, so
 * a settled call has landed when the step looks at the pages.
 */
class ReadReceiptListVectorsTest {
    private val table = SpecTables.table("read-receipt-list-vectors.json")

    private class Call(val column: FlareReadReceiptColumn, val cursor: String?, val answer: CompletableDeferred<FlareReadReceiptMembers?>)

    private fun column(wire: String) = if (wire == "read") FlareReadReceiptColumn.Read else FlareReadReceiptColumn.Unread
    private fun wire(column: FlareReadReceiptColumn?) = when (column) {
        FlareReadReceiptColumn.Read -> "read"
        FlareReadReceiptColumn.Unread -> "unread"
        null -> null
    }

    private fun members(raw: Map<*, *>): FlareReadReceiptMembers = FlareReadReceiptMembers(
        people = (raw["people"] as List<*>).map { Contact(id = it as String, name = it) },
        nextCursor = raw.str("nextCursor"),
    )

    private fun pages(raw: Map<*, *>?): FlareReadReceiptPages? = raw?.let {
        FlareReadReceiptPages(
            state = FlareReadReceiptState.entries.first { state -> state.name.equals(it.str("state"), ignoreCase = true) },
            read = members(it.obj("read")!!),
            unread = members(it.obj("unread")!!),
            loadingMore = it.str("loadingMore")?.let(::column),
            loadMoreFailed = it.str("loadMoreFailed")?.let(::column),
        )
    }

    private fun settle(call: Call, answer: Any?) {
        when (answer) {
            "pending" -> Unit
            "throw" -> call.answer.completeExceptionally(IllegalStateException("page failed"))
            null -> call.answer.complete(null)
            is Map<*, *> -> call.answer.complete(members(answer))
            else -> error("unknown answer $answer")
        }
    }

    @Test fun everyCaseStepsThroughTheTable() {
        val cases = table.items("cases").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            val id = case.str("id")!!
            val calls = mutableListOf<Call>()
            val settled = HashSet<Call>()
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
            val list = FlareReadReceiptListState(scope) { column, cursor ->
                val call = Call(column, cursor, CompletableDeferred())
                calls += call
                call.answer.await()
            }
            for ((index, step) in case.items("steps").withIndex()) {
                val where = "$id step ${index + 1}"
                val before = calls.size
                val action = step.str("do")!!
                when {
                    action == "open" -> list.open(step.str("key") ?: "m1")
                    action == "close" -> list.open(null)
                    action == "retry" -> list.retry()
                    action.startsWith("loadMore:") -> list.loadMore(column(action.removePrefix("loadMore:")))
                    action.startsWith("settle:") -> {
                        val target = column(action.removePrefix("settle:"))
                        val call = calls.first { it.column == target && it !in settled }
                        settled += call
                        settle(call, step["answer"])
                    }
                    else -> error("$where: unknown step $action")
                }
                val made = calls.drop(before)
                step["asks"]?.let { asks ->
                    assertEquals(
                        (asks as List<*>).map { (it as List<*>)[0] to it[1] },
                        made.map { wire(it.column) to it.cursor },
                        "$where asks",
                    )
                }
                if (!action.startsWith("settle:")) {
                    val answers = step.obj("answers")
                    for (call in made) {
                        val answer = if (answers != null) answers[wire(call.column)] else step["answer"]
                        if (answers != null || step.containsKey("answer")) {
                            if (answer != "pending") settled += call
                            settle(call, answer)
                        }
                    }
                }
                assertEquals(pages(step.obj("expect")), list.pages, where)
            }
            scope.cancel()
        }
    }
}
