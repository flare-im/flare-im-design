package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Vocabulary 2 against `spec/plugin-view-vectors.json` (formats2, blocks2, moneyInput, upgradeNotice): the facts the four
 * kits share, plus reading every new block, input and the upgrade placeholder.
 */
class PluginBlocksExtraTest {
    private val zh = FlareStrings()
    private val en = flareStringsEnglish()

    private fun table(): Map<*, *> {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/plugin-view-vectors.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            dir = dir.parentFile
        }
        error("spec/plugin-view-vectors.json not found")
    }

    private fun Map<*, *>.map(key: String): Map<*, *> = this[key] as Map<*, *>
    private fun Map<*, *>.list(key: String): List<Map<*, *>> = (this[key] as List<*>).map { it as Map<*, *> }

    @Test
    fun countsAndDurationsAreWrittenInTheViewersWords() {
        for (item in table().map("formats2").list("cases")) {
            val format = pluginValueFormat(item["format"])
            val text = item["text"] as String
            assertEquals(item["zh"], PluginFormatRules.text(text, format, zh), "$item")
            assertEquals(item["en"], PluginFormatRules.text(text, format, en), "$item")
        }
    }

    @Test
    fun aFieldOrACellKeepsItsFormatAndAnUnknownOneIsPlainText() {
        val view = PluginViewModel.fromJson(
            """{"available":true,"title":"x","fields":[{"label":"Members","value":"12345","format":{"kind":"count","count":12345}},
              {"label":"X","value":"as sent","format":{"kind":"newer","value":1}}],
              "blocks":[{"kind":"rows","source":"list","columns":[{"label":"Time","format":"text"},{"label":"Took","format":"text"}],
              "rows":[{"key":"r1","cells":[{"text":"a"},{"text":"7500000","format":{"kind":"duration","ms":7500000}}],"actions":[]}],"actions":[]}]}""",
        )
        assertEquals(PluginValueFormat.Count(12345.0), view.fields[0].format)
        assertNull(view.fields[1].format)
        val rows = view.blocks.single() as PluginRowsBlock
        assertEquals("2 小时 5 分钟", PluginViewFormat.rowLines(rows, rows.rows[0], 0, zh, 0).secondary)
    }

    @Test
    fun everyVocabulary2BlockReads() {
        val view = PluginViewModel.fromJson(
            """{"available":true,"title":"Board","fields":[],"actions":[],"blocks":[
              {"kind":"section","label":"Overview","collapsed":true,"blocks":[
                {"kind":"stats","items":[{"label":"Open","value":"12","trend":{"text":"+3","direction":"up"},"tone":"success"},
                                         {"label":"Done","value":"12345","format":{"kind":"count","count":12345}}]},
                {"kind":"section","label":"nested","blocks":[{"kind":"divider"}]},
                {"kind":"brandNew","x":1}]},
              {"kind":"chart","chartKind":"bar","series":[{"label":"A","points":[{"label":"Mon","value":1,"text":"1"}]}],"emptyText":"None"},
              {"kind":"image","asset":"assets/cover.png","aspect":"16:9","alt":"Cover"},
              {"kind":"qr","value":"flare://pay/1","label":"Pay","refreshOperation":"qr.refresh","valuePath":"/code","expiresAtPath":"/exp","expiresAtMs":5000},
              {"kind":"hero","label":"Balance","value":"12.50","amount":true,"tone":"brand","actions":[{"id":"top-up","label":"Top up"}]},
              {"kind":"steps","items":[{"label":"Submitted","state":"done"},{"label":"Review","state":"current"},{"label":"Done","state":"skipped"}]},
              {"kind":"banner","tone":"danger","text":"Rejected","action":{"id":"retry","label":"Retry"}},
              {"kind":"timeline","items":[{"atMs":1000,"title":"Created","detail":"by Ann","status":{"text":"ok","tone":"success"}}],"emptyText":"Nothing"}
            ]}""",
        )
        assertEquals(listOf("section", "chart", "image", "qr", "hero", "steps", "banner", "timeline"), view.blocks.map { it.kind })
        val section = assertIs<PluginSectionBlock>(view.blocks[0])
        assertTrue(section.collapsed)
        assertEquals(listOf("stats"), section.blocks.map { it.kind }, "a nested section and an unknown kind are dropped")
        val stats = assertIs<PluginStatsBlock>(section.blocks[0])
        assertEquals(PluginTrend("+3", PluginTrendDirection.Up), stats.items[0].trend)
        assertEquals(PluginTone.Success, stats.items[0].tone)
        assertEquals(PluginValueFormat.Count(12345.0), stats.items[1].format)
        assertTrue(assertIs<PluginChartBlock>(view.blocks[1]).hasPoints)
        val image = assertIs<PluginImageBlock>(view.blocks[2])
        assertEquals(PluginImageSource(asset = "assets/cover.png"), image.source)
        assertEquals(PluginImageAspect.Wide, image.aspect)
        assertEquals(PluginQrRefresh("qr.refresh", "/code", "/exp"), assertIs<PluginQrBlock>(view.blocks[3]).refresh)
        val hero = assertIs<PluginHeroBlock>(view.blocks[4])
        assertEquals(PluginHeroTone.Brand, hero.tone)
        assertEquals(listOf("top-up"), hero.actions.map { it.id })
        assertEquals(listOf(PluginStepState.Done, PluginStepState.Current, PluginStepState.Pending),
            assertIs<PluginStepsBlock>(view.blocks[5]).items.map { it.state })
        val banner = assertIs<PluginBannerBlock>(view.blocks[6])
        assertEquals(PluginBannerTone.Danger, banner.tone)
        assertEquals("retry", banner.action?.id)
        assertEquals(PluginBadge("ok", PluginTone.Success), assertIs<PluginTimelineBlock>(view.blocks[7]).items.single().status)
    }

    @Test
    fun blockRulesFollowTheSharedTable() {
        val blocks2 = table().map("blocks2")
        for (item in blocks2.list("steps")) assertEquals(item["expect"], PluginStepState.fromWire(item["state"] as? String).wire)
        for (item in blocks2.list("trend")) assertEquals(item["expect"], PluginTrendDirection.fromWire(item["direction"] as? String).wire)
        for (item in blocks2.list("bannerTone")) assertEquals(item["expect"], PluginBannerTone.fromWire(item["tone"] as? String).wire)
        for (item in blocks2.list("heroTone")) assertEquals(item["expect"], PluginHeroTone.fromWire(item["tone"] as? String).wire)
        for (item in blocks2.list("imageRatio")) {
            assertEquals((item["expect"] as Number).toDouble(), PluginImageAspect.fromWire(item["aspect"] as? String).ratio.toDouble(), 1e-6)
        }
        for (item in blocks2.list("qr")) {
            val block = PluginQrBlock("x", expiresAtMs = (item["expiresAtMs"] as? Number)?.toLong())
            val now = (item["nowMs"] as Number).toLong()
            assertEquals(item["expired"], block.expired(now))
            assertEquals((item["refreshMs"] as? Number)?.toLong(), block.refreshDelay(now))
        }
        for (item in blocks2.list("donut")) {
            val points = (item["values"] as List<*>).mapIndexed { i, v -> PluginChartPoint("$i", (v as Number).toDouble(), "") }
            val expected = item.list("expect").map {
                PluginDonutSlice((it["index"] as Number).toInt(), (it["start"] as Number).toDouble(), (it["sweep"] as Number).toDouble())
            }
            assertEquals(expected, PluginChartRules.donutSlices(points))
        }
        for (item in blocks2.list("chartHasPoints")) {
            val view = PluginViewModel.fromMap(mapOf("available" to true, "title" to "x",
                "blocks" to listOf(mapOf("kind" to "chart", "chartKind" to "bar", "series" to item["series"]))))
            assertEquals(item["expect"], (view.blocks.single() as PluginChartBlock).hasPoints)
        }
        val flatten = blocks2.map("flatten")
        val view = PluginViewModel.fromMap(mapOf("available" to true, "title" to "x", "blocks" to flatten["blocks"]))
        assertEquals(flatten.list("expect").map { it["kind"] }, pluginFlatBlocks(view.blocks).map { it.kind })
    }

    @Test
    fun sectionChildrenNameTheirUsersAndKeepTheirOwnChoicesState() {
        val view = PluginViewModel.fromJson(
            """{"available":true,"title":"x","blocks":[{"kind":"section","blocks":[
              {"kind":"people","groups":[{"label":"Going","userIds":["u1","u2"],"count":2}]}]}]}""",
        )
        assertEquals(listOf("u1", "u2"), PluginViewFormat.userIds(view))
        assertNotEquals(0, pluginSectionChildIndex(0, 0))
        assertNotEquals(pluginSectionChildIndex(1, 0), pluginSectionChildIndex(0, 1))
    }

    @Test
    fun moneyInputFollowsTheSharedTable() {
        val money = table().map("moneyInput")
        val view = PluginViewModel.fromMap(mapOf("available" to true, "title" to "x", "inputs" to listOf(money["input"])))
        val input = view.inputs.single()
        assertEquals(PluginMoneyRules("CNY", 2, "0.01", "200"), input.money)
        for (item in money.list("normalize")) assertEquals(item["expect"], PluginMoneyInputRules.amount(item["typed"] as String))
        for (item in money.list("check")) {
            val subject = (item["input"] as? Map<*, *>)?.let {
                PluginViewModel.fromMap(mapOf("available" to true, "title" to "x", "inputs" to listOf(it))).inputs.single()
            } ?: input
            assertEquals(item["expect"], PluginFormRules.check(subject, item["draft"])?.wire, "$item")
        }
        for (item in money.list("values")) {
            assertEquals(item["expect"], PluginFormRules.values(listOf(input), mapOf(input.id to item["draft"]))[input.id], "$item")
        }
        for (item in money.list("drafts")) {
            assertEquals(item["expect"], PluginFormRules.draftValue(input, mapOf(input.id to item["value"])))
        }
        for (item in money.list("compare")) {
            assertEquals((item["expect"] as Number).toInt(), Integer.signum(PluginMoneyInputRules.compare(item["a"] as String, item["b"] as String)))
        }
    }

    @Test
    fun imageAndDocumentInputsAreUploadsAndSayWhatTheyTake() {
        val file = """"file":{"accept":["image/jpeg","image/png"],"maxBytes":1048576,"upload":{"prepareOperation":"p","completeOperation":"c","purpose":"id"}}"""
        val view = PluginViewModel.fromJson(
            """{"available":true,"title":"x","inputs":[
              {"id":"cover","kind":"image","label":"Cover",$file},
              {"id":"front","kind":"document","label":"ID","side":"front",$file},
              {"id":"bare","kind":"image","label":"No policy"},
              {"id":"cash","kind":"money","label":"No rules"},
              {"id":"odd","kind":"document","label":"Odd","side":"left",$file}]}""",
        )
        assertEquals(listOf("cover", "front"), view.inputs.map { it.id }, "an upload needs its policy, money its rules, a document a known side")
        val (image, document) = view.inputs
        assertTrue(image.kind.isUpload)
        assertEquals(PluginDocumentSide.Front, document.side)
        assertEquals(zh.pluginFormChooseImage, pluginUploadChooseText(image, zh))
        assertEquals(zh.pluginFormCaptureDocument, pluginUploadChooseText(document, zh))
        assertEquals(zh.pluginFormDocumentFront, pluginDocumentSideText(document, zh))
        assertNull(pluginDocumentSideText(image, zh))
        val draft = PluginFormRules.draft(listOf(image), mapOf("cover" to mapOf("fileId" to "f1")))
        assertEquals(mapOf("fileId" to "f1"), PluginFormRules.values(listOf(image), draft)["cover"])
        assertNull(PluginFormRules.check(document, null))
    }

    @Test
    fun upgradeNoticeModeFollowsTheSharedTable() {
        for (item in table().list("upgradeNotice")) {
            val status = (item["status"] as? Map<*, *>)?.let { PluginUpgradeStatus(it["available"] as? Boolean ?: false, (it["build"] as? Number)?.toLong()) }
            assertEquals(item["expect"], PluginUpgradeMode.of(status, item["canUpdate"] == true).name.replaceFirstChar { it.lowercase() }, "$item")
        }
    }

    @Test
    fun anUpgradePlaceholderReadsWithItsBuildAndSaysSo() {
        val view = PluginViewModel.fromJson("""{"available":false,"title":"Task board","unavailableReason":"upgrade_required","minBuild":41020}""")
        assertTrue(view.upgradeRequired)
        assertEquals(41020L, view.minBuild)
        assertEquals(zh.pluginViewUnavailableUpgradeRequired, PluginViewFormat.reasonText(PluginUnavailableReason.UpgradeRequired, zh))
        val parts = pluginViewParts(view, embedded = false, quote = false, reasonLine = PluginViewFormat.reasonLine(view, null, zh),
            keys = emptyList(), detailKey = null, failure = null, strings = zh)
        assertTrue(PluginViewPart.Upgrade in parts)
        assertTrue(parts.none { it is PluginViewPart.Line && it.key == "reason" }, "the notice replaces the reason line")
        assertEquals(zh.pluginUpgradeNotAvailable, pluginUpgradeCardText(PluginUpgradeMode.NotAvailable, zh))
        assertEquals(zh.pluginViewUnavailableUpgradeRequired, pluginUpgradeCardText(PluginUpgradeMode.Update, zh))
        assertEquals(zh.pluginUpgradeDescription, pluginUpgradePageText(PluginUpgradeMode.Description, zh))
        assertEquals(PluginUpgradeStatus(true, 41020), PluginUpgradeStatus.fromJson("""{"available":true,"build":41020}"""))
    }

    @Test
    fun theDeclaredVocabularyIsWhatTheKitDraws() {
        val declared = FlareJson.parse(PLUGIN_UI_VOCABULARY) as Map<*, *>
        assertEquals(PluginUiVocabulary.blocks, (declared["blocks"] as List<*>).toSet())
        assertFalse("protected-media" in PluginUiVocabulary.blocks, "the kit does not draw it, so it never reports it")
        assertEquals(PluginInputKind.entries.map { it.wire }.toSet(), PluginUiVocabulary.inputs)
        assertEquals(setOf("redPacket.card", "redPacket.pay", "payment.confirm"), PluginUiVocabulary.renderers)
        for (renderer in PluginUiVocabulary.renderers) {
            assertTrue(hasResolvedPresentation(PluginViewModel(available = true, title = "x", presentation = mapOf("renderer" to renderer))), renderer)
        }
        for (renderer in listOf("redPacket.composer", "redPacket.detail", "account", "flare.qr")) {
            assertFalse(hasResolvedPresentation(PluginViewModel(available = true, title = "x", presentation = mapOf("renderer" to renderer))), renderer)
        }
    }
}
