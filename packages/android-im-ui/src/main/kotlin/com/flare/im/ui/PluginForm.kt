package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.ui.semantics.Role
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.error
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.imeAnimationTarget
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.util.UUID
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull

/**
 * The inputs of a plugin action. Spec: Form/PluginForm (`PluginForm`). The host puts it in the kit [BottomSheet] (inside
 * a scrolling column; [PluginView] does so for a card action whose `form` lists inputs).
 *
 * The kit checks only required and length (Unicode code points, trimmed): an input's issue shows once it was edited,
 * and every issue after a submit attempt; the core SDK's `validate_form` decides, and its [errors] show under their
 * inputs until that input is edited (the first one per input). [onSubmit] receives the cleaned values (String, Double,
 * Boolean, List of String): text trimmed (omitted when blank), number and datetime when set, toggle always, select when
 * chosen, option rows trimmed without the empty ones, members when any (`spec/plugin-view-vectors.json` → form).
 *
 * Controls: text and textarea with "n/max"; number; toggle ([Switch]); select as a single-choice list ([RadioGroup]);
 * datetime with the kit [DatePicker] and [TimePicker] in the device zone; options as rows with add and remove within
 * [max(min, 1), max]; members through [ContactPicker] over the host's [members] (one pick when max is 1); money as an
 * amount field with its currency (submitted as `{amount, currency}`, the amount normalised and checked against the
 * scale and bounds); file, image and document through the upload slot (the host picks, captures and uploads on
 * [PluginFileAction]; image asks to choose a picture, document to capture its side).
 */
/** How long a focused field waits for the keyboard to finish rising before its second scroll (the IME animates in ~300 ms). */
private const val PLUGIN_FORM_KEYBOARD_SETTLE_MS = 1_000L

