package com.flare.im.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.unit.dp
import java.io.File
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
            state: FlareRedPacketState,
            amount: String? = null,
            label: String? = null,
            busy: Boolean = false,
            disabled: Boolean = false,
        ) = redPacketCardStatus(state, amount, label, busy, disabled, zh)

        assertEquals(zh.packetBusy, status(FlareRedPacketState.Claimed, "¥1", "Created", busy = true))
        assertEquals("Created", status(FlareRedPacketState.Claimed, "¥1", "Created"))
        assertEquals(zh.packetClaimed("¥1"), status(FlareRedPacketState.Claimed, "¥1"))
        assertEquals(zh.packetStateClaimed, status(FlareRedPacketState.Claimed))
        assertEquals(zh.packetFinished, status(FlareRedPacketState.Finished, disabled = true))
        assertEquals(zh.packetStateExpired, status(FlareRedPacketState.Expired, disabled = true))
        assertEquals(zh.packetUnavailable, status(FlareRedPacketState.Unopened, disabled = true))
        assertEquals(zh.packetTapToClaim, status(FlareRedPacketState.Unopened))
        assertEquals("已被领完", zh.packetFinished)
        assertEquals("Flare 红包", zh.packetBrand)
    }

    /** `spec/red-packet-vectors.json`, the table the four kits run. */
    private fun vectors(): Map<*, *> {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/red-packet-vectors.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            dir = dir.parentFile
        }
        error("spec/red-packet-vectors.json not found above ${File(".").absolutePath}")
    }

    @Test fun cardFollowsTheSharedTable() {
        val cases = vectors()["card"] as List<*>
        assertTrue(cases.size >= 10, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val state = FlareRedPacketState.entries.first { it.name.equals(case["state"] as String, ignoreCase = true) }
            val amount = case["amount"] as String?
            val label = case["statusLabel"] as String?
            val busy = case["busy"] as Boolean? ?: false
            val disabled = case["disabled"] as Boolean? ?: false
            val expected = when (case["status"]) {
                "busy" -> zh.packetBusy
                "statusLabel" -> label
                "claimedAmount" -> zh.packetClaimed(amount!!)
                "claimed" -> zh.packetStateClaimed
                "finished" -> zh.packetFinished
                "expired" -> zh.packetStateExpired
                "unavailable" -> zh.packetUnavailable
                "tapToOpen" -> zh.packetTapToClaim
                else -> error("unknown status ${case["status"]} in $id")
            }
            assertEquals(expected, redPacketCardStatus(state, amount, label, busy, disabled, zh), id)
            assertEquals(case["tappable"], redPacketCardInteractive(busy, disabled, hasHandler = true), id)
            assertEquals(case["dimmed"], redPacketCardFaded(state), id)
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

    @Test fun aCustomTypeListedAsBareDrawsWithoutABubbleUnlessItQuotes() {
        val packet = FlareGenericContent(contentType = "redpacket", label = "Red packet")
        val plain = FlareMessageData(id = "m1", senderId = "u1", senderName = "Ann", content = packet)
        assertFalse(isBareMedia(packet), "a custom body has a bubble by default")
        assertTrue(isBareMedia(packet, customBare = true))
        assertFalse(messageBubbleChromeless(plain))
        assertTrue(messageBubbleChromeless(plain, customBare = true))
        val quoting = plain.copy(replyTo = FlareReplyTarget(messageId = "m0", senderName = "Bo", summary = "hi"))
        assertFalse(messageBubbleChromeless(quoting, customBare = true), "a quote needs the bubble around it")
        assertTrue(isBareMedia(FlareImageContent(url = "https://example.com/a.png")), "pictures stay bare")
    }

    @Test fun onlyBusyDisabledOrUnhandledCardsAreInert() {
        assertTrue(redPacketCardInteractive(busy = false, disabled = false, hasHandler = true))
        assertFalse(redPacketCardInteractive(busy = true, disabled = false, hasHandler = true))
        assertFalse(redPacketCardInteractive(busy = false, disabled = true, hasHandler = true))
        assertFalse(redPacketCardInteractive(busy = false, disabled = false, hasHandler = false))
        assertFalse(redPacketCardFaded(FlareRedPacketState.Unopened))
        for (state in listOf(FlareRedPacketState.Claimed, FlareRedPacketState.Finished, FlareRedPacketState.Expired)) {
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
            listOf(FlareRedPacketOpenState.Finished, FlareRedPacketOpenState.Expired, FlareRedPacketOpenState.NotEligible),
            FlareRedPacketOpenState.entries.filter(::redPacketOpenShowsDetails),
        )
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
