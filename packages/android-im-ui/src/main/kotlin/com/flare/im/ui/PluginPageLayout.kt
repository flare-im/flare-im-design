package com.flare.im.ui

// The page rules of docs/plugin-experience.md §2 as plain functions, so the four kits run the same facts
// (`spec/plugin-view-vectors.json` rules.actionRoles, blockBoundInputs, actionDedupe, refreshKey, accountDerivation,
// formPlacement, statusValues, references, result, pageStates, statusCard). The composables only draw what these return.

/** What a top-level action is to its page (R2). */
enum class PluginActionRole { Primary, Danger, Destination, Command }

/** The page shape that decides where its actions go (R2.1–R2.4). */
enum class PluginPageArchetype { Card, Overview, Task, Records }

/** Why a page asks to be read again (R4); the host reads `Return` itself when a page above it pops. */
enum class PluginRefreshReason(val wire: String) { Pull("pull"), Key("key"), Timer("timer"), Action("action"), Return("return") }

/** style danger → danger, primary → primary, a page target without a form → destination, anything else → command. */
internal fun pluginActionRole(action: PluginViewAction): PluginActionRole = when {
    action.style == PluginActionStyle.Danger -> PluginActionRole.Danger
    action.style == PluginActionStyle.Primary -> PluginActionRole.Primary
    action.target?.kind == "page" && action.form.isNullOrEmpty() -> PluginActionRole.Destination
    else -> PluginActionRole.Command
}

/** R6.1: the inputs a protected-media or choices block fills (top level or in a section); never drawn as fields. */
internal fun pluginBoundInputs(view: PluginViewModel): Set<String> = pluginFlatBlocks(view.blocks).mapNotNull {
    when (it) {
        is PluginProtectedMediaBlock -> it.inputName
        is PluginChoicesBlock -> it.inputName
        else -> null
    }
}.toSet()

/** An action whose form lists bound inputs only: its block runs it, it is not a page action (R6.1). */
internal fun pluginIsBlockAction(action: PluginViewAction, bound: Set<String>): Boolean =
    !action.form.isNullOrEmpty() && action.form.all { it in bound }

/** The fields an action's form draws: its inputs without the block-bound ones. */
internal fun pluginFormFields(view: PluginViewModel, action: PluginViewAction, bound: Set<String> = pluginBoundInputs(view)): List<PluginInput> =
    view.formInputs(action).filter { it.id !in bound }

/** R9: of the actions with one label only the first is drawn; the second element says whether any was dropped. */
internal fun pluginDedupeActions(actions: List<PluginViewAction>): Pair<List<PluginViewAction>, Boolean> {
    val seen = HashSet<String>()
    val kept = actions.filter { seen.add(it.label) }
    return kept to (kept.size != actions.size)
}

/**
 * The page's top-level actions in declared order: the view's actions (and on a page its menu actions after them),
 * without block actions, each label once. A card keeps its menu actions apart (they open from its ⋯ key).
 */
internal fun pluginTopLevelActions(view: PluginViewModel, embedded: Boolean): List<PluginViewAction> {
    val bound = pluginBoundInputs(view)
    val declared = if (embedded) view.actions + PluginViewFormat.menuActions(view) else view.actions
    return pluginDedupeActions(declared.filterNot { pluginIsBlockAction(it, bound) }).first
}

/** Block kinds a page with one form may draw beside it and still be that form's editor ("页内表单"). */
private val PLUGIN_INLINE_FORM_BLOCKS = setOf("note", "text", "steps", "banner", "fields", "status", "time", "choices", "protected-media", "section")

/**
 * The page's own form (R6 "页内表单"): the one top-level action that draws form fields, on a page without a
 * presentation whose blocks only explain it; null otherwise. Block-bound inputs never count (R6.1).
 */
