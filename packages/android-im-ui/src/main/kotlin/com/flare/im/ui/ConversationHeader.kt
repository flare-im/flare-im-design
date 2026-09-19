package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

enum class ConversationHeaderKind { Direct, Group, Channel, Bot, System }

enum class ConversationHeaderActionPlacement { Primary, Add, Overflow }

data class ConversationIdentity(
    val id: String,
    val title: String,
    val kind: ConversationHeaderKind = ConversationHeaderKind.Direct,
    val subtitle: String? = null,
    val avatarUrl: String? = null,
    val presence: FlarePresence? = null,
    val memberCount: Int? = null,
    val typingText: String? = null,
    val accessibilityLabel: String? = null,
    /**
     * Makes the whole identity block (avatar, title, subtitle) one button — typically
     * "details". Filtered like the header actions; a hidden or disabled action leaves the
     * block plain. Its accessible label is the action's own, else "{title}, {label}".
     */
    val action: ConversationHeaderAction? = null,
)

data class ConversationHeaderAction(
    val id: String,
    val label: String,
    val icon: String? = null,
    val placement: ConversationHeaderActionPlacement = ConversationHeaderActionPlacement.Primary,
    val group: String? = null,
    val order: Int? = null,
    val visible: Boolean = true,
    val enabled: Boolean = true,
    val badge: String? = null,
    val intent: String? = null,
    val capability: String? = null,
    val accessibilityLabel: String? = null,
    val disabledReason: String? = null,
    /** Non-null makes the action a toggle: selected look and on/off state while true / false. */
    val pressed: Boolean? = null,
)

data class ConversationHeaderCapabilities(val availableActionIds: Set<String>? = null)

data class ConversationHeaderConfiguration(
    val replaceDefaults: Boolean = false,
    val removeActionIds: Set<String> = emptySet(),
    val actionOverrides: List<ConversationHeaderAction> = emptyList(),
    val maxPrimaryActions: Int = 3,
    val compactMaxPrimaryActions: Int = 1,
)

val DefaultDirectConversationHeaderConfig = ConversationHeaderConfiguration()
val DefaultGroupConversationHeaderConfig = ConversationHeaderConfiguration()

private val directHeaderActions = listOf(
    ConversationHeaderAction("search", "Search messages", "search", order = 10),
    ConversationHeaderAction("audioCall", "Start audio call", "phone", order = 20, capability = "audioCall"),
    ConversationHeaderAction("videoCall", "Start video call", "video", order = 30, capability = "videoCall"),
    ConversationHeaderAction("share", "Share contact", "share", ConversationHeaderActionPlacement.Add, order = 40),
    ConversationHeaderAction("details", "Conversation details", "info", ConversationHeaderActionPlacement.Overflow, order = 90),
)

private val groupHeaderActions = listOf(
    ConversationHeaderAction("search", "Search messages", "search", order = 10),
    ConversationHeaderAction("audioCall", "Start audio call", "phone", order = 20, capability = "audioCall"),
    ConversationHeaderAction("videoCall", "Start video call", "video", order = 30, capability = "videoCall"),
    ConversationHeaderAction("addMember", "Add member", "person-add", ConversationHeaderActionPlacement.Add, order = 40),
    ConversationHeaderAction("share", "Share conversation", "share", ConversationHeaderActionPlacement.Add, order = 50),
    ConversationHeaderAction("details", "Conversation details", "info", ConversationHeaderActionPlacement.Overflow, order = 90),
)

fun resolveConversationHeaderActions(
    identity: ConversationIdentity,
    capabilities: ConversationHeaderCapabilities? = null,
    configuration: ConversationHeaderConfiguration = ConversationHeaderConfiguration(),
    actions: List<ConversationHeaderAction> = emptyList(),
): List<ConversationHeaderAction> {
    val defaults = if (identity.kind == ConversationHeaderKind.Group || identity.kind == ConversationHeaderKind.Channel) {
        groupHeaderActions
    } else {
        directHeaderActions
    }
    val byId = linkedMapOf<String, ConversationHeaderAction>()
    if (!configuration.replaceDefaults) defaults.forEach { byId[it.id] = it }
    (configuration.actionOverrides + actions).forEach { byId[it.id] = it }
    return byId.values
        .filter { action ->
            action.visible && action.id !in configuration.removeActionIds &&
                (capabilities?.availableActionIds == null || (action.capability ?: action.id) in capabilities.availableActionIds)
        }
        .sortedBy { it.order ?: 0 }
}

