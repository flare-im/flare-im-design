package com.flare.im.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

/** What the editor holds while it is open: the host keeps it to survive leaving the page (`FlareProfileDraft`). */
data class FlareProfileDraft(val name: String, val signature: String) : java.io.Serializable

/**
 * Profile editor — the avatar card, the nickname (24) and signature (60) fields with their counters, and the
 * actions row: 未保存修改 while something changed, then cancel and save. Spec: Profile/ProfileEditor (`ProfileEditor`).
 *
 * Parity with `FlareProfileEditor.vue`: the avatar card (48 + 「更换头像」 + camera) is one button that asks the host to
 * pick a picture ([onPickAvatar]); save is off while the name is blank, nothing changed or the host is [busy]; Enter
 * in the nickname saves. With [draft] and [onDraftChange] the host keeps the typing across navigation; a new [user]
 * id starts over from that user and drops the draft.
 */
@Composable
fun ProfileEditor(
    user: UserProfile,
    /** Field / button labels — overridable so hosts can localize them. */
    labels: FlareProfileEditorLabels = FlareProfileEditorLabels.from(flareStrings()),
    busy: Boolean = false,
    /** The host's kept draft; null starts from [user]. */
    draft: FlareProfileDraft? = null,
    onDraftChange: ((FlareProfileDraft?) -> Unit)? = null,
    onSave: ((name: String, signature: String) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
    onPickAvatar: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val initial = FlareProfileDraft(user.name, user.signature ?: "")
    var value by remember(user.id) { mutableStateOf(draft ?: initial) }
    LaunchedEffect(draft) { if (draft != null && draft != value) value = draft }
    var seenUser by remember { mutableStateOf(user.id) }
    LaunchedEffect(user.id) {
        if (seenUser != user.id) { seenUser = user.id; value = initial; onDraftChange?.invoke(null) }
    }
    fun update(next: FlareProfileDraft) { value = next; onDraftChange?.invoke(next) }
    val dirty = value.name != user.name || value.signature != (user.signature ?: "")
    val canSave = !busy && value.name.isNotBlank() && dirty
    val save = { if (canSave) onSave?.invoke(value.name, value.signature) }

    Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingMd), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        val shape = RoundedCornerShape(FlareSizes.radiusLg)
        Row(
            Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).clip(shape)
                .clickable(enabled = !busy && onPickAvatar != null, role = Role.Button) { onPickAvatar?.invoke() }
                .semantics(mergeDescendants = true) { contentDescription = strings.changeAvatar }
                .padding(FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(userId = user.id, displayName = value.name.ifEmpty { user.name }, avatarUrl = user.avatarUrl, size = 48.dp)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Text(strings.changeAvatar, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.weight(1f))
            FlareIcon("camera", size = FlareSizes.iconSizeMd, tint = colors.textSecondary)
        }
        FormField(label = labels.nickname, counter = "${value.name.length}/$NICKNAME_MAX") {
            Input(value = value.name, onValueChange = { update(value.copy(name = it)) }, placeholder = labels.nicknamePlaceholder,
                maxLength = NICKNAME_MAX, clearable = true, disabled = busy, onSubmit = save)
        }
        FormField(label = labels.bio, counter = "${value.signature.length}/$SIGNATURE_MAX") {
            Input(value = value.signature, onValueChange = { update(value.copy(signature = it)) }, placeholder = labels.bioPlaceholder,
                multiline = true, maxLength = SIGNATURE_MAX, disabled = busy)
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically) {
            if (dirty) Text(labels.unsaved, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
            Box(Modifier.weight(1f)) {
                Button(label = labels.cancel, variant = FlareButtonVariant.Secondary, size = FlareControlSize.Sm, block = true,
                    disabled = busy, onClick = { onCancel?.invoke() })
            }
            Box(Modifier.weight(1f)) {
                Button(label = labels.save, size = FlareControlSize.Sm, block = true, loading = busy, disabled = !canSave, onClick = save)
            }
        }
    }
}

private const val NICKNAME_MAX = 24
private const val SIGNATURE_MAX = 60

/** Localizable labels for [ProfileEditor]. Defaults keep today's English copy. */
data class FlareProfileEditorLabels(
    val nickname: String = FlareStrings().profileEditorNickname,
    val nicknamePlaceholder: String = FlareStrings().profileEditorNicknamePlaceholder,
    val bio: String = FlareStrings().profileEditorBio,
    val bioPlaceholder: String = FlareStrings().profileEditorBioPlaceholder,
    val cancel: String = FlareStrings().cancel,
    val save: String = FlareStrings().profileEditorSave,
    val unsaved: String = FlareStrings().profileEditorUnsaved,
) {
    companion object {
        fun from(strings: FlareStrings) = FlareProfileEditorLabels(
            strings.profileEditorNickname, strings.profileEditorNicknamePlaceholder,
            strings.profileEditorBio, strings.profileEditorBioPlaceholder, strings.cancel, strings.profileEditorSave,
            strings.profileEditorUnsaved,
        )
    }
}
