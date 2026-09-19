import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// Batch actions a host may expose over a multi-selection of messages.
enum FlareMessageBatchAction {
  forwardEach,
  forwardMerged,
  pin,
  pinSelf,
  delete,
}

/// Host-declared capabilities; a false entry hides the action entirely.
@immutable
class FlareMessageBatchCapabilities {
  const FlareMessageBatchCapabilities({
    this.forwardEach = false,
    this.forwardMerged = false,
    this.pin = false,
    this.pinSelf = false,
    this.delete = false,
  });
  final bool forwardEach, forwardMerged, pin, pinSelf, delete;

  bool allows(FlareMessageBatchAction action) => switch (action) {
    FlareMessageBatchAction.forwardEach => forwardEach,
    FlareMessageBatchAction.forwardMerged => forwardMerged,
    FlareMessageBatchAction.pin => pin,
    FlareMessageBatchAction.pinSelf => pinSelf,
    FlareMessageBatchAction.delete => delete,
  };
}

/// What an action needs to mean anything: merging messages into one card needs two.
const Map<FlareMessageBatchAction, int> flareMessageBatchMinimumSelection = {
  FlareMessageBatchAction.forwardMerged: 2,
};

/// Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same
/// table on four kits): empty while busy or with nothing selected; otherwise the
/// capability-enabled actions in canonical order, minus those the selection is too small for.
List<FlareMessageBatchAction> messageBatchActionsAvailable(
  List<String> selectedIds,
  FlareMessageBatchCapabilities? capabilities,
  bool busy,
) {
  if (busy || selectedIds.isEmpty || capabilities == null) return const [];
  return FlareMessageBatchAction.values
      .where(
        (action) =>
            capabilities.allows(action) &&
            selectedIds.length >=
                (flareMessageBatchMinimumSelection[action] ?? 1),
      )
      .toList(growable: false);
}

/// Multi-select batch toolbar over a set of chosen messages. Same contract as
/// [FlareConversationBatchToolbar] (FR-034): the host declares what it can do over the
/// selection and the toolbar reports one action with the ids; selecting all and clearing
/// the selection stay their own callbacks, because they change the selection, not the world.
/// Spec: Message/MessageBatchToolbar (`FlareMessageBatchToolbar`).
class FlareMessageBatchToolbar extends StatelessWidget {
  const FlareMessageBatchToolbar({
    super.key,
    required this.selectedIds,
    required this.total,
    required this.capabilities,
    this.busy = false,
    this.onAction,
    this.onSelectAll,
    this.onClearSelection,
    this.onExit,
  });

  final List<String> selectedIds;
  final int total;
  final FlareMessageBatchCapabilities capabilities;
  final bool busy;
  final void Function(FlareMessageBatchAction action, List<String> ids)?
  onAction;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final count = selectedIds.length;
    final available = messageBatchActionsAvailable(
      selectedIds,
      capabilities,
      busy,
    );
    final visible = FlareMessageBatchAction.values
        .where(capabilities.allows)
        .toList(growable: false);
    return Container(
      // Every key sits in a touch-target-tall run, and the exit key's target
      // reaches past the key to the toolbar's end edge, so the toolbar gives
      // that difference back to keep its height and inset.
      padding: const EdgeInsetsDirectional.fromSTEB(
        14,
        10 - _targetInset,
        0,
        10 - _targetInset,
      ),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1415131C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // At large text sizes the count wraps instead of starving the keys.
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$count',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / $total · ${strings.selectedSuffix}',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: FlareSizes.fontSizeMd),
            ),
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: FlareSizes.spacingSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _button(
                  colors,
                  icon: Icons.done_all,
                  label: strings.selectAll,
                  disabled: total == 0 || busy,
                  onTap: onSelectAll,
                ),
                _button(
                  colors,
                  icon: flareIconGlyph('close'),
                  label: strings.messageBatchClear,
                  disabled: count == 0 || busy,
                  onTap: onClearSelection,
                ),
                for (final action in visible)
                  _button(
                    colors,
                    icon: _icon(action),
                    label: _label(action, strings),
                    color: action == FlareMessageBatchAction.delete
                        ? colors.error
                        : null,
                    disabled: !available.contains(action),
                    onTap: () =>
                        onAction?.call(action, List<String>.from(selectedIds)),
                  ),
                _exitButton(colors, strings.messageBatchExit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(FlareMessageBatchAction action) => switch (action) {
    FlareMessageBatchAction.forwardEach => flareIconGlyph('forward'),
    FlareMessageBatchAction.forwardMerged => flareIconGlyph('merge-forward'),
    FlareMessageBatchAction.pin => flareIconGlyph('pin'),
    FlareMessageBatchAction.pinSelf => flareIconGlyph('pin-self'),
    FlareMessageBatchAction.delete => flareIconGlyph('delete'),
  };

  static String _label(FlareMessageBatchAction action, FlareStrings strings) =>
      switch (action) {
        FlareMessageBatchAction.forwardEach => strings.forwardEach,
        FlareMessageBatchAction.forwardMerged => strings.forwardMerged,
        FlareMessageBatchAction.pin => strings.messageBatchPin,
        FlareMessageBatchAction.pinSelf => strings.messageBatchPinSelf,
        FlareMessageBatchAction.delete => strings.delete,
      };

  static const double _key = 32;

  /// How far the exit control's touch target reaches past its key on each side.
  static const double _targetInset = (FlareSizes.touchTarget - _key) / 2;

  Widget _button(
    FlareColors colors, {
    required IconData icon,
    required String label,
    required bool disabled,
    Color? color,
    VoidCallback? onTap,
  }) {
    final fg = disabled ? colors.textTertiary : (color ?? colors.textPrimary);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        behavior: HitTestBehavior.opaque,
        // A touch target tall, like the exit key beside it; the key itself
        // keeps its 32-point look.
        child: SizedBox(
          height: FlareSizes.touchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: _key,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: FlareSizes.spacingXs),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The key starts where the gap after the last action ends; its touch target
  /// reaches past it toward the toolbar's edge.
  Widget _exitButton(FlareColors colors, String label) {
    return FlareIconControl(
      label: label,
      onTap: onExit,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: _key,
        width: _key,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        ),
        child: FlareIcon(
          'close',
          size: FlareSizes.iconSizeSm,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
