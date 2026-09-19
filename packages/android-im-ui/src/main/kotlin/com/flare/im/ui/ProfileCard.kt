package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** The card's meta line: the public Flare ID when the host passes one (never the account id) and the region; empty when neither. */
internal fun profileCardMeta(user: Contact): String = buildList {
    user.flareId?.takeIf { it.isNotBlank() }?.let { add("Flare ID · $it") }
    if (!user.region.isNullOrEmpty()) add(user.region)
}.joinToString(" · ")

/** One action tile on the card: the intent it carries out and its name (the message tile's visible label, the voice and video tiles' spoken name). */
internal data class ProfileCardTile(val action: ContactDetailAction, val label: String)

/**
 * The card's action tiles: only the intents the host handles, in order, as on [ContactDetail] — message named by its
 * visible [FlareStrings.sendMessage], then voice and video named by [FlareStrings.contactDetailVoice] and
 * [FlareStrings.contactDetailVideo]. Empty when the host handles none, so the card has no action row.
 */
internal fun profileCardTiles(strings: FlareStrings, handlesMessage: Boolean, handlesCall: Boolean, handlesVideo: Boolean): List<ProfileCardTile> =
    contactDetailActions(handlesMessage, handlesCall, handlesVideo).map { action ->
        val label = when (action) {
            ContactDetailAction.Message -> strings.sendMessage
            ContactDetailAction.Call -> strings.contactDetailVoice
            ContactDetailAction.Video -> strings.contactDetailVideo
        }
        ProfileCardTile(action, label)
    }

/**
 * Mini profile card. Spec: Profile/ProfileCard. The Flare ID shows only when the host passes [Contact.flareId].
 *
 * Message, voice and video appear only when the host handles them ([onMessage] / [onCall] / [onVideo]), with no action
 * row when it handles none. Each tile is a button at least the 48 dp touch target: the message tile shows its label,
 * the voice and video tiles are icons named from [FlareStrings]. Matches Vue, iOS `ProfileCardView` and Flutter
 * `FlareProfileCard`.
 */
@Composable
fun ProfileCard(
    user: Contact,
    onMessage: (() -> Unit)? = null,
    onCall: (() -> Unit)? = null,
    onVideo: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val meta = profileCardMeta(user)
    val tiles = profileCardTiles(strings, onMessage != null, onCall != null, onVideo != null)
    Column(
        Modifier.width(260.dp)
            .shadow(16.dp, RoundedCornerShape(FlareSizes.radiusXl), clip = false)
            .clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl))
            .padding(FlareSizes.spacingLg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Avatar(userId = user.id, displayName = user.name, size = 56.dp, presence = user.presence)
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Text(user.name, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                fontSize = FlareSizes.fontSize2xl.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (!user.signature.isNullOrEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Text(user.signature, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg.value.sp)
        }
        if (meta.isNotEmpty()) {
            Spacer(Modifier.height(FlareSizes.spacingSm))
            Text(meta, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (user.tags.isNotEmpty()) {
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                user.tags.forEach { t ->
                    Text(t, color = colors.primaryText, fontSize = FlareSizes.fontSizeXs.value.sp,
                        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(colors.bgSelected)
                            .padding(horizontal = 9.dp, vertical = 2.dp))
                }
            }
        }
        if (tiles.isNotEmpty()) {
            // The touch targets add their own margin above the visible tiles.
            Spacer(Modifier.height(FlareSizes.spacingMd))
            Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm), verticalAlignment = Alignment.CenterVertically) {
                tiles.forEach { tile ->
                    when (tile.action) {
                        ContactDetailAction.Message -> messageTile(colors, tile.label, onMessage ?: {}, Modifier.weight(1f))
                        ContactDetailAction.Call -> iconTile(colors, Icons.Outlined.Call, tile.label, onCall ?: {})
                        ContactDetailAction.Video -> iconTile(colors, Icons.Outlined.Videocam, tile.label, onVideo ?: {})
                    }
                }
            }
        }
    }
}

/** The visible tile: 38 dp tall (an icon tile 44 dp wide) around a 17 dp glyph; the control around it is the touch target. */
private val TileHeight = 38.dp
private val TileGlyph = 17.dp

/** The message tile: a button named by its visible [label], at least the touch target tall around the tile. */
@Composable
private fun messageTile(colors: FlareColors, label: String, onClick: () -> Unit, modifier: Modifier) {
    Box(
        modifier
            .heightIn(min = FlareSizes.touchTarget)
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .clickable(role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Row(
            Modifier.fillMaxWidth().height(TileHeight)
                .clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(colors.primary)
                .padding(horizontal = 10.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.ChatBubbleOutline, contentDescription = null, tint = Color.White, modifier = Modifier.size(TileGlyph))
            Spacer(Modifier.width(FlareSizes.spacing2xs))
            Text(label, color = Color.White, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeLg.value.sp,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

/** A voice or video tile: an icon button named [label], its tile drawn inside the kit's 48 dp icon control. */
@Composable
private fun iconTile(colors: FlareColors, icon: ImageVector, label: String, onClick: () -> Unit) {
    FlareIconControl(label = label, onClick = onClick, shape = RoundedCornerShape(FlareSizes.radiusLg)) {
        Box(
            Modifier.size(width = 44.dp, height = TileHeight)
                .clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(colors.bgSecondary),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = colors.textPrimary, modifier = Modifier.size(TileGlyph))
        }
    }
}