internal fun pluginPageInlineFormActionId(view: PluginViewModel, hasAction: Boolean = true): String? {
    if (!view.available || view.presentation != null) return null
    val bound = pluginBoundInputs(view)
    val forms = view.actions.filter { !pluginIsBlockAction(it, bound) && pluginFormFields(view, it, bound).isNotEmpty() }
    if (forms.size != 1) return null
    if (pluginFlatBlocks(view.blocks).any { it.kind !in PLUGIN_INLINE_FORM_BLOCKS }) return null
    return pluginInlineFormAction(view, forms.single().id, hasAction)?.id
}

/** One titled list card of an overview: [group] `common`, `records` or null (one untitled card). */
internal data class PluginActionList(val group: String?, val actions: List<PluginViewAction>)

/** Where each top-level action is drawn (R2): every place is in drawing order; an absent place is empty. */
internal data class PluginActionPlaces(
    val archetype: PluginPageArchetype,
    val quick: List<PluginViewAction> = emptyList(),
    val list: List<PluginActionList> = emptyList(),
    val bar: List<PluginViewAction> = emptyList(),
    val barSecondary: List<PluginViewAction> = emptyList(),
    val header: List<PluginViewAction> = emptyList(),
    val commands: List<PluginViewAction> = emptyList(),
    val more: List<PluginViewAction> = emptyList(),
    val danger: List<PluginViewAction> = emptyList(),
    val footer: List<PluginViewAction> = emptyList(),
    val menu: List<PluginViewAction> = emptyList(),
) {
    /** Every action drawn, once. */
    val all: List<PluginViewAction> get() = quick + list.flatMap { it.actions } + bar + barSecondary + header + commands + more + danger + footer + menu
}

/**
 * The archetype (R2): a card when not embedded; an overview with a hero or stats and at least 4 destinations; a task
 * with an inline form, or without rows, entries or timeline and at most 3 top-level actions, one primary; records
 * otherwise.
 */
internal fun pluginPageArchetype(view: PluginViewModel, embedded: Boolean, inlineFormActionId: String?, topLevel: List<PluginViewAction>): PluginPageArchetype {
    if (!embedded) return PluginPageArchetype.Card
    val flat = pluginFlatBlocks(view.blocks)
    val roles = topLevel.map(::pluginActionRole)
    if (flat.any { it is PluginHeroBlock || it is PluginStatsBlock } && roles.count { it == PluginActionRole.Destination } >= 4) return PluginPageArchetype.Overview
    if (inlineFormActionId != null) return PluginPageArchetype.Task
    val data = flat.any { it is PluginRowsBlock || it is PluginEntriesBlock || it is PluginTimelineBlock }
    if (!data && topLevel.size <= 3 && PluginActionRole.Primary in roles) return PluginPageArchetype.Task
    return PluginPageArchetype.Records
}

/** Places for [view]'s top-level actions (rules.actionRoles); [except] are drawn elsewhere (a status card's key). */
internal fun pluginActionPlaces(
    view: PluginViewModel,
    embedded: Boolean,
    inlineFormActionId: String? = null,
    except: Set<String> = emptySet(),
): PluginActionPlaces {
    val all = pluginTopLevelActions(view, embedded).filter { it.id !in except }
    val archetype = pluginPageArchetype(view, embedded, inlineFormActionId, all)
    // §6.3 (Vue flarePluginActionPlaces): a capture action writing `into` an input of the inline form is that input's
    // slot, not a key.
    val inlineForm = inlineFormActionId?.let { id -> view.actions.firstOrNull { it.id == id }?.form }.orEmpty()
    val topLevel = all.filterNot { it.target?.kind == "native" && it.target.into != null && it.target.into in inlineForm }
    fun of(role: PluginActionRole) = topLevel.filter { pluginActionRole(it) == role }
    val danger = of(PluginActionRole.Danger)
    // A command that declares a group is always a list item (more on task and records pages), never a quick,
    // barSecondary or commands key — the same rule as the other kits.
    fun key(action: PluginViewAction) = pluginActionRole(action).let { r -> r == PluginActionRole.Primary || (r == PluginActionRole.Command && action.group == null) }
    return when (archetype) {
        PluginPageArchetype.Card -> {
            val ordered = of(PluginActionRole.Primary) + topLevel.filter { pluginActionRole(it) != PluginActionRole.Primary }
            PluginActionPlaces(archetype, footer = ordered.take(3), menu = PluginViewFormat.menuActions(view) + ordered.drop(3))
        }
        PluginPageArchetype.Overview -> {
            val quick = of(PluginActionRole.Primary).take(2) + of(PluginActionRole.Command).filter { it.group == null }.take(2)
            val rest = topLevel.filter { it !in quick && pluginActionRole(it) != PluginActionRole.Danger }
            PluginActionPlaces(archetype, quick = quick, list = pluginActionLists(rest), danger = danger)
        }
        PluginPageArchetype.Task -> {
            val bar = of(PluginActionRole.Primary).take(1)
            val secondary = topLevel.filter { it !in bar && key(it) }.take(2)
            val more = topLevel.filter { it !in bar && it !in secondary && pluginActionRole(it) != PluginActionRole.Danger }
            PluginActionPlaces(archetype, bar = bar, barSecondary = secondary, more = more, danger = danger)
        }
        PluginPageArchetype.Records -> {
            val header = of(PluginActionRole.Primary).take(1)
            val commands = topLevel.filter { it !in header && key(it) }
            val more = topLevel.filter { it !in header && it !in commands && pluginActionRole(it) != PluginActionRole.Danger }
            PluginActionPlaces(archetype, header = header, commands = commands, more = more, danger = danger)
        }
    }
}

