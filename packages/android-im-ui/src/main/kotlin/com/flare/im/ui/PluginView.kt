package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.constrainHeight
import androidx.compose.ui.unit.constrainWidth
import androidx.compose.ui.graphics.compositeOver
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

/**
 * Visual arrangement only; all layouts share the guarded confirmation/form/action runner. [Page] is a plugin page's:
 * each top-level action placed by its role and the page archetype (R2 of docs/plugin-experience.md). [Quick] is the
 * overview card's key row (R2.1): equal widths 48 high on a phone, natural widths of at least
 * `component.actionMinWidth` otherwise. [Groups] is an account's services (R2.1): list cards by `group`, chevrons on
 * destinations only, the danger actions in a centred card of their own.
 */
enum class PluginViewActionLayout { Inline, Compact, List, Page, Quick, Groups }

/** A page header key handed to the view to run (confirm, form, then the action): a new [token] runs it again. */
internal data class PluginExternalRun(val actionId: String, val token: Int)

internal fun pluginInlineFormHeading(value: String?): String? = value?.trim()?.takeIf { it.isNotEmpty() }

/**
 * Plugin card — the core SDK's resolved plugin view drawn as a kit business card. Spec: Message/PluginView
 * (`PluginView`). Render facts follow `spec/plugin-view-vectors.json`.
 *
 * No plugin code, path or URL is executed: actions go out as opaque ids with the viewer's selection or form values
 * ([onAction] (id, payload)) and the host invokes them.
 * - Upgrade required ([PluginUnavailableReason.UpgradeRequired]): the title and [FlarePluginUpgradeNotice] (card) instead
 *   of the reason line — "更新应用后查看" and "去更新" when [upgradeStatus] says a build is offered and the host passes
 *   [onUpdate], else only the copy.
 * - Vocabulary 2 blocks (PluginBlocksExtra.kt): a section's blocks under its collapsible label; stats; a chart; an image
 *   the host resolves ([resolveImage], never a URL in the view); a QR code whose refresh key hands the host the query
 *   ([onQrRefresh]); a hero and a banner whose keys run like the footer keys; steps; a timeline. Fields, stats, heroes
 *   and cells with a `count` or `duration` format draw compact counts and durations in the viewer's words.
 * - Shell: card width `componentRichCardWidth` (within the parent), radius lg, a hairline border and the card shadow; the
 *   title row carries [icon] (a kit icon name). [embedded] drops the shell and the title row (the detail sheet);
 *   [inset] [PluginViewInset.Sheet] pads the view like [PluginForm] (spacing md on top, lg at the sides, xl at the
 *   bottom), so it goes straight into a kit [BottomSheet], and [PluginViewInset.SheetTop] does the same without the bottom
 *   inset for a view with more of the sheet under it (a preface above the form). The inset pads every state: the embedded
 *   body, available or not, and a card shell kept in a sheet (around it). `available` false shows only the title
 *   (embedded, which has no title row: as one line of secondary text).
 * - Actions: style danger → the danger key, primary → the primary key, else the secondary key. `confirm` asks in the kit
 *   [DangerConfirm] first; `form` collects [PluginForm] in the kit [BottomSheet], whose submit emits
 *   `onAction(id, PluginActionPayload(formValues = …))`.
 * - Choices: a single choice submits on tap; a multiple choice toggles a draft submitted by a key named after the block's
 *   action. `maxSelections` caps the draft: once it is full the other options are dimmed and take no taps, the chosen
 *   ones stay tappable, and the footer opens with "最多选 n 项"; a selection above a lowered cap can only shrink. The
 *   submitted options show at once and revert when [error] turns non-empty; a new [view] settles them.
 * - Settling: the host increments [settleToken] once per finished action, after setting that result's [error] and
 *   [formErrors]. A clean result closes the submitted form and keeps an optimistic choice marked until the new view; an
 *   error reverts the choice (an open form stays and shows it); form errors keep the form open with them (a choice it
 *   carries reverts). [busyActionId] leaving the action settles the same way as a fallback; a host that sets and clears
 *   it within one frame settles only through the token.
 * - [busy] disables everything; [busyActionId] too, and spins that action's key. [error] shows at the card's foot.
 * - People and entries name users through [resolveUser]; without an answer the avatar draws initials and the name is the
 *   id's last 4 characters. "See all" (entries with more) calls [onOpenDetail]; the host opens [PluginDetailSheet]. A
 *   view with a detail that no entries block offers gets a quiet text key beside its actions (or in its header)
 *   (not embedded, and only with [onOpenDetail]), disabled while busy.
 * - Badges (an entry's or a row's `badge`) draw as the kit tag in their tone: an entry reads number, avatar, name, "me",
 *   badge, text; a row leads its first line with it.
 * - Rows (a plugin page's list): one item per key — the badge and the first cell, the other cells joined with " · ", the
 *   row's action keys — whose actions emit `onAction(id, PluginActionPayload(row = …))` after their confirm and form.
 * - Time is formatted in the device zone (`pluginViewDateTimeFormat`); a countdown redraws every second under an hour and
 *   every minute otherwise.
 * - Protocol v2 (spec/plugin-view-vectors.json rules.menuActions, entriesGrouped, unavailableReason, shell): the view's
 *   `menuActions` open from a ⋯ key at the end of the title row (an embedded view draws them as keys after its
 *   actions) and run exactly like a key — confirm, then form, then the action. A grouped entries block puts a header row
 *   ("火锅 · 3 票 · 38%") before each group and tags the [viewerId]'s row "me". `unavailableReason` adds its line under
 *   the title, led by [displayName]; a read-only copy (`unbound_copy`) keeps its content, acts on nothing and closes with
 *   its own line.
 * - The shell is the message's card surface: the timeline draws no bubble around it. A quoted reply goes in the shell's
 *   [quote] slot, above the title row (a card message row passes its quote by itself).
 */
@Composable
fun PluginView(
    view: PluginViewModel,
    icon: String? = null,
    busy: Boolean = false,
    busyActionId: String? = null,
    error: String? = null,
    embedded: Boolean = false,
    /** Where the view sits: none, the bottom sheet's insets ([PluginForm]'s), or those without the bottom one. */
    inset: PluginViewInset = PluginViewInset.None,
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    members: List<PluginMember> = emptyList(),
    formErrors: List<PluginFormError> = emptyList(),
    /** The host's settle signal: incremented once per finished action, after that result's [error] / [formErrors]. */
    settleToken: Int = 0,
    /** The card envelope's displayName (the plugin's name), leading the unavailable reason line. */
    displayName: String? = null,
    /** The viewer's user id: entries of that user carry the "me" tag. */
    viewerId: String? = null,
    /** A quoted reply drawn inside the shell, above the title row; a card message row passes its own. */
    quote: (@Composable () -> Unit)? = LocalFlareCardQuote.current,
    actionLayout: PluginViewActionLayout = PluginViewActionLayout.Inline,
    /** Hide only the outer banner; the error still settles the form and remains visible in an active form. */
    showError: Boolean = true,
    labelRows: Boolean = false,
    inlineFormActionId: String? = null,
    /** Optional heading before an eligible inline form, using the primary pane width only when metadata is nonblank. */
    inlineFormTitle: String? = null,
    /** Optional supporting text below the inline form heading; blank metadata preserves the existing form layout. */
    inlineFormDescription: String? = null,
    fileStates: Map<String, PluginFileState> = emptyMap(),
    onFileAction: ((PluginFileAction) -> Unit)? = null,
    onAction: ((String, PluginActionPayload) -> Unit)? = null,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    onInteractionChanged: ((Boolean) -> Unit)? = null,
    onOpenDetail: (() -> Unit)? = null,
    /** `update.plugin_upgrade_status` for `view.minBuild`, on an upgrade-required view ([FlarePluginUpgradeNotice]). */
    upgradeStatus: PluginUpgradeStatus? = null,
    /** The update flow is opening. */
    upgradeBusy: Boolean = false,
    /** Opens the update flow; without it the notice shows only its copy. */
    onUpdate: (() -> Unit)? = null,
    /** The address of an image block's picture (a package asset or a private upload); null: none. Never in the view. */
    resolveImage: (suspend (PluginImageSource) -> String?)? = null,
    /** A QR block's refresh key: the host runs the query and passes back a view with the fresh code. */
    onQrRefresh: ((PluginQrRefresh) -> Unit)? = null,
    /** Location inputs: the host's fix, a running locate or a failure, by input id. */
    locationStates: Map<String, PluginLocationState> = emptyMap(),
    /** A location input's locate or clear key: the host runs the page's locationOnce action into the input. */
    onLocationAction: ((PluginLocationAction) -> Unit)? = null,
    /** What the host has for each protected media item, by item id (the read's https grant address). */
    protectedMedia: Map<String, PluginProtectedMediaState> = emptyMap(),
    /** A protected media read: the host runs and audits it, then fills [protectedMedia] ([FlarePluginProtectedMedia.url]). */
    onProtectedMediaRead: ((PluginProtectedMediaRead) -> Unit)? = null,
    /** The host is offline: every action waits (not hidden) and the primary says it is available online (R8). */
    offline: Boolean = false,
    /** A result view's done key (R7). */
    onDone: (() -> Unit)? = null,
) = PluginViewContent(
    view = view, icon = icon, busy = busy, busyActionId = busyActionId, error = error, embedded = embedded, inset = inset,
    resolveUser = resolveUser, members = members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,  formErrors = formErrors, settleToken = settleToken, displayName = displayName,
    viewerId = viewerId, quote = quote, onAction = onAction, onOpenDetail = onOpenDetail, list = null, actionLayout = actionLayout, showError = showError, labelRows = labelRows, inlineFormActionId = inlineFormActionId, inlineFormTitle = inlineFormTitle, inlineFormDescription = inlineFormDescription,
    fileStates = fileStates, onFileAction = onFileAction, onInteractionChanged = onInteractionChanged,
    upgradeStatus = upgradeStatus, upgradeBusy = upgradeBusy, onUpdate = onUpdate, resolveImage = resolveImage, onQrRefresh = onQrRefresh,
    locationStates = locationStates, onLocationAction = onLocationAction, protectedMedia = protectedMedia, onProtectedMediaRead = onProtectedMediaRead,
    offline = offline, onDone = onDone,
)

