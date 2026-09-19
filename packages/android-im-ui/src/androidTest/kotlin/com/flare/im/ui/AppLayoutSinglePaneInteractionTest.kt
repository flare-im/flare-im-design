package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * FR-083 on the device: a workspace narrower than navigation + list + a usable chat (752 dp) shows one pane
 * and keeps the rail; above it the two panes come back. The host is told which presentation is in use, and a
 * detail in one-pane mode is a page the host routes to, not an overlay.
 */
class AppLayoutSinglePaneInteractionTest {
    @get:Rule val compose = createComposeRule()

    private fun layout(
        width: Dp,
        hasDetail: Boolean = false,
        activePane: FlareApplicationWorkspacePane = FlareApplicationWorkspacePane.Content,
        onLayoutChange: ((FlareWorkspacePresentation) -> Unit)? = null,
    ) {
        compose.setContent {
            MaterialTheme {
                // A box of exactly this width: the layout must measure *itself*, not the window. `requiredWidth`,
                // not `width`: a phone screen narrower than the box would otherwise clamp it to the screen.
                Box(Modifier.requiredWidth(width).fillMaxHeight()) {
                    // No shell: the layout resolves the mode from its own box too.
                    AppLayout(
                        navigation = { Text("导航") },
                        primary = { Text("会话列表") },
                        content = { Text("聊天") },
                        detail = if (hasDetail) ({ Text("群详情") }) else null,
                        activePane = activePane,
                        onLayoutChange = onLayoutChange,
                    )
                }
            }
        }
    }

    @Test fun aTabletTooNarrowForAUsableChatShowsOnePaneAndKeepsTheRail() {
        layout(700.dp)
        compose.onNodeWithText("导航").assertExists()
        compose.onNodeWithText("聊天").assertExists()
        // The list is not beside it: it is the pane the host is not showing.
        compose.onNodeWithText("会话列表").assertDoesNotExist()
    }

    @Test fun theSamePanesFitSideBySideAboveTheWidth() {
        layout(800.dp)
        compose.onNodeWithText("导航").assertExists()
        compose.onNodeWithText("会话列表").assertExists()
        compose.onNodeWithText("聊天").assertExists()
    }

    @Test fun onePaneShowsTheHostsActivePane() {
        layout(700.dp, activePane = FlareApplicationWorkspacePane.Primary)
        compose.onNodeWithText("会话列表").assertExists()
        compose.onNodeWithText("聊天").assertDoesNotExist()
    }

    @Test fun theHostIsToldWhichPresentationIsInUse() {
        val reported = mutableListOf<FlareWorkspacePresentation>()
        layout(700.dp, hasDetail = true, onLayoutChange = { reported += it })
        compose.waitForIdle()
        // Reported on the first resolution, without the host measuring anything.
        assertEquals(1, reported.size)
        assertEquals(FlareWorkspacePaneMode.SinglePane, reported.single().paneMode)
        // A detail is a page here, never an overlay over a full-width pane.
        assertEquals(FlareWorkspaceDetailPresentation.Route, reported.single().detail)
        compose.onNodeWithText("群详情").assertDoesNotExist()
    }

    @Test fun aDetailStillOverlaysWhereTwoPanesFit() {
        val reported = mutableListOf<FlareWorkspacePresentation>()
        layout(800.dp, hasDetail = true, activePane = FlareApplicationWorkspacePane.Detail, onLayoutChange = { reported += it })
        compose.waitForIdle()
        assertEquals(FlareWorkspacePaneMode.DualPane, reported.single().paneMode)
        assertEquals(FlareWorkspaceDetailPresentation.Overlay, reported.single().detail)
        compose.onNodeWithText("群详情").assertExists()
    }
}