/** R2.1: [actions] as list cards: by `group` (common, then records) when any declares one, else one untitled card. */
internal fun pluginActionLists(actions: List<PluginViewAction>): List<PluginActionList> =
    if (actions.any { it.group != null }) listOf(
        PluginActionList("common", actions.filter { it.group != "records" }),
        PluginActionList("records", actions.filter { it.group == "records" }),
    ).filter { it.actions.isNotEmpty() } else listOfNotNull(actions.takeIf { it.isNotEmpty() }?.let { PluginActionList(null, it) })

/** A list row ends with chevron-right only when it goes somewhere (a destination). */
internal fun pluginActionChevron(action: PluginViewAction): Boolean = pluginActionRole(action) == PluginActionRole.Destination

/** The kit copy of a list card's title: the group's, more actions, or none. */
internal fun pluginActionListTitle(group: String?, strings: FlareStrings): String? = when (group) {
    "common" -> strings.pluginViewGroupCommon
    "records" -> strings.pluginViewGroupRecords
    else -> null
}

/**
 * R1: whether a loaded page draws the refresh key (and pull to refresh): a data page — rows, entries, stats, hero,
 * timeline or people (top level or in a section), a status block or a field — that is not a task, has no result
 * block and no presentation renderer other than account.
 */
internal fun pluginPageIsDataPage(view: PluginViewModel, archetype: PluginPageArchetype): Boolean {
    if (!view.available || archetype == PluginPageArchetype.Task) return false
    val renderer = view.presentation?.get("renderer") as? String
    if (view.presentation != null && renderer != "account") return false
    val flat = pluginFlatBlocks(view.blocks)
    if (flat.any { it is PluginResultBlock }) return false
    return view.fields.isNotEmpty() || flat.any {
        it is PluginRowsBlock || it is PluginEntriesBlock || it is PluginStatsBlock || it is PluginHeroBlock ||
            it is PluginTimelineBlock || it is PluginPeopleBlock || it is PluginStatusBlock ||
            (it is PluginFieldsBlock && it.fields.isNotEmpty())
    }
}

/**
 * R12: the page appearance. [requested] wins; absent, account when the presentation renderer is account, or with no
 * presentation a section holding a maskable amount hero without actions and exactly one rows block of at least 2
 * columns; document otherwise. Hosts never choose it by plugin id.
 */
internal fun pluginPageAppearance(requested: FlarePluginPageAppearance?, view: PluginViewModel?): FlarePluginPageAppearance {
    if (requested != null) return requested
    if (view == null) return FlarePluginPageAppearance.Document
    if (view.presentation != null) {
        return if (view.presentation["renderer"] == "account") FlarePluginPageAppearance.Account else FlarePluginPageAppearance.Document
    }
    return if (pluginAccountHead(view) != null) FlarePluginPageAppearance.Account else FlarePluginPageAppearance.Document
}

