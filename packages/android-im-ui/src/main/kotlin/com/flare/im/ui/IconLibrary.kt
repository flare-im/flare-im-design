package com.flare.im.ui

import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.Forward
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.Label
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.Reply
import androidx.compose.material.icons.automirrored.outlined.RotateRight
import androidx.compose.material.icons.automirrored.outlined.ScreenShare
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.automirrored.outlined.Undo
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.AddReaction
import androidx.compose.material.icons.outlined.AdminPanelSettings
import androidx.compose.material.icons.outlined.AlternateEmail
import androidx.compose.material.icons.outlined.Apps
import androidx.compose.material.icons.outlined.Storage
import androidx.compose.material.icons.outlined.MoveToInbox
import androidx.compose.material.icons.outlined.Tag
import androidx.compose.material.icons.outlined.ContactPage
import androidx.compose.material.icons.outlined.BugReport
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Archive
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material.icons.outlined.AttachFile
import androidx.compose.material.icons.outlined.Block
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.CallEnd
import androidx.compose.material.icons.outlined.Cameraswitch
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.ChevronLeft
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.CloseFullscreen
import androidx.compose.material.icons.outlined.CommentsDisabled
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.EmojiEmotions
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.FormatQuote
import androidx.compose.material.icons.outlined.Forum
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.Keyboard
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.MarkChatUnread
import androidx.compose.material.icons.outlined.Merge
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MicOff
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.OpenInFull
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonAddAlt
import androidx.compose.material.icons.outlined.PersonRemove
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Poll
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.QrCode
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material.icons.outlined.Report
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.TextFormat
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material.icons.outlined.Unarchive
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.outlined.VideocamOff
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material.icons.outlined.ZoomIn
import androidx.compose.material.icons.outlined.ZoomOut
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Cross-platform icon-library composable. Maps a fixed set of 105 semantic
 * names to the closest Material [ImageVector]s so every Flare platform can
 * share one naming contract. Outlined where Material has an outlined glyph;
 * the auto-mirrored variant wherever Material ships one, so the glyph follows
 * the layout direction and no deprecated vector is referenced.
 */
private val flareIconMap: Map<String, ImageVector> = mapOf(
    "search" to Icons.Outlined.Search,
    "send" to Icons.AutoMirrored.Outlined.Send,
    "more" to Icons.Outlined.MoreHoriz,
    "back" to Icons.AutoMirrored.Outlined.ArrowBack,
    "close" to Icons.Outlined.Close,
    "check" to Icons.Outlined.Check,
    "add" to Icons.Outlined.Add,
    "remove" to Icons.Outlined.Remove,
    "edit" to Icons.Outlined.Edit,
    "delete" to Icons.Outlined.Delete,
    "heart" to Icons.Outlined.FavoriteBorder,
    "comment" to Icons.Outlined.ChatBubbleOutline,
    "chats" to Icons.Outlined.Forum,
    "moments" to Icons.Outlined.Explore,
    "share" to Icons.Outlined.Share,
    "camera" to Icons.Outlined.PhotoCamera,
    "image" to Icons.Outlined.Image,
    "location" to Icons.Outlined.LocationOn,
    "mic" to Icons.Outlined.Mic,
    "phone" to Icons.Outlined.Call,
    "video" to Icons.Outlined.Videocam,
    "settings" to Icons.Outlined.Settings,
    "person" to Icons.Outlined.Person,
    "people" to Icons.Outlined.People,
    "person-add" to Icons.Outlined.PersonAddAlt,
    "star" to Icons.Outlined.StarBorder,
    "download" to Icons.Outlined.Download,
    "link" to Icons.Outlined.Link,
    "emoji" to Icons.Outlined.EmojiEmotions,
    "file" to Icons.Outlined.Description,
    "folder" to Icons.Outlined.Folder,
    "notification" to Icons.Outlined.Notifications,
    "mute" to Icons.Outlined.NotificationsOff,
    "copy" to Icons.Outlined.ContentCopy,
    "forward" to Icons.AutoMirrored.Outlined.Forward,
    "reply" to Icons.AutoMirrored.Outlined.Reply,
    "refresh" to Icons.Outlined.Refresh,
    "chevron-down" to Icons.Outlined.ExpandMore,
    "chevron-right" to Icons.Outlined.ChevronRight,
    "arrow-down" to Icons.Outlined.ArrowDownward,
    "warning" to Icons.Outlined.WarningAmber,
    "info" to Icons.Outlined.Info,
    "success" to Icons.Outlined.CheckCircle,
    "error" to Icons.Outlined.ErrorOutline,
    "calendar" to Icons.Outlined.CalendarToday,
    "clock" to Icons.Outlined.Schedule,
    "eye" to Icons.Outlined.Visibility,
    "eye-off" to Icons.Outlined.VisibilityOff,
    "lock" to Icons.Outlined.Lock,
    "qr" to Icons.Outlined.QrCode,
    "block" to Icons.Outlined.Block,
    "tag" to Icons.AutoMirrored.Outlined.Label,
    "announcement" to Icons.Outlined.Campaign,
    "theme" to Icons.Outlined.DarkMode,
    "language" to Icons.Outlined.Language,
    "devices" to Icons.Outlined.Devices,
    "logout" to Icons.AutoMirrored.Outlined.Logout,
    "pin" to Icons.Outlined.PushPin,
    "poll" to Icons.Outlined.Poll,
    "recall" to Icons.AutoMirrored.Outlined.Undo,
    // Material has no slashed pin; the filled pin reads as "pinned — tap to release".
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
    // Round 9: concepts every kit drew under a name that meant something else.
    "pin-self" to Icons.Outlined.BookmarkBorder,
    "diagnostics" to Icons.Outlined.BugReport,
    "card" to Icons.Outlined.ContactPage,
    "id" to Icons.Outlined.Tag,
    "join-request" to Icons.Outlined.MoveToInbox,
    "storage" to Icons.Outlined.Storage,
)

