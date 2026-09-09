import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_unknown_user_placeholder.dart';

void main() {
  group('unknownUserPresentation', () {
    test('maps every kind to itself', () {
      for (final kind in FlareUnknownUserKind.values) {
        expect(unknownUserPresentation(kind).kind, kind);
      }
    });

    test('carries a tone alongside the icon, never instead of it', () {
      expect(unknownUserPresentation(FlareUnknownUserKind.unknown).tone,
          FlareUnknownUserTone.neutral);
      expect(unknownUserPresentation(FlareUnknownUserKind.deactivated).tone,
          FlareUnknownUserTone.neutral);
      expect(unknownUserPresentation(FlareUnknownUserKind.blocked).tone,
          FlareUnknownUserTone.danger);
      expect(unknownUserPresentation(FlareUnknownUserKind.unreachable).tone,
          FlareUnknownUserTone.warning);
    });

    test('degrades an absent kind to unknown instead of blank', () {
      expect(unknownUserPresentation(null).kind, FlareUnknownUserKind.unknown);
      expect(unknownUserPresentation(null).tone, FlareUnknownUserTone.neutral);
    });

    test('each kind has its own icon', () {
      final icons = FlareUnknownUserKind.values
          .map(FlareUnknownUserPlaceholder.iconFor)
          .toSet();
      expect(icons.length, FlareUnknownUserKind.values.length);
    });
  });

  group('shortenUserId', () {
    test('keeps short ids intact and trims surrounding space', () {
      expect(shortenUserId('u_42'), 'u_42');
      expect(shortenUserId('  u_42  '), 'u_42');
      expect(shortenUserId(''), '');
      expect(shortenUserId(null), '');
    });

    test('keeps an id exactly at the budget', () {
      const exact = '0123456789abcdef01234567';
      expect(exact.length, 24);
      expect(shortenUserId(exact), exact);
    });

    test('middle-elides a long id to the budget', () {
      const long = '2AW1QQ2SKVWFEPJRXN0123456789abcdef';
      final out = shortenUserId(long);
      expect(out.length, 24);
      expect(out, '2AW1QQ2SKVWF…56789abcdef');
    });

    test('honours a custom budget and floors it so the result stays readable', () {
      expect(shortenUserId('abcdefghijklmnop', 10).length, 10);
      expect(shortenUserId('abcdefghijklmnop', 2).length, 8);
    });
  });

  testWidgets('row density shows the kind title, not the raw id', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FlareUnknownUserPlaceholder(
          userId: 'u_2AW1QQ2SKVWFEPJRXN',
          kind: FlareUnknownUserKind.deactivated,
        ),
      ),
    ));
    expect(find.text('该账号已注销'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    // The id appears only in the diagnostic slot, never as a heading.
    expect(find.text('u_2AW1QQ2SKVWFEPJRXN'), findsOneWidget);
    expect(find.text('未知用户'), findsNothing);
  });

  testWidgets('every kind renders its own default title', (tester) async {
    Future<void> check(FlareUnknownUserKind kind, String expected) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FlareUnknownUserPlaceholder(userId: 'u1', kind: kind)),
      ));
      expect(find.text(expected), findsOneWidget);
    }

    await check(FlareUnknownUserKind.unknown, '未知用户');
    await check(FlareUnknownUserKind.deactivated, '该账号已注销');
    await check(FlareUnknownUserKind.blocked, '该账号已被屏蔽');
    await check(FlareUnknownUserKind.unreachable, '暂时无法联系该账号');
  });

  testWidgets('card density shows host detail and stays action-free', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FlareUnknownUserPlaceholder(
          userId: 'u1',
          kind: FlareUnknownUserKind.unreachable,
          density: FlareUnknownUserDensity.card,
          detail: '来自群成员列表',
        ),
      ),
    ));
    expect(find.text('暂时无法联系该账号'), findsOneWidget);
    expect(find.text('来自群成员列表'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a blank id hides the diagnostic line instead of showing an empty one',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FlareUnknownUserPlaceholder(userId: '   ', kind: FlareUnknownUserKind.unknown),
      ),
    ));
    expect(find.text('未知用户'), findsOneWidget);
    expect(find.text('ID'), findsNothing);
  });
}
