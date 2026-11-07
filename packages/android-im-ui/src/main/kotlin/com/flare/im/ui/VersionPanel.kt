package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalView

private const val FLARE_VERSION_PANEL_ROW = "update"

/**
 * The version block of an About page, in the settings list's rows: the version, the build, the channel and the row that
 * checks for an update. Spec: Profile/VersionPanel (`VersionPanel`).
 *
 * What that row says and does is [flareVersionPanel]'s call (`spec/update-prompt-vectors.json`, the same in every kit).
 * The panel holds no SDK: it reports intent, and the row is disabled while work is under way or while the host passes
 * no handler for what it would do. It sizes to its content, so it goes inside the host's scrolling page.
 */
@Composable
fun VersionPanel(
    /** `UpdateStatus.current.version`. */
    version: String,
    /** `UpdateStatus.current.build`. */
    build: Long? = null,
    /** `UpdateStatus.current.channel`. */
    channel: String? = null,
    /** `UpdateStatus.state`. */
    updateState: String? = null,
    /** Check for an update (`update.check` with `manual`). */
    onCheck: (() -> Unit)? = null,
    /** Start or finish the update. */
    onUpdate: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val view = LocalView.current
    val model = flareVersionPanel(updateState)
    val handler = when (model.action) {
        FlareVersionPanelAction.Check -> onCheck
        FlareVersionPanelAction.Update -> onUpdate
        null -> null
    }
    val detail = model.detail?.label(strings)
    LaunchedEffect(detail) { if (detail != null) view.announceForAccessibility(detail) }
    val items = buildList {
        add(SettingsItem(key = "version", label = strings.versionPanelVersion, kind = FlareSettingKind.Value, detail = version))
        if (build != null) {
            add(SettingsItem(key = "build", label = strings.versionPanelBuild, kind = FlareSettingKind.Value, detail = build.toString()))
        }
        if (!channel.isNullOrEmpty()) {
            add(
                SettingsItem(
                    key = "channel",
                    label = strings.versionPanelChannel,
                    kind = FlareSettingKind.Value,
                    detail = flareVersionChannelLabel(channel, strings),
                ),
            )
        }
        add(
            SettingsItem(
                key = FLARE_VERSION_PANEL_ROW,
                label = model.row.label(strings),
                kind = FlareSettingKind.Action,
                detail = detail,
                disabled = handler == null,
            ),
        )
    }
    SettingsList(
        sections = listOf(SettingsSection(title = strings.versionPanelTitle, items = items)),
        onSelect = { item -> if (item.key == FLARE_VERSION_PANEL_ROW) handler?.invoke() },
        scrollable = false,
    )
}
