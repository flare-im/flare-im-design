package com.flare.im.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The ActionMenu rules that need no UI: order, grouping, visibility, selection, checkable items, sizes, placement and icons. */
class ActionMenuTest {
    /** Drawn ids in order, with "|" where a separator opens a group. */
    private fun drawn(items: List<FlareActionItem>): List<String> = actionMenuRows(items).flatMap { row ->
        if (row.separatorBefore) listOf("|", row.item.id) else listOf(row.item.id)
    }

    @Test fun keepsHostOrderAndSeparatesWhereTheGroupChanges() {
        assertEquals(
            listOf("reply", "recall", "copy", "|", "delete", "report"),
            drawn(listOf(
                FlareActionItem("reply", "Reply"),
                FlareActionItem("recall", "Recall", danger = true),
                FlareActionItem("copy", "Copy"),
                FlareActionItem("delete", "Delete", danger = true, group = "danger"),
                FlareActionItem("report", "Report", danger = true),
            )),
        )
    }

    @Test fun drawsNoLeadingSeparatorAndNoneInsideAGroup() {
        assertEquals(
            listOf("search", "details", "|", "members"),
            drawn(listOf(
                FlareActionItem("search", "Search", group = "view"),
                FlareActionItem("details", "Details", group = "view"),
                FlareActionItem("members", "Members", group = "manage"),
            )),
        )
        assertEquals(emptyList(), drawn(emptyList()))
    }

    @Test fun anItemWithoutAGroupStaysInTheCurrentOneAndAReturningGroupIsSeparatedAgain() {
        assertEquals(
            listOf("a", "b", "|", "c", "d", "|", "e"),
            drawn(listOf(
                FlareActionItem("a", "A", group = "one"),
                FlareActionItem("b", "B"),
                FlareActionItem("c", "C", group = "two"),
                FlareActionItem("d", "D"),
                FlareActionItem("e", "E", group = "one"),
            )),
        )
    }

    @Test fun invisibleItemsLeaveBeforeGroupingAndAMenuWithNothingVisibleHasNoRows() {
        // The hidden "b" would have opened a group; without it "c" continues the group of "a".
        assertEquals(
            listOf("a", "c"),
            drawn(listOf(
                FlareActionItem("a", "A", group = "one"),
                FlareActionItem("b", "B", group = "two", visible = false),
                FlareActionItem("c", "C", group = "one"),
            )),
        )
        assertTrue(actionMenuRows(listOf(FlareActionItem("x", "X", visible = false))).isEmpty())
    }

    @Test fun disabledAndCheckableItemsKeepTheirPlaceAndState() {
        val items = listOf(
            FlareActionItem("notify", "Notifications"),
            FlareActionItem("export", "Export", enabled = false, disabledReason = "Owner only"),
            FlareActionItem("pin", "Pin", pressed = true),
            FlareActionItem("mute", "Mute", pressed = false),
        )
        val rows = actionMenuRows(items)
        assertEquals(items, rows.map { it.item })
        assertEquals(listOf(null, null, true, false), rows.map { it.item.pressed })
        assertFalse(rows[1].item.enabled)
    }

    @Test fun anEnabledItemClosesTheMenuBeforeReportingAndADisabledOneNeverReports() {
        val calls = mutableListOf<String>()
        val dismiss = { calls += "dismiss" }
        val select = { id: String -> calls += "select:$id" }

        assertTrue(chooseActionMenuItem(FlareActionItem("pin", "Pin", pressed = false), dismiss, select))
        assertEquals(listOf("dismiss", "select:pin"), calls)

        calls.clear()
        assertFalse(chooseActionMenuItem(FlareActionItem("export", "Export", enabled = false, disabledReason = "Owner only"), dismiss, select))
        assertFalse(chooseActionMenuItem(FlareActionItem("hidden", "Hidden", visible = false), dismiss, select))
        assertEquals(emptyList(), calls)
    }

    @Test fun rowsMeetThePointerTargetUnderAFinePointerAndTheTouchTargetOtherwise() {
        assertEquals(FlareSizes.touchTargetMin, actionMenuRowMinHeight(FlarePointerKind.Fine))
        for (pointer in listOf(FlarePointerKind.Coarse, FlarePointerKind.Mixed, FlarePointerKind.Unknown)) {
            assertEquals(FlareSizes.touchTarget, actionMenuRowMinHeight(pointer), "$pointer")
        }
    }

    @Test fun theMenuShadowIsTheDepthOfTheLgToken() {
        assertEquals(12.dp, flareShadowElevation(FlareShadows.Light.lg))
        assertEquals(8.dp, flareShadowElevation(FlareShadows.Dark.lg))
        assertEquals(0.dp, flareShadowElevation(FlareShadows.Light.none))
    }