@OptIn(ExperimentalFoundationApi::class, ExperimentalLayoutApi::class)
@Composable
fun PluginForm(
    inputs: List<PluginInput>,
    values: Map<String, Any?>? = null,
    errors: List<PluginFormError> = emptyList(),
    submitLabel: String? = null,
    busy: Boolean = false,
    error: String? = null,
    members: List<PluginMember> = emptyList(),
    embedded: Boolean = false,
    fileStates: Map<String, PluginFileState> = emptyMap(),
    onFileAction: ((PluginFileAction) -> Unit)? = null,
    onSubmit: ((Map<String, Any?>) -> Unit)? = null,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    onCancel: (() -> Unit)? = null,
    /** Location inputs: the host's fix, a running locate or a failure, by input id. */
    locationStates: Map<String, PluginLocationState> = emptyMap(),
    /** A location input's locate or clear key: the host runs the page's locationOnce action into the input. */
    onLocationAction: ((PluginLocationAction) -> Unit)? = null,
    /** A page action's native target writing into one of these inputs: it runs through that input's key. */
    nativeRequest: PluginNativeIntoRequest? = null,
    /** The submit key is drawn by the page (its task bar): the form draws none and submits when [submitToken] moves. */
    hideSubmit: Boolean = false,
    submitToken: Int = 0,
    /** Whether submit may run now and what to say under it (an upload running), for a key the page draws. */
    onSubmitState: ((PluginFormSubmitState) -> Unit)? = null,
) {
    val strings = flareStrings()
    var form by remember(inputs, values) { mutableStateOf(PluginFormState.initial(inputs, values)) }
    val fileScope = remember(inputs, values) { UUID.randomUUID().toString() }
    var fileGenerations by remember(fileScope) { mutableStateOf(inputs.filter { it.kind.isUpload }.associate { it.id to 0 }) }
    var localFiles by remember(fileScope) {
        mutableStateOf(inputs.filter { it.kind.isUpload }.associate { input ->
            val value = pluginFileReference(form.draft[input.id])
            input.id to PluginFileState(fileScope, 0, if (value == null) PluginFilePhase.Empty else PluginFilePhase.Uploaded, value)
        })
    }
    val fileCallback by rememberUpdatedState(onFileAction)
    val disposalFiles by rememberUpdatedState(fileGenerations)
    val disposalDraft by rememberUpdatedState(form.draft)
    DisposableEffect(fileScope) {
        onDispose {
            inputs.filter { it.kind.isUpload }.forEach { input ->
                fileCallback?.invoke(PluginFileAction(PluginFileActionKind.Invalidate, input.id, input, fileScope,
                    (disposalFiles[input.id] ?: 0) + 1, PluginFormRules.values(inputs, disposalDraft) - input.id))
            }
        }
    }
    LaunchedEffect(fileScope, fileStates) {
        inputs.filter { it.kind.isUpload && it.visibleIn(form.draft) }.forEach { input ->
            pluginFileCurrent(fileStates[input.id], fileScope, fileGenerations[input.id] ?: 0)?.let { state ->
                localFiles = localFiles + (input.id to state)
                val reference = if (state.phase == PluginFilePhase.Uploaded) pluginFileReference(state.value) else null
                if (form.draft[input.id] != reference) form = form.set(input.id, reference)
            }
        }
    }
    var numberText by remember(inputs, values) {
        mutableStateOf(inputs.filter { it.kind == PluginInputKind.Number }.associate { input ->
            input.id to ((form.draft[input.id] as? Number)?.let { PluginViewFormat.number(it.toDouble()) } ?: "")
        })
    }
    var dateParts by remember(inputs, values) {
        mutableStateOf(inputs.filter { it.kind == PluginInputKind.Datetime }.associate { input ->
            input.id to pluginDateParts((form.draft[input.id] as? Number)?.toLong())
        })
    }
    var picking by remember { mutableStateOf<PluginInput?>(null) }
    var pickingRevision by remember { mutableStateOf(membersRevision) }
    var memberGeneration by remember { mutableStateOf(membersRevision) }
    val latestMembers by rememberUpdatedState(members)
    val latestMemberLoading by rememberUpdatedState(membersLoading)
    val latestMemberError by rememberUpdatedState(membersError)
    val latestMemberRevision by rememberUpdatedState(membersRevision)
    var chosenMembers by remember(inputs, values) { mutableStateOf<Map<String, PluginMember>>(emptyMap()) }
    LaunchedEffect(membersRevision) {
        if (memberGeneration != membersRevision) {
            memberGeneration = membersRevision
            picking = null
            chosenMembers = emptyMap()
            for (input in inputs) if (input.kind == PluginInputKind.Members) form = form.set(input.id, emptyList<String>(), inputs)
        }
    }
    // R6: on a failed submit (the kit's check or the host's errors) focus goes to the first wrong field, scrolled into view.
    val focusers = remember(inputs) { inputs.associate { it.id to FocusRequester() } }
    val bringers = remember(inputs) { inputs.associate { it.id to BringIntoViewRequester() } }
    var focusTick by remember { mutableStateOf(0) }
    PluginOnChange(errors) { _, next ->
        form = form.hostErrorsChanged()
        if (next.isNotEmpty()) focusTick++
    }

    fun fileAction(input: PluginInput, kind: PluginFileActionKind) {
        val increments = kind in setOf(PluginFileActionKind.Choose, PluginFileActionKind.Replace, PluginFileActionKind.Cancel,
            PluginFileActionKind.Remove, PluginFileActionKind.Invalidate)
        val generation = (fileGenerations[input.id] ?: 0) + if (increments) 1 else 0
        fileGenerations = fileGenerations + (input.id to generation)
        if (kind != PluginFileActionKind.Preview) {
            form = if (kind == PluginFileActionKind.Invalidate) form.copy(draft = form.draft - input.id) else form.set(input.id, null)
            val selecting = kind in setOf(PluginFileActionKind.Choose, PluginFileActionKind.Replace, PluginFileActionKind.Retry)
            localFiles = localFiles + (input.id to PluginFileState(fileScope, generation,
                if (selecting) PluginFilePhase.Selected else PluginFilePhase.Empty))
        }
        fileCallback?.invoke(PluginFileAction(kind, input.id, input, fileScope, generation,
            PluginFormRules.values(inputs, form.draft)))
    }
    fun set(id: String, value: Any?) {
        val changed = form.draft[id] != value
        form = form.set(id, value, inputs)
        if (changed) inputs.filter { it.showWhen?.field == id && it.kind.isUpload }
            .forEach { fileAction(it, PluginFileActionKind.Invalidate) }
        if (changed) {
            val dependentIds = inputs.filter { it.showWhen?.field == id }.map { it.id }.toSet()
            numberText = numberText - dependentIds
            dateParts = dateParts - dependentIds
        }
    }
    fun errorText(input: PluginInput) = form.errorText(input, errors, strings)
    // The host's fix is the input's value; one of another precision is never taken.
    LaunchedEffect(form.draft.keys, locationStates) {
        inputs.filter { it.kind == PluginInputKind.Location && it.visibleIn(form.draft) }.forEach { input ->
            val fix = PluginLocationValue.read(locationStates[input.id]?.value, input.precision) ?: return@forEach
            if (PluginLocationValue.read(form.draft[input.id], input.precision) != fix) set(input.id, fix.toMap())
        }
    }
    fun locationAction(input: PluginInput, kind: PluginLocationActionKind) {
        if (busy || !input.visibleIn(form.draft)) return
        if (kind == PluginLocationActionKind.Clear) set(input.id, null)
        else if (locationStates[input.id]?.locating == true) return
        onLocationAction?.invoke(PluginLocationAction(kind, input.id, input, PluginFormRules.values(inputs, form.draft)))
    }
    // A page action's native target writing `into` one of these inputs runs through that input's own key, so the host
    // gets this form's scope with it and its answer lands here, even before the viewer touched the input.
    LaunchedEffect(nativeRequest) {
        val target = nativeRequest?.target ?: return@LaunchedEffect
        if (busy) return@LaunchedEffect
        val input = inputs.firstOrNull { it.visibleIn(form.draft) && pluginNativeIntoKey(target, it) != null }
            ?: return@LaunchedEffect
        if (pluginNativeIntoKey(target, input) == "location") {
            if (onLocationAction != null) locationAction(input, PluginLocationActionKind.Locate)
        } else if (fileCallback != null) {
            val phase = localFiles[input.id]?.phase ?: PluginFilePhase.Empty
            fileAction(input, if (phase == PluginFilePhase.Empty) PluginFileActionKind.Choose else PluginFileActionKind.Replace)
        }
    }

    val uploads = inputs.filter { it.visibleIn(form.draft) && it.kind.isUpload }
    val uploading = uploads.any { pluginFilePending(localFiles[it.id]) }
    // R6: a select with no choices, or an upload still running, keeps submit off; the upload says how far it got.
    // 6.3: every required document photo before submit; the key says how many are missing.
    val documents = inputs.filter { it.visibleIn(form.draft) && it.kind == PluginInputKind.Document }
    val missing = pluginDocumentsMissing(documents, documents.associate { it.id to localFiles[it.id]?.phase })
    val blocked = uploading || missing > 0 || pluginFormBlocked(inputs, form.draft)
    val transferring = uploads.any { localFiles[it.id]?.phase == PluginFilePhase.Selected || localFiles[it.id]?.phase == PluginFilePhase.Uploading }
    val submitCaption = when {
        transferring -> strings.pluginViewUploading
            .replace("{done}", uploads.count { localFiles[it.id]?.phase == PluginFilePhase.Uploaded }.toString())
            .replace("{total}", uploads.count { (localFiles[it.id]?.phase ?: PluginFilePhase.Empty) != PluginFilePhase.Empty }.toString())
        missing > 0 -> (if (missing == 1) strings.realnamePhotosNeededOne else strings.realnamePhotosNeeded).replace("{count}", missing.toString())
        else -> null
    }
    val submitState = PluginFormSubmitState(enabled = !blocked && !busy && onSubmit != null, caption = submitCaption)
    val reportState by rememberUpdatedState(onSubmitState)
    LaunchedEffect(submitState) { reportState?.invoke(submitState) }
    fun submit() {
        if (busy || blocked) return
        val (next, submitted) = form.submit(inputs)
        form = next
        if (submitted != null) { inputs.filter { it.kind == PluginInputKind.Password }.forEach { set(it.id, "") }; onSubmit?.invoke(submitted) }
        else focusTick++
    }
    PluginOnChange(submitToken) { _, _ -> submit() }
    val density = LocalDensity.current
    val imeNow = WindowInsets.ime
    val imeEnd = WindowInsets.imeAnimationTarget
    LaunchedEffect(focusTick) {
        if (focusTick == 0) return@LaunchedEffect
        val first = inputs.firstOrNull { it.visibleIn(form.draft) && errorText(it) != null } ?: return@LaunchedEffect
        val target = if (first.kind == PluginInputKind.Document) documents.firstOrNull() ?: first else first
        bringers[target.id]?.bringIntoView()
        runCatching { focusers[target.id]?.requestFocus() }
        // R11: the focus raises the keyboard, which animates in after that scroll and shrinks the page; once its inset
        // reaches the animation's end, bring the field into view again so the bottom action bar does not cover it.
        // No keyboard coming (a hardware one, a picker field): the wait times out and nothing else happens.
        withTimeoutOrNull(PLUGIN_FORM_KEYBOARD_SETTLE_MS) {
            snapshotFlow { imeNow.getBottom(density) to imeEnd.getBottom(density) }.first { (now, end) -> end > 0 && now == end }
        } ?: return@LaunchedEffect
        bringers[target.id]?.bringIntoView()
    }
    // R6: a phone's fields are 48 high, a wide window's 40.
    val fieldSize = if (flareCompactOverlays()) FlareControlSize.Lg else FlareControlSize.Md
    /** Where a field sits for focus and scrolling. */
    fun anchor(input: PluginInput): Modifier =
        Modifier.bringIntoViewRequester(bringers.getValue(input.id)).focusRequester(focusers.getValue(input.id))
    /** A PIN (6-cell) finished: the form submits when no required field follows it, else the next field takes focus (5.10). */
    fun pinDone(input: PluginInput) {
        val visible = inputs.filter { it.visibleIn(form.draft) }
        val after = visible.drop(visible.indexOf(input) + 1)
        if (after.none { it.required }) submit() else after.firstOrNull()?.let { runCatching { focusers[it.id]?.requestFocus() } }
    }

    Column(
        Modifier.fillMaxWidth().padding(horizontal = if (embedded) 0.dp else FlareSizes.spacingLg, vertical = if (embedded) 0.dp else FlareSizes.spacingMd),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
    ) {
        inputs.filter { it.visibleIn(form.draft) }.forEach { input ->
            when (input.kind) {
                PluginInputKind.Password -> if (pluginPinInput(input, form.draft[input.id])) PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    FlarePinInput(form.draft[input.id] as? String ?: "", onValueChange = { set(input.id, it) }, label = input.label,
                        disabled = busy, error = errorText(input) != null, onComplete = { pinDone(input) })
                } else PluginFormField(input.label, input.required, input.help,errorText(input), PluginFormRules.counter(input, form.draft[input.id]), anchor(input)) {
                    Input(value = form.draft[input.id] as? String ?: "", onValueChange = { set(input.id, it) },
                        placeholder = input.placeholder, disabled = busy, secure = true, size = fieldSize, error = errorText(input) != null, onSubmit = ::submit)
                }
                PluginInputKind.Text -> PluginFormField(input.label, input.required, input.help,errorText(input), PluginFormRules.counter(input, form.draft[input.id]), anchor(input)) {
                    Input(value = form.draft[input.id] as? String ?: "", onValueChange = { set(input.id, it) },
                        placeholder = input.placeholder, disabled = busy, size = fieldSize, error = errorText(input) != null, onSubmit = ::submit)
                }
                PluginInputKind.Textarea -> PluginFormField(input.label, input.required, input.help,errorText(input), PluginFormRules.counter(input, form.draft[input.id]), anchor(input)) {
                    Textarea(value = form.draft[input.id] as? String ?: "", placeholder = input.placeholder, rows = 3, maxRows = 6,
                        disabled = busy, onChange = { set(input.id, it) }, error = errorText(input) != null)
                }
                PluginInputKind.Number -> PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    Input(value = numberText[input.id].orEmpty(), onValueChange = { raw ->
                        numberText = numberText + (input.id to raw)
                        set(input.id, raw.trim().takeIf { it.isNotEmpty() }?.toDoubleOrNull()?.takeIf { it.isFinite() })
                    }, placeholder = input.placeholder, disabled = busy, size = fieldSize, error = errorText(input) != null, onSubmit = ::submit)
                }
                PluginInputKind.Toggle -> PluginFormField(null, help = input.help, issue = errorText(input), modifier = anchor(input)) {
                    Row(Modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, verticalAlignment = Alignment.CenterVertically) {
                        Text(input.label, color = flareColors().textPrimary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
                        Switch(value = form.draft[input.id] as? Boolean ?: false, disabled = busy, onChange = { set(input.id, it) })
                    }
                }
                PluginInputKind.Select -> PluginFormField(input.label, input.required, pluginSelectHelp(input, strings) ?: input.help, errorText(input), modifier = anchor(input)) {
                    val choices = input.choices.orEmpty()
                    val value = form.draft[input.id] as? String ?: ""
                    when (pluginSelectControl(choices.size)) {
                        // R6: up to 4 choices are choice cards, more a Select; none a disabled Select that says so.
                        PluginSelectControl.Cards -> RadioGroup(options = choices.map { FlareSelectOption(it.value, it.label, disabled = busy) },
                            value = value, optionLayout = FlareRadioOptionLayout.Cards, onSelect = if (busy) null else ({ set(input.id, it) }))
                        // R6: a Select is as tall as the form's inputs (48 on a phone, 40 on a wide window).
                        PluginSelectControl.Select -> Select(options = choices.map { FlareSelectOption(it.value, it.label) }, value = value,
                            placeholder = input.placeholder ?: strings.select, disabled = busy, title = input.label, size = fieldSize, onChange = { set(input.id, it) })
                        PluginSelectControl.Empty -> Select(options = emptyList(), value = "", placeholder = strings.pluginViewNoOptions,
                            disabled = true, title = input.label, size = fieldSize)
                    }
                }
                PluginInputKind.Datetime -> PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    val parts = dateParts[input.id] ?: ("" to "")
                    fun update(next: Pair<String, String>) {
                        dateParts = dateParts + (input.id to next)
                        set(input.id, pluginDateTimeMs(next)?.toDouble())
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        DatePicker(value = parts.first, placeholder = strings.selectDate, title = input.label, disabled = busy,
                            onChange = { update(it to parts.second) })
                        TimePicker(value = parts.second, placeholder = strings.selectTime, title = input.label, disabled = busy,
                            onChange = { update(parts.first to it) })
                    }
                }
                PluginInputKind.Options -> PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    val rows = form.rows(input.id)
                    val removable = form.canRemoveRow(input)
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        rows.forEachIndexed { index, row ->
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                                Box(Modifier.weight(1f)) {
                                    Input(value = row, onValueChange = { form = form.setRow(input, index, it) },
                                        placeholder = strings.pollOptionHint(index + 1), disabled = busy, size = fieldSize)
                                }
                                IconButton(icon = "remove", contentDescription = strings.removeOption, size = FlareControlSize.Sm,
                                    disabled = busy || !removable, onClick = { form = form.removeRow(input, index) })
                            }
                        }
                        Button(label = strings.addOption, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm, icon = "add",
                            disabled = busy || !form.canAddRow(input), onClick = { form = form.addRow(input) })
                    }
                }
                PluginInputKind.Members -> PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    PluginMemberChips((form.draft[input.id] as? List<*>).orEmpty().filterIsInstance<String>(), (members + chosenMembers.values).distinctBy { it.userId })
                    Button(label = strings.select, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm, icon = "person-add",
                        disabled = busy || (onMemberSearch == null && members.isEmpty()), onClick = { pickingRevision = membersRevision; picking = input; onMemberSearch?.invoke("") })
                }
                // 5.5: the currency sits at the input's end, not under it.
                PluginInputKind.Money -> PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    // A money amount is digits and one point: the decimal keyboard, or digits only at scale 0. The
                    // locale's decimal separator is kept as "." (spec moneyInput.typed).
                    Input(value = form.draft[input.id] as? String ?: "", onValueChange = {
                        set(input.id, PluginMoneyInputRules.typed(it, java.text.DecimalFormatSymbols.getInstance().decimalSeparator.toString()))
                    },
                        placeholder = input.placeholder, disabled = busy || input.money?.currency == null, size = fieldSize,
                        error = errorText(input) != null, onSubmit = ::submit, suffix = input.money?.currency,
                        inputMode = if (input.money?.effectiveScale == 0) FlareInputMode.Numeric else FlareInputMode.Decimal)
                }
                PluginInputKind.Location -> PluginFormField(input.label, input.required, input.help,locationStates[input.id]?.error ?: errorText(input), modifier = anchor(input)) {
                    PluginLocationField(input, form.draft[input.id], locationStates[input.id], busy, onLocationAction != null) {
                        locationAction(input, it)
                    }
                }
                // 6.3: the document inputs are capture slots side by side — two a row on a phone, three on a wide
                // window — drawn once at the first of them.
                PluginInputKind.Document -> if (input == documents.firstOrNull()) PluginFormField(null, help = documents.firstNotNullOfOrNull { it.help }, issue = documents.firstNotNullOfOrNull { errorText(it) },modifier = anchor(input)) {
                    val columns = pluginDocumentColumns(phone = flareCompactOverlays())
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                        documents.chunked(columns).forEach { pair ->
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                                pair.forEach { document ->
                                    val state = localFiles[document.id]
                                    Box(Modifier.weight(1f)) {
                                        FlareDocumentSlot(
                                            label = pluginDocumentSideText(document, strings) ?: document.label,
                                            side = FlareDocumentSide.of(document.side?.wire) ?: FlareDocumentSide.Front,
                                            state = pluginDocumentSlotState(state?.phase),
                                            imageUrl = state?.previewUrl,
                                            progress = state?.progress?.takeIf { it.isFinite() }?.let { (it.coerceIn(0.0, 1.0) * 100).toInt() },
                                            disabled = busy || fileCallback == null,
                                            onCapture = { fileAction(document, if ((state?.phase ?: PluginFilePhase.Empty) == PluginFilePhase.Empty) PluginFileActionKind.Choose else PluginFileActionKind.Replace) },
                                            onRetry = { fileAction(document, PluginFileActionKind.Retry) },
                                        )
                                    }
                                }
                                repeat(columns - pair.size) { Box(Modifier.weight(1f)) }
                            }
                        }
                    }
                }
                PluginInputKind.File, PluginInputKind.Image -> PluginFormField(input.label, input.required, input.help,errorText(input), modifier = anchor(input)) {
                    val state = localFiles[input.id] ?: PluginFileState(fileScope, fileGenerations[input.id] ?: 0, PluginFilePhase.Empty)
                    PluginFileInput(input, state, busy || fileCallback == null) { kind -> fileAction(input, kind) }
                }
            }
        }
        error?.takeIf { it.isNotEmpty() }?.let { StatusBanner(text = it, tone = FlareStatusTone.Danger) }
        if (!hideSubmit) Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                if (!embedded) Box(Modifier.weight(1f)) {
                    Button(label = strings.cancel, variant = FlareButtonVariant.Secondary, disabled = busy || onCancel == null, block = true,
                        onClick = { onCancel?.invoke() })
                }
                Box(Modifier.weight(1f)) {
                    Button(label = submitLabel ?: strings.pluginViewSubmit, loading = busy,
                        disabled = onSubmit == null || blocked, block = true, onClick = ::submit)
                }
            }
            submitCaption?.let { Text(it, color = flareColors().textSecondary, fontSize = FlareTextRoles.Caption.fontSize) }
        }
    }

    picking?.let { input ->
        BottomSheet(onClose = { picking = null }, title = input.label, titleHidden = true) {
            ContactPicker(
                groups = listOf(FlareContactPickerGroup(FlareContactPickerGroup.GROUP_MEMBERS, input.label,
                    members.map { FlareContactPickerEntry(it.userId, it.name, it.avatarUrl) })),
                multiple = PluginFormRules.maxItems(input) != 1,
                onSearch = onMemberSearch, loading = membersLoading, error = membersError, onRetry = onMembersRetry,
                title = input.label,
                onSelect = { entries ->
                    if (picking?.id == input.id && latestMemberRevision == pickingRevision && !latestMemberLoading && latestMemberError.isNullOrBlank()) {
                        val selected = entries.mapNotNull { entry -> latestMembers.firstOrNull { it.userId == entry.userId } }.take(PluginFormRules.maxItems(input))
                        chosenMembers = chosenMembers + selected.associateBy { it.userId }
                        picking = null
                        set(input.id, selected.map { it.userId })
                    }
                },
                onCancel = { picking = null },
            )
        }
    }
}

