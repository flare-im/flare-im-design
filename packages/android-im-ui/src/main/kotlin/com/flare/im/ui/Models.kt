package com.flare.im.ui

/** Conversation kind — spec union `'single' | 'group' | 'ai'`. */
/**
 * What a conversation is, in one vocabulary for every kit (FR-056): `Channel` and `System` join the
 * three that were always here, so a header never needs words of its own.
 */
enum class FlareConversationKind { Single, Group, Channel, Ai, System }

/** Tone for a small inline row tag (group / bot / official markers). */
enum class FlareTagTone { Info, Warning, Neutral }

/**
 * A small inline label rendered next to a conversation title (e.g. "Group",
 * "Bot", "Official"). Product decides the text/tone; the kit renders it.
 */
data class ConversationRowTag(
    val text: String,
    val tone: FlareTagTone = FlareTagTone.Neutral,
)

/**
 * Neutral, presentational data for one inbox row — the spec's `ConversationRow`
 * data type. Product-specific formatting is resolved upstream into [preview].
 */
data class ConversationRowData(
    val id: String,
    val title: String,
    val avatarUrl: String? = null,
    val preview: String = "",
    val timestampLabel: String = "",
    val unreadCount: Int = 0,
    val pinned: Boolean = false,
    val muted: Boolean = false,
    val mentioned: Boolean = false,
    val draftPreview: String? = null,
    val presence: FlarePresence? = null,
    /** Inline title tags (group / role). Empty by default. */
    val tags: List<ConversationRowTag> = emptyList(),
    val typing: Boolean = false,
    val failed: Boolean = false,
) {
    val hasUnread: Boolean get() = unreadCount > 0
    val hasDraft: Boolean get() = !draftPreview.isNullOrBlank()
    val previewKind: String get() = when {
        failed -> "failed"
        hasDraft -> "draft"
        typing -> "typing"
        mentioned -> "mention"
        else -> "normal"
    }
    /** Title weight tier: strong only when unread and not quiet (muted without a mention). */
    val titleEmphasis: String get() = if (hasUnread && !(muted && !mentioned)) "strong" else "quiet"
    val unreadLabel: String get() = if (unreadCount > 999) "999+" else unreadCount.coerceAtLeast(0).toString()
}

/** Neutral conversation summary for the details panel (spec `Conversation`). */
data class FlareConversationSummary(
    val id: String,
    val title: String,
    val avatarUrl: String? = null,
    val kind: FlareConversationKind = FlareConversationKind.Single,
    val memberCount: Int? = null,
    val muted: Boolean = false,
    val pinned: Boolean = false,
    val archived: Boolean = false,
)

/** A selectable contact/directory entry for [StartConversationDialog]. */
data class FlareContactOption(
    val id: String,
    val name: String,
    val avatarUrl: String? = null,
    val subtitle: String? = null,
)

/** One pinned message shown in [PinnedMessageBar]. */
data class FlarePinnedMessage(
    val id: String,
    val summary: String,
    val senderName: String? = null,
)

/**
 * 谁能看到这条动态（FR-100）。套件只认名字，宿主把自己的编号映射一次；
 * `spec/moments-privacy.json` 记着参考 app 原来的编号。
 */
enum class FlareMomentVisibility { Friends, Public, Private }

/** 在可见人群之上做加减：谁都不单独指定 / 只给这些人 / 除了这些人。 */
enum class FlareMomentAudienceMode { Everyone, Include, Exclude }

/** 陌生人能往回看多久的动态。 */
enum class FlareMomentHistoryRange { All, ThreeDays, OneMonth, SixMonths }

/** 私密动态没有名单可言：没人看得到，加减谁都不改变结果。 */
fun flareMomentAudienceApplies(visibility: FlareMomentVisibility): Boolean =
    visibility != FlareMomentVisibility.Private

/**
 * 宿主自己的操作（举报、分享名片、后台工具），画在详情页里套件自带的按钮旁边（FR-046）。
 * [danger] 用危险色；套件只把 [id] 报回去，别的什么都不知道。
 */
data class FlareDetailExtraAction(val id: String, val label: String, val danger: Boolean = false)
