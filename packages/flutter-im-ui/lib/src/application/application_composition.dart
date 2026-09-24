import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/flare_conversation_workspace.dart';
import '../components/flare_action_menu.dart';
import '../components/flare_avatar.dart';
import '../components/flare_skeleton.dart';
import '../components/flare_status_banner.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import '../components/action_icon.dart';
import '../components/flare_shell_scope.dart';
import '../components/workspace_presentation_report.dart';
import '../models/workspace_layout.dart';

enum FlareNavigationPresentation { bottom, rail, sidebar, expandedSidebar }

enum FlareNavigationBadgeKind { dot, count, mention }

/// Keyboard commands a desktop shell emits; the host decides what each one does.
enum FlareDesktopShellCommand {
  closeOverlay,
  openCommandPalette,
  openSearch,
  newConversation,
  toggleDetails,
  openSettings,
  moreActions,
}

class FlareOpenSearchIntent extends Intent {
  const FlareOpenSearchIntent();
}

class FlareOpenCommandPaletteIntent extends Intent {
  const FlareOpenCommandPaletteIntent();
}

class FlareNewConversationIntent extends Intent {
  const FlareNewConversationIntent();
}

class FlareToggleDetailsIntent extends Intent {
  const FlareToggleDetailsIntent();
}

class FlareOpenSettingsIntent extends Intent {
  const FlareOpenSettingsIntent();
}

class FlareOpenMoreActionsIntent extends Intent {
  const FlareOpenMoreActionsIntent();
}

enum FlareWorkspacePane { primary, content, detail }

enum FlareViewStatus { loading, ready, empty, error, offline }

class FlareNavigationBadge {
  const FlareNavigationBadge({required this.kind, this.count, this.label});
  final FlareNavigationBadgeKind kind;
  final int? count;
  final String? label;
}

class FlareNavigationItem {
  const FlareNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.badge,
    this.disabled = false,
    this.visible = true,
    this.order,
    this.capability,
    this.intent,
    this.accessibilityLabel,
    this.menu,
  });
  final String id;
  final String label;

  /// A semantic icon name from `flareIconNames`.
  final String icon;
  final FlareNavigationBadge? badge;
  final bool disabled;
  final bool visible;
  final int? order;
  final String? capability;
  final FlareNavigationIntent? intent;
  final String? accessibilityLabel;

  /// Optional anchored menu for a navigation action. Destination items leave
  /// this null; actions such as "new" use it and report the selected entry id
  /// through the same navigation callback.
  final List<FlareActionItem>? menu;
}

