package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier

/**
 * A plugin page drawn as a red packet page (docs/plugin-experience.md §4, §11: from 「+」 to the details, red packet
 * layout throughout). [FlarePluginPage] draws it for a view whose renderer is `redPacket.compose` or `redPacket.detail`
 * and whose [plan] ([redPacketPagePlan]) reads; any other view stays the plain document.
 *
 * - Compose ([FlareRedPacketComposePlan]): [RedPacketComposer] over the plan's inputs. The total follows the kind (each
 *   share × the count for a normal packet in a group); submit checks the draft first (each visible input, the count
 *   against the deployment's limit, the total against the money maximum), puts the first problem on its row and moves
 *   focus there, else runs the bound submit with the form values. The host's failure goes on the form, its first form
 *   error on its row until the draft changes. An exclusive packet's recipient comes from [members] in the kit
 *   [ContactPicker]. The view's danger and warning notes show above.
 * - Review ([FlareRedPacketReviewPlan], `redPacket.review`): [RedPacketReview] with the total, the kind and count, the
 *   blessing and the bound submit; the view's danger and warning notes show above.
 * - Detail ([FlareRedPacketDetailPlan]): [RedPacketDetail] with the names from [members], else [resolveUser]; the bound
 *   `wallet` action makes 「已存入钱包」 a key. While the bound `claim` action is offered, [RedPacketOpenSheet] covers it:
 *   開 runs the claim (opening while [busyActionId] or [refreshing]), an error offers the result ([onRefresh]); closing
 *   it leaves the page ([onBack]), the result key shows the details with a claim key. A claim that lands reads the page
 *   again, which no longer offers it: the details show.
 *
 * An action this page ran that settles cleanly asks for a read ([onRefresh] with `action`, R4). [contentState] is the
 * host's memory of this page on its stack: the composer keeps its draft there, so going on to the wallet and coming
 * back finds it as it was (a recipient only while [members] still holds them).
 */
@Composable
fun RedPacketPage(
    plan: FlareRedPacketPagePlan,
    view: PluginViewModel,
    onAction: ((String, PluginActionPayload) -> Unit)?,
    modifier: Modifier = Modifier,
    busyActionId: String? = null,
    refreshing: Boolean = false,
    error: String? = null,
    formErrors: List<PluginFormError> = emptyList(),
    settleToken: Int = 0,
    members: List<PluginMember> = emptyList(),
    membersLoading: Boolean = false,
    membersError: String? = null,
    membersRevision: Int = 0,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    onRefresh: ((PluginRefreshReason) -> Unit)? = null,
    onBack: (() -> Unit)? = null,
    /** The group's size counting the viewer, from the host's own group or conversation data (never members.size). */
    memberCount: Int? = null,
    /** The host's server-corrected now for the details' times. */
    nowMs: Long? = null,
    /** The host's memory of this page on its stack (dropped when the page leaves it): the composer's draft. */
    contentState: MutableMap<String, Any?>? = null,
) {
    val busy = busyActionId != null || refreshing
    // R4: an action this page ran that settles with no error and no form errors reads the page again.
    var ran by remember { mutableStateOf(false) }
    PluginOnChange(PluginHostSignal(busy, busyActionId, error, formErrors, settleToken)) { old, new ->
        if (ran && new.settleToken != old.settleToken) {
            // The host's onRefresh drops an `action` read while the page is covered (PluginPage gates it on shownNow).
            if (pluginSettledRefresh(ran, old, new, visible = true)) onRefresh?.invoke(PluginRefreshReason.Action)
            ran = false
        }
    }
    val run = onAction?.let { emit -> { id: String, payload: PluginActionPayload -> ran = true; emit(id, payload) } }
    when (plan) {
        is FlareRedPacketComposePlan -> RedPacketComposePage(plan, view, run, modifier, busy, error, formErrors, settleToken,
            members, membersLoading, membersError, membersRevision, onMemberSearch, onMembersRetry, onRefresh, contentState, memberCount)
        is FlareRedPacketDetailPlan -> RedPacketDetailPage(plan, run, modifier, busy, error, members, resolveUser, onRefresh, onBack, nowMs)
        is FlareRedPacketReviewPlan -> RedPacketReviewPage(plan, view, run, modifier, busy, error)
    }
}

/** The view's danger and warning notes, above a red packet page. */
@Composable
private fun RedPacketNotes(view: PluginViewModel) {
    view.blocks.filterIsInstance<PluginNoteBlock>().filter { it.tone == PluginTone.Danger || it.tone == PluginTone.Warning }.forEach { note ->
        StatusBanner(text = note.text, tone = if (note.tone == PluginTone.Danger) FlareStatusTone.Danger else FlareStatusTone.Warning)
    }
}

/** 「拼手气红包 · 3 个」: the plugin's own label, else the kit's kind name with the share count when there is one. */
internal fun redPacketReviewKindLabel(plan: FlareRedPacketReviewPlan, strings: FlareStrings): String? =
    plan.kindLabel ?: plan.kind?.let { kind ->
        val label = redPacketKindLabel(kind, strings)
        plan.shareCount?.let { "$label · ${"$it ${strings.packetCountUnit}".trim()}" } ?: label
    }