/**
 * The identity action that turns the identity block into a button: null when there is none,
 * when it is hidden or disabled, removed or not among the capabilities, or nothing handles it.
 */
internal fun resolveConversationIdentityAction(
    identity: ConversationIdentity,
    capabilities: ConversationHeaderCapabilities?,
    configuration: ConversationHeaderConfiguration,
    hasOnAction: Boolean,
): ConversationHeaderAction? = identity.action?.takeIf { action ->
    hasOnAction && action.visible && action.enabled && action.id !in configuration.removeActionIds &&
        (capabilities?.availableActionIds == null || (action.capability ?: action.id) in capabilities.availableActionIds)
}

/**
 * The words a header action shows (Vue `localizedLabel`): a default action still carrying the English default label
 * of this conversation's [kind] speaks the strings table; a host label, or a default id whose label the host changed,
 * shows as given.
 */
internal fun conversationHeaderActionLabel(action: ConversationHeaderAction, kind: ConversationHeaderKind, strings: FlareStrings): String {
    val defaults = if (kind == ConversationHeaderKind.Group || kind == ConversationHeaderKind.Channel) groupHeaderActions else directHeaderActions
    if (defaults.none { it.id == action.id && it.label == action.label }) return action.label
    return when (action.id) {
        "search" -> strings.conversationHeaderSearch
        "audioCall" -> strings.conversationHeaderAudioCall
        "videoCall" -> strings.conversationHeaderVideoCall
        "addMember" -> strings.conversationHeaderAddMember
        "share" -> strings.conversationHeaderShare
        "details" -> strings.conversationHeaderDetails
        else -> action.label
    }
}

/**
 * The line under the title: the typing text, else the host subtitle, else a group's or channel's member count, else
 * the presence in words; empty when there is none. A direct conversation shows no member count (Vue).
 */
internal fun conversationHeaderSubtitle(identity: ConversationIdentity, strings: FlareStrings): String {
    identity.typingText?.takeIf { it.isNotBlank() }?.let { return it }
    identity.subtitle?.takeIf { it.isNotBlank() }?.let { return it }
    val grouped = identity.kind == ConversationHeaderKind.Group || identity.kind == ConversationHeaderKind.Channel
    identity.memberCount?.takeIf { grouped }?.let { return strings.conversationHeaderMemberCount(it) }
    return when (identity.presence) {
        FlarePresence.Online -> strings.presenceOnline
        FlarePresence.Offline -> strings.presenceOffline
        FlarePresence.Busy -> strings.presenceBusy
        FlarePresence.Away -> strings.presenceAway
        null -> ""
    }
}

/** Where the resolved actions sit: buttons, the Add menu, and the More menu (primary actions past the limit, then overflow ones). */
internal data class ConversationHeaderLayout(
    val primary: List<ConversationHeaderAction>,
    val add: List<ConversationHeaderAction>,
    val overflow: List<ConversationHeaderAction>,
) {
    /**
     * The overflow action that takes the More button itself: a More menu holding one action is a detour, so when
     * exactly one action overflows the button performs it (Vue `soleOverflowAction`). Two or more keep the menu.
     */
    val soleOverflow: ConversationHeaderAction? get() = overflow.singleOrNull()
}

internal fun conversationHeaderLayout(resolved: List<ConversationHeaderAction>, maxPrimary: Int): ConversationHeaderLayout {
    val primaryCandidates = resolved.filter { it.placement == ConversationHeaderActionPlacement.Primary }
    return ConversationHeaderLayout(
        primary = primaryCandidates.take(maxPrimary),
        add = resolved.filter { it.placement == ConversationHeaderActionPlacement.Add },
        overflow = primaryCandidates.drop(maxPrimary) + resolved.filter { it.placement == ConversationHeaderActionPlacement.Overflow },
    )
}

