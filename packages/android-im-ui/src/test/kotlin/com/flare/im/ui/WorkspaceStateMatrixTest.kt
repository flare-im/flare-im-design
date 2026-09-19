package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * DoD 18 — the state matrix WorkspaceFrame and ConversationWorkspace now share.
 * The Compose unit-test path cannot mount a composable offline, so this pins the
 * resolution both surfaces feed into `WorkspacePane`.
 */
class WorkspaceStateMatrixTest {
    private val statuses = listOf(
        FlareWorkspacePaneStatus.Ready,
        FlareWorkspacePaneStatus.Loading,
        FlareWorkspacePaneStatus.Empty,
        FlareWorkspacePaneStatus.Failure,
    )

    @Test fun everyStatusResolvesToOneRender() {
        assertEquals(
            listOf(
                FlareWorkspacePaneRender.Content,
                FlareWorkspacePaneRender.Skeleton,
                FlareWorkspacePaneRender.Empty,
                FlareWorkspacePaneRender.Failure,
            ),
            statuses.map { paneRender(FlareWorkspacePaneState(status = it)) },
        )
        // A pane with no state at all is the host's content, never a blank.
        assertEquals(FlareWorkspacePaneRender.Content, paneRender(null))
    }

    @Test fun onlyAFailureOffersRetryAndOnlyAnEmptyOffersTheNextStep() {
        for (status in statuses) {
            val state = FlareWorkspacePaneState(status = status, actionLabel = "Do it")
            assertEquals(
                status == FlareWorkspacePaneStatus.Failure,
                paneRetryVisible(state, hasRetry = true),
                "retry for $status",
            )
            assertEquals(
                status == FlareWorkspacePaneStatus.Empty,
                paneEmptyActionVisible(state, hasAction = true),
                "empty action for $status",
            )
        }
    }

    @Test fun anActionNeedsBothALabelAndAHandler() {
        val failure = FlareWorkspacePaneState(status = FlareWorkspacePaneStatus.Failure, actionLabel = "Retry")
        assertFalse(paneRetryVisible(failure, hasRetry = false), "no handler, no button")
        assertFalse(
            paneRetryVisible(FlareWorkspacePaneState(status = FlareWorkspacePaneStatus.Failure, actionLabel = "  "), hasRetry = true),
            "blank label, no button",
        )
        assertTrue(paneRetryVisible(failure, hasRetry = true))

        val empty = FlareWorkspacePaneState(status = FlareWorkspacePaneStatus.Empty, actionLabel = "Add a device")
        assertFalse(paneEmptyActionVisible(empty, hasAction = false))
        assertTrue(paneEmptyActionVisible(empty, hasAction = true))
    }

    @Test fun theBannerIsIndependentOfEveryPane() {
        assertFalse(workspaceBannerVisible(null))
        assertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message = "   ")))
        assertTrue(workspaceBannerVisible(FlareWorkspaceBanner(message = "Offline")))
        assertEquals(FlareStatusTone.Warning, workspaceBannerTone(FlareWorkspaceBannerTone.Warning))
        assertEquals(FlareStatusTone.Danger, workspaceBannerTone(FlareWorkspaceBannerTone.Error))
    }

    @Test fun theFrameCarriesGenericCopy() {
        // A frame that also hosts contacts and settings must not say "conversation".
        val strings = FlareStrings()
        for (text in listOf(strings.workspaceFrameLoading, strings.workspaceFrameEmpty, strings.workspaceFrameFailure)) {
            assertTrue(text.isNotBlank(), "frame copy is set")
            assertFalse(text.contains("会话"), "frame copy stays generic: $text")
        }
    }
}
