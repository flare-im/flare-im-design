package com.flare.im.ui

import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.Forward
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.Reply
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.Cancel
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Block
import androidx.compose.material.icons.outlined.Campaign
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.Devices
import androidx.compose.material.icons.outlined.EmojiEmotions
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.Label
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Forum
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.NotificationsOff
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.PersonAddAlt
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.QrCode
import androidx.compose.material.icons.outlined.PushPin
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Cross-platform icon-library composable. Maps a fixed set of 60 semantic
 * names to the closest Material [ImageVector]s so every Flare platform can
 * share one naming contract.
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
    "heart-filled" to Icons.Filled.Favorite,
    "comment" to Icons.Outlined.ChatBubbleOutline,
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
    "bookmark" to Icons.Outlined.BookmarkBorder,
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
    "error" to Icons.Outlined.Cancel,
    "calendar" to Icons.Outlined.CalendarToday,
    "clock" to Icons.Outlined.Schedule,
    "eye" to Icons.Outlined.Visibility,
    "eye-off" to Icons.Outlined.VisibilityOff,
    "lock" to Icons.Outlined.Lock,
    "qr" to Icons.Outlined.QrCode,
    "chats" to Icons.Outlined.Forum,
    "moments" to Icons.Outlined.Explore,
    "block" to Icons.Outlined.Block,
    "tag" to Icons.Outlined.Label,
    "announcement" to Icons.Outlined.Campaign,
    "theme" to Icons.Outlined.DarkMode,
    "language" to Icons.Outlined.Language,
    "devices" to Icons.Outlined.Devices,
    "logout" to Icons.AutoMirrored.Outlined.Logout,
    "pin" to Icons.Outlined.PushPin,
)

/** The 60 semantic icon names, in canonical order. */
val flareIconNames: List<String> = listOf(
    "search", "send", "more", "back", "close", "check", "add", "remove",
    "edit", "delete", "heart", "heart-filled", "comment", "share", "camera",
    "image", "location", "mic", "phone", "video", "settings", "person",
    "people", "person-add", "star", "bookmark", "download", "link", "emoji",
    "file", "folder", "notification", "mute", "copy", "forward", "reply",
    "refresh", "chevron-down", "chevron-right", "arrow-down", "warning",
    "info", "success", "error", "calendar", "clock", "eye", "eye-off",
    "lock", "qr", "chats", "moments", "block", "tag", "announcement",
    "theme", "language", "devices", "logout",
    "pin",
)

/** Resolve a semantic icon [name] to a Material [ImageVector]; unknown → HelpOutline. */
fun flareIconVector(name: String): ImageVector =
    flareIconMap[name] ?: Icons.AutoMirrored.Outlined.HelpOutline

/** Render a Flare semantic icon by [name]. */
@Composable
fun FlareIcon(name: String, size: Dp = 20.dp, tint: Color? = null) {
    Icon(
        imageVector = flareIconVector(name),
        contentDescription = name,
        tint = tint ?: flareColors().textSecondary,
        modifier = Modifier.size(size),
    )
}
