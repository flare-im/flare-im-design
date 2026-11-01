package com.flare.im.ui

/** Where a named value came from (`source` on the wire). For tests and diagnostics only: every source reads the same. */
enum class FlareDisplayNameSource(val wire: String) {
    Alias("alias"),
    MemberNickname("memberNickname"),
    Profile("profile"),
    Snapshot("snapshot"),
    Remark("remark"),
    Name("name");

    companion object {
        /** The source a wire value names; null for one the kit does not know. */
        fun fromWire(value: String?): FlareDisplayNameSource? = entries.firstOrNull { it.wire == value }
    }
}

/** What an unnamed value is (`entity` on the wire), after the conversation type, or a person. */
enum class FlareDisplayNameEntity(val wire: String) {
    Person("person"),
    Group("group"),
    System("system"),
    Ai("ai"),
    Customer("customer"),
    Channel("channel"),
    Broadcast("broadcast"),
    Temp("temp");

    companion object {
        /** The entity a wire value names; null for one the kit does not know. */
        fun fromWire(value: String?): FlareDisplayNameEntity? = entries.firstOrNull { it.wire == value }
    }
}

/**
 * A name as the core SDK projects it — a conversation's `title` and `lastSender`, a message's `sender`, a participant's
 * or a contact's `name` — camelCase JSON on the wire. The SDKs carry no copy: a name that is not known stays structured
 * and every kit writes it with the same table (`spec/display-name-vectors.json`) through [flareDisplayNameText].
 * Components keep string parameters; a host turns the projected value into text where it hands it to one.
 */
sealed interface FlareDisplayName {
    /** A real name, drawn as it is. */
    data class Named(val text: String, val source: FlareDisplayNameSource? = null) : FlareDisplayName

    /** A group without a name, by up to three of its named members (never the reader); [total] counts the reader. */
    data class Members(val names: List<String>, val total: Int) : FlareDisplayName

    /** Nothing to call it by: what it is, and for a person the tail of their id ([flareIdTail]). */
    data class Unnamed(val entity: FlareDisplayNameEntity, val idTail: String = "") : FlareDisplayName

    companion object {
        private val UNKNOWN_USER = Unnamed(FlareDisplayNameEntity.Person)

        /**
         * Reads a parsed wire value (objects as maps, arrays as lists), never failing: an unknown `entity` reads as
         * [FlareDisplayNameEntity.Person]; an unknown `kind`, or a form missing its text, as an unnamed person without an
         * id tail (`displayNameUnknownUser`). A core newer than the kit therefore still draws something sensible.
         */
        fun fromMap(map: Map<*, *>): FlareDisplayName = when (map["kind"]) {
            "named" -> (map["text"] as? String)?.let { Named(it, FlareDisplayNameSource.fromWire(map["source"] as? String)) } ?: UNKNOWN_USER
            "members" -> Members((map["names"] as? List<*>).orEmpty().filterIsInstance<String>(), (map["total"] as? Number)?.toInt() ?: 0)
            "unnamed" -> Unnamed(FlareDisplayNameEntity.fromWire(map["entity"] as? String) ?: FlareDisplayNameEntity.Person, map["idTail"] as? String ?: "")
            else -> UNKNOWN_USER
        }

        /** Reads the wire JSON as [fromMap] does; malformed JSON or a value that is not an object reads as an unknown user. */
        fun fromJson(json: String): FlareDisplayName = (runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *>)?.let(::fromMap) ?: UNKNOWN_USER
    }
}

/**
 * The sender a quote shows (`spec/display-name-vectors.json` quoteSender, the same on all four kits), never blank and
 * never an id: [FlareReplyTarget.sender] written by [flareDisplayNameText] when the quote carries one; else
 * [FlareReplyTarget.senderName], trimmed, when it is not blank; else the unnamed person of [FlareReplyTarget.senderId] —
 * `displayNameUser` with the tail of the id ([flareIdTail]), `displayNameUnknownUser` without one. A projected sender
 * that writes as blank text falls through the same way. The bubble's quote and the composer's reply strip both read it.
 */
fun flareQuoteSenderText(target: FlareReplyTarget, strings: FlareStrings): String {
    target.sender?.let { flareDisplayNameText(it, strings).trim() }?.takeIf { it.isNotEmpty() }?.let { return it }
    target.senderName.trim().takeIf { it.isNotEmpty() }?.let { return it }
    return flareDisplayNameText(FlareDisplayName.Unnamed(FlareDisplayNameEntity.Person, flareIdTail(target.senderId.orEmpty())), strings)
}

/**
 * The tail of an id the kits show for a person without a name: the id trimmed of surrounding white space, then its last
 * 4 Unicode scalars — code points, so an emoji is one — or the whole id when it has 4 or fewer; a blank id gives "". The
 * core SDK makes `idTail` with the same rule (`spec/display-name-vectors.json` idTail).
 */
fun flareIdTail(id: String): String {
    val trimmed = id.trim()
    val count = trimmed.codePointCount(0, trimmed.length)
    return if (count <= 4) trimmed else trimmed.substring(trimmed.offsetByCodePoints(0, count - 4))
}

/**
 * The text of a projected name (`spec/display-name-vectors.json`, the same on all four kits). [FlareDisplayName.Named]
 * reads as it is; [FlareDisplayName.Members] joins the non-blank names with `displayNameSeparator` and, when the group
 * has more people than it names besides the reader, adds `displayNameMembersMore(names, total, others)` — Chinese counts
 * the group (total, the reader included), English the others (total - names - 1) — and with no name left reads as an
 * unnamed group; [FlareDisplayName.Unnamed] reads by entity — a person with an id tail
 * `displayNameUser`, without one `displayNameUnknownUser`, any other entity its own word.
 */
fun flareDisplayNameText(name: FlareDisplayName, strings: FlareStrings): String = when (name) {
    is FlareDisplayName.Named -> name.text
    is FlareDisplayName.Members -> {
        val names = name.names.filter { it.isNotBlank() }
        if (names.isEmpty()) {
            strings.displayNameGroup
        } else {
            val joined = names.joinToString(strings.displayNameSeparator)
            val others = name.total - names.size - 1
            if (others > 0) strings.displayNameMembersMore(joined, name.total, others) else joined
        }
    }
    is FlareDisplayName.Unnamed -> when (name.entity) {
        FlareDisplayNameEntity.Person -> if (name.idTail.isNotEmpty()) strings.displayNameUser(name.idTail) else strings.displayNameUnknownUser
        FlareDisplayNameEntity.Group -> strings.displayNameGroup
        FlareDisplayNameEntity.System -> strings.displayNameSystem
        FlareDisplayNameEntity.Ai -> strings.displayNameAi
        FlareDisplayNameEntity.Customer -> strings.displayNameCustomer
        FlareDisplayNameEntity.Channel -> strings.displayNameChannel
        FlareDisplayNameEntity.Broadcast -> strings.displayNameBroadcast
        FlareDisplayNameEntity.Temp -> strings.displayNameTemp
    }
}