/// The signed-in identity displayed at the top of a desktop navigation rail.
class FlareNavigationIdentity {
  const FlareNavigationIdentity({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.accessibilityLabel,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? accessibilityLabel;
}

class FlareNavigationGroup {
  const FlareNavigationGroup({
    required this.id,
    required this.items,
    this.label,
  });
  final String id;
  final String? label;
  final List<FlareNavigationItem> items;
}

class FlareFeatureSet {
  const FlareFeatureSet(this.enabled);
  final Set<String> enabled;
  bool contains(String id) => enabled.contains(id);
}

class FlareCapabilitySet {
  const FlareCapabilitySet(this.enabled);
  final Set<String> enabled;
  bool contains(String id) => enabled.contains(id);
}

/// The kit's default IM navigation, named by [strings] — a function rather
/// than a const list because the names belong to the strings table, not to
/// English literals in the source.
List<FlareNavigationItem> flareDefaultIMNavigation(FlareStrings strings) => [
  FlareNavigationItem(
    id: 'chats',
    label: strings.navigationChats,
    icon: 'chats',
    order: 0,
  ),
  FlareNavigationItem(
    id: 'contacts',
    label: strings.navigationContacts,
    icon: 'people',
    order: 1,
  ),
  FlareNavigationItem(
    id: 'profile',
    label: strings.navigationProfile,
    icon: 'person',
    order: 2,
  ),
];

/// The kit's default contacts navigation, named by [strings].
List<FlareNavigationItem> flareDefaultContactNavigation(FlareStrings strings) =>
    [
      FlareNavigationItem(
        id: 'friends',
        label: strings.navigationFriends,
        icon: 'person',
        order: 0,
      ),
      FlareNavigationItem(
        id: 'groups',
        label: strings.navigationGroups,
        icon: 'group',
        order: 1,
      ),
      FlareNavigationItem(
        id: 'newFriends',
        label: strings.navigationNewFriends,
        icon: 'person-add',
        order: 2,
      ),
      FlareNavigationItem(
        id: 'favorites',
        label: strings.favorites,
        icon: 'star',
        order: 3,
      ),
    ];

List<FlareNavigationItem> resolveFlareNavigationItems(
  List<FlareNavigationItem> defaults, {
  List<FlareNavigationItem>? items,
  FlareCapabilitySet capabilities = const FlareCapabilitySet({}),
}) {
  final seen = <String>{};
  final indexed = (items ?? defaults).indexed
      .where(
        (entry) =>
            entry.$2.id.isNotEmpty && entry.$2.visible && seen.add(entry.$2.id),
      )
      .where(
        (entry) =>
            entry.$2.capability == null ||
            capabilities.contains(entry.$2.capability!),
      )
      .toList(growable: false);
  indexed.sort((left, right) {
    final byOrder = (left.$2.order ?? left.$1).compareTo(
      right.$2.order ?? right.$1,
    );
    return byOrder != 0 ? byOrder : left.$1.compareTo(right.$1);
  });
  return indexed.map((entry) => entry.$2).toList(growable: false);
}

class FlareGroupCapabilities {
  const FlareGroupCapabilities({
    this.invite = false,
    this.remove = false,
    this.promote = false,
    this.demote = false,
    this.mute = false,
    this.leave = false,
    this.dismiss = false,
    this.rename = false,
    this.changeAvatar = false,
    this.editAnnouncement = false,
  });
  final bool invite,
      remove,
      promote,
      demote,
      mute,
      leave,
      dismiss,
      rename,
      changeAvatar,
      editAnnouncement;
}

class FlareConversationCapabilities {
  const FlareConversationCapabilities({
    this.message = false,
    this.call = false,
    this.video = false,
    this.mute = false,
    this.pin = false,
    this.search = false,
    this.media = false,
    this.details = false,
  });
  final bool message, call, video, mute, pin, search, media, details;
}

class FlareContactCapabilities {
  const FlareContactCapabilities({
    this.message = false,
    this.call = false,
    this.video = false,
    this.viewProfile = false,
    this.block = false,
    this.delete = false,
  });
  final bool message, call, video, viewProfile, block, delete;
}

class FlareCallCapabilities {
  const FlareCallCapabilities({
    this.mute = false,
    this.speaker = false,
    this.camera = false,
    this.switchCamera = false,
    this.hangup = false,
    this.minimize = false,
    this.restore = false,
  });
  final bool mute, speaker, camera, switchCamera, hangup, minimize, restore;
}

class FlareViewState<T> {
  const FlareViewState({
    required this.status,
    this.data,
    this.error,
    this.emptyTitle,
    this.stale = false,
    this.hasMore = false,
  });
  final FlareViewStatus status;
  final T? data;

  /// What went wrong, for [FlareViewStatus.error] and [FlareViewStatus.offline]; never the empty
  /// state's words (FR-057).
  final String? error;

  /// What an empty list should say. Without it the container falls back to its own words.
  final String? emptyTitle;

  /// A failed refresh over content that is still worth showing: the rows stay and the failure is a
  /// banner above them, instead of replacing everything a person was reading (FR-057).
  final bool stale;
  final bool hasMore;
}

/// What a container draws for a state: the rows, the rows under a banner, or a state of its own.
enum FlareViewPresentation { content, contentWithNotice, state }

/// How a list container presents a state (`spec/view-state-vectors.json`, the same table on four kits).
FlareViewPresentation flareViewPresentation(
  FlareViewStatus status,
  bool stale,
) {
  if (status == FlareViewStatus.ready) return FlareViewPresentation.content;
  if (stale &&
      (status == FlareViewStatus.error || status == FlareViewStatus.offline)) {
    return FlareViewPresentation.contentWithNotice;
  }
  return FlareViewPresentation.state;
}

abstract interface class FlareDataSource<Q, R> {
  Future<FlareViewState<R>> read(Q query);
}

abstract class FlareIMHostAdapter {
  FlareDataSource<Object?, List<Object?>>? get conversations => null;
  FlareDataSource<Object?, List<Object?>>? get messages => null;
  FlareDataSource<Object?, List<Object?>>? get contacts => null;
  FlareDataSource<Object?, List<Object?>>? get groups => null;
  FlareDataSource<Object?, Object?>? get presence => null;
  FlareDataSource<Object?, Object?>? get uploads => null;
  FlareDataSource<Object?, Object?>? get calls => null;
}

sealed class FlareNavigationIntent {
  const FlareNavigationIntent();
}

class FlareNavigationOpenConversation extends FlareNavigationIntent {
  const FlareNavigationOpenConversation(this.conversationId);
  final String conversationId;
}

class FlareNavigationOpenContact extends FlareNavigationIntent {
  const FlareNavigationOpenContact(this.contactId);
  final String contactId;
}

class FlareNavigationOpenGroup extends FlareNavigationIntent {
  const FlareNavigationOpenGroup(this.groupId);
  final String groupId;
}

class FlareNavigationOpenSearch extends FlareNavigationIntent {
  const FlareNavigationOpenSearch([this.query]);
  final String? query;
}

class FlareNavigationOpenSettings extends FlareNavigationIntent {
  const FlareNavigationOpenSettings([this.sectionId]);
  final String? sectionId;
}

class FlareCustomNavigationIntent extends FlareNavigationIntent {
  const FlareCustomNavigationIntent(this.id, [this.payload]);
  final String id;
  final Object? payload;
}

class FlareIMAppConfiguration {
  const FlareIMAppConfiguration({
    required this.features,
    required this.navigation,
    this.capabilities = const FlareCapabilitySet({}),
    this.identity,
    this.navigationActions = const [],
  });
  final FlareFeatureSet features;
  final List<FlareNavigationGroup> navigation;
  final FlareCapabilitySet capabilities;

  /// Desktop rail identity. Phone bottom navigation intentionally ignores it.
  final FlareNavigationIdentity? identity;

  /// High-frequency desktop rail actions, such as new and search.
  final List<FlareNavigationItem> navigationActions;
}

class FlareMessageActionExtension<T> {
  const FlareMessageActionExtension({
    required this.id,
    required this.label,
    this.icon,
    this.group,
    this.order,
    this.visible = true,
    this.enabled,
    this.capability,
    this.intent,
    this.accessibilityLabel,
    this.disabledReason,
    this.destructive = false,
    this.available,
  });
  final String id;
  final String label;

  /// A semantic icon name from `flareIconNames`.
  final String? icon;
  final String? group;
  final int? order;
  final bool visible;
  final bool Function(T context)? enabled;
  final String? capability;
  final String? intent;
  final String? accessibilityLabel;
  final String? disabledReason;
  final bool destructive;
  final bool Function(T context)? available;

  bool isEnabled(T context) => enabled?.call(context) ?? true;
}

List<FlareMessageActionExtension<T>> resolveFlareMessageActionExtensions<T>(
  List<FlareMessageActionExtension<T>> actions,
  T context, {
  FlareCapabilitySet capabilities = const FlareCapabilitySet({}),
}) {
  final indexed = actions.indexed
      .where((entry) => entry.$2.visible)
      .where(
        (entry) =>
            entry.$2.capability == null ||
            capabilities.contains(entry.$2.capability!),
      )
      .where((entry) => entry.$2.available?.call(context) ?? true)
      .toList(growable: false);
  indexed.sort((left, right) {
    final byOrder = (left.$2.order ?? left.$1).compareTo(
      right.$2.order ?? right.$1,
    );
    return byOrder != 0 ? byOrder : left.$1.compareTo(right.$1);
  });
  return indexed.map((entry) => entry.$2).toList(growable: false);
}

/// Width the navigation presentation for [mode] occupies beside the panes.
double flareNavigationWidthForMode(FlareApplicationResponsiveMode mode) =>
    switch (mode) {
      FlareApplicationResponsiveMode.mobile => 0,
      FlareApplicationResponsiveMode.tablet => FlareSizes.navigationRailWidth,
      FlareApplicationResponsiveMode.wideDesktop =>
        FlareSizes.primaryPaneDefaultWidth,
      FlareApplicationResponsiveMode.desktop => FlareSizes.primaryPaneMinWidth,
    };

/// Shared rule with Vue/Compose/SwiftUI (spec/application-layout-vectors.json): the pane rule
/// ([flarePaneModeForWidth]),
/// with the navigation [mode] draws, and the detail inline only when three panes fit.
FlareWorkspacePresentation flareWorkspacePresentation(
  FlareApplicationResponsiveMode mode, {
  bool hasDetail = false,
  double? width,
  double textScale = 1,
  double? navigationWidth,
  double primaryWidth = FlareSizes.primaryPaneDefaultWidth,
  double detailWidth = FlareSizes.detailPaneDefaultWidth,
}) {
  final routed = hasDetail
      ? FlareWorkspaceDetailPresentation.route
      : FlareWorkspaceDetailPresentation.hidden;
  if (mode == FlareApplicationResponsiveMode.mobile) {
    return FlareWorkspacePresentation(
      FlareWorkspacePaneMode.singlePane,
      routed,
    );
  }
  final measured = width != null && width.isFinite;
  FlareWorkspacePaneMode fit(bool detail) => flarePaneModeForWidth(
    width!,
    hasDetail: detail,
    textScale: textScale,
    navigationWidth: navigationWidth ?? flareNavigationWidthForMode(mode),
    primaryWidth: primaryWidth,
    detailWidth: detailWidth,
  );
  if (mode == FlareApplicationResponsiveMode.tablet) {
    // A tablet's layout has no detail column: two panes at most, and a detail
    // over them. One pane makes the detail a page the host routes to.
    if (measured && fit(false) == FlareWorkspacePaneMode.singlePane) {
      return FlareWorkspacePresentation(
        FlareWorkspacePaneMode.singlePane,
        routed,
      );
    }
    return FlareWorkspacePresentation(
      FlareWorkspacePaneMode.dualPane,
      hasDetail
          ? FlareWorkspaceDetailPresentation.overlay
          : FlareWorkspaceDetailPresentation.hidden,
    );
  }
  final paneMode = measured
      ? fit(hasDetail)
      : hasDetail
      ? FlareWorkspacePaneMode.triplePane
      : FlareWorkspacePaneMode.dualPane;
  return switch (paneMode) {
    FlareWorkspacePaneMode.triplePane => const FlareWorkspacePresentation(
      FlareWorkspacePaneMode.triplePane,
      FlareWorkspaceDetailPresentation.inline,
    ),
    // Two panes: a detail opens over the chat rather than crushing the navigation.
    FlareWorkspacePaneMode.dualPane => FlareWorkspacePresentation(
      FlareWorkspacePaneMode.dualPane,
      hasDetail
          ? FlareWorkspaceDetailPresentation.overlay
          : FlareWorkspaceDetailPresentation.hidden,
    ),
    FlareWorkspacePaneMode.singlePane => FlareWorkspacePresentation(
      FlareWorkspacePaneMode.singlePane,
      routed,
    ),
  };
}

FlareNavigationPresentation flareNavigationPresentation(
  FlareApplicationResponsiveMode mode,
) => switch (mode) {
  FlareApplicationResponsiveMode.mobile => FlareNavigationPresentation.bottom,
  FlareApplicationResponsiveMode.tablet => FlareNavigationPresentation.rail,
  FlareApplicationResponsiveMode.desktop => FlareNavigationPresentation.sidebar,
  FlareApplicationResponsiveMode.wideDesktop =>
    FlareNavigationPresentation.expandedSidebar,
};

class FlareAdaptiveNavigation extends StatelessWidget {
  const FlareAdaptiveNavigation({
    super.key,
    required this.groups,
    required this.activeId,
    required this.responsiveMode,
    this.presentation,
    this.onNavigate,
    this.label,
    this.identity,
    this.actions = const [],
  });
  final List<FlareNavigationGroup> groups;
  final String activeId;
  final FlareApplicationResponsiveMode responsiveMode;
  final FlareNavigationPresentation? presentation;
  final ValueChanged<String>? onNavigate;
  final String? label;
  final FlareNavigationIdentity? identity;
  final List<FlareNavigationItem> actions;

  List<FlareNavigationItem> get _items => groups
      .expand((group) => group.items)
      .where((item) => item.visible)
      .toList(growable: false);
  int get _selectedIndex {
    final index = _items.indexWhere((item) => item.id == activeId);
    return index < 0 ? 0 : index;
  }

  Widget _icon(FlareNavigationItem item) {
    final badge = item.badge;
    final icon = Icon(
      flareIconGlyph(item.icon),
      semanticLabel: item.accessibilityLabel ?? item.label,
    );
    if (badge == null) return icon;
    final text = badge.kind == FlareNavigationBadgeKind.dot
        ? null
        : badge.kind == FlareNavigationBadgeKind.mention
        ? (badge.label ?? '@')
        : '${(badge.count ?? 0).clamp(0, 99)}${(badge.count ?? 0) > 99 ? '+' : ''}';
    return Badge(label: text == null ? null : Text(text), child: icon);
  }

  Widget _railIcon(
    BuildContext context,
    FlareNavigationItem item, {
    double size = FlareSizes.iconSizeLg,
  }) {
    final colors = FlareColors.of(context);
    final badge = item.badge;
    final count = badge?.count ?? 0;
    final badgeText = switch (badge?.kind) {
      FlareNavigationBadgeKind.count =>
        '${count.clamp(0, 99)}${count > 99 ? '+' : ''}',
      FlareNavigationBadgeKind.mention => badge?.label ?? '@',
      _ => null,
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(flareIconGlyph(item.icon), size: size)),
          if (badge != null)
            PositionedDirectional(
              top: badge.kind == FlareNavigationBadgeKind.dot ? -2 : -7,
              end: badge.kind == FlareNavigationBadgeKind.dot ? -4 : -11,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: badge.kind == FlareNavigationBadgeKind.dot ? 8 : 16,
                ),
                height: badge.kind == FlareNavigationBadgeKind.dot ? 8 : 16,
                padding: badge.kind == FlareNavigationBadgeKind.dot
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badge.kind == FlareNavigationBadgeKind.mention
                      ? colors.important
                      : colors.errorText,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                ),
                child: badgeText == null
                    ? null
                    : Text(
                        badgeText,
                        style: TextStyle(
                          color: colors.messageOutgoingForeground,
                          fontSize: FlareSizes.fontSize2xs,
                          height: 1,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _railDestination(BuildContext context, FlareNavigationItem item) {
    final colors = FlareColors.of(context);
    final active = item.id == activeId;
    final foreground = active ? colors.primaryText : colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
      child: Semantics(
        selected: active,
        button: true,
        label: item.accessibilityLabel ?? item.label,
        child: Tooltip(
          message: item.label,
          child: Material(
            color: active ? colors.bgSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              onTap: item.disabled ? null : () => onNavigate?.call(item.id),
              child: SizedBox(
                width: FlareSizes.navigationRailWidth - FlareSizes.spacingSm,
                height: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(color: foreground),
                      child: _railIcon(context, item),
                    ),
                    const SizedBox(height: FlareSizes.spacingXs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: FlareSizes.fontSizeSm,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _railActionButton(
    BuildContext context,
    FlareNavigationItem item,
    VoidCallback? onPressed,
  ) {
    final colors = FlareColors.of(context);
    return Semantics(
      button: true,
      label: item.accessibilityLabel ?? item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            onTap: item.disabled ? null : onPressed,
            child: SizedBox(
              width: FlareSizes.touchTarget,
              height: FlareSizes.touchTarget,
              child: IconTheme(
                data: IconThemeData(color: colors.textSecondary),
                child: Center(
                  child: _railIcon(context, item, size: FlareSizes.iconSizeMd),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _railAction(BuildContext context, FlareNavigationItem item) {
    final menu =
        item.menu?.where((entry) => entry.visible).toList() ??
        const <FlareActionItem>[];
    if (menu.isEmpty) {
      return _railActionButton(context, item, () => onNavigate?.call(item.id));
    }
    return FlareActionMenu(
      items: menu,
      label: item.label,
      presentation: FlareActionMenuPresentation.anchored,
      onSelected: (id) => onNavigate?.call(id),
      builder: (context, open) => _railActionButton(context, item, open),
    );
  }

  Widget _rail(BuildContext context) {
    final colors = FlareColors.of(context);
    final visibleActions = actions.where((item) => item.visible).toList();
    final showLeading = identity != null || visibleActions.isNotEmpty;
    return Semantics(
      container: true,
      label: label,
      child: Material(
        color: colors.bgSecondary,
        child: SizedBox(
          width: FlareSizes.navigationRailWidth,
          // A rail inside a Row otherwise shrink-wraps its scroll content and the Row
          // vertically centres that shorter box. On tall desktop windows this leaves a
          // large bgPrimary band above the avatar. Fill the shell height so identity,
          // actions and the rail surface all start at the same top edge as Web.
          height: double.infinity,
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              FlareSizes.spacingXs,
              FlareSizes.spacingLg,
              FlareSizes.spacingXs,
              FlareSizes.spacingMd,
            ),
            child: Column(
              children: [
                if (showLeading) ...[
                  if (identity case final identity?)
                    Semantics(
                      button: true,
                      label:
                          identity.accessibilityLabel ?? identity.displayName,
                      child: ExcludeSemantics(
                        child: FlareAvatar(
                          userId: identity.userId,
                          displayName: identity.displayName,
                          avatarUrl: identity.avatarUrl,
                          size: FlareSizes.avatarSize,
                          onTap: () => onNavigate?.call('profile'),
                        ),
                      ),
                    ),
                  for (final action in visibleActions) ...[
                    const SizedBox(height: FlareSizes.spacingSm),
                    _railAction(context, action),
                  ],
                  const SizedBox(height: FlareSizes.spacingMd),
                  Divider(height: 1, color: colors.borderPrimary),
                  const SizedBox(height: FlareSizes.spacingMd),
                ],
                for (final group in groups)
                  for (final item in group.items)
                    if (item.visible) _railDestination(context, item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final mode = presentation ?? flareNavigationPresentation(responsiveMode);
    if (mode == FlareNavigationPresentation.bottom) {
      final colors = FlareColors.of(context);
      // NavigationBar 不暴露 selectedIconColor / selectedTextColor,只能经 theme 下发 ——
      // 光把 indicatorColor 关掉还不够:图标和文字仍会落回 Material 的 onSecondaryContainer
      // 之类的默认色,活跃态就不是 Flare 的 primaryText 了。
      return NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? colors.primaryText
                  : colors.textSecondary,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: FlareSizes.fontSizeSm,
              color: states.contains(WidgetState.selected)
                  ? colors.primaryText
                  : colors.textSecondary,
            ),
          ),
        ),
        child: NavigationBar(
          // 活跃态只由图标和文字的颜色表达。Material 默认会在活跃项外面画一块胶囊指示器 ——
          // 那是 Material 的语言不是 Flare 的,一行四项里只有一项带色块,比它要标示的图标还显眼。
          // iOS 一直是只用颜色。
          indicatorColor: Colors.transparent,
          backgroundColor: colors.bgPrimary,
          surfaceTintColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            final item = items[index];
            if (!item.disabled) onNavigate?.call(item.id);
          },
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: _icon(item),
                label: item.label,
                enabled: !item.disabled,
              ),
          ],
        ),
      );
    }
    if (mode == FlareNavigationPresentation.rail) {
      return _rail(context);
    }
    final colors = FlareColors.of(context);
    // Material, not ColoredBox: ListTile paints its selection and ink on the
    // nearest Material, so a plain colored box would swallow both.
    return Semantics(
      container: true,
      label: label,
      child: Material(
        color: colors.bgSecondary,
        child: SizedBox(
          width: mode == FlareNavigationPresentation.expandedSidebar
              ? FlareSizes.primaryPaneDefaultWidth
              : FlareSizes.primaryPaneMinWidth,
          child: ListView(
            padding: const EdgeInsets.all(FlareSizes.spacingSm),
            children: [
              for (final group in groups) ...[
                if (group.label != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      FlareSizes.spacingSm,
                      FlareSizes.spacingLg,
                      FlareSizes.spacingSm,
                      FlareSizes.spacingXs,
                    ),
                    child: Text(
                      group.label!,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
                  ),
                for (final item in group.items)
                  ListTile(
                    minTileHeight: FlareSizes.touchTarget,
                    leading: _icon(item),
                    title: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: item.id == activeId,
                    enabled: !item.disabled,
                    onTap: item.disabled
                        ? null
                        : () => onNavigate?.call(item.id),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The application frame: navigation beside (or under) the panes the host supplies.
///
/// Inside a shell it takes the shell's responsive mode ([FlareShellScope]); on its own it resolves the
/// mode from its own box. It measures **its own box**, not the window, and decides from that width
/// how many panes fit ([flareWorkspacePresentation]): below navigation + list + a usable chat
/// ([flarePaneModeMinWidth], 752 with the tablet rail and the default list) it shows **one
/// pane at a time** — the host's [activePane] — and keeps the navigation rail; a detail is then a
/// page the host routes to, not an overlay over a screen-wide pane. A phone always shows one pane,
/// and a pane other than the list is a page beyond the destination's root ([FlareDestinationDepth]).
///
/// [onLayoutChange] hands the host the presentation actually in use (pane mode + detail mode) on
/// the first resolution and whenever it changes, so a host never has to guess it back from a width.
class FlareAppLayout extends StatelessWidget {
  const FlareAppLayout({
    super.key,
    required this.content,
    this.navigation,
    this.primary,
    this.detail,
    this.overlay,
    this.floating,
    this.command,
    this.activePane = FlareWorkspacePane.content,
    this.hasDetail = false,
    this.primaryWidth = FlareSizes.primaryPaneDefaultWidth,
    this.detailWidth = FlareSizes.detailPaneDefaultWidth,
    this.onLayoutChange,
    this.label,
  });
  final Widget content;
  final Widget? navigation, primary, detail, overlay, floating, command;
  final FlareWorkspacePane activePane;
  final bool hasDetail;
  final double primaryWidth, detailWidth;

  /// The presentation this frame settled on, reported after the first layout
  /// and on every change.
  final ValueChanged<FlareWorkspacePresentation>? onLayoutChange;
  final String? label;

  @override
  Widget build(BuildContext context) {
    Widget active() => switch (activePane) {
      FlareWorkspacePane.primary => primary ?? content,
      FlareWorkspacePane.detail => detail ?? content,
      FlareWorkspacePane.content => content,
    };
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        // Inside a shell the mode is the shell's: it measured the box the whole
        // app lives in. On its own the frame resolves the mode from its box.
        final mode =
            FlareShellScope.responsiveModeOf(context) ??
            (width == null
                ? FlareApplicationResponsiveMode.desktop
                : flareApplicationResponsiveModeForWidth(
                    width,
                    textScale: textScale,
                  ));
        final mobile = mode == FlareApplicationResponsiveMode.mobile;
        final presentation = flareWorkspacePresentation(
          mode,
          hasDetail: hasDetail && detail != null,
          width: width,
          textScale: textScale,
          navigationWidth: navigation == null ? 0 : null,
          primaryWidth: primaryWidth,
          detailWidth: detailWidth,
        );
        final onePane =
            presentation.paneMode == FlareWorkspacePaneMode.singlePane;
        Widget row;
        if (mobile) {
          // A phone shows the host's active pane; its navigation is the shell's.
          row = active();
        } else {
          row = Row(
            children: [
              if (navigation != null) ...[
                navigation!,
                const VerticalDivider(width: 1),
              ],
              // One pane: the host's active pane fills what is left of the rail.
              if (onePane)
                Expanded(child: active())
              else ...[
                if (primary != null) ...[
                  SizedBox(width: primaryWidth, child: primary),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: content),
                if (presentation.detail ==
                    FlareWorkspaceDetailPresentation.inline) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(width: detailWidth, child: detail),
                ],
              ],
            ],
          );
          if (presentation.detail == FlareWorkspaceDetailPresentation.overlay &&
              activePane == FlareWorkspacePane.detail) {
            row = Stack(
              fit: StackFit.expand,
              children: [
                row,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: detailWidth,
                    child: Material(
                      elevation: FlareSizes.spacingSm,
                      child: detail!,
                    ),
                  ),
                ),
              ],
            );
          }
        }
        // One pane showing something other than the list is a page beyond the
        // destination's root.
        return FlareDestinationDepth(
          active:
              onePane &&
              primary != null &&
              activePane != FlareWorkspacePane.primary,
          child: FlareWorkspacePresentationReport(
            presentation: presentation,
            onLayoutChange: onLayoutChange,
            child: row,
          ),
        );
      },
    );
    return Semantics(
      container: true,
      label: label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          body,
          if (overlay != null) overlay!,
          if (floating != null) floating!,
          if (command != null) command!,
        ],
      ),
    );
  }
}

class FlareMobileAppShell extends StatelessWidget {
  const FlareMobileAppShell({
    super.key,
    required this.navigation,
    required this.activeNavigationId,
    required this.child,
    this.appBar,
    this.overlay,
    this.floating,
    this.toast,
    this.hideNavigation = false,
    this.onNavigate,
    this.label,
  });
  final List<FlareNavigationGroup> navigation;
  final String activeNavigationId;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? overlay, floating, toast;
  final bool hideNavigation;
  final ValueChanged<String>? onNavigate;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Scaffold(
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(bottom: hideNavigation, child: child),
          if (overlay != null) overlay!,
          if (floating != null) floating!,
          if (toast != null) toast!,
        ],
      ),
      bottomNavigationBar: hideNavigation
          ? null
          : SafeArea(
              top: false,
              child: FlareAdaptiveNavigation(
                groups: navigation,
                activeId: activeNavigationId,
                responsiveMode: FlareApplicationResponsiveMode.mobile,
                onNavigate: onNavigate,
              ),
            ),
    ),
  );
}

/// Spec: Layout/DesktopAppShell (`FlareDesktopAppShell`). Adaptive navigation
/// plus the AppLayout pane regions, with the desktop keyboard commands (Escape,
/// ⌘/Ctrl+K, ⌘/Ctrl+F, ⌘/Ctrl+N, ⌘/Ctrl+Shift+D, ⌘/Ctrl+, and Alt+/) emitted as
/// one [onCommand] callback. The shell never decides what a command does.
class FlareDesktopAppShell extends StatelessWidget {
  const FlareDesktopAppShell({
    super.key,
    required this.navigation,
    required this.activeNavigationId,
    required this.content,
    this.primary,
    this.detail,
    this.overlay,
    this.floating,
    this.command,
    this.responsiveMode = FlareApplicationResponsiveMode.desktop,
    this.hasDetail = false,
    this.activePane = FlareWorkspacePane.content,
    this.onNavigate,
    this.onCommand,
    this.onLayoutChange,
    this.label,
  });
  final List<FlareNavigationGroup> navigation;
  final String activeNavigationId;
  final Widget content;
  final Widget? primary, detail, overlay, floating, command;
  final FlareApplicationResponsiveMode responsiveMode;
  final bool hasDetail;

  /// The pane the frame shows when it fits only one (see [FlareAppLayout]).
  final FlareWorkspacePane activePane;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<FlareDesktopShellCommand>? onCommand;

  /// See [FlareAppLayout.onLayoutChange].
  final ValueChanged<FlareWorkspacePresentation>? onLayoutChange;
  final String? label;

  static const Map<ShortcutActivator, Intent> _shortcuts = {
    SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
    SingleActivator(LogicalKeyboardKey.keyK, control: true):
        FlareOpenCommandPaletteIntent(),
    SingleActivator(LogicalKeyboardKey.keyK, meta: true):
        FlareOpenCommandPaletteIntent(),
    SingleActivator(LogicalKeyboardKey.keyF, control: true):
        FlareOpenSearchIntent(),
    SingleActivator(LogicalKeyboardKey.keyF, meta: true):
        FlareOpenSearchIntent(),
    SingleActivator(LogicalKeyboardKey.keyN, control: true):
        FlareNewConversationIntent(),
    SingleActivator(LogicalKeyboardKey.keyN, meta: true):
        FlareNewConversationIntent(),
    SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true):
        FlareToggleDetailsIntent(),
    SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true):
        FlareToggleDetailsIntent(),
    SingleActivator(LogicalKeyboardKey.comma, control: true):
        FlareOpenSettingsIntent(),
    SingleActivator(LogicalKeyboardKey.comma, meta: true):
        FlareOpenSettingsIntent(),
    SingleActivator(LogicalKeyboardKey.slash, alt: true):
        FlareOpenMoreActionsIntent(),
  };

  CallbackAction<T> _emit<T extends Intent>(FlareDesktopShellCommand value) =>
      CallbackAction<T>(
        onInvoke: (_) {
          onCommand?.call(value);
          return null;
        },
      );

  @override
  Widget build(BuildContext context) {
    // A desktop shell is told its presentation rather than measuring for it;
    // the layout inside reads it from the scope.
    final layout = FlareShellScope(
      responsiveMode: responsiveMode,
      child: FlareAppLayout(
        navigation: FlareAdaptiveNavigation(
          groups: navigation,
          activeId: activeNavigationId,
          responsiveMode: responsiveMode,
          onNavigate: onNavigate,
        ),
        primary: primary,
        content: content,
        detail: detail,
        hasDetail: hasDetail,
        activePane: activePane,
        overlay: overlay,
        floating: floating,
        command: command,
        onLayoutChange: onLayoutChange,
        label: label,
      ),
    );
    if (onCommand == null) return layout;
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: {
            DismissIntent: _emit<DismissIntent>(
              FlareDesktopShellCommand.closeOverlay,
            ),
            FlareOpenCommandPaletteIntent: _emit<FlareOpenCommandPaletteIntent>(
              FlareDesktopShellCommand.openCommandPalette,
            ),
            FlareOpenSearchIntent: _emit<FlareOpenSearchIntent>(
              FlareDesktopShellCommand.openSearch,
            ),
            FlareNewConversationIntent: _emit<FlareNewConversationIntent>(
              FlareDesktopShellCommand.newConversation,
            ),
            FlareToggleDetailsIntent: _emit<FlareToggleDetailsIntent>(
              FlareDesktopShellCommand.toggleDetails,
            ),
            FlareOpenSettingsIntent: _emit<FlareOpenSettingsIntent>(
              FlareDesktopShellCommand.openSettings,
            ),
            FlareOpenMoreActionsIntent: _emit<FlareOpenMoreActionsIntent>(
              FlareDesktopShellCommand.moreActions,
            ),
          },
          child: Focus(autofocus: true, child: layout),
        ),
      ),
    );
  }
}

/// One host state per pane, plus the cross-pane banner. Contacts, settings,
/// search and media all come through here, so the fallback text stays generic
/// and the panes resolve through the same [FlareWorkspacePaneView] the inbox
/// uses. `offline` is not a pane status: a connection condition belongs to the
/// banner, above panes that may still read fine from cache.
class FlareWorkspaceState {
  const FlareWorkspaceState({
    this.activePane = FlareWorkspacePane.content,
    this.primary = const FlareWorkspacePaneState(),
    this.content = const FlareWorkspacePaneState(),
    this.detail = const FlareWorkspacePaneState(),
    this.banner,
  });
  final FlareWorkspacePane activePane;
  final FlareWorkspacePaneState primary, content, detail;
  final FlareWorkspaceBanner? banner;
}

class FlareWorkspaceFrame extends StatelessWidget {
  const FlareWorkspaceFrame({
    super.key,
    required this.content,
    this.primary,
    this.detail,
    this.state = const FlareWorkspaceState(),
    this.hasDetail = false,
    this.onRetry,
    this.onEmptyAction,
    this.onBannerAction,
    this.onLayoutChange,
    this.label,
    this.loadingText,
    this.emptyText,
    this.failureText,
  });
  final Widget content;
  final Widget? primary, detail;
  final FlareWorkspaceState state;
  final bool hasDetail;
  final ValueChanged<FlareWorkspacePane>? onRetry;
  final ValueChanged<FlareWorkspacePane>? onEmptyAction;
  final VoidCallback? onBannerAction;

  /// See [FlareAppLayout.onLayoutChange].
  final ValueChanged<FlareWorkspacePresentation>? onLayoutChange;
  final String? label;

  /// Generic fallbacks: this frame carries contacts, settings, search and media,
  /// so its default text cannot talk about conversations. Null takes the value
  /// from the strings provider.
  final String? loadingText, emptyText, failureText;

  static FlareSkeletonVariant _skeleton(FlareWorkspacePane pane) =>
      switch (pane) {
        FlareWorkspacePane.primary => FlareSkeletonVariant.conversation,
        FlareWorkspacePane.content => FlareSkeletonVariant.message,
        FlareWorkspacePane.detail => FlareSkeletonVariant.profile,
      };

  static int _rows(FlareWorkspacePane pane) => switch (pane) {
    FlareWorkspacePane.primary => 6,
    FlareWorkspacePane.content => 5,
    FlareWorkspacePane.detail => 1,
  };

  static String _icon(FlareWorkspacePane pane) => switch (pane) {
    FlareWorkspacePane.primary => 'folder',
    FlareWorkspacePane.content => 'chats',
    FlareWorkspacePane.detail => 'info',
  };

  Widget _pane(
    BuildContext context,
    Widget? child,
    FlareWorkspacePaneState paneState,
    FlareWorkspacePane pane,
  ) {
    final strings = FlareStrings.of(context);
    return FlareWorkspacePaneView(
      state: paneState,
      skeleton: _skeleton(pane),
      skeletonRows: _rows(pane),
      emptyIcon: _icon(pane),
      emptyText: emptyText ?? strings.workspaceFrameEmpty,
      failureText: failureText ?? strings.workspaceFrameFailure,
      loadingText: loadingText ?? strings.workspaceFrameLoading,
      onRetry: onRetry == null ? null : () => onRetry!.call(pane),
      onEmptyAction: onEmptyAction == null
          ? null
          : () => onEmptyAction!.call(pane),
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banner = state.banner;
    final bannerAction = workspaceBannerActionVisible(
      banner,
      onBannerAction != null,
    );
    return Column(
      children: [
        if (banner != null && workspaceBannerVisible(banner))
          Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingSm),
            child: FlareStatusBanner(
              text: banner.message,
              tone: workspaceBannerTone(banner.tone),
              actionText: bannerAction ? banner.actionLabel : null,
              onAction: bannerAction ? onBannerAction : null,
            ),
          ),
        Expanded(
          child: FlareAppLayout(
            activePane: state.activePane,
            hasDetail: hasDetail,
            primary: _pane(
              context,
              primary,
              state.primary,
              FlareWorkspacePane.primary,
            ),
            content: _pane(
              context,
              content,
              state.content,
              FlareWorkspacePane.content,
            ),
            detail: _pane(
              context,
              detail,
              state.detail,
              FlareWorkspacePane.detail,
            ),
            onLayoutChange: onLayoutChange,
            label: label,
          ),
        ),
      ],
    );
  }
}

/// The application shell (FR-095). It measures its own box — not the window —
/// for the responsive mode and hands that mode down ([FlareShellScope]), draws
/// the navigation the mode calls for, and builds one destination per navigation
/// item with [destinationBuilder]. A destination arranges its own panes
/// ([FlareAppLayout], [FlareWorkspaceFrame], `FlareConversationWorkspace`).
///
/// Every destination opened so far stays built (off stage, without tickers,
/// focus or semantics while another is active), so coming back finds the list
/// scrolled where it was and the chat still open; the destinations survive a
/// change of mode too. The phone navigation steps aside while the active
/// destination shows a page beyond its root ([FlareDestinationDepth]).
class FlareIMAppKit extends StatefulWidget {
  const FlareIMAppKit({
    super.key,
    required this.configuration,
    required this.activeNavigationId,
    required this.destinationBuilder,
    this.overlay,
    this.command,
    this.onNavigate,
    this.onNavigateWithMode,
    this.onIntent,
    this.label,
  });
  final FlareIMAppConfiguration configuration;
  final String activeNavigationId;

  /// Builds the destination for a navigation item id.
  final Widget Function(BuildContext context, String id) destinationBuilder;
  final Widget? overlay, command;

  /// Navigation callback for hosts whose presentation depends on the mode
  /// already resolved by this shell. When supplied it replaces [onNavigate],
  /// so the host never needs to duplicate the responsive breakpoint logic.
  final void Function(String id, FlareApplicationResponsiveMode responsiveMode)?
  onNavigateWithMode;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<FlareNavigationIntent>? onIntent;
  final String? label;

  @override
  State<FlareIMAppKit> createState() => _FlareIMAppKitState();
}

class _FlareIMAppKitState extends State<FlareIMAppKit> {
  final List<String> _visited = [];
  final Map<String, ValueNotifier<int>> _depths = {};
  // Keeps the destinations' state when a change of mode moves them to another
  // parent (the phone scaffold body or the row beside the rail).
  final GlobalKey _destinationsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _visit();
  }

  @override
  void didUpdateWidget(FlareIMAppKit oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visit();
  }

  @override
  void dispose() {
    for (final depth in _depths.values) {
      depth.removeListener(_onDepth);
    }
    super.dispose();
  }

  void _visit() {
    final known = {
      for (final group in widget.configuration.navigation)
        for (final item in group.items) item.id,
    };
    final active = widget.activeNavigationId;
    _visited.removeWhere((id) => id != active && !known.contains(id));
    if (!_visited.contains(active)) _visited.add(active);
    for (final id in _depths.keys.toList()) {
      if (_visited.contains(id)) continue;
      _depths.remove(id)!.removeListener(_onDepth);
    }
    for (final id in _visited) {
      _depths.putIfAbsent(
        id,
        () => ValueNotifier<int>(0)..addListener(_onDepth),
      );
    }
  }

  void _onDepth() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mode = flareApplicationResponsiveModeForWidth(
        constraints.maxWidth,
        textScale: MediaQuery.textScalerOf(context).scale(1),
      );
      final mobile = mode == FlareApplicationResponsiveMode.mobile;
      final active = widget.activeNavigationId;
      final navigationHidden = mobile && (_depths[active]?.value ?? 0) > 0;
      void navigate(String id) {
        final contextual = widget.onNavigateWithMode;
        if (contextual != null) {
          contextual(id, mode);
        } else {
          widget.onNavigate?.call(id);
        }
      }

      final destinations = Stack(
        key: _destinationsKey,
        fit: StackFit.expand,
        children: [
          for (final id in _visited)
            FlareDestinationScope(
              key: ValueKey(id),
              depth: _depths[id]!,
              child: _Destination(
                active: id == active,
                child: Builder(
                  builder: (context) => widget.destinationBuilder(context, id),
                ),
              ),
            ),
        ],
      );
      final colors = FlareColors.of(context);
      return FlareShellScope(
        responsiveMode: mode,
        child: Semantics(
          container: true,
          label: widget.label,
          child: Scaffold(
            backgroundColor: colors.bgPrimary,
            body: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  bottom: !mobile || navigationHidden,
                  child: mobile
                      ? destinations
                      : Row(
                          children: [
                            FlareAdaptiveNavigation(
                              groups: widget.configuration.navigation,
                              activeId: active,
                              responsiveMode: mode,
                              // The Web app uses the compact 72px rail at every
                              // non-mobile width; pane density grows in the
                              // destination instead of widening app chrome.
                              presentation: FlareNavigationPresentation.rail,
                              onNavigate: navigate,
                              label: widget.label,
                              identity: widget.configuration.identity,
                              actions: widget.configuration.navigationActions,
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(child: destinations),
                          ],
                        ),
                ),
                if (widget.overlay != null) widget.overlay!,
                if (widget.command != null) widget.command!,
              ],
            ),
            bottomNavigationBar: mobile && !navigationHidden
                ? SafeArea(
                    top: false,
                    child: FlareAdaptiveNavigation(
                      groups: widget.configuration.navigation,
                      activeId: active,
                      responsiveMode: mode,
                      onNavigate: navigate,
                      label: widget.label,
                    ),
                  )
                : null,
          ),
        ),
      );
    },
  );
}

