package com.flare.im.ui

import java.math.BigInteger

/** The compose page's renderer (docs/plugin-experience.md §4.2, §11): the kit draws [RedPacketComposer] for it. */
const val RED_PACKET_COMPOSE_RENDERER = "redPacket.compose"

/** The packet page's renderer (§4.5, §4.6): the kit draws [RedPacketDetail] with [RedPacketOpenSheet] over it. */
const val RED_PACKET_DETAIL_RENDERER = "redPacket.detail"

/** The confirm page's renderer (§4.3): the kit draws [RedPacketReview]. */
const val RED_PACKET_REVIEW_RENDERER = "redPacket.review"

/**
 * A plugin page the kit draws as a red packet page ([RedPacketPage]): what [redPacketPagePlan] read from a view that
 * declares `redPacket.compose`, `redPacket.detail` or `redPacket.review`. [ownedActionIds] are the view actions the red packet page runs
 * itself; the page host draws the rest as plain keys below it.
 */
sealed interface FlareRedPacketPagePlan {
    val ownedActionIds: List<String>
}

/**
 * A `redPacket.compose` view as the composer reads it: the bound submit [action] (`submit`, else `submitDirect`), the
 * inputs its form collects in form order, the money input, the offered [kinds], the money [scale] and [currency], and
 * the deployment's [maxRecipients] (a positive whole number, else null).
 */
data class FlareRedPacketComposePlan(
    val action: PluginViewAction,
    val inputs: List<PluginInput>,
    val money: PluginInput,
    val kinds: List<FlareRedPacketKind>,
    val scale: Int,
    val currency: String,
    val maxRecipients: Int? = null,
) : FlareRedPacketPagePlan {
    override val ownedActionIds: List<String> get() = listOf(action.id)
}

/** One claim of a `redPacket.detail` view, before the host names the claimant. */
data class FlareRedPacketClaimLine(val id: String, val amountMinor: String, val claimedAtMs: Long, val best: Boolean = false)

/**
 * A `redPacket.detail` view as the detail and the open layer read it: the viewer's [details], the claim lines, the
 * sender and the designated recipients by id, the bound `claim` and `wallet` actions when the view offers them, and
 * whether a paid claim's original command is still unconfirmed ([paidClaimPending]).
 */
data class FlareRedPacketDetailPlan(
    val details: FlareRedPacketDetailsView,
    val claims: List<FlareRedPacketClaimLine>,
    val senderId: String,
    val designatedUserIds: List<String>,
    val claimAction: PluginViewAction?,
    val walletAction: PluginViewAction?,
    val paidClaimPending: Boolean,
) : FlareRedPacketPagePlan {
    override val ownedActionIds: List<String> get() = listOfNotNull(claimAction?.id, walletAction?.id)
}

/**
 * A `redPacket.review` view as the confirm step reads it: the bound submit [action], the total as written ([amount],
 * with its [currency]), the packet's [kind] and [shareCount], the [blessing], and a [kindLabel] the plugin wrote itself.
 */
data class FlareRedPacketReviewPlan(
    val action: PluginViewAction,
    val amount: String,
    val currency: String? = null,
    val kind: FlareRedPacketKind? = null,
    val shareCount: Int? = null,
    val blessing: String? = null,
    val kindLabel: String? = null,
) : FlareRedPacketPagePlan {
    override val ownedActionIds: List<String> get() = listOf(action.id)
}

private const val MAX_SAFE_INTEGER = 9_007_199_254_740_991.0
private val composeInputKinds = setOf(PluginInputKind.Money, PluginInputKind.Text, PluginInputKind.Select, PluginInputKind.Number, PluginInputKind.Members)
private val claimCommands = setOf("flare.redpacket.ui.claim", "flare.redpacket.claim")

private fun Any?.obj(): Map<*, *> = this as? Map<*, *> ?: emptyMap<Any?, Any?>()

