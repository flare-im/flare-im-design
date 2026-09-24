package com.flare.im.ui


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
    /**
     * The public handle the contact is found by, shown as the Flare ID (ContactDetail, ProfileCard). Never the
     * account [id], which is internal: without a handle no Flare ID is shown.
     */
    val flareId: String? = null,
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

/** Who sent a [FriendRequest]: someone asking the current user, or the current user asking. */
enum class FriendRequestDirection { Incoming, Outgoing }

/** A friend/contact request: an incoming one awaits accept/reject, an outgoing one awaits the other side. */
data class FriendRequest(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val message: String? = null,
    val direction: FriendRequestDirection = FriendRequestDirection.Incoming,
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

/**
 * What a settings row is (Vue `FlareSettingsRow`):
 * - [Navigation] opens a page or a picker — a button with a chevron and an optional current value.
 * - [Toggle] is a switch.
 * - [Action] runs in place (clear history, mark unread, sign out) — a button with no chevron; pair it
 *   with `danger` when the step destroys something.
 * - [Value] is read-only information — not a control at all: no pressed state, no chevron, taps do
 *   nothing, and assistive technology reads "label, detail" as one element.
 */
enum class FlareSettingKind { Navigation, Toggle, Action, Value }

data class SettingsItem(
    val key: String,
    val label: String,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    val icon: String? = null,
    val kind: FlareSettingKind = FlareSettingKind.Navigation,
    val value: Boolean = false,
    val detail: String? = null,
    val disabled: Boolean = false,
    val danger: Boolean = false,
)

data class SettingsSection(
    val title: String? = null,
    val items: List<SettingsItem>,
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

// --- Form / controls ---
/** 中性的低强度动作:配在主按钮旁边的那个「出口」。和 text 的唯一区别是不用品牌色 —— 两个都用紫色就分不出主次;和 ghost 的区别是没有那圈 40% 品牌色描边。内距走尺寸类而不是像 text 那样压成固定值,这样它和配对的主按钮同字数时同宽。 */
enum class FlareButtonVariant { Primary, Secondary, Ghost, Danger, Text, Quiet }
enum class FlareControlSize { Sm, Md, Lg }
enum class FlareIconButtonVariant { Plain, Tinted, Solid }
data class FlareSelectOption(val value: String, val label: String, val disabled: Boolean = false)

// --- Moments (圈子) social feed ---
data class MomentAuthor(val id: String, val name: String, val avatarUrl: String? = null)
data class MomentLike(val id: String, val name: String)
data class MomentComment(
    val id: String,
    val author: MomentAuthor,
    val text: String,
    val replyToName: String? = null,
    val time: String? = null,
)
data class Moment(
    val id: String,
    val author: MomentAuthor,
    val text: String? = null,
    val images: List<GridImage> = emptyList(),
    val location: String? = null,
    val time: String? = null,
    val likes: List<MomentLike> = emptyList(),
    val comments: List<MomentComment> = emptyList(),
    val likedBySelf: Boolean = false,
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

/**
 * A section of search results of one kind. [total] is the match count when the list is truncated and the
 * host knows it; [hasMore] says the list is truncated when it does not (a search that takes a limit and
 * returns no count: ask for one more than is shown). [total] wins; a count is never made up.
 */
data class SearchResultGroup(
    val kind: SearchResultKind,
    val label: String,
    val items: List<SearchResultItem> = emptyList(),
    val total: Int? = null,
    val hasMore: Boolean = false,
)
