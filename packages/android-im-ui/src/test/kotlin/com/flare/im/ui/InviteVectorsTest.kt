package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * The shared invite table (spec/invite-vectors.json), run vector by vector so a rule that drifts on
 * one platform reddens here and nowhere else. Every vector id is asserted, so a table the test stops
 * reading is a failure, not silence.
 */
class InviteVectorsTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/invite-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/invite-vectors.json not found above ${File(".").absolutePath}")
    }

    @Suppress("UNCHECKED_CAST")
    private fun table(name: String): List<Map<String, Any?>> {
        val root = FlareJson.parse(vectorsFile().readText()) as Map<String, Any?>
        return root.getValue(name) as List<Map<String, Any?>>
    }

    private fun mode(name: Any?): FlareInviteCodeMode = when (name) {
        "off" -> FlareInviteCodeMode.Off
        "required" -> FlareInviteCodeMode.Required
        else -> FlareInviteCodeMode.Optional
    }

    @Suppress("UNCHECKED_CAST")
    private fun result(raw: Any?): FlareInviteCodeCheckResult? = (raw as? Map<String, Any?>)?.let {
        FlareInviteCodeCheckResult(it["valid"] as Boolean, it["inviterDisplayName"] as? String)
    }

    @Suppress("UNCHECKED_CAST")
    private fun stats(raw: Any?): FlareReferralStats? = (raw as? Map<String, Any?>)?.let {
        FlareReferralStats((it["direct"] as Number).toInt(), (it["l2"] as Number).toInt(), (it["l3"] as Number).toInt(), (it["total"] as Number).toInt())
    }

    private fun length(v: Map<String, Any?>) = (v["length"] as? Number)?.toInt() ?: FLARE_INVITE_CODE_DEFAULT_LENGTH

    @Test fun normalizesLikeTheTableAndIdempotently() {
        val rows = table("normalize")
        assertEquals(10, rows.size)
        for (v in rows) {
            val once = normalizeInviteCode(v["raw"] as String, length(v))
            assertEquals(v["expected"], once, v["id"].toString())
            assertEquals(once, normalizeInviteCode(once, length(v)), "${v["id"]} idempotent")
        }
    }

    @Test fun resolvesTheFieldState() {
        val rows = table("fieldState")
        assertEquals(13, rows.size)
        for (v in rows) {
            val state = inviteCodeFieldState(
                mode = mode(v["mode"]), value = v["value"] as String,
                checking = v["checking"] as? Boolean ?: false, checkResult = result(v["checkResult"]),
                error = v["error"] as? String, disabled = v["disabled"] as? Boolean ?: false,
            )
            assertEquals(v["expected"], state.name.lowercase(), v["id"].toString())
        }
    }

    @Test fun asksForACheckOnlyForACompleteEnabledCode() {
        val rows = table("checkRequest")
        assertEquals(6, rows.size)
        for (v in rows) {
            val code = inviteCodeToCheck(v["value"] as String, length(v), mode(v["mode"]), v["disabled"] as? Boolean ?: false)
            assertEquals(v["expected"], code, v["id"].toString())
        }
    }

    @Suppress("UNCHECKED_CAST")
    @Test fun listsDepthRowsPerVisibility() {
        val rows = table("depthRows")
        assertEquals(6, rows.size)
        for (v in rows) {
            val actual = referralDepthRows(stats(v["stats"]), (v["maxDepthShown"] as Number).toInt()).map { it.name.lowercase() }
            assertEquals(v["expected"] as List<String>, actual, v["id"].toString())
        }
    }

    @Suppress("UNCHECKED_CAST")
    @Test fun resolvesRegenerateCooldownRoundingUp() {
        val rows = table("regenerate")
        assertEquals(10, rows.size)
        for (v in rows) {
            val a = regenerateAvailability(v["canRegenerate"] as Boolean, (v["availableAt"] as? Number)?.toLong(), (v["now"] as Number).toLong())
            val expected = v["expected"] as Map<String, Any?>
            assertEquals(expected["shown"], a.shown, "${v["id"]} shown")
            assertEquals(expected["enabled"], a.enabled, "${v["id"]} enabled")
            val remaining = expected["remaining"] as? Map<String, Any?>
            if (remaining == null) assertNull(a.remaining, v["id"].toString())
            else {
                assertEquals(remaining["unit"], a.remaining!!.unit.name.lowercase(), "${v["id"]} unit")
                assertEquals((remaining["count"] as Number).toInt(), a.remaining!!.count, "${v["id"]} count")
            }
        }
    }

    @Test fun formatsJoinedDates() {
        val rows = table("joinedDate")
        assertEquals(2, rows.size)
        for (v in rows) {
            assertEquals(v["expected"], formatInviteJoinedDate((v["year"] as Number).toInt(), (v["month"] as Number).toInt(), (v["day"] as Number).toInt()), v["id"].toString())
        }
    }

    @Test fun cooldownAndDepthCopyComeFromTheStringsTable() {
        val s = FlareStrings()
        assertEquals("15 分钟 后可重新生成", inviteCooldownText(s, FlareInviteCooldown(FlareInviteCooldownUnit.Minute, 15)))
        assertEquals("2 小时 后可重新生成", inviteCooldownText(s, FlareInviteCooldown(FlareInviteCooldownUnit.Hour, 2)))
        assertEquals("团队总数", inviteDepthLabel(s, FlareReferralDepth.Total))
        val en = FlareStrings { myInviteCooldown = "You can regenerate in {time}"; myInviteUnitDays = "{n} d" }
        assertEquals("You can regenerate in 3 d", inviteCooldownText(en, FlareInviteCooldown(FlareInviteCooldownUnit.Day, 3)))
    }
}
