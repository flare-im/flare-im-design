package com.flare.im.ui

import androidx.compose.ui.input.key.Key
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The red packet renderers (`redPacket.compose`, `redPacket.detail`, `redPacket.review`, docs/plugin-experience.md §11): which views read as
 * a red packet page and which stay the plain document, what the composer page checks and sends, and the component
 * rules fixed with them (§4.2, §4.5, §12.12).
 */
class RedPacketPageTest {
    private val zh = FlareStrings()

    private val inputs = """[
        {"id":"kind","kind":"select","label":"红包类型","required":true,"default":"normal","choices":[{"value":"normal","label":"普通红包"},{"value":"lucky","label":"拼手气"},{"value":"exclusive","label":"专属红包"}]},
        {"id":"amount","kind":"money","label":"金额","required":true,"money":{"currency":"CNY","scale":2,"min":"0.01","max":"10.00"}},
        {"id":"shareCount","kind":"number","label":"份数","required":true,"min":1,"max":100,"default":1},
        {"id":"greeting","kind":"text","label":"祝福语","required":true,"maxLength":128,"default":"恭喜发财，大吉大利"},
        {"id":"designatedUserIds","kind":"members","label":"专属接收人","required":true,"min":1,"max":1,"showWhen":{"field":"kind","anyOf":["exclusive"]}}
    ]"""

    private fun compose(
        action: String = """{"id":"prepare","label":"塞钱进红包","style":"primary","form":["kind","amount","shareCount","greeting","designatedUserIds"]}""",
        presentation: String = """{"renderer":"redPacket.compose","props":{"maxRecipients":4},"actions":{"submit":"prepare"}}""",
        extra: String = "",
    ) = PluginViewModel.fromJson("""{"available":true,"title":"发红包","actions":[$action],"inputs":$inputs,"presentation":$presentation$extra}""")

    private val details = """{"viewerRole":"eligible","status":"open","kind":"lucky","greeting":"祝福","currency":"CNY","currencyExponent":2,
        "claimedCount":1,"shareCount":3,"createdAtMs":1000,"expiresAtMs":100000,"claimsListed":true,"completedInMs":500}"""

    private fun detail(details: String = this.details, actions: String = """[{"id":"claim","label":"领取红包"},{"id":"cancel","label":"取消","style":"danger","confirm":"确定？"}]""",
                       bound: String = """{"claim":"claim"}""", journal: String = "{}") = PluginViewModel.fromJson(
        """{"available":true,"title":"红包详情","actions":$actions,"presentation":{"renderer":"redPacket.detail","props":{
            "details":$details,"senderId":"sender","journal":$journal,
            "claims":[{"id":"u1","amountMinor":"88","claimedAtMs":2000,"best":true},{"id":"u2","amountMinor":"x","claimedAtMs":1},{"amountMinor":"1","claimedAtMs":1}]
        },"actions":$bound}}""")

    // ── renderer mapping ─────────────────────────────────────────────────────

    @Test fun aGroupComposeViewReadsAsTheComposer() {
        val plan = assertNotNull(redPacketComposePlan(compose()))
        assertEquals("prepare", plan.action.id)
        assertEquals(listOf(FlareRedPacketKind.Normal, FlareRedPacketKind.Lucky, FlareRedPacketKind.Exclusive), plan.kinds)
        assertEquals(listOf("kind", "amount", "shareCount", "greeting", "designatedUserIds"), plan.inputs.map { it.id })
        assertEquals("CNY", plan.currency)
        assertEquals(2, plan.scale)
        assertEquals(4, plan.maxRecipients)
        assertEquals(listOf("prepare"), plan.ownedActionIds)
        assertIs<FlareRedPacketComposePlan>(redPacketPagePlan(compose()))
    }

    @Test fun aDirectChatOffersOneOrdinaryPacket() {
        val view = compose(
            action = """{"id":"prepareDirect","label":"塞钱进红包","form":["amount","greeting"]}""",
            presentation = """{"renderer":"redPacket.compose","props":{},"actions":{"submitDirect":"prepareDirect"}}""",
        )
        val plan = assertNotNull(redPacketComposePlan(view))
        assertEquals(listOf(FlareRedPacketKind.Normal), plan.kinds)
        assertNull(plan.maxRecipients)
        val draft = FlareRedPacketDraft(FlareRedPacketKind.Normal, amount = "0.01", greeting = "")
        assertEquals(mapOf("amount" to mapOf("amount" to "0.01", "currency" to "CNY"), "greeting" to "恭喜发财，大吉大利"), redPacketFormValues(plan, draft))
    }

