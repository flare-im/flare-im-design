import 'package:flutter/material.dart';

import '../../tokens/flare_strings.dart';
import '../../tokens/flare_tokens.dart';
import '../action_icon.dart';

/// One attachment/action tile in [FlareComposerActionPanel].
///
/// [id] is the stable, cross-platform action identifier (contract
/// `composerActions`: image, camera, video, file, location, card, vote, task,
/// schedule, link, announcement, notification, miniProgram, translate). [label]
/// is optional — when omitted the kit resolves it from [FlareStrings] via
/// [resolveLabel], so the default set never hard-codes a language.
class FlareComposerAction {
  const FlareComposerAction({
    required this.id,
    this.label,
    required this.icon,
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

  /// A semantic icon name from `flareIconNames`.
  final String icon;
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
}

/// Business availability supplied by the host. An omitted set allows all ids.
class FlareComposerCapabilities {
  const FlareComposerCapabilities({this.availableActionIds});
  final Set<String>? availableActionIds;
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

/// The composer's bottom function area (下方功能区) — an inline, expandable grid
/// of attachment actions (image / file / card / vote / …). A composable part:
/// wrap it in an [AnimatedSize]/visibility to expand under the input, or use it
/// standalone. This is the one attachment grid; the message long-press sheet
/// is [FlareMessageActionSheet].
class FlareComposerActionPanel extends StatelessWidget {
  const FlareComposerActionPanel({
    super.key,
    this.actions,
    this.capabilities = const FlareComposerCapabilities(),
    this.crossAxisCount = 4,
    this.onAction,
    this.maxHeight = 240,
  }) : assert(crossAxisCount > 0),
       assert(maxHeight > 0);

  final List<FlareComposerAction>? actions;
  final FlareComposerCapabilities capabilities;
  final int crossAxisCount;
  final double maxHeight;
  final void Function(FlareComposerAction action)? onAction;

  /// Default action set shared by all platforms (labels come from
  /// [FlareStrings]; the host passes its own `actions` to add or reorder).
  static const List<FlareComposerAction> defaultActions = [
    FlareComposerAction(id: 'image', icon: 'image'),
    FlareComposerAction(id: 'file', icon: 'folder'),
    FlareComposerAction(id: 'voice', icon: 'mic'),
    FlareComposerAction(id: 'location', icon: 'location'),
    FlareComposerAction(id: 'contact', icon: 'card'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final resolvedActions = resolveFlareComposerActions(
      actions: actions,
      capabilities: capabilities,
    );
    final rows = <List<FlareComposerAction>>[];
    for (var i = 0; i < resolvedActions.length; i += crossAxisCount) {
      rows.add(
        resolvedActions.sublist(
          i,
          (i + crossAxisCount).clamp(0, resolvedActions.length),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: colors.bgPrimary,
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: FlareSizes.spacingLg),
                  child: Row(
                    children: [
                      for (final a in row)
                        Expanded(child: _tile(a, colors, strings)),
                      for (var k = row.length; k < crossAxisCount; k++)
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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
        onTap: action.enabled ? () => onAction?.call(action) : null,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              ),
              child: Icon(
                flareIconGlyph(action.icon),
                color: colors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingXs),
            Text(
              action.resolveLabel(strings),
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
