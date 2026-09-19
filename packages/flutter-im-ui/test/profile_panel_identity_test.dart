import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// The profile header is a quiet identity card: the surface of the groups below
// it, the normal text colours, one control that opens the editor and a QR
// control beside it rather than inside it.

const _strings = FlareStrings();
const _user = FlareUserProfile(
  id: 'u_lin',
  name: '林夏',
  signature: '保持好奇',
  flareId: 'linxia',
);

Widget _host(Widget panel, {FlareStrings strings = _strings}) =>
    FlareStringsScope(
      strings: strings,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: panel)),
      ),
    );

void main() {
  testWidgets('the identity row is one control and the QR code its sibling', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        FlareProfilePanel(
          user: _user,
          onEdit: () => events.add('edit'),
          onQr: () => events.add('qr'),
        ),
      ),
    );

    final identity = find.bySemanticsLabel('林夏，编辑资料');
    expect(identity, findsOneWidget);
    final identityNode = tester.getSemantics(identity);
    expect(identityNode, isSemantics(isButton: true, hasTapAction: true));
    expect(
      identityNode.rect.height,
      greaterThanOrEqualTo(FlareSizes.touchTarget),
    );

    final qr = find.bySemanticsLabel(_strings.myQrCode);
    expect(qr, findsOneWidget);
    final qrNode = tester.getSemantics(qr);
    expect(qrNode, isSemantics(isButton: true, hasTapAction: true));
    expect(qrNode.rect.width, greaterThanOrEqualTo(FlareSizes.touchTarget));
    expect(qrNode.rect.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
    for (
      SemanticsNode? node = qrNode.parent;
      node != null;
      node = node.parent
    ) {
      expect(node, isNot(same(identityNode)), reason: 'QR is not nested');
    }

    await tester.tap(qr);
    await tester.tap(identity);
    expect(events, ['qr', 'edit']);
    handle.dispose();
  });

  testWidgets('the card reads like content, not an outgoing bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareProfilePanel(
          user: _user,
          onEdit: () {},
          onQr: () {},
          sections: const [
            FlareSettingsSection(
              items: [FlareSettingsItem(key: 'settings', label: '设置')],
            ),
          ],
        ),
      ),
    );
    final colors = FlareColors.of(tester.element(find.text('林夏')));
    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style!.color;
    expect(colorOf('林夏'), colors.textPrimary);
    expect(colorOf('保持好奇'), colors.textSecondary);
    expect(colorOf('Flare ID: linxia'), colors.textTertiary);

    // The identity card and the entry group share one elevated decoration.
    final surfaces = [
      for (final box in tester.widgetList<Container>(find.byType(Container)))
        if (box.decoration case final BoxDecoration d?
            when d.color == colors.bgElevated)
          d,
    ];
    expect(surfaces, hasLength(2));
    expect(surfaces.first, surfaces.last);
    expect(
      surfaces.first.borderRadius,
      BorderRadius.circular(FlareSizes.radiusXl),
    );
    expect(surfaces.first.boxShadow, isNotEmpty);
    for (final box in tester.widgetList<Container>(find.byType(Container))) {
      final d = box.decoration;
      if (d is BoxDecoration) {
        expect(d.color, isNot(colors.messageOutgoingBackground));
      }
    }
    // Chevrons: the identity row and the one navigation entry.
    final chevron = tester.widget<Icon>(find.byIcon(Icons.chevron_right).first);
    expect(chevron.color, colors.textTertiary);
  });

  testWidgets('without callbacks the identity is plain content and no QR', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const FlareProfilePanel(user: _user, entries: [])),
    );
    expect(find.bySemanticsLabel('林夏，编辑资料'), findsNothing);
    expect(find.bySemanticsLabel(_strings.myQrCode), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.text('林夏'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the identity control name comes from FlareStrings', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        FlareProfilePanel(
          user: const FlareUserProfile(id: 'u', name: 'Ann'),
          onEdit: () {},
        ),
        strings: _strings.copyWith(
          profilePanelEditProfile: (name) => '$name, edit profile',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ann, edit profile'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the default entries read their labels from FlareStrings', (
    tester,
  ) async {
    List<String> rowLabels() => [
      for (final row in tester.widgetList<FlareSettingsRow>(
        find.byType(FlareSettingsRow),
      ))
        row.item.label,
    ];

    await tester.pumpWidget(_host(const FlareProfilePanel(user: _user)));
    expect(rowLabels(), ['收藏', '圈子', '设置']);

    await tester.pumpWidget(
      _host(
        const FlareProfilePanel(user: _user),
        strings: _strings.copyWith(
          favorites: 'Favorites',
          moments: 'Moments',
          settings: 'Settings',
        ),
      ),
    );
    expect(rowLabels(), ['Favorites', 'Moments', 'Settings']);
    expect(FlareProfilePanel.entriesFor(_strings).map((item) => item.key), [
      'favorites',
      'moments',
      'settings',
    ]);

    // Entries the host passes replace the defaults.
    await tester.pumpWidget(
      _host(
        const FlareProfilePanel(
          user: _user,
          entries: [FlareSettingsItem(key: 'wallet', label: '钱包')],
        ),
      ),
    );
    expect(rowLabels(), ['钱包']);
  });
}
