package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * The page rules of docs/plugin-experience.md (R1–R12, 6.1) against the groups `spec/plugin-view-vectors.json` and
 * `spec/plugin-refresh-vectors.json` share with the other kits: actionRoles, statusValues, references,
 * blockBoundInputs, cardHeader, refreshKey, accountDerivation, formPlacement, formCounter, selectOptions,
 * actionDedupe, result, pageStates, statusCard, afterAction, afterReturn and doneTarget.
 */
class PluginExperienceVectorsTest {
    private val table = SpecTables.table("plugin-view-vectors.json")
    private val refresh = SpecTables.table("plugin-refresh-vectors.json")
    private val s = FlareStrings()

    private fun Map<*, *>.strings(key: String): List<String> = (this[key] as? List<*>).orEmpty().map { it as String }

    /** A case's view as the core resolves it: the vectors leave out what every loaded page has. */
    private fun view(raw: Map<*, *>): PluginViewModel =
        PluginViewModel.fromMap(LinkedHashMap<Any?, Any?>(raw).apply { putIfAbsent("available", true); putIfAbsent("title", "") })

    private fun cases(group: String): List<Map<*, *>> =
        table.items(group).filter { "compose" in it.strings("platforms") }.also { assertTrue(it.isNotEmpty(), "the shared table lost $group") }

    private fun ids(actions: List<PluginViewAction>) = actions.map { it.id }

    @Test fun actionsTakeTheirRoleAndPlace() {
        for (case in cases("actionRoles")) {
            val name = case.str("name")!!
            val v = view(case.obj("view")!!)
            val places = pluginActionPlaces(v, case.bool("embedded")!!, case.str("inlineFormActionId"))
            val expect = case.obj("expect")!!
            assertEquals(expect.str("archetype"), places.archetype.name.lowercase(), "$name archetype")
            val facts = expect.obj("places")!!
            val drawn = mapOf(
                "quick" to ids(places.quick), "bar" to ids(places.bar), "barSecondary" to ids(places.barSecondary),
                "header" to ids(places.header), "commands" to ids(places.commands), "more" to ids(places.more),
                "danger" to ids(places.danger), "footer" to ids(places.footer), "menu" to ids(places.menu),
            )
            for ((place, got) in drawn) {
                if (place in facts) assertEquals(facts[place], got, "$name $place")
                else assertTrue(got.isEmpty(), "$name: $place is empty")
            }
            val lists = places.list.map { mapOf("group" to it.group, "ids" to ids(it.actions)) }
            assertEquals(facts["list"] ?: emptyList<Any>(), lists, "$name list")
            expect.obj("roles")?.forEach { (id, role) ->
                assertEquals(role, pluginActionRole(v.actions.first { it.id == id }).name.lowercase(), "$name role of $id")
            }
            (expect["chevron"] as? List<*>)?.let { chevron ->
                for (action in places.list.flatMap { it.actions }) {
                    assertEquals(action.id in chevron, pluginActionChevron(action), "$name chevron of ${action.id}")
                }
            }
        }
        assertEquals("常用", s.pluginViewGroupCommon)
        assertEquals("记录与设置", s.pluginViewGroupRecords)
    }

    /** What a status value draws as, from where the case says it sits. */
    private fun statusDraw(where: String, item: Map<*, *>): PluginStatusDraw = when (where) {
        "field" -> view(mapOf("fields" to listOf(item))).fields.single().let { pluginStatusDraw(it.value, it.tone, it.unmapped, s) }
        "cell" -> {
            val rows = pluginBlockOf(mapOf("kind" to "rows", "source" to "x", "columns" to listOf(mapOf("label" to "状态")),
                "rows" to listOf(mapOf("key" to "k", "cells" to listOf(item))))) as PluginRowsBlock
            rows.rows.single().cells.single().let { pluginStatusDraw(it.text, it.tone, it.unmapped, s) }
        }
        "status" -> (pluginBlockOf(item) as PluginStatusBlock).let { pluginStatusDraw(it.text, it.tone, it.unmapped, s) }
        "badge" -> {
            val entries = pluginBlockOf(mapOf("kind" to "entries", "items" to listOf(mapOf("index" to 1, "text" to "x", "badge" to item)))) as PluginEntriesBlock
            entries.items.single().badge!!.let { pluginStatusDraw(it.text, it.tone, it.unmapped, s) }
        }
        else -> error("no status place $where")
    }

