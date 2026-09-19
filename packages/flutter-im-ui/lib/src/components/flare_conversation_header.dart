import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_action_menu.dart';
import 'flare_avatar.dart';

enum FlareConversationHeaderKind { direct, group, channel, bot, system }

enum FlareConversationHeaderActionPlacement { primary, add, overflow }

class FlareConversationIdentity {
  const FlareConversationIdentity({
    required this.id,
    required this.title,
    this.kind = FlareConversationHeaderKind.direct,
    this.subtitle,
    this.avatarUrl,
    this.presence,
    this.memberCount,
    this.typingText,
    this.accessibilityLabel,
    this.action,
  });

  final String id;
  final String title;
  final FlareConversationHeaderKind kind;
  final String? subtitle;
  final String? avatarUrl;
  final FlarePresence? presence;
  final int? memberCount;
  final String? typingText;
  final String? accessibilityLabel;

  /// Makes the whole identity block (avatar, title, subtitle) one button that
  /// reports this action, typically opening the conversation details.
  final FlareConversationHeaderAction? action;
}

class FlareConversationHeaderAction {
  const FlareConversationHeaderAction({
    required this.id,
    required this.label,
    this.icon,
    this.placement = FlareConversationHeaderActionPlacement.primary,
    this.group,
    this.order,
    this.visible = true,
    this.enabled = true,
    this.badge,
    this.intent,
    this.capability,
    this.accessibilityLabel,
    this.disabledReason,
    this.pressed,
  });

  final String id;
  final String label;
  final String? icon;
  final FlareConversationHeaderActionPlacement placement;
  final String? group;
  final int? order;
  final bool visible;
  final bool enabled;
  final String? badge;
  final String? intent;
  final String? capability;
  final String? accessibilityLabel;
  final String? disabledReason;

  /// Non-null makes the action a toggle, drawn and announced as on when true.
  final bool? pressed;
}

class FlareConversationHeaderCapabilities {
  const FlareConversationHeaderCapabilities({this.availableActionIds});
  final Set<String>? availableActionIds;
}

class FlareConversationHeaderConfiguration {
  const FlareConversationHeaderConfiguration({
    this.replaceDefaults = false,
    this.removeActionIds = const {},
    this.actionOverrides = const [],
    this.maxPrimaryActions = 3,
    this.compactMaxPrimaryActions = 1,
  });

  final bool replaceDefaults;
  final Set<String> removeActionIds;
  final List<FlareConversationHeaderAction> actionOverrides;
  final int maxPrimaryActions;
  final int compactMaxPrimaryActions;
}

const DefaultDirectConversationHeaderConfig =
    FlareConversationHeaderConfiguration();
const DefaultGroupConversationHeaderConfig =
    FlareConversationHeaderConfiguration();

/// The actions every conversation of [kind] starts with, labelled from
/// [strings] so a host that changes the language changes them too.
List<FlareConversationHeaderAction> _defaultActions(
  FlareConversationHeaderKind kind,
  FlareStrings strings,
) {
  final group =
      kind == FlareConversationHeaderKind.group ||
      kind == FlareConversationHeaderKind.channel;
  return [
    FlareConversationHeaderAction(
      id: 'search',
      label: strings.conversationHeaderSearch,
      icon: 'search',
      order: 10,
    ),
    FlareConversationHeaderAction(
      id: 'audioCall',
      label: strings.conversationHeaderAudioCall,
      icon: 'phone',
      capability: 'audioCall',
      order: 20,
    ),
    FlareConversationHeaderAction(
      id: 'videoCall',
      label: strings.conversationHeaderVideoCall,
      icon: 'video',
      capability: 'videoCall',
      order: 30,
    ),
    if (group)
      FlareConversationHeaderAction(
        id: 'addMember',
        label: strings.conversationHeaderAddMember,
        icon: 'person-add',
        placement: FlareConversationHeaderActionPlacement.add,
        order: 40,
      ),
    FlareConversationHeaderAction(
      id: 'share',
      label: strings.conversationHeaderShare,
      icon: 'share',
      placement: FlareConversationHeaderActionPlacement.add,
      order: group ? 50 : 40,
    ),
    FlareConversationHeaderAction(
      id: 'details',
      label: strings.conversationHeaderDetails,
      icon: 'info',
      placement: FlareConversationHeaderActionPlacement.overflow,
      order: 90,
    ),
  ];
}

