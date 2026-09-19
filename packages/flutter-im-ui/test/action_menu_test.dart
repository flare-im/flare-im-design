import 'dart:ui' show SemanticsRole;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _byTypeName(String name) =>
    find.byWidgetPredicate((widget) => widget.runtimeType.toString() == name);

final _menu = _byTypeName('_ActionMenuPanel');
final _separators = _byTypeName('_ActionMenuSeparator');

const _fine = FlarePlatformCapabilities(pointer: FlarePointerKind.fine);
const _coarse = FlarePlatformCapabilities(pointer: FlarePointerKind.coarse);
const _phone = FlarePlatformCapabilities(
  pointer: FlarePointerKind.coarse,
  bottomSheet: true,
);

String? get _focusedItem => FocusManager.instance.primaryFocus?.debugLabel;

/// A trigger at [alignment] opening a menu of [items]; [capabilities] installs a
/// platform adapter (none when null).
Widget _host({
  required List<FlareActionItem> items,
  ValueChanged<String>? onSelected,
  FlareActionMenuPresentation presentation =
      FlareActionMenuPresentation.anchored,
  FlarePlatformCapabilities? capabilities = _coarse,
  Alignment alignment = Alignment.topRight,
  FocusNode? triggerFocus,
  void Function(BuildContext)? onTriggerBuilt,
}) {
  Widget body = Scaffold(
    body: Align(
      alignment: alignment,
      child: FlareActionMenu(
        items: items,
        label: 'Conversation',
        presentation: presentation,
        onSelected: onSelected ?? (_) {},
        builder: (context, open) {
          onTriggerBuilt?.call(context);
          return TextButton(
            focusNode: triggerFocus,
            onPressed: open,
            child: const Text('Open'),
          );
        },
      ),
    ),
  );
  if (capabilities != null) {
    body = FlarePlatformScope(
      adapter: FlareUnsupportedPlatformAdapter(capabilities: capabilities),
      child: body,
    );
  }
  return MaterialApp(home: body);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  final colors = FlareColors.resolve(Brightness.light);

  testWidgets('host order is kept and a separator opens each new group', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'pin', label: 'Pin', group: 'state'),
          // No group: stays in the current one.
          FlareActionItem(id: 'mute', label: 'Mute'),
          FlareActionItem(id: 'read', label: 'Mark read', group: 'read'),
          FlareActionItem(id: 'archive', label: 'Archive', group: 'read'),
          // Invisible items are left out before grouping: no break here.
          FlareActionItem(
            id: 'ghost',
            label: 'Ghost',
            group: 'other',
            visible: false,
          ),
          FlareActionItem(id: 'clear', label: 'Clear', group: 'read'),
          FlareActionItem(
            id: 'delete',
            label: 'Delete',
            group: 'danger',
            danger: true,
          ),
        ],
      ),
    );
    await _open(tester);

    expect(find.text('Ghost'), findsNothing);
    final labels = ['Pin', 'Mute', 'Mark read', 'Archive', 'Clear', 'Delete'];
    final tops = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dy,
    ];
    expect(tops, [...tops]..sort(), reason: 'drawn in host order');

    expect(_separators, findsNWidgets(2));
    final breaks = [
      for (final element in _separators.evaluate())
        tester.getCenter(find.byWidget(element.widget)).dy,
    ];
    expect(breaks[0], allOf(greaterThan(tops[1]), lessThan(tops[2])));
    expect(breaks[1], allOf(greaterThan(tops[4]), lessThan(tops[5])));
  });

  testWidgets('selecting an enabled item closes the menu, then reports it', (
    tester,
  ) async {
    final selected = <String>[];
    late BuildContext trigger;
    bool? closedWhenReported;
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'pin', label: 'Pin'),
          FlareActionItem(id: 'mute', label: 'Mute'),
        ],
        onTriggerBuilt: (context) => trigger = context,
        onSelected: (id) {
          closedWhenReported = ModalRoute.of(trigger)!.isCurrent;
          selected.add(id);
        },
      ),
    );
    await _open(tester);
    expect(_menu, findsOneWidget);

    await tester.tap(find.text('Mute'));
    await tester.pumpAndSettle();
    expect(selected, ['mute']);
    expect(closedWhenReported, isTrue);
    expect(_menu, findsNothing);
  });

  testWidgets('show completes with the picked id, or null when dismissed', (
    tester,
  ) async {
    late BuildContext trigger;
    await tester.pumpWidget(
      _host(items: const [], onTriggerBuilt: (context) => trigger = context),
    );
    const items = [
      FlareActionItem(id: 'pin', label: 'Pin'),
      FlareActionItem(id: 'mute', label: 'Mute'),
    ];

    final picked = FlareActionMenu.show(trigger, items: items, label: 'Menu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(await picked, 'pin');

    // A tap outside.
    final outside = FlareActionMenu.show(trigger, items: items, label: 'Menu');
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 596));
    await tester.pumpAndSettle();
    expect(_menu, findsNothing);
    expect(await outside, isNull);

    // System back.
    final back = FlareActionMenu.show(trigger, items: items, label: 'Menu');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_menu, findsNothing);
    expect(await back, isNull);
  });

  testWidgets('a menu with no visible item never opens', (tester) async {
    late BuildContext trigger;
    final selected = <String>[];
    await tester.pumpWidget(
      _host(
        items: const [],
        onSelected: selected.add,
        onTriggerBuilt: (context) => trigger = context,
      ),
    );
    await _open(tester);
    expect(_menu, findsNothing);

    final empty = FlareActionMenu.show(trigger, items: const [], label: 'x');
    final hidden = FlareActionMenu.show(
      trigger,
      items: const [FlareActionItem(id: 'a', label: 'A', visible: false)],
      label: 'x',
      presentation: FlareActionMenuPresentation.sheet,
    );
    await tester.pumpAndSettle();
    // Checked before awaiting: a menu that did open would never complete.
    expect(_menu, findsNothing);
    expect(find.byType(FlareBottomSheet), findsNothing);
    expect(await empty, isNull);
    expect(await hidden, isNull);
    expect(selected, isEmpty);
  });

  testWidgets(
    'a disabled item is shown, announced disabled and never reports',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final selected = <String>[];
      await tester.pumpWidget(
        _host(
          items: const [
            FlareActionItem(id: 'pin', label: 'Pin'),
            FlareActionItem(
              id: 'archive',
              label: 'Archive',
              enabled: false,
              disabledReason: 'Read only',
            ),
            FlareActionItem(id: 'mute', label: 'Mute'),
          ],
          onSelected: selected.add,
        ),
      );
      await _open(tester);

      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Read only'), findsOneWidget, reason: 'second line');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Archive\nRead only')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      expect(
        tester.widget<Text>(find.text('Archive')).style?.color,
        colors.textDisabled,
      );

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(_menu, findsOneWidget, reason: 'the menu stays open');
      expect(selected, isEmpty);

      // The keyboard walks past it too.
      expect(_focusedItem, 'FlareActionMenu pin');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedItem, 'FlareActionMenu mute');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, ['mute']);
      semantics.dispose();
    },
  );

  testWidgets('the arrow keys cycle enabled items; Home and End jump', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'off', label: 'Off', enabled: false),
          FlareActionItem(id: 'a', label: 'A'),
          FlareActionItem(id: 'b', label: 'B'),
          FlareActionItem(id: 'c', label: 'C'),
        ],
      ),
    );
    await _open(tester);
    expect(_focusedItem, 'FlareActionMenu a', reason: 'first enabled item');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(_focusedItem, 'FlareActionMenu c', reason: 'wraps to the end');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(_focusedItem, 'FlareActionMenu a', reason: 'wraps to the start');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(_focusedItem, 'FlareActionMenu c');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(_focusedItem, 'FlareActionMenu a');
  });

  testWidgets('Escape closes the menu and focus returns to the trigger', (
    tester,
  ) async {
    final triggerFocus = FocusNode(debugLabel: 'trigger');
    addTearDown(triggerFocus.dispose);
    final selected = <String>[];
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'pin', label: 'Pin'),
          FlareActionItem(id: 'mute', label: 'Mute'),
        ],
        triggerFocus: triggerFocus,
        onSelected: selected.add,
      ),
    );
    triggerFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_menu, findsOneWidget);
    expect(_focusedItem, 'FlareActionMenu pin');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_menu, findsNothing);
    expect(triggerFocus.hasPrimaryFocus, isTrue);
    expect(selected, isEmpty);

    // Selecting hands focus back the same way.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, ['mute']);
    expect(triggerFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('focus is drawn once the keyboard is in use, not after a click', (
    tester,
  ) async {
    final triggerFocus = FocusNode(debugLabel: 'trigger');
    addTearDown(triggerFocus.dispose);
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'pin', label: 'Pin'),
          FlareActionItem(id: 'mute', label: 'Mute'),
        ],
        capabilities: _fine,
        triggerFocus: triggerFocus,
      ),
    );
    // The row's own box is the nearest one around its label.
    Border? ring(String label) =>
        (tester
                        .widget<DecoratedBox>(
                          find
                              .ancestor(
                                of: find.text(label),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .border
            as Border?;

    await tester.tap(find.text('Open'), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(_focusedItem, 'FlareActionMenu pin');
    expect(ring('Pin'), isNull, reason: 'opened by a click');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ring('Pin'), isNull);
    expect(ring('Mute')?.top.color, colors.borderSelected);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    triggerFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_focusedItem, 'FlareActionMenu pin');
    expect(
      ring('Pin')?.top.color,
      colors.borderSelected,
      reason: 'opened by a key',
    );
  });

  testWidgets('a pressed item is checkable: a check and its checked state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'members', label: 'Show members', pressed: true),
          FlareActionItem(id: 'pin', label: 'Pin', pressed: false),
          FlareActionItem(id: 'search', label: 'Search'),
        ],
      ),
    );
    await _open(tester);

    final menu = tester.getSemantics(find.bySemanticsLabel('Conversation'));
    expect(menu.getSemanticsData().role, SemanticsRole.menu);
    expect(
      menu,
      isSemantics(label: 'Conversation', scopesRoute: true, namesRoute: true),
    );

    final checked = tester.getSemantics(find.bySemanticsLabel('Show members'));
    expect(
      checked,
      isSemantics(
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(checked.getSemanticsData().role, SemanticsRole.menuItemCheckbox);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pin')),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    final plain = tester.getSemantics(find.bySemanticsLabel('Search'));
    expect(plain, isSemantics(isButton: true, hasCheckedState: false));
    expect(plain.getSemanticsData().role, SemanticsRole.menuItem);

    // One check, on the pressed item, in the primary text colour.
    final check = find.byIcon(Icons.check_rounded);
    expect(check, findsOneWidget);
    expect(
      (tester.getCenter(check).dy -
              tester.getCenter(find.text('Show members')).dy)
          .abs(),
      lessThan(1),
    );
    expect(tester.widget<Icon>(check).color, colors.primaryText);
    semantics.dispose();
  });

  testWidgets('danger draws the label and icon in the error text colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'pin', label: 'Pin', icon: 'pin'),
          FlareActionItem(
            id: 'delete',
            label: 'Delete',
            icon: 'delete',
            danger: true,
          ),
        ],
      ),
    );
    await _open(tester);
    expect(
      tester.widget<Text>(find.text('Delete')).style?.color,
      colors.errorText,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.delete_outline)).color,
      colors.errorText,
    );
    expect(
      tester.widget<Text>(find.text('Pin')).style?.color,
      colors.textPrimary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.push_pin_outlined)).color,
      colors.textSecondary,
    );
  });

  testWidgets('icons resolve by kit name; labels line up when one is unknown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(id: 'search', label: 'Search', icon: 'search'),
          FlareActionItem(id: 'odd', label: 'Odd', icon: 'no-such-glyph'),
          FlareActionItem(id: 'plain', label: 'Plain'),
        ],
      ),
    );
    await _open(tester);
    // The header's own glyph for `search`, from the shared map.
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    final left = tester.getTopLeft(find.text('Search')).dx;
    expect(tester.getTopLeft(find.text('Odd')).dx, left);
    expect(tester.getTopLeft(find.text('Plain')).dx, left);
  });

  testWidgets('a badge is trailing text; accessibilityLabel names the item', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        items: const [
          FlareActionItem(
            id: 'requests',
            label: 'Join requests',
            badge: '3',
            accessibilityLabel: 'Review join requests',
          ),
        ],
      ),
    );
    await _open(tester);
    expect(
      tester.getTopLeft(find.text('3')).dx,
      greaterThan(tester.getTopRight(find.text('Join requests')).dx),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Review join requests')),
      isSemantics(value: '3', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('rows meet the pointer target; touch and sheets the full one', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const items = [FlareActionItem(id: 'pin', label: 'Pin')];
    double rowHeight() =>
        tester.getSemantics(find.bySemanticsLabel('Pin')).rect.height;

    await tester.pumpWidget(_host(items: items, capabilities: _fine));
    await _open(tester);
    expect(rowHeight(), FlareSizes.touchTargetMin);
    await tester.tapAt(const Offset(4, 596));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(items: items, capabilities: _coarse));
    await _open(tester);
    expect(rowHeight(), FlareSizes.touchTarget);
    await tester.tapAt(const Offset(4, 596));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _host(
        items: items,
        capabilities: _fine,
        presentation: FlareActionMenuPresentation.sheet,
      ),
    );
    await _open(tester);
    expect(find.byType(FlareBottomSheet), findsOneWidget);
    expect(rowHeight(), FlareSizes.touchTarget);
    semantics.dispose();
  });

  group('auto presentation', () {
    const items = [
      FlareActionItem(id: 'pin', label: 'Pin'),
      FlareActionItem(id: 'mute', label: 'Mute'),
    ];

    testWidgets('is the kit sheet, titled with the label, where the platform '
        'presents sheets', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(
        _host(
          items: items,
          presentation: FlareActionMenuPresentation.auto,
          capabilities: _phone,
          onSelected: selected.add,
        ),
      );
      await _open(tester);
      final sheet = find.byType(FlareBottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text('Conversation')),
        findsOneWidget,
      );
      // Full-width rows.
      expect(
        tester.getSize(find.byType(FlareBottomSheet)).width,
        tester.getSemantics(find.bySemanticsLabel('Mute')).rect.width,
      );
      await tester.tap(find.text('Mute'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(selected, ['mute']);
    });

    testWidgets('is anchored where it does not', (tester) async {
      await tester.pumpWidget(
        _host(
          items: items,
          presentation: FlareActionMenuPresentation.auto,
          capabilities: _coarse,
        ),
      );
      await _open(tester);
      expect(find.byType(FlareBottomSheet), findsNothing);
      expect(_menu, findsOneWidget);
    });

    testWidgets('without an adapter follows the window width', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
      await tester.pumpWidget(
        _host(
          items: items,
          presentation: FlareActionMenuPresentation.auto,
          capabilities: null,
        ),
      );
      await _open(tester);
      expect(find.byType(FlareBottomSheet), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1024, 800);
      await tester.pumpWidget(
        _host(
          items: items,
          presentation: FlareActionMenuPresentation.auto,
          capabilities: null,
        ),
      );
      await _open(tester);
      expect(find.byType(FlareBottomSheet), findsNothing);
      expect(_menu, findsOneWidget);
    });
  });

  group('anchored placement', () {
    final items = [
      for (var i = 0; i < 4; i++) FlareActionItem(id: 'i$i', label: 'Item $i'),
    ];

    testWidgets('opens below the trigger, end-aligned, inside the screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(items: items, alignment: Alignment.topRight),
      );
      final trigger = tester.getRect(find.byType(TextButton));
      await _open(tester);
      final menu = tester.getRect(_menu);
      expect(menu.top, greaterThanOrEqualTo(trigger.bottom));
      expect(menu.right, lessThanOrEqualTo(800 - FlareSizes.spacingSm));
      expect(menu.left, greaterThanOrEqualTo(FlareSizes.spacingSm));
    });

    testWidgets('flips above the trigger when there is no room below', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(items: items, alignment: Alignment.bottomLeft),
      );
      final trigger = tester.getRect(find.byType(TextButton));
      await _open(tester);
      final menu = tester.getRect(_menu);
      expect(menu.bottom, lessThanOrEqualTo(trigger.top));
      expect(menu.left, greaterThanOrEqualTo(FlareSizes.spacingSm));
    });

    testWidgets('keeps clear of the safe area', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 120);
      await tester.pumpWidget(
        _host(items: items, alignment: const Alignment(1, -0.55)),
      );
      final trigger = tester.getRect(find.byType(TextButton));
      await _open(tester);
      final menu = tester.getRect(_menu);
      expect(menu.top, greaterThanOrEqualTo(120 + FlareSizes.spacingSm));
      expect(menu.bottom <= trigger.top || menu.top >= trigger.bottom, isTrue);
    });
  });

  testWidgets('the menu keeps the FlareTheme of its trigger', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlareTheme(
          mode: FlareThemeMode.dark,
          child: Scaffold(
            body: FlareActionMenu(
              items: const [FlareActionItem(id: 'pin', label: 'Pin')],
              label: 'Conversation',
              presentation: FlareActionMenuPresentation.anchored,
              onSelected: (_) {},
              builder: (context, open) =>
                  TextButton(onPressed: open, child: const Text('Open')),
            ),
          ),
        ),
      ),
    );
    await _open(tester);
    expect(
      tester.widget<Text>(find.text('Pin')).style?.color,
      FlareColors.resolve(Brightness.dark).textPrimary,
    );
  });

  group('FlareConversationHeader menus', () {
    const identity = FlareConversationIdentity(
      id: 'g1',
      title: 'Product room',
      kind: FlareConversationHeaderKind.group,
    );

    Widget header(List<String> picked) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 720,
          child: FlareConversationHeader(
            identity: identity,
            actions: const [
              FlareConversationHeaderAction(
                id: 'members',
                label: 'Show members',
                placement: FlareConversationHeaderActionPlacement.overflow,
                group: 'view',
                order: 91,
                pressed: true,
              ),
              FlareConversationHeaderAction(
                id: 'export',
                label: 'Export',
                placement: FlareConversationHeaderActionPlacement.overflow,
                group: 'data',
                order: 92,
                enabled: false,
                disabledReason: 'Admins only',
              ),
            ],
            onAction: (action) => picked.add(action.id),
          ),
        ),
      ),
    );

    testWidgets('dispatch the picked action, check pressed ones, separate '
        'groups', (tester) async {
      final semantics = tester.ensureSemantics();
      final picked = <String>[];
      await tester.pumpWidget(header(picked));

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('更多会话操作'))
            .getSemanticsData()
            .role,
        SemanticsRole.menu,
      );
      const strings = FlareStrings();
      expect(find.text(strings.conversationHeaderDetails), findsOneWidget);
      expect(_separators, findsNWidgets(2));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Show members')),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      expect(find.text('Admins only'), findsOneWidget);

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(picked, isEmpty, reason: 'a disabled action never dispatches');

      await tester.tap(find.text(strings.conversationHeaderDetails));
      await tester.pumpAndSettle();
      expect(picked, ['details']);
      expect(_menu, findsNothing);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text(strings.conversationHeaderShare), findsOneWidget);
      await tester.tap(find.text(strings.conversationHeaderAddMember));
      await tester.pumpAndSettle();
      expect(picked, ['details', 'addMember']);
      semantics.dispose();
    });

    testWidgets('stay closed without a handler', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 720,
              child: FlareConversationHeader(identity: identity),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(_menu, findsNothing);
    });
  });
}
