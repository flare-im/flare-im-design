package com.flare.im.ui

import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.rememberTransition
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupPositionProvider
import androidx.compose.ui.window.PopupProperties
import kotlin.math.max
import kotlin.math.min

/**
 * One entry of an [ActionMenu]. The fields are the kit's action vocabulary —
 * [ConversationHeaderAction] carries the same ones — so a host maps its actions field by field.
 * Spec: General/ActionMenu (`FlareActionItem`).
 */
data class FlareActionItem(
    /** Stable id, reported to `onSelect` when the item is chosen. */
    val id: String,
    val label: String,
    /**
     * A semantic kit icon name ([flareIconNames], or a header action id such as `audioCall`),
     * resolved by the same mapping as [ConversationHeaderAction.icon]; null draws no icon.
     */
    val icon: String? = null,
    /** Items are separated where the group changes; hosts put destructive items in their own group. */
    val group: String? = null,
    /** False leaves the item out entirely, before grouping. */
    val visible: Boolean = true,
    /** False draws the item and announces it disabled; it never reports. */
    val enabled: Boolean = true,
    /** Compact trailing text, e.g. a count. */
    val badge: String? = null,
    /** Replaces the row's spoken name, which is otherwise its label, reason and badge. */
    val accessibilityLabel: String? = null,
    /** Why a disabled item is unavailable; drawn as its second line. */
    val disabledReason: String? = null,
    /** Non-null makes the item checkable: a trailing check while true, and on/off state for assistive technology. */
    val pressed: Boolean? = null,
    /** Destructive: the label and icon use the error text colour; nothing else changes. */
    val danger: Boolean = false,
)

/** One drawn row of an [ActionMenu]: a visible item, and whether a separator opens a new group above it. */
internal data class FlareActionMenuRow(val item: FlareActionItem, val separatorBefore: Boolean)

/**
 * The rows an [ActionMenu] draws, in host order — the kit never sorts. Invisible items are left
 * out first; then a separator comes before an item whose group is set and differs from the last
 * group seen, unless nothing precedes it. An item without a group stays in the current one.
 */
internal fun actionMenuRows(items: List<FlareActionItem>): List<FlareActionMenuRow> {
    val rows = ArrayList<FlareActionMenuRow>(items.size)
    var group: String? = null
    for (item in items) {
        if (!item.visible) continue
        val opensGroup = item.group != null && item.group != group
        if (opensGroup) group = item.group
        rows += FlareActionMenuRow(item, separatorBefore = opensGroup && rows.isNotEmpty())
    }
    return rows
}

/**
 * Choosing [item]: an enabled, visible item closes the menu first and then reports its id; any
 * other item does nothing. Returns whether the item was reported.
 */
internal fun chooseActionMenuItem(item: FlareActionItem, onDismiss: () -> Unit, onSelect: (String) -> Unit): Boolean {
    if (!item.visible || !item.enabled) return false
    onDismiss()
    onSelect(item.id)
    return true
}

/** A row's height floor: the pointer target for a fine pointer, the full touch target wherever touch may be used. */
internal fun actionMenuRowMinHeight(pointer: FlarePointerKind): Dp =
    if (pointer == FlarePointerKind.Fine) FlareSizes.touchTargetMin else FlareSizes.touchTarget

/** A shadow token as a Compose elevation: the depth of its deepest layer, which is its vertical offset. */
internal fun flareShadowElevation(layers: List<FlareShadowLayer>): Dp = (layers.maxOfOrNull { it.offset.y } ?: 0f).dp

/**
 * Header action ids that stand for a registry icon under another name. A header action without an
 * explicit icon is drawn by its id, so these ids resolve to the same glyph on every platform.
 */
internal val flareActionIconAliases: Map<String, String> = mapOf(
    "audioCall" to "phone",
    "videoCall" to "video",
    "addMember" to "person-add",
    "details" to "info",
)

/** The registry name an action icon [name] resolves to: its alias target, or the name itself. */
internal fun flareActionIconName(name: String): String = flareActionIconAliases[name] ?: name

