package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier

/** The system notification permission, as a settings row says it. */
enum class FlareNotificationStatus { On, Off, NotTurnedOn }

/** What the system lets the app do in the background, in the words of the platform's battery settings. */
enum class FlareBackgroundDelivery { Unrestricted, Optimized, Restricted }

/**
 * One extra way to keep background delivery working, offered by the host (a phone maker's auto-start page). [label]
 * defaults to the strings table's `backgroundDeliveryAutoStart`.
 */
data class FlareNotificationGuideAction(val label: String? = null, val onSelect: () -> Unit)

/** The words of [status] in a settings row. */
fun notificationStatusLabel(status: FlareNotificationStatus, strings: FlareStrings = FlareStrings()): String = when (status) {
    FlareNotificationStatus.On -> strings.notificationStatusOn
    FlareNotificationStatus.Off -> strings.notificationStatusOff
    FlareNotificationStatus.NotTurnedOn -> strings.notificationStatusNotTurnedOn
}

/** The words of [background] in a settings row. */
fun backgroundDeliveryLabel(background: FlareBackgroundDelivery, strings: FlareStrings = FlareStrings()): String = when (background) {
    FlareBackgroundDelivery.Unrestricted -> strings.backgroundDeliveryUnrestricted
    FlareBackgroundDelivery.Optimized -> strings.backgroundDeliveryOptimized
    FlareBackgroundDelivery.Restricted -> strings.backgroundDeliveryRestricted
}

/** Row keys of the section and its guide. */
internal const val NOTIFICATION_STATUS_ROW = "notifications"
internal const val BACKGROUND_DELIVERY_ROW = "backgroundDelivery"
internal const val BATTERY_SETTINGS_ROW = "batteryUsage"
internal const val RESIDENT_CONNECTION_ROW = "residentConnection"
internal const val RESIDENT_BATTERY_ROW = "residentBattery"
private const val VENDOR_ROW_PREFIX = "vendor:"

/**
 * The group as one settings section: the permission, then the background row where the platform has one, then the
 * resident connection switch where the build offers it ([residentMode] not null) with the battery optimization row
 * while the switch is on and the battery settings do not say unrestricted. [title] defaults to
 * `notificationDeliveryTitle`; an empty one draws none.
 */
internal fun notificationDeliverySection(
    status: FlareNotificationStatus?,
    background: FlareBackgroundDelivery?,
    title: String?,
    footer: String?,
    statusActionable: Boolean,
    strings: FlareStrings,
    residentMode: Boolean? = null,
    residentActionable: Boolean = false,
    batteryActionable: Boolean = false,
): SettingsSection {
    val items = buildList<SettingsItem> {
        add(
            SettingsItem(
                key = NOTIFICATION_STATUS_ROW,
                label = strings.notificationDeliveryNewMessages,
                icon = "notification",
                kind = if (statusActionable) FlareSettingKind.Navigation else FlareSettingKind.Value,
                detail = status?.let { notificationStatusLabel(it, strings) },
            ),
        )
        if (background != null) {
            add(
                SettingsItem(
                    key = BACKGROUND_DELIVERY_ROW,
                    label = strings.backgroundDeliveryLabel,
                    icon = "refresh",
                    detail = backgroundDeliveryLabel(background, strings),
                ),
            )
        }
        if (residentMode != null) {
            add(
                SettingsItem(
                    key = RESIDENT_CONNECTION_ROW,
                    label = strings.residentConnectionLabel,
                    icon = "link",
                    kind = FlareSettingKind.Toggle,
                    value = residentMode,
                    disabled = !residentActionable,
                    description = strings.residentConnectionDescription,
                ),
            )
            if (residentMode && background != FlareBackgroundDelivery.Unrestricted) {
                add(
                    SettingsItem(
                        key = RESIDENT_BATTERY_ROW,
                        label = strings.residentConnectionBattery,
                        icon = "settings",
                        kind = if (batteryActionable) FlareSettingKind.Navigation else FlareSettingKind.Value,
                        detail = background?.let { backgroundDeliveryLabel(it, strings) },
                        description = strings.residentConnectionBatteryDescription,
                    ),
                )
            }
        }
    }
    return SettingsSection(title = title ?: strings.notificationDeliveryTitle, items = items, footer = footer)
}

/**
 * Whether new messages reach the person when the app is not in front, as one settings section.
 * Spec: Profile/NotificationDeliverySettings (`NotificationDeliverySettings`).
 *
 * "New message notifications" shows the system permission ([status]; null until it has been read) and hands the
 * press to the host in [onStatusAction]: the host asks for the permission or opens the system settings, whichever
 * the platform allows (without the callback the row is information only). With [background] a second row shows
 * what the battery settings let the app do and opens a guide in the kit [BottomSheet]: why background running
 * matters, the battery settings ([onOpenBatterySettings]) and any auto-start pages the host knows of
 * ([vendorActions]). The section draws through [SettingsList], so it looks like the settings around it, and takes
 * a [footer]. It reads nothing from the platform and opens nothing itself.
 *
 * Android only: with [residentMode] (not null where the build offers the resident connection mode, that is where it
 * has no push provider) the group ends with a switch, "Stay connected in the background", whose explanation sits
 * under its title and whose change goes to [onResidentModeChange] (without the callback the switch is disabled).
 * While the switch is on and [background] is not [FlareBackgroundDelivery.Unrestricted], a battery optimization row
 * follows that opens [onOpenBatterySettings]. The other kits have no such mode and no such parameters.
 *
 * This form draws the group as a list of its own; a settings page that is already one [SettingsList] places the
 * group among its own sections with the `sectionContent` form.
 */