/** A JSON whole number from 0 to 2^53 − 1 (the core's numbers arrive as doubles); null otherwise. */
private fun Any?.whole(): Long? = (this as? Number)?.toDouble()
    ?.takeIf { it.isFinite() && it >= 0 && it <= MAX_SAFE_INTEGER && it == Math.floor(it) }?.toLong()

private fun Any?.minorDigits(): Boolean = this is String && isNotEmpty() && all { it in '0'..'9' }

private fun PluginViewModel.renderer(): String? = presentation?.get("renderer") as? String

private fun PluginViewModel.props(): Map<*, *> = presentation?.get("props").obj()

/** The view action the presentation binds to [name]; the engine binds only actions the view shows. */
private fun PluginViewModel.bound(name: String): PluginViewAction? {
    val id = presentation?.get("actions").obj()[name] as? String ?: return null
    return actions.firstOrNull { it.id == id }
}

/** A key the red packet page may run itself: no confirm, no form, not a native target. */
private fun PluginViewAction.plain(): Boolean = confirm == null && form.isNullOrEmpty() && target?.kind != "native"

internal fun redPacketKindOf(value: Any?): FlareRedPacketKind? =
    FlareRedPacketKind.entries.firstOrNull { it.name.lowercase() == value }

internal fun redPacketKindWire(kind: FlareRedPacketKind): String = kind.name.lowercase()

/**
 * The composer's plan for [view], or null — then the page draws the plain document: not `redPacket.compose`, not
 * available, a read-only copy, an original command whose outcome is unknown (the plain page offers its recovery), no
 * bound submit, a submit with a confirm, a native target or no form, a form input the view does not hold or of a kind
 * the composer cannot collect, no money `amount` with a currency, no text `greeting`, or a kind outside
 * normal / lucky / exclusive.
 */
fun redPacketComposePlan(view: PluginViewModel): FlareRedPacketComposePlan? {
    if (view.renderer() != RED_PACKET_COMPOSE_RENDERER || !view.available || view.unavailableReason == PluginUnavailableReason.UnboundCopy) return null
    val props = view.props()
    val journal = props["journal"].obj()
    if (journal["commandId"] is String && journal["known"] == false) return null
    val action = view.bound("submit") ?: view.bound("submitDirect") ?: return null
    val form = action.form.orEmpty()
    if (action.confirm != null || action.target?.kind == "native" || form.isEmpty()) return null
    val inputs = view.formInputs(action)
    if (inputs.size != form.size || inputs.any { it.kind !in composeInputKinds }) return null
    val money = inputs.firstOrNull { it.id == "amount" && it.kind == PluginInputKind.Money } ?: return null
    val currency = money.money?.currency?.takeIf { it.isNotEmpty() } ?: return null
    if (inputs.none { it.id == "greeting" && it.kind == PluginInputKind.Text }) return null
    val kindInput = inputs.firstOrNull { it.id == "kind" }
    val choices = kindInput?.choices.orEmpty()
    val kinds = if (kindInput == null) listOf(FlareRedPacketKind.Normal) else choices.mapNotNull { redPacketKindOf(it.value) }
    if (kinds.isEmpty() || (kindInput != null && kinds.size != choices.size)) return null
    val maxRecipients = props["maxRecipients"].whole()?.takeIf { it in 1..Int.MAX_VALUE }?.toInt()
    return FlareRedPacketComposePlan(action, inputs, money, kinds, money.money?.effectiveScale ?: 2, currency, maxRecipients)
}

/**
 * The detail's plan for [view], or null — then the page draws the plain document: not `redPacket.detail`, not
 * available, or `details` that are not a whole details view (spec dataTypes `RedPacketDetailsView`: a known role,
 * status and kind, a greeting, a currency, an exponent 0..12, whole counts and times, claimsListed, and amounts that
 * are absent or ASCII digits).
 */
