package com.flare.im.ui

/** A built-in 我 page destination; its id is also the host's route name. */
enum class FlareMeMenuBuiltin(val id: String) { Moments("moments"), Reports("reports"), Invite("invite"), Settings("settings") }

/**
 * One item of the social SDK's `features.meMenu`, as the kit reads it: a built-in destination ([kind] `builtin`, [id]
 * moments / reports / invite / settings) or a plugin page entry ([kind] `plugin`, [id] `plugin:<contributionId>`, its
 * [title]). [icon] is a kit icon name; [order] is the SDK's sort key (the kit keeps the given order).
 */
data class FlareMeMenuItem(
    val kind: String,
    val id: String,
    val icon: String? = null,
    val title: String? = null,
    val order: Int = 0,
)

/** The `features.meMenu` result: the items in the SDK's order, and whether the switches and catalog were all read. */
data class FlareMeMenu(val items: List<FlareMeMenuItem>, val complete: Boolean = true) {
    companion object {
        /**
         * The social SDK's `features.meMenu` JSON (`{items: [{kind, id, icon?, title?, order, …}], complete}`) as the kit
         * reads it; fields the kit does not use are skipped. Malformed JSON reads as an empty, incomplete menu.
         */
        fun parse(json: String): FlareMeMenu {
            val root = runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *> ?: return FlareMeMenu(emptyList(), complete = false)
            val items = (root["items"] as? List<*>).orEmpty().mapNotNull { raw ->
                val item = raw as? Map<*, *> ?: return@mapNotNull null
                val kind = item["kind"] as? String ?: return@mapNotNull null
                val id = item["id"] as? String ?: return@mapNotNull null
                FlareMeMenuItem(
                    kind = kind,
                    id = id,
                    icon = item["icon"] as? String,
                    title = item["title"] as? String,
                    order = (item["order"] as? Number)?.toInt() ?: 0,
                )
            }
            return FlareMeMenu(items, complete = root["complete"] == true)
        }
    }
}

/**
 * The 我 page's menu as [SettingsList] sections (spec/me-menu-vectors.json): every item but settings in the SDK's order,
 * then settings alone, last; an empty section is left out. A built-in item reads [labels] by id, else the kit copy
 * (`meMenuMoments` … `meMenuSettings`); a plugin item reads its title, else `meMenuPluginFallback`. Any item reads
 * [summaries] by its id (trimmed, when not empty) as its detail: a plugin item's `meMenuSummary`, a built-in page's own
 * subtitle (what 我的邀请 holds). Every icon goes through [flareIconNameOrFallback], and an item without one
 * draws the fallback too. Unknown kinds and built-in ids are dropped; of two items with one id the first is kept. Every
 * row is a navigation row keyed by the item id: the host routes built-in ids and opens a plugin item's page.
 */
fun flareMeMenuSections(
    menu: FlareMeMenu?,
    labels: Map<FlareMeMenuBuiltin, String> = emptyMap(),
    summaries: Map<String, String> = emptyMap(),
    strings: FlareStrings = FlareStrings(),
): List<SettingsSection> {
    val destinations = mutableListOf<SettingsItem>()
    val settings = mutableListOf<SettingsItem>()
    val seen = HashSet<String>()
    val detail = { id: String -> summaries[id]?.trim()?.takeIf { it.isNotEmpty() } }
    for (item in menu?.items.orEmpty()) {
        if (item.id in seen) continue
        val icon = flareIconNameOrFallback(item.icon) ?: FLARE_ICON_FALLBACK
        val row = when (item.kind) {
            "builtin" -> {
                val builtin = FlareMeMenuBuiltin.entries.firstOrNull { it.id == item.id } ?: continue
                val label = labels[builtin]?.trim()?.takeIf { it.isNotEmpty() } ?: when (builtin) {
                    FlareMeMenuBuiltin.Moments -> strings.meMenuMoments
                    FlareMeMenuBuiltin.Reports -> strings.meMenuReports
                    FlareMeMenuBuiltin.Invite -> strings.meMenuInvite
                    FlareMeMenuBuiltin.Settings -> strings.meMenuSettings
                }
                SettingsItem(key = item.id, label = label, icon = icon, kind = FlareSettingKind.Navigation, detail = detail(item.id))
            }
            "plugin" -> SettingsItem(
                key = item.id,
                label = item.title?.trim()?.takeIf { it.isNotEmpty() } ?: strings.meMenuPluginFallback,
                icon = icon,
                kind = FlareSettingKind.Navigation,
                detail = detail(item.id),
            )
            else -> continue
        }
        seen += item.id
        (if (item.kind == "builtin" && item.id == FlareMeMenuBuiltin.Settings.id) settings else destinations) += row
    }
    return listOf(destinations, settings).filter { it.isNotEmpty() }.map { SettingsSection(items = it) }
}
