package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.FlashOn
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Quick phrases / canned replies picker. Spec: Composer/QuickPhrases. */
@Composable
fun QuickPhrases(
    groups: List<QuickPhraseGroup>,
    manageable: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    onManage: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var activeKey by remember { mutableStateOf(groups.firstOrNull()?.key ?: "") }
    val active = groups.firstOrNull { it.key == activeKey } ?: groups.firstOrNull()
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    Column(
        Modifier.width(320.dp)
            .clip(shape)
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, shape),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.FlashOn, contentDescription = null, tint = colors.primary, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                flareStrings().quickPhrases,
                color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSizeXl.value.sp,
                modifier = Modifier.weight(1f),
            )
            if (manageable) {
                Row(
                    Modifier.then(if (onManage != null) Modifier.clickable { onManage() } else Modifier),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(flareStrings().manage, color = colors.primary, fontSize = FlareSizes.fontSizeMd.value.sp, fontWeight = FontWeight.Medium)
                    Icon(Icons.Outlined.Edit, contentDescription = null, tint = colors.primary, modifier = Modifier.size(14.dp))
                }
            }
        }
        if (groups.size > 1) {
            Row(
                Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = FlareSizes.spacingLg),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                groups.forEach { g ->
                    val sel = g.key == active?.key
                    Text(
                        g.title,
                        color = if (sel) colors.primary else colors.textSecondary,
                        fontWeight = if (sel) FontWeight.Medium else FontWeight.Normal,
                        fontSize = FlareSizes.fontSizeMd.value.sp,
                        modifier = Modifier.clip(RoundedCornerShape(999.dp))
                            .background(if (sel) colors.bgSelected else colors.bgSecondary)
                            .clickable { activeKey = g.key }
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                    )
                }
            }
            Spacer(Modifier.height(8.dp))
        }
        Column(
            Modifier.fillMaxWidth().heightIn(max = 280.dp).verticalScroll(rememberScrollState())
                .padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, bottom = FlareSizes.spacingMd),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            active?.phrases?.forEach { p ->
                Text(
                    p.text,
                    color = colors.textPrimary,
                    fontSize = 14.sp,
                    modifier = Modifier.fillMaxWidth()
                        .clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(colors.bgSecondary)
                        .then(if (onSelect != null) Modifier.clickable { onSelect(p.text) } else Modifier)
                        .padding(horizontal = 12.dp, vertical = 10.dp),
                )
            }
        }
    }
}
