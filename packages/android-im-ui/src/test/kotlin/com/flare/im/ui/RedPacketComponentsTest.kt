package com.flare.im.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The red packet family's rules, without a UI: the card's status order and interactivity, the open layer's copy
 * per state, the composer's field formats and labels, and the payment confirmation's gate. Copy is read from the
 * strings table, so a translation does not break these and a missing field does.
 */
class RedPacketComponentsTest {
    private val zh = FlareStrings()
    private val en = flareStringsEnglish()

    @Test fun cardStatusFollowsTheContractOrder() {
        fun status(
            state: FlareRedPacketCardState,
            label: String? = null,
            busy: Boolean = false,
            disabled: Boolean = false,
        ) = redPacketCardStatus(state, label, busy, disabled, zh)

        assertEquals(zh.packetBusy, status(FlareRedPacketCardState.Claimed, "Created", busy = true))
        assertEquals("Created", status(FlareRedPacketCardState.Claimed, "Created"))
        assertEquals(zh.packetStateClaimed, status(FlareRedPacketCardState.Claimed))
        assertEquals(zh.packetFinished, status(FlareRedPacketCardState.Finished, disabled = true))
        assertEquals(zh.packetStateExpired, status(FlareRedPacketCardState.Expired, disabled = true))
        assertEquals(zh.packetRefunded, status(FlareRedPacketCardState.Refunded))
        assertEquals(zh.packetUnavailable, status(FlareRedPacketCardState.Unopened, disabled = true))
        assertEquals(zh.packetView, status(FlareRedPacketCardState.Viewable))
        assertEquals(zh.packetTapToClaim, status(FlareRedPacketCardState.Unopened))
        assertEquals("已被领完", zh.packetFinished)
        assertEquals("Flare 红包", zh.packetBrand)
    }

    /** `spec/red-packet-vectors.json`, the table the four kits run. */
    private fun vectors(): Map<*, *> = SpecTables.table("red-packet-vectors.json")

    private val copy: Map<*, *> by lazy { vectors().obj("cardCopy")!!.obj("zh")!! }

    private fun cardState(name: String?) = FlareRedPacketCardState.entries.first { it.name.equals(name, ignoreCase = true) }

    @Test fun cardStateComesFromTheTwoLayers() {
        val cases = vectors().items("cardState")
        assertTrue(cases.size >= 11, "the shared table lost cases: ${cases.size}")
        for (case in cases) {
            val view = case.obj("view")!!
            val got = flareRedPacketCardState(
                status = FlareRedPacketStatus.fromWire(view.str("status"))!!,
                claimedByMe = view.bool("claimedByMe") ?: false,
                tapAction = FlareRedPacketTapAction.fromWire(view.str("tapAction")),
            )
            assertEquals(cardState(case.str("state")), got, case.str("id"))
        }
    }

    @Test fun cardFollowsTheSharedTable() {
        val cases = vectors().items("card")
        assertTrue(cases.size >= 11, "the shared table lost cases: ${cases.size}")
        for (case in cases) {
            val id = case.str("id")!!
            val state = cardState(case.str("state"))
            val label = case.str("statusLabel")
            val busy = case.bool("busy") ?: false
            val disabled = case.bool("disabled") ?: false
            val expected = when (val status = case.str("status")) {
                "statusLabel" -> label
                "busy", "tapToOpen", "view", "claimed", "finished", "expired", "refunded", "unavailable" -> copy.str(status)
                else -> error("unknown status $status in $id")
            }
            val got = redPacketCardStatus(state, label, busy, disabled, zh)
            assertEquals(expected, got, id)
            assertEquals(case["tappable"], redPacketCardInteractive(busy, disabled, hasHandler = true), id)
            assertEquals(case["dimmed"], redPacketCardFaded(state), id)
        }
        // The card's copy is the shared copy: zh from the table, and no amount anywhere on it.
        assertEquals(copy.str("tapToOpen"), zh.packetTapToClaim)
        assertEquals(copy.str("view"), zh.packetView)
        assertEquals(copy.str("refunded"), zh.packetRefunded)
    }

    @Test fun kindBadgeAndRecipientFollowTheTable() {
        for (case in vectors().items("cardBadge")) {
            val id = case.str("id")!!
            val kind = FlareRedPacketKind.entries.first { it.name.equals(case.str("kind"), ignoreCase = true) }
            val badge = redPacketCardBadge(kind, case.str("recipientName"), zh)
            assertEquals(case.str("zh"), badge.badge, "$id badge")
            assertEquals(case.obj("recipient")?.str("zh"), badge.recipient, "$id recipient")
        }
    }

