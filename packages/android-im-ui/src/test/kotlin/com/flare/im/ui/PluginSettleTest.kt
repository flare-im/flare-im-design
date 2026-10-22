package com.flare.im.ui

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The host's settle signal (`settleToken`), the embedded view's sheet insets and what the detail sheet hands its embedded
 * view for the actions run from it (`spec/plugin-view-vectors.json` rules: settle, inset, detail).
 */
class PluginSettleTest {
    private val poll = PluginChoicesBlock(
        options = listOf(PluginChoice(0, "A"), PluginChoice(1, "B")),
        action = PluginViewAction("vote", "Vote"),
    )

    /** A choice submitted and waiting for the host. */
    private fun submitted() = PluginChoicesInteraction().submitted(0, "vote", listOf(1))

    // ── choices ──

    @Test fun aCleanSettleKeepsTheMarkAndThePauseUntilTheNewView() {
        val state = submitted().hostChanged(PluginHostSignal(), PluginHostSignal(settleToken = 1))
        assertEquals(listOf(1), state.shown(poll, 0), "the mark stays")
        assertFalse(state.isInteractive(poll, 0, locked = false), "the options wait for the new view")
        assertTrue(state.viewChanged().isInteractive(poll, 0, locked = false))
    }

    @Test fun aSettleWithAnErrorRevertsEvenWhenTheTextDidNotChange() {
        val state = submitted().hostChanged(PluginHostSignal(error = "网络异常"), PluginHostSignal(error = "网络异常", settleToken = 1))
        assertEquals(emptyList(), state.shown(poll, 0), "read at the change, the same text reverts")
        assertTrue(state.isInteractive(poll, 0, locked = false))
    }

    @Test fun aSettleWithFormErrorsRevertsTheChoiceTheFormCarried() {
        val invalid = PluginHostSignal(formErrors = listOf(PluginFormError("note", PluginFormIssue.Required)), settleToken = 1)
        assertEquals(emptyList(), submitted().hostChanged(PluginHostSignal(), invalid).shown(poll, 0))
    }

    @Test fun busyActionIdLeavingTheActionStillSettlesAndTogetherTheySettleOnce() {
        val fallback = submitted().hostChanged(
            PluginHostSignal(busyActionId = "vote"),
            PluginHostSignal(formErrors = listOf(PluginFormError("x", PluginFormIssue.TooLong))),
        )
        assertEquals(emptyList(), fallback.shown(poll, 0), "the fallback reads form errors too")
        val both = submitted().hostChanged(PluginHostSignal(busyActionId = "vote"), PluginHostSignal(settleToken = 1))
        assertEquals(listOf(1), both.shown(poll, 0), "a clean result, however many signals")
        // Set and cleared within one frame: busyActionId never changes, the token alone settles.
        val sameFrame = submitted().hostChanged(PluginHostSignal(), PluginHostSignal(error = "失败", settleToken = 1))
        assertEquals(emptyList(), sameFrame.shown(poll, 0))
        assertEquals(listOf(1), submitted().hostChanged(PluginHostSignal(), PluginHostSignal()).shown(poll, 0), "no signal, no settle")
    }

    // ── forms ──

    @Test fun theSubmittedFormClosesOnACleanSettleAndStaysWithErrors() {
        val idle = PluginHostSignal()
        assertEquals(PluginFormSettle.Close, pluginFormSettle(idle, PluginHostSignal(settleToken = 1), "create"))
        assertEquals(PluginFormSettle.Keep, pluginFormSettle(idle, PluginHostSignal(error = "保存失败", settleToken = 1), "create"))
        assertEquals(
            PluginFormSettle.Keep,
            pluginFormSettle(idle, PluginHostSignal(formErrors = listOf(PluginFormError("title", PluginFormIssue.Required)), settleToken = 1), "create"),
        )
        assertEquals(PluginFormSettle.Wait, pluginFormSettle(idle, PluginHostSignal(error = "x"), "create"), "an error alone does not settle the form")
        // The fallback: the form's action (or the whole card) stops being busy.
        assertEquals(PluginFormSettle.Close, pluginFormSettle(PluginHostSignal(busyActionId = "create"), idle, "create"))
        assertEquals(PluginFormSettle.Keep, pluginFormSettle(PluginHostSignal(busy = true), PluginHostSignal(error = "x"), "create"))
        assertEquals(PluginFormSettle.Wait, pluginFormSettle(PluginHostSignal(busyActionId = "other"), idle, "create"),
            "another action finishing leaves this form alone")
        assertEquals(PluginFormSettle.Close, pluginFormSettle(PluginHostSignal(busyActionId = "create"), PluginHostSignal(settleToken = 1), "create"),
            "both signals at once settle once")
    }