fun redPacketDetailPlan(view: PluginViewModel): FlareRedPacketDetailPlan? {
    if (view.renderer() != RED_PACKET_DETAIL_RENDERER || !view.available) return null
    val props = view.props()
    val raw = props["details"] as? Map<*, *> ?: return null
    val role = FlareRedPacketViewerRole.fromWire(raw["viewerRole"] as? String) ?: return null
    val status = FlareRedPacketStatus.fromWire(raw["status"] as? String) ?: return null
    val kind = redPacketKindOf(raw["kind"]) ?: return null
    val greeting = raw["greeting"] as? String ?: return null
    val currency = (raw["currency"] as? String)?.takeIf { it.isNotEmpty() } ?: return null
    val exponent = raw["currencyExponent"].whole()?.takeIf { it <= 12 }?.toInt() ?: return null
    val claimed = raw["claimedCount"].whole()?.takeIf { it <= Int.MAX_VALUE }?.toInt() ?: return null
    val shares = raw["shareCount"].whole()?.takeIf { it <= Int.MAX_VALUE }?.toInt() ?: return null
    val createdAtMs = raw["createdAtMs"].whole() ?: return null
    val expiresAtMs = raw["expiresAtMs"].whole() ?: return null
    val claimsListed = raw["claimsListed"] as? Boolean ?: return null
    val amounts = listOf("totalMinor", "claimedMinor", "refundedMinor", "myAmountMinor")
    if (amounts.any { raw[it] != null && !raw[it].minorDigits() }) return null
    val completedAtMs = raw["completedInMs"].whole()?.let { createdAtMs + it }?.takeIf { it <= MAX_SAFE_INTEGER }
    val details = FlareRedPacketDetailsView(
        viewerRole = role, status = status, kind = kind, greeting = greeting, currency = currency, currencyExponent = exponent,
        claimedCount = claimed, shareCount = shares, createdAtMs = createdAtMs, expiresAtMs = expiresAtMs, claimsListed = claimsListed,
        totalMinor = raw["totalMinor"] as? String, claimedMinor = raw["claimedMinor"] as? String,
        refundedMinor = raw["refundedMinor"] as? String, myAmountMinor = raw["myAmountMinor"] as? String,
        completedAtMs = completedAtMs,
    )
    val claims = (props["claims"] as? List<*>).orEmpty().mapNotNull { item ->
        val row = item as? Map<*, *> ?: return@mapNotNull null
        val id = row["id"] as? String ?: return@mapNotNull null
        val amount = row["amountMinor"].takeIf { it.minorDigits() } as? String ?: return@mapNotNull null
        val at = row["claimedAtMs"].whole() ?: return@mapNotNull null
        FlareRedPacketClaimLine(id, amount, at, row["best"] == true)
    }
    val journal = props["journal"].obj()
    return FlareRedPacketDetailPlan(
        details = details,
        claims = claims,
        senderId = props["senderId"] as? String ?: "",
        designatedUserIds = (raw["designatedUserIds"] as? List<*>).orEmpty().filterIsInstance<String>(),
        claimAction = view.bound("claim")?.takeIf { it.plain() },
        walletAction = view.bound("wallet")?.takeIf { it.plain() },
        paidClaimPending = journal["known"] == false && journal["capabilityId"] in claimCommands &&
            role == FlareRedPacketViewerRole.Claimer && details.myAmountMinor != null,
    )
}

/**
 * The confirm step's plan for [view], or null — then the page draws the plain document (its note, status and recovery
 * stay reachable): not `redPacket.review`, not available, a read-only copy, an original command whose outcome is
 * unknown, or no bound `submit` the page may run itself (no confirm, no form, not native).
 */
fun redPacketReviewPlan(view: PluginViewModel): FlareRedPacketReviewPlan? {
    if (view.renderer() != RED_PACKET_REVIEW_RENDERER || !view.available || view.unavailableReason == PluginUnavailableReason.UnboundCopy) return null
    val props = view.props()
    val journal = props["journal"].obj()
    if (journal["commandId"] is String && journal["known"] == false) return null
    val action = view.bound("submit")?.takeIf { it.plain() } ?: return null
    return FlareRedPacketReviewPlan(
        action = action,
        amount = props["amount"] as? String ?: "",
        currency = (props["currency"] as? String)?.takeIf { it.isNotEmpty() },
        kind = redPacketKindOf(props["kind"]),
        shareCount = props["shareCount"].whole()?.takeIf { it in 1..Int.MAX_VALUE }?.toInt(),
        blessing = (props["blessing"] as? String)?.takeIf { it.isNotEmpty() },
        kindLabel = (props["kindLabel"] as? String)?.takeIf { it.isNotEmpty() },
    )
}

