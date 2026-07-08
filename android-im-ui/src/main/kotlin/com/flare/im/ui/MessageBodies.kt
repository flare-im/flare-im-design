package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material.icons.outlined.VolumeUp
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/*
 * Standalone, presentational per-type message bodies (clean params, no SDK /
 * media coupling) — drop any single one into your own layout. The SDK-driven
 * dispatcher MessageContentView stays the batteries-included path.
 * Spec: Message/MessageContentView content types, decomposed into components.
 */

private fun Modifier.bubbleCard(colors: FlareColors): Modifier = this
    .shadow(2.dp, RoundedCornerShape(16.dp), clip = false)
    .clip(RoundedCornerShape(16.dp))
    .background(colors.bgPrimary)
    .border(1.dp, colors.borderSecondary, RoundedCornerShape(16.dp))

/** text — a plain text bubble (self flips to the brand-purple side). */
@Composable
fun TextMessage(text: String, self: Boolean = false) {
    val colors = flareColors()
    Text(
        text,
        color = if (self) Color.White else colors.textPrimary,
        fontSize = FlareSizes.fontSizeXl.value.sp,
        lineHeight = (FlareSizes.fontSizeXl.value * 1.45f).sp,
        modifier = Modifier
            .then(
                if (self) Modifier.clip(RoundedCornerShape(16.dp)).background(colors.bubbleSelf)
                else Modifier.bubbleCard(colors),
            )
            .padding(horizontal = 14.dp, vertical = 9.dp),
    )
}

/** image — a rounded thumbnail placeholder. */
@Composable
fun ImageMessage(width: Int = 132, height: Int = 92) {
    val colors = flareColors()
    Box(
        Modifier.size(width.dp, height.dp).clip(RoundedCornerShape(12.dp)).background(colors.bgTertiary),
        contentAlignment = Alignment.Center,
    ) { Icon(Icons.Outlined.Image, null, Modifier.size(26.dp), tint = colors.textTertiary) }
}

/** video — a thumbnail with a play overlay and duration badge. */
@Composable
fun VideoMessage(duration: String = "00:00") {
    val colors = flareColors()
    Box(
        Modifier.size(148.dp, 92.dp).clip(RoundedCornerShape(12.dp)).background(colors.bgTertiary),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Outlined.Videocam, null, Modifier.size(24.dp), tint = colors.textTertiary.copy(alpha = 0.5f))
        Box(Modifier.fillMaxWidth().height(92.dp).background(Color.Black.copy(alpha = 0.28f)))
        Icon(Icons.Filled.PlayArrow, null, Modifier.size(34.dp), tint = Color.White)
        Box(Modifier.fillMaxWidth().height(92.dp).padding(6.dp), contentAlignment = Alignment.BottomEnd) {
            Text(
                duration, color = Color.White, fontSize = 10.sp,
                modifier = Modifier.clip(RoundedCornerShape(5.dp)).background(Color.Black.copy(alpha = 0.45f))
                    .padding(horizontal = 5.dp, vertical = 1.dp),
            )
        }
    }
}

/** audio / voice — a compact bubble with a waveform and duration. */
@Composable
fun VoiceMessage(seconds: Int = 1) {
    val colors = flareColors()
    Row(
        Modifier.bubbleCard(colors).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(Icons.Outlined.VolumeUp, null, Modifier.size(17.dp), tint = colors.textSecondary)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            for (n in 1..9) {
                Box(Modifier.size(2.dp, (4 + (n * 5) % 13).dp).clip(RoundedCornerShape(2.dp)).background(colors.primary))
            }
        }
        Text("$seconds\"", color = colors.textTertiary, fontSize = 12.sp)
    }
}

/** file — a file card with name / size / ext and a download affordance. */
@Composable
fun FileMessage(name: String, size: String = "", ext: String? = null) {
    val colors = flareColors()
    val sub = if (!ext.isNullOrEmpty()) "$size · $ext" else size
    Row(
        Modifier.widthIn(max = 300.dp).bubbleCard(colors).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Outlined.Folder, null, Modifier.size(20.dp), tint = colors.primary)
        Column(Modifier.weight(1f, fill = false)) {
            Text(name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(sub, color = colors.textTertiary, fontSize = 11.sp)
        }
        Icon(Icons.Outlined.FileDownload, null, Modifier.size(17.dp), tint = colors.textTertiary)
    }
}

/** location — a map placeholder over a title / address. */
@Composable
fun LocationMessage(title: String, address: String = "") {
    val colors = flareColors()
    Column(Modifier.width(264.dp).bubbleCard(colors)) {
        Box(
            Modifier.fillMaxWidth().height(84.dp)
                .background(colors.primary.copy(alpha = 0.08f).compositeOverColor(colors.bgTertiary)),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Outlined.LocationOn, null, Modifier.size(22.dp), tint = colors.primary) }
        Column(Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium)
            Text(address, color = colors.textTertiary, fontSize = 11.sp)
        }
    }
}

