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
        /** Reads a parsed wire value (objects as maps, arrays as lists); null for one that is not a name the kit knows. */
        fun fromMap(map: Map<*, *>): FlareDisplayName? = when (map["kind"]) {
            "named" -> (map["text"] as? String)?.let { Named(it, FlareDisplayNameSource.fromWire(map["source"] as? String)) }
            "members" -> Members((map["names"] as? List<*>).orEmpty().filterIsInstance<String>(), (map["total"] as? Number)?.toInt() ?: 0)
            "unnamed" -> FlareDisplayNameEntity.fromWire(map["entity"] as? String)?.let { Unnamed(it, map["idTail"] as? String ?: "") }
            else -> null
        }

        /** Reads the wire JSON; null for malformed JSON or a value that is not a name the kit knows. */
        fun fromJson(json: String): FlareDisplayName? = (runCatching { FlareJson.parse(json) }.getOrNull() as? Map<*, *>)?.let(::fromMap)
    }
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
 * has more people than it names besides the reader, adds `displayNameMembersMore` with N = total - names - 1, and with
 * no name left reads as an unnamed group; [FlareDisplayName.Unnamed] reads by entity — a person with an id tail
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
            if (others > 0) strings.displayNameMembersMore(joined, others) else joined
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
