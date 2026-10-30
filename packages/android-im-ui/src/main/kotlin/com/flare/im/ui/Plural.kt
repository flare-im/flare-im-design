package com.flare.im.ui

import java.util.Locale

/*
 * Plural forms of the kit's count copy (spec/plural-vectors.json). A count string has an `other` field and a
 * `<field>One` sibling (`pluginViewVotes` / `pluginViewVotesOne`); the kit picks the one form when the locale's CLDR
 * cardinal category for the count is `one`. The rule is a table of language families rather than android.icu: the JVM
 * unit tests read the same vectors, and the four kits stay on one table (Vue checks it against Intl.PluralRules).
 */

private val NO_ONE = setOf("zh", "ja", "ko", "th", "vi", "id", "ms", "yue", "lo", "my", "km")
private val ZERO_OR_ONE = setOf("fr", "pt", "hi", "bn", "fa", "gu", "kn", "am", "zu")
private val ENDS_IN_ONE = setOf("ru", "uk", "be", "hr", "sr", "bs")

/** Java's legacy language codes, as some runtimes still report them. */
private fun canonicalLanguage(language: String): String = when (language.lowercase(Locale.ROOT)) {
    "iw" -> "he"
    "in" -> "id"
    "ji" -> "yi"
    else -> language.lowercase(Locale.ROOT)
}

/**
 * Whether [count] (a non-negative integer) takes the `one` form in [locale]: never in Chinese and its neighbours; at 1
 * in English and most languages (and any language not in the table); at 0 and 1 in French, Portuguese (not Portugal's)
 * and Hindi; at a last digit 1 other than 11 in Russian and its neighbours.
 */
fun flarePluralIsOne(count: Long, locale: Locale): Boolean {
    val n = if (count < 0) -count else count
    val language = canonicalLanguage(locale.language)
    return when {
        language in NO_ONE -> false
        language == "pt" && locale.country.equals("PT", ignoreCase = true) -> n == 1L
        language in ZERO_OR_ONE -> n == 0L || n == 1L
        language in ENDS_IN_ONE -> n % 10 == 1L && n % 100 != 11L
        else -> n == 1L
    }
}

/** The template for [count]: [one] when the count takes the one form in [locale], else [other]. */
fun flarePluralForm(count: Long, one: String, other: String, locale: Locale): String =
    if (flarePluralIsOne(count, locale)) one else other

/** The template for [count] filled in: `{count}` (and `{n}`) replaced by the number. */
fun flarePlural(count: Long, one: String, other: String, locale: Locale): String =
    flarePluralForm(count, one, other, locale).replace("{count}", count.toString()).replace("{n}", count.toString())