/** contact / business card — pastel avatar + name / id. */
@Composable
fun ContactMessage(name: String, flareId: String? = null) {
    val colors = flareColors()
    val tint = seedTint(name)
    Row(
        Modifier.widthIn(min = 240.dp).bubbleCard(colors).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(44.dp).clip(RoundedCornerShape(10.dp)).background(tint.first), contentAlignment = Alignment.Center) {
            Text(initials(name), color = tint.second, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
        }
        Column(Modifier.weight(1f, fill = false)) {
            Text(name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl.value.sp, fontWeight = FontWeight.SemiBold)
            if (!flareId.isNullOrEmpty()) {
                Text("Flare ID: $flareId", color = colors.textTertiary, fontSize = 11.sp)
            }
        }
        Icon(Icons.Outlined.ChevronRight, null, Modifier.size(16.dp), tint = colors.textTertiary)
    }
}

/** link card — thumbnail + title + domain. */
@Composable
fun LinkCardMessage(title: String, domain: String = "") {
    val colors = flareColors()
    Row(
        Modifier.widthIn(max = 300.dp).bubbleCard(colors).padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(Modifier.size(48.dp).clip(RoundedCornerShape(8.dp)).background(colors.bgTertiary), contentAlignment = Alignment.Center) {
            Icon(Icons.Outlined.Image, null, Modifier.size(22.dp), tint = colors.textTertiary)
        }
        Column(Modifier.weight(1f, fill = false), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                Icon(Icons.Outlined.Link, null, Modifier.size(12.dp), tint = colors.textTertiary)
                Text(domain, color = colors.textTertiary, fontSize = 11.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** A vote option for [VoteMessage]. */
data class FlareVoteOption(val text: String, val pct: Int)

/** vote — a title over option rows with proportional bars. */
@Composable
fun VoteMessage(title: String, options: List<FlareVoteOption> = emptyList()) {
    val colors = flareColors()
    Column(
        Modifier.widthIn(min = 220.dp).bubbleCard(colors).padding(horizontal = 12.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Outlined.BarChart, null, Modifier.size(16.dp), tint = colors.textPrimary)
            Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.SemiBold)
        }
        options.forEach { o ->
            Box(Modifier.fillMaxWidth().height(30.dp).clip(RoundedCornerShape(7.dp)).background(colors.bgSecondary)) {
                Box(Modifier.fillMaxWidth((o.pct.coerceIn(0, 100)) / 100f).height(30.dp)
                    .background(colors.primary.copy(alpha = 0.16f)))
                Row(Modifier.fillMaxWidth().height(30.dp).padding(horizontal = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(o.text, color = colors.textPrimary, fontSize = 13.sp, modifier = Modifier.weight(1f))
                    Text("${o.pct}%", color = colors.textSecondary, fontSize = 12.sp)
                }
            }
        }
    }
}

/** task — checkbox + title (struck through when done) + meta. */
@Composable
fun TaskMessage(title: String, meta: String? = null, done: Boolean = false) {
    val colors = flareColors()
    Row(
        Modifier.widthIn(min = 220.dp).bubbleCard(colors).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            Modifier.size(20.dp).clip(RoundedCornerShape(6.dp))
                .then(if (done) Modifier.background(colors.primary) else Modifier.border(1.5.dp, colors.borderPrimary, RoundedCornerShape(6.dp))),
            contentAlignment = Alignment.Center,
        ) { if (done) Icon(Icons.Rounded.Check, null, Modifier.size(13.dp), tint = Color.White) }
        Column(Modifier.weight(1f, fill = false)) {
            Text(
                title,
                color = if (done) colors.textTertiary else colors.textPrimary,
                fontSize = FlareSizes.fontSizeLg.value.sp, fontWeight = FontWeight.Medium,
                textDecoration = if (done) TextDecoration.LineThrough else null,
            )
            if (!meta.isNullOrEmpty()) Text(meta, color = colors.textTertiary, fontSize = 11.sp)
        }
    }
}

/** sticker — a bare, larger glyph (no bubble). */
@Composable
fun StickerMessage(emoji: String = "🐱") {
    Text(emoji, fontSize = 72.sp)
}

/** emoji — a bare, large emoji (no bubble). */
@Composable
fun EmojiMessage(emoji: String = "🎉") {
    Text(emoji, fontSize = 40.sp)
}

/** notification / system — a centered pill. */
@Composable
fun SystemMessage(text: String) {
    val colors = flareColors()
    Text(
        text, color = colors.textTertiary, fontSize = 12.sp,
        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgTertiary)
            .padding(horizontal = 12.dp, vertical = 4.dp),
    )
}

// blend a translucent color over an opaque base (for the location map tint)
private fun Color.compositeOverColor(base: Color): Color {
    val a = alpha
    return Color(
        red = red * a + base.red * (1 - a),
        green = green * a + base.green * (1 - a),
        blue = blue * a + base.blue * (1 - a),
        alpha = 1f,
    )
}
