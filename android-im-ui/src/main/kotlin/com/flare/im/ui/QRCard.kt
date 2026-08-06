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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

/** Scannable name card. Spec: Profile/QRCard. */
@Composable
fun QRCard(
    name: String,
    subtitle: String? = null,
    avatarUrl: String? = null,
    qrImageUrl: String? = null,
) {
    val colors = flareColors()
    val qrColor = colors.textPrimary
    Column(
        Modifier.width(240.dp).clip(RoundedCornerShape(16.dp)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(16.dp)).padding(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Avatar(userId = name, displayName = name, size = 44.dp)
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
        Box(
            Modifier.padding(top = 16.dp).fillMaxWidth().aspectRatio(1f)
                .clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary)
                .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg)).padding(14.dp),
            contentAlignment = Alignment.Center,
        ) {
            if (qrImageUrl != null) {
                AsyncImage(model = qrImageUrl, contentDescription = null,
                    modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
            } else {
                QrMatrix(name = name, color = qrColor, modifier = Modifier.fillMaxSize())
            }
        }
        Text(flareStrings().scanToAddMe, color = colors.textTertiary, fontSize = 12.sp,
            modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center)
    }
}

/** Deterministic decorative QR-like matrix (NOT a scannable code). */
@Composable
private fun QrMatrix(name: String, color: Color, modifier: Modifier = Modifier) {
    val seed = name.sumOf { it.code } + 7
    Canvas(modifier) {
        val n = 11
        val cell = size.minDimension / n
        for (y in 0 until n) {
            for (x in 0 until n) {
                val corner = (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7)
                if (corner) continue
                if ((x * 31 + y * 17 + seed) % 5 == 0) {
                    drawRoundRect(
                        color = color,
                        topLeft = Offset((x + 0.12f) * cell, (y + 0.12f) * cell),
                        size = Size(0.76f * cell, 0.76f * cell),
                        cornerRadius = CornerRadius(0.16f * cell),
                    )
                }
            }
        }
        val finders = listOf(Offset(0.3f, 0.3f), Offset((n - 2.7f), 0.3f), Offset(0.3f, (n - 2.7f)))
        val inners = listOf(Offset(1.1f, 1.1f), Offset((n - 1.9f), 1.1f), Offset(1.1f, (n - 1.9f)))
        finders.forEach { p ->
            drawRoundRect(
                color = color,
                topLeft = Offset(p.x * cell, p.y * cell),
                size = Size(2.4f * cell, 2.4f * cell),
                cornerRadius = CornerRadius(0.5f * cell),
                style = Stroke(width = 0.6f * cell),
            )
        }
        inners.forEach { p ->
            drawRoundRect(
                color = color,
                topLeft = Offset(p.x * cell, p.y * cell),
                size = Size(0.8f * cell, 0.8f * cell),
                cornerRadius = CornerRadius(0.2f * cell),
            )
        }
    }
}