/**
 * A plugin page's lazy list around an embedded view: the page's own items before ([header]) and after ([footer]) the
 * view, which draws its parts on one primary panel between them.
 */
internal class PluginViewList(
    val state: LazyListState,
    val contentPadding: PaddingValues,
    val header: LazyListScope.() -> Unit,
    val footer: LazyListScope.() -> Unit,
)

/** [PluginView]; with [list] the view's parts are items of a lazy list (a plugin page) instead of a column. */
@OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
internal fun PluginViewContent(
    view: PluginViewModel,
    icon: String?,
    busy: Boolean,
    busyActionId: String?,
    error: String?,
    embedded: Boolean,
    inset: PluginViewInset,
    resolveUser: (suspend (String) -> PluginUser?)?,
    members: List<PluginMember>,
    formErrors: List<PluginFormError>,
    settleToken: Int,
    displayName: String?,
    viewerId: String?,
    quote: (@Composable () -> Unit)?,
    onAction: ((String, PluginActionPayload) -> Unit)?,
    onOpenDetail: (() -> Unit)?,
    list: PluginViewList?,
    actionLayout: PluginViewActionLayout = PluginViewActionLayout.Inline,
    showError: Boolean = true,
    labelRows: Boolean = false,
    inlineFormActionId: String? = null,
    inlineFormTitle: String? = null,
    inlineFormDescription: String? = null,
    fileStates: Map<String, PluginFileState> = emptyMap(),
    onFileAction: ((PluginFileAction) -> Unit)? = null,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    encodeQr: (suspend (String) -> String)? = null,
    qrReceivedAtNanos: Long? = null,
    onInteractionChanged: ((Boolean) -> Unit)? = null,
    upgradeStatus: PluginUpgradeStatus? = null,
    upgradeBusy: Boolean = false,
    onUpdate: (() -> Unit)? = null,
    resolveImage: (suspend (PluginImageSource) -> String?)? = null,
    onQrRefresh: ((PluginQrRefresh) -> Unit)? = null,
    /** Location inputs: the host's fix, a running locate or a failure, by input id. */
    locationStates: Map<String, PluginLocationState> = emptyMap(),
    /** A location input's locate or clear key: the host runs the page's locationOnce action into the input. */
    onLocationAction: ((PluginLocationAction) -> Unit)? = null,
    /** What the host has for each protected media item, by item id (the read's https grant address). */
    protectedMedia: Map<String, PluginProtectedMediaState> = emptyMap(),
    /** A protected media read: the host runs and audits it, then fills [protectedMedia] ([FlarePluginProtectedMedia.url]). */
    onProtectedMediaRead: ((PluginProtectedMediaRead) -> Unit)? = null,
    /** The host is offline: every action waits (not hidden) and the primary says it is available online (R8). */
    offline: Boolean = false,
    /** A result page's done key (R7). */
    onDone: (() -> Unit)? = null,
    /** A page header key's run ([PluginViewActionLayout.Page]). */
    externalRun: PluginExternalRun? = null,
    /** An action this view ran settled with no error and no form errors (R4: the page reads itself again). */
    onSettled: (() -> Unit)? = null,
    /** The view is the one shown (R4: only then does a clean settle call [onSettled]). */
    visible: Boolean = true,
    /** A page filter is applied: an empty rows block says so and offers to clear the filters (5.8). */
    onClearFilters: (() -> Unit)? = null,
) {
    // A read-only copy acts on nothing, whatever the host passed.
    val onAction = onAction.takeUnless { PluginViewFormat.readOnly(view) }
    val onOpenDetail = onOpenDetail.takeUnless { PluginViewFormat.readOnly(view) }
    val colors = flareColors()
    val strings = flareStrings()
    val context = androidx.compose.ui.platform.LocalContext.current
    var menuOpen by remember { mutableStateOf(false) }
    // R2: a plugin page places its actions by role and archetype; a card puts its primaries first, three keys, the
    // rest in its ⋯ menu (R2.4). Other embedded uses (a detail sheet, the account renderer) keep the layout they ask.
    val pageLayout = embedded && actionLayout == PluginViewActionLayout.Page
    val cardFooter = !embedded && actionLayout == PluginViewActionLayout.Inline
    val bound = remember(view) { pluginBoundInputs(view) }
    val inlineAction = pluginInlineFormAction(view, inlineFormActionId, onAction != null)
    val plan = if (pageLayout && view.available) pluginPagePlan(view, inlineAction?.id) else null
    val cardPlaces = if (cardFooter && view.available) pluginActionPlaces(view, embedded = false) else null
    val warnScope = LocalPluginWarnScope.current.orEmpty()
    if (view.available && pluginDedupeActions(if (embedded) view.actions + view.menuActions else view.actions).second) {
        PluginDevWarnings.warn(context, "dupe:$warnScope:${view.title}", "Plugin view \"${view.title}\" ($warnScope) declares visible actions with one label; the first is drawn")
    }
    val menuActions = cardPlaces?.menu ?: PluginViewFormat.menuActions(view)
    val reasonLine = PluginViewFormat.reasonLine(view, displayName, strings)
    var interaction by remember { mutableStateOf(PluginChoicesInteraction()) }
    var users by remember { mutableStateOf<Map<String, PluginUser>>(emptyMap()) }
    var confirming by remember { mutableStateOf<PluginActionRun?>(null) }
    var formRun by remember { mutableStateOf<PluginActionRun?>(null) }
    // A page action's native target handed to the form holding its `into` input.
    var nativeRequest by remember { mutableStateOf<PluginNativeIntoRequest?>(null) }
    var formSubmitted by remember { mutableStateOf(false) }
    // A native request belongs to the form it was handed to: a form opened later starts without it.
    LaunchedEffect(formRun == null) { if (formRun == null) nativeRequest = null }
    // The inline form's submit drawn as a place key (the task bar): a tap asks the form to submit itself.
    var inlineSubmitToken by remember(inlineAction?.id) { mutableStateOf(0) }
    var inlineSubmitState by remember(inlineAction?.id) { mutableStateOf(PluginFormSubmitState()) }
    var pageFormSubmitToken by remember { mutableStateOf(0) }
    var pageFormSubmitState by remember { mutableStateOf(PluginFormSubmitState()) }
    // R4: an action this view handed over; its clean settle asks the page to read itself again.
    var ran by remember { mutableStateOf(false) }
    // R8: a failure banner the viewer closed stays closed for that failure.
    var dismissedError by remember { mutableStateOf<String?>(null) }
    SideEffect { onInteractionChanged?.invoke(confirming != null || formRun != null || inlineAction != null || menuOpen) }
    var inlineForm by remember(inlineAction?.id) { mutableStateOf(PluginInlineFormState()) }
    // The rows action last handed over, as (action id, row key): only that row's key spins while the action runs.
    var rowRun by remember { mutableStateOf<Pair<String, String>?>(null) }
    val locked = busy || busyActionId != null || inlineForm.pending || PluginViewFormat.readOnly(view) || offline
    val failure = error?.takeIf { it.isNotEmpty() }
    val formPending = formRun?.let { busy || busyActionId == it.action.id } ?: false
    val emitAction by rememberUpdatedState(onAction)
    // Rows write their times against the moment the view arrived (the year shows only outside the current one), on the
    // server's clock like every other plugin time (spec/server-clock-vectors.json).
    val nowMs = remember(view) { FlareServerClock.nowMs() }

    // A new view is the truth.
    PluginOnChange(view) { _, _ -> interaction = interaction.viewChanged() }
    // The host's signals compared whole, so an error set in the same frame as the settle is read: a failure reverts the
    // optimistic choice; a settle closes the submitted form unless it came back with errors.
    PluginOnChange(PluginHostSignal(busy, busyActionId, error, formErrors, settleToken)) { old, new ->
        interaction = interaction.hostChanged(old, new)
        inlineAction?.let { inlineForm = inlineForm.settle(old, new, it.id) }
        if (ran && new.settleToken != old.settleToken) {
            if (pluginSettledRefresh(ran, old, new, visible)) onSettled?.invoke()
            ran = false
        }
        val request = formRun
        if (request != null && formSubmitted && pluginFormSettle(old, new, request.action.id) == PluginFormSettle.Close) {
            formRun = null
            formSubmitted = false
        }
    }
    val ids = PluginViewFormat.userIds(view)
    LaunchedEffect(ids, resolveUser) {
        val resolve = resolveUser ?: return@LaunchedEffect
        val found = pluginResolvedUsers(ids, users, resolve)
        if (found.isNotEmpty()) users = users + found
    }

    fun emit(request: PluginActionRun, payload: PluginActionPayload) {
        val selection = payload.selection
        if (request.block != null && selection != null) {
            interaction = interaction.submitted(request.block, request.action.id, selection)
        }
        payload.row?.let { rowRun = request.action.id to it.key }
        ran = true
        emitAction?.invoke(request.action.id, payload)
    }

    fun advance(step: PluginActionStep) {
        when (step) {
            is PluginActionStep.Confirm -> confirming = step.run
            is PluginActionStep.Form -> {
                formSubmitted = false
                formRun = step.run
            }
            is PluginActionStep.Emit -> emit(step.run, step.payload)
        }
    }

    /** Confirm, then collect the form, then hand the action over. */
    fun run(action: PluginViewAction, payload: PluginActionPayload, block: Int? = null) {
        // R2.5: an action that says why it cannot run now does not run.
        if (locked || emitAction == null || action.disabledReason != null) return
        // A native target writing `into` an input of a form on this view (the inline form or the open form sheet)
        // runs through that input's own key, so the host's answer is written into the form's current scope.
        val target = action.target
        if (payload.row == null && target != null) {
            val forms = listOfNotNull(inlineAction, formRun?.action)
            val takes = forms.any { form ->
                view.formInputs(form).any { input ->
                    when (pluginNativeIntoKey(target, input)) {
                        "file" -> onFileAction != null
                        "location" -> onLocationAction != null
                        else -> false
                    }
                }
            }
            if (takes) {
                nativeRequest = PluginNativeIntoRequest(target)
                return
            }
            // The input belongs to another action's form that is not open (a page's capture keys beside its submit):
            // open that form and run the target through the input's key there, so the answer lands in its scope.
            val holder = if (formRun == null) view.actions.firstOrNull { other ->
                other.id != action.id && view.formInputs(other).any { input ->
                    when (pluginNativeIntoKey(target, input)) {
                        "file" -> onFileAction != null
                        "location" -> onLocationAction != null
                        else -> false
                    }
                }
            } else null
            if (holder != null) {
                nativeRequest = PluginNativeIntoRequest(target)
                advance(PluginActionRun(holder, PluginActionPayload.Empty, block).start())
                return
            }
        }
        advance(PluginActionRun(action, payload, block).start())
    }

    val keys = when {
        plan != null -> emptyList()
        cardPlaces != null -> cardPlaces.footer.filter { it.id != inlineAction?.id }
        else -> PluginViewFormat.keys(view, embedded).filter { it.id != inlineAction?.id }
    }
    val detailKey = PluginViewFormat.detailKey(view, embedded, onOpenDetail != null, busy, busyActionId)
    // The body a page draws: a result's fields go into the result view, a status card takes what it says itself.
    val statusCardParts = if (plan?.statusCard == true) pluginStatusCardParts(view, strings) else null
    val bodyView = when {
        plan?.result != null -> view.copy(fields = emptyList(), blocks = view.blocks.filterNot { it is PluginResultBlock })
        statusCardParts != null -> statusCardParts.rest
        else -> view
    }
    val pageFailure = failure.takeIf { pageLayout && showError && it != dismissedError }
    val parts = pluginViewParts(bodyView, embedded, quote != null, reasonLine, keys, detailKey,
        failure.takeIf { showError && inlineAction == null && !pageLayout }, strings, nowMs).toMutableList().apply {
        if (inlineAction != null) {
            val footer = indexOfFirst { it is PluginViewPart.Keys || it is PluginViewPart.Error }
            add(if (footer < 0) size else footer, PluginViewPart.InlineForm)
        }
        // R2.1: the overview's quick keys close the card that holds its hero or stats.
        if (plan != null && plan.places.quick.isNotEmpty()) {
            val head = indexOfFirst { part ->
                part is PluginViewPart.Block && (part.block is PluginHeroBlock || part.block is PluginStatsBlock ||
                    (part.block is PluginSectionBlock && part.block.blocks.any { it is PluginHeroBlock || it is PluginStatsBlock }))
            }
            add(head + 1, PluginViewPart.Quick)
        }
    }
        .filterNot { it is PluginViewPart.DetailKey }
    val phone = flareCompactOverlays()
    val offlineCaption = strings.pluginViewAvailableOnline.takeIf { offline }
    /** A place key: the inline form's action submits that form; any other runs (confirm, form, then the action). */
    val runPlace: (PluginViewAction) -> Unit = { action ->
        if (inlineAction != null && action.id == inlineAction.id) { if (!locked) inlineSubmitToken++ }
        else run(action, PluginActionPayload.Empty)
    }
    PluginOnChange(externalRun) { _, request ->
        if (request != null) (view.actions + view.menuActions).firstOrNull { it.id == request.actionId }?.let(runPlace)
    }
    val detail: @Composable () -> Unit = {
        // R5: 13 secondary text and chevron-right 16, a target of at least 44.
        Button(label = strings.pluginViewDetail, variant = FlareButtonVariant.Quiet, size = FlareControlSize.Sm,
            disabled = detailKey != true, appearance = FlareButtonAppearance.Text, onClick = onOpenDetail, maintainTouchTarget = true) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                Text(strings.pluginViewDetail, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
                FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textSecondary)
            }
        }
    }
    val formTitle = pluginInlineFormHeading(inlineFormTitle)
    val formDescription = pluginInlineFormHeading(inlineFormDescription)

    /** One block: a top-level one at its position, or a section's child at [PluginView]'s child position. */
    @Composable
    fun drawBlock(index: Int, block: PluginBlock) {
        when (block) {
            is PluginTextBlock -> PluginTextBlockView(block)
            is PluginFieldsBlock -> PluginFieldList(block.fields, view.title)
            is PluginChoicesBlock -> {
                val interactive = onAction != null && interaction.isInteractive(block, index, locked)
                PluginChoicesBlockView(
                    block = block,
                    shown = interaction.shown(block, index),
                    interactive = interactive,
                    held = if (interactive) block.options.filter { interaction.capped(block, index, it.index) }.map { it.index }.toSet() else emptySet(),
                    submitEnabled = interaction.submitEnabled(block, index),
                    submitLoading = block.action != null && block.action.id == busyActionId,
                    onPick = { option ->
                        val action = block.action
                        if (action != null) {
                            val (next, selection) = interaction.tap(block, index, option, locked)
                            interaction = next
                            if (selection != null) run(action, PluginActionPayload(selection = selection), index)
                        }
                    },
                    onSubmit = {
                        val action = block.action
                        val selection = interaction.submission(block, index, locked)
                        if (action != null && selection != null) run(action, PluginActionPayload(selection = selection), index)
                    },
                )
            }
            is PluginEntriesBlock -> PluginEntriesBlockView(block, users, viewerId, onOpenDetail)
            is PluginPeopleBlock -> PluginPeopleBlockView(block, users)
            is PluginStatusBlock -> PluginStatusBlockView(block, view.title)
            is PluginProgressBlock -> PluginProgressBlockView(block)
            is PluginTimeBlock -> PluginTimeBlockView(block)
            is PluginDividerBlock -> Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
            // R1: a section's info note is its caption (a section child's position is pluginSectionChildIndex's).
            is PluginNoteBlock -> PluginNoteBlockView(block, inSection = index >= 1000)
            is PluginSectionBlock -> PluginSectionBlockView(block) { child, item -> drawBlock(pluginSectionChildIndex(index, child), item) }
            is PluginStatsBlock -> PluginStatsBlockView(block)
            is PluginChartBlock -> PluginChartBlockView(block)
            is PluginImageBlock -> PluginImageBlockView(block, resolveImage)
            is PluginQrBlock -> PluginQrBlockView(block, onQrRefresh.takeUnless { PluginViewFormat.readOnly(view) }, locked)
            is PluginHeroBlock -> PluginHeroBlockView(block, busyActionId, locked,
                if (onAction == null) null else ({ action: PluginViewAction -> run(action, PluginActionPayload.Empty) }))
            is PluginStepsBlock -> PluginStepsBlockView(block)
            is PluginBannerBlock -> PluginBannerBlockView(block, locked,
                if (onAction == null) null else ({ action: PluginViewAction -> run(action, PluginActionPayload.Empty) }))
            is PluginTimelineBlock -> PluginTimelineBlockView(block)
            is PluginProtectedMediaBlock -> PluginProtectedMediaBlockView(block, protectedMedia, locked,
                onProtectedMediaRead.takeUnless { PluginViewFormat.readOnly(view) })
            // Rows are drawn row by row (PluginViewPart.Row).
            is PluginRowsBlock -> Unit
            else -> Unit
        }
    }

    val drawPart: @Composable (PluginViewPart) -> Unit = { part ->
        when (part) {
            PluginViewPart.InlineForm -> inlineAction?.let { action -> key(action.id, inlineForm.revision) {
                // R6: a page's own form is a column of component.formColumnWidth at the start.
                Column(Modifier.then(when {
                    pageLayout -> Modifier.widthIn(max = FlareSizes.componentFormColumnWidth)
                    formTitle != null || formDescription != null -> Modifier.widthIn(max = FlareSizes.primaryPaneMaxWidth)
                    else -> Modifier
                }).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    formTitle?.let {
                        Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() })
                    }
                    formDescription?.let {
                        Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
                    }
                PluginForm(inputs = pluginFormFields(view, action, bound), errors = if (inlineForm.submitted) formErrors else emptyList(),
                    submitLabel = action.label, busy = locked, error = failure.takeUnless { pageLayout }, members = members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,  embedded = true,
                    hideSubmit = plan != null && plan.places.all.any { it.id == action.id },
                    submitToken = inlineSubmitToken, onSubmitState = { inlineSubmitState = it },
                    fileStates = fileStates, onFileAction = onFileAction,
                    locationStates = locationStates, onLocationAction = onLocationAction,
                    nativeRequest = nativeRequest,
                    onSubmit = { values ->
                        if (!locked && pluginInlineFormAction(view, action.id, emitAction != null) != null) {
                            val next = inlineForm.begin()
                            if (next != null) { inlineForm = next; advance(PluginActionRun(action, PluginActionPayload.Empty, null).submitted(values)) }
                        }
                    })
                }
            } }
            // The quote slot: a reply's quote sits inside the shell, above the title row; nothing nested inherits it.
            PluginViewPart.Quote -> quote?.invoke()
            // The row spans the card and the title takes what the icon and the ⋯ key leave, so the key sits at the
            // trailing edge whatever the title's length (spec rules.menuActions). Two weights here would split the
            // spare width between the title and a spacer and leave the key in the middle.
            PluginViewPart.TitleRow -> Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                if (icon != null && icon in flareIconNames) FlareIcon(icon, size = FlareSizes.iconSizeSm, tint = colors.primaryText)
                // R5: one line, ellipsized; with the row's xs gap its end padding keeps sm before the details key.
                Text(view.title, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.Medium,
                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f).padding(end = FlareSizes.spacingXs).semantics { heading() })
                if (detailKey != null && pluginCardDetailInHead(keys.size)) detail()
                if (menuActions.isNotEmpty()) {
                    // R5: the ⋯ key is the kit IconButton sm; the row keeps the disc's height, the target reaches past it.
                    Box(Modifier.flareTouchTargetBeyond(FlareSizes.componentIconButtonSideSm)) {
                        IconButton(
                            icon = "more",
                            contentDescription = strings.pluginViewMore,
                            size = FlareControlSize.Sm,
                            disabled = locked || onAction == null,
                            onClick = { menuOpen = true },
                        )
                        ActionMenu(
                            expanded = menuOpen,
                            items = menuActions.map { action ->
                                FlareActionItem(id = action.id, label = action.label, danger = action.style == PluginActionStyle.Danger)
                            },
                            onDismiss = { menuOpen = false },
                            onSelect = { id -> menuActions.firstOrNull { it.id == id }?.let { run(it, PluginActionPayload.Empty) } },
                            label = strings.pluginViewMore,
                        )
                    }
                }
            }
            is PluginViewPart.Line -> Text(
                part.text,
                color = if (part.quiet) colors.textTertiary else colors.textSecondary,
                fontSize = if (part.quiet) FlareSizes.fontSizeSm else FlareSizes.fontSizeMd,
            )
            is PluginViewPart.Fields -> PluginFieldList(part.fields, view.title)
            PluginViewPart.Quick -> plan?.let { PluginQuickKeys(it.places.quick, phone, busyActionId, locked || onAction == null, offlineCaption, runPlace) }
            is PluginViewPart.Block -> drawBlock(part.index, part.block)
            PluginViewPart.Upgrade -> FlarePluginUpgradeNotice(FlarePluginUpgradeVariant.Card, status = upgradeStatus, busy = upgradeBusy, onUpdate = onUpdate)
            is PluginViewPart.Row -> PluginRowItem(
                block = part.rows,
                row = PluginViewFormat.namedRow(part.row, users),
                divided = !part.first,
                nowMs = nowMs,
                spinning = { action -> busyActionId == action.id && rowRun == (action.id to part.row.key) },
                disabled = locked || onAction == null,
                labelRows = labelRows,
                onRun = { action, bound -> run(action, PluginActionPayload(row = PluginActionRow(part.row.key, bound.input))) },
            )
            // rules.rowsIcon: a records block's empty state carries its icon.
            // 5.8: under a filter the empty state says the filter found nothing and offers to clear it.
            is PluginViewPart.RowsEmpty -> if (plan != null && onClearFilters != null) EmptyState(
                title = strings.pluginViewFilterEmpty, icon = (view.blocks.getOrNull(part.index) as? PluginRowsBlock)?.icon ?: "clock", compact = true,
                actions = { Button(label = strings.pluginViewClearFilter, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm,
                    maintainTouchTarget = true, onClick = onClearFilters) },
            ) else if (plan != null) PluginBlockEmpty(part.text, (view.blocks.getOrNull(part.index) as? PluginRowsBlock)?.icon ?: "clock", plan.emptyCreate, busyActionId,
                locked || onAction == null, runPlace)
                else Text(part.text, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd)
            is PluginViewPart.RowDay -> Text(
                part.text, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth().semantics { heading() },
            )
            is PluginViewPart.Keys -> if (actionLayout == PluginViewActionLayout.Quick) {
                PluginQuickKeys(part.actions, phone, busyActionId, locked || onAction == null, null) { run(it, PluginActionPayload.Empty) }
            } else if (actionLayout == PluginViewActionLayout.Groups) {
                val danger = part.actions.filter { pluginActionRole(it) == PluginActionRole.Danger }
                val off = locked || onAction == null
                // R1: groups stand 2xl apart; the danger card is the last of them.
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xl)) {
                    pluginActionLists(part.actions - danger.toSet()).forEach { group ->
                        PluginActionListCard(pluginActionListTitle(group.group, strings), group.actions, off, { run(it, PluginActionPayload.Empty) }, busyActionId)
                    }
                    PluginDangerCard(danger, off) { run(it, PluginActionPayload.Empty) }
                }
            } else Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
                if (!embedded) Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
                val keys: @Composable () -> Unit = {
                    part.actions.forEachIndexed { index, action ->
                        val actionColor = if (action.style == PluginActionStyle.Danger) colors.errorText else if (action.style == PluginActionStyle.Primary) colors.primaryText else colors.textSecondary
                        if (actionLayout == PluginViewActionLayout.List && index > 0) Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
                        Button(label = action.label, variant = PluginViewFormat.variant(action),
                            loading = busyActionId == action.id,
                            disabled = (locked && busyActionId != action.id) || onAction == null || action.disabledReason != null,
                            size = if (actionLayout == PluginViewActionLayout.List) FlareControlSize.Md else FlareControlSize.Sm,
                            block = actionLayout == PluginViewActionLayout.List,
                            appearance = if (actionLayout == PluginViewActionLayout.Compact || cardFooter) FlareButtonAppearance.Standard else FlareButtonAppearance.Text,
                            maintainTouchTarget = true,
                            onClick = { run(action, PluginActionPayload.Empty) },
                            content = if (actionLayout != PluginViewActionLayout.List) null else ({
                                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                    Text(action.label, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold,
                                        color = actionColor,
                                        modifier = Modifier.weight(1f))
                                    FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = actionColor)
                                }
                            }))
                    }
                    if (detailKey != null) detail()
                }
                if (actionLayout == PluginViewActionLayout.List) Column(Modifier.fillMaxWidth()) { keys() }
                else PluginActionFooter(trailingDetail = detailKey != null, compact = actionLayout == PluginViewActionLayout.Compact || cardFooter) { keys() }
                // R2.5: why a key waits, under the keys.
                part.actions.mapNotNull { it.disabledReason }.distinct().forEach { PluginCaption(it) }
            }
            // Detail is drawn beside the action keys, or in the header without actions.
            is PluginViewPart.DetailKey -> Unit
            is PluginViewPart.Error -> if (showError) StatusBanner(text = part.text, tone = FlareStatusTone.Danger)
        }
    }

    // A scan code page (`flare.qr`): the code goes above the plain view, which keeps its fields, blocks and actions.
    val qrProps = pluginQrPresentationProps(view)
    if (hasResolvedPresentation(view)) {
        val content: @Composable () -> Unit = {
            quote?.invoke()
            ResolvedPresentation(view, locked, { id -> view.actions.firstOrNull { it.id == id }?.let { run(it, PluginActionPayload.Empty) } },
                busyActionId = busyActionId, error = failure)
            if (PluginViewFormat.readOnly(view) && reasonLine != null) Text(reasonLine, color = colors.textTertiary)
        }
        // In a thread the card keeps its own width, so the message row can put the sender's own card on its side (Vue).
        if (list == null) Column(Modifier.then(if (embedded) Modifier.fillMaxWidth() else Modifier).padding(pluginViewInsetPadding(inset))) { content() }
        else LazyColumn(Modifier.fillMaxSize(), state = list.state, contentPadding = list.contentPadding) {
            list.header(this)
            item(key = "presentation") { content() }
            list.footer(this)
        }
    } else if (list == null) {
        val shape = RoundedCornerShape(FlareSizes.radiusLg)
        // Every state takes the inset; a card shell kept in a sheet takes it around the shell.
        val shell = if (embedded) Modifier.then(if (actionLayout == PluginViewActionLayout.Compact) Modifier else Modifier.fillMaxWidth()).padding(pluginViewInsetPadding(inset)) else Modifier
            .padding(pluginViewInsetPadding(inset))
            .widthIn(max = FlareSizes.componentRichCardWidth)
            .fillMaxWidth()
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderSecondary.copy(alpha = colors.borderSecondary.alpha * 0.6f), shape)
            .padding(FlareSizes.spacingMd)
        Column(shell) {
            qrProps?.let { props ->
                Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingMd)) { PluginQrPresentation(props, qrReceivedAtNanos, encodeQr) }
            }
            parts.forEachIndexed { i, part ->
                key(part.key) {
                    Box(Modifier.then(if (actionLayout == PluginViewActionLayout.Compact) Modifier else Modifier.fillMaxWidth()).padding(top = pluginPartGap(parts.getOrNull(i - 1), part, page = embedded))) { drawPart(part) }
                }
            }
        }
    } else {
        val places = plan?.places
        val resultActions = plan?.resultActions.orEmpty()
        val actionsOff = locked || onAction == null
        // R2.2: a phone task pins its primary over the navigation bar; a wide window keeps it after the body.
        val pinned = places != null && places.archetype == PluginPageArchetype.Task && phone && (places.bar.isNotEmpty() || places.barSecondary.isNotEmpty())
        val formKey = inlineAction?.id
        Column(Modifier.fillMaxSize()) {
        LazyColumn(Modifier.weight(1f).fillMaxWidth(), state = list.state, contentPadding = list.contentPadding) {
            list.header(this)
            // R8: an action's failure at the top, with a close key.
            pageFailure?.let { text ->
                item(key = "page:action-error") {
                    Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingMd)) {
                        StatusBanner(text = text, tone = FlareStatusTone.Danger, dismissible = true, onDismiss = { dismissedError = text })
                    }
                }
            }
            plan?.result?.let { result ->
                item(key = "page:result") {
                    Box(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingLg), contentAlignment = Alignment.TopCenter) {
                        FlareResultView(
                            title = if (result.unmapped) strings.pluginViewUnknownStatus else result.title,
                            tone = if (result.unmapped) PluginTone.Neutral else result.tone,
                            unknown = result.unmapped,
                            amount = result.amount?.let { PluginFormatRules.text(it, result.format, strings) },
                            description = result.description,
                            details = view.fields,
                            // R7: a phone pins done to the bottom (below); a wide window keeps it under the result.
                            onDone = onDone.takeUnless { phone },
                            actions = if (resultActions.isEmpty()) null else ({
                                resultActions.forEach { action ->
                                    Button(label = action.label, variant = if (action.style == PluginActionStyle.Danger) FlareButtonVariant.Danger else FlareButtonVariant.Secondary,
                                        size = FlareControlSize.Lg, block = true, loading = busyActionId == action.id,
                                        disabled = actionsOff && busyActionId != action.id, onClick = { runPlace(action) })
                                }
                            }),
                        )
                    }
                }
            }
            // 6.1: a banner that asks for something (a journal's resolve) stands above the status card.
            val ahead = if (statusCardParts == null) emptyList() else parts.filter { it is PluginViewPart.Block && it.block is PluginBannerBlock && it.block.action != null }
            ahead.forEach { part ->
                item(key = part.key) { Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingLg)) { drawPart(part) } }
            }
            statusCardParts?.let { card ->
                item(key = "page:status-card") {
                    Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingLg)) {
                        PluginStatusCard(card, plan?.statusCardKey, busyActionId, actionsOff, offlineCaption, runPlace)
                    }
                }
            }
            qrProps?.let { props ->
                item(key = "presentation.qr") {
                    Box(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingMd)) { PluginQrPresentation(props, qrReceivedAtNanos, encodeQr) }
                }
            }
            // Keys come from the parts, whose rows are each drawn once: a lazy list rejects a repeated key. A day heading
            // over rows sticks while its rows scroll under it (5.8).
            // R2.1: the overview card (its hero or stats and the quick keys) is a card of its own; the rest is the next one.
            val body = parts - ahead.toSet()
            val cardEnd = body.indexOfFirst { it is PluginViewPart.Quick }
            body.forEachIndexed { i, part ->
                val opens = i == 0 || i == cardEnd + 1 && cardEnd >= 0
                val panel = Modifier.fillMaxWidth().then(if (i == cardEnd + 1 && cardEnd >= 0) Modifier.padding(top = FlareSizes.spacingLg) else Modifier)
                    .pluginPanel(colors.bgPrimary, opens, i == body.lastIndex || i == cardEnd, pluginPartGap(body.getOrNull(i - 1), part))
                if (part is PluginViewPart.RowDay) stickyHeader(key = part.key) { Box(panel) { drawPart(part) } }
                else item(key = part.key) { Box(panel) { drawPart(part) } }
            }
            if (places != null) {
                val gap = Modifier.fillMaxWidth().padding(top = FlareSizes.spacingLg)
                if (places.archetype == PluginPageArchetype.Task && !pinned && (places.bar.isNotEmpty() || places.barSecondary.isNotEmpty())) item(key = "page:task-keys") {
                    Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2xl)) {
                        PluginKeyRow(places.bar, places.barSecondary, busyActionId, actionsOff,
                            inlineSubmitState.caption.takeIf { formKey != null && places.bar.any { it.id == formKey } } ?: offlineCaption, runPlace)
                    }
                }
                if (places.commands.isNotEmpty()) item(key = "page:commands") {
                    Box(gap) { PluginKeyRow(emptyList(), places.commands, busyActionId, actionsOff,
                        offlineCaption.takeIf { places.commands.any { it.style == PluginActionStyle.Primary } }, runPlace) }
                }
                places.list.forEachIndexed { index, group ->
                    item(key = "page:list:$index") {
                        Box(gap) { PluginActionListCard(pluginActionListTitle(group.group, strings), group.actions, actionsOff, runPlace, busyActionId) }
                    }
                }
                if (places.more.isNotEmpty()) item(key = "page:more") {
                    Box(gap) { PluginActionListCard(strings.pluginViewMore, places.more, actionsOff, runPlace, busyActionId) }
                }
                if (places.danger.isNotEmpty()) item(key = "page:danger") {
                    Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2xl)) { PluginDangerCard(places.danger, actionsOff, runPlace) }
                }
            }
            list.footer(this)
        }
        if (plan?.result != null && phone && onDone != null) FlareResultDoneBar(onDone)
        if (pinned && places != null) {
            val primary = places.bar.firstOrNull()
            val isForm = primary != null && primary.id == formKey
            PluginTaskBar(primary, places.barSecondary, busyActionId, actionsOff,
                primaryDisabled = isForm && !inlineSubmitState.enabled,
                caption = (if (isForm) inlineSubmitState.caption else null) ?: offlineCaption,
                onRun = runPlace)
        }
        }
    }

    confirming?.let { request ->
        DangerConfirm(
            title = request.action.label, description = request.action.confirm.orEmpty(), target = "",
            confirmText = request.action.label,
            onConfirm = { confirming = null; advance(request.confirmed()) },
            onCancel = { confirming = null },
        )
    }
    formRun?.let { request ->
        val fields = pluginFormFields(view, request.action, bound)
        val close = { if (!formPending) { formRun = null; formSubmitted = false } }
        // R6: a short plain form is a sheet; a long one, or one with files, documents or members, a whole page.
        if (pluginFormPlacement(fields, inline = false) == PluginFormPlacement.Page) PluginPageForm(
            title = request.action.label, submitLabel = request.action.label, pending = formPending,
            submitState = pageFormSubmitState, onClose = close, onSubmit = { pageFormSubmitToken++ },
        ) {
            PluginForm(
                inputs = fields,
                errors = if (formSubmitted) formErrors else emptyList(),
                busy = formPending,
                error = if (formSubmitted) failure else null,
                members = members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,
                fileStates = fileStates, onFileAction = onFileAction,
                locationStates = locationStates, onLocationAction = onLocationAction,
                nativeRequest = nativeRequest,
                hideSubmit = true, submitToken = pageFormSubmitToken, onSubmitState = { pageFormSubmitState = it },
                onSubmit = { values -> formSubmitted = true; advance(request.submitted(values)) },
            )
        } else BottomSheet(
            onClose = close,
            title = request.action.label,
            dismissible = !formPending,
        ) {
            Column(Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())) {
                PluginForm(
                    inputs = fields,
                    errors = if (formSubmitted) formErrors else emptyList(),
                    busy = formPending,
                    error = if (formSubmitted) failure else null,
                    members = members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,
                    fileStates = fileStates, onFileAction = onFileAction,
                    locationStates = locationStates, onLocationAction = onLocationAction,
                    nativeRequest = nativeRequest,
                    onSubmit = { values -> formSubmitted = true; advance(request.submitted(values)) },
                    onCancel = { if (!formPending) { formRun = null; formSubmitted = false } },
                )
            }
        }
    }
}

