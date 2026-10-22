package com.flare.im.ui

import java.time.ZoneOffset
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Grouping, row presentation and date pills (docs/design/message-surface-and-meta.md C4) against
 * spec/message-grouping-vectors.json: every case's rows — date pills by label tier, the unread divider with its count,
 * and each message's run position, avatar, name, gutter, side and tail.
 */
class MessageGroupingVectorsTest {
    private fun surface(name: String?) = FlareMessageSurface.fromWire(name) ?: error("unknown surface $name")

    @Test fun everyCaseFollowsTheTable() {
        val table = SpecTables.table("message-grouping-vectors.json")
        val gap = table.long("timeGapMs")!!
        assertEquals(300_000L, gap, "the kit groups within five minutes")
        val now = table.long("nowMs")!!
        val zone = ZoneOffset.ofTotalSeconds(table.int("utcOffsetMinutes")!! * 60)
        val cases = table.items("cases")
        assertTrue(cases.size >= 15, "the shared table lost cases: ${cases.size}")
        for (case in cases) {
            val name = case.str("name")!!
            val me = case.str("currentUserId")!!
            val group = case.str("conversationKind") == "group"
            val options = case.obj("options")
            val items = case.items("messages").map { m ->
                FlareMessageGroupingItem(m.str("id")!!, m.str("senderId")!!, m.long("atMs")!!, surface(m.str("surface")))
            }
            val rows = messageTimelineRowsOf(items, me, case.str("unreadFromId"), zone) { ms ->
                FlareTimeFormat.timelineDayKind(ms, now, zone).wire
            }
            val expected = case.items("rows")
            assertEquals(expected.size, rows.size, "$name: rows ${rows.map { it.key }}")
            for ((row, want) in rows.zip(expected)) {
                when (want.str("kind")) {
                    "date" -> assertEquals(want.str("label"), (row as MessageTimelineRow.Day).label, "$name date")
                    "unread" -> assertEquals(want.int("count"), (row as MessageTimelineRow.Unread).count, "$name unread")
                    "message" -> {
                        val message = row as MessageTimelineRow.Message
                        val id = want.str("id")!!
                        assertEquals(id, message.key, name)
                        assertEquals(want.str("position"), message.groupPosition.name.lowercase(), "$name $id position")
                        val p = messageRowPresentation(
                            senderId = items[message.index].senderId,
                            surface = message.surface,
                            position = message.groupPosition,
                            currentUserId = me,
                            groupConversation = group,
                            showIncomingAvatar = options?.bool("showIncomingAvatar") ?: true,
                            showSelfAvatar = options?.bool("showSelfAvatar") ?: false,
                            showGroupSenderName = options?.bool("showGroupSenderName") ?: true,
                        )
                        assertEquals(want.bool("showAvatar"), p.showAvatar, "$name $id avatar")
                        assertEquals(want.bool("showSenderName"), p.showSenderName, "$name $id name")
                        assertEquals(want.bool("reserveAvatarSpace"), p.reserveAvatarSpace, "$name $id gutter")
                        assertEquals(want.str("avatarPlacement"), p.avatarPlacement.name.lowercase(), "$name $id side")
                        assertEquals(want.bool("tail"), p.tail, "$name $id tail")
                    }
                    else -> error("$name: unknown row kind ${want.str("kind")}")
                }
            }
        }
    }

    @Test fun messageDataGroupsOnItsDerivedSurface() {
        fun msg(id: String, content: FlareMessageContent, at: Long, lifecycle: FlareMessageLifecycle? = null) =
            FlareMessageData(id = id, senderId = "u1", senderName = "Ann", content = content, sentAtMs = at, lifecycle = lifecycle)
        val base = 1_792_632_600_000L
        val messages = listOf(
            msg("a", FlareTextContent("hi"), base),
            msg("b", FlareGenericContent("custom", "Poll", subtype = "flare.plugin.message.v1"), base + 60_000),
            msg("c", FlareTextContent("deleted"), base + 120_000, FlareMessageLifecycle(mutation = FlareMessageMutationState.Deleted)),
            msg("d", FlareImageContent("u"), base + 180_000),
            msg("e", FlareTextContent("again"), base + 240_000),
        )
        assertEquals(
            listOf(MessageGroupPosition.Single, MessageGroupPosition.Single, MessageGroupPosition.Single, MessageGroupPosition.First, MessageGroupPosition.Last),
            messages.indices.map { messageGroupPosition(messages, it) },
            "a card and a deletion each end the run; a picture and a bubble share one",
        )
        val presentation = messageRowPresentation(messages[3], MessageGroupPosition.First, "me", groupConversation = true)
        assertEquals(false, presentation.tail, "bare media never draws a tail")
    }
}