/**
 * The glyph for an action icon name — the one mapping behind [ConversationHeaderAction.icon] and
 * [FlareActionItem.icon]: the header's action-id aliases first, then the kit icon library, and
 * "more" for a name neither knows.
 */
internal fun flareActionIcon(name: String): ImageVector =
    flareIconVectorOrNull(flareActionIconName(name)) ?: Icons.Rounded.MoreHoriz

/**
 * Where an [ActionMenu] card goes, in window pixels — the Material dropdown rule applied to the
 * visible card: aligned to the anchor's start edge, else its end edge, else the window edge; below
 * the anchor, else above it, else centred on its top edge, else at the window bottom — keeping
 * [edgeMargin] clear at the top and bottom so there is always room to tap outside.
 */
internal fun actionMenuCardBounds(
    anchor: IntRect,
    window: IntSize,
    card: IntSize,
    layoutDirection: LayoutDirection,
    edgeMargin: Int,
): IntRect {
    val toAnchorStartLtr = anchor.left
    val toAnchorEndLtr = anchor.right - card.width
    val xCandidates = if (layoutDirection == LayoutDirection.Ltr) {
        listOf(toAnchorStartLtr, toAnchorEndLtr, if (anchor.left >= 0) window.width - card.width else 0)
    } else {
        listOf(toAnchorEndLtr, toAnchorStartLtr, if (anchor.right <= window.width) 0 else window.width - card.width)
    }
    val x = xCandidates.firstOrNull { it >= 0 && it + card.width <= window.width } ?: toAnchorEndLtr
    val below = max(anchor.bottom, edgeMargin)
    val above = anchor.top - card.height
    val yCandidates = listOf(below, above, anchor.top - card.height / 2, window.height - card.height - edgeMargin)
    val y = yCandidates.firstOrNull { it >= edgeMargin && it + card.height <= window.height - edgeMargin } ?: above
    return IntRect(x, y, x + card.width, y + card.height)
}

/** The point the card grows from as it opens: the part of its edge that faces the anchor. */
internal fun actionMenuTransformOrigin(anchor: IntRect, card: IntRect): TransformOrigin {
    val pivotX = when {
        card.left >= anchor.right -> 0f
        card.right <= anchor.left -> 1f
        card.width == 0 -> 0f
        else -> ((max(anchor.left, card.left) + min(anchor.right, card.right)) / 2 - card.left).toFloat() / card.width
    }
    val pivotY = when {
        card.top >= anchor.bottom -> 0f
        card.bottom <= anchor.top -> 1f
        card.height == 0 -> 0f
        else -> ((max(anchor.top, card.top) + min(anchor.bottom, card.bottom)) / 2 - card.top).toFloat() / card.height
    }
    return TransformOrigin(pivotX, pivotY)
}

/**
 * Places the menu popup, whose window is the card plus [shadowRoom] on every side: the card by
 * [actionMenuCardBounds], and the window [shadowRoom] above and left of the card.
 */
internal class ActionMenuPositionProvider(
    private val shadowRoom: Int,
    private val edgeMargin: Int,
    private val onPlaced: (TransformOrigin) -> Unit = {},
) : PopupPositionProvider {
    override fun calculatePosition(
        anchorBounds: IntRect,
        windowSize: IntSize,
        layoutDirection: LayoutDirection,
        popupContentSize: IntSize,
    ): IntOffset {
        val card = IntSize(
            (popupContentSize.width - 2 * shadowRoom).coerceAtLeast(0),
            (popupContentSize.height - 2 * shadowRoom).coerceAtLeast(0),
        )
        val bounds = actionMenuCardBounds(anchorBounds, windowSize, card, layoutDirection, edgeMargin)
        onPlaced(actionMenuTransformOrigin(anchorBounds, bounds))
        return IntOffset(bounds.left - shadowRoom, bounds.top - shadowRoom)
    }
}

// Material's menu width bounds: the native idiom the anchored dropdown follows.
private val ActionMenuMinWidth = 112.dp
private val ActionMenuMaxWidth = 280.dp