/**
 * Where a [PluginView] sits — the padding it gives itself, in every state: [None] leaves it to the host's surface;
 * [Sheet] is the kit bottom sheet's insets — spacing md on top, lg at the sides and xl at the bottom ([PluginForm]'s);
 * [SheetTop] is the top of a sheet with more under it (a preface above [PluginForm]) — md on top, lg at the sides and no
 * bottom inset, so the next part's own top inset is the gap.
 */
enum class PluginViewInset { None, Sheet, SheetTop }

/** The padding of [inset] (spec rules.inset), around whatever the view draws — the card shell included. */
internal fun pluginViewInsetPadding(inset: PluginViewInset): PaddingValues = when (inset) {
    PluginViewInset.None -> PaddingValues(0.dp)
    PluginViewInset.Sheet ->
        PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl)
    PluginViewInset.SheetTop ->
        PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = 0.dp)
}

/** An action on its way out: confirmation and form come first; [block] marks a choices submit. */
internal data class PluginActionRun(val action: PluginViewAction, val payload: PluginActionPayload, val block: Int?) {
    /** The first step: the confirmation when the action asks one or is a danger action (R2: always), else what follows. */
    fun start(): PluginActionStep =
        if (!action.confirm.isNullOrEmpty() || action.style == PluginActionStyle.Danger) PluginActionStep.Confirm(this) else confirmed()

