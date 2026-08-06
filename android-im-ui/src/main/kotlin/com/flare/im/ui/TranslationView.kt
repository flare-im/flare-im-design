package com.flare.im.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Translate
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Inline machine-translation block. Spec: Message/TranslationView. */
@Composable
fun TranslationView(
    translated: String,
    original: String? = null,
    provider: String? = null,
    pending: Boolean = false,
) {
    val colors = flareColors()
    var showOriginal by remember { mutableStateOf(false) }
    val spin = rememberInfiniteTransition(label = "translate")
    val angle by spin.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(900, easing = LinearEasing), RepeatMode.Restart),
        label = "spin",
    )
    Row(Modifier.padding(top = 4.dp).height(IntrinsicSize.Min)) {
        Box(Modifier.width(2.dp).fillMaxHeight().background(colors.primary.copy(alpha = 0.4f)))
        Column(Modifier.padding(start = 10.dp)) {
            if (pending) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Language, contentDescription = null, tint = colors.textTertiary,
                        modifier = Modifier.size(14.dp).rotate(angle))
                    Spacer(Modifier.width(6.dp))
                    Text(flareStrings().translating, color = colors.textTertiary, fontSize = 13.sp)
                }
            } else {
                Text(translated, color = colors.textPrimary, fontSize = 14.sp)
                Row(
                    Modifier.fillMaxWidth().padding(top = 5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Outlined.Translate, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(if (provider != null) flareStrings().translatedBy(provider) else flareStrings().translated,
                        color = colors.textTertiary, fontSize = 11.sp)
                    Spacer(Modifier.weight(1f))
                    if (original != null) {
                        Row(
                            Modifier.clickable { showOriginal = !showOriginal },
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(if (showOriginal) flareStrings().hideOriginal else flareStrings().showOriginal, color = colors.primary, fontSize = 11.sp)
                            Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = colors.primary,
                                modifier = Modifier.size(13.dp).rotate(if (showOriginal) 180f else 0f))
                        }
                    }
                }
                if (original != null && showOriginal) {
                    Box(Modifier.fillMaxWidth().padding(top = 6.dp).height(1.dp).background(colors.borderPrimary))
                    Text(original, color = colors.textSecondary, fontSize = 13.sp, modifier = Modifier.padding(top = 6.dp))
                }
            }
        }
    }
}