    @Test fun theOpenSheetOffersTheTablesKeys() {
        for (case in vectors().items("openSheet")) {
            val id = case.str("id")!!
            val state = FlareRedPacketOpenState.entries.first { it.name.equals(case.str("state"), ignoreCase = true) }
            assertEquals(case.bool("coin"), redPacketOpenShowsButton(state), "$id coin")
            assertEquals(case.bool("details"), redPacketOpenShowsDetails(state, case.bool("canViewDetails") ?: true), "$id details")
        }
    }

    @Test fun aRefundedPacketSaysSoAndOffersItsDetails() {
        val cases = vectors().items("openSheetRefunded").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) {
            val id = case.str("id")!!
            val state = FlareRedPacketOpenState.entries.first { it.name.equals(case.str("state"), ignoreCase = true) }
            assertEquals(case.bool("coin"), redPacketOpenShowsButton(state), "$id coin")
            assertEquals(case.bool("details"), redPacketOpenShowsDetails(state, case.bool("canViewDetails") ?: true), "$id details")
            assertEquals(case.obj("headline")!!.str("zh"), redPacketOpenHeadline(state, "Wish", null, zh), "$id zh")
            assertEquals(case.obj("headline")!!.str("en"), redPacketOpenHeadline(state, "Wish", null, en), "$id en")
        }
        assertEquals("Gone back", redPacketOpenHeadline(FlareRedPacketOpenState.Refunded, "Wish", "Gone back", zh))
    }

    @Test fun theAmountFieldKeepsTheCurrencysDecimals() {
        val table = vectors()
        val cases = table.items("amountInputExponent").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(cases.isNotEmpty())
        for (case in cases) assertEquals(case.str("output"), sanitizeRedPacketAmount(case.str("input")!!, case.int("exponent")!!), case.str("id"))
        val minor = table.items("amountMinor").filter { (it["platforms"] as List<*>).contains("compose") }
        assertTrue(minor.isNotEmpty())
        for (case in minor) assertEquals(case.str("minor"), flareRedPacketAmountMinor(case.str("input")!!, case.int("exponent")!!), case.str("id"))
        for (case in table.obj("amountPlaceholder")!!.items("cases")) {
            assertEquals(case.str("placeholder"), flareRedPacketAmountText("0", flareRedPacketExponent(case.int("exponent")!!)), "placeholder ${case.int("exponent")}")
        }
        assertEquals(9, flareRedPacketExponent(9))
        assertEquals(12, flareRedPacketExponent(99))
        assertEquals(0, flareRedPacketExponent(-1))
    }

    @Test fun amountsFormatFromMinorUnits() {
        val table = vectors().obj("amount")!!
        val symbols = table.obj("symbols")!!
        for ((code, symbol) in symbols) assertEquals("${symbol}1.00", flareRedPacketMoney("100", 2, code as String), code)
        val cases = table.items("cases")
        assertTrue(cases.size >= 12)
        for (case in cases) {
            val minor = case.str("minor")
            val exponent = case.int("exponent")!!
            val currency = case.str("currency")!!
            assertEquals(case.str("text"), flareRedPacketAmountText(minor, exponent), "$minor/$exponent")
            assertEquals(case.str("money"), flareRedPacketMoney(minor, exponent, currency), "$minor $currency")
        }
    }

    @Test fun theDetailsDrawWhatTheServerReturned() {
        val detail = vectors().obj("detail")!!
        val now = detail.long("nowMs")!!
        val zone = detail.int("utcOffsetMinutes")!!
        val words = detail.obj("copy")!!.obj("zh")!!
        // The kit's copy is the table's copy.
        for ((key, field) in listOf(
            "summarySender" to zh.packetSummarySender, "summaryCompleted" to zh.packetSummaryCompleted,
            "summaryCount" to zh.packetSummaryCount, "refundAt" to zh.packetRefundAt, "refundedNote" to zh.packetRefundedNote,
            "deposited" to zh.packetDeposited, "missed" to zh.packetMissed, "expired" to zh.packetExpiredNotice,
            "notEligibleName" to zh.packetNotEligibleName, "notEligible" to zh.packetNotEligible,
        )) assertEquals(words.str(key), field, key)
        val cases = detail.items("cases")
        assertTrue(cases.size >= 15)
        for (case in cases) {
            val id = case.str("id")!!
            val d = case.obj("details")!!
            val view = FlareRedPacketDetailsView(
                viewerRole = FlareRedPacketViewerRole.fromWire(d.str("viewerRole"))!!,
                status = FlareRedPacketStatus.fromWire(d.str("status"))!!,
                kind = FlareRedPacketKind.entries.first { it.name.equals(d.str("kind"), ignoreCase = true) },
                greeting = d.str("greeting")!!,
                currency = d.str("currency")!!,
                currencyExponent = d.int("currencyExponent")!!,
                claimedCount = d.int("claimedCount")!!,
                shareCount = d.int("shareCount")!!,
                createdAtMs = d.long("createdAtMs")!!,
                expiresAtMs = d.long("expiresAtMs")!!,
                claimsListed = d.bool("claimsListed")!!,
                totalMinor = d.str("totalMinor"),
                claimedMinor = d.str("claimedMinor"),
                refundedMinor = d.str("refundedMinor"),
                myAmountMinor = d.str("myAmountMinor"),
                completedAtMs = d.long("completedAtMs"),
                refundedAtMs = d.long("refundedAtMs"),
            )
            val shown = RedPacketDetailFormat.presentation(view, case.str("designatedName"), now, zh, zone)
            val expect = case.obj("expect")!!
            assertEquals(expect.str("amount"), shown.amount, "$id amount")
            assertEquals(expect.bool("deposited"), shown.deposited, "$id deposited")
            assertEquals(expect.str("headline"), shown.headline, "$id headline")
            assertEquals(expect.str("summary"), shown.summary, "$id summary")
            assertEquals(expect.bool("claims"), shown.claims, "$id claims")
            assertEquals(expect.str("note"), shown.note, "$id note")
        }
    }

    @Test fun fieldsFormatAsTheSharedTableSays() {
        val table = vectors()
        val amounts = table["amountInput"] as List<*>
        assertTrue(amounts.size >= 13)
        for (raw in amounts) {
            val case = raw as Map<*, *>
            assertEquals(case["output"], sanitizeRedPacketAmount(case["input"] as String), case["id"] as String)
        }
        val counts = table["countInput"] as List<*>
        assertTrue(counts.size >= 7)
        for (raw in counts) {
            val case = raw as Map<*, *>
            assertEquals((case["output"] as Number).toInt(), sanitizeRedPacketCount(case["input"] as String), case["id"] as String)
        }
        assertEquals("", redPacketCountText(0))
        assertEquals("12", redPacketCountText(12))
    }

    private fun hex(value: String): Color = Color(("FF" + value.removePrefix("#")).toLong(16))

    private fun channels(c: Color): List<Int> = listOf(c.red, c.green, c.blue).map { (it * 255).roundToInt() }

    private fun contrast(a: Color, b: Color): Double {
        val (x, y) = a.luminance().toDouble() to b.luminance().toDouble()
        return (maxOf(x, y) + 0.05) / (minOf(x, y) + 0.05)
    }

    /** Light and dark: the mix target, the ink, every faded stop, and the ink's contrast on the text stops. */
    @Test fun spentCardsFadeAsTheSharedTableSays() {
        val table = vectors()["faded"] as Map<*, *>
        assertEquals((table["mix"] as Number).toFloat(), FlareSizes.componentRedPacketFadedMix)
        val minimum = (table["minTextContrast"] as Number).toDouble()
        val dark = table["dark"] as Map<*, *>
        for ((isDark, mode) in listOf(false to table, true to dark)) {
            val colors = FlareColors.resolve(FlareBrandTheme.Violet, isDark)
            val tokens = mapOf(
                "colors.redPacket.start" to colors.redPacketStart,
                "colors.redPacket.middle" to colors.redPacketMiddle,
                "colors.redPacket.end" to colors.redPacketEnd,
                "colors.redPacket.gold" to colors.redPacketGold,
                "colors.redPacket.goldDeep" to colors.redPacketGoldDeep,
            )
            val where = if (isDark) "dark" else "light"
            assertEquals(channels(hex(mode["target"] as String)), channels(colors.redPacketFadedMixTarget), where)
            assertEquals(channels(hex(mode["ink"] as String)), channels(colors.redPacketFadedInk), where)
            val stops = mode["stops"] as List<*>
            assertEquals(5, stops.size)
            for (raw in stops) {
                val stop = raw as Map<*, *>
                val name = stop["token"] as String
                val base = tokens.getValue(name)
                assertEquals(channels(hex(stop["base"] as String)), channels(base), "$where $name")
                for ((got, want) in channels(redPacketFade(base, colors)).zip(channels(hex(stop["faded"] as String)))) {
                    assertTrue(abs(got - want) <= 1, "$where $name: $got vs $want")
                }
            }
            for (name in table["textStops"] as List<*>) {
                val faded = redPacketFade(tokens.getValue(name as String), colors)
                assertTrue(contrast(colors.redPacketFadedInk, faded) >= minimum, "$where: the spent card's text on $name")
            }
        }
    }

    @Test fun composerRowsFollowTheSharedTable() {
        val cases = vectors()["composer"] as List<*>
        assertTrue(cases.size >= 6)
        fun kind(name: Any?) = FlareRedPacketKind.entries.first { it.name.equals(name as String, ignoreCase = true) }
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val kinds = (case["kinds"] as List<*>).map(::kind)
            val shown = redPacketShownKind(kind(case["kind"]), kinds)
            val label = when (case["amountLabel"]) {
                "total" -> zh.packetFieldTotal
                "each" -> zh.packetFieldEach
                "amount" -> zh.packetFieldAmount
                else -> error("unknown label ${case["amountLabel"]} in $id")
            }
            assertEquals(label, redPacketAmountLabel(shown, kinds, zh), id)
            assertEquals(case["showsCount"], redPacketShowsCount(shown, kinds), id)
            assertEquals(case["showsRecipient"], shown == FlareRedPacketKind.Exclusive, id)
        }
    }

    /** Red packets and every other custom card are the card surface: no bubble around them, quoted or not (P0-1). */
    @Test fun aCustomCardIsACardSurfaceWithoutABubble() {
        val packet = FlareGenericContent(contentType = "custom.flare.redpacket.card", label = "Red packet")
        val plain = FlareMessageData(id = "m1", senderId = "u1", senderName = "Ann", content = packet)
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(plain), "a custom body is a card by default")
        val chrome = messageSurfaceChrome(flareMessageSurface(plain), tail = true)
        assertFalse(chrome.background || chrome.padding || chrome.tail || chrome.shadow)
        val quoting = plain.copy(replyTo = FlareReplyTarget(messageId = "m0", senderName = "Bo", summary = "hi"))
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(quoting), "the quote goes inside the card's shell")
        assertEquals(FlareMessageSurface.BareMedia, flareMessageSurface(plain.copy(content = FlareImageContent(url = "https://example.com/a.png"))), "pictures stay bare")
    }

    @Test fun onlyBusyDisabledOrUnhandledCardsAreInert() {
        assertTrue(redPacketCardInteractive(busy = false, disabled = false, hasHandler = true))
        assertFalse(redPacketCardInteractive(busy = true, disabled = false, hasHandler = true))
        assertFalse(redPacketCardInteractive(busy = false, disabled = true, hasHandler = true))
        assertFalse(redPacketCardInteractive(busy = false, disabled = false, hasHandler = false))
        assertFalse(redPacketCardFaded(FlareRedPacketCardState.Unopened))
        assertFalse(redPacketCardFaded(FlareRedPacketCardState.Viewable))
        for (state in listOf(FlareRedPacketCardState.Claimed, FlareRedPacketCardState.Finished, FlareRedPacketCardState.Expired,
            FlareRedPacketCardState.Refunded)) {
            assertTrue(redPacketCardFaded(state), state.name)
        }
    }

    @Test fun openLayerCopyForEveryState() {
        fun headline(state: FlareRedPacketOpenState, message: String? = null) =
            redPacketOpenHeadline(state, "Wish", message, zh)
        fun hint(state: FlareRedPacketOpenState, message: String? = null) = redPacketOpenHint(state, message, zh)

        assertEquals("Wish", headline(FlareRedPacketOpenState.Ready))
        assertEquals("Wish", headline(FlareRedPacketOpenState.Opening))
        assertEquals("Wish", headline(FlareRedPacketOpenState.Error))
        assertEquals(zh.packetMissed, headline(FlareRedPacketOpenState.Finished))
        assertEquals(zh.packetExpiredNotice, headline(FlareRedPacketOpenState.Expired))
        assertEquals(zh.packetNotEligible, headline(FlareRedPacketOpenState.NotEligible))
        assertEquals("Only Ann", headline(FlareRedPacketOpenState.NotEligible, "Only Ann"))
        assertEquals("Gone", headline(FlareRedPacketOpenState.Finished, "Gone"), "the host's message replaces the kit's copy")
        assertEquals("Refunded", headline(FlareRedPacketOpenState.Expired, "Refunded"))
        assertEquals(zh.packetExpiredNotice, headline(FlareRedPacketOpenState.Expired, ""), "an empty message is no message")
        assertEquals("Wish", headline(FlareRedPacketOpenState.Ready, "Only Ann"))
        for (state in FlareRedPacketOpenState.entries.filter { it != FlareRedPacketOpenState.Error }) {
            assertNull(hint(state, "Only Ann"), state.name)
        }
        assertEquals(zh.packetOpenFailed, hint(FlareRedPacketOpenState.Error))
        assertEquals(zh.packetOpenFailed, hint(FlareRedPacketOpenState.Error, ""))
        assertEquals("Network", hint(FlareRedPacketOpenState.Error, "Network"))

        assertEquals(
            listOf(FlareRedPacketOpenState.Ready, FlareRedPacketOpenState.Opening, FlareRedPacketOpenState.Error),
            FlareRedPacketOpenState.entries.filter(::redPacketOpenShowsButton),
        )
        assertEquals(
            listOf(FlareRedPacketOpenState.Finished, FlareRedPacketOpenState.Expired, FlareRedPacketOpenState.Refunded),
            FlareRedPacketOpenState.entries.filter { redPacketOpenShowsDetails(it) },
            "a not-eligible viewer never gets the details",
        )
        assertTrue(FlareRedPacketOpenState.entries.none { redPacketOpenShowsDetails(it, canViewDetails = false) })
    }

    @Test fun envelopeKeepsAGutterOnNarrowWindows() {
        assertEquals(FlareSizes.componentRedPacketEnvelopeWidth, redPacketEnvelopeWidth(1024.dp))
        assertEquals(320.dp - FlareSizes.spacingXl * 2, redPacketEnvelopeWidth(320.dp))
        assertEquals(0.dp, redPacketEnvelopeWidth(10.dp))
    }

    @Test fun amountLabelFollowsTheKind() {
        val group = FlareRedPacketKind.entries
        assertEquals(zh.packetFieldTotal, redPacketAmountLabel(FlareRedPacketKind.Lucky, group, zh))
        assertEquals(zh.packetFieldEach, redPacketAmountLabel(FlareRedPacketKind.Normal, group, zh))
        assertEquals(zh.packetFieldAmount, redPacketAmountLabel(FlareRedPacketKind.Normal, listOf(FlareRedPacketKind.Normal), zh))
        assertEquals(zh.packetFieldAmount, redPacketAmountLabel(FlareRedPacketKind.Exclusive, group, zh))
        assertEquals(FlareRedPacketKind.Normal, redPacketShownKind(FlareRedPacketKind.Lucky, listOf(FlareRedPacketKind.Normal)))
        assertEquals(FlareRedPacketKind.Exclusive, redPacketShownKind(FlareRedPacketKind.Exclusive, FlareRedPacketKind.entries))
        assertEquals(
            listOf(zh.packetKindLucky, zh.packetKindNormal, zh.packetKindExclusive),
            FlareRedPacketKind.entries.map { redPacketKindLabel(it, zh) },
        )
    }

    @Test fun payConfirmNeedsBalanceAndNothingRunning() {
        assertTrue(redPacketPayConfirmEnabled(insufficient = false, busy = false))
        assertFalse(redPacketPayConfirmEnabled(insufficient = true, busy = false))
        assertFalse(redPacketPayConfirmEnabled(insufficient = false, busy = true))
    }

    @Test fun englishPresetCoversTheFamily() {
        assertEquals("张三的红包", zh.packetFromSender("张三"))
        assertEquals("Red packet from Ann", en.packetFromSender("Ann"))
        assertEquals("Opened", en.packetStateClaimed)
        assertEquals("Put money in", en.packetSubmit)
        assertEquals("Insufficient balance", en.packetInsufficient)
        val pairs = listOf(
            zh.packetStateExpired to en.packetStateExpired, zh.packetKindLucky to en.packetKindLucky,
            zh.packetOpenAction to en.packetOpenAction, zh.packetMissed to en.packetMissed,
            zh.packetViewDetails to en.packetViewDetails, zh.packetBestLuck to en.packetBestLuck,
            zh.packetNoClaims to en.packetNoClaims, zh.packetFieldEach to en.packetFieldEach,
            zh.packetDefaultGreeting to en.packetDefaultGreeting, zh.packetPayTitle to en.packetPayTitle,
            zh.packetPayConfirm to en.packetPayConfirm, zh.packetCountPlaceholder to en.packetCountPlaceholder,
            zh.packetKindPicker to en.packetKindPicker, zh.packetClaims to en.packetClaims,
        )
        for ((chinese, english) in pairs) assertNotEquals(chinese, english)
    }
}
