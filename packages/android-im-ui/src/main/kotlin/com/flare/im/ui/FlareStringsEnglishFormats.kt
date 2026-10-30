package com.flare.im.ui

import java.text.DateFormatSymbols
import java.util.Locale

/**
 * The English copy of the [FlareStrings] fields that are functions of a count, a name or a kind — the part of
 * [flareStringsEnglish] that `strings/en.json` cannot hold, because a template alone cannot pick a plural form, a month
 * name or an omitted name. [flareStringsEnglish] applies it after the generated fields. The wording is checked against
 * `strings/en-formats.json`, the table the native kits share; a count takes the English `one` form at 1
 * ([flarePlural], spec/plural-vectors.json).
 */
internal fun FlareStringsBuilder.englishFormats() {
    readTab = { count -> "Read ($count)" }
    unreadTab = { count -> "Unread ($count)" }
    viewAll = { count -> "View all $count" }
    typingOne = { name -> "$name is typing…" }
    typingMany = { count -> english(count, "{count} person typing…", "{count} people typing…") }
    newMessages = { count -> if (count > 0) english(count, "{count} new message", "{count} new messages") else "New messages" }
    joinedCount = { count, status -> "$count joined · $status" }
    selfSuffix = { name -> "$name (me)" }
    selectedCount = { count -> "$count selected" }
    translatedBy = { provider -> "Translated by $provider" }
    pollOptionHint = { index -> "Option $index" }
    yearMonth = { year, month -> "${ENGLISH_MONTHS.getOrElse(month - 1) { month.toString() }} $year" }
    confirmCount = { count -> "Confirm ($count)" }
    memberCount = { count -> english(count, "{count} member", "{count} members") }
    wordCharCount = { words, chars ->
        "${english(words, "{count} word", "{count} words")} · ${english(chars, "{count} character", "{count} characters")}"
    }
    imagePreviewPosition = { index, count -> "$index of $count" }
    voiceDuration = { seconds -> english(seconds, "{count} second", "{count} seconds") }
    permissionNoun = {
        when (it) {
            FlarePermissionKind.Microphone -> "microphone"
            FlarePermissionKind.Camera -> "camera"
            FlarePermissionKind.Notifications -> "notifications"
            FlarePermissionKind.Storage -> "storage"
            FlarePermissionKind.Photos -> "photos"
            FlarePermissionKind.Contacts -> "contacts"
            FlarePermissionKind.Location -> "location"
            FlarePermissionKind.Screen -> "screen recording"
        }
    }
    permissionVerb = {
        when (it) {
            FlarePermissionKind.Microphone -> "use the microphone"
            FlarePermissionKind.Camera -> "use the camera"
            FlarePermissionKind.Notifications -> "send notifications"
            FlarePermissionKind.Storage -> "access storage"
            FlarePermissionKind.Photos -> "access your photos"
            FlarePermissionKind.Contacts -> "access your contacts"
            FlarePermissionKind.Location -> "use your location"
            FlarePermissionKind.Screen -> "record the screen"
        }
    }
    permissionTitle = { noun -> "Allow $noun access" }
    permissionUndeterminedBody = { feature, verb -> "$feature needs to $verb. Allow it to continue." }
    permissionDeniedBody = { feature, verb -> "Permission to $verb was denied, so $feature can't be used. Turn it on in system settings." }
    permissionRestrictedBody = { feature, verb -> "Permission to $verb is restricted by this device or your organization, so $feature isn't available." }
    permissionUnavailableBody = { feature, verb -> "This device can't $verb here, so $feature isn't available." }
    permissionStateLabel = {
        when (it) {
            FlarePermissionState.Undetermined -> "Not granted"
            FlarePermissionState.Denied -> "Denied"
            FlarePermissionState.Restricted -> "Restricted"
            FlarePermissionState.Unavailable -> "Unavailable"
        }
    }
    messageImageGroupLabel = { count -> english(count, "{count} image", "{count} images") }
    messageImageGroupItem = { index, count -> "Image $index of $count" }
    messageImageGroupItemMore = { index, count, more -> "Image $index of $count, $more more not shown" }
    messageRecalledGroupOther = { name -> "$name recalled a message" }
    messageQuoteLabel = { name, summary -> if (name.isEmpty()) "Quoted: $summary" else "Quoted $name: $summary" }
    jumpedToMessage = { name, summary -> "Jumped to $name's message: $summary" }
    previewImageNamed = { label -> "[Image] $label" }
    previewFileNamed = { name -> "[File] $name" }
    previewLocationNamed = { label -> "[Location] $label" }
    previewCardNamed = { label -> "[Contact] $label" }
    previewForwardCount = { count -> english(count, "[Forward] {count} message", "[Forward] {count} messages") }
    previewImageGroupCount = { count -> "[Album] $count" }
    conversationHeaderIdentityLabel = { title, action -> "$title, $action" }
    momentAudienceSheetSelected = { count -> english(count, "{count} person selected", "{count} people selected") }
    announcementReadBarReadCount = { read, total -> "$read/$total read" }
    connectionDisconnectedReason = { reason -> "Disconnected: $reason" }
    groupDetailMembersTitle = { count -> "Members ($count)" }
    conversationHeaderMemberCount = { count -> english(count, "{count} member", "{count} members") }
    profilePanelEditProfile = { name -> "$name, edit profile" }
    momentReplyToComment = { name, text -> "Reply to $name: $text" }
}

private val ENGLISH_MONTHS: Array<String> = DateFormatSymbols(Locale.ENGLISH).months

private fun english(count: Int, one: String, other: String): String = flarePlural(count.toLong(), one, other, Locale.ENGLISH)
