package com.flare.im.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp

/**
 * Result view — the one outcome layout of a money action, a verification submit or a failed send (R7 of
 * docs/plugin-experience.md). Spec: Plugin/ResultView (`FlareResultView`).
 *
 * A [tone] icon (success → success, info → clock, warning → warning, danger → error, neutral → info) in a
 * `component.resultIconSize` circle of the tone at `opacity.tintWeak`; [title] (`textRole.title`); [amount] in
 * `component.amountHeroFontSize`, tabular; [description] (at most 3 lines); [details] as label/value rows; the done key
 * (primary, [doneLabel] else `pluginView.done`; full width on a phone — a page pins it to the bottom itself with
 * [FlareResultDoneBar] — and 240 wide, centred, on a wide window) and an optional [secondaryLabel] key. The title and description are
 * announced politely whenever they change (the result moved to another state). [busy] locks both keys.
 * [actions] go under the keys (a result page's own actions, as secondary keys).
 */
@Composable
fun FlareResultView(
    title: String,
    tone: PluginTone = PluginTone.Info,
    modifier: Modifier = Modifier,
    amount: String? = null,
    description: String? = null,
    details: List<PluginViewField> = emptyList(),
    doneLabel: String? = null,
    secondaryLabel: String? = null,
    busy: Boolean = false,
    /** A state outside the plugin's values: the info icon, whatever [tone] says. */
    unknown: Boolean = false,
    onDone: (() -> Unit)? = null,
    onSecondary: (() -> Unit)? = null,
    actions: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val ink = pluginToneText(tone)
    val fill = pluginToneFill(tone)
    val reducedMotion = flareReducedMotion()
    val grow = remember(title, tone) { Animatable(if (reducedMotion) 1f else 0.6f) }
    LaunchedEffect(title, tone) { if (!reducedMotion) grow.animateTo(1f, spring()) }
    Column(
        modifier.fillMaxWidth().widthIn(max = FlareSizes.componentFormColumnWidth),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Box(
            Modifier.size(FlareSizes.componentResultIconSize).scale(grow.value).clip(CircleShape)
                .background(fill.copy(alpha = FlareOpacity.tintWeak)),
            contentAlignment = Alignment.Center,
        ) { FlareIcon(pluginResultIcon(tone, unknown), size = FlareSizes.iconSizeXl, tint = ink) }
        // One polite announcement per state: the title and the description read together.
        Column(
            Modifier.fillMaxWidth().semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            Text(
                title, color = colors.textPrimary, fontSize = FlareTextRoles.Title.fontSize, fontWeight = FlareTextRoles.Title.fontWeight,
                textAlign = TextAlign.Center, modifier = Modifier.semantics { heading() },
            )
            amount?.let {
                Text(
                    it, color = colors.textPrimary, fontSize = FlareSizes.componentAmountHeroFontSize.value.sp,
                    fontWeight = FontWeight.Bold, style = FlareTabularFigures, textAlign = TextAlign.Center,
                )
            }
            description?.let {
                Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center,
                    maxLines = 3, overflow = TextOverflow.Ellipsis)
            }
        }
        // R3: reference fields (fund orders, proofs) fold under References after the details.
        val (main, references) = remember(details) { pluginSplitReferences(details) }
        if (main.isNotEmpty()) PluginDescriptionList(main, Modifier.padding(top = FlareSizes.spacingSm))
        if (references.isNotEmpty()) Box(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm)) { PluginFieldList(references, "result") }
        Column(
            Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            val wide = !flareCompactOverlays()
            val keyWidth = if (wide) Modifier.width(FlareSizes.componentResultActionWidth) else Modifier.fillMaxWidth()
            if (onDone != null) Box(keyWidth.align(Alignment.CenterHorizontally)) {
                Button(label = doneLabel ?: strings.pluginViewDone, size = FlareControlSize.Lg, block = true, disabled = busy, onClick = onDone)
            }
            if (secondaryLabel != null) Box(keyWidth.align(Alignment.CenterHorizontally)) {
                Button(label = secondaryLabel, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Lg,
                    block = true, disabled = busy, onClick = onSecondary)
            }
            actions?.let { Column(keyWidth.align(Alignment.CenterHorizontally), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) { it() } }
        }
    }
}

/** R7: a phone's done key, pinned over the navigation bar on the primary surface with a hairline on top, full width. */
@Composable
fun FlareResultDoneBar(onDone: () -> Unit, label: String? = null, busy: Boolean = false) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary).windowInsetsPadding(WindowInsets.navigationBars)) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
        Box(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd)) {
            Button(label = label ?: flareStrings().pluginViewDone, size = FlareControlSize.Lg, block = true, disabled = busy, onClick = onDone)
        }
    }
}

/** The fill of a tone (the hue the text ink is the readable half of). */
@Composable
internal fun pluginToneFill(tone: PluginTone): androidx.compose.ui.graphics.Color {
    val colors = flareColors()
    return when (tone) {
        PluginTone.Neutral -> colors.textSecondary
        PluginTone.Info -> colors.info
        PluginTone.Success -> colors.success
        PluginTone.Warning -> colors.warning
        PluginTone.Danger -> colors.error
    }
}

/**
 * Label/value rows (the kit DescriptionList of R7 and 5.6): the label at the start in secondary text, the value at the
 * end; a toned or unmapped value is the kit Tag (R3). Each row reads as one.
 */
@Composable
internal fun PluginDescriptionList(fields: List<PluginViewField>, modifier: Modifier = Modifier) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(
        modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusCard)).background(colors.bgSecondary)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
    ) {
        fields.forEach { field ->
            Row(
                Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm).semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
                Box(Modifier.weight(1f), contentAlignment = Alignment.CenterEnd) {
                    PluginStatusValue(field.value, field.format, field.tone, field.unmapped, strings, TextAlign.End)
                }
            }
        }
    }
}