/** The red packet page [view] declares and validates as, or null (the plain document). */
fun redPacketPagePlan(view: PluginViewModel): FlareRedPacketPagePlan? =
    redPacketComposePlan(view) ?: redPacketDetailPlan(view) ?: redPacketReviewPlan(view)

/**
 * A red packet page view whose plan did not read, as the plain document: without its page renderer, so the card
 * dispatcher ([hasResolvedPresentation]) never draws a review over the note, the status and the recovery it covers.
 */
internal fun redPacketPlainView(view: PluginViewModel): PluginViewModel =
    if (view.renderer() in setOf(RED_PACKET_COMPOSE_RENDERER, RED_PACKET_DETAIL_RENDERER, RED_PACKET_REVIEW_RENDERER)) view.copy(presentation = null) else view

/** What the page host still draws under a red packet page: the actions the page does not run, nothing else. */
internal fun redPacketPageRemainder(view: PluginViewModel, plan: FlareRedPacketPagePlan): PluginViewModel {
    val owned = plan.ownedActionIds.toSet()
    return view.copy(title = "", fields = emptyList(), blocks = emptyList(), presentation = null, detail = false,
        actions = view.actions.filterNot { it.id in owned }, menuActions = view.menuActions.filterNot { it.id in owned })
}

// ── the composer page's form ────────────────────────────────────────────────

/** What the viewer typed on the composer page; [recipient] is the exclusive packet's member. */
data class FlareRedPacketDraft(
    val kind: FlareRedPacketKind,
    val amount: String = "",
    val count: Int = 1,
    val greeting: String = "",
    val recipient: PluginMember? = null,
)

/** An error the composer shows: on a field row, or the form's banner ([FlareRedPacketField.Form]). */
internal data class RedPacketIssue(val field: FlareRedPacketField, val text: String)

/** The composer field an input's error belongs to. */
internal fun redPacketFieldFor(inputId: String): FlareRedPacketField = when (inputId) {
    "amount" -> FlareRedPacketField.Amount
    "shareCount" -> FlareRedPacketField.Count
    "greeting" -> FlareRedPacketField.Greeting
    "designatedUserIds" -> FlareRedPacketField.Recipient
    else -> FlareRedPacketField.Form
}

/** The draft by input id: one share for an exclusive packet or a single-kind chat; a blank greeting is the default. */
internal fun redPacketComposeValues(plan: FlareRedPacketComposePlan, draft: FlareRedPacketDraft): Map<String, Any?> {
    val fallback = plan.inputs.firstOrNull { it.id == "greeting" }?.default as? String ?: ""
    return linkedMapOf(
        "kind" to redPacketKindWire(draft.kind),
        "amount" to draft.amount,
        "shareCount" to (if (draft.kind == FlareRedPacketKind.Exclusive || plan.kinds.size == 1) 1 else draft.count),
        "greeting" to PluginFormRules.trimmed(draft.greeting).ifEmpty { fallback },
        "designatedUserIds" to listOfNotNull(draft.recipient?.userId),
    )
}

/** What submit hands over: the plan's visible inputs, as the plain form would send them. */
internal fun redPacketFormValues(plan: FlareRedPacketComposePlan, draft: FlareRedPacketDraft): Map<String, Any?> =
    PluginFormRules.values(plan.inputs, redPacketComposeValues(plan, draft))

