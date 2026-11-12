package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

/**
 * Entry times, day headings over page rows and the maskable hero (`spec/plugin-view-vectors.json` rules.entryTime,
 * rowsGroupByDay, heroMask and the rowDays facts): what the account renderer showed, in plain blocks.
 */
class PluginPlainAccountTest {
    private val table = SpecTables.table("plugin-view-vectors.json")

    private fun daysBlock(times: List<Long?>, groupByDay: Boolean = true) = PluginRowsBlock(
        source = "history",
        columns = listOf(PluginRowsColumn("金额", PluginRowsFormat.Text), PluginRowsColumn("时间", PluginRowsFormat.Time)),
        rows = times.mapIndexed { i, ms -> PluginRow("$i", listOf(PluginRowCell("1", null, null), PluginRowCell("", ms, null)), emptyList()) },
        groupByDay = groupByDay,
    )

    @Test
    fun dayHeadingsFollowTheSharedFacts() {
        val facts = table.obj("rowDays")!!
        val times = (facts["timesMs"] as List<*>).map { (it as? Number)?.toLong() }
        val now = table.long("nowMs")!!
        val zone = facts.int("utcOffsetMinutes")!!
        assertEquals(facts["zh"], PluginViewFormat.rowDayHeadings(daysBlock(times), now, FlareStrings(), zone))
        assertEquals(facts["en"], PluginViewFormat.rowDayHeadings(daysBlock(times), now, flareStringsEnglish(), zone))
        assertTrue(PluginViewFormat.rowDayHeadings(daysBlock(times, groupByDay = false), now, FlareStrings(), zone).all { it == null })
    }

    @Test
    fun aPageListHeadsEachDayOnceAndTheRowUnderItDrawsNoDivider() {
        val now = System.currentTimeMillis()
        val view = PluginViewModel.fromMap(mapOf("available" to true, "title" to "钱包", "blocks" to listOf(mapOf(
            "kind" to "rows", "source" to "history", "groupByDay" to true, "actions" to emptyList<Any>(),
            "columns" to listOf(mapOf("label" to "金额", "format" to "text"), mapOf("label" to "时间", "format" to "time")),
            "rows" to listOf("a", "b").map { mapOf("key" to it, "actions" to emptyList<Any>(),
                "cells" to listOf(mapOf("text" to "+1.00"), mapOf("text" to "", "timeMs" to now))) },
        ))))
        val parts = pluginViewParts(view, embedded = true, quote = false, reasonLine = null, keys = emptyList(),
            detailKey = null, failure = null, strings = FlareStrings(), nowMs = now)
        val days = parts.filterIsInstance<PluginViewPart.RowDay>()
        assertEquals(listOf(FlareStrings().accountToday), days.map { it.text })
        val rows = parts.filterIsInstance<PluginViewPart.Row>()
        assertEquals(listOf(true, false), rows.map { it.first })
    }

    @Test
    fun theNewFieldsAreRead() {
        val entries = pluginBlockOf(mapOf("kind" to "entries", "numbered" to false, "total" to 1, "more" to false,
            "items" to listOf(mapOf("index" to 1, "text" to "5.00", "timeMs" to 7))))
        assertIs<PluginEntriesBlock>(entries)
        assertEquals(7L, entries.items.single().timeMs)
        val hero = pluginBlockOf(mapOf("kind" to "hero", "value" to "12.00", "amount" to true, "maskable" to true))
        assertIs<PluginHeroBlock>(hero)
        assertTrue(hero.maskable)
        val plain = pluginBlockOf(mapOf("kind" to "hero", "value" to "12.00"))
        assertIs<PluginHeroBlock>(plain)
        assertFalse(plain.maskable)
    }
}
