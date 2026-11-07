package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * `spec/access-diagnostics-vectors.json`, the table the four kits run: what the host read in, what the diagnostics page
 * shows out ([flareAccessDiagnostics] and its helpers), and the page's words in both languages.
 */
class AccessDiagnosticsTest {
    private val table = SpecTables.table("access-diagnostics-vectors.json")

    private fun wire(value: Enum<*>?): String? = value?.name?.replaceFirstChar { it.lowercase() }

    private fun status(raw: Map<*, *>?): FlareAccessStatus? = raw?.let {
        FlareAccessStatus(
            loaded = it.bool("loaded")!!,
            serial = it.long("serial"),
            source = it.str("source"),
            stale = it.bool("stale") ?: false,
            developmentMode = it.bool("developmentMode") ?: false,
            regionId = it.str("regionId"),
            accessPointId = it.str("accessPointId"),
            protocol = it.str("protocol"),
            connectAck = it.obj("connectAck")?.let { ack ->
                FlareAccessConnectAck(ack.str("accessPointId"), ack.bool("accessPointMismatch") ?: false)
            },
            recovering = it.obj("recovering")?.let { recovering ->
                FlareAccessRecovering(recovering.int("rounds")!!, recovering.long("nextRoundAtMs"))
            },
        )
    }

    private fun point(raw: Map<*, *>) = FlareAccessPoint(
        accessPointId = raw.str("accessPointId")!!,
        regionId = raw.str("regionId"),
        host = raw.str("host"),
        status = raw.str("status")!!,
        rttMs = (raw["rttMs"] as? Number)?.toDouble(),
        breaker = raw.str("breaker")!!,
        pinned = raw.bool("pinned")!!,
        current = raw.bool("current")!!,
    )

    @Test fun theThresholdsAreTheSharedOnes() {
        val thresholds = table.obj("thresholds")!!
        assertEquals(thresholds.long("rttGoodBelowMs"), FlareAccessRttThresholds.GOOD_BELOW_MS)
        assertEquals(thresholds.long("rttPoorAboveMs"), FlareAccessRttThresholds.POOR_ABOVE_MS)
        assertTrue(table.items("cases").size >= 14, "the shared table lost cases")
    }

    @Test fun everyCaseShowsWhatTheSharedTableSays() {
        for (case in table.items("cases")) {
            val name = case.str("name")!!
            val model = flareAccessDiagnostics(status(case.obj("status")), case.items("accessPoints").map(::point))
            val want = case.obj("expect")!!
            assertEquals(want.str("state"), wire(model.state), name)
            assertEquals(
                want.items("notices").map { Triple(it.str("text"), it.str("tone"), it.bool("pulse")) },
                model.notices.map { Triple(wire(it.text), wire(it.tone), it.pulse) },
                name,
            )
            assertEquals(want.str("manifest"), wire(model.manifest), name)
            assertEquals(want.long("rttMs"), model.rtt.shownMs, name)
            assertEquals(want.str("rttGrade"), wire(model.rtt.grade), name)
            assertEquals(want.str("reportedAccessPointId"), model.reportedAccessPointId, name)
            assertEquals(want.int("recoveryRounds"), model.recoveryRounds, name)
            assertEquals(
                want.items("regions").map { it.str("regionId") to (it["accessPoints"] as List<*>) },
                model.regions.map { region -> region.regionId to region.accessPoints.map { it.accessPointId } },
                name,
            )
        }
    }

    @Test fun everyRowReadsWhatTheSharedTableSays() {
        for (vector in table.items("points")) {
            val name = vector.str("name")!!
            val row = flareAccessPointRow(point(vector.obj("point")!!))
            val want = vector.obj("expect")!!
            assertEquals(want.str("status"), wire(row.status), name)
            assertEquals(want.str("statusTone"), wire(row.statusTone), name)
            assertEquals(want.str("breaker"), wire(row.breaker), name)
            assertEquals(want.str("breakerTone"), wire(row.breakerTone), name)
            assertEquals(want.str("pin"), wire(row.pin), name)
        }
    }

    @Test fun latencyIsGradedOnTheWholeMillisecondsItShows() {
        for (row in table.items("rtt")) {
            val rtt = flareAccessRtt((row["rttMs"] as? Number)?.toDouble())
            assertEquals(row.long("shownMs"), rtt.shownMs, "${row["rttMs"]}")
            assertEquals(row.str("grade"), wire(rtt.grade), "${row["rttMs"]}")
        }
        assertNull(flareAccessRtt(Double.NaN).grade)
        assertNull(flareAccessRtt(Double.POSITIVE_INFINITY).grade)
    }

    @Test fun theProtocolIsNamed() {
        for (row in table.items("protocols")) assertEquals(row.str("label"), flareAccessProtocolLabel(row.str("protocol")))
    }

    @Test fun theSourceReadsApart() {
        for (row in table.items("sources")) {
            val source = flareAccessSource(row.str("source"))
            assertEquals(row.str("kind"), wire(source.kind), "${row["source"]}")
            assertEquals(row.str("detail"), source.detail, "${row["source"]}")
        }
    }

    @Test fun theActionsAreAnswered() {
        for (row in table.items("refresh")) {
            val feedback = flareAccessRefreshFeedback(row.str("outcome"))
            assertEquals(row.str("text"), wire(feedback?.text), "${row["outcome"]}")
            assertEquals(row.str("tone"), wire(feedback?.tone), "${row["outcome"]}")
        }
        for (row in table.items("import")) {
            val feedback = flareAccessImportFeedback(row.str("outcome"), row.str("code"))
            assertEquals(row.str("text"), wire(feedback?.text), "${row["outcome"]} ${row["code"]}")
            assertEquals(row.str("tone"), wire(feedback?.tone), "${row["outcome"]} ${row["code"]}")
        }
        for (row in table.items("export")) {
            val feedback = flareAccessExportFeedback(row.str("outcome"))
            assertEquals(row.str("text"), wire(feedback?.text), "${row["outcome"]}")
            assertEquals(row.str("tone"), wire(feedback?.tone), "${row["outcome"]}")
        }
    }

    @Test fun theWordsReadInBothLanguages() {
        val zh = FlareStrings()
        val en = flareStringsEnglish()
        assertEquals("服务暂时不可用，正在自动恢复…", FlareAccessNoticeText.ServiceUnavailable.label(zh))
        assertEquals("Connection is healthy", FlareAccessNoticeText.Healthy.label(en))
        assertEquals("86 ms · 良好", flareAccessRtt(86.0).label(zh))
        assertEquals("420 ms · Poor", flareAccessRtt(420.0).label(en))
        assertNull(flareAccessRtt(null).label(zh))
        assertEquals("镜像 cfg.example.org", flareAccessSourceLabel("https:https://cfg.example.org/flare/", zh))
        assertEquals("Access point ap-1", flareAccessSourceLabel("wellKnown:ap-1", en))
        assertEquals("This link is older than the lines on this device.", FlareAccessImportText.Rollback.label(en))
    }
}
