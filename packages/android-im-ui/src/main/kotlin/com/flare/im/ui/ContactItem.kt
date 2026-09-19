package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Directory row — avatar, name, signature/department, presence.
 * Spec: Contacts/ContactItem (`ContactItem`).
 *
 * [selectable] adds a leading checkbox showing [selected]: tapping the row then runs
 * [onToggleSelect] (never [onSelect]) and the row reads as one checkbox named by the
 * contact. [trailing] sits at the row end; controls in it keep their own focus and taps.
 */
@Composable
fun ContactItem(
    item: Contact,
    showPresence: Boolean = true,
    onSelect: (() -> Unit)? = null,
    selectable: Boolean = false,
    selected: Boolean = false,
    onToggleSelect: (() -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth()
            .then(
                when {
                    selectable -> Modifier
                        .toggleable(value = selected, enabled = onToggleSelect != null, role = Role.Checkbox) { onToggleSelect?.invoke() }
                        .semantics { contentDescription = item.name }
                    onSelect != null -> Modifier.clickable { onSelect() }
                    else -> Modifier
                },
            )
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (selectable) {
            // Only the picture of the row's state: the row itself is the checkbox.
            Box(Modifier.clearAndSetSemantics {}) { Checkbox(value = selected) }
            Spacer(Modifier.width(FlareSizes.spacingMd))
        }
        Avatar(userId = item.id, displayName = item.name, size = 40.dp,
            presence = if (showPresence) item.presence else null)
        Spacer(Modifier.width(FlareSizes.spacingMd))
        Column(Modifier.weight(1f)) {
            Text(item.name, color = colors.textPrimary, fontWeight = FontWeight.Medium,
                fontSize = FlareSizes.fontSizeLg.value.sp)
            if (!item.signature.isNullOrEmpty()) {
                Text(item.signature, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        if (trailing != null) {
            Spacer(Modifier.width(FlareSizes.spacingSm))
            trailing()
        }
    }
}
