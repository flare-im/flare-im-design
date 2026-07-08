package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Settings list — grouped toggle / navigation / value rows. A generic settings
 * container. Spec: Profile/SettingsList (`SettingsList`).
 */
@Composable
fun SettingsList(
    sections: List<SettingsSection>,
    onToggle: ((SettingsItem, Boolean) -> Unit)? = null,
    onSelect: ((SettingsItem) -> Unit)? = null,
) {
    val colors = flareColors()
    LazyColumn(Modifier.fillMaxWidth()) {
        sections.forEach { section ->
            if (!section.title.isNullOrEmpty()) {
                item(key = "t-${section.title}") {
                    Text(section.title, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        modifier = Modifier.padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm))
                }
            }
            section.items.forEachIndexed { i, it ->
                item(key = it.key) {
                    if (i > 0) Divider(color = colors.borderSecondary, modifier = Modifier.padding(start = FlareSizes.spacingMd))
                    Row(
                        Modifier.fillMaxWidth()
                            .then(if (it.kind != FlareSettingKind.Toggle) Modifier.clickable { onSelect?.invoke(it) } else Modifier)
                            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingMd),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        it.icon?.let { ic -> Icon(ic, null, tint = colors.textSecondary); Spacer(Modifier.width(FlareSizes.spacingMd)) }
                        Text(it.label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.weight(1f))
                        when (it.kind) {
                            FlareSettingKind.Toggle -> Switch(checked = it.value, onCheckedChange = { v -> onToggle?.invoke(it, v) })
                            FlareSettingKind.Value -> Text(it.detail ?: "", color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp)
                            FlareSettingKind.Navigation -> {
                                it.detail?.let { d -> Text(d, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp); Spacer(Modifier.width(6.dp)) }
                                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}
