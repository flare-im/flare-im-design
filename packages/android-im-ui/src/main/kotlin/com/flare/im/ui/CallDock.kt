package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/**
 * The icon-only controls of a [CallDock]: the microphone switch (on = capturing, glyph follows the
 * state) and hang up, which draws the end-call glyph rather than a rotated handset.
 */
internal fun callDockControls(strings: FlareStrings, muted: Boolean): List<FlareIconControlSpec> = listOf(
    FlareIconControlSpec("microphone", if (muted) "mic-off" else "mic", strings.microphone, checked = !muted),
    FlareIconControlSpec("hangUp", "end-call", strings.hangUp),
)

/** Minimized floating call bar. Spec: Call/CallDock. */
@Composable
fun CallDock(
    title: String,
    avatarUrl: String? = null,
    durationLabel: String? = null,
    mode: FlareCallMode = FlareCallMode.Audio,
    muted: Boolean = false,
    onExpand: (() -> Unit)? = null,
    onToggleMute: (() -> Unit)? = null,
    onHangup: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val (microphone, hangUp) = callDockControls(strings, muted)
    // The mute and hang-up discs are drawn at 36 dp inside 48 dp touch targets; the bar's padding and
    // the gaps give back the 6 dp a side the targets add, so the dock keeps its size and insets.
    Row(
        Modifier
            .shadow(12.dp, RoundedCornerShape(999.dp), clip = false)
            .clip(RoundedCornerShape(999.dp))
            .background(colors.messageOutgoingBackground)
            .padding(start = 8.dp, top = 4.dp, bottom = 4.dp, end = FlareSizes.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.then(
                if (onExpand != null) Modifier.clickable(role = Role.Button, onClickLabel = strings.callReturn) { onExpand() } else Modifier,
            ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(contentAlignment = Alignment.Center) {
                Avatar(
                    userId = title, displayName = title, size = 34.dp,
                    image = avatarUrl?.let { url ->
                        { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
                    },
                )
                Box(Modifier.size(40.dp).clip(CircleShape).border(2.dp, colors.success, CircleShape))
            }
            Spacer(Modifier.width(10.dp))
            Column {
                Text(title, color = colors.messageOutgoingForeground, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeLg.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.widthIn(max = 120.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(flareIconVector(if (mode == FlareCallMode.Video) "video" else "phone"),
                        contentDescription = null, tint = colors.messageOutgoingForeground.copy(alpha = 0.66f), modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(durationLabel ?: flareStrings().callConnected, color = colors.messageOutgoingForeground.copy(alpha = 0.66f), fontSize = 12.sp)
                }
            }
            Spacer(Modifier.width(2.dp))
            Icon(flareIconVector("expand"), contentDescription = null, tint = colors.messageOutgoingForeground.copy(alpha = 0.5f), modifier = Modifier.size(FlareSizes.iconSizeSm))
        }
        Spacer(Modifier.width(FlareSizes.spacingXs))
        FlareIconControl(label = microphone.label, onClick = onToggleMute, checked = microphone.checked) {
            Box(
                Modifier.size(36.dp).clip(CircleShape)
                    .background(if (muted) colors.messageOutgoingForeground else colors.messageOutgoingForeground.copy(alpha = 0.14f)),
            )
            Icon(flareIconVector(microphone.icon), contentDescription = null,
                tint = if (muted) colors.messageOutgoingBackground else colors.messageOutgoingForeground, modifier = Modifier.size(18.dp))
        }
        FlareIconControl(label = hangUp.label, onClick = onHangup) {
            Box(Modifier.size(36.dp).clip(CircleShape).background(colors.error))
            Icon(flareIconVector(hangUp.icon), contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
        }
    }
}