/**
 * One field of a plugin form (R6): the label above (13/500, primary text; a required one adds `*` read as "required"),
 * the control, then one line under it — the error (icon 16 and the caption in the error ink, also the field's error
 * for TalkBack) or the help — with the counter at its end.
 */
@Composable
private fun PluginFormField(
    label: String?,
    required: Boolean = false,
    help: String? = null,
    issue: String? = null,
    counter: String? = null,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(
        modifier.fillMaxWidth().semantics { if (issue != null) this.error(issue) },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        if (label != null) Row(verticalAlignment = Alignment.CenterVertically) {
            Text(label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium)
            // R6: the required mark is `color.error`, read as required.
            if (required) Text("*", color = colors.errorText, fontSize = FlareSizes.fontSizeMd,
                modifier = Modifier.padding(start = 2.dp).semantics { contentDescription = strings.pluginFormRequired })
        }
        content()
        if (issue != null || help != null || counter != null) Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
            Box(Modifier.weight(1f)) {
                if (issue != null) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                    FlareIcon("error", size = FlareSizes.iconSizeSm, tint = colors.errorText)
                    Text(issue, color = colors.errorText, fontSize = FlareTextRoles.Caption.fontSize)
                } else if (help != null) Text(help, color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize)
            }
            counter?.let { Text(it, color = colors.textTertiary, fontSize = FlareTextRoles.Caption.fontSize, modifier = Modifier.padding(start = FlareSizes.spacingSm)) }
        }
    }
}