    /** Past the confirmation: the form when the action collects one, else out as it is. */
    fun confirmed(): PluginActionStep =
        if (!action.form.isNullOrEmpty()) PluginActionStep.Form(this) else PluginActionStep.Emit(this, payload)

    /** The form was submitted: out with its values beside what the action already carries (a row, a selection). */
    fun submitted(values: Map<String, Any?>): PluginActionStep = PluginActionStep.Emit(this, payload.copy(formValues = values))
}

/** Where an action run stands: asking, collecting its form, or handed over with its payload. */
internal sealed interface PluginActionStep {
    data class Confirm(val run: PluginActionRun) : PluginActionStep
    data class Form(val run: PluginActionRun) : PluginActionStep
    data class Emit(val run: PluginActionRun, val payload: PluginActionPayload) : PluginActionStep
}

/** One thing a view draws, in order, with a key that is unique within the view (rows are drawn once per key). */
internal sealed interface PluginViewPart {
    val key: String
    data object InlineForm : PluginViewPart { override val key = "inline-form" }

    data object Quote : PluginViewPart { override val key: String get() = "quote" }
    data object TitleRow : PluginViewPart { override val key: String get() = "title" }

    /** A line of words: the unavailable title or reason (secondary), or a read-only copy's closing line ([quiet]). */
    data class Line(override val key: String, val text: String, val quiet: Boolean) : PluginViewPart

