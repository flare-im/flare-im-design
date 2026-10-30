package com.flare.im.ui

import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** flarePluralIsOne and the count copy's one forms against spec/plural-vectors.json. */
class PluralVectorsTest {
    private val table = SpecTables.table("plural-vectors.json")

    @Test fun everyLocaleAndCountTakesTheFormTheVectorSays() {
        val cases = table.items("cases").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            val locale = Locale.forLanguageTag(case.str("locale")!!)
            assertEquals(case.bool("one"), flarePluralIsOne(case.long("count")!!, locale), "${case.str("locale")} ${case.long("count")}")
        }
    }

    /** Every language the table names follows its family, on more counts than the cases list. */
    @Test fun theLanguageTableMatchesItsFamilies() {
        val languages = table.obj("rules")!!.obj("languages")!!
        for ((family, names) in languages) for (name in names as List<*>) for (n in 0L..222L) {
            val expected = when (family) {
                "none" -> false
                "is1" -> n == 1L
                "is0or1" -> n == 0L || n == 1L
                else -> n % 10 == 1L && n % 100 != 11L
            }
            assertEquals(expected, flarePluralIsOne(n, Locale.forLanguageTag(name as String)), "$name $n")
        }
    }

    @Test fun theCountCopyTakesItsOneForm() {
        val forms = table.items("forms").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(forms.isNotEmpty())
        for (form in forms) {
            val english = form.str("locale") == "en"
            val strings = if (english) flareStringsEnglish() else FlareStrings()
            val locale = if (english) Locale.US else Locale.SIMPLIFIED_CHINESE
            val (one, other) = when (form.str("native")) {
                "pluginViewVotes" -> strings.pluginViewVotesOne to strings.pluginViewVotes
                "forwardRecordMore" -> strings.forwardRecordMoreOne to strings.forwardRecordMore
                "forwardRecordTotal" -> strings.forwardRecordTotalOne to strings.forwardRecordTotal
                "myInviteCountOnly" -> strings.myInviteCountOnlyOne to strings.myInviteCountOnly
                "storageUsageFileCount" -> strings.storageUsageFileCountOne to strings.storageUsageFileCount
                "messageBatchUnforwardable" -> strings.messageBatchUnforwardableOne to strings.messageBatchUnforwardable
                else -> error("no field ${form.str("native")}")
            }
            assertEquals(form.str("text"), flarePlural(form.long("count")!!, one, other, locale), "${form.str("native")} ${form.long("count")}")
        }
        assertEquals("1 vote", PluginViewFormat.votes(1, flareStringsEnglish(), Locale.US))
        assertEquals("1 file", storageFileCountLabel("{count} files", 1, "{count} file", Locale.US))
    }
}
