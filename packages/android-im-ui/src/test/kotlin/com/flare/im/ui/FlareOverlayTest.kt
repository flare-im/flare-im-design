package com.flare.im.ui

import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The overlay family's decisions as pure tables — which form a sheet takes, how wide a drawer or modal may be,
 * how tall an overlay may grow, which side a drawer slides from, what back does, and which overlay draws the
 * toasts — so they are pinned without an emulator.
 */
class FlareOverlayTest {
    private val mobile = FlareApplicationResponsiveMode.Mobile
    private val tablet = FlareApplicationResponsiveMode.Tablet

    @Test fun anInstalledAdapterDecidesTheFormFactorOnItsOwn() {
        // The host declared its capabilities: they win over the shell and the window.
        assertTrue(resolveCompactOverlays(installed = true, capabilityBottomSheet = true, shellMode = tablet, screenWidthDp = 1200))
        assertFalse(resolveCompactOverlays(installed = true, capabilityBottomSheet = false, shellMode = mobile, screenWidthDp = 360))
    }

    @Test fun withoutAnAdapterTheShellModeThenTheWindowWidthDecides() {
        assertTrue(resolveCompactOverlays(installed = false, capabilityBottomSheet = false, shellMode = mobile, screenWidthDp = 700))
        assertFalse(resolveCompactOverlays(installed = false, capabilityBottomSheet = true, shellMode = tablet, screenWidthDp = 390))
        // No shell either: the navigation-rail breakpoint (600) on the window width.
        assertTrue(resolveCompactOverlays(installed = false, capabilityBottomSheet = false, shellMode = null, screenWidthDp = 599))
        assertFalse(resolveCompactOverlays(installed = false, capabilityBottomSheet = true, shellMode = null, screenWidthDp = 600))
    }

    @Test fun autoIsASheetOnPhonesAndAModalElsewhereWhileSheetIsAlwaysASheet() {
        assertEquals(FlareResolvedOverlay.Sheet, resolveOverlayPresentation(FlareSheetPresentation.Auto, compact = true))
        assertEquals(FlareResolvedOverlay.Modal, resolveOverlayPresentation(FlareSheetPresentation.Auto, compact = false))
        assertEquals(FlareResolvedOverlay.Sheet, resolveOverlayPresentation(FlareSheetPresentation.Sheet, compact = true))
        assertEquals(FlareResolvedOverlay.Sheet, resolveOverlayPresentation(FlareSheetPresentation.Sheet, compact = false))
    }

    @Test fun aDrawerAlwaysLeavesATouchTargetOfScrim() {
        assertEquals(FlareSizes.componentSheetWidth, flareDrawerWidth(FlareSizes.componentSheetWidth, 1024.dp))
        // A 390 dp phone window: 390 − 48.
        assertEquals(342.dp, flareDrawerWidth(FlareSizes.componentSheetWidth, 390.dp))
        assertEquals(0.dp, flareDrawerWidth(FlareSizes.componentSheetWidth, 20.dp))
    }

    @Test fun aModalKeepsSpacingXlOnBothSides() {
        assertEquals(FlareSizes.componentSheetDialogWidth, flareModalWidth(FlareSizes.componentSheetDialogWidth, 1024.dp))
        assertEquals(360.dp - FlareSizes.spacingXl * 2, flareModalWidth(FlareSizes.componentSheetDialogWidth, 360.dp))
        assertEquals(720.dp, flareModalWidth(720.dp, 1280.dp))
    }

    @Test fun theHeightCapDefaultsTo72PercentAndNeverPassesTheCeiling() {
        assertEquals(720.dp, flareOverlayMaxHeight(null, available = 1000.dp))
        assertEquals(400.dp, flareOverlayMaxHeight(400.dp, available = 1000.dp))
        assertEquals(940.dp, flareOverlayMaxHeight(2000.dp, available = 1000.dp, ceiling = 940.dp))
        assertEquals(300.dp, flareOverlayMaxHeight(null, available = 1000.dp, ceiling = 300.dp))
        assertEquals(0.dp, flareOverlayMaxHeight(null, available = 100.dp, ceiling = (-20).dp))
    }

    @Test fun aDrawerSlidesFromItsOwnEdgeInBothLayoutDirections() {
        assertEquals(1, flareDrawerSlideSign(FlareDrawerPlacement.End, LayoutDirection.Ltr))
        assertEquals(-1, flareDrawerSlideSign(FlareDrawerPlacement.Start, LayoutDirection.Ltr))
        // Under RTL the end edge is the left one: slide offsets are physical, so the sign flips.
        assertEquals(-1, flareDrawerSlideSign(FlareDrawerPlacement.End, LayoutDirection.Rtl))
        assertEquals(1, flareDrawerSlideSign(FlareDrawerPlacement.Start, LayoutDirection.Rtl))
    }

    @Test fun backIsSwallowedWhileLockedStepsBackWithABackControlAndOtherwiseCloses() {
        assertEquals(FlareOverlayBackAction.Ignore, resolveOverlayBack(dismissible = false, showBack = true))
        assertEquals(FlareOverlayBackAction.Ignore, resolveOverlayBack(dismissible = false, showBack = false))
        assertEquals(FlareOverlayBackAction.Back, resolveOverlayBack(dismissible = true, showBack = true))
        assertEquals(FlareOverlayBackAction.Close, resolveOverlayBack(dismissible = true, showBack = false))
    }

    @Test fun theScrimIsAnnouncedOnlyWhenItIsTheOneCloseControl() {
        assertTrue(flareScrimAnnounced(dismissible = true, showClose = false))
        assertFalse(flareScrimAnnounced(dismissible = true, showClose = true))
        assertFalse(flareScrimAnnounced(dismissible = false, showClose = false))
    }

    @Test fun theHeaderRowExistsOnlyWithSomethingToShow() {
        assertFalse(flareOverlayHeaderVisible(null, titleHidden = false, hasActions = false, showClose = false, showBack = false))
        assertFalse(flareOverlayHeaderVisible("详情", titleHidden = true, hasActions = false, showClose = false, showBack = false))
        assertTrue(flareOverlayHeaderVisible("详情", titleHidden = false, hasActions = false, showClose = false, showBack = false))
        assertTrue(flareOverlayHeaderVisible(null, titleHidden = false, hasActions = true, showClose = false, showBack = false))
        assertTrue(flareOverlayHeaderVisible(null, titleHidden = false, hasActions = false, showClose = true, showBack = false))
        assertTrue(flareOverlayHeaderVisible(null, titleHidden = false, hasActions = false, showClose = false, showBack = true))
    }

    @Test fun everyOverlayHasAName() {
        assertEquals("群详情", flareOverlayPaneTitle("群详情", "页面", "侧边面板"))
        assertEquals("页面", flareOverlayPaneTitle(null, "页面", "侧边面板"))
        assertEquals("页面", flareOverlayPaneTitle(" ", "页面", "侧边面板"))
        assertEquals("侧边面板", flareOverlayPaneTitle(null, "", "侧边面板"))
    }

    @Test fun theLastOpenedOverlayDrawsTheToasts() {
        val stack = FlareOverlayStack(FlareToastState())
        val drawer = Any()
        val sheet = Any()
        assertTrue(stack.isEmpty)
        stack.push(drawer)
        assertTrue(stack.isTop(drawer))
        stack.push(sheet)
        stack.push(sheet)
        assertTrue(stack.isTop(sheet))
        assertFalse(stack.isTop(drawer))
        stack.remove(sheet)
        assertTrue(stack.isTop(drawer))
        stack.remove(drawer)
        assertTrue(stack.isEmpty)
    }
}
