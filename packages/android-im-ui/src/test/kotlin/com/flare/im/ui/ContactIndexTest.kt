package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * Contact index letters and order, read from the generated pinyin table (`PinyinInitials.kt`) rather than from
 * the device's ICU transliterator — so the rules hold on every API level, and these run on the JVM.
 */
class ContactIndexTest {
    @Test fun chineseNamesIndexByPinyinInitialAndLatinNamesByLetter() {
        assertEquals("C", contactIndexLetter("陈默", null))
        assertEquals("L", contactIndexLetter(" 林澈", null))
        assertEquals("A", contactIndexLetter("alice", null))
        // Accents and full-width letters fold to their letter.
        assertEquals("E", contactIndexLetter("Émile", null))
        assertEquals("B", contactIndexLetter("Ｂob", null))
        // Digits, emoji and a blank name go under "#".
        assertEquals(CONTACT_INDEX_OTHER, contactIndexLetter("123", null))
        assertEquals(CONTACT_INDEX_OTHER, contactIndexLetter("😀 Joy", null))
        assertEquals(CONTACT_INDEX_OTHER, contactIndexLetter("  ", null))
    }

    @Test fun theHostIndexKeyWins() {
        assertEquals("Z", contactIndexLetter("曾", indexKey = "zeng"))
        assertEquals(CONTACT_INDEX_OTHER, contactIndexLetter("曾", indexKey = "#"))
    }

    @Test fun theTableCoversWhatIcuUsedToMissAndAgreesWithTheOtherKits() {
        // Android 8 and 9 had no transliterator, so every one of these was "#" there; 梓 琪 苒 珩 婧 are
        // GB2312 level 2 and 玥 is outside GB2312, which is what Flutter's old table missed.
        for ((name, letter) in mapOf("梓" to "Z", "琪" to "Q", "苒" to "R", "珩" to "H", "玥" to "Y", "婧" to "J")) {
            assertEquals(letter, contactIndexLetter(name, null), name)
        }
        // A polyphonic character follows the collation the table was generated from: 曾 is C on all four kits.
        assertEquals("C", contactIndexLetter("曾一", null))
        assertEquals("Z", contactIndexLetter("长江", null))
    }

    @Test fun charactersOutsideTheTableHaveNoLetter() {
        assertNull(flarePinyinInitial('A'))
        assertNull(flarePinyinInitial('㐀'), "CJK extension A is outside the block")
        assertEquals(-1, flarePinyinPosition('A'))
    }

    @Test fun lettersListAToZThenHashAndNamesFollowPinyinInsideALetter() {
        val contacts = listOf("周舟", "123", "陈曦", "alice", "安娜", "陈默", "Chloe", "林澈").mapIndexed { i, name -> Contact("c$i", name) }
        val groups = contactIndexGroups(contacts)
        assertEquals(listOf("A", "C", "L", "Z", CONTACT_INDEX_OTHER), groups.map { it.first })
        // Chinese names before Latin ones inside a letter, which is what the pinyin collation does and what
        // the other three kits show. Reading 安娜 as "an na" used to sort it after "alice", here alone.
        assertEquals(listOf("安娜", "alice"), groups[0].second.map { it.name })
        // 陈默 (chen mo) before 陈曦 (chen xi), then the Latin name.
        assertEquals(listOf("陈默", "陈曦", "Chloe"), groups[1].second.map { it.name })
    }

    @Test fun namesInALetterOrderByPinyinAndNotByCodePoint() {
        // 张 (U+5F20) < 周 (U+5468) by pinyin but not by code point, so a code-point sort would swap them.
        val contacts = listOf("周六", "张三", "梓涵").mapIndexed { i, name -> Contact("c$i", name) }
        val groups = contactIndexGroups(contacts)
        assertEquals(listOf("Z"), groups.map { it.first })
        assertEquals(listOf("张三", "周六", "梓涵"), groups[0].second.map { it.name })
    }
}
