package com.flare.im.ui

import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHeightIsAtLeast
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertWidthIsAtLeast
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.click
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.dp
import androidx.test.platform.app.InstrumentationRegistry
import kotlin.math.abs
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test

/**
 * The red packet family on a device: what each state draws, what reaches the host, the touch targets, the layer's
 * close paths and the opening motion under the system's animation setting. Copy comes from the strings table.
 */
class RedPacketComponentsInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val zh = FlareStrings()
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private var previousScale = 1f

    private fun animatorScale(): Float =
        Settings.Global.getFloat(instrumentation.targetContext.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f)

    private fun setAnimatorScale(value: Float) {
        instrumentation.uiAutomation.executeShellCommand("settings put global animator_duration_scale $value").close()
        val deadline = System.currentTimeMillis() + 5_000
        while (animatorScale() != value && System.currentTimeMillis() < deadline) Thread.sleep(50)
    }

    @Before fun rememberSetting() {
        previousScale = animatorScale()
    }

    @After fun restoreSetting() {
        setAnimatorScale(previousScale)
    }

    private fun content(body: @Composable () -> Unit) = compose.setContent { FlareThemeProvider { body() } }

    // MARK: Card

    @Test fun everyCardStateOpensAndShowsItsStatus() {
        val state = mutableStateOf(FlareRedPacketState.Unopened)
        val opened = mutableListOf<FlareRedPacketState>()
        content { RedPacketCard(blessing = "Hello", kindLabel = "Lucky", state = state.value, onOpen = { opened += state.value }) }
        compose.onNodeWithText("Lucky").assertExists()
        compose.onNodeWithText(zh.packetBrand).assertExists()
        compose.onNodeWithText("Hello").assertHeightIsAtLeast(FlareSizes.touchTarget)
        val statuses = mapOf(
            FlareRedPacketState.Unopened to zh.packetTapToClaim,
            FlareRedPacketState.Claimed to zh.packetStateClaimed,
            FlareRedPacketState.Finished to zh.packetFinished,
            FlareRedPacketState.Expired to zh.packetStateExpired,
        )
        for ((next, status) in statuses) {
            compose.runOnIdle { state.value = next }
            compose.onNodeWithText("Hello")
                .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, status))
                .assertIsEnabled()
                .performClick()
        }
        assertEquals(FlareRedPacketState.entries, opened)
    }

    /** A busy or unavailable card is drawn exactly like an open one showing the same status: nothing dims it. */
    @Test fun inertCardsKeepTheirColours() {
        content {
            // Far enough apart that no card's shadow reaches into another card's box.
            Column(Modifier.width(300.dp).padding(FlareSizes.spacing2xl * 2),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xl * 2)) {
                RedPacketCard(blessing = "Busy", busy = true, onOpen = {})
                RedPacketCard(blessing = "Busy", statusLabel = zh.packetBusy, onOpen = {})
                RedPacketCard(blessing = "Off", disabled = true, onOpen = {})
                RedPacketCard(blessing = "Off", statusLabel = zh.packetUnavailable, onOpen = {})
            }
        }
        for (blessing in listOf("Busy", "Off")) {
            val (inert, open) = compose.onAllNodesWithText(blessing).let { it[0] to it[1] }
            inert.assertIsNotEnabled()
            open.assertIsEnabled()
            // The two boxes sit at different sub-pixel offsets, so anti-aliased edges differ by a step or two;
            // dimming or greying would move the whole face.
            val a = averageColour(inert.captureToImage().asAndroidBitmap())
            val b = averageColour(open.captureToImage().asAndroidBitmap())
            for (channel in 0..2) {
                assertTrue("$blessing: the inert card must keep the open card's colours ($a vs $b)", abs(a[channel] - b[channel]) < 2.0)
            }
        }
    }

    private fun averageColour(bitmap: android.graphics.Bitmap): List<Double> {
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        val sums = DoubleArray(3)
        for (p in pixels) {
            sums[0] += (p shr 16 and 0xFF).toDouble()
            sums[1] += (p shr 8 and 0xFF).toDouble()
            sums[2] += (p and 0xFF).toDouble()
        }
        return sums.map { it / pixels.size }
    }

    // MARK: Custom bodies in the timeline

    /** A type listed in `bareTypes` is drawn without the bubble's padding (or surface); an unlisted one keeps it. */
    @Test fun aBareCustomBodyLosesTheBubbleAndAFramedOneKeepsIt() {
        val body: FlareContentBuilder = { content, _ ->
            Box(Modifier.size(120.dp, 60.dp).testTag((content as FlareGenericContent).label))
        }
        fun message(label: String) = FlareMessageData(
            id = label, senderId = "u1", senderName = "Ann",
            content = FlareGenericContent(contentType = "redpacket", label = label),
        )
        content {
            Column {
                FlareContentScope(builders = mapOf("redpacket" to body), bareTypes = setOf("redpacket")) {
                    MessageBubble(message = message("bare"), currentUserId = "me")
                }
                FlareContentScope(builders = mapOf("redpacket" to body)) {
                    MessageBubble(message = message("framed"), currentUserId = "me")
                }
            }
        }
        val bare = compose.onNodeWithTag("bare").getUnclippedBoundsInRoot()
        val framed = compose.onNodeWithTag("framed").getUnclippedBoundsInRoot()
        assertEquals(FlareSizes.componentBubblePaddingX.value, (framed.left - bare.left).value, 0.5f)
    }

    /** A custom renderer in a list is told the message's core id (the server's before the client's) and the conversation. */
    @Test fun aCustomRendererKnowsItsMessageAndConversation() {
        val seen = mutableListOf<FlareContentContext>()
        val body: FlareContentBuilder = { _, ctx -> SideEffect { seen += ctx }; Text("Packet") }
        content {
            FlareContentScope(builders = mapOf("redpacket" to body)) {
                MessageList(
                    messages = listOf(
                        FlareMessageData(id = "client-1", serverId = "server-1", senderId = "u1", senderName = "Ann",
                            content = FlareGenericContent(contentType = "redpacket", label = "Packet")),
                        FlareMessageData(id = "client-2", senderId = "u1", senderName = "Ann",
                            content = FlareGenericContent(contentType = "redpacket", label = "Packet")),
                    ),
                    currentUserId = "me",
                    conversationId = "conv-1",
                )
            }
        }
        compose.waitForIdle()
        compose.runOnIdle {
            assertEquals(setOf("server-1", "client-2"), seen.map { it.messageId }.toSet())
            assertEquals(setOf("conv-1"), seen.map { it.conversationId }.toSet())
        }
    }

    // MARK: Open sheet

    @Test fun readySheetOpensAndClosesFromItsCloseControl() {
        val shown = mutableStateOf(true)
        var opens = 0
        content {
            if (shown.value) {
                RedPacketOpenSheet(senderName = "Ann", blessing = "Wish", kindLabel = "Lucky",
                    onClose = { shown.value = false }, onOpen = { opens++ }, onViewDetails = {})
            }
        }
        compose.onNodeWithText(zh.packetFromSender("Ann")).assertIsDisplayed()
        compose.onNodeWithText("Lucky").assertIsDisplayed()
        compose.onNodeWithText("Wish").assertIsDisplayed()
        compose.onNodeWithText(zh.packetViewDetails).assertDoesNotExist()
        compose.onNodeWithContentDescription(zh.packetOpenAction)
            .assertIsEnabled().assertWidthIsAtLeast(FlareSizes.touchTarget).performClick()
        assertEquals(1, opens)
        compose.onNodeWithContentDescription(zh.close)
            .assertWidthIsAtLeast(FlareSizes.touchTarget).assertHeightIsAtLeast(FlareSizes.touchTarget)
            .performClick()
        compose.waitUntil(5_000) { !shown.value }
        compose.onNodeWithText("Wish").assertDoesNotExist()
    }

    @Test fun aTapOnTheEnvelopeStaysAndATapOnTheScrimCloses() {
        val shown = mutableStateOf(true)
        content { if (shown.value) RedPacketOpenSheet(senderName = "Ann", blessing = "Wish", onClose = { shown.value = false }) }
        compose.onNodeWithText("Wish").performClick()
        compose.waitForIdle()
        assertTrue("a tap on the envelope must not reach the scrim", shown.value)
        compose.onAllNodes(isRoot()).onLast().performTouchInput { click(Offset(10f, 10f)) }
        compose.waitUntil(5_000) { !shown.value }
    }

    @Test fun unavailableSheetsExplainAndLeadToTheDetails() {
        val state = mutableStateOf(FlareRedPacketOpenState.Finished)
        var details = 0
        content {
            RedPacketOpenSheet(
                senderName = "Ann", blessing = "Wish", state = state.value,
                message = if (state.value == FlareRedPacketOpenState.NotEligible) "Only Bo" else null,
                onClose = {}, onOpen = {}, onViewDetails = { details++ },
            )
        }
        val cases = listOf(
            FlareRedPacketOpenState.Finished to zh.packetMissed,
            FlareRedPacketOpenState.Expired to zh.packetExpiredNotice,
            FlareRedPacketOpenState.NotEligible to "Only Bo",
        )
        for ((next, copy) in cases) {
            compose.runOnIdle { state.value = next }
            compose.onNodeWithText(copy).assertIsDisplayed()
            compose.onNodeWithText("Wish").assertDoesNotExist()
            compose.onNodeWithContentDescription(zh.packetOpenAction).assertDoesNotExist()
            compose.onNodeWithText(zh.packetViewDetails).assertHeightIsAtLeast(FlareSizes.touchTarget).performClick()
        }
        assertEquals(3, details)
    }

    @Test fun errorSheetKeepsTheButtonForAnotherTry() {
        var opens = 0
        content { RedPacketOpenSheet(senderName = "Ann", blessing = "Wish", state = FlareRedPacketOpenState.Error, onClose = {}, onOpen = { opens++ }) }
        compose.onNodeWithText(zh.packetOpenFailed).assertIsDisplayed()
        compose.onNodeWithContentDescription(zh.packetOpenAction).assertIsEnabled().performClick()
        assertEquals(1, opens)
    }

    /** The flip loops for as long as the claim runs, so the clock is driven by hand. */
    @Test fun openingTurnsTheButtonAndTakesNoSecondTap() {
        setAnimatorScale(1f)
        compose.mainClock.autoAdvance = false
        var opens = 0
        content { RedPacketOpenSheet(senderName = "Ann", blessing = "Wish", state = FlareRedPacketOpenState.Opening, onClose = {}, onOpen = { opens++ }) }
        compose.mainClock.advanceTimeBy(1_000)
        compose.onNodeWithContentDescription(zh.packetOpenAction)
            .assertIsNotEnabled()
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, zh.packetBusy))
        compose.onNodeWithText(zh.packetBusy, useUnmergedTree = true).assertDoesNotExist()
        assertEquals(0, opens)
    }

    @Test fun openingWithAnimationsRemovedSaysSoInstead() {
        setAnimatorScale(0f)
        content { RedPacketOpenSheet(senderName = "Ann", blessing = "Wish", state = FlareRedPacketOpenState.Opening, onClose = {}, onOpen = {}) }
        compose.onNodeWithText(zh.packetBusy, useUnmergedTree = true).assertIsDisplayed()
        compose.onNodeWithContentDescription(zh.packetOpenAction).assertIsNotEnabled()
    }

    // MARK: Details

    @Test fun detailsMarkTheBestClaimAndSayWhenNoOneClaimed() {
        val claims = mutableStateOf(listOf(
            FlareRedPacketClaim("u1", "Ann", "10:01", "0.88"),
            FlareRedPacketClaim("u2", "Bo", "10:02", "1.20", best = true),
        ))
        content {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                RedPacketDetail(senderName = "Cy", blessing = "Wish", summary = "2/2 opened", kindLabel = "Lucky",
                    amount = "0.88", amountNote = "In wallet", claims = claims.value, note = "Refunds after 24 hours")
            }
        }
        for (text in listOf(zh.packetFromSender("Cy"), "Lucky", "Wish", "In wallet", "2/2 opened", "Refunds after 24 hours")) {
            compose.onNodeWithText(text).assertExists()
        }
        compose.onNodeWithText("Bo").assert(hasText(zh.packetBestLuck)).assertHeightIsAtLeast(FlareSizes.touchTarget)
        compose.onAllNodesWithText(zh.packetBestLuck).assertCountEquals(1)
        compose.onNodeWithText(zh.packetNoClaims).assertDoesNotExist()
        compose.runOnIdle { claims.value = emptyList() }
        compose.onNodeWithText(zh.packetNoClaims).assertExists()
        compose.onNodeWithText(zh.packetBestLuck).assertDoesNotExist()
    }

    @Test fun detailsDrawTheirOwnRedTitleBarOnlyWithAWayBack() {
        val back = mutableStateOf<(() -> Unit)?>(null)
        var backs = 0
        content {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                RedPacketDetail(senderName = "Cy", blessing = "Wish", summary = "0/1 opened", onBack = back.value)
            }
        }
        compose.onNodeWithText(zh.packetDetailTitle).assertDoesNotExist()
        compose.runOnIdle { back.value = { backs++ } }
        compose.onNodeWithText(zh.packetDetailTitle).assertIsDisplayed()
        compose.onNodeWithContentDescription(zh.back).assertWidthIsAtLeast(FlareSizes.touchTarget).performClick()
        assertEquals(1, backs)
    }

    // MARK: Composer

    @Test fun groupComposerFormatsTheAmountAndSwitchesKinds() {
        val kind = mutableStateOf(FlareRedPacketKind.Lucky)
        val amount = mutableStateOf("")
        val count = mutableStateOf(0)
        var submits = 0
        content {
            RedPacketComposer(
                kinds = FlareRedPacketKind.entries, kind = kind.value, amount = amount.value, total = "¥" + amount.value,
                count = count.value, onKindChange = { kind.value = it }, onAmountChange = { amount.value = it },
                onCountChange = { count.value = it }, onSubmit = { submits++ }, recipient = { Text("Picker") },
            )
        }
        compose.onNodeWithContentDescription(zh.packetFieldTotal).performTextInput("12.345")
        compose.runOnIdle { assertEquals("12.34", amount.value) }
        compose.onNodeWithContentDescription(zh.packetFieldCount).performTextInput("3x")
        compose.runOnIdle { assertEquals(3, count.value) }
        compose.onNodeWithText("¥12.34").assertExists()
        compose.onNodeWithContentDescription(zh.packetKindPicker).assertExists()
        compose.onNodeWithText(zh.packetKindNormal).assertHeightIsAtLeast(FlareSizes.touchTarget).performClick()
        compose.runOnIdle { assertEquals(FlareRedPacketKind.Normal, kind.value) }
        compose.onNodeWithContentDescription(zh.packetFieldEach).assertExists()
        compose.onNodeWithText("Picker").assertDoesNotExist()
        compose.onNodeWithText(zh.packetKindExclusive).performClick()
        compose.onNodeWithText("Picker").assertExists()
        compose.onNodeWithContentDescription(zh.packetFieldCount).assertDoesNotExist()
        compose.onNodeWithText(zh.packetSubmit).assertHeightIsAtLeast(FlareSizes.touchTarget).performClick()
        assertEquals(1, submits)
    }

    @Test fun directChatComposerHasOnlyTheAmountAndLocksWhileBusy() {
        val busy = mutableStateOf(false)
        var submits = 0
        content {
            RedPacketComposer(kinds = listOf(FlareRedPacketKind.Normal), kind = FlareRedPacketKind.Normal, amount = "1",
                total = "¥1.00", error = "Too much", busy = busy.value, onAmountChange = {}, onCountChange = {},
                onSubmit = { submits++ })
        }
        compose.onNodeWithText(zh.packetKindNormal).assertDoesNotExist()
        compose.onNodeWithContentDescription(zh.packetKindPicker).assertDoesNotExist()
        compose.onNodeWithContentDescription(zh.packetFieldAmount).assertExists()
        compose.onNodeWithContentDescription(zh.packetFieldEach).assertDoesNotExist()
        compose.onNodeWithContentDescription(zh.packetFieldCount).assertDoesNotExist()
        compose.onNodeWithText("Too much").assertExists()
        compose.runOnIdle { busy.value = true }
        compose.onNodeWithText(zh.packetSubmit).assertIsNotEnabled().performClick()
        assertEquals(0, submits)
    }

    @Test fun aLockedComposerIsReadOnlyWithoutProgress() {
        var submits = 0
        var kinds = 0
        content {
            RedPacketComposer(
                kinds = FlareRedPacketKind.entries, kind = FlareRedPacketKind.Lucky, amount = "5", total = "¥5.00",
                count = 3, locked = true, onKindChange = { kinds++ }, onAmountChange = {}, onCountChange = {},
                onSubmit = { submits++ },
            )
        }
        compose.onNodeWithContentDescription(zh.packetFieldTotal).assertIsNotEnabled()
        compose.onNodeWithContentDescription(zh.packetFieldCount).assertIsNotEnabled()
        compose.onNodeWithContentDescription(zh.packetKindPicker).assertIsNotEnabled()
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, zh.packetKindLucky))
        compose.onNodeWithContentDescription(zh.packetKindPicker).performTouchInput { click(centerRight) }
        compose.onNodeWithText(zh.packetSubmit).assertIsNotEnabled().performClick()
        compose.onNode(SemanticsMatcher.keyIsDefined(SemanticsProperties.ProgressBarRangeInfo)).assertDoesNotExist()
        compose.runOnIdle {
            assertEquals(0, submits)
            assertEquals(0, kinds)
        }
    }

    /**
     * The red action keeps its red fill in both themes, inert and enabled, and while the amount field has focus and the
     * keyboard is up — a fill that vanished there left the label white on the page.
     */
    @Test fun theSubmitKeepsItsRedFillInLightMode() = submitKeepsItsRedFill(dark = false)

    @Test fun theSubmitKeepsItsRedFillInDarkMode() = submitKeepsItsRedFill(dark = true)

    private fun submitKeepsItsRedFill(dark: Boolean) {
        val amount = mutableStateOf("")
        compose.setContent {
            FlareThemeProvider(mode = if (dark) FlareThemeMode.Dark else FlareThemeMode.Light) {
                Column(Modifier.fillMaxSize().background(flareColors().bgSecondary)) {
                    RedPacketComposer(
                        kinds = listOf(FlareRedPacketKind.Normal), kind = FlareRedPacketKind.Normal, amount = amount.value,
                        total = "¥" + amount.value.ifEmpty { "0.00" }, onAmountChange = { amount.value = it },
                        onSubmit = if ((amount.value.toDoubleOrNull() ?: 0.0) > 0) ({}) else null,
                    )
                }
            }
        }
        val red = FlareColors.resolve(FlareBrandTheme.Violet, dark).redPacketEnd
        val mode = if (dark) "dark" else "light"
        assertFillIs(zh.packetSubmit, red, "$mode, inert")
        compose.onNodeWithContentDescription(zh.packetFieldAmount).performTextInput("1.88")
        compose.onNodeWithContentDescription(zh.packetFieldAmount).assertIsFocused()
        compose.onNodeWithText(zh.packetSubmit).assertIsEnabled()
        assertFillIs(zh.packetSubmit, red, "$mode, enabled with the field focused")
    }

    /** The pay sheet's confirm keeps its red fill when enough balance arrives and it becomes enabled. */
    @Test fun thePayConfirmKeepsItsRedFillWhenItBecomesEnabled() {
        val insufficient = mutableStateOf(true)
        content {
            RedPacketPayConfirm(amount = "¥1.88", methodLabel = "Wallet", insufficient = insufficient.value,
                onConfirm = {}, onCancel = {})
        }
        val red = FlareColors.resolve(FlareBrandTheme.Violet, isSystemDark()).redPacketEnd
        compose.onNodeWithText(zh.packetPayConfirm).assertIsNotEnabled()
        assertFillIs(zh.packetPayConfirm, red, "inert")
        compose.runOnIdle { insufficient.value = false }
        compose.onNodeWithText(zh.packetPayConfirm).assertIsEnabled()
        assertFillIs(zh.packetPayConfirm, red, "enabled")
    }

    /**
     * The kit button underneath: a fill drawn before the dimming layer survives the button turning enabled. A plain
     * `Modifier.alpha` drops its layer at 1, and dropping it left the fill undrawn.
     */
    @Test fun aKitButtonThatBecomesEnabledKeepsItsFill() {
        val enabled = mutableStateOf(false)
        content {
            Column(Modifier.width(300.dp)) {
                Button(label = "Go", size = FlareControlSize.Lg, block = true, onClick = if (enabled.value) ({}) else null)
            }
        }
        val primary = FlareColors.resolve(FlareBrandTheme.Violet, isSystemDark()).primary
        assertFillIs("Go", primary, "inert")
        compose.runOnIdle { enabled.value = true }
        assertFillIs("Go", primary, "enabled")
    }

    private fun isSystemDark(): Boolean =
        (instrumentation.targetContext.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
            android.content.res.Configuration.UI_MODE_NIGHT_YES

    /** The pixel just inside the button's leading edge, halfway down: the fill, away from the label. */
    private fun assertFillIs(label: String, expected: Color, where: String) {
        compose.waitForIdle()
        val bitmap = compose.onNodeWithText(label).captureToImage().asAndroidBitmap()
        val pixel = bitmap.getPixel((bitmap.width * 0.06f).toInt(), bitmap.height / 2)
        val got = Color(pixel)
        val close = abs(got.red - expected.red) < 0.04f && abs(got.green - expected.green) < 0.04f &&
            abs(got.blue - expected.blue) < 0.04f
        assertTrue("$where: the fill is $got, not the red packet's $expected", close)
    }

    // MARK: Pay confirm

    @Test fun payConfirmNeedsEnoughBalance() {
        val shown = mutableStateOf(true)
        val events = mutableListOf<String>()
        content {
            if (shown.value) {
                RedPacketPayConfirm(amount = "¥5.00", methodLabel = "Wallet (¥3.00)", insufficient = true,
                    onConfirm = { events += "confirm" }, onCancel = { events += "cancel"; shown.value = false })
            }
        }
        compose.onNodeWithText("¥5.00").assertIsDisplayed()
        compose.onNodeWithText(zh.packetInsufficient).assertIsDisplayed()
        compose.onNodeWithText(zh.packetPayConfirm).assertIsNotEnabled()
        compose.onNodeWithText(zh.cancel).assertIsEnabled().assertHeightIsAtLeast(FlareSizes.touchTarget).performClick()
        compose.runOnIdle { assertEquals(listOf("cancel"), events) }
        compose.onNodeWithText("¥5.00").assertDoesNotExist()
    }

    @Test fun payConfirmConfirmsAndLocksWhileBusy() {
        val busy = mutableStateOf(false)
        val events = mutableListOf<String>()
        content {
            RedPacketPayConfirm(amount = "¥5.00", methodLabel = "Wallet (¥30.00)", busy = busy.value,
                onConfirm = { events += "confirm"; busy.value = true }, onCancel = { events += "cancel" })
        }
        compose.onNodeWithText(zh.packetInsufficient).assertDoesNotExist()
        compose.onNodeWithText(zh.packetPayConfirm).assertIsEnabled().performClick()
        compose.onNodeWithText(zh.packetPayConfirm).assertIsNotEnabled()
        compose.onNodeWithText(zh.cancel).assertIsNotEnabled().performClick()
        compose.runOnIdle { assertEquals(listOf("confirm"), events) }
    }
}