    @Test fun statusValuesDrawTagsAndNeverTheRawUnmappedValue() {
        for (case in cases("statusValues")) {
            val name = case.str("name")!!
            val expect = case.obj("expect")!!
            val draw = statusDraw(case.str("where")!!, case.obj("item")!!)
            when (expect.str("draw")) {
                "text" -> assertEquals(PluginStatusDraw.Text(expect.str("text")!!), draw, name)
                "tag" -> {
                    assertIs<PluginStatusDraw.Tag>(draw, name)
                    assertEquals(expect.str("tone"), draw.tone.wire, "$name tone")
                    if (expect.bool("unknown") == true) {
                        assertTrue(draw.unknown, "$name reads unknown")
                        assertEquals(s.pluginViewUnknownStatus, draw.text, "$name never the raw value")
                    } else assertEquals(expect.str("text"), draw.text, name)
                    assertEquals(expect.bool("warn") == true, draw.unknown, "$name warns exactly when unmapped")
                }
            }
        }
    }

    @Test fun referenceFieldsFoldAfterTheOthers() {
        for (case in cases("references")) {
            val fields = view(mapOf("fields" to case["fields"])).fields
            val (main, references) = pluginSplitReferences(fields)
            val expect = case.obj("expect")!!
            assertEquals(expect["main"], main.map { it.label }, case.str("name"))
            assertEquals(expect["references"], references.map { it.label }, case.str("name"))
        }
    }

    @Test fun blockBoundInputsAreNeverFields() {
        for (case in cases("blockBoundInputs")) {
            val name = case.str("name")!!
            val v = view(case.obj("view")!!)
            val bound = pluginBoundInputs(v)
            val expect = case.obj("expect")!!
            assertEquals(expect["formFields"], v.actions.flatMap { pluginFormFields(v, it, bound) }.map { it.id }.distinct(), "$name fields")
            assertEquals(expect["topLevel"], ids(pluginTopLevelActions(v, embedded = true)), "$name top level")
            assertEquals(expect["blockActions"], ids(v.actions.filter { pluginIsBlockAction(it, bound) }), "$name block actions")
            assertEquals(expect.str("inlineFormActionId"), pluginPageInlineFormActionId(v), "$name inline form")
        }
    }

    @Test fun theCardHeadKeepsDetailsBesideTheTitleOnlyWithoutFooterKeys() {
        for (case in cases("cardHeader")) {
            val detail = case.bool("detail")!!
            val head = pluginCardDetailInHead(case.int("footerActions")!!)
            val order = listOf("icon", "title") + (if (detail && head) listOf("detail") else emptyList()) +
                (if (case.int("menuActions")!! > 0) listOf("more") else emptyList())
            val expect = case.obj("expect")!!
            assertEquals(expect["order"], order, case.str("name"))
            expect.bool("detailInFooter")?.let { assertEquals(it, detail && !head, case.str("name")) }
        }
    }

    @Test fun onlyDataPagesRefresh() {
        for (case in cases("refreshKey")) {
            val v = view(case.obj("view")!!)
            val archetype = pluginActionPlaces(v, embedded = true, inlineFormActionId = case.str("inlineFormActionId")).archetype
            assertEquals(case["expect"], pluginPageIsDataPage(v, archetype), case.str("name"))
        }
    }

    @Test fun theAccountAppearanceIsDerivedFromStructure() {
        for (case in cases("accountDerivation")) {
            val requested = when (case.str("appearance")) {
                "document" -> FlarePluginPageAppearance.Document
                "account" -> FlarePluginPageAppearance.Account
                else -> null
            }
            val v = view(case.obj("view")!!)
            assertEquals(case.str("expect"), pluginPageAppearance(requested, v).name.lowercase(), case.str("name"))
        }
        // A derived account is drawn as the account renderer reads it: the hero leads its fields.
        val derived = pluginAccountDocument(view(cases("accountDerivation").first().obj("view")!!))
        assertEquals("account", derived.presentation?.get("renderer"))
        assertEquals("¥1,000.00", derived.fields.first().value)
    }

    @Test fun formsOpenWhereTheirFieldsFit() {
        for (case in cases("formPlacement")) {
            val kinds = case.strings("inputs").map { assertNotNull(PluginInputKind.fromWire(it), it) }
            assertEquals(case.str("expect"), pluginFormPlacementOf(kinds, case.bool("inline")!!).name.lowercase(), case.str("name"))
        }
        for (case in cases("formCounter")) {
            assertEquals(case["expect"], pluginFormCounterShows(case.int("maxLength"), case.int("length")!!), case.str("name"))
        }
        for (case in cases("selectOptions")) {
            val name = case.str("name")!!
            val count = case.int("choices")!!
            val input = PluginInput("plan", PluginInputKind.Select, "方案", required = true,
                choices = List(count) { PluginInputChoice("v$it", "选项 $it") })
            val expect = case.obj("expect")!!
            val control = pluginSelectControl(count)
            assertEquals(expect.str("control"), if (control == PluginSelectControl.Cards) "cards" else "select", "$name control")
            assertEquals(expect.bool("disabled"), control == PluginSelectControl.Empty, "$name disabled")
            assertEquals(expect.bool("submitDisabled"), pluginFormBlocked(listOf(input), emptyMap()), "$name submit")
            // Inputs carry no help text (rules.formPlacement): a select with no choices always explains with the kit's line.
            if (case.str("help") == null) expect.str("help")?.let { help ->
                assertEquals(if (help == "pluginView.noOptionsHelp") s.pluginViewNoOptionsHelp else help, pluginSelectHelp(input, s), "$name help")
            }
            if (expect.str("placeholder") == "pluginView.noOptions") assertEquals("暂无可选项", s.pluginViewNoOptions)
        }
    }

