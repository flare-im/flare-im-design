package com.flare.im.ui

import java.text.Normalizer

/*
 * A–Z index letters for contact lists (the Vue `utils/contactIndex.ts` contract). Latin names — accented or full
 * width included — index by their first letter. A Chinese name indexes by the pinyin initial of its first
 * character, read from the generated table in `PinyinInitials.kt`; a polyphonic character follows the table's
 * reading, and a host that knows better passes `Contact.indexKey`. Anything else goes under "#", which lists
 * last. Inside a letter, names are ordered by the same table, so two names order by pinyin, not by code point.
 *
 * The table replaced the ICU "Han-Latin" transliterator in Round 12 (FR-044). ICU only arrived in Android 10, so
 * on Android 8 and 9 every Chinese name had gone under "#" next to the emoji; the table has no API level, covers
 * every BMP hanzi rather than what ICU happens to know, and is generated from the same collation the Vue kit
 * reads at runtime, so the four kits cannot disagree.
 */

/** The index bucket for names that start with neither a Latin letter nor a Chinese character. */
internal const val CONTACT_INDEX_OTHER = "#"

private fun firstCodePoint(text: String): Int? = text.trim().takeIf { it.isNotEmpty() }?.codePointAt(0)

/** A–Z for a Latin letter (accents and full width folded), else null. */
private fun latinLetter(codePoint: Int): String? {
    val folded = Normalizer.normalize(String(Character.toChars(codePoint)), Normalizer.Form.NFKD)
        .filter { Character.getType(it) != Character.NON_SPACING_MARK.toInt() }
        .uppercase()
    return folded.singleOrNull()?.takeIf { it in 'A'..'Z' }?.toString()
}

/** The index letter of a contact: [indexKey] when the host gives one, otherwise the name (see the file comment). */
internal fun contactIndexLetter(name: String, indexKey: String?): String {
    val source = indexKey ?: name
    val first = firstCodePoint(source) ?: return CONTACT_INDEX_OTHER
    latinLetter(first)?.let { return it }
    if (indexKey == null && first <= 0xFFFF) {
        flarePinyinInitial(first.toChar())?.let { return it.toString() }
    }
    return CONTACT_INDEX_OTHER
}

/**
 * The key names are ordered by inside a letter: the host's [indexKey], else the name with every hanzi replaced
 * by its position in the pinyin table. The marker sorts after digits and before letters, so a group reads
 * symbols, digits, Chinese in pinyin order, then Latin — the order the other three kits use.
 */
internal fun contactSortKey(name: String, indexKey: String?): String {
    if (indexKey != null) return indexKey.lowercase()
    val key = StringBuilder()
    for (character in name.trim()) {
        val position = flarePinyinPosition(character)
        if (position >= 0) key.append(':').append(position.toString().padStart(5, '0'))
        else key.append(character.lowercaseChar())
    }
    return key.toString()
}

/**
 * The index groups of [contacts] in list order: A to Z, then "#"; names in each group ordered by [contactSortKey].
 */
internal fun contactIndexGroups(contacts: List<Contact>): List<Pair<String, List<Contact>>> {
    return contacts.map { contact ->
        Triple(contact, contactIndexLetter(contact.name, contact.indexKey), contactSortKey(contact.name, contact.indexKey))
    }
        .groupBy { it.second }
        .toList()
        .sortedWith(compareBy({ it.first == CONTACT_INDEX_OTHER }, { it.first }))
        .map { (letter, keyed) -> letter to keyed.sortedWith(compareBy({ it.third }, { it.first.name })).map { it.first } }
}
