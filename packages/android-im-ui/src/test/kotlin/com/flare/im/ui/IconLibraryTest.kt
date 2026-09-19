package com.flare.im.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.RotateRight
import androidx.compose.material.icons.automirrored.outlined.ScreenShare
import androidx.compose.material.icons.automirrored.outlined.Undo
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.outlined.AddReaction
import androidx.compose.material.icons.outlined.AdminPanelSettings
import androidx.compose.material.icons.outlined.AlternateEmail
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.BugReport
import androidx.compose.material.icons.outlined.AttachFile
import androidx.compose.material.icons.outlined.CallEnd
import androidx.compose.material.icons.outlined.Cameraswitch
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.ChevronLeft
import androidx.compose.material.icons.outlined.CloseFullscreen
import androidx.compose.material.icons.outlined.CommentsDisabled
import androidx.compose.material.icons.outlined.ContactPage
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.FormatQuote
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.MarkChatUnread
import androidx.compose.material.icons.outlined.Merge
import androidx.compose.material.icons.outlined.MicOff
import androidx.compose.material.icons.outlined.MoveToInbox
import androidx.compose.material.icons.outlined.OpenInFull
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.PersonRemove
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Report
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.Tag
import androidx.compose.material.icons.outlined.TextFormat
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material.icons.outlined.Unarchive
import androidx.compose.material.icons.outlined.VideocamOff
import androidx.compose.material.icons.outlined.ZoomIn
import androidx.compose.material.icons.outlined.ZoomOut
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The icon registry contract: the same 105 kebab-case names, in the same order, as the other three kits. */
class IconLibraryTest {
    private val canonical = listOf(
        "search", "send", "more", "back", "close", "check", "add", "remove", "edit", "delete",
        "heart", "comment", "chats", "moments", "share", "camera", "image", "location", "mic", "phone",
        "video", "settings", "person", "people", "person-add", "star", "download", "link", "emoji", "file",
        "folder", "notification", "mute", "copy", "forward", "reply", "refresh", "chevron-down", "chevron-right", "arrow-down",
        "warning", "info", "success", "error", "calendar", "clock", "eye", "eye-off", "lock", "qr",
        "block", "tag", "announcement", "theme", "language", "devices", "logout", "pin", "poll",
        "recall", "unpin", "merge-forward", "multi-select", "quote", "reaction", "translate", "mention", "read", "mark",
        "rich-text", "attachment", "mark-unread", "archive", "unarchive", "clear-history", "mic-off", "camera-off", "speaker", "speaker-off",
        "end-call", "switch-camera", "screen-share", "play", "pause", "expand", "collapse", "zoom-in", "zoom-out", "rotate",
        "group", "admin", "remove-member", "transfer-owner", "silence", "report", "chevron-up", "chevron-left", "keyboard", "mini-app",
        "pin-self", "diagnostics", "card", "id", "join-request", "storage",
    )

    @Test fun kebabCaseNamesInCanonicalOrder() {
        assertEquals(105, flareIconNames.size)
        assertEquals(canonical, flareIconNames)
        assertEquals(flareIconNames.size, flareIconNames.toSet().size, "names are unique")
        for (name in flareIconNames) assertTrue(Regex("^[a-z]+(-[a-z]+)*$").matches(name), "$name is kebab-case")
    }

    @Test fun everyNameResolvesAndNothingElseDoes() {
        for (name in flareIconNames) assertNotNull(flareIconVectorOrNull(name), "$name has a glyph")
        assertNull(flareIconVectorOrNull("heart-filled"), "heart-filled was removed")
        assertNull(flareIconVectorOrNull("bookmark"), "bookmark was removed")
        assertNull(flareIconVectorOrNull("videoCall"), "header aliases are not registry names")
        assertEquals(Icons.AutoMirrored.Outlined.HelpOutline, flareIconVector("no-such-icon"))
    }

    @Test fun errorIsTheExclamationCircleNotCancel() {
        assertEquals(Icons.Outlined.ErrorOutline, flareIconVector("error"))
    }

