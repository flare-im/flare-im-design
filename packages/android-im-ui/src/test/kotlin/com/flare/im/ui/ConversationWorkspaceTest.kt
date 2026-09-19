package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class ConversationWorkspaceTest {
    @Test fun paneRenderMapsEveryStatus() {
        assertEquals(
            listOf(
                FlareWorkspacePaneRender.Content,
                FlareWorkspacePaneRender.Skeleton,
                FlareWorkspacePaneRender.Empty,
                FlareWorkspacePaneRender.Failure,
            ),
            FlareWorkspacePaneStatus.entries.map { paneRender(FlareWorkspacePaneState(status = it)) },
        )
    }

    @Test fun paneRenderDegradesMissingStateToContent() {
        assertEquals(FlareWorkspacePaneRender.Content, paneRender(null))
        assertEquals(FlareWorkspacePaneRender.Content, paneRender(FlareWorkspacePaneState()))
        assertEquals(FlareWorkspacePaneRender.Content, paneRender(FlareWorkspacePaneState(message = "只有文案")))
    }

    @Test fun loadingNeverResolvesToEmpty() {
        val loading = FlareWorkspacePaneState(status = FlareWorkspacePaneStatus.Loading)
        assertNotEquals(FlareWorkspacePaneRender.Empty, paneRender(loading))
        assertEquals(FlareWorkspacePaneRender.Skeleton, paneRender(loading))
    }

    @Test fun paneRetryVisibleNeedsFailureLabelAndHandler() {
        for (status in FlareWorkspacePaneStatus.entries) {
            for (label in listOf(null, "", "   ", "重试")) {
                for (hasRetry in listOf(false, true)) {
                    val expected = status == FlareWorkspacePaneStatus.Failure && label == "重试" && hasRetry
                    assertEquals(
                        expected,
                        paneRetryVisible(FlareWorkspacePaneState(status = status, actionLabel = label), hasRetry),
                        "status=$status label=$label hasRetry=$hasRetry",
                    )
                }
            }
        }
    }

    @Test fun failureWithoutHandlerOrLabelShowsReasonOnly() {
        val failed = FlareWorkspacePaneState(
            status = FlareWorkspacePaneStatus.Failure, message = "网络中断", actionLabel = "重试",
        )
        assertEquals(FlareWorkspacePaneRender.Failure, paneRender(failed))
        assertFalse(paneRetryVisible(failed, hasRetry = false))
        assertFalse(
            paneRetryVisible(
                FlareWorkspacePaneState(status = FlareWorkspacePaneStatus.Failure, message = "网络中断"),
                hasRetry = true,
            ),
        )
        assertFalse(paneRetryVisible(null, hasRetry = true))
    }

    @Test fun panesAreIndependent() {
        val list = FlareWorkspacePaneState()
        val chat = FlareWorkspacePaneState(
            status = FlareWorkspacePaneStatus.Failure, message = "消息加载失败", actionLabel = "重试",
        )
        val detail = FlareWorkspacePaneState(status = FlareWorkspacePaneStatus.Loading)
        assertEquals(FlareWorkspacePaneRender.Content, paneRender(list))
        assertEquals(FlareWorkspacePaneRender.Failure, paneRender(chat))
        assertEquals(FlareWorkspacePaneRender.Skeleton, paneRender(detail))
        assertFalse(paneRetryVisible(list, hasRetry = true))
        assertTrue(paneRetryVisible(chat, hasRetry = true))
        assertFalse(paneRetryVisible(detail, hasRetry = true))
    }

    @Test fun bannerVisibilityIgnoresBlankMessages() {
        assertFalse(workspaceBannerVisible(null))
        assertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message = "")))
        assertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message = "   ")))
        assertFalse(workspaceBannerVisible(FlareWorkspaceBanner(message = "\n\t ")))
        assertTrue(workspaceBannerVisible(FlareWorkspaceBanner(message = "网络已断开")))
    }

    @Test fun bannerCoexistsWithReadablePane() {
        val banner = FlareWorkspaceBanner(message = "离线，显示的是缓存内容", tone = FlareWorkspaceBannerTone.Warning)
        assertTrue(workspaceBannerVisible(banner))
        assertEquals(FlareWorkspacePaneRender.Content, paneRender(FlareWorkspacePaneState()))
    }

    @Test fun bannerActionNeedsLabelAndHandler() {
        val withLabel = FlareWorkspaceBanner(message = "离线", actionLabel = "重连")
        assertTrue(workspaceBannerActionVisible(withLabel, hasAction = true))
        assertFalse(workspaceBannerActionVisible(withLabel, hasAction = false))
        assertFalse(workspaceBannerActionVisible(FlareWorkspaceBanner("离线", actionLabel = "  "), hasAction = true))
        assertFalse(workspaceBannerActionVisible(FlareWorkspaceBanner("离线"), hasAction = true))
        assertFalse(workspaceBannerActionVisible(FlareWorkspaceBanner("  ", actionLabel = "重连"), hasAction = true))
        assertFalse(workspaceBannerActionVisible(null, hasAction = true))
    }

    @Test fun bannerToneMapsErrorToDanger() {
        assertEquals(
            listOf(FlareStatusTone.Info, FlareStatusTone.Warning, FlareStatusTone.Danger, FlareStatusTone.Success),
            FlareWorkspaceBannerTone.entries.map { workspaceBannerTone(it) },
        )
        assertEquals(FlareStatusTone.Info, workspaceBannerTone(null))
    }

    @Test fun skeletonVariantPerPane() {
        assertEquals(
            listOf(SkeletonVariant.Conversation, SkeletonVariant.Message, SkeletonVariant.Profile),
            FlareWorkspacePaneKey.entries.map { paneSkeletonVariant(it) },
        )
    }
}
