package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.layout.layout
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp

/**
 * One icon-only control as assistive technology meets it: a stable [id], the registry [icon] it
 * draws, the localized [label] TalkBack reads (what pressing it does), whether it is [enabled] and,
 * for a toggle, whether it is [checked]. Components derive these from their state in a pure function,
 * so the name, glyph and state of every such control are testable without mounting a UI.
 */
internal data class FlareIconControlSpec(
    val id: String,
    val icon: String,
    val label: String,
    val enabled: Boolean = true,
    val checked: Boolean? = null,
)

/**
 * An icon-only control: a node of at least [minSize] (the 48 dp touch target unless a layout is
 * deliberately denser) that carries [label] as its content description and a button role, or [role]
 * with its on/off state when [checked] is set. [content] is the glyph and any disc behind it, drawn at
 * its own size in the middle of the node; [modifier] places the node and must not size it. Without
 * [onClick] nothing is interactive and nothing is announced: the glyph stays decoration.
 */
/**
 * For the [modifier] of a [FlareIconControl] in a dense row: the row reserves only [visual] (the disc the
 * eye sees) while the control keeps its full touch target, centred on the disc and reaching past it. The
 * room it reaches into (the row's gaps, the surface's padding) must hold no other target.
 */
internal fun Modifier.flareTouchTargetBeyond(visual: Dp): Modifier = layout { measurable, constraints ->
    val target = measurable.measure(constraints.copy(minWidth = 0, minHeight = 0))
    val size = visual.roundToPx()
    layout(size, size) { target.place((size - target.width) / 2, (size - target.height) / 2) }
}

@Composable
internal fun FlareIconControl(
    label: String,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    checked: Boolean? = null,
    role: Role = if (checked == null) Role.Button else Role.Switch,
    shape: Shape = CircleShape,
    minSize: Dp = FlareSizes.touchTarget,
    content: @Composable BoxScope.() -> Unit,
) {
    val node = if (onClick == null) {
        Modifier
    } else {
        val action = if (checked != null) {
            Modifier.toggleable(value = checked, enabled = enabled, role = role) { onClick() }
        } else {
            Modifier.clickable(enabled = enabled, role = role, onClick = onClick)
        }
        Modifier.clip(shape).then(action).semantics { contentDescription = label }
    }
    Box(
        modifier.sizeIn(minWidth = minSize, minHeight = minSize).then(node),
        contentAlignment = Alignment.Center,
        content = content,
    )
}
