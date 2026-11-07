import 'package:flutter/material.dart';

import '../../tokens/flare_strings.dart';
import '../../tokens/flare_tokens.dart';
import '../action_icon.dart';
import '../flare_icon.dart' show flareIconMap;

/// Where a "+" tile comes from: a built-in [feature] the tenant's feature
/// switches control, or a [plugin] — the composer-action an authorised plugin
/// declares. Contract `composerActions.kinds`.
enum FlareComposerActionKind { feature, plugin }

/// The generic plugin glyph: a tile whose [FlareComposerAction.icon] is not a
/// registry name draws this instead.
const String flareComposerPluginIcon = 'plugin';

/// One attachment/action tile in [FlareComposerActionPanel].
///
/// [id] is the stable, cross-platform action identifier (contract
/// `composerActions`: image, camera, video, file, location, card, poll, vote,
/// task, schedule, link, announcement, notification, miniProgram, translate).
/// [label] is optional — when omitted the kit resolves it from [FlareStrings]
/// via [resolveLabel], so the default set never hard-codes a language and the
/// built-in items of a composer menu pass through as they come.
class FlareComposerAction {
  const FlareComposerAction({
    required this.id,
    this.label,
    required this.icon,
    this.kind,
    this.group,
    this.order,
    this.visible = true,
    this.enabled = true,
    this.badge,
    this.intent,
    this.accessibilityLabel,
    this.disabledReason,
  });

  /// Stable action identifier (contract field `id`).
  final String id;

  /// Host-provided label override. `null` ⇒ resolved from [FlareStrings].
  final String? label;

  /// A semantic icon name from `flareIconNames`; an unknown name draws
  /// [flareComposerPluginIcon] (see [resolvedIcon]).
  final String icon;

  /// Built-in feature or plugin entry; null for a host's own tile.
  final FlareComposerActionKind? kind;
  final String? group;
  final int? order;
  final bool visible;
  final bool enabled;
  final String? badge;
  final String? intent;
  final String? accessibilityLabel;
  final String? disabledReason;

  /// The label to render: [label] if given, else the [FlareStrings] entry
  /// matching [id]; unknown ids fall back to the raw id so nothing renders
  /// blank.
  String resolveLabel(FlareStrings strings) {
    if (label != null) return label!;
    return switch (id) {
      'image' => strings.actionImage,
      'camera' => strings.actionCamera,
      'voice' => strings.composerVoiceInput,
      'video' => strings.actionVideo,
      'file' => strings.actionFile,
      'location' => strings.actionLocation,
      'contact' => strings.actionCard,
      'card' => strings.actionCard,
      'poll' => strings.actionVote,
      'vote' => strings.actionVote,
      'task' => strings.actionTask,
      'schedule' => strings.actionSchedule,
      'link' => strings.actionLink,
      'announcement' => strings.actionAnnouncement,
      'notification' => strings.actionNotification,
      'miniProgram' => strings.actionMiniProgram,
      'translate' => strings.actionTranslate,
      _ => id,
    };
  }

  /// The registry name the tile draws, the same rule on all four platforms:
  /// a name the registry does not know (a plugin's own icon name, a typo)
  /// draws the generic [flareComposerPluginIcon] rather than a "missing glyph"
  /// mark.
  String get resolvedIcon =>
      flareIconMap.containsKey(icon) ? icon : flareComposerPluginIcon;
}

/// Business availability supplied by the host. An omitted set allows all ids.
class FlareComposerCapabilities {
  const FlareComposerCapabilities({
    this.availableActionIds,
    this.availableToolIds,
  });
  final Set<String>? availableActionIds;

  /// Host-owned availability, not an authorization decision. Null keeps the
  /// default toolbar; IDs: emoji, mention, voice, image, richText, attachments.
  final Set<String>? availableToolIds;

  bool allowsTool(String id) => availableToolIds?.contains(id) ?? true;
}

