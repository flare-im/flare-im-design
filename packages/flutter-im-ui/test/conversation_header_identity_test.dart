import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 720, child: child)),
);

const _details = FlareConversationHeaderAction(
  id: 'identity',
  label: 'Details',
);

void main() {
  testWidgets('the identity block is one button that reports its action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final actions = <String>[];
    var back = 0;
    await tester.pumpWidget(
      _host(
        FlareConversationHeader(
          identity: const FlareConversationIdentity(
            id: 'team',
            title: 'Team Flare',
            subtitle: '12 members',
            action: _details,
          ),
          capabilities: const FlareConversationHeaderCapabilities(
            availableActionIds: {'identity'},
          ),
          showBack: true,
          onBack: () => back++,
          onAction: (action) => actions.add(action.id),
        ),
      ),
    );
    final identity = find.bySemanticsLabel('Team Flare, Details');
    expect(
      tester.getSemantics(identity),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSize(identity).height,
      greaterThanOrEqualTo(FlareSizes.touchTarget),
    );
    await tester.tap(find.text('12 members'));
    await tester.tap(find.byType(FlareAvatar));
    expect(actions, ['identity', 'identity']);
    // The back button stays its own control.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    expect(back, 1);
    expect(actions, hasLength(2));
    // Keyboard: back, then the identity block.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(actions, hasLength(3));
    semantics.dispose();
  });

  testWidgets('an accessibility label replaces the composed one', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        FlareConversationHeader(
          identity: const FlareConversationIdentity(
            id: 'ann',
            title: 'Ann',
            action: FlareConversationHeaderAction(
              id: 'identity',
              label: 'Profile',
              accessibilityLabel: 'Open Ann profile',
            ),
          ),
          onAction: (_) {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Open Ann profile'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('no button without a handler, when disabled or filtered out', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final header in [
      const FlareConversationHeader(
        identity: FlareConversationIdentity(
          id: 'team',
          title: 'Team Flare',
          action: _details,
        ),
      ),
      FlareConversationHeader(
        identity: const FlareConversationIdentity(
          id: 'team',
          title: 'Team Flare',
          action: FlareConversationHeaderAction(
            id: 'identity',
            label: 'Details',
            enabled: false,
          ),
        ),
        onAction: (_) => fail('disabled'),
      ),
      FlareConversationHeader(
        identity: const FlareConversationIdentity(
          id: 'team',
          title: 'Team Flare',
          action: _details,
        ),
        capabilities: const FlareConversationHeaderCapabilities(
          availableActionIds: {'search'},
        ),
        onAction: (action) {
          if (action.id == 'identity') fail('filtered');
        },
      ),
    ]) {
      await tester.pumpWidget(_host(header));
      expect(find.bySemanticsLabel('Team Flare, Details'), findsNothing);
      expect(
        find.ancestor(
          of: find.text('Team Flare'),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Team Flare'));
    }
    semantics.dispose();
  });

  testWidgets('a pressed action is a toggle drawn and announced on', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final colors = FlareColors.resolve(Brightness.light);
    Widget header(bool? pressed) => _host(
      FlareConversationHeader(
        identity: const FlareConversationIdentity(id: 'team', title: 'Team'),
        capabilities: const FlareConversationHeaderCapabilities(
          availableActionIds: {'search'},
        ),
        actions: [
          FlareConversationHeaderAction(
            id: 'search',
            label: 'Search messages',
            icon: 'search',
            order: 10,
            pressed: pressed,
          ),
        ],
        onAction: (_) {},
      ),
    );
    IconButton button() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.search_rounded),
        matching: find.byType(IconButton),
      ),
    );

    await tester.pumpWidget(header(true));
    expect(
      tester.getSemantics(find.byTooltip('Search messages')),
      isSemantics(isButton: true, hasToggledState: true, isToggled: true),
    );
    expect(button().color, colors.primary);
    expect(
      button().style?.backgroundColor?.resolve(const <WidgetState>{}),
      colors.bgSelected,
    );

    await tester.pumpWidget(header(false));
    expect(
      tester.getSemantics(find.byTooltip('Search messages')),
      isSemantics(hasToggledState: true, isToggled: false),
    );
    expect(button().color, colors.textSecondary);

    await tester.pumpWidget(header(null));
    expect(
      tester.getSemantics(find.byTooltip('Search messages')),
      isSemantics(hasToggledState: false),
    );
    semantics.dispose();
  });
}