/** The packet total in minor units: each share × the count for a normal packet in a group, else the amount. */
internal fun redPacketComposeTotalMinor(plan: FlareRedPacketComposePlan, draft: FlareRedPacketDraft): String? {
    val minor = flareRedPacketAmountMinor(draft.amount, plan.scale) ?: return null
    if (draft.kind != FlareRedPacketKind.Normal || plan.kinds.size == 1) return minor
    return (BigInteger(minor) * BigInteger.valueOf(draft.count.coerceAtLeast(0).toLong())).toString()
}

/** 「金额范围：min–max 币种」 for money rules with both bounds, else null. */
private fun redPacketMoneyRange(rules: PluginMoneyRules?, strings: FlareStrings): String? {
    val min = rules?.min ?: return null
    val max = rules.max ?: return null
    return strings.pluginFormMoneyRange.replace("{min}", min).replace("{max}", max).replace("{currency}", rules.currency.orEmpty())
}

private fun redPacketInputText(input: PluginInput, issue: PluginFormIssue, strings: FlareStrings): String =
    // §4.2: a missing exclusive recipient reads 请选择发给谁, not the generic "<label>: 必填" (as Vue).
    if (redPacketFieldFor(input.id) == FlareRedPacketField.Recipient && (issue == PluginFormIssue.Required || issue == PluginFormIssue.TooFewItems)) {
        strings.packetChooseRecipient
    } else "${input.label}: ${PluginFormRules.issueText(issue, input, strings)}"

/**
 * The first problem with [draft] before a payment is prepared (the web composer's order): each visible input's light
 * check, the share count against the input's range and [FlareRedPacketComposePlan.maxRecipients] (an empty count is
 * required), the amount with its range, then the total against the money input's maximum.
 */
internal fun redPacketComposeIssue(plan: FlareRedPacketComposePlan, draft: FlareRedPacketDraft, strings: FlareStrings): RedPacketIssue? {
    val values = redPacketComposeValues(plan, draft)
    for (input in plan.inputs.filter { it.visibleIn(values) }) {
        val value = values[input.id]
        val issue = if (input.id == "shareCount" && input.kind == PluginInputKind.Number) {
            val count = (value as? Number)?.toInt() ?: 0
            val limit = listOfNotNull(input.max?.toInt()?.takeIf { it > 0 }, plan.maxRecipients).minOrNull()
            if (limit != null && count > limit) {
                return RedPacketIssue(FlareRedPacketField.Count, strings.packetCountLimit.replace("{n}", limit.toString()))
            }
            when {
                count <= 0 -> PluginFormIssue.Required
                (input.min != null && count < input.min) || (input.max != null && count > input.max) -> PluginFormIssue.OutOfRange
                else -> null
            }
        } else PluginFormRules.check(input, value)
        if (issue == null) continue
        val range = if (input.kind == PluginInputKind.Money) redPacketMoneyRange(input.money, strings) else null
        return RedPacketIssue(redPacketFieldFor(input.id), range ?: redPacketInputText(input, issue, strings))
    }
    val maxMinor = plan.money.money?.max?.let { flareRedPacketAmountMinor(it, plan.scale) } ?: return null
    val total = redPacketComposeTotalMinor(plan, draft) ?: return null
    if (BigInteger(total) > BigInteger(maxMinor)) {
        val range = redPacketMoneyRange(plan.money.money, strings) ?: strings.pluginFormOutOfRange
        return RedPacketIssue(FlareRedPacketField.Amount, "${strings.packetFieldTotal}: $range")
    }
    return null
}

/** The host's answer to the last submit: its failure on the form, else its first form error on that field. */
internal fun redPacketHostIssue(plan: FlareRedPacketComposePlan, error: String?, formErrors: List<PluginFormError>, strings: FlareStrings): RedPacketIssue? {
    error?.takeIf { it.isNotEmpty() }?.let { return RedPacketIssue(FlareRedPacketField.Form, it) }
    val first = formErrors.firstOrNull() ?: return null
    val input = plan.inputs.firstOrNull { it.id == first.input }
    val text = input?.let { redPacketInputText(it, first.issue, strings) } ?: PluginFormRules.issueText(first.issue, null, strings)
    return RedPacketIssue(redPacketFieldFor(first.input), text)
}
