package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Message
import androidx.compose.material.icons.outlined.Phone
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Chinese-default labels for [ContactDetail] (kit convention: labels passed as params). */
data class FlareContactDetailLabels(
    val message: String = "发消息",
    val voice: String = "语音通话",
    val video: String = "视频通话",
    val infoSection: String = "资料",
    val flareId: String = "Flare ID",
    val remark: String = "备注",
    val description: String = "描述",
    val star: String = "星标好友",
    val notSet: String = "未设置",
    val block: String = "加入黑名单",
    val remove: String = "删除好友",
)

/**
 * Contact profile — a full presentational card: hero (avatar / name / presence /
 * signature / star chip), a 3-up action row (发消息 / 语音 / 视频), a 资料 settings card
 * (Flare ID / 备注 / 描述 / 星标 toggle), and a danger zone (加入黑名单 / 删除好友).
 *
 * Purely presentational — it renders [contact] + [starred] / [description] and emits
 * intents; the host owns the edit sheets / confirms and the SDK writes. Mirrors the Vue
 * kit's `FlareContactDetail.vue`. Spec: Contacts/ContactDetail.
 */
@Composable
fun ContactDetail(
    contact: Contact,
    modifier: Modifier = Modifier,
    /** Whether the viewer has starred (favorited) this contact. */
    starred: Boolean = false,
    /** Free-text description the viewer set for this contact. */
    description: String? = null,
    labels: FlareContactDetailLabels = FlareContactDetailLabels(),
    onMessage: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
    onVideo: (() -> Unit)? = null,
    /** Edit the remark (备注). */
    onEditRemark: (() -> Unit)? = null,
    /** Edit the description (描述). */
    onEditDescription: (() -> Unit)? = null,
    onToggleStar: ((Boolean) -> Unit)? = null,
    onBlock: (() -> Unit)? = null,
    onRemove: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Column(
        modifier.fillMaxWidth().verticalScroll(rememberScrollState()),
    ) {
        // Hero
        Column(
            Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2xl, bottom = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Avatar(userId = contact.id, displayName = contact.name, size = 76.dp, presence = contact.presence)
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Text(contact.name, color = colors.textPrimary, fontSize = FlareSizes.fontSize4xl.value.sp, fontWeight = FontWeight.Bold)
            if (!contact.signature.isNullOrEmpty()) {
                Spacer(Modifier.height(FlareSizes.spacingXs))
                Text(contact.signature, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
            }
            if (starred) {
                Spacer(Modifier.height(FlareSizes.spacingSm))
                Text(
                    "★ ${labels.star}", color = colors.primary, fontWeight = FontWeight.SemiBold, fontSize = 12.sp,
                    modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSelected).padding(horizontal = 10.dp, vertical = 2.dp),
                )
            }
        }

        // 3-up actions
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            action(labels.message, Icons.Outlined.Message, onMessage, colors, Modifier.weight(1f), primary = true)
            action(labels.voice, Icons.Outlined.Phone, onCall, colors, Modifier.weight(1f))
            action(labels.video, Icons.Outlined.Videocam, onVideo, colors, Modifier.weight(1f))
        }

        // 资料 settings card
        Spacer(Modifier.height(FlareSizes.spacingSm))
        SettingsList(
            sections = listOf(
                SettingsSection(
                    title = labels.infoSection,
                    items = listOf(
                        SettingsItem("flareId", labels.flareId, kind = FlareSettingKind.Value, detail = contact.id),
                        SettingsItem("remark", labels.remark, kind = FlareSettingKind.Navigation, detail = contact.remark?.ifEmpty { null } ?: labels.notSet),
                        SettingsItem("description", labels.description, kind = FlareSettingKind.Navigation, detail = description?.ifEmpty { null } ?: labels.notSet),
                        SettingsItem("star", labels.star, kind = FlareSettingKind.Toggle, value = starred),
                    ),
                ),
            ),
            onSelect = { item ->
                when (item.key) {
                    "remark" -> onEditRemark?.invoke()
                    "description" -> onEditDescription?.invoke()
                }
            },
            onToggle = { item, v -> if (item.key == "star") onToggleStar?.invoke(v) },
        )

        // Danger zone
        Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            OutlinedButton(
                onClick = { onBlock?.invoke() },
                shape = RoundedCornerShape(FlareSizes.radiusLg),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary),
                modifier = Modifier.fillMaxWidth(),
            ) { Text(labels.block) }
            Button(
                onClick = { onRemove?.invoke() },
                shape = RoundedCornerShape(FlareSizes.radiusLg),
                colors = ButtonDefaults.buttonColors(containerColor = colors.error),
                modifier = Modifier.fillMaxWidth().height(48.dp),
            ) { Text(labels.remove, color = Color.White, fontSize = FlareSizes.fontSizeXl.value.sp) }
        }
    }
}

@Composable
private fun action(label: String, icon: ImageVector, onClick: (() -> Unit)?, colors: FlareColors, modifier: Modifier, primary: Boolean = false) {
    Button(
        onClick = { onClick?.invoke() },
        colors = if (primary) ButtonDefaults.buttonColors(containerColor = colors.primary)
        else ButtonDefaults.buttonColors(containerColor = colors.bgSecondary, contentColor = colors.textPrimary),
        shape = RoundedCornerShape(FlareSizes.radiusLg),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 4.dp, vertical = 10.dp),
        modifier = modifier,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Icon(icon, null, tint = if (primary) Color.White else colors.textPrimary)
            Text(label, fontSize = FlareSizes.fontSizeSm.value.sp, color = if (primary) Color.White else colors.textPrimary)
        }
    }
}