/// One destination, kept built while another is active: off stage (laid out,
/// so scroll positions survive, but not painted or hit), with its tickers
/// paused and its focus excluded.
class _Destination extends StatelessWidget {
  const _Destination({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !active,
    child: TickerMode(
      enabled: active,
      child: ExcludeFocus(excluding: !active, child: child),
    ),
  );
}

class FlareConversationListContainer extends StatelessWidget {
  const FlareConversationListContainer({
    super.key,
    required this.child,
    this.state = const FlareViewState(status: FlareViewStatus.ready),
    this.header,
    this.search,
    this.filters,
    this.pinned,
    this.archived,
    this.footer,
    this.loadingMore = false,
    this.onRetry,
    this.onLoadMore,
    this.onRefresh,
    this.emptyTitle,
    this.label,
  });
  final Widget child;
  final FlareViewState<List<Object?>> state;
  final Widget? header, search, filters, pinned, archived, footer;
  final bool loadingMore;
  final VoidCallback? onRetry, onLoadMore;

  /// Pull the ready list down to ask the host for fresh data; the gesture ends when the
  /// future completes. Without it the list does not take the gesture at all.
  final Future<void> Function()? onRefresh;

  /// The container's own words for an empty list; `state.emptyTitle` overrides it per state.
  final String? emptyTitle;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final presentation = flareViewPresentation(state.status, state.stale);
    final content = onRefresh == null
        ? child
        : RefreshIndicator(onRefresh: onRefresh!, child: child);
    Widget body = switch (presentation) {
      FlareViewPresentation.content => content,
      // A failed refresh over rows worth keeping: the failure is a banner, the rows stay readable.
      FlareViewPresentation.contentWithNotice => Column(
        children: [
          FlareStatusBanner(
            text: state.error ?? '',
            tone: state.status == FlareViewStatus.error
                ? FlareStatusTone.danger
                : FlareStatusTone.neutral,
            actionText: onRetry == null ? null : FlareStrings.of(context).retry,
            onAction: onRetry,
          ),
          Expanded(child: content),
        ],
      ),
      FlareViewPresentation.state => switch (state.status) {
        FlareViewStatus.empty => Center(
          child: Text(
            state.emptyTitle ?? emptyTitle ?? '',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        FlareViewStatus.error || FlareViewStatus.offline => Center(
          child: IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            tooltip: state.error,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    };
    return Semantics(
      container: true,
      label: label,
      child: Column(
        children: [
          if (header != null) header!,
          if (search != null) search!,
          if (filters != null) filters!,
          if (pinned != null && state.status == FlareViewStatus.ready) pinned!,
          Expanded(child: body),
          if (archived != null && state.status == FlareViewStatus.ready)
            archived!,
          if (state.hasMore && !loadingMore && onLoadMore != null)
            IconButton(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more),
            ),
          if (loadingMore) const LinearProgressIndicator(),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class FlareFriendListContainer extends FlareConversationListContainer {
  const FlareFriendListContainer({
    super.key,
    required super.child,
    super.state,
    super.header,
    super.search,
    super.filters,
    super.pinned,
    super.archived,
    super.footer,
    super.loadingMore,
    super.onRetry,
    super.onLoadMore,
    super.onRefresh,
    super.emptyTitle,
    super.label,
  });
}
