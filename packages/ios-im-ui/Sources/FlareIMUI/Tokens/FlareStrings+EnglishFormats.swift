import Foundation

extension FlareStrings {
    /// The English copy of the fields that are functions of a count, a name or a kind — the part of ``english`` that
    /// `strings/en.json` cannot hold, because a template alone cannot pick a plural form, a month name or an omitted
    /// name. ``english`` applies it after the generated fields. The wording is checked against
    /// `strings/en-formats.json`, the table the native kits share; a count takes the English `one` form at 1
    /// (``flarePlural(_:one:other:locale:)``, spec/plural-vectors.json).
    func englishFormats() -> FlareStrings {
        var s = self
        s.readTab = { "Read (\($0))" }
        s.unreadTab = { "Unread (\($0))" }
        s.viewAll = { "View all \($0)" }
        s.typingOne = { "\($0) is typing…" }
        s.typingMany = { englishCount($0, "{count} person typing…", "{count} people typing…") }
        s.newMessages = { $0 > 0 ? englishCount($0, "{count} new message", "{count} new messages") : "New messages" }
        s.joinedCount = { "\($0) joined · \($1)" }
        s.selfSuffix = { "\($0) (me)" }
        s.selectedCount = { "\($0) selected" }
        s.translatedBy = { "Translated by \($0)" }
        s.pollOptionHint = { "Option \($0)" }
        s.yearMonth = { year, month in
            "\(englishMonths.indices.contains(month - 1) ? englishMonths[month - 1] : String(month)) \(year)"
        }
        s.confirmCount = { "Confirm (\($0))" }
        s.memberCount = { englishCount($0, "{count} member", "{count} members") }
        s.wordCharCount = { words, chars in
            "\(englishCount(words, "{count} word", "{count} words")) · "
                + englishCount(chars, "{count} character", "{count} characters")
        }
        s.permissionNoun = { kind in
            switch kind {
            case .microphone: return "microphone"
            case .camera: return "camera"
            case .notifications: return "notifications"
            case .storage: return "storage"
            case .photos: return "photos"
            case .contacts: return "contacts"
            case .location: return "location"
            case .screen: return "screen recording"
            }
        }
        s.permissionVerb = { kind in
            switch kind {
            case .microphone: return "use the microphone"
            case .camera: return "use the camera"
            case .notifications: return "send notifications"
            case .storage: return "access storage"
            case .photos: return "access your photos"
            case .contacts: return "access your contacts"
            case .location: return "use your location"
            case .screen: return "record the screen"
            }
        }
        s.permissionTitle = { "Allow \($0) access" }
        s.permissionUndeterminedBody = { feature, verb in "\(feature) needs to \(verb). Allow it to continue." }
        s.permissionDeniedBody = { feature, verb in
            "Permission to \(verb) was denied, so \(feature) can't be used. Turn it on in system settings."
        }
        s.permissionRestrictedBody = { feature, verb in
            "Permission to \(verb) is restricted by this device or your organization, so \(feature) isn't available."
        }
        s.permissionUnavailableBody = { feature, verb in
            "This device can't \(verb) here, so \(feature) isn't available."
        }
        s.permissionStateLabel = { state in
            switch state {
            case .undetermined: return "Not granted"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .unavailable: return "Unavailable"
            }
        }
        s.messageImageGroupLabel = { englishCount($0, "{count} image", "{count} images") }
        s.messageImageGroupItem = { index, count in "Image \(index) of \(count)" }
        s.messageImageGroupItemMore = { index, count, more in "Image \(index) of \(count), \(more) more not shown" }
        s.messageRecalledGroupOther = { "\($0) recalled a message" }
        s.messageQuoteLabel = { name, summary in name.isEmpty ? "Quoted: \(summary)" : "Quoted \(name): \(summary)" }
        s.jumpedToMessage = { name, summary in "Jumped to \(name)'s message: \(summary)" }
        s.conversationHeaderIdentityLabel = { title, action in "\(title), \(action)" }
        s.momentAudienceSheetSelected = { englishCount($0, "{count} person selected", "{count} people selected") }
        s.announcementReadBarReadCount = { read, total in "\(read)/\(total) read" }
        s.imagePreviewPosition = { index, count in "\(index) of \(count)" }
        s.voiceSeconds = { englishCount($0, "{count} second", "{count} seconds") }
        s.ratingStar = { englishCount($0, "{count} star", "{count} stars") }
        s.connectionDisconnectedReason = { "Disconnected: \($0)" }
        s.groupDetailMembersTitle = { "Members (\($0))" }
        s.profilePanelEditProfile = { "\($0), edit profile" }
        s.momentReplyToComment = { name, text in "Reply to \(name): \(text)" }
        s.previewImageNamed = { "[Image] \($0)" }
        s.previewFileNamed = { "[File] \($0)" }
        s.previewLocationNamed = { "[Location] \($0)" }
        s.previewCardNamed = { "[Contact] \($0)" }
        s.previewForwardCount = { englishCount($0, "[Forward] {count} message", "[Forward] {count} messages") }
        s.previewImageGroupCount = { "[Album] \($0)" }
        s.systemEventGroupProfileUpdatedNamed = { "Group renamed to \($0)" }
        s.displayNameMembersMore = { names, count in names + englishCount(count, " and {count} other", " and {count} others") }
        return s
    }
}

/// The English month names, January first.
private let englishMonths: [String] = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.monthSymbols
}()

/// `count` in its English form: `one` at 1, else `other`, with `{count}` filled in.
private func englishCount(_ count: Int, _ one: String, _ other: String) -> String {
    flarePlural(count, one: one, other: other, locale: Locale(identifier: "en"))
        .replacingOccurrences(of: "{count}", with: String(count))
}
