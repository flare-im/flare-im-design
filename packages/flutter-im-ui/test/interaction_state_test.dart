import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composer precedence and allowed actions are deterministic', () {
    expect(
      resolveComposerMode(
        const FlareComposerInteractionInput(
          readOnly: true,
          recording: true,
          online: false,
        ),
      ),
      FlareComposerInteractionMode.readOnly,
    );
    expect(
      resolveComposerMode(
        const FlareComposerInteractionInput(
          permissionGranted: false,
          online: false,
        ),
      ),
      FlareComposerInteractionMode.permissionDenied,
    );
    expect(
      composerAllowedActions(FlareComposerInteractionMode.offline),
      isNot(contains(FlareComposerInteractionAction.send)),
    );
  });

  test('message lifecycle outranks transient hover', () {
    expect(
      resolveMessageMode(
        const FlareMessageLifecycle(
          mutation: FlareMessageMutationState.recalled,
        ),
        hovered: true,
      ),
      FlareMessageInteractionMode.recalled,
    );
    expect(
      resolveMessageMode(
        const FlareMessageLifecycle(read: FlareMessageReadState.read),
      ),
      FlareMessageInteractionMode.read,
    );
  });

  test('selection range, shortcuts, and gesture direction are stable', () {
    final anchor = reduceSelection(
      const FlareSelectionState(),
      const FlareSelectionReplace('b'),
    );
    final range = reduceSelection(
      anchor,
      const FlareSelectionExtend('d', ['a', 'b', 'c', 'd']),
    );
    expect(range.selectedIds, {'b', 'c', 'd'});
    expect(
      resolveDesktopShortcut('k', primary: true),
      FlareDesktopShortcutAction.commandPalette,
    );
    expect(
      resolveSwipeIntent(deltaX: 80, deltaY: 70, message: true),
      FlareSwipeIntent.none,
    );
    expect(
      resolveSwipeIntent(deltaX: 80, deltaY: 8, message: true),
      FlareSwipeIntent.reply,
    );
  });

  test('message capabilities follow ownership and terminal lifecycle', () {
    final own = resolveMessageCapabilities(
      const FlareMessageCapabilityInput(
        lifecycle: FlareMessageLifecycle(),
        own: true,
      ),
    );
    expect(own, contains(FlareMessageCapability.edit));
    expect(own, isNot(contains(FlareMessageCapability.report)));
    final recalled = resolveMessageCapabilities(
      const FlareMessageCapabilityInput(
        lifecycle: FlareMessageLifecycle(
          mutation: FlareMessageMutationState.recalled,
        ),
        own: true,
      ),
    );
    expect(recalled, isEmpty);
  });

  test('extended actions and shortcuts share the capability contract', () {
    final actions = resolveMessageCapabilities(
      const FlareMessageCapabilityInput(
        lifecycle: FlareMessageLifecycle(),
        own: true,
        pinned: true,
        hasThread: true,
        hasQuote: true,
        supportsMergeForward: true,
      ),
    );
    expect(
      actions,
      containsAll({
        FlareMessageCapability.unpin,
        FlareMessageCapability.openThread,
        FlareMessageCapability.jumpToQuote,
        FlareMessageCapability.mergeForward,
      }),
    );
    expect(
      resolveDesktopShortcut(
        'f',
        scope: FlareDesktopShortcutScope.conversation,
      ),
      FlareDesktopShortcutAction.forward,
    );
    expect(
      resolveDesktopShortcut(
        't',
        scope: FlareDesktopShortcutScope.conversation,
      ),
      FlareDesktopShortcutAction.openThread,
    );
  });

  test('action presentation stays downstream of availability', () {
    final actions = resolveMessageActions(
      const FlareMessageCapabilityInput(
        lifecycle: FlareMessageLifecycle(),
        own: false,
      ),
      FlareMessageActionPresentation.hoverToolbar,
    );
    expect(
      actions.singleWhere((a) => a.id == FlareMessageCapability.reply).promoted,
      isTrue,
    );
    expect(
      actions.singleWhere((a) => a.id == FlareMessageCapability.report).group,
      FlareMessageActionGroup.destructive,
    );
  });
}
