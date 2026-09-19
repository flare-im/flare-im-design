package com.flare.im.ui

/**
 * When what someone typed and did not send is written down, and what it is written as.
 *
 * The rule is shared with the Vue, Flutter and SwiftUI kits and tested against `spec/draft-vectors.json`.
 * It lives here rather than in each app because all five were writing it, and writing it to five different
 * places with five different lifetimes: the web app saved to the core after 1200 ms, so a draft roamed to
 * another device; the Tauri app to `localStorage` after 450 ms, so it survived a restart on that machine
 * and nowhere else; the Android app to a map in memory, so it survived switching conversations and nothing
 * else; the Flutter and iOS apps did not save at all — leave the chat and what you typed was gone.
 * "Draft" meant four different things.
 */

/** A pause this long after the last edit writes the draft down. */
const val FLARE_DRAFT_SAVE_DELAY_MS = 1200

/**
 * One write this client owes the core. [text] of "" clears the conversation's draft; [atMs] is the instant
 * the write is for — the deadline when a pause triggered it, else the moment it happened.
 */
data class FlareDraftSave(val conversationId: String, val text: String, val atMs: Long)

/**
 * The text a send that reached nothing leaves behind: above whatever was typed while it was in flight, and
 * never twice. A failed send of nothing changes nothing.
 */
fun flareRestoredDraft(current: String, failed: String): String {
    val back = failed.trim()
    if (back.isEmpty()) return current
    if (current.isBlank()) return failed
    if (current.contains(back)) return current
    return "$failed\n$current"
}

private fun storedText(text: String): String = if (text.isBlank()) "" else text

class FlareDraftAutosave {
    private val saved = HashMap<String, String>()
    private var pendingId: String? = null
    private var pendingText = ""

    // Epoch milliseconds do not fit in an Int; see FlareTypingSignal for what that costs.
    private var deadlineMs = 0L

    /** What the core already holds for a conversation, so an unchanged draft is never written back. */
    fun seed(conversationId: String, text: String) {
        if (conversationId.isEmpty()) return
        saved[conversationId] = storedText(text)
    }

    /** The draft this client believes the core holds. */
    fun storedTextFor(conversationId: String): String = saved[conversationId] ?: ""

    /** When the pending write is due, or null when none is. Hosts arm a timer on it. */
    val pendingDeadline: Long? get() = if (pendingId == null) null else deadlineMs

    /** The composer's text changed. Editing a sent message is not this: the host does not report it here. */
    fun edit(conversationId: String, text: String, nowMs: Long): List<FlareDraftSave> {
        val out = tick(nowMs).toMutableList()
        if (conversationId.isEmpty()) return out
        // Moving to another conversation writes the one being left before starting the new one.
        if (pendingId != null && pendingId != conversationId) out += flush(nowMs)
        pendingId = conversationId
        pendingText = storedText(text)
        deadlineMs = nowMs + FLARE_DRAFT_SAVE_DELAY_MS
        return out
    }

    /** The message went out: the draft it came from is gone, and any pending write with it. */
    fun send(conversationId: String, nowMs: Long): List<FlareDraftSave> {
        val out = tick(nowMs).toMutableList()
        if (pendingId == conversationId) pendingId = null
        out += write(conversationId, "", nowMs)
        return out
    }

    /** The reader left the conversation, the screen or the app: write the pending draft now. */
    fun leave(nowMs: Long): List<FlareDraftSave> = tick(nowMs) + flush(nowMs)

    /**
     * A send that reached nothing. Its text goes back immediately, never on the timer: a draft lost to a
     * pending write is the one case where losing it is unforgivable.
     */
    fun restore(conversationId: String, failedText: String, nowMs: Long): List<FlareDraftSave> {
        val out = tick(nowMs).toMutableList()
        if (conversationId.isEmpty()) return out
        if (pendingId == conversationId) pendingId = null
        out += write(conversationId, flareRestoredDraft(storedTextFor(conversationId), failedText), nowMs)
        return out
    }

    /** Time passed. Fires the pending write at its deadline, not at [nowMs]. */
    fun tick(nowMs: Long): List<FlareDraftSave> {
        if (pendingId == null || nowMs < deadlineMs) return emptyList()
        return flush(deadlineMs)
    }

    private fun flush(atMs: Long): List<FlareDraftSave> {
        val id = pendingId ?: return emptyList()
        val text = pendingText
        pendingId = null
        pendingText = ""
        deadlineMs = 0L
        return write(id, text, atMs)
    }

    private fun write(conversationId: String, text: String, atMs: Long): List<FlareDraftSave> {
        if (conversationId.isEmpty()) return emptyList()
        val next = storedText(text)
        if (storedTextFor(conversationId) == next) return emptyList()
        saved[conversationId] = next
        return listOf(FlareDraftSave(conversationId, next, atMs))
    }
}
