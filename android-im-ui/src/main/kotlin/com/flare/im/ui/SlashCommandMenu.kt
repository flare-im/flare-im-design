package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Terminal
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
            Text(flareStrings().commands, color = colors.textTertiary, fontWeight = FontWeight.SemiBold, fontSize = 11.sp)
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
            Text(flareStrings().noMatchingCommands, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                modifier = Modifier.fillMaxWidth().padding(14.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        }
    }
}
