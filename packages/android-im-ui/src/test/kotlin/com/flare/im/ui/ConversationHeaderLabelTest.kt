package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/** The header's default actions, member count and presence speak the strings table; host labels show as given. */
class ConversationHeaderLabelTest {
    private val s = FlareStrings()

    @Test fun defaultActionsShowTheStringsTableWordsAndHostLabelsShowAsGiven() {
        val direct = resolveConversationHeaderActions(ConversationIdentity("u1", "Ada"))
        assertEquals(
            listOf(s.conversationHeaderSearch, s.conversationHeaderAudioCall, s.conversationHeaderVideoCall, s.conversationHeaderShare, s.conversationHeaderDetails),
            direct.map { conversationHeaderActionLabel(it, ConversationHeaderKind.Direct, s) },
        )
        val group = resolveConversationHeaderActions(ConversationIdentity("g1", "Room", ConversationHeaderKind.Group))
        assertEquals(
            listOf(
                s.conversationHeaderSearch, s.conversationHeaderAudioCall, s.conversationHeaderVideoCall,
                s.conversationHeaderAddMember, s.conversationHeaderShare, s.conversationHeaderDetails,
            ),
            group.map { conversationHeaderActionLabel(it, ConversationHeaderKind.Group, s) },
        )
        assertEquals(
            listOf("搜索消息", "发起语音通话", "发起视频通话", "添加成员", "分享会话", "会话详情"),
            listOf(s.conversationHeaderSearch, s.conversationHeaderAudioCall, s.conversationHeaderVideoCall, s.conversationHeaderAddMember, s.conversationHeaderShare, s.conversationHeaderDetails),
        )
        // A channel reads the group defaults.
        assertEquals(s.conversationHeaderAddMember, conversationHeaderActionLabel(group[3], ConversationHeaderKind.Channel, s))

        // A host label, or a default id whose label the host changed, is never replaced.
        assertEquals("Find in chat", conversationHeaderActionLabel(ConversationHeaderAction("search", "Find in chat"), ConversationHeaderKind.Direct, s))
        assertEquals("置顶", conversationHeaderActionLabel(ConversationHeaderAction("pin", "置顶"), ConversationHeaderKind.Group, s))
        // Only the default of the conversation's own kind is translated.
        assertEquals("Share conversation", conversationHeaderActionLabel(ConversationHeaderAction("share", "Share conversation"), ConversationHeaderKind.Direct, s))
        assertEquals("Share contact", conversationHeaderActionLabel(ConversationHeaderAction("share", "Share contact"), ConversationHeaderKind.Group, s))
        // A host strings table decides the words.
        val english = FlareStrings { conversationHeaderSearch = "Search messages" }
        assertEquals("Search messages", conversationHeaderActionLabel(direct[0], ConversationHeaderKind.Direct, english))
    }

    @Test fun menuItemsCarryTheWordsTheHeaderShows() {
        val details = resolveConversationHeaderActions(ConversationIdentity("u1", "Ada")).last()
        assertEquals(s.conversationHeaderDetails, details.toActionItem(conversationHeaderActionLabel(details, ConversationHeaderKind.Direct, s)).label)
        // Without a shown label the item keeps the action's own.
        assertEquals("Conversation details", details.toActionItem().label)
    }

    @Test fun thePresenceSubtitleIsWordsFromTheStringsTable() {
        fun subtitle(identity: ConversationIdentity) = conversationHeaderSubtitle(identity, s)
        assertEquals("在线", subtitle(ConversationIdentity("u1", "Ada", presence = FlarePresence.Online)))
        assertEquals(s.presenceOffline, subtitle(ConversationIdentity("u1", "Ada", presence = FlarePresence.Offline)))
        assertEquals(s.presenceBusy, subtitle(ConversationIdentity("u1", "Ada", presence = FlarePresence.Busy)))
        assertEquals(s.presenceAway, subtitle(ConversationIdentity("u1", "Ada", presence = FlarePresence.Away)))
        assertEquals(listOf("离线", "忙碌", "离开"), listOf(s.presenceOffline, s.presenceBusy, s.presenceAway))
        // A group's member count comes before a presence; a direct conversation shows no member count (Vue).
        assertEquals("8 位成员", subtitle(ConversationIdentity("g1", "Room", ConversationHeaderKind.Group, presence = FlarePresence.Online, memberCount = 8)))
        assertEquals(s.conversationHeaderMemberCount(12), subtitle(ConversationIdentity("c1", "Channel", ConversationHeaderKind.Channel, memberCount = 12)))
        assertEquals(s.presenceOnline, subtitle(ConversationIdentity("u1", "Ada", presence = FlarePresence.Online, memberCount = 2)))
        // Typing wins, then a host subtitle; a blank subtitle does not count.
        assertEquals("Ada 正在输入", subtitle(ConversationIdentity("u1", "Ada", subtitle = " ", presence = FlarePresence.Online, typingText = "Ada 正在输入")))
        assertEquals("3 人", subtitle(ConversationIdentity("g1", "Room", ConversationHeaderKind.Group, subtitle = "3 人", memberCount = 3)))
        assertEquals("", subtitle(ConversationIdentity("u1", "Ada")))
        assertEquals("{count} members".replace("{count}", "8"), FlareStrings { conversationHeaderMemberCount = { "$it members" } }.conversationHeaderMemberCount(8))
    }
}
