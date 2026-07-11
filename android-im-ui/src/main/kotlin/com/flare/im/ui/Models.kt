package com.flare.im.ui

/** Conversation kind — spec union `'single' | 'group' | 'ai'`. */
enum class FlareConversationKind { Single, Group, Ai }

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
) {
    val hasUnread: Boolean get() = unreadCount > 0
    val hasDraft: Boolean get() = !draftPreview.isNullOrEmpty()
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
