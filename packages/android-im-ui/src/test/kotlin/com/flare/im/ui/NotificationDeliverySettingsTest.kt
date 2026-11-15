package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

class NotificationDeliverySettingsTest {
    @Test fun statusRowSaysThePermissionInTheSettingsWords() {
        assertEquals(listOf("已开启", "已关闭", "未开启"), FlareNotificationStatus.entries.map { notificationStatusLabel(it) })
        assertEquals(
            listOf("On", "Off", "Not turned on"),
            FlareNotificationStatus.entries.map { notificationStatusLabel(it, flareStringsEnglish()) },
        )
    }

    @Test fun backgroundRowUsesTheBatterySettingsWords() {
        assertEquals(listOf("不受限制", "已优化", "受限制"), FlareBackgroundDelivery.entries.map { backgroundDeliveryLabel(it) })
        assertEquals(
            listOf("Unrestricted", "Optimized", "Restricted"),
            FlareBackgroundDelivery.entries.map { backgroundDeliveryLabel(it, flareStringsEnglish()) },
        )
    }

    @Test fun sectionFooterIsOptional() {
        assertEquals(null, SettingsSection(items = emptyList()).footer)
        assertEquals("note", SettingsSection(items = emptyList(), footer = "note").footer)
    }

    @Test fun theSectionCarriesTheRowsAHostPlacesInItsOwnList() {
        val iOSLike = notificationDeliverySection(null, null, title = null, footer = null, statusActionable = false, strings = FlareStrings())
        assertEquals("通知", iOSLike.title)
        assertEquals(listOf("notifications"), iOSLike.items.map { it.key })
        assertEquals(null, iOSLike.items[0].detail)
        assertEquals(FlareSettingKind.Value, iOSLike.items[0].kind)

        val android = notificationDeliverySection(
            FlareNotificationStatus.Off, FlareBackgroundDelivery.Restricted, title = "", footer = "note",
            statusActionable = true, strings = flareStringsEnglish(),
        )
        assertEquals(listOf("notifications", "backgroundDelivery"), android.items.map { it.key })
        assertEquals(listOf("Off", "Restricted"), android.items.map { it.detail })
        assertEquals(FlareSettingKind.Navigation, android.items[0].kind)
        assertEquals("", android.title)
        assertEquals("note", android.footer)
    }

    @Test fun aVendorActionWithoutALabelReadsTheKitsAutoStartLabel() {
        assertEquals(null, FlareNotificationGuideAction {}.label)
        assertEquals("Auto-start", FlareNotificationGuideAction("Auto-start") {}.label)
        assertEquals("自启动管理", FlareStrings().backgroundDeliveryAutoStart)
        assertEquals("Auto-start settings", flareStringsEnglish().backgroundDeliveryAutoStart)
    }

    @Test fun theResidentSwitchAppearsOnlyWhereTheBuildOffersIt() {
        val without = notificationDeliverySection(
            FlareNotificationStatus.On, FlareBackgroundDelivery.Optimized, title = null, footer = null,
            statusActionable = true, strings = FlareStrings(),
        )
        assertEquals(listOf("notifications", "backgroundDelivery"), without.items.map { it.key })

        val off = notificationDeliverySection(
            FlareNotificationStatus.On, FlareBackgroundDelivery.Optimized, title = null, footer = null,
            statusActionable = true, strings = flareStringsEnglish(), residentMode = false, residentActionable = true,
            batteryActionable = true,
        )
        assertEquals(listOf("notifications", "backgroundDelivery", "residentConnection"), off.items.map { it.key })
        val switch = off.items.last()
        assertEquals(FlareSettingKind.Toggle, switch.kind)
        assertEquals(false, switch.value)
        assertEquals(false, switch.disabled)
        assertEquals("Stay connected in the background", switch.label)
        assertEquals(flareStringsEnglish().residentConnectionDescription, switch.description)
    }

    @Test fun theBatteryRowFollowsTheSwitchUnlessBatteryUseIsUnrestricted() {
        fun keys(resident: Boolean, background: FlareBackgroundDelivery?, battery: Boolean = true) = notificationDeliverySection(
            FlareNotificationStatus.On, background, title = null, footer = null, statusActionable = true,
            strings = FlareStrings(), residentMode = resident, residentActionable = false, batteryActionable = battery,
        )
        val on = keys(resident = true, background = FlareBackgroundDelivery.Restricted)
        assertEquals(listOf("notifications", "backgroundDelivery", "residentConnection", "residentBattery"), on.items.map { it.key })
        assertEquals(true, on.items[2].disabled)
        val battery = on.items[3]
        assertEquals("关闭电池优化", battery.label)
        assertEquals("受限制", battery.detail)
        assertEquals(FlareSettingKind.Navigation, battery.kind)
        assertEquals(FlareSettingKind.Value, keys(resident = true, background = null, battery = false).items.last().kind)

        assertEquals("residentConnection", keys(resident = true, background = FlareBackgroundDelivery.Unrestricted).items.last().key)
        assertEquals("residentConnection", keys(resident = false, background = FlareBackgroundDelivery.Restricted).items.last().key)
    }
}