/**
 * A small menu of actions anchored to its trigger — the "add", "more" and context menus of an IM
 * app. Place it inside the trigger's `Box`, like `DropdownMenu`; the host owns [expanded].
 *
 * Rows keep host order, with a separator where the group changes. Choosing an enabled row calls
 * [onDismiss] and then [onSelect] with its id; a disabled row stays visible, is announced as
 * disabled and never reports. An item with `pressed` set is checkable: a trailing check while
 * pressed, and its on/off state exposed. The menu is named by [label] (the kit's action-menu
 * name when null), opens with keyboard focus on the first enabled row, and back, Escape or a tap
 * outside closes it through [onDismiss]. A list with no visible items never opens.
 *
 * Kit surface: `bgElevated` with a 1 dp `borderPrimary` border, `radiusLg` corners and the `lg`
 * shadow; rows at least the touch target (the pointer target under a fine pointer). The popup
 * window reserves the shadow's depth around the card, so the shadow is never cut off at the
 * window edge. Opening and closing use the `fast` motion token, or none under reduced motion.
 * Spec: General/ActionMenu (`ActionMenu`).
 */
@Composable
fun ActionMenu(
    expanded: Boolean,
    items: List<FlareActionItem>,
    onDismiss: () -> Unit,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
) {
    val rows = actionMenuRows(items)
    val openState = remember { MutableTransitionState(false) }
    openState.targetState = expanded && rows.isNotEmpty()
    // Stays composed while the close animation runs.
    if (!openState.currentState && !openState.targetState) return

    val colors = flareColors()
    val density = LocalDensity.current
    val name = label ?: flareStrings().actionMenuLabel
    val depth = flareShadowElevation(flareShadows().lg)
    val rowMinHeight = actionMenuRowMinHeight(flarePlatform().capabilities.pointer)
    val reducedMotion = flareReducedMotion()
    // Labels line up when any row has an icon, so a row without one keeps the icon column.
    val iconColumn = rows.any { it.item.icon != null }
    val transformOrigin = remember { mutableStateOf(TransformOrigin.Center) }
    val positionProvider = remember(density, depth) {
        ActionMenuPositionProvider(
            shadowRoom = with(density) { depth.roundToPx() },
            edgeMargin = with(density) { FlareSizes.touchTarget.roundToPx() },
            onPlaced = { transformOrigin.value = it },
        )
    }
    Popup(
        popupPositionProvider = positionProvider,
        onDismissRequest = onDismiss,
        // The card sits inside the screen; only the transparent shadow room may extend past it.
        properties = PopupProperties(focusable = true, clippingEnabled = false),
    ) {
        val transition = rememberTransition(openState, label = "ActionMenu")
        val shown by transition.animateFloat(
            transitionSpec = { if (reducedMotion) snap() else tween(FlareMotion.fast, easing = FlareMotion.fastEasing) },
            label = "ActionMenuShown",
        ) { open -> if (open) 1f else 0f }
        val shape = RoundedCornerShape(FlareSizes.radiusLg)
        val inputModeManager = LocalInputModeManager.current
        val firstEnabled = rows.indexOfFirst { it.item.enabled }
        val firstEnabledFocus = remember { FocusRequester() }
        val cardFocus = remember { FocusRequester() }
        // Keyboard users start on the first enabled row. When no row can take focus (touch mode, or nothing
        // enabled) the card holds it instead — nothing is drawn for that — so a hardware Escape still reaches it.
        val rowTakesFocus = firstEnabled >= 0 && inputModeManager.inputMode == InputMode.Keyboard
        Box(
            Modifier
                // A tap in the shadow room is a tap outside the menu.
                .pointerInput(onDismiss, depth) {
                    val room = depth.toPx()
                    detectTapGestures { at ->
                        val onCard = at.x in room..(size.width - room) && at.y in room..(size.height - room)
                        if (!onCard) onDismiss()
                    }
                }
                .padding(depth),
        ) {
            Column(
                Modifier
                    .graphicsLayer {
                        // Grows from the anchor while opening; closing only fades.
                        val scale = if (transition.targetState) OpeningScale + (1f - OpeningScale) * shown else 1f
                        scaleX = scale
                        scaleY = scale
                        alpha = shown
                        this.transformOrigin = transformOrigin.value
                    }
                    .shadow(depth, shape, clip = false)
                    .border(1.dp, colors.borderPrimary, shape)
                    .background(colors.bgElevated, shape)
                    .clip(shape)
                    .then(modifier)
                    .widthIn(min = ActionMenuMinWidth, max = ActionMenuMaxWidth)
                    .width(IntrinsicSize.Max)
                    .semantics {
                        paneTitle = name
                        contentDescription = name
                    }
                    // Escape closes the menu from wherever focus is inside it. Compose would otherwise
                    // spend the key on a focus exit, so it never becomes the system back.
                    .onPreviewKeyEvent { event ->
                        if (event.key != Key.Escape) return@onPreviewKeyEvent false
                        if (event.type == KeyEventType.KeyDown && openState.targetState) onDismiss()
                        true
                    }
                    .focusRequester(cardFocus)
                    .focusProperties { canFocus = !rowTakesFocus }
                    .focusable()
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = FlareSizes.spacingXs),
            ) {
                rows.forEachIndexed { index, row ->
                    if (row.separatorBefore) {
                        HorizontalDivider(
                            Modifier.padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
                            color = colors.borderPrimary,
                        )
                    }
                    ActionMenuRow(
                        item = row.item,
                        iconColumn = iconColumn,
                        minHeight = rowMinHeight,
                        colors = colors,
                        focusRequester = if (index == firstEnabled) firstEnabledFocus else null,
                        // A row fading out with a closing menu no longer chooses.
                        onChoose = { if (openState.targetState) chooseActionMenuItem(row.item, onDismiss, onSelect) },
                    )
                }
                LaunchedEffect(rowTakesFocus) {
                    runCatching { if (rowTakesFocus) firstEnabledFocus.requestFocus() else cardFocus.requestFocus() }
                }
            }
        }
    }
}

