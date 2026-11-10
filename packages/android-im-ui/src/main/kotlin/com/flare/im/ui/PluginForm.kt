package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.util.UUID

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
 * [max(min, 1), max]; members through [ContactPicker] over the host's [members] (one pick when max is 1).
 */
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
) {
    val strings = flareStrings()
    var form by remember(inputs, values) { mutableStateOf(PluginFormState.initial(inputs, values)) }
    val fileScope = remember(inputs, values) { UUID.randomUUID().toString() }
    var fileGenerations by remember(fileScope) { mutableStateOf(inputs.filter { it.kind == PluginInputKind.File }.associate { it.id to 0 }) }
    var localFiles by remember(fileScope) {
        mutableStateOf(inputs.filter { it.kind == PluginInputKind.File }.associate { input ->
            val value = pluginFileReference(form.draft[input.id])
            input.id to PluginFileState(fileScope, 0, if (value == null) PluginFilePhase.Empty else PluginFilePhase.Uploaded, value)
        })
    }
    val fileCallback by rememberUpdatedState(onFileAction)
    val disposalFiles by rememberUpdatedState(fileGenerations)
    val disposalDraft by rememberUpdatedState(form.draft)
    DisposableEffect(fileScope) {
        onDispose {
            inputs.filter { it.kind == PluginInputKind.File }.forEach { input ->
                fileCallback?.invoke(PluginFileAction(PluginFileActionKind.Invalidate, input.id, input, fileScope,
                    (disposalFiles[input.id] ?: 0) + 1, PluginFormRules.values(inputs, disposalDraft) - input.id))
            }
        }
    }
    LaunchedEffect(fileScope, fileStates) {
        inputs.filter { it.kind == PluginInputKind.File && it.visibleIn(form.draft) }.forEach { input ->
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
    PluginOnChange(errors) { _, _ -> form = form.hostErrorsChanged() }

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
        if (changed) inputs.filter { it.showWhen?.field == id && it.kind == PluginInputKind.File }
            .forEach { fileAction(it, PluginFileActionKind.Invalidate) }
        if (changed) {
            val dependentIds = inputs.filter { it.showWhen?.field == id }.map { it.id }.toSet()
            numberText = numberText - dependentIds
            dateParts = dateParts - dependentIds
        }
    }
    fun errorText(input: PluginInput) = form.errorText(input, errors, strings)

    Column(
        Modifier.fillMaxWidth().padding(horizontal = if (embedded) 0.dp else FlareSizes.spacingLg, vertical = if (embedded) 0.dp else FlareSizes.spacingMd),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
    ) {
        inputs.filter { it.visibleIn(form.draft) }.forEach { input ->
            when (input.kind) {
                PluginInputKind.Text, PluginInputKind.Password -> FormField(input.label, input.required, PluginFormRules.counter(input, form.draft[input.id]), errorText(input)) {
                    Input(value = form.draft[input.id] as? String ?: "", onValueChange = { set(input.id, it) },
                        placeholder = input.placeholder, disabled = busy, secure = input.kind == PluginInputKind.Password)
                }
                PluginInputKind.Textarea -> FormField(input.label, input.required, PluginFormRules.counter(input, form.draft[input.id]), errorText(input)) {
                    Textarea(value = form.draft[input.id] as? String ?: "", placeholder = input.placeholder, rows = 3, maxRows = 6,
                        disabled = busy, onChange = { set(input.id, it) })
                }
                PluginInputKind.Number -> FormField(input.label, input.required, null, errorText(input)) {
                    Input(value = numberText[input.id].orEmpty(), onValueChange = { raw ->
                        numberText = numberText + (input.id to raw)
                        set(input.id, raw.trim().takeIf { it.isNotEmpty() }?.toDoubleOrNull()?.takeIf { it.isFinite() })
                    }, placeholder = input.placeholder, disabled = busy)
                }
                PluginInputKind.Toggle -> FormField(error = errorText(input)) {
                    Row(Modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, verticalAlignment = Alignment.CenterVertically) {
                        Text(input.label, color = flareColors().textPrimary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
                        Switch(value = form.draft[input.id] as? Boolean ?: false, disabled = busy, onChange = { set(input.id, it) })
                    }
                }
                PluginInputKind.Select -> FormField(input.label, input.required, null, errorText(input)) {
                    RadioGroup(
                        options = input.choices.orEmpty().map { FlareSelectOption(it.value, it.label, disabled = busy) },
                        value = form.draft[input.id] as? String ?: "", vertical = true,
                        onSelect = if (busy) null else ({ set(input.id, it) }),
                    )
                }
                PluginInputKind.Datetime -> FormField(input.label, input.required, null, errorText(input)) {
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
                PluginInputKind.Options -> FormField(input.label, input.required, null, errorText(input)) {
                    val rows = form.rows(input.id)
                    val removable = form.canRemoveRow(input)
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        rows.forEachIndexed { index, row ->
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                                Box(Modifier.weight(1f)) {
                                    Input(value = row, onValueChange = { form = form.setRow(input, index, it) },
                                        placeholder = strings.pollOptionHint(index + 1), disabled = busy)
                                }
                                IconButton(icon = "remove", contentDescription = strings.removeOption, size = FlareControlSize.Sm,
                                    disabled = busy || !removable, onClick = { form = form.removeRow(input, index) })
                            }
                        }
                        Button(label = strings.addOption, variant = FlareButtonVariant.Ghost, size = FlareControlSize.Sm, icon = "add",
                            disabled = busy || !form.canAddRow(input), onClick = { form = form.addRow(input) })
                    }
                }
                PluginInputKind.Members -> FormField(input.label, input.required, null, errorText(input)) {
                    PluginMemberChips((form.draft[input.id] as? List<*>).orEmpty().filterIsInstance<String>(), (members + chosenMembers.values).distinctBy { it.userId })
                    Button(label = strings.select, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm, icon = "person-add",
                        disabled = busy || (onMemberSearch == null && members.isEmpty()), onClick = { pickingRevision = membersRevision; picking = input; onMemberSearch?.invoke("") })
                }
                PluginInputKind.File -> FormField(input.label, input.required, null, errorText(input)) {
                    val state = localFiles[input.id] ?: PluginFileState(fileScope, fileGenerations[input.id] ?: 0, PluginFilePhase.Empty)
                    PluginFileInput(input, state, busy || fileCallback == null) { kind -> fileAction(input, kind) }
                }
            }
        }
        error?.takeIf { it.isNotEmpty() }?.let { StatusBanner(text = it, tone = FlareStatusTone.Danger) }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (!embedded) Box(Modifier.weight(1f)) {
                Button(label = strings.cancel, variant = FlareButtonVariant.Secondary, disabled = busy || onCancel == null, block = true,
                    onClick = { onCancel?.invoke() })
            }
            Box(Modifier.weight(1f)) {
                Button(label = submitLabel ?: strings.pluginViewSubmit, loading = busy,
                    disabled = onSubmit == null || inputs.any { it.visibleIn(form.draft) && it.kind == PluginInputKind.File && pluginFilePending(localFiles[it.id]) }, block = true,
                    onClick = {
                        if (!busy && inputs.none { it.visibleIn(form.draft) && it.kind == PluginInputKind.File && pluginFilePending(localFiles[it.id]) }) {
                            val (next, submitted) = form.submit(inputs)
                            form = next
                            if (submitted != null) { inputs.filter { it.kind == PluginInputKind.Password }.forEach { set(it.id, "") }; onSubmit?.invoke(submitted) }
                        }
                    })
            }
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
