package com.flare.im.ui

/**
 * What this client tells a conversation about its own typing.
 *
 * The rule is shared with the Vue, Flutter and SwiftUI kits and tested against the `signal` half of
 * `spec/typing-vectors.json`. It lives here rather than in each app because all five were writing it, and
 * writing it differently: the pause that ends typing was 3000, 2800, 1500, 1500 and — on iOS — never, two
 * apps re-reported `true` on every keystroke, and the two that deduplicated the report never refreshed it,
 * so a message that took longer than the peer's belief to write stopped showing as typing while it was
 * still being typed.
 *
 * The engine is a state machine with the clock passed in, not read: the same script must produce the same
 * reports on four platforms, and a rule that reads the wall clock cannot be tested at all.
 */

/** A pause this long after the last edit ends typing. */
const val FLARE_TYPING_IDLE_STOP_MS = 4000

/** `typing = true` is reported at most this often while the user keeps typing. */
const val FLARE_TYPING_REFRESH_MS = 2500

/** How long a peer stays "typing" on this belief without a fresh signal (the receiving half of the rule). */
const val FLARE_TYPING_PEER_TTL_MS = 6000

/**
 * One report this client owes a conversation. [atMs] is the instant the report is for: usually the `nowMs`
 * handed in, but an idle stop is timestamped at its deadline, so a host whose timer fired late still reports
 * the moment typing actually ended — and the shared table can assert *when*, not only *what*.
 */
data class FlareTypingReport(val conversationId: String, val typing: Boolean, val atMs: Long)

/**
 * One conversation types at a time: the composer is one control, so an edit somewhere else ends the
 * previous conversation before it starts the new one. Every method answers with the reports to send, in
 * order — the caller does the sending, and a send that fails is not this rule's business.
 */
class FlareTypingSignal {
    private var activeId = ""
    // Times are epoch milliseconds, which do not fit in an Int: a host that passes `System.currentTimeMillis()`
    // into a 32-bit field gets a wrapped, negative "now" and a rule that never stops typing.
    private var lastTrueAtMs = 0L
    private var idleDeadlineMs = 0L

    /** The conversation currently reported as typing, or "" when none is. */
    val typingConversationId: String get() = activeId

    /** When the idle stop is due, or null when nothing is typing. Hosts arm a timer on it. */
    val idleDeadline: Long? get() = if (activeId.isEmpty()) null else idleDeadlineMs

    /** The composer's text changed. Text that trims to nothing is not typing. */
    fun edit(conversationId: String, text: String, nowMs: Long): List<FlareTypingReport> {
        val out = tick(nowMs).toMutableList()
        if (text.isBlank() || conversationId.isEmpty()) {
            out += stop(nowMs)
            return out
        }
        if (activeId != conversationId) {
            out += stop(nowMs)
            activeId = conversationId
            lastTrueAtMs = nowMs
            out += FlareTypingReport(conversationId, true, nowMs)
        } else if (nowMs - lastTrueAtMs >= FLARE_TYPING_REFRESH_MS) {
            lastTrueAtMs = nowMs
            out += FlareTypingReport(conversationId, true, nowMs)
        }
        idleDeadlineMs = nowMs + FLARE_TYPING_IDLE_STOP_MS
        return out
    }

    /** The message went out. It says more than the signal does, so typing ends with it. */
    fun send(conversationId: String, nowMs: Long): List<FlareTypingReport> = tick(nowMs) + stop(nowMs)

    /** The reader left the conversation, the screen or the app. */
    fun close(nowMs: Long): List<FlareTypingReport> = tick(nowMs) + stop(nowMs)

    /** Time passed. Fires the idle stop at its deadline, not at [nowMs], so a late tick still reports on time. */
    fun tick(nowMs: Long): List<FlareTypingReport> {
        if (activeId.isEmpty() || nowMs < idleDeadlineMs) return emptyList()
        return stop(idleDeadlineMs)
    }

