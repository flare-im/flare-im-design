import 'package:flutter/material.dart';

import '../../tokens/flare_tokens.dart';
import '../flare_message_action_sheet.dart'
    show FlareComposerAction, FlareMessageActionSheet;

/// The composer's bottom function area (下方功能区) — an inline, expandable grid
/// of attachment actions (image / file / card / vote / …). A composable part:
/// wrap it in an [AnimatedSize]/visibility to expand under the input, or use it
/// standalone. Shares [FlareComposerAction] with the action sheet.
class FlareComposerActionPanel extends StatelessWidget {
  const FlareComposerActionPanel({
    super.key,
    this.actions = defaultActions,
    this.crossAxisCount = 4,
    this.onAction,
  });

  final List<FlareComposerAction> actions;
  final int crossAxisCount;
  final void Function(FlareComposerAction action)? onAction;

  static const List<FlareComposerAction> defaultActions =
      FlareMessageActionSheet.defaultActions;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final rows = <List<FlareComposerAction>>[];
    for (var i = 0; i < actions.length; i += crossAxisCount) {
      rows.add(actions.sublist(
          i, (i + crossAxisCount).clamp(0, actions.length)));
    }
    return Container(
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
                  for (final a in row) Expanded(child: _tile(a, colors)),
                  for (var k = row.length; k < crossAxisCount; k++)
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
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