/** The draft [contentState] kept for [plan]: its kind if still offered, its recipient if still a member; else null. */
/** 「本群共 N 人」: the host's group size (viewer included), in a group only (more than one kind on offer). */
internal fun redPacketMemberCount(plan: FlareRedPacketComposePlan, count: Int?): Int? = count?.takeIf { it > 0 && plan.kinds.size > 1 }

internal fun redPacketRestoredDraft(contentState: Map<String, Any?>?, plan: FlareRedPacketComposePlan, members: List<PluginMember>): FlareRedPacketDraft? {
    val saved = contentState?.get(RED_PACKET_DRAFT_KEY) as? FlareRedPacketDraft ?: return null
    return saved.copy(
        kind = saved.kind.takeIf { it in plan.kinds } ?: plan.kinds.first(),
        recipient = saved.recipient?.takeIf { picked -> members.any { it.userId == picked.userId } },
    )
}

internal const val RED_PACKET_DRAFT_KEY = "redPacketDraft"

@Composable
private fun RedPacketReviewPage(
    plan: FlareRedPacketReviewPlan,
    view: PluginViewModel,
    onAction: ((String, PluginActionPayload) -> Unit)?,
    modifier: Modifier,
    busy: Boolean,
    error: String?,
) {
    val strings = flareStrings()
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        RedPacketNotes(view)
        RedPacketReview(
            amount = plan.currency?.let { FlarePaymentRules.amountText(plan.amount, it) } ?: plan.amount,
            kindLabel = redPacketReviewKindLabel(plan, strings), blessing = plan.blessing, submitLabel = plan.action.label,
            busy = busy, error = error?.takeIf { it.isNotEmpty() },
            onSubmit = onAction?.let { emit -> { if (!busy) emit(plan.action.id, PluginActionPayload.Empty) } },
        )
    }
}

@Composable
private fun RedPacketComposePage(
    plan: FlareRedPacketComposePlan,
    view: PluginViewModel,
    onAction: ((String, PluginActionPayload) -> Unit)?,
    modifier: Modifier,
    busy: Boolean,
    error: String?,
    formErrors: List<PluginFormError>,
    settleToken: Int,
    members: List<PluginMember>,
    membersLoading: Boolean,
    membersError: String?,
    membersRevision: Int,
    onMemberSearch: ((String) -> Unit)?,
    onMembersRetry: (() -> Unit)?,
    onRefresh: ((PluginRefreshReason) -> Unit)?,
    contentState: MutableMap<String, Any?>?,
    memberCount: Int?,
) {
    val strings = flareStrings()
    val greeting = plan.inputs.firstOrNull { it.id == "greeting" }?.default as? String ?: ""
    var draft by remember(plan.action.id, contentState) {
        mutableStateOf(redPacketRestoredDraft(contentState, plan, members) ?: FlareRedPacketDraft(kind = plan.kinds.first(), greeting = greeting))
    }
    var attempted by remember(plan.action.id) { mutableStateOf(false) }
    // The host's form errors stand until the draft changes; a new settle brings them back.
    var hostErrors by remember(plan.action.id) { mutableStateOf(true) }
    var picking by remember(plan.action.id) { mutableStateOf(false) }
    var focus by remember { mutableStateOf<FlareRedPacketField?>(null) }
    PluginOnChange(settleToken) { _, _ -> hostErrors = true }
    // Another member list: a recipient picked from the old one no longer stands.
    PluginOnChange(membersRevision) { _, _ -> draft = draft.copy(recipient = null); picking = false }
    fun edit(next: FlareRedPacketDraft) { draft = next; hostErrors = false; contentState?.set(RED_PACKET_DRAFT_KEY, next) }
    val issue = redPacketHostIssue(plan, error, formErrors.takeIf { hostErrors }.orEmpty(), strings)
        ?: if (attempted) redPacketComposeIssue(plan, draft, strings) else null
    val total = flareRedPacketMoney(redPacketComposeTotalMinor(plan, draft) ?: "0", plan.scale, plan.currency).orEmpty()
    fun submit() {
        val emit = onAction ?: return
        if (busy) return
        attempted = true
        val problem = redPacketComposeIssue(plan, draft, strings)
        if (problem != null) { if (problem.field != FlareRedPacketField.Form) focus = problem.field; return }
        emit(plan.action.id, PluginActionPayload(formValues = redPacketFormValues(plan, draft)))
    }
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        RedPacketNotes(view)
        RedPacketComposer(
            kinds = plan.kinds, kind = draft.kind, amount = draft.amount, total = total,
            count = draft.count, greeting = draft.greeting, error = issue?.text, busy = busy, locked = onAction == null,
            submitLabel = plan.action.label, currencyExponent = plan.scale,
            onKindChange = { edit(draft.copy(kind = it)) },
            onAmountChange = { edit(draft.copy(amount = it)) },
            onCountChange = { edit(draft.copy(count = it)) },
            onGreetingChange = { edit(draft.copy(greeting = it)) },
            onSubmit = ::submit,
            recipient = {
                Button(label = draft.recipient?.name ?: strings.select, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm,
                    disabled = busy || onAction == null, maintainTouchTarget = true,
                    onClick = { if (!busy) { picking = true; onMemberSearch?.invoke("") } })
            },
            errorField = issue?.field, focusField = focus,
            currencySymbol = FlarePaymentRules.prefix[plan.currency.uppercase(java.util.Locale.ROOT)],
            memberCount = redPacketMemberCount(plan, memberCount),
        )
        // A failure may have landed anyway: reading the page again shows where it stands.
        if (!error.isNullOrEmpty() && onRefresh != null) {
            Button(label = strings.pluginPageRefresh, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm,
                loading = busy, disabled = busy, onClick = { onRefresh(PluginRefreshReason.Key) })
        }
    }
    if (picking) BottomSheet(onClose = { picking = false }, title = strings.packetFieldRecipient, titleHidden = true) {
        ContactPicker(
            groups = listOf(FlareContactPickerGroup(FlareContactPickerGroup.GROUP_MEMBERS, strings.packetFieldRecipient,
                members.map { FlareContactPickerEntry(it.userId, it.name, it.avatarUrl) })),
            title = strings.packetFieldRecipient,
            onSearch = onMemberSearch, loading = membersLoading, error = membersError, onRetry = onMembersRetry,
            onSelect = { entries ->
                members.firstOrNull { it.userId == entries.firstOrNull()?.userId }?.let { edit(draft.copy(recipient = it)) }
                picking = false
            },
            onCancel = { picking = false },
        )
    }
}