    @Test fun headerActionsMapFieldByField() {
        val action = ConversationHeaderAction(
            id = "mute",
            label = "Mute",
            icon = "mute",
            placement = ConversationHeaderActionPlacement.Overflow,
            group = "prefs",
            order = 5,
            visible = true,
            enabled = false,
            badge = "2",
            intent = "conversation.mute",
            capability = "mute",
            accessibilityLabel = "Mute notifications",
            disabledReason = "Read only",
            pressed = true,
        )
        assertEquals(
            FlareActionItem(
                id = "mute",
                label = "Mute",
                icon = "mute",
                group = "prefs",
                visible = true,
                enabled = false,
                badge = "2",
                accessibilityLabel = "Mute notifications",
                disabledReason = "Read only",
                pressed = true,
                danger = false,
            ),
            action.toActionItem(),
        )
        // Without an icon name the action id names the glyph, as on the header's own buttons.
        assertEquals("details", ConversationHeaderAction("details", "Details").toActionItem().icon)
        assertNull(ConversationHeaderAction("details", "Details").toActionItem().pressed)
    }

    @Test fun iconNamesResolveThroughTheHeaderMappingThenTheLibrary() {
        assertEquals(Icons.Outlined.Call, flareActionIcon("audioCall"))
        assertEquals(Icons.Outlined.Call, flareActionIcon("phone"))
        assertEquals(Icons.Outlined.Info, flareActionIcon("details"))
        assertEquals(flareIconVector("mute"), flareActionIcon("mute"))
        assertEquals(flareIconVector("block"), flareActionIcon("block"))
        assertEquals(Icons.Rounded.MoreHoriz, flareActionIcon("no-such-icon"))
    }

    @Test fun headerActionIdsAliasRegistryNames() {
        assertEquals(
            mapOf("audioCall" to "phone", "videoCall" to "video", "addMember" to "person-add", "details" to "info"),
            flareActionIconAliases,
        )
        for ((alias, name) in flareActionIconAliases) {
            assertTrue(name in flareIconNames, "$alias points at a registry name")
            assertEquals(name, flareActionIconName(alias))
            assertEquals(flareIconVector(name), flareActionIcon(alias), "$alias draws $name")
        }
        // Registry names pass through unchanged, search included: one glyph per name on every path.
        assertEquals("search", flareActionIconName("search"))
        assertEquals(flareIconVector("search"), flareActionIcon("search"))
        // A header action without an icon is drawn by its id.
        assertEquals(flareIconVector("info"), flareActionIcon(ConversationHeaderAction("details", "Details").toActionItem().icon!!))
    }

    private val window = IntSize(1080, 2000)
    private val card = IntSize(400, 600)
    private val edge = 126

    @Test fun aMenuUnderAnEndTriggerHangsFromTheTriggerEndEdge() {
        // The header's "more" button at the end of the bar: the card cannot start at the anchor, so it ends there.
        val anchor = IntRect(960, 100, 1080, 220)
        assertEquals(IntRect(680, 220, 1080, 820), actionMenuCardBounds(anchor, window, card, LayoutDirection.Ltr, edge))
        // Right to left, the end-aligned card is the preferred one.
        assertEquals(IntRect(680, 220, 1080, 820), actionMenuCardBounds(anchor, window, card, LayoutDirection.Rtl, edge))
    }

    @Test fun aMenuUnderAStartTriggerStartsAtTheTrigger() {
        val anchor = IntRect(0, 100, 120, 220)
        assertEquals(IntRect(0, 220, 400, 820), actionMenuCardBounds(anchor, window, card, LayoutDirection.Ltr, edge))
        // Right to left the card would end at the anchor's end edge, which leaves the window, so it starts there instead.
        assertEquals(IntRect(0, 220, 400, 820), actionMenuCardBounds(anchor, window, card, LayoutDirection.Rtl, edge))
    }

    @Test fun aMenuWithoutRoomBelowOpensAboveAndKeepsTheEdgeMargin() {
        val low = IntRect(0, 1700, 120, 1820)
        assertEquals(IntRect(0, 1100, 400, 1700), actionMenuCardBounds(low, window, card, LayoutDirection.Ltr, edge))
        // A trigger inside the top margin still opens below the margin, never over the status area.
        val high = IntRect(0, 20, 120, 100)
        assertEquals(edge, actionMenuCardBounds(high, window, card, LayoutDirection.Ltr, edge).top)
    }

    @Test fun thePopupWindowReservesTheShadowAroundTheCard() {
        val room = 32
        var origin: TransformOrigin? = null
        val provider = ActionMenuPositionProvider(shadowRoom = room, edgeMargin = edge, onPlaced = { origin = it })
        val anchor = IntRect(960, 100, 1080, 220)
        val popup = IntSize(card.width + 2 * room, card.height + 2 * room)
        assertEquals(IntOffset(680 - room, 220 - room), provider.calculatePosition(anchor, window, LayoutDirection.Ltr, popup))
        // It grows from the middle of the edge it shares with the trigger: its top, under the trigger's span.
        assertEquals(TransformOrigin((1020 - 680) / 400f, 0f), origin)
    }

    @Test fun aMenuAboveItsTriggerGrowsFromItsBottomEdge() {
        val anchor = IntRect(0, 1700, 120, 1820)
        assertEquals(TransformOrigin(60 / 400f, 1f), actionMenuTransformOrigin(anchor, IntRect(0, 1100, 400, 1700)))
    }
}
