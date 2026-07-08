package com.flare.im.ui

import androidx.compose.ui.graphics.vector.ImageVector

/** A directory contact. */
data class Contact(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val signature: String? = null,
    val presence: FlarePresence? = null,
    /** Optional explicit A-Z index letter; derived from [name] when null. */
    val indexKey: String? = null,
)

/** A friend/contact request awaiting accept/reject. */
data class FriendRequest(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val message: String? = null,
)

/** A group the current user belongs to. */
data class GroupSummary(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val memberCount: Int = 0,
)

/** The current user's profile. */
data class UserProfile(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val signature: String? = null,
    val flareId: String? = null,
)

enum class FlareSettingKind { Navigation, Toggle, Value }

data class SettingsItem(
    val key: String,
    val label: String,
    val icon: ImageVector? = null,
    val kind: FlareSettingKind = FlareSettingKind.Navigation,
    val value: Boolean = false,
    val detail: String? = null,
)

data class SettingsSection(
    val title: String? = null,
    val items: List<SettingsItem>,
)

/** A destination in [AppShell]'s adaptive navigation. */
data class NavItem(
    val key: String,
    val label: String,
    val icon: ImageVector,
    val badge: Int = 0,
)
