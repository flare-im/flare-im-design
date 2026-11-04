package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class MyInvitePanelInteractionTest {
    @get:Rule val compose = createComposeRule()

    private val code = "ABCDEFGHJKMN"
    private val link = "https://flare.example/r/123/$code"

    @Test fun narrowInviteShowsRealQrAndCopiesOnlyTheCode() {
        val copied = mutableListOf<String>()
        compose.setContent {
            FlareThemeProvider(mode = FlareThemeMode.Dark) {
                Box(Modifier.width(320.dp).verticalScroll(rememberScrollState())) {
                    MyInvitePanel(
                        code = code,
                        shareUrl = link,
                        onCopy = { copied += it },
                    )
                }
            }
        }
        compose.onNodeWithContentDescription("扫码注册").assertIsDisplayed()
        compose.onNodeWithText(code).assertIsDisplayed()
        compose.onNodeWithText("复制").performScrollTo().performClick()
        for (label in listOf(link, "邀请链接", "复制链接", "分享", "重新生成")) {
            compose.onNodeWithText(label).assertDoesNotExist()
        }
        compose.runOnIdle { assertEquals(listOf(code), copied) }
    }

    @Test fun inviteesExpandLazilyAndRetryTheSameBranch() {
        val requests = mutableListOf<Pair<String, String?>>()
        compose.setContent {
            FlareThemeProvider {
                Box(Modifier.width(320.dp).verticalScroll(rememberScrollState())) {
                    MyInvitePanel(
                        code = code,
                        maxDepthShown = 3,
                        invitees = listOf(FlareInvitee("first", "Ann", joinedAt = 0, hasChildren = true)),
                        onLoadChildren = { parent, cursor ->
                            requests += parent to cursor
                            when {
                                parent == "first" && requests.size == 1 -> error("fixture failure")
                                parent == "first" && cursor == null -> FlareInviteeBranchPage(
                                    listOf(FlareInvitee("second", "Bob", joinedAt = 0, hasChildren = true)),
                                    nextCursor = "page-2",
                                )
                                parent == "first" -> FlareInviteeBranchPage(
                                    listOf(FlareInvitee("second-other", "Bea", joinedAt = 0)),
                                )
                                else -> FlareInviteeBranchPage(
                                    listOf(FlareInvitee("third", "Chao", joinedAt = 0, hasChildren = true)),
                                )
                            }
                        },
                    )
                }
            }
        }
        for (label in listOf("邀请人", "暂无邀请人", "当前用户", "直接邀请的人", "Bob")) {
            compose.onNodeWithText(label).assertDoesNotExist()
        }
        compose.runOnIdle { assertEquals(emptyList<Pair<String, String?>>(), requests) }
        compose.onNodeWithContentDescription("展开 Ann").performClick()
        compose.onNodeWithText("重试").performScrollTo().performClick()
        compose.onNodeWithContentDescription("展开 Bob").performScrollTo().performClick()
        compose.onNodeWithText("Chao").performScrollTo().assertIsDisplayed()
        compose.onNodeWithContentDescription("展开 Chao").assertDoesNotExist()
        compose.onNodeWithText("加载更多").performScrollTo().performClick()
        compose.onNodeWithText("Bea").performScrollTo().assertIsDisplayed()
        compose.onNodeWithContentDescription("收起 Ann").performScrollTo().performClick()
        compose.onNodeWithText("Bob").assertDoesNotExist()
        compose.runOnIdle {
            assertEquals(listOf("first" to null, "first" to null, "second" to null, "first" to "page-2"), requests)
        }
    }

    @Test fun unavailableCodeKeepsOnlyAllowedTeamInformation() {
        compose.setContent {
            FlareThemeProvider {
                MyInvitePanel(
                    code = "",
                    shareUrl = link,
                    stats = FlareReferralStats(direct = 5, l2 = 0, l3 = 0, total = 5),
                    showProfiles = false,
                    onCopy = {},
                )
            }
        }
        compose.onNodeWithText("邀请码暂不可用").assertIsDisplayed()
        compose.onNodeWithText("我的团队").assertIsDisplayed()
        compose.onNodeWithContentDescription("扫码注册").assertDoesNotExist()
        for (label in listOf("复制", "分享", "重新生成", "邀请关系")) {
            compose.onNodeWithText(label).assertDoesNotExist()
        }
    }
}
