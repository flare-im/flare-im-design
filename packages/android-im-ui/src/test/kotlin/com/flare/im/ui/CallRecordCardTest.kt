package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The call record card's rules, without a UI, against the shared table (spec/call-record-vectors.json): the status
 * line, its tone, the one action and the copy in both languages. Copy is read from the strings table, so a missing
 * field or a translation that drifted from the table reddens here.
 */
class CallRecordCardTest {
    private val zh = FlareStrings()
    private val en = flareStringsEnglish()

    private fun vectors(): Map<*, *> = SpecTables.table("call-record-vectors.json")

    private inline fun <reified T : Enum<T>> wire(name: String?): T? =
        name?.let { value -> enumValues<T>().first { it.name.equals(value, ignoreCase = true) } }

    @Test fun durationFollowsTheSharedTable() {
        val rows = vectors().items("duration")
        assertTrue(rows.size >= 10, "the shared table lost rows: ${rows.size}")
        for (row in rows) assertEquals(row.str("label"), flareCallDurationLabel(row.int("seconds")!!), "${row.int("seconds")}")
    }

    @Test fun rulesAndCopyFollowTheSharedTable() {
        val cases = vectors().items("cases")
        assertTrue(cases.size >= 30, "the shared table lost cases: ${cases.size}")
        for (case in cases) {
            val id = case.str("id")!!
            val input = case.obj("input")!!
            val scope = wire<FlareCallRecordScope>(input.str("scope"))!!
            val state = wire<FlareCallRecordState>(input.str("state"))!!
            val joined = input.int("joinedCount")
            val seconds = input.int("durationSeconds")
            val status = flareCallRecordStatus(
                scope = scope,
                state = state,
                viewerIsInitiator = input.bool("viewerIsInitiator")!!,
                endReason = wire<FlareCallEndReason>(input.str("endReason")),
                durationSeconds = seconds,
                joinedCount = joined,
            )
            assertEquals(wire<FlareCallRecordStatus>(case.str("status")), status, id)
            assertEquals(wire<FlareCallRecordTone>(case.str("tone")), flareCallRecordTone(status), id)
            val action = flareCallRecordAction(
                scope = scope,
                state = state,
                canJoin = input.bool("canJoin")!!,
                canCallBack = input.bool("canCallBack")!!,
                disabled = input.bool("disabled") ?: false,
            )
            assertEquals(wire<FlareCallRecordAction>(case.str("action")), action, id)
            val text = case.obj("text")!!
            assertEquals(text.str("zh"), flareCallRecordStatusText(zh, status, joined, seconds), id)
            assertEquals(text.str("en"), flareCallRecordStatusText(en, status, joined, seconds), id)
        }
    }

    @Test fun mediaAndActionCopyComesFromTheSharedSource() {
        for ((key, value) in listOf(
            "callRecordVoice" to zh.callRecordVoice,
            "callRecordVideo" to zh.callRecordVideo,
            "callRecordJoin" to zh.callRecordJoin,
            "callRecordCallBack" to zh.callRecordCallBack,
        )) assertEquals(SpecTables.copy(key, "zh"), value, key)
        assertEquals(SpecTables.copy("callRecordCallBack", "en"), en.callRecordCallBack)
        assertEquals(SpecTables.copy("callRecordJoin", "en"), en.callRecordJoin)
    }
}