/** The card's starting size as it grows open, a fraction of its full size. */
private const val OpeningScale = 0.8f

@Composable
private fun ActionMenuRow(
    item: FlareActionItem,
    iconColumn: Boolean,
    minHeight: Dp,
    colors: FlareColors,
    focusRequester: FocusRequester?,
    onChoose: () -> Unit,
) {
    val labelColor = when {
        !item.enabled -> colors.textDisabled
        item.danger -> colors.errorText
        else -> colors.textPrimary
    }
    val iconTint = when {
        !item.enabled -> colors.textDisabled
        item.danger -> colors.errorText
        else -> colors.textSecondary
    }
    val pressed = item.pressed
    val action = if (pressed != null) {
        Modifier.toggleable(value = pressed, enabled = item.enabled, role = Role.Checkbox) { onChoose() }
    } else {
        Modifier.clickable(enabled = item.enabled, role = Role.Button, onClick = onChoose)
    }
    val spokenName = item.accessibilityLabel
    Row(
        Modifier.fillMaxWidth()
            .padding(horizontal = FlareSizes.spacingXs)
            .heightIn(min = minHeight)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .then(if (focusRequester != null) Modifier.focusRequester(focusRequester) else Modifier)
            .then(action)
            .then(if (spokenName != null) Modifier.semantics { contentDescription = spokenName } else Modifier)
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        if (iconColumn) {
            Box(Modifier.size(FlareSizes.iconSizeMd), contentAlignment = Alignment.Center) {
                item.icon?.let { icon ->
                    Icon(flareActionIcon(icon), contentDescription = null, tint = iconTint, modifier = Modifier.size(FlareSizes.iconSizeMd))
                }
            }
        }
        Column(Modifier.weight(1f)) {
            Text(item.label, color = labelColor, fontSize = FlareSizes.fontSizeLg)
            val reason = item.disabledReason
            if (!item.enabled && !reason.isNullOrBlank()) {
                Text(reason, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
            }
        }
        val badge = item.badge
        if (!badge.isNullOrEmpty()) {
            Text(badge, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
        }
        if (pressed == true) {
            Icon(
                Icons.Outlined.Check,
                contentDescription = null,
                tint = if (item.enabled) colors.primaryText else colors.textDisabled,
                modifier = Modifier.size(FlareSizes.iconSizeMd),
            )
        }
    }
}
