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
    /** Optional profile detail — surfaced by ContactDetail / ProfileCard. */
    val remark: String? = null,
    val region: String? = null,
    val phone: String? = null,
    val tags: List<String> = emptyList(),
)

/** One participant in a group (multi-party) call. */
data class CallParticipant(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val muted: Boolean = false,
    val cameraOff: Boolean = false,
    val speaking: Boolean = false,
    val isSelf: Boolean = false,
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

/** A grouped emoji reaction on a message. */
data class ReactionGroup(
    val emoji: String,
    val count: Int,
    val reactedBySelf: Boolean = false,
    val users: List<String> = emptyList(),
)

/** A candidate for @-mention in the mention picker. */
data class MentionCandidate(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val detail: String? = null,
    val isEveryone: Boolean = false,
)

/** A single quick phrase / canned reply. */
data class QuickPhrase(
    val id: String,
    val text: String,
)

/** A named group of quick phrases. */
data class QuickPhraseGroup(
    val key: String,
    val title: String,
    val phrases: List<QuickPhrase> = emptyList(),
)

/** A forward destination (chat/contact) in the forward picker. */
data class ForwardTarget(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val subtitle: String? = null,
)

/** A slash command surfaced by the composer's "/" menu. */
data class SlashCommand(
    val command: String,
    val description: String? = null,
    val hint: String? = null,
)

/** One image in an adaptive album grid (九宫格). */
data class GridImage(val url: String? = null, val alt: String? = null)

/** A selectable chat wallpaper — a hex color ("#7C3AED") or an image. */
data class WallpaperOption(
    val id: String,
    val color: String? = null,
    val imageUrl: String? = null,
    val label: String? = null,
)

/** A named category of emoji in the full emoji picker. */
data class EmojiCategory(
    val key: String,
    val label: String,
    val symbol: String? = null,
    val emojis: List<String> = emptyList(),
)

/** One sticker in a pack. */
data class StickerItem(val id: String, val url: String? = null, val placeholder: String? = null)

/** A sticker pack shown in the sticker panel. */
data class StickerPack(
    val key: String,
    val label: String,
    val coverUrl: String? = null,
    val coverEmoji: String? = null,
    val stickers: List<StickerItem> = emptyList(),
)

enum class SearchResultKind { Contact, Group, Message }

/** A single result row in unified search. */
data class SearchResultItem(
    val id: String,
    val kind: SearchResultKind,
    val title: String,
    val subtitle: String? = null,
    val avatarUrl: String? = null,
    val meta: String? = null,
)

/** A section of search results of one kind. */
data class SearchResultGroup(
    val kind: SearchResultKind,
    val label: String,
    val items: List<SearchResultItem> = emptyList(),
    val total: Int? = null,
)
