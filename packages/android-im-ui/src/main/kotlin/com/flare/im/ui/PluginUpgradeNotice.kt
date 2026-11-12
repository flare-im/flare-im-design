package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTag

/** Where an upgrade notice sits: a message card's line, the mark of a "+" or "Me" entry, or a whole page (also the sheet an entry opens). */
enum class FlarePluginUpgradeVariant { Card, Entry, Page }

/** The card line: why it cannot be shown, or that no build can show it yet. */
internal fun pluginUpgradeCardText(mode: PluginUpgradeMode, strings: FlareStrings): String =
    if (mode == PluginUpgradeMode.NotAvailable) strings.pluginUpgradeNotAvailable else strings.pluginViewUnavailableUpgradeRequired

/** The page description. */
internal fun pluginUpgradePageText(mode: PluginUpgradeMode, strings: FlareStrings): String =
    if (mode == PluginUpgradeMode.NotAvailable) strings.pluginUpgradeNotAvailable else strings.pluginUpgradeDescription

/**
 * Plugin upgrade notice — what a plugin contribution this build cannot draw shows instead (`unavailableReason`
 * `upgrade_required`). Spec: Message/PluginUpgradeNotice (`FlarePluginUpgradeNotice`), `spec/plugin-view-vectors.json`
 * → upgradeNotice; docs/plugin-components.md "Upgrade notice".
 *
 * The kit asks nothing: the host reads the engine's `update.plugin_upgrade_status` for the view's `minBuild` and passes
 * the answer as [status]. The update key shows only when that build is offered to this device and the host passes
 * [onUpdate] (which calls `update.open_flow` or opens the platform update UI); with no build for this device yet only
 * the copy shows ("当前版本暂不支持，新版本发布后可用"), so a rollout elsewhere is never revealed.
 * - [FlarePluginUpgradeVariant.Card]: one line ("更新应用后查看") and the update key, under the card's title.
 * - [FlarePluginUpgradeVariant.Entry]: the "需更新" mark after an entry's label; the entry stays listed and opens the
 *   page form in a sheet.
 * - [FlarePluginUpgradeVariant.Page]: the kit empty state with [title] (what the page was), the description and the
 *   update key.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun FlarePluginUpgradeNotice(
    variant: FlarePluginUpgradeVariant = FlarePluginUpgradeVariant.Card,
    /** What the page was (the placeholder's title); page only. */
    title: String? = null,
    /** `update.plugin_upgrade_status` for the view's `minBuild`; null while the host has not asked. */
    status: PluginUpgradeStatus? = null,
    /** The update flow is opening: the key spins. */
    busy: Boolean = false,
    /** Opens the update flow. Without it no key is drawn. */
    onUpdate: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val mode = PluginUpgradeMode.of(status, onUpdate != null)
    val update = { if (!busy && mode == PluginUpgradeMode.Update) onUpdate?.invoke() }
    when (variant) {
        FlarePluginUpgradeVariant.Entry -> PluginBadgeTag(PluginBadge(strings.pluginUpgradeBadge, PluginTone.Warning),
            Modifier.semantics { testTag = "plugin.upgrade.entry" })
        FlarePluginUpgradeVariant.Page -> EmptyState(
            title = title?.takeIf { it.isNotEmpty() } ?: strings.pluginUpgradeTitle,
            description = pluginUpgradePageText(mode, strings),
            icon = "info",
            actions = if (mode != PluginUpgradeMode.Update) null else ({
                Button(label = strings.pluginUpgradeAction, loading = busy, disabled = busy, onClick = update)
            }),
        )
        FlarePluginUpgradeVariant.Card -> FlowRow(
            Modifier.fillMaxWidth().semantics { liveRegion = LiveRegionMode.Polite; testTag = "plugin.upgrade.card" },
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm, Alignment.Start),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs),
        ) {
            Text(pluginUpgradeCardText(mode, strings), color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm,
                modifier = Modifier.align(Alignment.CenterVertically))
            if (mode == PluginUpgradeMode.Update) {
                Button(label = strings.pluginUpgradeAction, size = FlareControlSize.Sm, loading = busy, disabled = busy,
                    appearance = FlareButtonAppearance.Text, maintainTouchTarget = true, onClick = update)
            }
        }
    }
}
