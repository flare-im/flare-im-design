package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material.icons.automirrored.outlined.Message
import androidx.compose.material.icons.outlined.Phone
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
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
 * [ContactDetail]'s labels from [strings] — the `contactDetail*` keys (plus `sendMessage`), which is what
 * [ContactDetail] uses when the host passes none. Without this the data class's own defaults won silently,
 * so a host that had translated the kit through [LocalFlareStrings] still got Chinese here.
 */
fun flareContactDetailLabels(strings: FlareStrings): FlareContactDetailLabels = FlareContactDetailLabels(
    message = strings.sendMessage,
    voice = strings.contactDetailVoice,
    video = strings.contactDetailVideo,
    infoSection = strings.contactDetailInfoSection,
    flareId = strings.contactDetailFlareId,
    remark = strings.contactDetailRemark,
    description = strings.contactDetailDescription,
    star = strings.contactDetailStar,
    notSet = strings.contactDetailNotSet,
    block = strings.contactDetailBlock,
    remove = strings.contactDetailRemove,
)

/** The contact intents the action row can offer, in their order. */
internal enum class ContactDetailAction { Message, Call, Video }

/** The action row's buttons: only the intents the host handles, so a host without calls gets no call buttons. */
internal fun contactDetailActions(handlesMessage: Boolean, handlesCall: Boolean, handlesVideo: Boolean): List<ContactDetailAction> = buildList {
    if (handlesMessage) add(ContactDetailAction.Message)
    if (handlesCall) add(ContactDetailAction.Call)
    if (handlesVideo) add(ContactDetailAction.Video)
}

/** The host's primary action is drawn: a label and a handler. */
internal fun contactDetailHasPrimaryAction(label: String?, handled: Boolean): Boolean = handled && !label.isNullOrBlank()

/** One key of the action row: the host's primary action ([intent] null) or a contact intent, and whether it is the primary key. */
internal data class ContactDetailRowKey(val intent: ContactDetailAction?, val primary: Boolean)

/**
 * The action row in order: the host's primary action first when there is one ([hasPrimary]), then the handled intents.
 * The primary key is the host's action, else Message, which follows it as a secondary key when both are there.
 */
internal fun contactDetailRow(hasPrimary: Boolean, intents: List<ContactDetailAction>): List<ContactDetailRowKey> = buildList {
    if (hasPrimary) add(ContactDetailRowKey(null, primary = true))
    for (intent in intents) add(ContactDetailRowKey(intent, primary = intent == ContactDetailAction.Message && !hasPrimary))
}

/** Whether [key] spins and takes no clicks: only the host's primary action, and only while [primaryActionBusy]. */
internal fun contactDetailKeyBusy(key: ContactDetailRowKey, primaryActionBusy: Boolean): Boolean =
    primaryActionBusy && key.intent == null

/**
 * The 资料 card rows (Vue `FlareContactDetail`): the Flare ID only when the host passes the contact's public handle
 * ([Contact.flareId]; the account id is internal and never shown); 备注 and 描述 are rows that open their editor (with
 * a chevron) when the host edits them, otherwise read-only values shown only when set; 星标好友 only when the host
 * toggles the star.
 */
internal fun contactDetailInfoItems(
    contact: Contact,
    starred: Boolean,
    description: String?,
    labels: FlareContactDetailLabels,
    editsRemark: Boolean,
    editsDescription: Boolean,
    togglesStar: Boolean,
): List<SettingsItem> = buildList {
    contact.flareId?.takeIf { it.isNotBlank() }?.let { handle -> add(SettingsItem("flareId", labels.flareId, icon = "id", kind = FlareSettingKind.Value, detail = handle)) }
    val remark = contact.remark.orEmpty()
    if (editsRemark || remark.isNotEmpty()) {
        add(SettingsItem("remark", labels.remark, icon = "edit", kind = if (editsRemark) FlareSettingKind.Navigation else FlareSettingKind.Value, detail = remark.ifEmpty { labels.notSet }))
    }
    val about = description.orEmpty()
    if (editsDescription || about.isNotEmpty()) {
        add(SettingsItem("description", labels.description, icon = "comment", kind = if (editsDescription) FlareSettingKind.Navigation else FlareSettingKind.Value, detail = about.ifEmpty { labels.notSet }))
    }
    if (togglesStar) add(SettingsItem("star", labels.star, icon = "star", kind = FlareSettingKind.Toggle, value = starred))
}

