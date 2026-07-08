package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Directory row — avatar, name, signature/department, presence.
 * Spec: Contacts/ContactItem (`ContactItem`).
 */
@Composable
fun ContactItem(
    item: Contact,
    showPresence: Boolean = true,
    onSelect: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth()
            .then(if (onSelect != null) Modifier.clickable { onSelect() } else Modifier)
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Avatar(userId = item.id, displayName = item.name, size = 40.dp,
            presence = if (showPresence) item.presence else null)
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Column {
            Text(item.name, color = colors.textPrimary, fontWeight = FontWeight.Medium,
                fontSize = FlareSizes.fontSizeXl.value.sp)
            if (!item.signature.isNullOrEmpty()) {
                Text(item.signature, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

internal fun contactLetter(c: Contact): String {
    val k = (c.indexKey ?: c.name.trim().firstOrNull()?.toString() ?: "#").uppercase()
    return if (k.isNotEmpty() && k[0] in 'A'..'Z') k[0].toString() else "#"
}