/** The section and hero an account document is derived from, or null when the view is not that shape. */
private fun pluginAccountHead(view: PluginViewModel): Pair<PluginSectionBlock, PluginHeroBlock>? {
    val head = view.blocks.filterIsInstance<PluginSectionBlock>().firstOrNull { section ->
        section.blocks.any { it is PluginHeroBlock && it.amount && it.maskable }
    } ?: return null
    val hero = head.blocks.first { it is PluginHeroBlock && it.amount && it.maskable } as PluginHeroBlock
    if (hero.actions.isNotEmpty()) return null
    val rows = view.blocks.filterIsInstance<PluginRowsBlock>()
    if (rows.size != 1 || rows.single().columns.size < 2) return null
    return head to hero
}

/**
 * A structurally derived account (R12) as the account renderer reads it (Vue `flareAccountDocument`): the hero and the
 * stats become the leading fields, the section's other blocks and the rest stay, and a `wallet` presentation names the
 * first two primary page actions. A view with a presentation, or not of that shape, is returned as it is.
 */
internal fun pluginAccountDocument(view: PluginViewModel): PluginViewModel {
    if (view.presentation != null) return view
    val (head, hero) = pluginAccountHead(view) ?: return view
    val stats = head.blocks.filterIsInstance<PluginStatsBlock>().flatMap { it.items }
    val primary = view.actions.filter {
        it.style == PluginActionStyle.Primary && it.target?.kind == "page" && it.confirm.isNullOrEmpty() && it.form.isNullOrEmpty()
    }.take(2)
    val rows = view.blocks.filterIsInstance<PluginRowsBlock>().single()
    val entry = rows.actions.singleOrNull()?.takeIf { it.target?.kind == "page" && it.confirm.isNullOrEmpty() && it.form.isNullOrEmpty() }
    return view.copy(
        fields = listOf(PluginViewField(hero.label.orEmpty(), hero.value)) + stats.map { PluginViewField(it.label, it.value) } + view.fields,
        blocks = head.blocks.filter { it !== hero && it !is PluginStatsBlock } + view.blocks.filter { it !== head },
        presentation = mapOf(
            "renderer" to "account",
            "props" to buildMap<String, Any?> {
                put("layout", "wallet")
                put("summaryTitle", head.label?.takeIf { it.isNotEmpty() } ?: view.title)
                entry?.let { put("rowEntryAction", it.id) }
            },
            "actions" to primary.mapIndexed { i, action -> (if (i == 0) "primary" else "secondary") to action.id }.toMap(),
        ),
    )
}

/** Where an action's form opens (R6): a sheet for at most 4 plain fields, else a page form. */
enum class PluginFormPlacement { Sheet, Page }

internal fun pluginFormPlacement(fields: List<PluginInput>, inline: Boolean): PluginFormPlacement =
    pluginFormPlacementOf(fields.map { it.kind }, inline)

internal fun pluginFormPlacementOf(kinds: List<PluginInputKind>, inline: Boolean): PluginFormPlacement = when {
    inline -> PluginFormPlacement.Page
    kinds.size > 4 -> PluginFormPlacement.Page
    kinds.any { it.isUpload || it == PluginInputKind.Members } -> PluginFormPlacement.Page
    else -> PluginFormPlacement.Sheet
}

/** R6: the counter shows only with a declared limit of at most 200 and something typed. */
internal fun pluginFormCounterShows(maxLength: Int?, length: Int): Boolean = maxLength != null && maxLength <= 200 && length > 0

/** How a select draws (R6): segmented choice cards up to 4 choices, the Select above, a disabled Select with none. */
enum class PluginSelectControl { Cards, Select, Empty }

