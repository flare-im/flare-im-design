package com.flare.im.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CardGiftcard
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Terminal
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

// MARK: - RedPacketCard

/** Lucky-money red packet card. Spec: Message/RedPacketCard. */
@Composable
fun RedPacketCard(
    blessing: String,
    amount: String? = null,
    opened: Boolean = false,
    finished: Boolean = false,
    onOpen: (() -> Unit)? = null,
) {
    val gold = Color(0xFFFFE9B8)
    Box(
        Modifier.width(248.dp).clip(RoundedCornerShape(14.dp))
            .background(Brush.linearGradient(listOf(Color(0xFFF0503C), Color(0xFFE23B2E), Color(0xFFC8291F))))
            .then(if (!finished && onOpen != null) Modifier.clickable { onOpen() } else Modifier)
            .padding(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(42.dp).clip(CircleShape)
                    .background(Brush.radialGradient(listOf(gold, Color(0xFFF6C453)))),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Outlined.CardGiftcard, contentDescription = null, tint = Color(0xFFC8291F), modifier = Modifier.size(22.dp))
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(blessing, color = Color.White, fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                val status = when {
                    opened && amount != null -> "已领取 · $amount"
                    finished -> "已被领完"
                    else -> "点击领取"
                }
                Text(status, color = if (opened && amount != null) gold else Color(0xFFFFECD2).copy(alpha = 0.85f),
                    fontSize = 12.sp, modifier = Modifier.padding(top = 3.dp))
            }
        }
        Text("闪包", color = Color(0xFFFFECD2).copy(alpha = 0.5f), fontSize = 10.sp,
            modifier = Modifier.align(Alignment.BottomEnd))
    }
}

// MARK: - SlashCommandMenu

/** Composer "/" command menu. Spec: Composer/SlashCommandMenu. */
@Composable
fun SlashCommandMenu(
    commands: List<SlashCommand>,
    query: String = "",
    onSelect: ((SlashCommand) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val q = query.trim().lowercase().removePrefix("/")
    val filtered = commands.filter {
        q.isEmpty() || it.command.lowercase().contains(q) || (it.description?.lowercase()?.contains(q) == true)
    }
    Column(
        Modifier.width(300.dp).heightIn(max = 280.dp).clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl))
            .verticalScroll(rememberScrollState()).padding(6.dp),
    ) {
        Row(
            Modifier.padding(start = 8.dp, end = 8.dp, top = 6.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Terminal, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(13.dp))
            Spacer(Modifier.width(5.dp))
            Text("命令", color = colors.textTertiary, fontWeight = FontWeight.SemiBold, fontSize = 11.sp)
        }
        filtered.forEach { cmd ->
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg))
                    .clickable { onSelect?.invoke(cmd) }.padding(horizontal = 10.dp, vertical = 8.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("/${cmd.command}", color = colors.primary, fontWeight = FontWeight.SemiBold,
                        fontFamily = FontFamily.Monospace, fontSize = 13.sp)
                    cmd.hint?.let {
                        Spacer(Modifier.width(8.dp))
                        Text(it, color = colors.textTertiary, fontFamily = FontFamily.Monospace, fontSize = 12.sp)
                    }
                }
                cmd.description?.let {
                    Text(it, color = colors.textSecondary, fontSize = 12.sp, modifier = Modifier.padding(top = 2.dp))
                }
            }
        }
        if (filtered.isEmpty()) {
            Text("没有匹配的命令", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                modifier = Modifier.fillMaxWidth().padding(14.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        }
    }
}

// MARK: - TranslationView

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
                    Text("翻译中…", color = colors.textTertiary, fontSize = 13.sp)
                }
            } else {
                Text(translated, color = colors.textPrimary, fontSize = 14.sp)
                Row(
                    Modifier.fillMaxWidth().padding(top = 5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Outlined.Translate, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(if (provider != null) "由 $provider 翻译" else "已翻译",
                        color = colors.textTertiary, fontSize = 11.sp)
                    Spacer(Modifier.weight(1f))
                    if (original != null) {
                        Row(
                            Modifier.clickable { showOriginal = !showOriginal },
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(if (showOriginal) "隐藏原文" else "显示原文", color = colors.primary, fontSize = 11.sp)
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

// MARK: - QRCard

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
        Text("扫一扫加我", color = colors.textTertiary, fontSize = 12.sp,
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