/**
 * Contact profile — a full presentational card: hero (avatar / name / presence /
 * signature / star chip), an action row (发消息 / 语音 / 视频), a 资料 settings card
 * (Flare ID / 备注 / 描述 / 星标 toggle), and a danger zone (加入黑名单 / 删除好友).
 *
 * An intent appears only when the host handles it: the action row holds only the non-null [onMessage] / [onCall] /
 * [onVideo] and is left out when there are none; 备注 and 描述 open their editor only with [onEditRemark] /
 * [onEditDescription] and otherwise show as read-only values when set; the star switch needs [onToggleStar]; the
 * danger zone holds only [onBlock] / [onRemove] and is left out without both. A stranger's profile, given no
 * friend-only callbacks, shows no friend-only actions.
 *
 * A stranger's page gets its main step from [primaryActionLabel] with [onPrimaryAction] ("Add to contacts"): with both,
 * that key leads the action row as the primary key (person-add), where a friend's page has 发消息, and 发消息, when
 * handled, follows as a secondary key. It is not one of the footer's [extraActions]. While the host runs it,
 * [primaryActionBusy] puts a spinner in place of its icon and takes that key's clicks away; the rest of the page stays
 * usable.
 *
 * Purely presentational — it renders [contact] + [starred] / [description] and emits
 * intents; the host owns edit sheets, confirmations, and persistence. Mirrors the Vue
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
    labels: FlareContactDetailLabels = flareContactDetailLabels(flareStrings()),
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
    /** 宿主自己的操作，画在套件自带的底部按钮里（FR-046）。 */
    extraActions: List<FlareDetailExtraAction> = emptyList(),
    onExtraAction: ((String) -> Unit)? = null,
    /** The page's primary action for someone who is not a contact yet ("Add to contacts"), first in the action row. */
    primaryActionLabel: String? = null,
    onPrimaryAction: (() -> Unit)? = null,
    /** The host is carrying out the primary action: that key spins and takes no clicks; the others stay usable. */
    primaryActionBusy: Boolean = false,
) {
    val colors = flareColors()
    Column(
        modifier.fillMaxWidth().verticalScroll(rememberScrollState()),
    ) {
        // Hero
        Column(
            Modifier.fillMaxWidth().padding(top = FlareSizes.spacing2xl, bottom = FlareSizes.spacing2sm),
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
                // The registry star and the label; the glyph is decoration, the label names the badge.
                Row(
                    Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSelected).padding(horizontal = FlareSizes.spacing2sm, vertical = 2.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                ) {
                    Icon(flareIconVector("star"), contentDescription = null, tint = colors.primaryText, modifier = Modifier.size(13.dp))
                    Text(labels.star, color = colors.primaryText, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                }
            }
        }

        // Actions: only the intents the host handles.
        val row = contactDetailRow(
            hasPrimary = contactDetailHasPrimaryAction(primaryActionLabel, onPrimaryAction != null),
            intents = contactDetailActions(onMessage != null, onCall != null, onVideo != null),
        )
        if (row.isNotEmpty()) Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
        ) {
            row.forEach { key ->
                when (key.intent) {
                    null -> action(primaryActionLabel.orEmpty(), flareIconVector("person-add"), onPrimaryAction ?: {}, colors, Modifier.weight(1f), primary = true, busy = contactDetailKeyBusy(key, primaryActionBusy))
                    ContactDetailAction.Message -> action(labels.message, Icons.AutoMirrored.Outlined.Message, onMessage ?: {}, colors, Modifier.weight(1f), primary = key.primary)
                    ContactDetailAction.Call -> action(labels.voice, Icons.Outlined.Phone, onCall ?: {}, colors, Modifier.weight(1f))
                    ContactDetailAction.Video -> action(labels.video, Icons.Outlined.Videocam, onVideo ?: {}, colors, Modifier.weight(1f))
                }
            }
        }

        // 资料 settings card — left out when there is nothing to show or edit.
        val infoItems = contactDetailInfoItems(
            contact, starred, description, labels,
            editsRemark = onEditRemark != null,
            editsDescription = onEditDescription != null,
            togglesStar = onToggleStar != null,
        )
        if (infoItems.isNotEmpty()) Spacer(Modifier.height(FlareSizes.spacingSm))
        if (infoItems.isNotEmpty()) SettingsList(
            scrollable = false,
            sections = listOf(SettingsSection(title = labels.infoSection, items = infoItems)),
            onSelect = { item ->
                when (item.key) {
                    "remark" -> onEditRemark?.invoke()
                    "description" -> onEditDescription?.invoke()
                }
            },
            onToggle = { item, v -> if (item.key == "star") onToggleStar?.invoke(v) },
        )

        // Danger zone: only the handled intents, and none at all without them.
        if (onBlock != null || onRemove != null || extraActions.isNotEmpty()) Column(
            Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
        ) {
            for (action in extraActions) OutlinedButton(
                onClick = { onExtraAction?.invoke(action.id) },
                shape = RoundedCornerShape(FlareSizes.radiusLg),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = if (action.danger) colors.errorText else colors.textPrimary,
                ),
                modifier = Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget),
            ) { Text(action.label) }
            if (onBlock != null) OutlinedButton(
                onClick = onBlock,
                shape = RoundedCornerShape(FlareSizes.radiusLg),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = colors.textPrimary),
                modifier = Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget),
            ) { Text(labels.block) }
            if (onRemove != null) Button(
                onClick = onRemove,
                shape = RoundedCornerShape(FlareSizes.radiusLg),
                colors = ButtonDefaults.buttonColors(containerColor = colors.error),
                modifier = Modifier.fillMaxWidth().height(48.dp),
            ) { Text(labels.remove, color = Color.White, fontSize = FlareSizes.fontSizeXl.value.sp) }
        }
    }
}