    @Test fun composeViewsTheComposerCannotTakeStayPlain() {
        val prepare = """{"id":"prepare","label":"塞钱进红包","form":["kind","amount","shareCount","greeting","designatedUserIds"]"""
        val plain = listOf(
            compose(presentation = """{"renderer":"redPacket.card","props":{},"actions":{"submit":"prepare"}}"""),
            // Payments unavailable: the engine binds no submit.
            compose(presentation = """{"renderer":"redPacket.compose","props":{},"actions":{}}"""),
            compose(presentation = """{"renderer":"redPacket.compose","props":{"journal":{"commandId":"c1","known":false}},"actions":{"submit":"prepare"}}"""),
            compose(action = "$prepare,\"confirm\":\"确定？\"}"),
            compose(action = "$prepare,\"target\":{\"kind\":\"native\",\"capability\":\"camera\"}}"),
            compose(action = """{"id":"prepare","label":"塞钱进红包","form":["kind","amount","missing"]}"""),
            compose(action = """{"id":"prepare","label":"塞钱进红包","form":["kind","amount","shareCount"]}"""),
            compose(extra = ""","unavailableReason":"unbound_copy""""),
            PluginViewModel.fromJson("""{"available":true,"title":"发红包","actions":[$prepare}],"inputs":${inputs.replace("\"exclusive\",\"label\"", "\"golden\",\"label\"")},"presentation":{"renderer":"redPacket.compose","props":{},"actions":{"submit":"prepare"}}}"""),
            PluginViewModel.fromJson("""{"available":true,"title":"发红包","actions":[$prepare}],"inputs":${inputs.replace("\"currency\":\"CNY\",", "")},"presentation":{"renderer":"redPacket.compose","props":{},"actions":{"submit":"prepare"}}}"""),
        )
        plain.forEachIndexed { i, view -> assertNull(redPacketComposePlan(view), "case $i reads as the composer") }
        assertNull(redPacketPagePlan(compose().copy(available = false)))
        // A known unknown outcome is a journal with known false; a settled one composes.
        assertNotNull(redPacketComposePlan(compose(presentation = """{"renderer":"redPacket.compose","props":{"journal":{"commandId":"c1","known":true}},"actions":{"submit":"prepare"}}""")))
    }

    @Test fun aPacketViewReadsAsTheDetail() {
        val plan = assertNotNull(redPacketDetailPlan(detail()))
        assertEquals(FlareRedPacketViewerRole.Eligible, plan.details.viewerRole)
        assertEquals(FlareRedPacketKind.Lucky, plan.details.kind)
        assertEquals(1500L, plan.details.completedAtMs)
        assertNull(plan.details.totalMinor)
        assertEquals(listOf(FlareRedPacketClaimLine("u1", "88", 2000, best = true)), plan.claims)
        assertEquals("sender", plan.senderId)
        assertEquals("claim", plan.claimAction?.id)
        assertNull(plan.walletAction)
        assertFalse(plan.paidClaimPending)
        assertEquals(listOf("claim"), plan.ownedActionIds)
        // The detail page keeps the actions it does not run.
        assertEquals(listOf("cancel"), redPacketPageRemainder(detail(), plan).actions.map { it.id })
        assertNull(redPacketPageRemainder(detail(), plan).presentation)
    }

    @Test fun aClaimerSeesTheWalletKeyAndAPendingOriginal() {
        val claimer = details.replace("\"eligible\"", "\"claimer\"").replace("\"claimsListed\":true", "\"claimsListed\":true,\"myAmountMinor\":\"88\"")
        val plan = assertNotNull(redPacketDetailPlan(detail(
            details = claimer,
            actions = """[{"id":"wallet","label":"查看钱包","target":{"kind":"page"}}]""",
            bound = """{"wallet":"wallet"}""",
            journal = """{"known":false,"commandId":"c1","capabilityId":"flare.redpacket.ui.claim"}""",
        )))
        assertEquals("wallet", plan.walletAction?.id)
        assertNull(plan.claimAction)
        assertTrue(plan.paidClaimPending)
        assertEquals(listOf("wallet"), plan.ownedActionIds)
    }

    @Test fun packetViewsTheDetailCannotTrustStayPlain() {
        val broken = listOf(
            details.replace("\"eligible\"", "\"owner\""),
            details.replace("\"open\"", "\"funding\""),
            details.replace("\"lucky\"", "\"golden\""),
            details.replace("\"currency\":\"CNY\"", "\"currency\":\"\""),
            details.replace("\"currencyExponent\":2", "\"currencyExponent\":13"),
            details.replace("\"shareCount\":3", "\"shareCount\":2.5"),
            details.replace("\"createdAtMs\":1000", "\"createdAtMs\":-1"),
            details.replace("\"claimsListed\":true", "\"claimsListed\":\"yes\""),
            details.replace("\"claimsListed\":true", "\"claimsListed\":true,\"myAmountMinor\":\"not-money\""),
        )
        broken.forEachIndexed { i, raw -> assertNull(redPacketDetailPlan(detail(details = raw)), "case $i reads as the detail") }
        // A claim behind a confirm is not the open layer's to run.
        assertNull(redPacketDetailPlan(detail(actions = """[{"id":"claim","label":"领取红包","confirm":"确定？"}]"""))?.claimAction)
        assertNull(redPacketDetailPlan(compose()))
    }

    // ── the composer page ───────────────────────────────────────────────────

    @Test fun theDraftIsCheckedBeforeAPaymentIsPrepared() {
        val plan = assertNotNull(redPacketComposePlan(compose()))
        fun issue(draft: FlareRedPacketDraft) = redPacketComposeIssue(plan, draft, zh)
        val ok = FlareRedPacketDraft(FlareRedPacketKind.Normal, amount = "0.01", count = 2, greeting = "")
        assertNull(issue(ok))
        // The deployment allows 4 shares, the input 100: the smaller one stands.
        assertEquals(FlareRedPacketField.Count, issue(ok.copy(count = 8))?.field)
        assertEquals(FlareRedPacketField.Count, issue(ok.copy(count = 0))?.field)
        assertEquals(FlareRedPacketField.Amount, issue(ok.copy(amount = ""))?.field)
        assertEquals(FlareRedPacketField.Amount, issue(ok.copy(amount = "20"))?.field)
        // 4 shares of 6.00 is 24.00, over the 10.00 maximum.
        assertEquals(FlareRedPacketField.Amount, issue(ok.copy(amount = "6.00", count = 4))?.field)
        assertEquals("2400", redPacketComposeTotalMinor(plan, ok.copy(amount = "6.00", count = 4)))
        // A lucky total is the amount whatever the count.
        assertEquals("600", redPacketComposeTotalMinor(plan, ok.copy(kind = FlareRedPacketKind.Lucky, amount = "6.00", count = 4)))
        assertEquals(FlareRedPacketField.Recipient, issue(ok.copy(kind = FlareRedPacketKind.Exclusive))?.field)
        // §4.2: the missing recipient says whom to choose, not "专属接收人: 必填".
        assertEquals("请选择发给谁", issue(ok.copy(kind = FlareRedPacketKind.Exclusive))?.text)
        assertNull(issue(ok.copy(kind = FlareRedPacketKind.Exclusive, recipient = PluginMember("u9", "周屿"))))
    }

    @Test fun submitSendsTheVisibleInputsAsThePlainFormWould() {
        val plan = assertNotNull(redPacketComposePlan(compose()))
        assertEquals(
            mapOf("kind" to "normal", "amount" to mapOf("amount" to "0.01", "currency" to "CNY"), "shareCount" to 2.0, "greeting" to "恭喜发财，大吉大利"),
            redPacketFormValues(plan, FlareRedPacketDraft(FlareRedPacketKind.Normal, amount = "0.01", count = 2, greeting = "  ")),
        )
        assertEquals(
            mapOf("kind" to "exclusive", "amount" to mapOf("amount" to "1", "currency" to "CNY"), "shareCount" to 1.0, "greeting" to "Hi",
                "designatedUserIds" to listOf("u9")),
            redPacketFormValues(plan, FlareRedPacketDraft(FlareRedPacketKind.Exclusive, amount = "1", count = 5, greeting = "Hi", recipient = PluginMember("u9", "周屿"))),
        )
    }

    @Test fun theHostsAnswerGoesOnTheFormOrItsField() {
        val plan = assertNotNull(redPacketComposePlan(compose()))
        assertEquals(RedPacketIssue(FlareRedPacketField.Form, "网络暂不可用"), redPacketHostIssue(plan, "网络暂不可用", emptyList(), zh))
        assertEquals(FlareRedPacketField.Count, redPacketHostIssue(plan, null, listOf(PluginFormError("shareCount", PluginFormIssue.OutOfRange)), zh)?.field)
        assertEquals(RedPacketIssue(FlareRedPacketField.Recipient, "请选择发给谁"),
            redPacketHostIssue(plan, null, listOf(PluginFormError("designatedUserIds", PluginFormIssue.Required)), zh))
        assertNull(redPacketHostIssue(plan, "", emptyList(), zh))
    }

    // ── component rows (§4.2, §4.5, §12.12) ─────────────────────────────────

    @Test fun theComposerWaitsOnAZeroTotalOrAFieldError() {
        val kinds = listOf(FlareRedPacketKind.Normal)
        assertTrue(redPacketComposerBlocked(kinds, "", 2, locked = false, fieldError = false))
        assertTrue(redPacketComposerBlocked(kinds, "0", 2, locked = false, fieldError = false))
        assertTrue(redPacketComposerBlocked(kinds, "0.00", 2, locked = false, fieldError = false))
        assertTrue(redPacketComposerBlocked(kinds, "0.01", 2, locked = false, fieldError = true))
        assertTrue(redPacketComposerBlocked(emptyList(), "0.01", 2, locked = false, fieldError = false))
        assertFalse(redPacketComposerBlocked(kinds, "0.01", 2, locked = false, fieldError = false))
    }

    @Test fun theGreetingKeepsTwentyFourCharacters() {
        assertEquals("恭喜发财，大吉大利", redPacketGreeting("恭喜发财，大吉大利"))
        assertEquals("a".repeat(24), redPacketGreeting("a".repeat(30)))
        // Counted in code points: an emoji is one character and is never cut in half.
        val emoji = "🧧".repeat(30)
        assertEquals(24, redPacketGreeting(emoji).codePointCount(0, redPacketGreeting(emoji).length))
    }

    @Test fun theOpenLayerStaysWhileTheClaimRuns() {
        assertFalse(redPacketOpenDismissible(FlareRedPacketOpenState.Opening))
        FlareRedPacketOpenState.entries.filter { it != FlareRedPacketOpenState.Opening }.forEach { assertTrue(redPacketOpenDismissible(it), "$it") }
        assertTrue(redPacketOpenKey(Key.Enter))
        assertTrue(redPacketOpenKey(Key.NumPadEnter))
        assertTrue(redPacketOpenKey(Key.Spacebar))
        assertFalse(redPacketOpenKey(Key.Escape))
        assertEquals(800, RedPacketMetrics.flipMillis)
        // §12.12: an error keeps 開 as the retry unless the host can show the result.
        assertTrue(redPacketOpenShowsButton(FlareRedPacketOpenState.Error))
        assertFalse(redPacketOpenShowsButton(FlareRedPacketOpenState.Error, reviewOnError = true))
    }

    // ── round 2: strings, review, draft ────────────────────────────────────

    @Test fun limitsReadInTheKitsOwnWords() {
        val plan = assertNotNull(redPacketComposePlan(compose()))
        val ok = FlareRedPacketDraft(FlareRedPacketKind.Normal, amount = "0.01", count = 2)
        assertEquals("最多可发 4 个红包", redPacketComposeIssue(plan, ok.copy(count = 8), zh)?.text)
        assertEquals("金额范围：0.01–10.00 CNY", redPacketComposeIssue(plan, ok.copy(amount = "20"), zh)?.text)
        assertEquals("${zh.packetFieldTotal}: 金额范围：0.01–10.00 CNY", redPacketComposeIssue(plan, ok.copy(amount = "6.00", count = 4), zh)?.text)
    }

    private fun review(props: String = """{"amount":"26.64","currency":"CNY","kind":"lucky","shareCount":3,"blessing":"恭喜发财","journal":{}}""",
                       actions: String = """[{"id":"commit","label":"发送红包"},{"id":"recovery","label":"查看待确认操作"}]""",
                       bound: String = """{"submit":"commit"}""") = PluginViewModel.fromJson(
        """{"available":true,"title":"发送已授权红包","actions":$actions,"blocks":[{"kind":"note","text":"勿重复扣款","tone":"warning"}],
            "presentation":{"renderer":"redPacket.review","props":$props,"actions":$bound}}""")

    @Test fun theConfirmPageReadsAsTheReviewAndElseStaysPlain() {
        val plan = assertNotNull(redPacketReviewPlan(review()))
        assertEquals("commit", plan.action.id)
        assertEquals(FlareRedPacketKind.Lucky, plan.kind)
        assertEquals(3, plan.shareCount)
        assertEquals(listOf("commit"), plan.ownedActionIds)
        assertIs<FlareRedPacketReviewPlan>(redPacketPagePlan(review()))
        assertEquals("拼手气红包 · 3 个", redPacketReviewKindLabel(plan, zh))
        assertEquals("¥26.64", FlarePaymentRules.amountText(plan.amount, plan.currency!!))
        // The recovery stays a plain key under it.
        assertEquals(listOf("recovery"), redPacketPageRemainder(review(), plan).actions.map { it.id })
        // An unknown original, no bound submit, or a submit behind a confirm: the plain document, without the renderer.
        val unknown = review(props = """{"amount":"1","journal":{"commandId":"c","known":false}}""")
        assertNull(redPacketReviewPlan(unknown))
        assertNull(redPacketPlainView(unknown).presentation)
        assertNull(redPacketReviewPlan(review(bound = "{}")))
        assertNull(redPacketReviewPlan(review(actions = """[{"id":"commit","label":"发送红包","confirm":"确定？"}]""")))
        assertNull(redPacketPagePlan(review().copy(unavailableReason = PluginUnavailableReason.UnboundCopy)))
    }

    @Test fun aGroupComposerCountsTheMembersAndKeepsItsDraftOnTheStack() {
        val plan = assertNotNull(redPacketComposePlan(compose()))
        // 「本群共 N 人」 is the host's group size (viewer included), never the member rows.
        assertEquals(12, redPacketMemberCount(plan, 12))
        assertNull(redPacketMemberCount(plan, null))
        assertNull(redPacketMemberCount(plan, 0))
        val member = PluginMember("u9", "周屿")
        val state = mutableMapOf<String, Any?>(RED_PACKET_DRAFT_KEY to
            FlareRedPacketDraft(FlareRedPacketKind.Exclusive, amount = "0.01", count = 3, greeting = "Keep", recipient = member))
        assertEquals(FlareRedPacketDraft(FlareRedPacketKind.Exclusive, "0.01", 3, "Keep", member), redPacketRestoredDraft(state, plan, listOf(member)))
        // A recipient no longer offered is not restored; nothing saved restores nothing.
        assertNull(redPacketRestoredDraft(state, plan, emptyList())?.recipient)
        assertNull(redPacketRestoredDraft(mutableMapOf(), plan, listOf(member)))
        // A direct chat's composer offers only normal: a saved kind it does not offer falls back.
        val direct = assertNotNull(redPacketComposePlan(compose(
            action = """{"id":"prepareDirect","label":"塞钱进红包","form":["amount","greeting"]}""",
            presentation = """{"renderer":"redPacket.compose","props":{},"actions":{"submitDirect":"prepareDirect"}}""")))
        assertEquals(FlareRedPacketKind.Normal, redPacketRestoredDraft(state, direct, listOf(member))?.kind)
        assertNull(redPacketMemberCount(direct, 2), "a direct chat has no group size")
    }

    @Test fun theCardAndThePagesAreNotTheSameRenderer() {
        assertFalse(hasResolvedPresentation(compose()))
        assertFalse(hasResolvedPresentation(detail()))
        assertTrue(RED_PACKET_COMPOSE_RENDERER in PluginUiVocabulary.renderers)
        assertTrue(RED_PACKET_DETAIL_RENDERER in PluginUiVocabulary.renderers)
    }
}