@Composable
fun NotificationDeliverySettings(
    status: FlareNotificationStatus?,
    background: FlareBackgroundDelivery? = null,
    vendorActions: List<FlareNotificationGuideAction> = emptyList(),
    title: String? = null,
    footer: String? = null,
    onStatusAction: (() -> Unit)? = null,
    onOpenBatterySettings: (() -> Unit)? = null,
    residentMode: Boolean? = null,
    onResidentModeChange: ((Boolean) -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    NotificationDeliverySettings(
        status, background, vendorActions, title, footer, onStatusAction, onOpenBatterySettings, residentMode,
        onResidentModeChange,
    ) { section, select ->
        Column(modifier.fillMaxWidth()) {
            SettingsList(
                sections = listOf(section),
                onToggle = { item, _ -> select(item) },
                onSelect = { select(it) },
                scrollable = false,
            )
        }
    }
}

/**
 * The section form of [NotificationDeliverySettings], for a settings page that is already one [SettingsList]: the
 * host draws the list in [sectionContent] and gets the group as one [SettingsSection] with `select`, which runs a
 * row of the group (the status action, the background guide in the kit [BottomSheet], flipping the resident
 * connection switch, the battery optimization row) and returns whether the row was one; the host handles the rows it
 * returns false for. The group's rows are keyed `notifications`, `backgroundDelivery`, `residentConnection` and
 * `residentBattery`, so the host's own rows keep other keys. The resident connection row is a switch: the host hands
 * it to `select` from its `onToggle` as well.
 *
 * ```kotlin
 * NotificationDeliverySettings(status = access.status, onStatusAction = { notifications.enable() }) { notifications, select ->
 *     SettingsList(
 *         sections = listOf(general, notifications, about),
 *         onToggle = { item, on -> if (!select(item)) toggle(item, on) },
 *         onSelect = { if (!select(it)) openPage(it) },
 *     )
 * }
 * ```
 */
@Composable
fun NotificationDeliverySettings(
    status: FlareNotificationStatus?,
    background: FlareBackgroundDelivery? = null,
    vendorActions: List<FlareNotificationGuideAction> = emptyList(),
    title: String? = null,
    footer: String? = null,
    onStatusAction: (() -> Unit)? = null,
    onOpenBatterySettings: (() -> Unit)? = null,
    residentMode: Boolean? = null,
    onResidentModeChange: ((Boolean) -> Unit)? = null,
    sectionContent: @Composable (section: SettingsSection, select: (SettingsItem) -> Boolean) -> Unit,
) {
    val strings = flareStrings()
    var guideOpen by rememberSaveable { mutableStateOf(false) }
    // The guide belongs to the background row: when the row goes, so does the guide.
    LaunchedEffect(background) { if (background == null) guideOpen = false }
    val section = notificationDeliverySection(
        status, background, title, footer, onStatusAction != null, strings,
        residentMode = residentMode,
        residentActionable = onResidentModeChange != null,
        batteryActionable = onOpenBatterySettings != null,
    )
    sectionContent(section) { item ->
        when {
            item.key == NOTIFICATION_STATUS_ROW -> { onStatusAction?.invoke(); true }
            item.key == BACKGROUND_DELIVERY_ROW && background != null -> { guideOpen = true; true }
            item.key == RESIDENT_CONNECTION_ROW && residentMode != null -> { onResidentModeChange?.invoke(!residentMode); true }
            item.key == RESIDENT_BATTERY_ROW -> { onOpenBatterySettings?.invoke(); true }
            else -> false
        }
    }
    if (guideOpen && background != null) {
        BackgroundDeliveryGuide(background, vendorActions, onOpenBatterySettings, onClose = { guideOpen = false })
    }
}

/** The guide behind the background row: why it matters, the battery settings, then the maker's auto-start pages. */
@Composable
private fun BackgroundDeliveryGuide(
    background: FlareBackgroundDelivery,
    vendorActions: List<FlareNotificationGuideAction>,
    onOpenBatterySettings: (() -> Unit)?,
    onClose: () -> Unit,
) {
    val strings = flareStrings()
    val colors = flareColors()
    BottomSheet(onClose = onClose, title = strings.backgroundDeliveryLabel) {
        Column(
            Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())
                .padding(bottom = FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            Text(
                strings.backgroundDeliveryExplanation,
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeMd,
                modifier = Modifier.padding(horizontal = FlareSizes.spacingLg),
            )
            if (vendorActions.isNotEmpty()) {
                Text(
                    strings.backgroundDeliveryAutoStartHint,
                    color = colors.textSecondary,
                    fontSize = FlareSizes.fontSizeMd,
                    modifier = Modifier.padding(horizontal = FlareSizes.spacingLg),
                )
            }
            val rows = buildList<SettingsItem> {
                add(
                    SettingsItem(
                        key = BATTERY_SETTINGS_ROW,
                        label = strings.backgroundDeliveryBattery,
                        kind = if (onOpenBatterySettings != null) FlareSettingKind.Navigation else FlareSettingKind.Value,
                        detail = backgroundDeliveryLabel(background, strings),
                    ),
                )
                vendorActions.forEachIndexed { index, action ->
                    add(SettingsItem(key = "$VENDOR_ROW_PREFIX$index", label = action.label ?: strings.backgroundDeliveryAutoStart))
                }
            }
            SettingsList(
                sections = listOf(SettingsSection(items = rows)),
                onSelect = { item ->
                    if (item.key == BATTERY_SETTINGS_ROW) {
                        onOpenBatterySettings?.invoke()
                    } else {
                        item.key.removePrefix(VENDOR_ROW_PREFIX).toIntOrNull()?.let { vendorActions.getOrNull(it)?.onSelect?.invoke() }
                    }
                },
                scrollable = false,
            )
        }
    }
}