internal fun pluginSelectControl(choices: Int): PluginSelectControl = when {
    choices == 0 -> PluginSelectControl.Empty
    choices <= 4 -> PluginSelectControl.Cards
    else -> PluginSelectControl.Select
}

/** The help under a select (R6): with no choices the kit's "try again later"; otherwise none. */
internal fun pluginSelectHelp(input: PluginInput, strings: FlareStrings): String? =
    if (pluginSelectControl(input.choices.orEmpty().size) == PluginSelectControl.Empty) strings.pluginViewNoOptionsHelp else null

/** The records skeleton's rows (R8). */
internal const val PLUGIN_RECORDS_SKELETON_ROWS = 6

/** A form with a select of no choices cannot be submitted (R6). */
internal fun pluginFormBlocked(inputs: List<PluginInput>, draft: Map<String, Any?>): Boolean =
    inputs.any { it.visibleIn(draft) && it.kind == PluginInputKind.Select && it.choices.isNullOrEmpty() }

/** What a resolved status value draws as (R3). */
internal sealed interface PluginStatusDraw {
    data class Text(val text: String) : PluginStatusDraw
    /** The kit Tag; [unknown] is the unknown status (its text is the kit's, never the raw value). */
    data class Tag(val text: String, val tone: PluginTone, val unknown: Boolean = false) : PluginStatusDraw
}

/** R3: unmapped → the unknown Tag, neutral; a tone → the Tag; no tone → the text as it is. */
internal fun pluginStatusDraw(text: String, tone: PluginTone?, unmapped: Boolean, strings: FlareStrings): PluginStatusDraw = when {
    unmapped -> PluginStatusDraw.Tag(strings.pluginViewUnknownStatus, PluginTone.Neutral, unknown = true)
    tone != null -> PluginStatusDraw.Tag(text, tone)
    else -> PluginStatusDraw.Text(text)
}

/** R3: reference fields (fund orders, payment proofs, external ids) fold under References after the others. */
internal fun pluginSplitReferences(fields: List<PluginViewField>): Pair<List<PluginViewField>, List<PluginViewField>> =
    fields.partition { it.format !is PluginValueFormat.Reference }

/** R7: the icon a result's tone draws. */
internal fun pluginResultIcon(tone: PluginTone, unmapped: Boolean): String = if (unmapped) "info" else when (tone) {
    PluginTone.Success -> "success"
    PluginTone.Info -> "clock"
    PluginTone.Warning -> "warning"
    PluginTone.Danger -> "error"
    PluginTone.Neutral -> "info"
}

/** R7: a pending result reads the page again every 3 s for at most 60 s. */
internal const val PLUGIN_RESULT_POLL_MS = 3_000L
internal const val PLUGIN_RESULT_POLL_FOR_MS = 60_000L

internal fun pluginResultPolls(block: PluginResultBlock): Boolean = block.state == "pending" && !block.unmapped

/** R7: what a result says once to a screen reader: its title (the unknown status when unmapped) and description. */
internal fun pluginResultAnnouncement(block: PluginResultBlock, strings: FlareStrings): String =
    listOfNotNull(if (block.unmapped) strings.pluginViewUnknownStatus else block.title, block.description).joinToString(" ")

/** The result block a view leads with (top level), if any. */
internal fun pluginResultBlock(view: PluginViewModel): PluginResultBlock? =
    view.blocks.firstNotNullOfOrNull { it as? PluginResultBlock }

/**
 * 6.1 rules.statusCard: the status card draws for presentation renderer `status.card`, or (structure fallback) when
 * the view's first block is a steps block and a field carries a tone.
 */
internal fun pluginStatusCard(view: PluginViewModel): Boolean {
    if (!view.available) return false
    val renderer = view.presentation?.get("renderer")
    if (renderer == "status.card") return true
    if (view.presentation != null) return false
    return view.blocks.firstOrNull() is PluginStepsBlock && view.fields.any { it.tone != null || it.unmapped }
}

/** What the first load draws (R8): nothing for 300 ms, then the archetype skeleton. */
enum class PluginPageSkeleton { Blank, Overview, Records, Task }