/// The header's actions: the defaults for the identity's kind (labelled from
/// [strings]; the header passes the ambient `FlareStrings.of(context)`), then
/// the configuration's overrides and [actions] by id, filtered by visibility,
/// removal and [capabilities], in `order`.
List<FlareConversationHeaderAction> resolveConversationHeaderActions({
  required FlareConversationIdentity identity,
  FlareConversationHeaderCapabilities? capabilities,
  FlareConversationHeaderConfiguration configuration =
      const FlareConversationHeaderConfiguration(),
  List<FlareConversationHeaderAction> actions = const [],
  FlareStrings strings = const FlareStrings(),
}) {
  final source = configuration.replaceDefaults
      ? <FlareConversationHeaderAction>[]
      : _defaultActions(identity.kind, strings);
  final byId = <String, FlareConversationHeaderAction>{
    for (final action in source) action.id: action,
  };
  for (final action in [...configuration.actionOverrides, ...actions]) {
    byId[action.id] = action;
  }
  final available = capabilities?.availableActionIds;
  final result = byId.values.where((action) {
    if (!action.visible || configuration.removeActionIds.contains(action.id))
      return false;
    return available == null ||
        available.contains(action.capability ?? action.id);
  }).toList();
  result.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  return result;
}

/// Opinionated conversation identity plus capability-aware host actions.
class FlareConversationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const FlareConversationHeader({
    super.key,
    required this.identity,
    this.capabilities,
    this.configuration = const FlareConversationHeaderConfiguration(),
    this.actions = const [],
    this.showBack = false,
    this.onBack,
    this.onAction,
    this.identityBuilder,
    this.actionIconBuilder,
    this.trailing,
  });

  final FlareConversationIdentity identity;
  final FlareConversationHeaderCapabilities? capabilities;
  final FlareConversationHeaderConfiguration configuration;
  final List<FlareConversationHeaderAction> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final ValueChanged<FlareConversationHeaderAction>? onAction;
  final Widget Function(BuildContext, FlareConversationIdentity)?
  identityBuilder;

  /// Builds the icon of a primary action button. The add and more menus draw
  /// each action's semantic [FlareConversationHeaderAction.icon] instead.
  final Widget Function(BuildContext, FlareConversationHeaderAction)?
  actionIconBuilder;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(FlareSizes.headerHeight);

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final resolved = resolveConversationHeaderActions(
      identity: identity,
      capabilities: capabilities,
      configuration: configuration,
      actions: actions,
      strings: strings,
    );
    final identityAction = _resolveIdentityAction();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final maxPrimary = compact
            ? configuration.compactMaxPrimaryActions
            : configuration.maxPrimaryActions;
        final candidates = resolved
            .where(
              (a) =>
                  a.placement == FlareConversationHeaderActionPlacement.primary,
            )
            .toList();
        final primary = candidates.take(maxPrimary).toList();
        final add = resolved
            .where(
              (a) => a.placement == FlareConversationHeaderActionPlacement.add,
            )
            .toList();
        final overflow = [
          ...candidates.skip(maxPrimary),
          ...resolved.where(
            (a) =>
                a.placement == FlareConversationHeaderActionPlacement.overflow,
          ),
        ];

        return Semantics(
          container: true,
          label: identity.accessibilityLabel ?? identity.title,
          child: Container(
            height: FlareSizes.headerHeight,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? FlareSizes.spacingSm : FlareSizes.spacingLg,
            ),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              border: Border(bottom: BorderSide(color: colors.borderPrimary)),
            ),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    tooltip: strings.back,
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child:
                      identityBuilder?.call(context, identity) ??
                      _identity(colors, strings, compact, identityAction),
                ),
                for (final action in primary)
                  _actionButton(context, action, colors),
                if (add.isNotEmpty)
                  _menu(
                    add,
                    Icons.add_rounded,
                    strings.conversationHeaderAddActions,
                    colors,
                  ),
                // A More menu holding one action is a detour: that action
                // takes the More button itself, named by its own label.
                if (overflow.length == 1)
                  _actionButton(
                    context,
                    overflow.single,
                    colors,
                    icon: const Icon(Icons.more_horiz_rounded, size: 22),
                  )
                else if (overflow.isNotEmpty)
                  _menu(
                    overflow,
                    Icons.more_horiz_rounded,
                    strings.conversationHeaderMoreActions,
                    colors,
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        );
      },
    );
  }

  /// The identity action when it survives visibility, removal, capability
  /// filtering and is enabled; only then is the identity block a button.
  FlareConversationHeaderAction? _resolveIdentityAction() {
    final action = identity.action;
    if (action == null ||
        !action.visible ||
        !action.enabled ||
        onAction == null ||
        configuration.removeActionIds.contains(action.id)) {
      return null;
    }
    final available = capabilities?.availableActionIds;
    return available == null ||
            available.contains(action.capability ?? action.id)
        ? action
        : null;
  }

  Widget _identity(
    FlareColors colors,
    FlareStrings strings,
    bool compact,
    FlareConversationHeaderAction? action,
  ) {
    final memberCount = identity.memberCount;
    final grouped =
        identity.kind == FlareConversationHeaderKind.group ||
        identity.kind == FlareConversationHeaderKind.channel;
    final subtitle = identity.typingText?.trim().isNotEmpty == true
        ? identity.typingText!
        : identity.subtitle?.trim().isNotEmpty == true
        ? identity.subtitle!
        : grouped && memberCount != null
        ? strings.conversationHeaderMemberCount(memberCount)
        : switch (identity.presence) {
            FlarePresence.online => strings.presenceOnline,
            FlarePresence.offline => strings.presenceOffline,
            FlarePresence.busy => strings.presenceBusy,
            FlarePresence.away => strings.presenceAway,
            null => '',
          };
    final block = Row(
      children: [
        FlareAvatar(
          userId: identity.id,
          displayName: identity.title,
          avatarUrl: identity.avatarUrl,
          size: compact ? 36 : 40,
          presence: identity.presence,
        ),
        const SizedBox(width: FlareSizes.spacingSm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                identity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSize2xl,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: identity.presence == FlarePresence.online
                        ? colors.success
                        : colors.textTertiary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (action == null) return block;
    void activate() => onAction!(action);
    return Semantics(
      container: true,
      button: true,
      label: action.accessibilityLabel ?? '${identity.title}, ${action.label}',
      onTap: activate,
      excludeSemantics: true,
      // Ink on a surface of its own, above the header fill.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: activate,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          hoverColor: colors.bgHover,
          highlightColor: colors.bgHover,
          focusColor: colors.focusRing,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: block,
          ),
        ),
      ),
    );
  }

  /// A primary action as its own button. [icon] replaces the action's glyph,
  /// as for the sole overflow action, which keeps the More glyph.
  Widget _actionButton(
    BuildContext context,
    FlareConversationHeaderAction action,
    FlareColors colors, {
    Widget? icon,
  }) {
    final pressed = action.pressed;
    final glyph =
        icon ??
        actionIconBuilder?.call(context, action) ??
        Icon(_icon(action), size: 21);
    return IconButton(
      tooltip:
          action.disabledReason ?? action.accessibilityLabel ?? action.label,
      onPressed: action.enabled && onAction != null
          ? () => onAction!(action)
          : null,
      style: pressed == true
          ? IconButton.styleFrom(backgroundColor: colors.bgSelected)
          : null,
      icon: pressed == null ? glyph : Semantics(toggled: pressed, child: glyph),
      color: pressed == true ? colors.primary : colors.textSecondary,
    );
  }

  /// An add or more menu: the actions become [FlareActionItem]s field by field,
  /// so a pressed action is a checked item, a disabled one keeps its reason and
  /// a group change draws a separator.
  Widget _menu(
    List<FlareConversationHeaderAction> actions,
    IconData trigger,
    String label,
    FlareColors colors,
  ) {
    return FlareActionMenu(
      label: label,
      items: [for (final action in actions) _menuItem(action)],
      onSelected: (id) {
        final handler = onAction;
        if (handler == null) return;
        for (final action in actions) {
          if (action.id == id) {
            handler(action);
            return;
          }
        }
      },
      builder: (context, open) => IconButton(
        tooltip: label,
        onPressed: onAction == null ? null : open,
        icon: Icon(trigger, size: 22, color: colors.textSecondary),
      ),
    );
  }

  static FlareActionItem _menuItem(FlareConversationHeaderAction action) =>
      FlareActionItem(
        id: action.id,
        label: action.label,
        // The glyph name the header's buttons resolve, in the menu too.
        icon: action.icon ?? action.id,
        group: action.group,
        visible: action.visible,
        enabled: action.enabled,
        badge: action.badge,
        accessibilityLabel: action.accessibilityLabel,
        disabledReason: action.disabledReason,
        pressed: action.pressed,
      );

  IconData _icon(FlareConversationHeaderAction action) =>
      flareActionIcon(action.icon ?? action.id) ?? Icons.more_horiz_rounded;
}
