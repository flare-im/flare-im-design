import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// One attachment/action tile in [FlareMessageActionSheet] /
/// `FlareComposerActionPanel`.
///
/// [id] is the stable, cross-platform action identifier (contract
/// `composerActions`: image, camera, video, file, location, card, vote, task,
/// schedule, link, announcement, notification, miniProgram, translate). [label]
/// is optional — when omitted the kit resolves it from [FlareStrings] via
/// [resolveLabel], so the default set never hard-codes a language.
class FlareComposerAction {
  const FlareComposerAction({
    String? id,
    @Deprecated('Use id; key is forwarded to it and will be removed.')
    String? key,
    this.label,
    required this.icon,
  })  : assert(id != null || key != null, 'FlareComposerAction needs an id'),
        id = id ?? key ?? '';

  /// Stable action identifier (contract field `id`).
  final String id;

  /// Legacy name of [id].
  @Deprecated('Use id; key is forwarded to it and will be removed.')
  String get key => id;

  /// Host-provided label override. `null` ⇒ resolved from [FlareStrings].
  final String? label;
  final IconData icon;

  /// The label to render: [label] if given, else the [FlareStrings] entry
  /// matching [id]; unknown ids fall back to the raw id so nothing renders
  /// blank.
  String resolveLabel(FlareStrings strings) {
    if (label != null) return label!;
    return switch (id) {
      'image' => strings.actionImage,
      'camera' => strings.actionCamera,
      'video' => strings.actionVideo,
      'file' => strings.actionFile,
      'location' => strings.actionLocation,
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

/// The attachment "+" action grid — image, file, card, vote, location, etc.
/// Spec: Composer/MessageActionSheet (`FlareMessageActionSheet`). Emits the
/// chosen action; the host builds the content message.
class FlareMessageActionSheet extends StatelessWidget {
  const FlareMessageActionSheet({
    super.key,
    this.actions = defaultActions,
    this.onAction,
  });

  final List<FlareComposerAction> actions;
  final void Function(FlareComposerAction action)? onAction;

  /// Core default set shared by all platforms (labels come from
  /// [FlareStrings]; the host passes its own `actions` to add or reorder).
  static const List<FlareComposerAction> defaultActions = [
    FlareComposerAction(id: 'image', icon: Icons.image_outlined),
    FlareComposerAction(id: 'camera', icon: Icons.camera_alt_outlined),
    FlareComposerAction(id: 'file', icon: Icons.folder_outlined),
    FlareComposerAction(id: 'location', icon: Icons.location_on_outlined),
    FlareComposerAction(id: 'card', icon: Icons.contact_page_outlined),
    FlareComposerAction(id: 'vote', icon: Icons.how_to_vote_outlined),
    FlareComposerAction(id: 'task', icon: Icons.checklist_rounded),
    FlareComposerAction(id: 'schedule', icon: Icons.event_outlined),
  ];

  /// Convenience: present this sheet as a modal bottom sheet and return the
  /// chosen action (or null if dismissed).
  static Future<FlareComposerAction?> show(
    BuildContext context, {
    List<FlareComposerAction> actions = defaultActions,
  }) {
    return showModalBottomSheet<FlareComposerAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlareMessageActionSheet(
        actions: actions,
        onAction: (a) => Navigator.of(ctx).pop(a),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final strings = FlareStrings.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        child: LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 340 ? 3 : 4;
          final labelHeight = MediaQuery.textScalerOf(context).scale(12) * 2.4;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 64 + labelHeight,
              mainAxisSpacing: FlareSizes.spacingMd,
              crossAxisSpacing: FlareSizes.spacingMd,
            ),
            shrinkWrap: true,
            itemCount: actions.length,
            itemBuilder: (context, index) =>
                _tile(actions[index], colors, strings),
          );
        }),
      ),
    );
  }

  Widget _tile(
      FlareComposerAction action, FlareColors colors, FlareStrings strings) {
    return InkWell(
      onTap: () => onAction?.call(action),
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
            child: Icon(action.icon, color: colors.textPrimary, size: 24),
          ),
          const SizedBox(height: FlareSizes.spacingXs),
          Text(action.resolveLabel(strings),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: FlareSizes.fontSizeXs)),
        ],
      ),
    );
  }
}
