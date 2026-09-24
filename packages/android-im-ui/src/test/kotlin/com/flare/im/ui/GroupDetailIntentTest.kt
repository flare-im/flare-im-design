package com.flare.im.ui

import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Group member intents carry the state the user asked for, read from the model the labels come from. */
class GroupDetailIntentTest {
    private val model = FlareGroupDetailModel(
        groupId = "g1",
        name = "设计评审组",
        members = listOf(Contact("me", "Me"), Contact("ann", "Ann"), Contact("bob", "Bob")),
        ownerId = "me",
        adminIds = listOf("ann"),
        mutedIds = listOf("bob"),
        canManage = true,
    )

    @Test fun theRoleActionAsksForTheOppositeOfTheCurrentRole() {
        assertFalse(groupMemberAdminTarget(model, "ann"))
        assertTrue(groupMemberAdminTarget(model, "bob"))
    }

    @Test fun theMuteActionAsksForTheOppositeOfTheCurrentMute() {
        assertTrue(groupMemberMuteTarget(model, "ann"))
        assertFalse(groupMemberMuteTarget(model, "bob"))
    }

    @Test fun theJoinPolicyRowNamesEachPolicyAndSaysNotSetWhenUnknown() {
        val labels = FlareGroupDetailLabels()
        assertEquals(labels.joinOpen, groupJoinPolicyLabel(FlareGroupJoinPolicy.Open, labels))
        assertEquals(labels.joinApproval, groupJoinPolicyLabel(FlareGroupJoinPolicy.Approval, labels))
        assertEquals(labels.joinInvite, groupJoinPolicyLabel(FlareGroupJoinPolicy.Invite, labels))
        assertEquals(labels.notSet, groupJoinPolicyLabel(null, labels))
        // The model does not guess: a host that maps nothing leaves the policy unknown.
        assertNull(model.joinPolicy)
    }

    @Test fun discoverabilityDefaultsPrivateAndUsesTheSharedString() {
        assertFalse(model.discoverable)
        assertEquals(FlareStrings().groupDetailDiscoverable, flareGroupDetailLabels(FlareStrings()).discoverable)
    }

    @Test fun theGridPreviewsTwentyCellsWithTheAddTileWhenManaging() {
        val members = (1..500).map { Contact("u$it", "成员$it") }
        assertEquals(19, groupPreviewMembers(members, canManage = true).size)
        assertEquals(20, groupPreviewMembers(members, canManage = false).size)
        assertEquals(listOf("u1", "u2"), groupPreviewMembers(members.take(2), canManage = true).map { it.id })
    }

    @Test fun theMembersSheetSearchMatchesNamesIgnoringCase() {
        assertEquals(listOf("ann"), groupMembersMatching(model.members, " an ").map { it.id })
        assertEquals(model.members, groupMembersMatching(model.members, ""))
        assertEquals(emptyList(), groupMembersMatching(model.members, "陈"))
    }

    @Test fun hostBackedMemberSearchReplacesLocalFilteringOnlyWhenSupplied() {
        val remote = listOf(Contact("remote", "Remote Ann"))
        assertEquals(listOf("remote"), visibleGroupMembers(model.members, "ann", remote, remoteEnabled = true).map { it.id })
        assertEquals(
            listOf("ann"),
            visibleGroupMembers(model.members, "ann", null, remoteEnabled = true).map { it.id },
            "while a host-backed query is pending the sheet keeps the local fallback visible",
        )
        assertEquals(listOf("ann"), visibleGroupMembers(model.members, "ann", remote, remoteEnabled = false).map { it.id })
    }

    @Test fun eachEditorOpensOnTheCurrentValueWithItsLimits() {
        val labels = FlareGroupDetailLabels()
        val m = model.copy(announcement = "周五评审", myNickname = "主持人")
        fun options(kind: FlareGroupDetailEditKind) = groupDetailEditPrompt(kind, m, labels) {}
        with(options(FlareGroupDetailEditKind.Name)) {
            assertEquals(listOf<Any?>(labels.editName, "设计评审组", 30, false, false, labels.save, labels.cancel), listOf(title, value, maxLength, multiline, allowEmpty, confirmText, cancelText))
        }
        with(options(FlareGroupDetailEditKind.Announcement)) {
            assertEquals(listOf<Any?>(labels.editAnnouncement, "周五评审", 200, true, true), listOf(title, value, maxLength, multiline, allowEmpty))
        }
        with(options(FlareGroupDetailEditKind.Nickname)) {
            assertEquals(listOf<Any?>(labels.myNickname, "主持人", labels.nicknamePlaceholder, 20, false, true), listOf(title, value, placeholder, maxLength, multiline, allowEmpty))
        }
        assertEquals("", groupDetailEditPrompt(FlareGroupDetailEditKind.Nickname, model, labels) {}.value)
    }

    @Test fun aConfirmedEditGoesToSubmitEditWhenThereIsOneOtherwiseToItsCallback() = runBlocking {
        val calls = mutableListOf<String>()
        val onName: (String) -> Unit = { calls += "name:$it" }
        val onAnnouncement: (String) -> Unit = { calls += "announcement:$it" }
        val onNickname: (String) -> Unit = { calls += "nickname:$it" }
        groupDetailSaveEdit(FlareGroupDetailEditKind.Name, "新名字", { kind, value -> calls += "submit:$kind:$value" }, onName, onAnnouncement, onNickname)
        groupDetailSaveEdit(FlareGroupDetailEditKind.Name, "新名字", null, onName, onAnnouncement, onNickname)
        groupDetailSaveEdit(FlareGroupDetailEditKind.Announcement, "周五评审", null, onName, onAnnouncement, onNickname)
        groupDetailSaveEdit(FlareGroupDetailEditKind.Nickname, "", null, onName, onAnnouncement, onNickname)
        assertEquals(listOf("submit:Name:新名字", "name:新名字", "announcement:周五评审", "nickname:"), calls)
    }

    @Test fun aFailedSubmitKeepsTheEditorOpenWithItsErrorUntilARetrySucceeds() = runBlocking {
        val editor = FlareDialogState()
        val submitted = mutableListOf<String>()
        val submitEdit: suspend (FlareGroupDetailEditKind, String) -> Unit = { _, value ->
            submitted += value
            if (submitted.size == 1) error("群聊名称保存失败，请重试。")
        }
        val saved = async {
            editor.prompt(groupDetailEditPrompt(FlareGroupDetailEditKind.Name, model, FlareGroupDetailLabels()) { value ->
                groupDetailSaveEdit(FlareGroupDetailEditKind.Name, value, submitEdit, {}, {}, {})
            })
        }
        withTimeout(2_000) { while (editor.request == null) yield() }
        // An empty name is not saved.
        editor.accept("  ")
        assertEquals(false, editor.request?.busy)
        editor.accept(" 设计评审群 ")
        withTimeout(2_000) { while (editor.request?.error == null) yield() }
        assertEquals("群聊名称保存失败，请重试。", editor.request?.error)
        editor.accept("设计评审群")
        assertEquals("设计评审群", saved.await())
        assertEquals(listOf("设计评审群", "设计评审群"), submitted)
        assertNull(editor.request)
    }
}
