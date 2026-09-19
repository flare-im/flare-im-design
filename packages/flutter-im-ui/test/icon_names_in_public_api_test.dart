import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// B5.1 (FR-079): every public model or parameter that carries an icon for a
// concept takes a semantic name from the registry, never a Material glyph.
// A name draws the registry glyph; an unknown name draws the fallback and
// neither crashes nor prints the name on screen.

const _unknown = 'not-a-registry-name';
IconData _glyph(String name) => flareIconMap[name]!;

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 420, child: child)),
);

void main() {
  test('every name the kit ships defaults with is in the registry', () {
    final defaults = <String>[
      for (final item in flareDefaultIMNavigation(const FlareStrings()))
        item.icon,
      for (final item in flareDefaultContactNavigation(const FlareStrings()))
        item.icon,
      for (final action in FlareComposerActionPanel.defaultActions) action.icon,
    ];
    expect(defaults, isNotEmpty);
    for (final name in defaults) {
      expect(flareIconNames, contains(name), reason: name);
    }
  });

  testWidgets('a settings item renders the registry glyph for its name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareSettingsRow(
          item: const FlareSettingsItem(
            key: 'notif',
            label: '消息免打扰',
            icon: 'mute',
            kind: FlareSettingKind.toggle,
          ),
          onSelect: (_) {},
          onToggle: (_, _) {},
        ),
      ),
    );
    expect(find.byIcon(_glyph('mute')), findsOneWidget);
  });

  testWidgets('a navigation item renders the registry glyph for its name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: FlareDesktopAppShell(
          navigation: [
            FlareNavigationGroup(
              id: 'main',
              items: [
                FlareNavigationItem(id: 'chats', label: 'Chats', icon: 'chats'),
              ],
            ),
          ],
          activeNavigationId: 'chats',
          primary: Text('primary'),
          content: Text('content'),
          responsiveMode: FlareApplicationResponsiveMode.wideDesktop,
        ),
      ),
    );
    expect(find.byIcon(_glyph('chats')), findsWidgets);
  });

  testWidgets('a composer action renders the registry glyph for its name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareComposerActionPanel(
          actions: const [FlareComposerAction(id: 'image', icon: 'image')],
          onAction: (_) {},
        ),
      ),
    );
    expect(find.byIcon(_glyph('image')), findsOneWidget);
  });

  testWidgets('a message action renders the registry glyph for its name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FlareMessageActionSheet(
          availability: FlareMessageActionAvailability(canReply: true),
        ),
      ),
    );
    expect(find.byIcon(_glyph('reply')), findsOneWidget);
  });

  testWidgets('empty state, button and icon button take names too', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            const FlareEmptyState(title: 'Empty', icon: 'chats'),
            FlareButton(label: 'Send', icon: 'send', onPressed: () {}),
            FlareIconButton(
              icon: 'search',
              semanticLabel: '搜索',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.byIcon(_glyph('chats')), findsOneWidget);
    expect(find.byIcon(_glyph('send')), findsOneWidget);
    expect(find.byIcon(_glyph('search')), findsOneWidget);
  });

  testWidgets('an unknown name draws the fallback, never the name as text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            const FlareEmptyState(title: 'Empty', icon: _unknown),
            FlareIconButton(
              icon: _unknown,
              semanticLabel: '未知',
              onPressed: () {},
            ),
            FlareSettingsRow(
              item: const FlareSettingsItem(
                key: 'k',
                label: '一行设置',
                icon: _unknown,
              ),
              onSelect: (_) {},
              onToggle: (_, _) {},
            ),
            const FlareIcon(_unknown),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(_unknown), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsNWidgets(4));
  });
}