/**
 * P2 (5.10): a password of exactly 6 characters whose value is digits only (or nothing yet) is a PIN, drawn as six
 * cells; a value with anything else stays a masked field (the cells would drop its other characters).
 */
internal fun pluginPinInput(input: PluginInput, value: Any? = null): Boolean =
    input.kind == PluginInputKind.Password && input.maxLength == 6 && (value as? String).orEmpty().all { it in '0'..'9' }

/** A PIN draft: digits only (full-width folded), at most six. */
internal fun pluginPinDigits(text: String): String = text.mapNotNull { ch ->
    when (ch) {
        in '0'..'9' -> ch
        in '０'..'９' -> '0' + (ch - '０')
        else -> null
    }
}.take(6).joinToString("")

/** What a form's submit may do now, for a submit key drawn outside the form (R2.2 task bar, R6 page form). */
data class PluginFormSubmitState(val enabled: Boolean = true, val caption: String? = null)

/** The chosen members of a members input, as small chips. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PluginMemberChips(ids: List<String>, members: List<PluginMember>) {
    if (ids.isEmpty()) return
    val colors = flareColors()
    FlowRow(
        Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingXs).semantics(mergeDescendants = true) {},
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        ids.forEach { userId ->
            val member = members.firstOrNull { it.userId == userId }
            val name = member?.name ?: PluginViewFormat.fallbackName(userId)
            Row(
                Modifier.clip(RoundedCornerShape(FlareSizes.radiusFull)).background(colors.bgSecondary)
                    .padding(start = FlareSizes.spacing3xs, end = FlareSizes.spacingSm, top = FlareSizes.spacing3xs, bottom = FlareSizes.spacing3xs),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
            ) {
                Avatar(userId = userId, displayName = name, size = 20.dp, avatarUrl = member?.avatarUrl)
                Text(name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, maxLines = 1)
            }
        }
    }
}

/** A datetime value as the kit pickers' "YYYY-MM-DD" and "HH:mm" in the device zone ("" for none). */
internal fun pluginDateParts(ms: Long?, zone: ZoneId = ZoneId.systemDefault()): Pair<String, String> {
    if (ms == null) return "" to ""
    val local = Instant.ofEpochMilli(ms).atZone(zone).toLocalDateTime()
    val pad = { n: Int -> n.toString().padStart(2, '0') }
    return "${local.year}-${pad(local.monthValue)}-${pad(local.dayOfMonth)}" to "${pad(local.hour)}:${pad(local.minute)}"
}