    @Test fun oneLabelIsDrawnOnce() {
        for (case in cases("actionDedupe")) {
            val actions = case.items("actions").map { assertNotNull(pluginActionOf(it)) }
            val (kept, dropped) = pluginDedupeActions(actions)
            val expect = case.obj("expect")!!
            assertEquals(expect["drawn"], ids(kept), case.str("name"))
            assertEquals(expect.bool("warn"), dropped, case.str("name"))
        }
    }

    @Test fun resultsDrawTheirOutcome() {
        for (case in cases("result")) {
            val name = case.str("name")!!
            val block = assertIs<PluginResultBlock>(pluginBlockOf(case.obj("block")!!), name)
            val expect = case.obj("expect")!!
            assertEquals(expect.str("icon"), pluginResultIcon(block.tone, block.unmapped), "$name icon")
            assertEquals(expect.str("tone"), (if (block.unmapped) PluginTone.Neutral else block.tone).wire, "$name tone")
            expect.str("title")?.let { assertEquals(it, block.title, "$name title") }
            expect.str("amount")?.let { assertEquals(it, PluginFormatRules.text(block.amount!!, block.format, s), "$name amount") }
            expect.str("description")?.let { assertEquals(it, block.description, "$name description") }
            assertEquals(expect.bool("poll"), pluginResultPolls(block), "$name poll")
            expect.long("pollMs")?.let { assertEquals(it, PLUGIN_RESULT_POLL_MS) }
            expect.long("pollForMs")?.let { assertEquals(it, PLUGIN_RESULT_POLL_FOR_MS) }
            expect.str("announce")?.let { assertEquals(it, pluginResultAnnouncement(block, s), "$name announce") }
            assertEquals(expect.bool("unknown") == true, block.unmapped, "$name unknown")
            // A result page draws no refresh key and no other places.
            val page = view(mapOf("fields" to emptyList<Any>(), "blocks" to listOf(case.obj("block")!!), "actions" to emptyList<Any>()))
            assertEquals(block, pluginPagePlan(page, null).result, name)
        }
    }

    @Test fun pageStatesFollowTheTable() {
        for (case in cases("pageStates")) {
            val name = case.str("name")!!
            val expect = case.obj("expect")!!
            val raw = case.obj("view")
            val page = raw?.let { PluginPageViewModel(view(it)) }
            val phase = pluginPagePhase(case.bool("loading") == true, case.str("error"), page)
            when (expect.str("state")) {
                "blank" -> assertEquals(PluginPageSkeleton.Blank, pluginPageSkeleton(case.long("elapsedMs")!!), name)
                "skeleton" -> {
                    assertEquals(PluginPageSkeleton.Records, pluginPageSkeleton(case.long("elapsedMs")!!), name)
                    assertEquals(expect.int("rows"), PLUGIN_RECORDS_SKELETON_ROWS, name)
                }
                "error" -> {
                    assertEquals(PluginPagePhase.Error, phase, name)
                    assertEquals("没有读到内容", s.pluginViewLoadFailedTitle)
                }
                "loaded" -> {
                    assertEquals(PluginPagePhase.Loaded, phase, name)
                    val v = page!!.view
                    expect.obj("blockEmpty")?.let { empty ->
                        val rows = v.blocks.filterIsInstance<PluginRowsBlock>().single()
                        assertEquals(empty.str("title"), PluginViewFormat.rowsEmpty(rows, s), "$name empty title")
                        assertEquals(empty.str("action"), pluginPagePlan(v, null).emptyCreate?.id, "$name create action")
                    }
                    if (expect.str("primaryCaption") == "pluginView.availableOnline") {
                        assertNotNull(pluginEmptyCreateAction(v), "$name has a primary to carry the caption")
                        assertEquals("联网后可用", s.pluginViewAvailableOnline)
                    }
                }
            }
        }
    }