    private fun stop(atMs: Long): List<FlareTypingReport> {
        if (activeId.isEmpty()) return emptyList()
        val conversationId = activeId
        activeId = ""
        idleDeadlineMs = 0
        return listOf(FlareTypingReport(conversationId, false, atMs))
    }
}

/**
 * What this client believes about its peers — the receiving half of the same rule.
 *
 * Facts in (someone started, someone stopped, the server listed everyone typing, a message arrived from a
 * typer), the people typing in a conversation out, in the order they started. Nothing here knows a wire
 * shape: the app parses its own events and calls these, which is the boundary the kit is not allowed to
 * cross. A belief expires [FLARE_TYPING_PEER_TTL_MS] after the signal that made it, so a client that dies
 * mid-sentence does not leave a peer typing forever.
 *
 * Two of five apps had this, with two different expiries and two different sets of facts — one of them only
 * ever heard "someone started", so a server listing of who is typing did nothing — and three apps had no
 * idea a peer could be typing at all. Tested against the `roster` half of `spec/typing-vectors.json`.
 *
 * [selfId] never appears among the typers: this client's own signal is not news to itself.
 */
class FlareTypingRoster(private val selfId: String = "") {
    /** conversationId → (userId → the instant this belief expires), in the order they started. */
    private val state = LinkedHashMap<String, LinkedHashMap<String, Long>>()

    /** Someone began typing in a conversation. */
    fun started(conversationId: String, userId: String, nowMs: Long) {
        if (conversationId.isEmpty() || userId.isEmpty() || userId == selfId) return
        state.getOrPut(conversationId) { LinkedHashMap() }[userId] = nowMs + FLARE_TYPING_PEER_TTL_MS
    }

    /** Someone stopped — an explicit signal, believed at once. */
    fun stopped(conversationId: String, userId: String) {
        val users = state[conversationId] ?: return
        if (users.remove(userId) == null) return
        if (users.isEmpty()) state.remove(conversationId)
    }

    /** The server listed everyone typing in a conversation: that listing is the whole truth for it. */
    fun replaced(conversationId: String, userIds: List<String>, nowMs: Long) {
        if (conversationId.isEmpty()) return
        val kept = userIds.filter { it.isNotEmpty() && it != selfId }
        if (kept.isEmpty()) {
            state.remove(conversationId)
            return
        }
        state[conversationId] = LinkedHashMap<String, Long>().apply {
            for (id in kept) put(id, nowMs + FLARE_TYPING_PEER_TTL_MS)
        }
    }

    /** A message arrived. It says more than the signal did, so its sender is no longer typing. */
    fun sent(conversationId: String, senderId: String) = stopped(conversationId, senderId)

    /** Drops every belief whose time has run out. Hosts call it on a timer armed from [nextExpiry]. */
    fun prune(nowMs: Long) {
        for (conversationId in state.keys.toList()) {
            val users = state[conversationId] ?: continue
            users.entries.removeAll { it.value <= nowMs }
            if (users.isEmpty()) state.remove(conversationId)
        }
    }

    /** Who is typing in a conversation, in the order they started. */
    fun typers(conversationId: String): List<String> = state[conversationId]?.keys?.toList() ?: emptyList()

    /** When the soonest belief runs out, or null when nothing is typing. */
    val nextExpiry: Long? get() = state.values.flatMap { it.values }.minOrNull()

    /** Forgets everything — signing out, or switching account. */
    fun clear() = state.clear()
}

/**
 * The names a typing indicator shows. A typer the roster has but the directory has not introduced yet
 * falls back to [fallback] — the conversation's own name in a 1:1, a generic "member" word in a group —
 * because a raw id is never shown to a reader. An empty fallback drops the unnamed typer instead.
 */
fun flareTypingNames(
    userIds: List<String>,
    nameOf: (String) -> String,
    fallback: String,
): List<String> = userIds.map { nameOf(it).ifEmpty { fallback } }.filter { it.isNotEmpty() }