internal const val PLUGIN_SKELETON_DELAY_MS = 300L

/** Before a view the skeleton is the records one (rules.pageStates). */
internal fun pluginPageSkeleton(elapsedMs: Long): PluginPageSkeleton =
    if (elapsedMs < PLUGIN_SKELETON_DELAY_MS) PluginPageSkeleton.Blank else PluginPageSkeleton.Records

/** R8: an empty data block offers the page's create action — the first primary — under its empty state. */
internal fun pluginEmptyCreateAction(view: PluginViewModel): PluginViewAction? =
    pluginTopLevelActions(view, embedded = true).firstOrNull { pluginActionRole(it) == PluginActionRole.Primary }

/** R10: a hidden amount reads as four bullets. */
internal const val PLUGIN_HIDDEN_AMOUNT = "••••"

/** Development builds say once per key what the renderer had to fall back on (an unmapped value, a dropped duplicate). */
internal object PluginDevWarnings {
    private val seen = java.util.Collections.synchronizedSet(HashSet<String>())

    /** True the first time [key] is seen. */
    fun first(key: String): Boolean = seen.add(key)

    fun warn(context: android.content.Context, key: String, message: String) {
        val debuggable = (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (debuggable && first(key)) android.util.Log.w("FlarePluginView", message)
    }
}

/**
 * Everything a page decides before it draws (R2, R7, R8, 6.1): the action places; the result block that replaces
 * them (its view's actions then follow it as secondary keys); the status card and the primary it carries as its key;
 * the create action an empty rows block offers (it then leaves the header).
 */
internal data class PluginPagePlan(
    val places: PluginActionPlaces,
    val result: PluginResultBlock? = null,
    val resultActions: List<PluginViewAction> = emptyList(),
    val statusCard: Boolean = false,
    val statusCardKey: PluginViewAction? = null,
    val emptyCreate: PluginViewAction? = null,
)

internal fun pluginPagePlan(view: PluginViewModel, inlineFormActionId: String?): PluginPagePlan {
    val result = pluginResultBlock(view)
    if (result != null) {
        return PluginPagePlan(PluginActionPlaces(PluginPageArchetype.Records), result, pluginTopLevelActions(view, embedded = true))
    }
    val statusCard = pluginStatusCard(view)
    val key = if (statusCard) pluginEmptyCreateAction(view) else null
    val places = pluginActionPlaces(view, embedded = true, inlineFormActionId = inlineFormActionId, except = setOfNotNull(key?.id))
    val emptyRows = view.blocks.any { it is PluginRowsBlock && PluginViewFormat.rowsOnce(it.rows).isEmpty() }
    val create = places.header.firstOrNull()?.takeIf { emptyRows }
    return PluginPagePlan(
        places = if (create == null) places else places.copy(header = places.header - create),
        statusCard = statusCard,
        statusCardKey = key,
        emptyCreate = create,
    )
}

/**
 * The view a status card draws around (6.1): without the status field (its title), the first text or note (its
 * description), the steps block (drawn across it) and the banners that repeat the status in its own tone.
 */
internal data class PluginStatusCardParts(
    val title: String,
    val tone: PluginTone,
    val unmapped: Boolean,
    val description: String?,
    val steps: PluginStepsBlock?,
    val rest: PluginViewModel,
)

internal fun pluginStatusCardParts(view: PluginViewModel, strings: FlareStrings): PluginStatusCardParts {
    val status = view.fields.firstOrNull { it.tone != null || it.unmapped }
    val tone = if (status?.unmapped == true) PluginTone.Neutral else status?.tone ?: PluginTone.Neutral
    val description = view.blocks.firstOrNull { it is PluginTextBlock || it is PluginNoteBlock }
    val steps = view.blocks.firstOrNull { it is PluginStepsBlock } as? PluginStepsBlock
    val bannerTone = when (tone) {
        PluginTone.Info, PluginTone.Neutral -> PluginBannerTone.Info
        PluginTone.Success -> PluginBannerTone.Success
        PluginTone.Warning -> PluginBannerTone.Warning
        PluginTone.Danger -> PluginBannerTone.Danger
    }
    return PluginStatusCardParts(
        title = if (status?.unmapped == true) strings.pluginViewUnknownStatus else status?.value ?: view.title,
        tone = tone,
        unmapped = status?.unmapped == true,
        description = when (description) {
            is PluginTextBlock -> description.text
            is PluginNoteBlock -> description.text
            else -> null
        },
        steps = steps,
        rest = view.copy(
            fields = view.fields.filter { it !== status },
            blocks = view.blocks.filter { it !== description && it !== steps && !(it is PluginBannerBlock && it.tone == bannerTone && it.action == null) },
        ),
    )
}

/** The icon a status card's tone draws (6.1 table). */
internal fun pluginStatusCardIcon(tone: PluginTone, unmapped: Boolean): String = if (unmapped) "info" else when (tone) {
    PluginTone.Neutral -> "admin"
    PluginTone.Info -> "clock"
    PluginTone.Success -> "success"
    PluginTone.Warning -> "warning"
    PluginTone.Danger -> "error"
}

/**
 * R4 (plugin-refresh-vectors afterAction): an action this view ran settled with no error and no form errors while the
 * page is [visible] (a page another one covers reads itself on return instead).
 */
internal fun pluginSettledRefresh(ran: Boolean, old: PluginHostSignal, new: PluginHostSignal, visible: Boolean): Boolean =
    visible && ran && new.settleToken != old.settleToken && !new.failed

/** What brings control back to a plugin page (plugin-refresh-vectors afterReturn). */
enum class PluginReturnEvent { Pop, Done, MessageCard }

/** Where control lands: the page itself, the page that started the flow, or out of the plugin pages. */
enum class PluginReturnLanding { Self, Origin, Close }

/** The host's move when control comes back ([refresh]: the reason the landing page reads itself with, or none). */
data class PluginReturn(val landing: PluginReturnLanding, val refresh: PluginRefreshReason?)

/**
 * R4 (plugin-refresh-vectors afterReturn): a page above popping lands on this page and reads it again; done lands on
 * the page that started the flow ([origin]) and reads it, or closes without one; an action that sent a message card closes.
 */
fun pluginAfterReturn(event: PluginReturnEvent, origin: Boolean = false): PluginReturn = when (event) {
    PluginReturnEvent.Pop -> PluginReturn(PluginReturnLanding.Self, PluginRefreshReason.Return)
    PluginReturnEvent.Done ->
        if (origin) PluginReturn(PluginReturnLanding.Origin, PluginRefreshReason.Return) else PluginReturn(PluginReturnLanding.Close, null)
    PluginReturnEvent.MessageCard -> PluginReturn(PluginReturnLanding.Close, null)
}

/**
 * §12.1 (plugin-refresh-vectors doneTarget): done on the top page of [stack] (bottom to top, each page's
 * [pluginPageDoneArchetype]) lands on the nearest page below it that is an overview or a records page; null: none,
 * the host closes its plugin pages.
 */
fun pluginDoneTarget(stack: List<PluginPageArchetype?>): Int? =
    (stack.lastIndex - 1 downTo 0).firstOrNull { stack[it] == PluginPageArchetype.Overview || stack[it] == PluginPageArchetype.Records }

/** The archetype a host keeps for a page on its stack (doneTarget): the page's, or null for a result or an unavailable page. */
fun pluginPageDoneArchetype(view: PluginViewModel): PluginPageArchetype? {
    if (!view.available) return null
    val plan = pluginPagePlan(view, pluginPageInlineFormActionId(view))
    return if (plan.result != null) null else plan.places.archetype
}

/** R3: who a development warning names — the page's plugin id and page — provided by [FlarePluginPage]. */
internal val LocalPluginWarnScope = androidx.compose.runtime.staticCompositionLocalOf<String?> { null }

/** R5 (rules.cardHeader): the details key sits in the card head without footer actions, else at the footer's end. */
internal fun pluginCardDetailInHead(footerActions: Int): Boolean = footerActions == 0
