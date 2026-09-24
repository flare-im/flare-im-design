package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val SKIN_TONES = listOf("", "🏻", "🏼", "🏽", "🏾", "🏿")

/** Full emoji picker — search + categories + recents + skin tones. Spec: Composer/EmojiPicker. */
@Composable
fun EmojiPicker(
    categories: List<EmojiCategory>,
    recents: List<String> = emptyList(),
    skinTones: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    onToneChange: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    var query by remember { mutableStateOf("") }
    var tone by remember { mutableStateOf("") }
    val recentKey = "__recent"
    val recentLabel = flareStrings().recent
    val tabs = buildList {
        if (recents.isNotEmpty()) add(EmojiCategory(recentKey, recentLabel, "🕘", recents))
        addAll(categories)
    }
    var activeKey by remember { mutableStateOf(tabs.firstOrNull()?.key ?: "") }
    val activeCat = tabs.firstOrNull { it.key == activeKey } ?: tabs.firstOrNull()
    val searching = query.trim().isNotEmpty()
    val shown = if (searching) {
        categories.flatMap { it.emojis }.distinct().filter { it.contains(query.trim()) }
    } else {
        activeCat?.emojis ?: emptyList()
    }

    Column(
        Modifier.width(320.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Search, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(15.dp))
            Spacer(Modifier.width(8.dp))
            BasicTextField(
                value = query, onValueChange = { query = it }, singleLine = true,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 14.sp),
                cursorBrush = SolidColor(colors.primary), modifier = Modifier.weight(1f),
                decorationBox = { inner ->
                    if (query.isEmpty()) Text(flareStrings().searchEmoji, color = colors.textTertiary, fontSize = 14.sp)
                    inner()
                },
            )
            if (skinTones) {
                Row {
                    SKIN_TONES.forEach { tn ->
                        Text(if (tn.isEmpty()) "✋" else "✋$tn", fontSize = 14.sp,
                            modifier = Modifier.size(22.dp).clip(RoundedCornerShape(FlareSizes.radiusSm))
                                .background(if (tone == tn) colors.bgSelected else Color.Transparent)
                                .clickable { tone = tn; onToneChange?.invoke(tn) },
                            textAlign = TextAlign.Center)
                    }
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        Column(Modifier.height(200.dp).verticalScroll(rememberScrollState()).padding(FlareSizes.spacingSm)) {
            shown.chunked(8).forEach { row ->
                Row(Modifier.fillMaxWidth()) {
                    row.forEach { e ->
                        Text(e, fontSize = 22.sp, textAlign = TextAlign.Center,
                            modifier = Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(FlareSizes.radiusMd))
                                .clickable { onSelect?.invoke(if (tone.isEmpty()) e else e + tone) }.padding(FlareSizes.spacingXs))
                    }
                    repeat(8 - row.size) { Spacer(Modifier.weight(1f)) }
                }
            }
            if (shown.isEmpty()) {
                Text(flareStrings().noMatchingEmoji, color = colors.textTertiary, fontSize = 13.sp,
                    modifier = Modifier.fillMaxWidth().padding(40.dp), textAlign = TextAlign.Center)
            }
        }
        if (!searching) {
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
            // The first chip keeps its 8 dp from the edge; chips sit 16 dp apart so their 48 dp targets never overlap.
            Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState())) {
                tabs.forEach { c ->
                    val active = c.key == activeKey
                    // A tab is named by its category, whatever glyph stands for it, and reports whether it is open.
                    // Each tab is a 48 dp target around its 32 dp chip.
                    Box(
                        Modifier.sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
                            .clip(RoundedCornerShape(FlareSizes.radiusMd))
                            .selectable(selected = active, role = Role.Tab) { activeKey = c.key }
                            .semantics { contentDescription = c.label },
                        contentAlignment = Alignment.Center,
                    ) {
                        Box(
                            Modifier.size(FlareSizes.iconSizeXl).clip(RoundedCornerShape(FlareSizes.radiusMd))
                                .background(if (active) colors.bgSelected else Color.Transparent),
                            contentAlignment = Alignment.Center,
                        ) {
                            val glyph = c.symbol ?: c.emojis.firstOrNull()
                            when {
                                c.key == recentKey -> Icon(flareIconVector("clock"), contentDescription = null, tint = colors.textSecondary, modifier = Modifier.size(FlareSizes.iconSizeSm))
                                glyph != null -> Text(glyph, fontSize = FlareSizes.fontSize3xl.value.sp, modifier = Modifier.clearAndSetSemantics {})
                                // No glyph to stand for the category: its label, never an arbitrary emoji.
                                else -> Text(
                                    c.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeXs.value.sp, maxLines = 1,
                                    modifier = Modifier.clearAndSetSemantics {},
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