    data class Fields(val fields: List<PluginViewField>) : PluginViewPart { override val key: String get() = "fields" }

    data class Block(val index: Int, val block: PluginBlock) : PluginViewPart { override val key: String get() = "b$index" }

    /** One row of the rows block at [index]; [first] draws no divider above it. */
    data class Row(val index: Int, val rows: PluginRowsBlock, val row: PluginRow, val first: Boolean) : PluginViewPart {
        override val key: String get() = "r$index:${row.key}"
    }

    data class RowsEmpty(val index: Int, val text: String) : PluginViewPart { override val key: String get() = "e$index" }

    /** The day heading before the row at [position] of the rows block at [index] (rules.rowsGroupByDay). */
    data class RowDay(val index: Int, val position: Int, val text: String) : PluginViewPart {
        override val key: String get() = "d$index:$position"
    }

    data class Keys(val actions: List<PluginViewAction>) : PluginViewPart { override val key: String get() = "keys" }

    /** An overview's quick keys, closing the card that holds its hero or stats (R2.1). */
    data object Quick : PluginViewPart { override val key: String get() = "quick" }

    data class DetailKey(val enabled: Boolean) : PluginViewPart { override val key: String get() = "detail" }

    data class Error(val text: String) : PluginViewPart { override val key: String get() = "error" }