    @Test fun addedNamesDrawTheirOwnConcept() {
        val expected = mapOf(
            "recall" to Icons.AutoMirrored.Outlined.Undo,
            "unpin" to Icons.Filled.PushPin,
            "merge-forward" to Icons.Outlined.Merge,
            "multi-select" to Icons.Outlined.Checklist,
            "quote" to Icons.Outlined.FormatQuote,
            "reaction" to Icons.Outlined.AddReaction,
            "translate" to Icons.Outlined.Translate,
            "mention" to Icons.Outlined.AlternateEmail,
            "read" to Icons.Outlined.DoneAll,
            "mark" to Icons.Outlined.Flag,
            "rich-text" to Icons.Outlined.TextFormat,
            "attachment" to Icons.Outlined.AttachFile,
            "mark-unread" to Icons.Outlined.MarkChatUnread,
            "archive" to Icons.Outlined.Archive,
            "unarchive" to Icons.Outlined.Unarchive,
            "clear-history" to Icons.Outlined.DeleteSweep,
            "mic-off" to Icons.Outlined.MicOff,
            "camera-off" to Icons.Outlined.VideocamOff,
            "speaker" to Icons.AutoMirrored.Outlined.VolumeUp,
            "speaker-off" to Icons.AutoMirrored.Outlined.VolumeOff,
            "end-call" to Icons.Outlined.CallEnd,
            "switch-camera" to Icons.Outlined.Cameraswitch,
            "screen-share" to Icons.AutoMirrored.Outlined.ScreenShare,
            "play" to Icons.Outlined.PlayArrow,
            "pause" to Icons.Outlined.Pause,
            "expand" to Icons.Outlined.OpenInFull,
            "collapse" to Icons.Outlined.CloseFullscreen,
            "zoom-in" to Icons.Outlined.ZoomIn,
            "zoom-out" to Icons.Outlined.ZoomOut,
            "rotate" to Icons.AutoMirrored.Outlined.RotateRight,
            "group" to Icons.Outlined.Groups,
            "admin" to Icons.Outlined.AdminPanelSettings,
            "remove-member" to Icons.Outlined.PersonRemove,
            "transfer-owner" to Icons.Outlined.Key,
            "silence" to Icons.Outlined.CommentsDisabled,
            "report" to Icons.Outlined.Report,
            "chevron-up" to Icons.Outlined.ExpandLess,
            "chevron-left" to Icons.Outlined.ChevronLeft,
            "keyboard" to Icons.Outlined.Keyboard,
            "mini-app" to Icons.Outlined.Apps,
        )
        assertEquals(40, expected.size)
        assertEquals(canonical.subList(59, 99), expected.keys.toList(), "the 40 names follow the 59 kept ones")
        for ((name, glyph) in expected) assertEquals(glyph, flareIconVector(name), name)
    }

    @Test fun conceptsDrawnUnderAnotherNameGotTheirOwn() {
        val expected = mapOf(
            "pin-self" to Icons.Outlined.BookmarkBorder,
            "diagnostics" to Icons.Outlined.BugReport,
            "card" to Icons.Outlined.ContactPage,
            "id" to Icons.Outlined.Tag,
            "join-request" to Icons.Outlined.MoveToInbox,
            "storage" to Icons.Outlined.Storage,
        )
        assertEquals(canonical.drop(99), expected.keys.toList(), "the 6 names follow the 99 before them")
        for ((name, glyph) in expected) assertEquals(glyph, flareIconVector(name), name)
    }

    @Test fun conceptsThatUsedToShareAGlyphNoLongerDo() {
        // Each pair was one glyph with two meanings before the registry named them apart.
        for ((a, b) in listOf(
            "pin" to "unpin", "reply" to "recall", "logout" to "remove-member", "star" to "transfer-owner",
            "notification" to "silence", "mute" to "silence", "delete" to "clear-history", "phone" to "end-call",
            "language" to "translate", "devices" to "screen-share", "emoji" to "reaction",
            // Each concept below was drawn under the first name, which means something else.
            "pin" to "pin-self", "person" to "card", "info" to "id", "tag" to "id", "person-add" to "join-request",
            "notification" to "join-request", "folder" to "storage", "info" to "diagnostics",
        )) assertTrue(flareIconVector(a) != flareIconVector(b), "$a and $b draw different glyphs")
    }
}