/// Defaults -> capabilities -> host list. A host list is a full replacement.
List<FlareComposerAction> resolveFlareComposerActions({
  List<FlareComposerAction> defaults = FlareComposerActionPanel.defaultActions,
  FlareComposerCapabilities capabilities = const FlareComposerCapabilities(),
  List<FlareComposerAction>? actions,
}) {
  final seen = <String>{};
  final indexed = (actions ?? defaults)
      .asMap()
      .entries
      .where((entry) {
        final action = entry.value;
        if (!action.visible || action.id.isEmpty || !seen.add(action.id))
          return false;
        return capabilities.availableActionIds?.contains(action.id) ?? true;
      })
      .toList(growable: false);
  indexed.sort((left, right) {
    final result = (left.value.order ?? left.key).compareTo(
      right.value.order ?? right.key,
    );
    return result != 0 ? result : left.key.compareTo(right.key);
  });
  return indexed.map((entry) => entry.value).toList(growable: false);
}

/// How [FlareComposerActionPanel] lays out: a phone pages the grid sideways, a
/// desktop shows at most [FlareComposerActionPanel.rows] rows and scrolls the
/// rest inside the panel.
enum FlareComposerPanelFormFactor { mobile, desktop }

/// The composer's bottom function area (下方功能区) — an inline, expandable grid
/// of attachment actions (image / file / card / vote / …). A composable part:
/// wrap it in an [AnimatedSize]/visibility to expand under the input, or use it
/// standalone. This is the one attachment grid; the message long-press sheet
/// is [FlareMessageActionSheet].
///
/// Items are ordered by `order`, then by position. On a phone ([formFactor]
/// mobile) the grid pages sideways, [rows] × [crossAxisCount] per page, with
/// page dots; on a desktop it shows at most [rows] rows and scrolls. A new list
/// keeps the page the reader is on (clamped when pages go away); a tile that
/// appears fades in (150 ms, none with reduced motion).
class FlareComposerActionPanel extends StatefulWidget {
  const FlareComposerActionPanel({
    super.key,
    this.actions,
    this.capabilities = const FlareComposerCapabilities(),
    this.crossAxisCount = 4,
    this.onAction,
    this.formFactor = FlareComposerPanelFormFactor.mobile,
    this.rows,
  }) : assert(crossAxisCount > 0),
       assert(rows == null || rows > 0);

  final List<FlareComposerAction>? actions;
  final FlareComposerCapabilities capabilities;
  final int crossAxisCount;
  final FlareComposerPanelFormFactor formFactor;

  /// Rows per page on a phone (default 2), most rows shown on a desktop
  /// (default 3).
  final int? rows;
  final void Function(FlareComposerAction action)? onAction;

  /// Height of one row of tiles.
  static const double rowExtent = 76;

  /// The built-in features of the panel, in the order every platform shows
  /// them (contract `composerActions.defaults`). Labels come from
  /// [FlareStrings]; a host list replaces the set whole. Polls come from the
  /// poll plugin, not from this set (PollComposer and VoteMessage stay for
  /// history).
  static const List<FlareComposerAction> defaultActions = [
    FlareComposerAction(
      id: 'image',
      icon: 'image',
      kind: FlareComposerActionKind.feature,
    ),
    FlareComposerAction(
      id: 'camera',
      icon: 'camera',
      kind: FlareComposerActionKind.feature,
    ),
    FlareComposerAction(
      id: 'video',
      icon: 'video',
      kind: FlareComposerActionKind.feature,
    ),
    FlareComposerAction(
      id: 'file',
      icon: 'file',
      kind: FlareComposerActionKind.feature,
    ),
    FlareComposerAction(
      id: 'voice',
      icon: 'mic',
      kind: FlareComposerActionKind.feature,
    ),
    FlareComposerAction(
      id: 'location',
      icon: 'location',
      kind: FlareComposerActionKind.feature,
    ),
    FlareComposerAction(
      id: 'card',
      icon: 'card',
      kind: FlareComposerActionKind.feature,
    ),
  ];