/** The 105 semantic icon names, in canonical order (the order of the Vue registry). */
val flareIconNames: List<String> = listOf(
    "search", "send", "more", "back", "close", "check", "add", "remove",
    "edit", "delete", "heart", "comment", "chats", "moments", "share", "camera",
    "image", "location", "mic", "phone", "video", "settings", "person",
    "people", "person-add", "star", "download", "link", "emoji",
    "file", "folder", "notification", "mute", "copy", "forward", "reply",
    "refresh", "chevron-down", "chevron-right", "arrow-down", "warning",
    "info", "success", "error", "calendar", "clock", "eye", "eye-off",
    "lock", "qr", "block", "tag", "announcement",
    "theme", "language", "devices", "logout",
    "pin", "poll",
    "recall", "unpin", "merge-forward", "multi-select", "quote", "reaction",
    "translate", "mention", "read", "mark", "rich-text", "attachment",
    "mark-unread", "archive", "unarchive", "clear-history",
    "mic-off", "camera-off", "speaker", "speaker-off", "end-call",
    "switch-camera", "screen-share", "play", "pause", "expand", "collapse",
    "zoom-in", "zoom-out", "rotate",
    "group", "admin", "remove-member", "transfer-owner", "silence", "report",
    "chevron-up", "chevron-left", "keyboard", "mini-app",
    "pin-self", "diagnostics", "card", "id", "join-request", "storage",
)

/**
 * Resolve a semantic icon [name] to a Material [ImageVector]; a name the registry does not have draws the
 * fallback glyph (HelpOutline) — visible, never blank, never the word itself — and is reported once in the
 * log so the typo is findable. A component never crashes over an icon name.
 */
fun flareIconVector(name: String): ImageVector =
    flareIconMap[name] ?: run { warnUnknownIconName(name); Icons.AutoMirrored.Outlined.HelpOutline }

/** Names already reported: one line per typo, not one per frame. */
private val reportedUnknownIconNames = java.util.Collections.synchronizedSet(HashSet<String>())

private fun warnUnknownIconName(name: String) {
    if (!reportedUnknownIconNames.add(name)) return
    // On a JVM without the Android framework (unit tests) there is nothing to log to, and a missing
    // logger must not fail a render.
    runCatching {
        android.util.Log.w("FlareIcon", "unknown icon name \"$name\": drawing the fallback glyph (see docs/ICON-LIBRARY.md for the $ICON_NAME_COUNT names)")
    }
}

private const val ICON_NAME_COUNT = 105

/** The glyph for a semantic icon [name], or null when the library does not know the name. */
internal fun flareIconVectorOrNull(name: String): ImageVector? = flareIconMap[name]

/** Render a Flare semantic icon by [name]. */
@Composable
fun FlareIcon(name: String, size: Dp = 20.dp, tint: Color? = null, contentDescription: String? = null) {
    // Decorative by default: an icon inside an already-described control must not
    // announce its own id ("close", "devices") on top of that description. Pass
    // [contentDescription] only when the icon itself is the content.
    Icon(
        imageVector = flareIconVector(name),
        contentDescription = contentDescription,
        tint = tint ?: flareColors().textSecondary,
        modifier = Modifier.size(size),
    )
}