@Composable
private fun RedPacketDetailPage(
    plan: FlareRedPacketDetailPlan,
    onAction: ((String, PluginActionPayload) -> Unit)?,
    modifier: Modifier,
    busy: Boolean,
    error: String?,
    members: List<PluginMember>,
    resolveUser: (suspend (String) -> PluginUser?)?,
    onRefresh: ((PluginRefreshReason) -> Unit)?,
    onBack: (() -> Unit)?,
    nowMs: Long?,
) {
    val strings = flareStrings()
    val ids = remember(plan) { (listOf(plan.senderId) + plan.claims.map { it.id } + plan.designatedUserIds).filter { it.isNotEmpty() }.distinct() }
    var people by remember { mutableStateOf<Map<String, PluginUser>>(emptyMap()) }
    LaunchedEffect(ids, members, resolveUser) {
        val local = ids.mapNotNull { id -> members.firstOrNull { it.userId == id }?.let { id to PluginUser(it.name, it.avatarUrl) } }.toMap()
        people = local + (resolveUser?.let { pluginResolvedUsers(ids, local, it) }.orEmpty())
    }
    val unknown = strings.displayNameUnknownUser
    val sender = people[plan.senderId]
    var dismissed by remember { mutableStateOf(false) }
    val claim = plan.claimAction
    val failure = error?.takeIf { it.isNotEmpty() }
    fun runClaim() { if (!busy && claim != null) onAction?.invoke(claim.id, PluginActionPayload.Empty) }
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        failure?.let {
            if (plan.paidClaimPending) StatusBanner(text = strings.packetClaimPendingReview, tone = FlareStatusTone.Warning)
            else StatusBanner(text = it, tone = FlareStatusTone.Danger)
        }
        RedPacketDetail(
            senderName = sender?.name ?: unknown, details = plan.details, senderAvatar = sender?.avatarUrl,
            designatedName = plan.designatedUserIds.firstOrNull()?.let { people[it]?.name },
            claims = plan.claims.map { line ->
                FlareRedPacketClaim(line.id, people[line.id]?.name ?: unknown, line.amountMinor, line.claimedAtMs, people[line.id]?.avatarUrl, line.best)
            },
            nowMs = nowMs,
            onDeposited = plan.walletAction?.let { wallet -> { if (!busy) onAction?.invoke(wallet.id, PluginActionPayload.Empty) } },
        )
        if (claim != null && dismissed) Box(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg)) {
            RedPacketMoneyTint {
                Button(label = claim.label, size = FlareControlSize.Lg, block = true, loading = busy, disabled = onAction == null,
                    onClick = { dismissed = false })
            }
        }
    }
    if (claim != null && !dismissed) RedPacketOpenSheet(
        senderName = sender?.name ?: unknown,
        blessing = plan.details.greeting,
        // Closing the layer leaves the page; without a way back it shows the details instead.
        onClose = { if (onBack != null) onBack() else dismissed = true },
        senderAvatar = sender?.avatarUrl,
        kindLabel = redPacketKindLabel(plan.details.kind, strings),
        state = when {
            busy -> FlareRedPacketOpenState.Opening
            failure != null -> FlareRedPacketOpenState.Error
            else -> FlareRedPacketOpenState.Ready
        },
        message = failure,
        onOpen = ::runClaim,
        onViewDetails = {
            dismissed = true
            if (failure != null && !busy) onRefresh?.invoke(PluginRefreshReason.Key)
        },
        reviewOnError = onRefresh != null,
    )
}
