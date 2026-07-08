import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// One attachment/action tile in [FlareMessageActionSheet].
class FlareComposerAction {
  const FlareComposerAction({
    required this.key,
    required this.label,
    required this.icon,
  });
  final String key;
  final String label;
  final IconData icon;
}

/// The attachment "+" action grid — image, file, card, vote, location, etc.
/// Spec: Composer/MessageActionSheet (`FlareMessageActionSheet`). Emits the
/// chosen action key; the host builds the content message.
class FlareMessageActionSheet extends StatelessWidget {
  const FlareMessageActionSheet({
    super.key,
    this.actions = defaultActions,
    this.onAction,
  });

  final List<FlareComposerAction> actions;
  final void Function(FlareComposerAction action)? onAction;

  static const List<FlareComposerAction> defaultActions = [
    FlareComposerAction(key: 'image', label: '图片', icon: Icons.image_outlined),
    FlareComposerAction(key: 'camera', label: '拍摄', icon: Icons.camera_alt_outlined),
    FlareComposerAction(key: 'file', label: '文件', icon: Icons.folder_outlined),
    FlareComposerAction(key: 'location', label: '位置', icon: Icons.location_on_outlined),
    FlareComposerAction(key: 'card', label: '名片', icon: Icons.contact_page_outlined),
    FlareComposerAction(key: 'vote', label: '投票', icon: Icons.how_to_vote_outlined),
    FlareComposerAction(key: 'task', label: '任务', icon: Icons.checklist_rounded),
    FlareComposerAction(key: 'schedule', label: '日程', icon: Icons.event_outlined),
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
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: FlareSizes.spacingLg,
          crossAxisSpacing: FlareSizes.spacingLg,
          children: [
            for (final a in actions)
              _tile(a, colors),
          ],
        ),
      ),
    );
  }

  Widget _tile(FlareComposerAction action, FlareColors colors) {
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
            child: Icon(action.icon, color: colors.textPrimary, size: 26),
          ),
          const SizedBox(height: FlareSizes.spacingXs),
          Text(action.label,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: FlareSizes.fontSizeXs)),
        ],
      ),
    );
  }
}
