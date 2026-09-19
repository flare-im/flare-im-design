package com.flare.im.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.floor
import kotlin.math.sqrt

/**
 * Personal QR name card. Spec: Profile/QRCard.
 *
 * The kit encodes [qrPayload] itself (byte mode UTF-8, error correction M, smallest version,
 * 4-module quiet zone) and draws crisp modules, dark on a light panel in both themes, so any
 * scanner reads it. Without a payload — or with one too long for a QR code — the frame shows
 * "QR code unavailable" instead; the card never draws a look-alike matrix.
 */
@Composable
fun QRCard(
    name: String,
    subtitle: String? = null,
    avatarUrl: String? = null,
    qrPayload: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val symbol = remember(qrPayload) { qrPayload?.takeIf { it.isNotEmpty() }?.let(QrEncoder::encodeText) }
    Column(
        Modifier.width(240.dp)
            .shadow(14.dp, RoundedCornerShape(16.dp), clip = false)
            .clip(RoundedCornerShape(16.dp)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(16.dp)).padding(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Avatar(userId = name, displayName = name, size = 44.dp, avatarUrl = avatarUrl)
            Spacer(Modifier.width(12.dp))
            Column {
                Text(name, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSize2xl.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                subtitle?.let {
                    Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
        val frameShape = RoundedCornerShape(FlareSizes.radiusLg)
        val frame = Modifier.padding(top = 16.dp).fillMaxWidth().aspectRatio(1f).clip(frameShape)
        if (symbol == null) {
            Box(
                frame.background(colors.bgSecondary).border(1.dp, colors.borderPrimary, frameShape).padding(14.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(strings.qrCardUnavailable, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm,
                    textAlign = TextAlign.Center)
            }
        } else {
            // Scanners expect dark modules on a light ground, so the code keeps the light palette
            // whatever the current theme is. The painted quiet zone is the code's margin.
            val light = FlareColors.Light
            val label = "${strings.qrCode}, $name"
            Box(frame.background(light.bgPrimary).border(1.dp, colors.borderPrimary, frameShape)) {
                QrCodeImage(
                    symbol = symbol,
                    color = light.textPrimary,
                    modifier = Modifier.fillMaxSize().semantics {
                        contentDescription = label
                        role = Role.Image
                    },
                )
            }
            Text(strings.scanToAddMe, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm,
                modifier = Modifier.fillMaxWidth().padding(top = FlareSizes.spacingMd),
                textAlign = TextAlign.Center)
        }
    }
}

/**
 * Paints [symbol] centred with its quiet zone, one rectangle per run of dark modules. Modules are
 * whole pixels and start on a whole pixel, so every edge is crisp.
 */
@Composable
private fun QrCodeImage(symbol: QrSymbol, color: Color, modifier: Modifier) {
    Canvas(modifier) {
        val count = symbol.size + 2 * QrEncoder.QUIET_ZONE
        // The whole quiet zone stays on the rounded light panel: a square corner clears a corner
        // arc of radius r once it sits r·(1 − 1/√2) inside.
        val inset = FlareSizes.radiusLg.toPx() * (1 - sqrt(0.5f))
        val side = size.minDimension - 2 * inset
        val whole = floor(side / count)
        val module = if (whole >= 1f) whole else side / count
        val left = floor((size.width - module * count) / 2) + module * QrEncoder.QUIET_ZONE
        val top = floor((size.height - module * count) / 2) + module * QrEncoder.QUIET_ZONE
        for (y in 0 until symbol.size) {
            var x = 0
            while (x < symbol.size) {
                if (!symbol.isDark(x, y)) {
                    x++
                    continue
                }
                val start = x
                while (x < symbol.size && symbol.isDark(x, y)) x++
                drawRect(
                    color = color,
                    topLeft = Offset(left + start * module, top + y * module),
                    size = Size((x - start) * module, module),
                )
            }
        }
    }
}
