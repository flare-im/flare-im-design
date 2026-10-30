import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plural.dart';
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

/// The actions that forward the selection: they count and report only its
/// forwardable ids.
extension FlareMessageBatchForward on FlareMessageBatchAction {
  bool get forwards =>
      this == FlareMessageBatchAction.forwardEach ||
      this == FlareMessageBatchAction.forwardMerged;
}

/// The ids an action works on (`spec/message-batch-vectors.json` forward): for
/// a forward action the selection minus [unforwardableIds] — the ids the core
/// answers canForward false for — in selection order; for any other action the
/// whole selection.
List<String> messageBatchActionIds(
  FlareMessageBatchAction action,
  List<String> selectedIds, [
  Set<String> unforwardableIds = const {},
]) {
  if (!action.forwards || unforwardableIds.isEmpty) {
    return List<String>.from(selectedIds);
  }
  return selectedIds
      .where((id) => !unforwardableIds.contains(id))
      .toList(growable: false);
}

/// How many of the selected ids cannot be forwarded: the count the toolbar's
/// hint shows.
int messageBatchUnforwardableCount(
  List<String> selectedIds, [
  Set<String> unforwardableIds = const {},
]) => selectedIds.toSet().intersection(unforwardableIds).length;

/// Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same
/// table on four kits): empty while busy or with nothing selected; otherwise the
/// capability-enabled actions in canonical order, minus those too few ids are left for —
/// a forward action counts only the forwardable ids (the selection minus
/// [unforwardableIds]), every other action the whole selection.
List<FlareMessageBatchAction> messageBatchActionsAvailable(
  List<String> selectedIds,
  FlareMessageBatchCapabilities? capabilities,
  bool busy, [
  Set<String> unforwardableIds = const {},
]) {
  if (busy || selectedIds.isEmpty || capabilities == null) return const [];
  return FlareMessageBatchAction.values
      .where(
        (action) =>
            capabilities.allows(action) &&
            messageBatchActionIds(
                  action,
                  selectedIds,
                  unforwardableIds,
                ).length >=
                (flareMessageBatchMinimumSelection[action] ?? 1),
      )
      .toList(growable: false);
}

/// Multi-select batch toolbar over a set of chosen messages. Same contract as
/// [FlareConversationBatchToolbar] (FR-034): the host declares what it can do over the
/// selection and the toolbar reports one action with the ids; selecting all and clearing
/// the selection stay their own callbacks, because they change the selection, not the world.
/// [unforwardableIds] are selected ids the core answers canForward false for: the forward
/// keys leave them out, and the count says how many there are.
/// Spec: Message/MessageBatchToolbar (`FlareMessageBatchToolbar`).
class FlareMessageBatchToolbar extends StatelessWidget {
  const FlareMessageBatchToolbar({
    super.key,
    required this.selectedIds,
    required this.total,
    required this.capabilities,
    this.unforwardableIds = const {},
    this.busy = false,
    this.onAction,
    this.onSelectAll,
    this.onClearSelection,
    this.onExit,
  });

  final List<String> selectedIds;
  final int total;
  final FlareMessageBatchCapabilities capabilities;

  /// Selected ids the core answers canForward false for (a plugin card that is
  /// not forwardable).
  final Set<String> unforwardableIds;
  final bool busy;
  final void Function(FlareMessageBatchAction action, List<String> ids)?
  onAction;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onExit;

  /// The meta's count of selected messages the forward keys leave out.
  static const Key unforwardableKey = ValueKey('flare-batch-unforwardable');

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final count = selectedIds.length;
    final available = messageBatchActionsAvailable(
      selectedIds,
      capabilities,
      busy,
      unforwardableIds,
    );
    final unforwardable = messageBatchUnforwardableCount(
      selectedIds,
      unforwardableIds,
    );
    final locale = flareCopyLocaleOf(context);
    final visible = FlareMessageBatchAction.values
        .where(capabilities.allows)
        .toList(growable: false);
    return _MessageBatchExitScope(
      onExit: onExit,
      busy: busy,
      child: Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FlareSizes.spacing3xs,
                children: [
                  Text.rich(
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
                  // The forward keys leave these out: say how many.
                  if (unforwardable > 0)
                    Text(
                      strings.messageBatchUnforwardableCount(
                        unforwardable,
                        locale,
                      ),
                      key: unforwardableKey,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeXs,
                      ),
                    ),
                ],
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
                      onTap: () => onAction?.call(
                        action,
                        messageBatchActionIds(
                          action,
                          selectedIds,
                          unforwardableIds,
                        ),
                      ),
                    ),
                  _exitButton(colors, strings.messageBatchExit),
                ],
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacing2sm,
              ),
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

/// The toolbar being on screen is the selection being on: the system back and a hardware
/// keyboard's Escape leave the selection before they leave the chat. While [busy] both are
/// consumed and nothing exits — the same rule as the disabled exit key. Without an [onExit]
/// handler nothing is claimed.
///
/// Escape is read from [HardwareKeyboard] rather than a [Shortcuts] binding: shortcuts only see
/// keys while focus is inside their subtree, and the toolbar never holds focus (its keys are
/// gesture targets) — in a chat the focus is in the composer or nowhere. The handler steps aside
/// when another route is on top or an editable control has focus (its own Escape comes first),
/// so nothing here fires under a dialog or while typing.
class _MessageBatchExitScope extends StatefulWidget {
  const _MessageBatchExitScope({
    required this.onExit,
    required this.busy,
    required this.child,
  });

  final VoidCallback? onExit;
  final bool busy;
  final Widget child;

  @override
  State<_MessageBatchExitScope> createState() => _MessageBatchExitScopeState();
}

class _MessageBatchExitScopeState extends State<_MessageBatchExitScope> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    final onExit = widget.onExit;
    if (onExit == null || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    if (!widget.busy) onExit();
    return true;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.onExit == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !widget.busy) widget.onExit?.call();
    },
    child: widget.child,
  );
}