/**
 * Opinionated conversation identity plus capability-aware host actions. Actions past the primary limit go to
 * the More menu; when only one action overflows, the More button (still drawn with the `more` glyph) performs it
 * and is named by it. Default actions, the member count and the presence speak the strings table
 * ([conversationHeaderActionLabel], [conversationHeaderSubtitle]); host labels show as given.
 */
@Composable
fun ConversationHeader(
    identity: ConversationIdentity,
    capabilities: ConversationHeaderCapabilities? = null,
    configuration: ConversationHeaderConfiguration = ConversationHeaderConfiguration(),
    actions: List<ConversationHeaderAction> = emptyList(),
    showBack: Boolean = false,
    onBack: (() -> Unit)? = null,
    onAction: ((ConversationHeaderAction) -> Unit)? = null,
    identityContent: (@Composable (ConversationIdentity) -> Unit)? = null,
    /** Draws the glyph of a primary action button; the add and more menus draw each action's `icon` name. */
    actionIcon: (@Composable (ConversationHeaderAction) -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
) {
    val colors = flareColors()
    FlareNativeBackEffect(enabled = showBack && onBack != null) { onBack?.invoke() }
    val resolved = resolveConversationHeaderActions(identity, capabilities, configuration, actions)
    val identityAction = resolveConversationIdentityAction(identity, capabilities, configuration, hasOnAction = onAction != null)
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val compact = maxWidth < 560.dp
        val maxPrimary = if (compact) configuration.compactMaxPrimaryActions else configuration.maxPrimaryActions
        val layout = conversationHeaderLayout(resolved, maxPrimary)

        Row(
            Modifier.fillMaxWidth().height(FlareSizes.headerHeight).background(colors.bgPrimary)
                .padding(horizontal = if (compact) FlareSizes.spacingSm else FlareSizes.spacingLg)
                .semantics { contentDescription = identity.accessibilityLabel ?: identity.title },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (showBack) {
                IconButton(onClick = { onBack?.invoke() }, enabled = onBack != null) {
                    Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = flareStrings().back, modifier = Modifier.size(22.dp))
                }
            }
            val strings = flareStrings()
            val labelOf = { action: ConversationHeaderAction -> conversationHeaderActionLabel(action, identity.kind, strings) }
            Box(Modifier.weight(1f)) {
                IdentityTarget(identity, identityAction, identityAction?.let(labelOf).orEmpty(), onAction, colors) {
                    if (identityContent != null) identityContent(identity)
                    else HeaderIdentity(identity, compact, colors)
                }
            }
            layout.primary.forEach { HeaderActionButton(it, labelOf(it), onAction, actionIcon, colors) }
            if (layout.add.isNotEmpty()) HeaderActionMenu(layout.add, labelOf, Icons.Rounded.Add, strings.conversationHeaderAddActions, onAction, colors)
            val sole = layout.soleOverflow
            if (sole != null) HeaderActionButton(sole, labelOf(sole), onAction, actionIcon = null, colors, glyph = Icons.Rounded.MoreHoriz)
            else if (layout.overflow.isNotEmpty()) HeaderActionMenu(layout.overflow, labelOf, Icons.Rounded.MoreHoriz, strings.conversationHeaderMoreActions, onAction, colors)
            trailing?.invoke(this)
        }
        HorizontalDivider(Modifier.align(Alignment.BottomCenter), color = colors.borderPrimary)
    }
}

/**
 * The identity block, as one button when [action] survived filtering: pressed and
 * keyboard focus show the hover background; the back button and actions stay separate.
 */
@Composable
private fun IdentityTarget(
    identity: ConversationIdentity,
    action: ConversationHeaderAction?,
    actionLabel: String,
    onAction: ((ConversationHeaderAction) -> Unit)?,
    colors: FlareColors,
    content: @Composable () -> Unit,
) {
    if (action == null) {
        content()
        return
    }
    val label = action.accessibilityLabel ?: flareStrings().conversationHeaderIdentityLabel(identity.title, actionLabel)
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val focused by interaction.collectIsFocusedAsState()
    Box(
        Modifier.heightIn(min = FlareSizes.touchTarget)
            .clip(RoundedCornerShape(FlareSizes.radiusMd))
            .background(if (pressed || focused) colors.bgHover else Color.Transparent)
            .clickable(interactionSource = interaction, indication = null, role = Role.Button) { onAction?.invoke(action) }
            .semantics { contentDescription = label }
            .padding(horizontal = FlareSizes.spacingXs),
        contentAlignment = Alignment.CenterStart,
    ) { content() }
}