    /** The upgrade notice of a view this build cannot draw ([FlarePluginUpgradeNotice], card). */
    data object Upgrade : PluginViewPart { override val key: String get() = "upgrade" }
}

/** The position a section's child keys its local state by: apart from every top-level position. */
internal fun pluginSectionChildIndex(section: Int, child: Int): Int = 1000 + section * 10 + child

/**
 * What a view draws, in order: on a card the quote and the title row; an unavailable view's title and reason; then the
 * fields, the blocks (a rows block as one part per row, each key once, or its empty line), the action [keys] and the
 * [detailKey]; a read-only copy's closing line; the failure.
 */
internal fun pluginViewParts(
    view: PluginViewModel,
    embedded: Boolean,
    quote: Boolean,
    reasonLine: String?,
    keys: List<PluginViewAction>,
    detailKey: Boolean?,
    failure: String?,
    strings: FlareStrings,
    nowMs: Long = FlareServerClock.nowMs(),
): List<PluginViewPart> = buildList {
    if (!embedded && quote) add(PluginViewPart.Quote)
    if (!embedded) add(PluginViewPart.TitleRow)
    // No title row: an unavailable embedded view still says what it was.
    PluginViewFormat.unavailableLine(view, embedded)?.let { add(PluginViewPart.Line("unavailable", it, quiet = false)) }
    // Why it is unavailable, under the title; a view this build cannot draw says how to get one that can.
    if (view.upgradeRequired) add(PluginViewPart.Upgrade)
    else if (!view.available && reasonLine != null) add(PluginViewPart.Line("reason", reasonLine, quiet = false))
    if (view.available) {
        if (view.fields.isNotEmpty()) add(PluginViewPart.Fields(view.fields))
        view.blocks.forEachIndexed { index, block ->
            if (block is PluginRowsBlock) {
                val rows = PluginViewFormat.rowsOnce(block.rows)
                if (rows.isEmpty()) PluginViewFormat.rowsEmpty(block, strings)?.let { add(PluginViewPart.RowsEmpty(index, it)) }
                val days = PluginViewFormat.rowDayHeadings(block.copy(rows = rows), nowMs, strings, null)
                rows.forEachIndexed { position, row ->
                    val day = days[position]
                    if (day != null) add(PluginViewPart.RowDay(index, position, day))
                    add(PluginViewPart.Row(index, block, row, first = position == 0 || day != null))
                }
            } else {
                add(PluginViewPart.Block(index, block))
            }
        }
        if (keys.isNotEmpty()) add(PluginViewPart.Keys(keys))
        if (detailKey != null) add(PluginViewPart.DetailKey(detailKey))
    }
    // A read-only copy closes with why nothing on it acts.
    if (view.available && reasonLine != null) add(PluginViewPart.Line("readonly", reasonLine, quiet = true))
    if (failure != null) add(PluginViewPart.Error(failure))
}

/** Wrapping text actions; the optional final details key stays at the trailing edge of its row. */
@Composable
private fun PluginActionFooter(trailingDetail: Boolean, compact: Boolean = false, content: @Composable () -> Unit) {
    Layout(content = content, modifier = if (compact) Modifier else Modifier.fillMaxWidth()) { measurables, constraints ->
        val gap = (if (compact) FlareSizes.spacingSm else FlareSizes.spacingMd).roundToPx()
        val lineGap = FlareSizes.spacingSm.roundToPx()
        val items = measurables.map { it.measure(constraints.copy(minWidth = 0, minHeight = 0)) }
        val ideal = items.sumOf { it.width } + gap * (items.size - 1).coerceAtLeast(0)
        val width = constraints.constrainWidth(if (constraints.hasBoundedWidth && !compact) constraints.maxWidth else ideal)
        val positions = mutableListOf<Pair<Int, Int>>()
        var x = 0
        var y = 0
        var rowHeight = 0
        items.forEachIndexed { index, item ->
            if (x > 0 && x + item.width > width) {
                x = 0
                y += rowHeight + lineGap
                rowHeight = 0
            }
            val itemX = if (trailingDetail && index == items.lastIndex) maxOf(x, width - item.width) else x
            positions += itemX to y
            x += item.width + gap
            rowHeight = maxOf(rowHeight, item.height)
        }
        layout(width, constraints.constrainHeight(y + rowHeight)) {
            items.forEachIndexed { index, item -> item.placeRelative(positions[index].first, positions[index].second) }
        }
    }
}

/**
 * The space above a part (R1 on a page): none for the first, none between the rows of one block (a hairline divides them), 2xl
 * on either side of a section (between groups), lg between other blocks.
 */
internal fun pluginPartGap(previous: PluginViewPart?, part: PluginViewPart, page: Boolean = true): Dp = when {
    previous == null -> 0.dp
    previous is PluginViewPart.RowDay -> FlareSizes.spacingXs
    part is PluginViewPart.Row && !part.first -> 0.dp
    // A message card keeps its tighter rhythm; R1 is the page's.
    !page -> FlareSizes.spacingMd
    pluginPartIsSection(previous) || pluginPartIsSection(part) -> FlareSizes.spacing2xl
    else -> FlareSizes.spacingLg
}

private fun pluginPartIsSection(part: PluginViewPart): Boolean = part is PluginViewPart.Block && part.block is PluginSectionBlock

/**
 * One segment of the primary panel a page draws its view on: the first rounds the top and pads md above, the last rounds
 * the bottom and pads md below, the ones between keep [gap] above, so the segments read as one card.
 */
private fun Modifier.pluginPanel(surface: Color, first: Boolean, last: Boolean, gap: Dp): Modifier {
    val top = if (first) FlareSizes.radiusLg else 0.dp
    val bottom = if (last) FlareSizes.radiusLg else 0.dp
    return background(surface, RoundedCornerShape(topStart = top, topEnd = top, bottomStart = bottom, bottomEnd = bottom))
        .padding(
            start = FlareSizes.spacingMd, end = FlareSizes.spacingMd,
            top = if (first) FlareSizes.spacingMd else gap, bottom = if (last) FlareSizes.spacingMd else 0.dp,
        )
}

/** The host's answers for the ids not known yet; an id it cannot answer keeps the fallback. */
internal suspend fun pluginResolvedUsers(
    ids: List<String>,
    known: Map<String, PluginUser>,
    resolveUser: suspend (String) -> PluginUser?,
): Map<String, PluginUser> {
    val found = LinkedHashMap<String, PluginUser>()
    for (id in ids) {
        if (id in known || id in found) continue
        val user = runCatching { resolveUser(id) }.getOrNull() ?: continue
        found[id] = user
    }
    return found
}

/** Runs [onChange] after a composition in which [value] differs from the last one seen (not on the first). */
@Composable
internal fun <T> PluginOnChange(value: T, onChange: (old: T, new: T) -> Unit) {
    val seen = remember { arrayOf<Any?>(value) }
    val action by rememberUpdatedState(onChange)
    LaunchedEffect(value) {
        @Suppress("UNCHECKED_CAST")
        val old = seen[0] as T
        if (old != value) {
            seen[0] = value
            action(old, value)
        }
    }
}

// ── blocks ──────────────────────────────────────────────────────────────────

