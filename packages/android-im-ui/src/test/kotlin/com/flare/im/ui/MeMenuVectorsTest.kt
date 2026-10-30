package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** flareMeMenuSections and flareIconNameOrFallback against spec/me-menu-vectors.json. */
class MeMenuVectorsTest {
    private val table = SpecTables.table("me-menu-vectors.json")

    private fun menu(raw: Map<*, *>): FlareMeMenu = FlareMeMenu(
        items = raw.items("items").map { item ->
            FlareMeMenuItem(kind = item.str("kind")!!, id = item.str("id")!!, icon = item.str("icon"), title = item.str("title"), order = item.int("order") ?: 0)
        },
        complete = raw.bool("complete") ?: false,
    )

    @Test fun everyCaseGivesTheSectionsTheVectorSays() {
        val cases = table.items("cases").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            val strings = if (case.str("locale") == "en") flareStringsEnglish() else FlareStrings()
            val labels = case.obj("labels").orEmpty().mapNotNull { (key, value) ->
                FlareMeMenuBuiltin.entries.firstOrNull { it.id == key }?.let { it to value as String }
            }.toMap()
            val summaries = case.obj("summaries").orEmpty().map { (key, value) -> key as String to value as String }.toMap()
            val sections = flareMeMenuSections(menu(case.obj("menu")!!), labels, summaries, strings)
            val expected = (case["expect"] as List<*>).map { section ->
                (section as Map<*, *>).items("items").map { item ->
                    SettingsItem(key = item.str("key")!!, label = item.str("label")!!, icon = item.str("icon"),
                        kind = FlareSettingKind.Navigation, detail = item.str("detail"))
                }
            }
            assertEquals(expected, sections.map { it.items }, case.str("id"))
        }
    }

    @Test fun theMenuReadsTheSdkJson() {
        val parsed = FlareMeMenu.parse(
            """{"items":[{"kind":"builtin","id":"moments","icon":"moments","order":10,"target":{"route":"moments"}},""" +
                """{"kind":"plugin","id":"plugin:w","contributionId":"w","title":"钱包","icon":"wallet","order":100,"target":{"pluginId":"p","page":"wallet"}}],"complete":true}""",
        )
        assertEquals(
            FlareMeMenu(listOf(FlareMeMenuItem("builtin", "moments", "moments", null, 10), FlareMeMenuItem("plugin", "plugin:w", "wallet", "钱包", 100)), complete = true),
            parsed,
        )
        assertEquals(FlareMeMenu(emptyList(), complete = false), FlareMeMenu.parse("not json"))
    }

    @Test fun unknownIconNamesFallBackToThePluginGlyph() {
        val cases = table.obj("iconFallback")!!.items("cases").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) assertEquals(case.str("expect"), flareIconNameOrFallback(case.str("name")), case.str("name"))
    }
}