    @Test fun theStatusCardDrawsForItsRendererOrItsStructure() {
        for (case in cases("statusCard")) {
            assertEquals(case["expect"], pluginStatusCard(view(case.obj("view")!!)), case.str("name"))
        }
        val card = pluginStatusCardParts(view(cases("statusCard")[1].obj("view")!!), s)
        assertEquals("审核中", card.title)
        assertEquals(PluginTone.Info, card.tone)
        assertNotNull(card.steps)
    }

    @Test fun aDisabledActionKeepsItsPlaceAndSaysWhy() {
        for (case in cases("actionDisabled")) {
            val name = case.str("name")!!
            val v = view(mapOf("actions" to case["actions"]))
            val drawn = pluginTopLevelActions(v, embedded = true)
            val expect = case.obj("expect")!!
            assertEquals(expect["drawn"], ids(drawn), "$name drawn")
            assertEquals(expect["disabled"], ids(drawn.filter { it.disabledReason != null }), "$name disabled")
            assertEquals(expect["captions"], drawn.mapNotNull { a -> a.disabledReason?.let { a.id to it } }.toMap(), "$name captions")
            // R2.5: a disabled action keeps the role and place it would have anyway.
            for (action in drawn) {
                assertEquals(pluginActionRole(action.copy(disabledReason = null)), pluginActionRole(action), "$name role of ${action.id}")
            }
            val places = pluginActionPlaces(v, embedded = true).all.map { it.id }
            assertEquals(ids(drawn).toSet(), places.toSet(), "$name places")
        }
    }

    @Test fun aCleanSettleReadsThePageAgain() {
        for (case in refresh.items("afterAction")) {
            val name = case.str("name")!!
            val old = PluginHostSignal(busyActionId = "a", settleToken = 1)
            val ran = case.str("settle") != "cancelled"
            val new = when (case.str("settle")) {
                "ok" -> PluginHostSignal(settleToken = 2)
                "error" -> PluginHostSignal(error = "余额不足", settleToken = 2)
                "formErrors" -> PluginHostSignal(formErrors = listOf(PluginFormError("amount", PluginFormIssue.Required)), settleToken = 2)
                else -> PluginHostSignal(settleToken = 1)
            }
            val refreshes = pluginSettledRefresh(ran, old, new, visible = case.bool("visible") == true)
            assertEquals(case.obj("expect")!!.bool("refresh"), refreshes, name)
        }
        assertEquals(listOf("pull", "key", "timer", "action", "return"), PluginRefreshReason.entries.map { it.wire })
    }

    @Test fun controlComingBackLandsAndReadsAsTheTableSays() {
        val cases = refresh.items("afterReturn")
        assertTrue(cases.isNotEmpty(), "the shared table lost afterReturn")
        for (case in cases) {
            val name = case.str("name")!!
            val event = when (case.str("event")) {
                "pop" -> PluginReturnEvent.Pop
                "done" -> PluginReturnEvent.Done
                "messageCard" -> PluginReturnEvent.MessageCard
                else -> error("$name: unknown event")
            }
            val got = pluginAfterReturn(event, origin = case.bool("origin") == true)
            val expect = case.obj("expect")!!
            assertEquals(expect.bool("refresh"), got.refresh != null, "$name refresh")
            expect.str("reason")?.let { assertEquals(it, got.refresh?.wire, "$name reason") }
            assertEquals(expect.str("page"), got.landing.name.lowercase(), "$name page")
        }
    }

    @Test fun doneLandsOnTheNearestDataPageBelow() {
        val cases = refresh.items("doneTarget")
        assertTrue(cases.isNotEmpty(), "the shared table lost doneTarget")
        for (case in cases) {
            val stack = case.strings("stack").map { kind ->
                when (kind) {
                    "overview" -> PluginPageArchetype.Overview
                    "records" -> PluginPageArchetype.Records
                    "task" -> PluginPageArchetype.Task
                    // A result page is not an archetype a host lands on.
                    "result" -> null
                    else -> error("${case.str("name")}: unknown archetype $kind")
                }
            }
            val target = case.obj("expect")!!["target"] as? Number
            assertEquals(target?.toInt(), pluginDoneTarget(stack), case.str("name"))
        }
    }

    @Test fun aDangerActionAlwaysAsksFirst() {
        // R2 / §12.3: danger confirms whether or not the plugin wrote a confirm.
        val danger = PluginViewAction("close", "关闭钱包", PluginActionStyle.Danger)
        assertIs<PluginActionStep.Confirm>(PluginActionRun(danger, PluginActionPayload.Empty, null).start())
        val plain = PluginViewAction("open", "开户")
        assertIs<PluginActionStep.Emit>(PluginActionRun(plain, PluginActionPayload.Empty, null).start())
    }
}