@Composable
private fun HeaderIdentity(
    identity: ConversationIdentity,
    compact: Boolean,
    colors: FlareColors,
) {
    val subtitle = conversationHeaderSubtitle(identity, flareStrings())
    Row(verticalAlignment = Alignment.CenterVertically) {
        Avatar(
            userId = identity.id,
            displayName = identity.title,
            presence = identity.presence,
            size = if (compact) 36.dp else 40.dp,
            image = identity.avatarUrl?.let { url ->
                { AsyncImage(model = url, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop) }
            },
        )
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Column {
            Text(identity.title, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl.value.sp,
                fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (subtitle.isNotEmpty()) Text(subtitle,
                color = if (identity.presence == FlarePresence.Online) colors.successText else colors.textTertiary,
                fontSize = FlareSizes.fontSizeSm.value.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

/**
 * One header action as an icon button named [label] (its [ConversationHeaderAction.accessibilityLabel] wins); [glyph]
 * replaces the action's own icon (the More button performing its only action).
 */
@Composable
private fun HeaderActionButton(
    action: ConversationHeaderAction,
    label: String,
    onAction: ((ConversationHeaderAction) -> Unit)?,
    actionIcon: (@Composable (ConversationHeaderAction) -> Unit)?,
    colors: FlareColors,
    glyph: ImageVector? = null,
) {
    val pressed = action.pressed
    IconButton(
        onClick = { onAction?.invoke(action) },
        enabled = action.enabled && onAction != null,
        colors = if (pressed == true) IconButtonDefaults.iconButtonColors(containerColor = colors.bgSelected) else IconButtonDefaults.iconButtonColors(),
        modifier = Modifier.semantics {
            contentDescription = action.accessibilityLabel ?: label
            if (pressed != null) toggleableState = ToggleableState(pressed)
        },
    ) {
        if (glyph != null) Icon(glyph, contentDescription = null, Modifier.size(21.dp), tint = if (pressed == true) colors.primaryText else colors.textSecondary)
        else if (actionIcon != null) actionIcon(action)
        else Icon(headerActionIcon(action), contentDescription = null, Modifier.size(20.dp), tint = if (pressed == true) colors.primaryText else colors.textSecondary)
    }
}

/** The add / more menu: the kit [ActionMenu] over the placement's actions, each named by [labelOf], reporting the chosen action. */
@Composable
private fun HeaderActionMenu(
    actions: List<ConversationHeaderAction>,
    labelOf: (ConversationHeaderAction) -> String,
    trigger: ImageVector,
    label: String,
    onAction: ((ConversationHeaderAction) -> Unit)?,
    colors: FlareColors,
) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        IconButton(
            onClick = { expanded = true },
            enabled = onAction != null,
            modifier = Modifier.semantics { contentDescription = label },
        ) { Icon(trigger, contentDescription = null, Modifier.size(21.dp), tint = colors.textSecondary) }
        ActionMenu(
            expanded = expanded,
            items = actions.map { it.toActionItem(labelOf(it)) },
            onDismiss = { expanded = false },
            onSelect = { id -> actions.firstOrNull { it.id == id }?.let { onAction?.invoke(it) } },
            label = label,
        )
    }
}

/**
 * A header action as an [ActionMenu] item, field by field (`order` and `intent` are the header's,
 * not the menu's), shown as [shownLabel] (the header passes the strings-table words for a default). The icon
 * falls back to the action id, as the header's buttons resolve it.
 */
internal fun ConversationHeaderAction.toActionItem(shownLabel: String = label): FlareActionItem = FlareActionItem(
    id = id,
    label = shownLabel,
    icon = icon ?: id,
    group = group,
    visible = visible,
    enabled = enabled,
    badge = badge,
    accessibilityLabel = accessibilityLabel,
    disabledReason = disabledReason,
    pressed = pressed,
)

private fun headerActionIcon(action: ConversationHeaderAction): ImageVector = flareActionIcon(action.icon ?: action.id)
