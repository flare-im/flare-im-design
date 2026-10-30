package com.flare.im.ui

import kotlin.test.*

class AccountViewTest {
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
}