/** The semantic colour of a tone as text (`*Text` tokens; neutral is the secondary text). */
@Composable
internal fun pluginToneText(tone: PluginTone?): Color {
    val colors = flareColors()
    return when (tone ?: PluginTone.Neutral) {
        PluginTone.Neutral -> colors.textSecondary
        PluginTone.Info -> colors.infoText
        PluginTone.Success -> colors.successText
        PluginTone.Warning -> colors.warningText
        PluginTone.Danger -> colors.errorText
    }
}

/** The ground a tone tints (the fill of the pair, faint). */
@Composable
internal fun pluginToneGround(tone: PluginTone?): Color {
    val colors = flareColors()
    return when (tone ?: PluginTone.Neutral) {
        PluginTone.Neutral -> colors.bgTertiary
        PluginTone.Info -> colors.info.copy(alpha = 0.12f)
        PluginTone.Success -> colors.success.copy(alpha = 0.12f)
        PluginTone.Warning -> colors.warning.copy(alpha = 0.12f)
        PluginTone.Danger -> colors.error.copy(alpha = 0.12f)
    }
}

// The kit tag's mix (Vue FlareTag): the tone at 6% over the primary surface, and an edge of its ink at 18%.
private const val BADGE_TINT = 0.06f
private const val BADGE_EDGE = 0.18f

/**
 * A badge as the kit tag (spec rules.badge): the tone's `*Text` ink on a faint tint of the tone over the primary surface
 * (neutral: secondary text on the tertiary background), caption size, one line. It is words, never a control.
 */
@Composable
internal fun PluginBadgeTag(given: PluginBadge, modifier: Modifier = Modifier) {
    val colors = flareColors()
    // R3: a value outside the plugin's values reads as the unknown status, neutral, never the raw text.
    val badge = if (given.unmapped) PluginBadge(flareStrings().pluginViewUnknownStatus, PluginTone.Neutral) else given
    val ink = pluginToneText(badge.tone)
    val surface = when (badge.tone) {
        PluginTone.Neutral -> colors.bgTertiary
        PluginTone.Info -> colors.info.copy(alpha = BADGE_TINT).compositeOver(colors.bgPrimary)
        PluginTone.Success -> colors.success.copy(alpha = BADGE_TINT).compositeOver(colors.bgPrimary)
        PluginTone.Warning -> colors.warning.copy(alpha = BADGE_TINT).compositeOver(colors.bgPrimary)
        PluginTone.Danger -> colors.error.copy(alpha = BADGE_TINT).compositeOver(colors.bgPrimary)
    }
    val shape = RoundedCornerShape(FlareSizes.radiusSm)
    Text(
        badge.text, color = ink, fontSize = FlareTextRoles.Caption.fontSize, fontWeight = FontWeight.Medium,
        lineHeight = FlareTextRoles.Caption.fontSize * FlareTextRoles.Caption.lineHeight, maxLines = 1, overflow = TextOverflow.Ellipsis,
        modifier = modifier.clip(shape).background(surface).border(1.dp, ink.copy(alpha = BADGE_EDGE), shape)
            .padding(horizontal = FlareSizes.spacing2xs),
    )
}

/** Label/value rows; a value with a `count` or `duration` format is written in the viewer's words. */
@Composable
private fun PluginFieldRows(fields: List<PluginViewField>) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        fields.forEach { field ->
            Row(Modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.widthIn(min = 56.dp))
                Text(PluginFormatRules.text(field.value, field.format, strings), color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun PluginTextBlockView(block: PluginTextBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    var expanded by remember(block) { mutableStateOf(false) }
    var overflows by remember(block) { mutableStateOf(false) }
    val (size, weight) = when (block.style) {
        PluginTextStyle.Title -> FlareSizes.fontSize2xl to FontWeight.SemiBold
        PluginTextStyle.Body -> FlareSizes.fontSizeLg to FontWeight.Normal
        PluginTextStyle.Secondary -> FlareSizes.fontSizeMd to FontWeight.Normal
    }
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
        Text(
            block.text,
            color = if (block.style == PluginTextStyle.Secondary) colors.textSecondary else colors.textPrimary,
            fontSize = size, fontWeight = weight,
            maxLines = if (expanded) Int.MAX_VALUE else block.maxLines ?: Int.MAX_VALUE,
            overflow = TextOverflow.Ellipsis,
            onTextLayout = { if (!expanded) overflows = it.hasVisualOverflow },
        )
        if (block.maxLines != null && (overflows || expanded)) {
            Text(
                if (expanded) strings.collapse else strings.expand,
                color = colors.primaryText, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium,
                modifier = Modifier.clickable(role = Role.Button) { expanded = !expanded }.padding(vertical = FlareSizes.spacing3xs),
            )
        }
    }
}

@Composable
private fun PluginChoicesBlockView(
    block: PluginChoicesBlock,
    shown: List<Int>,
    interactive: Boolean,
    /** Options the cap holds back while the block can be chosen: dimmed, not tappable, still in the list. */
    held: Set<Int>,
    submitEnabled: Boolean,
    submitLoading: Boolean,
    onPick: (Int) -> Unit,
    onSubmit: () -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val chosen = shown.toSet()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.options.forEach { option ->
            val selected = option.index in chosen
            val waiting = option.index in held
            val percent = PluginViewFormat.percentText(option, block.showResults)
            val votes = PluginViewFormat.votesText(option, block.showResults, strings, flareLocale())
            val shape = RoundedCornerShape(FlareSizes.radiusMd)
            Box(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTargetMin)
                    // A held option keeps its layer and only changes its alpha (no layer dropped when it frees up).
                    .flareDimmed(if (waiting) FlareOpacity.disabled else 1f)
                    .clip(shape)
                    .background(colors.bgSecondary)
                    .border(1.dp, if (selected) colors.borderSelected else colors.borderPrimary, shape)
                    .clickable(enabled = interactive && !waiting, role = if (block.multiple) Role.Checkbox else Role.Button) { onPick(option.index) }
                    .semantics(mergeDescendants = true) {
                        this.selected = selected
                        contentDescription = listOfNotNull(option.label, percent, votes).joinToString(", ")
                    },
                contentAlignment = Alignment.CenterStart,
            ) {
                if (block.showResults) {
                    val fraction = ((option.percent ?: 0).coerceIn(0, 100)) / 100f
                    Box(Modifier.matchParentSize()) {
                        Box(Modifier.fillMaxHeight().fillMaxWidth(fraction).background(colors.primary.copy(alpha = if (selected) 0.16f else 0.08f)))
                    }
                }
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                ) {
                    if (block.multiple && interactive) PluginCheckBox(selected)
                    Text(option.label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg,
                        fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal, modifier = Modifier.weight(1f))
                    if (selected && !(block.multiple && interactive)) FlareIcon("check", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
                    percent?.let { Text(it, color = if (selected) colors.primaryText else colors.textSecondary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold) }
                    votes?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm) }
                }
            }
        }
        val action = block.action
        if (action != null && block.multiple && !block.closed) {
            Button(
                label = action.label,
                variant = if (action.style == PluginActionStyle.Danger) FlareButtonVariant.Danger else FlareButtonVariant.Primary,
                loading = submitLoading, disabled = !(interactive && submitEnabled), block = true, onClick = onSubmit,
            )
        }
        PluginViewFormat.choicesFooter(block, strings)?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm) }
    }
}

/** The square a multiple choice draws while it can still be changed. */
@Composable
private fun PluginCheckBox(on: Boolean) {
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusXs)
    Box(
        Modifier.size(18.dp).clip(shape).background(if (on) colors.primary else colors.bgPrimary)
            .border(1.5.dp, if (on) colors.primary else colors.borderHover, shape),
        contentAlignment = Alignment.Center,
    ) {
        if (on) FlareIcon("check", size = 12.dp, tint = Color.White)
    }
}

@Composable
private fun PluginEntriesBlockView(block: PluginEntriesBlock, users: Map<String, PluginUser>, viewerId: String?, onSeeAll: (() -> Unit)?) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        if (block.items.isEmpty()) {
            block.emptyText?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd) }
        }
        block.items.forEachIndexed { position, entry ->
            // A grouped block opens each group with its header row.
            PluginViewFormat.entryGroupHeader(block, entry, strings, flareLocale())?.let { header ->
                Text(
                    header, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.fillMaxWidth().padding(top = if (position > 0) FlareSizes.spacingXs else 0.dp).semantics { heading() },
                )
            }
            val name = PluginViewFormat.entryName(entry, users)
            // One reading in drawing order: number, avatar, name, me, badge, text.
            Row(
                Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                for (part in PluginViewFormat.entryParts(block, entry, users, viewerId)) when (part) {
                    PluginEntryPart.Number -> Text("${PluginViewFormat.entryNumber(block, entry)}.", color = colors.textTertiary,
                        fontSize = FlareSizes.fontSizeMd, modifier = Modifier.widthIn(min = 20.dp))
                    PluginEntryPart.Avatar -> {
                        val userId = entry.userId.orEmpty()
                        Avatar(userId = userId, displayName = name.orEmpty(), size = 20.dp, avatarUrl = users[userId]?.avatarUrl)
                    }
                    PluginEntryPart.Name -> Text(name.orEmpty(), color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg,
                        fontWeight = FontWeight.SemiBold, maxLines = 1)
                    PluginEntryPart.Me -> Text(
                        strings.pluginViewMe, color = colors.primaryText, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.Medium,
                        modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusXs)).background(colors.primary.copy(alpha = FlareOpacity.tintWeak))
                            .padding(horizontal = FlareSizes.spacingXs),
                    )
                    PluginEntryPart.Badge -> entry.badge?.let { PluginBadgeTag(it) }
                    PluginEntryPart.Text -> Text(entry.text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
                }
                entry.timeMs?.let { timeMs ->
                    Text(
                        PluginViewFormat.dateTime(timeMs, FlareServerClock.nowMs(), strings, null),
                        color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 1,
                    )
                }
            }
        }
        if (block.more) {
            Row(
                Modifier.heightIn(min = FlareSizes.touchTargetMin)
                    .clickable(enabled = onSeeAll != null, role = Role.Button) { onSeeAll?.invoke() },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
            ) {
                Text(PluginViewFormat.seeAll(block.total, strings), color = colors.primaryText, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium)
                FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
            }
        }
    }
}