    // ── inset ──

    @Test fun anEmbeddedViewTakesTheSheetInsetsOnlyWhenAsked() {
        assertEquals(
            PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl),
            pluginViewInsetPadding(PluginViewInset.Sheet),
        )
        assertEquals(PaddingValues(0.dp), pluginViewInsetPadding(PluginViewInset.None))
        assertEquals(
            PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = 0.dp),
            pluginViewInsetPadding(PluginViewInset.SheetTop),
            "a preface leaves the gap to the form under it",
        )
        assertEquals(listOf("None", "Sheet", "SheetTop"), PluginViewInset.entries.map { it.name })
    }

    @Test fun anUnavailableEmbeddedViewSaysWhatItWas() {
        val gone = PluginViewModel(available = false, title = "投票（已失效）", actions = listOf(PluginViewAction("vote", "投票")))
        assertEquals("投票（已失效）", PluginViewFormat.unavailableLine(gone, embedded = true))
        assertEquals(null, PluginViewFormat.unavailableLine(gone, embedded = false), "the card's title row says it")
        assertEquals(null, PluginViewFormat.unavailableLine(PluginViewModel(available = true, title = "Card"), embedded = true))
        assertEquals(null, PluginViewFormat.unavailableLine(PluginViewModel(available = false, title = ""), embedded = true))
    }

    // ── detail sheet ──

    @Test fun theDetailSheetHandsItsActionStateToTheEmbeddedView() {
        val members = listOf(PluginMember("u1", "Ann"))
        val errors = listOf(PluginFormError("text", PluginFormIssue.Required))
        val state = pluginDetailActionState("join", "提交失败", errors, members, 4)
        assertEquals("提交失败", state.error, "actionError is the embedded view's error")
        assertEquals(errors, state.formErrors)
        assertEquals(members, state.members)
        assertEquals(4, state.settleToken)
        assertEquals("join", state.busyActionId)
        // The loading failure stays `error`, with retry, and never reaches the embedded view.
        assertEquals(PluginDetailPhase.Error, pluginDetailPhase(false, "加载失败", null))
    }

    // ── detail pages ──

    @Test fun theDetailViewReadsItsNextCursor() {
        assertEquals("c2", PluginViewModel.fromJson("""{"available":true,"title":"接龙","nextCursor":"c2"}""").nextCursor)
        assertEquals(null, PluginViewModel.fromJson("""{"available":true,"title":"接龙","nextCursor":""}""").nextCursor, "empty: the last page")
        assertEquals(null, PluginViewModel.fromJson("""{"available":true,"title":"接龙","nextCursor":"  "}""").nextCursor, "blank: the last page")
        assertEquals(null, PluginViewModel.fromJson("""{"available":true,"title":"接龙"}""").nextCursor)
        assertEquals(null, PluginViewModel.fromJson("""{"available":true,"title":"接龙","nextCursor":7}""").nextCursor, "lenient")
    }

    @Test fun loadMoreShowsWithACursorAndSpinsUntilThePageMovesItOn() {
        assertEquals(PluginDetailLoadMore.Hidden, pluginDetailLoadMore(null, null, loadingMore = false))
        assertEquals(PluginDetailLoadMore.Hidden, pluginDetailLoadMore("", null, loadingMore = false))
        assertEquals(PluginDetailLoadMore.Hidden, pluginDetailLoadMore(" \n", null, loadingMore = false))
        assertEquals(PluginDetailLoadMore.Ready("c2"), pluginDetailLoadMore("c2", null, loadingMore = false))
        assertEquals(PluginDetailLoadMore.Loading, pluginDetailLoadMore("c2", null, loadingMore = true), "the host is loading")
        assertEquals(PluginDetailLoadMore.Loading, pluginDetailLoadMore("c2", "c2", loadingMore = false),
            "asked for and not answered: the same page is never asked for twice")
        assertEquals(PluginDetailLoadMore.Ready("c3"), pluginDetailLoadMore("c3", "c2", loadingMore = false), "the merged page moved the cursor on")
        assertEquals(PluginDetailLoadMore.Hidden, pluginDetailLoadMore(null, "c2", loadingMore = false), "the last page")
    }
}