/** The milliseconds of a date and a time in the device zone; null until both are set. */
internal fun pluginDateTimeMs(parts: Pair<String, String>, zone: ZoneId = ZoneId.systemDefault()): Long? {
    val date = runCatching { LocalDate.parse(parts.first) }.getOrNull() ?: return null
    val time = runCatching { LocalTime.parse(parts.second) }.getOrNull() ?: return null
    return LocalDateTime.of(date, time).atZone(zone).toInstant().toEpochMilli()
}

/** A location input: the fix (place, precision and accuracy) or "no location yet", and its locate and clear keys. */
@Composable
internal fun PluginLocationField(
    input: PluginInput,
    draft: Any?,
    state: PluginLocationState?,
    busy: Boolean,
    enabled: Boolean,
    onAction: (PluginLocationActionKind) -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val fix = PluginLocationValue.read(draft, input.precision)
    val locating = state?.locating == true
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        FlareIcon("location")
        Column(Modifier.weight(1f).semantics(mergeDescendants = true) {}) {
            when {
                locating -> Text(strings.pluginLocationLocating, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
                fix != null -> {
                    Text(fix.text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg,
                        modifier = Modifier.testTag("plugin-location-${input.id}-place"))
                    Text("${if (fix.precision == PluginLocationPrecision.Fine) strings.pluginLocationFine else strings.pluginLocationCoarse} · " +
                        strings.pluginLocationAccuracy.replace("{m}", fix.accuracyM.toString()),
                        color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                }
                else -> Text(strings.pluginLocationEmpty, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd,
                    modifier = Modifier.testTag("plugin-location-${input.id}-empty"))
            }
        }
        if (fix != null && !locating) Button(label = strings.pluginLocationClear, variant = FlareButtonVariant.Quiet,
            size = FlareControlSize.Sm, disabled = busy, onClick = { onAction(PluginLocationActionKind.Clear) })
        Button(label = if (fix == null) strings.pluginLocationLocate else strings.pluginLocationRelocate,
            variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm, loading = locating, disabled = busy || !enabled,
            onClick = { onAction(PluginLocationActionKind.Locate) })
    }
}