/**
 * One row of a page's list (spec rules.pageRows): the badge and the first cell, under them the other cells, and the
 * row's action keys at its end. The words read as one item; each key is its own control (a row whose only action opens
 * a page is one control instead, rules.rowTap).
 */
@Composable
private fun PluginRowItem(
    block: PluginRowsBlock,
    row: PluginRow,
    divided: Boolean,
    nowMs: Long,
    spinning: (PluginViewAction) -> Boolean,
    disabled: Boolean,
    labelRows: Boolean = false,
    onRun: (PluginViewAction, PluginRowAction) -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    // R3: a toned or unmapped cell is a Tag at the row's end (under the amount), not part of the second line.
    val tags = row.cells.withIndex().filter { (i, cell) -> i > 0 && (cell.tone != null || cell.unmapped) }
    val lines = PluginViewFormat.rowLines(block.copy(columns = block.columns.filterIndexed { i, _ -> tags.none { it.index == i } }),
        row.copy(cells = row.cells.filterIndexed { i, _ -> tags.none { it.index == i } }), nowMs, strings, null)
    // R2.3 (rules.rowTap): a row whose only action opens a page is one control ending with a chevron, and draws no key.
    val tap = PluginViewFormat.rowTap(block, row)
    val actions = if (tap != null) emptyList() else PluginViewFormat.rowActions(block, row)
    val reasons = (tap?.let { listOf(it) } ?: actions).mapNotNull { it.first.disabledReason }.distinct()
    val tapModifier = tap?.let { (action, bound) ->
        Modifier.clickable(enabled = !disabled && action.disabledReason == null, role = Role.Button) { onRun(action, bound) }
    } ?: Modifier
    // The words read as one item; a tappable row is that item itself (a nested merge would split its name off).
    val words = if (tap == null) Modifier.semantics(mergeDescendants = true) {} else Modifier
    // Busy as on a key: the row that ran the action spins in place of its chevron.
    val chevron: @Composable () -> Unit = {
        if (tap != null) if (spinning(tap.first)) SettingsRowSpinner()
            else FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
    }
    // rules.rowsIcon (§12.24): only a block that declares an icon draws its rows as records (5.8 ledger lines) — the
    // circle, who or what first, the signed amount at the end; without one the rows are rules.pageRows items below.
    if (!labelRows && pluginRowsAreRecords(block)) {
        val ledger = pluginLedgerLine(block, row, nowMs, strings)
        val amount = ledger.value
        val kind = pluginLedgerKind(amount)
        Column(Modifier.fillMaxWidth()) {
            if (divided) Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
            Row(
                Modifier.fillMaxWidth().then(tapModifier).heightIn(min = FlareSizes.componentRecordRowHeight).padding(vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                PluginLedgerIcon(kind, row.icon ?: block.icon)
                Row(Modifier.weight(1f).then(words), verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                            Text(ledger.title.ifEmpty { row.badge?.text.orEmpty() }, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl,
                                maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                            if (ledger.title.isNotEmpty()) row.badge?.let { PluginBadgeTag(it) }
                        }
                        ledger.line?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                        reasons.forEach { PluginCaption(it) }
                    }
                    Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                        Text(pluginSignedAmount(amount), color = if (kind == PluginLedgerKind.Income) colors.successText else colors.textPrimary,
                            fontSize = FlareSizes.fontSize2xl, fontWeight = FontWeight.SemiBold, style = FlareTabularFigures, maxLines = 1)
                        // A completed status stays quiet; any other reads as its Tag under the amount.
                        ledger.tags.forEach { cell ->
                            PluginStatusValue(cell.text, cell.format, cell.tone, cell.unmapped, strings, warnKey = "${block.source}/${row.key}")
                        }
                    }
                }
                actions.forEach { (action, bound) ->
                    Button(label = action.label, variant = PluginViewFormat.variant(action), size = FlareControlSize.Sm,
                        loading = spinning(action), disabled = disabled || action.disabledReason != null, onClick = { onRun(action, bound) })
                }
                chevron()
            }
        }
        return
    }
    Column(Modifier.fillMaxWidth()) {
        if (divided) Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
        Row(
            Modifier.fillMaxWidth().then(tapModifier).heightIn(min = FlareSizes.touchTargetMin).padding(vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            Column(
                Modifier.weight(1f).then(words),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
            ) {
                if (labelRows) block.columns.firstOrNull()?.label?.takeIf { it.isNotEmpty() }?.let {
                    Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    row.badge?.let { PluginBadgeTag(it) }
                    Text(lines.primary, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.Medium,
                        maxLines = if (labelRows) Int.MAX_VALUE else 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                }
                if (labelRows) PluginFieldRows(PluginViewFormat.rowFields(block, row, nowMs, strings, null))
                else lines.secondary?.let {
                    Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                reasons.forEach { PluginCaption(it) }
            }
            if (tags.isNotEmpty()) Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                tags.forEach { (_, cell) -> PluginStatusValue(cell.text, cell.format, cell.tone, cell.unmapped, strings, warnKey = "${block.source}/${row.key}") }
            }
            actions.forEach { (action, bound) ->
                Button(
                    label = action.label, variant = PluginViewFormat.variant(action), size = FlareControlSize.Sm,
                    loading = spinning(action), disabled = disabled || action.disabledReason != null, onClick = { onRun(action, bound) },
                )
            }
            chevron()
        }
    }
}

@Composable
private fun PluginPeopleBlockView(block: PluginPeopleBlock, users: Map<String, PluginUser>) {
    val colors = flareColors()
    val side = 24.dp
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.groups.forEach { group ->
            val tone = pluginToneText(group.tone)
            Row(
                Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (group.userIds.isNotEmpty()) {
                    Box(Modifier.width(side + (side * 2 / 3) * (group.userIds.size - 1)).height(side)) {
                        group.userIds.forEachIndexed { i, userId ->
                            val user = PluginViewFormat.user(userId, users)
                            Box(Modifier.offset(x = (side * 2 / 3) * i).border(1.5.dp, colors.bgPrimary, CircleShape)) {
                                Avatar(userId = userId, displayName = user.name, size = side, avatarUrl = user.avatarUrl)
                            }
                        }
                    }
                }
                Text(group.label, color = tone, fontSize = FlareSizes.fontSizeMd)
                Text(group.count.toString(), color = tone, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
            }
        }
    }
}

/** A status block (R3): its label and the kit Tag in its tone; a value outside the plugin's values reads unknown. */
@Composable
private fun PluginStatusBlockView(block: PluginStatusBlock, warnScope: String) {
    val colors = flareColors()
    Row(
        Modifier.semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
        PluginStatusValue(block.text, null, block.tone, block.unmapped, flareStrings(), warnKey = "$warnScope/${block.label.orEmpty()}")
    }
}

@Composable
private fun PluginProgressBlockView(block: PluginProgressBlock) {
    val colors = flareColors()
    val text = PluginViewFormat.progressText(block)
    val fraction = block.percent.coerceIn(0, 100) / 100f
    Column(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) {
            progressBarRangeInfo = ProgressBarRangeInfo(fraction, 0f..1f)
            stateDescription = text
        },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
            Spacer(Modifier.weight(1f))
            Text(text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold)
        }
        Box(Modifier.fillMaxWidth().height(FlareSizes.spacing2xs).clip(CircleShape).background(colors.bgTertiary)) {
            Box(Modifier.fillMaxHeight().fillMaxWidth(fraction).clip(CircleShape).background(colors.primary))
        }
    }
}

@Composable
private fun PluginTimeBlockView(block: PluginTimeBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    // `atMs` is the server's clock, so now is the server's too (spec/server-clock-vectors.json).
    var now by remember { mutableLongStateOf(FlareServerClock.nowMs()) }
    LaunchedEffect(block) {
        if (!block.countdown) return@LaunchedEffect
        while (true) {
            now = FlareServerClock.nowMs()
            val wait = PluginViewFormat.countdownDelay(block.atMs, now) ?: break
            delay(wait)
        }
    }
    val text = PluginViewFormat.timeText(block.atMs, block.endMs, now, strings, null)
    val countdown = if (block.countdown) PluginViewFormat.countdown(block.atMs, now, strings) else null
    Row(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
        Text(text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg)
        Spacer(Modifier.weight(1f))
        countdown?.let {
            Text(it.text, color = if (it.refreshMs == null) colors.textTertiary else colors.warningText, fontSize = FlareSizes.fontSizeSm,
                fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
private fun PluginNoteBlockView(block: PluginNoteBlock, inSection: Boolean = false) {
    if (inSection && block.tone == PluginTone.Info) {
        Text(block.text, color = flareColors().textSecondary, fontSize = FlareTextRoles.Caption.fontSize, modifier = Modifier.fillMaxWidth())
        return
    }
    Text(
        block.text, color = pluginToneText(block.tone), fontSize = FlareSizes.fontSizeMd,
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusSm)).background(pluginToneGround(block.tone))
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
    )
}