  @override
  State<FlareComposerActionPanel> createState() =>
      _FlareComposerActionPanelState();
}

class _FlareComposerActionPanelState extends State<FlareComposerActionPanel> {
  final PageController _pages = PageController();
  int _page = 0;

  /// Ids drawn so far: a tile not among them fades in. The first frame draws
  /// without a fade.
  final Set<String> _seen = {};
  bool _built = false;

  bool get _paged => widget.formFactor == FlareComposerPanelFormFactor.mobile;
  int get _rows => widget.rows ?? (_paged ? 2 : 3);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final resolvedActions = resolveFlareComposerActions(
      actions: widget.actions,
      capabilities: widget.capabilities,
    );
    final fresh = {
      if (_built)
        for (final action in resolvedActions)
          if (!_seen.contains(action.id)) action.id,
    };
    _built = true;
    _seen
      ..clear()
      ..addAll(resolvedActions.map((action) => action.id));
    Widget tile(FlareComposerAction action) => _FadeIn(
      key: ValueKey(action.id),
      animate: fresh.contains(action.id) && !reduceMotion,
      child: _tile(action, colors, strings),
    );
    final height =
        _rows * FlareComposerActionPanel.rowExtent +
        (_rows - 1) * FlareSizes.spacingLg;
    final Widget body;
    if (_paged) {
      final size = _rows * widget.crossAxisCount;
      final pages = <List<FlareComposerAction>>[
        for (var i = 0; i < resolvedActions.length; i += size)
          resolvedActions.sublist(
            i,
            (i + size).clamp(0, resolvedActions.length),
          ),
      ];
      final page = _page.clamp(0, pages.isEmpty ? 0 : pages.length - 1);
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: PageView.builder(
              controller: _pages,
              itemCount: pages.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => _grid(pages[index], tile),
            ),
          ),
          if (pages.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      AnimatedContainer(
                        key: ValueKey('flare-action-panel-dot-$i'),
                        duration: reduceMotion
                            ? Duration.zero
                            : FlareMotion.fast,
                        margin: const EdgeInsets.symmetric(
                          horizontal: FlareSizes.spacing3xs,
                        ),
                        width: i == page ? 12 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == page
                              ? colors.primary
                              : colors.borderPrimary,
                          borderRadius: BorderRadius.circular(
                            FlareSizes.radiusFull,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: SingleChildScrollView(child: _grid(resolvedActions, tile)),
      );
    }
    return Container(
      width: double.infinity,
      color: colors.bgPrimary,
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: body,
    );
  }

  Widget _grid(
    List<FlareComposerAction> actions,
    Widget Function(FlareComposerAction action) tile,
  ) {
    final rows = <List<FlareComposerAction>>[
      for (var i = 0; i < actions.length; i += widget.crossAxisCount)
        actions.sublist(
          i,
          (i + widget.crossAxisCount).clamp(0, actions.length),
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : FlareSizes.spacingLg),
            child: SizedBox(
              height: FlareComposerActionPanel.rowExtent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in rows[r]) Expanded(child: tile(a)),
                  for (var k = rows[r].length; k < widget.crossAxisCount; k++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tile(
    FlareComposerAction action,
    FlareColors colors,
    FlareStrings strings,
  ) {
    return Semantics(
      button: true,
      enabled: action.enabled,
      label: action.accessibilityLabel ?? action.resolveLabel(strings),
      hint: action.enabled ? null : action.disabledReason,
      child: InkWell(
        onTap: action.enabled ? () => widget.onAction?.call(action) : null,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              ),
              child: Icon(
                flareIconGlyph(action.resolvedIcon),
                color: colors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingXs),
            Text(
              action.resolveLabel(strings),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeXs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades a tile in once, when it first appears in the panel.
class _FadeIn extends StatefulWidget {
  const _FadeIn({super.key, required this.animate, required this.child});
  final bool animate;
  final Widget child;
  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FlareMotion.fast,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _controller, child: widget.child);
}