@Composable
private fun action(
    label: String,
    icon: ImageVector,
    onClick: () -> Unit,
    colors: FlareColors,
    modifier: Modifier,
    primary: Boolean = false,
    busy: Boolean = false,
) {
    val container = if (primary) colors.primary else colors.bgSecondary
    val content = if (primary) Color.White else colors.textPrimary
    Button(
        onClick = onClick,
        // The key the host is running keeps its colour (the spinner says why it takes no click), so its disabled
        // colours are its own.
        enabled = !busy,
        colors = ButtonDefaults.buttonColors(
            containerColor = container,
            contentColor = content,
            disabledContainerColor = container,
            disabledContentColor = content,
        ),
        shape = RoundedCornerShape(FlareSizes.radiusLg),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = FlareSizes.spacingXs, vertical = FlareSizes.spacing2sm),
        // Parity with iOS/Flutter: action tiles float — brand-tinted glow on primary, soft neutral on the rest.
        modifier = modifier.shadow(
            if (primary) 10.dp else 6.dp,
            RoundedCornerShape(FlareSizes.radiusLg),
            clip = false,
            ambientColor = if (primary) colors.primary else Color(0xFF151320),
            spotColor = if (primary) colors.primary else Color(0xFF151320),
        ),
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
            if (busy) {
                Box(Modifier.size(FlareSizes.iconSizeLg), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeMd), color = content, strokeWidth = 2.dp)
                }
            } else {
                Icon(icon, null, tint = content)
            }
            Text(label, fontSize = FlareSizes.fontSizeSm.value.sp, color = content)
        }
    }
}
