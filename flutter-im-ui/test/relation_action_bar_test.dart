import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_relation_action_bar.dart';

void main() {
  const all = FlareRelationCapabilities(
    add: true,
    accept: true,
    reject: true,
    remove: true,
    block: true,
    unblock: true,
    message: true,
  );
  List<FlareRelationAction> ids(FlareRelationState r, FlareRelationCapabilities? c) =>
      relationActions(r, c).map((e) => e.action).toList();

  group('relationActions', () {
    test('renders nothing when the host grants no capability', () {
      for (final relation in FlareRelationState.values) {
        expect(ids(relation, const FlareRelationCapabilities()), isEmpty);
        expect(ids(relation, null), isEmpty);
      }
    });

    test('none offers add as primary plus block', () {
      expect(ids(FlareRelationState.none, all),
          [FlareRelationAction.add, FlareRelationAction.block]);
      final entries = relationActions(FlareRelationState.none, all);
      expect(entries.first.primary, isTrue);
      expect(entries.first.destructive, isFalse);
      expect(entries.last.primary, isFalse);
    });

    test('pendingOut never re-offers add, only block', () {
      expect(ids(FlareRelationState.pendingOut, all), [FlareRelationAction.block]);
      expect(ids(FlareRelationState.pendingOut, const FlareRelationCapabilities(add: true)),
          isEmpty);
      expect(relationShowsPending(FlareRelationState.pendingOut), isTrue);
      for (final r in FlareRelationState.values.where((r) => r != FlareRelationState.pendingOut)) {
        expect(relationShowsPending(r), isFalse);
      }
      expect(relationShowsPending(null), isFalse);
    });

    test('pendingIn offers accept as primary, then reject and block', () {
      expect(ids(FlareRelationState.pendingIn, all),
          [FlareRelationAction.accept, FlareRelationAction.reject, FlareRelationAction.block]);
      final entries = relationActions(FlareRelationState.pendingIn, all);
      expect(entries.where((e) => e.primary).map((e) => e.action), [FlareRelationAction.accept]);
      expect(entries.any((e) => e.destructive), isFalse);
    });

    test('friends offers message as primary and marks remove and block destructive', () {
      expect(ids(FlareRelationState.friends, all),
          [FlareRelationAction.message, FlareRelationAction.remove, FlareRelationAction.block]);
      final entries = relationActions(FlareRelationState.friends, all);
      expect(entries.where((e) => e.primary).map((e) => e.action), [FlareRelationAction.message]);
      expect(entries.where((e) => e.destructive).map((e) => e.action),
          [FlareRelationAction.remove, FlareRelationAction.block]);
    });

    test('blocked offers unblock and nothing else', () {
      expect(ids(FlareRelationState.blocked, all), [FlareRelationAction.unblock]);
      expect(relationActions(FlareRelationState.blocked, all).first.primary, isTrue);
    });

    test('a missing capability removes just its own entry and keeps the order', () {
      expect(ids(FlareRelationState.none, const FlareRelationCapabilities(block: true)),
          [FlareRelationAction.block]);
      expect(
          ids(FlareRelationState.pendingIn,
              const FlareRelationCapabilities(accept: true, block: true)),
          [FlareRelationAction.accept, FlareRelationAction.block]);
      expect(
          ids(FlareRelationState.friends,
              const FlareRelationCapabilities(remove: true, block: true)),
          [FlareRelationAction.remove, FlareRelationAction.block]);
      expect(
          ids(FlareRelationState.blocked,
              const FlareRelationCapabilities(message: true, add: true)),
          isEmpty);
    });

    test('an absent relation degrades to none rather than throwing', () {
      expect(relationActions(null, all).map((e) => e.action),
          [FlareRelationAction.add, FlareRelationAction.block]);
    });
  });

  testWidgets('emits the action, busy blocks a second tap', (tester) async {
    final received = <String>[];
    Widget build({bool busy = false}) => MaterialApp(
          home: Scaffold(
            body: FlareRelationActionBar(
              relation: FlareRelationState.friends,
              capabilities: all,
              busy: busy,
              onAction: (a) => received.add(a.name),
            ),
          ),
        );

    await tester.pumpWidget(build());
    expect(find.text('发消息'), findsOneWidget);
    expect(find.text('删除好友'), findsOneWidget);
    expect(find.text('加入黑名单'), findsOneWidget);
    expect(find.text('添加好友'), findsNothing);

    await tester.tap(find.text('删除好友'));
    await tester.pump();
    expect(received, ['remove']);

    await tester.pumpWidget(build(busy: true));
    await tester.pump();
    await tester.tap(find.text('发消息'), warnIfMissed: false);
    await tester.pump();
    expect(received, ['remove']);
  });

  testWidgets('pendingOut shows the waiting notice instead of an add button',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareRelationActionBar(
          relation: FlareRelationState.pendingOut,
          capabilities: all,
          onAction: (_) {},
        ),
      ),
    ));
    expect(find.text('等待对方验证'), findsOneWidget);
    expect(find.text('添加好友'), findsNothing);
    expect(find.text('加入黑名单'), findsOneWidget);
  });

  testWidgets('blocked hides message and add entirely', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareRelationActionBar(
          relation: FlareRelationState.blocked,
          capabilities: all,
          onAction: (_) {},
        ),
      ),
    ));
    expect(find.text('移出黑名单'), findsOneWidget);
    expect(find.text('发消息'), findsNothing);
    expect(find.text('添加好友'), findsNothing);
    expect(find.text('删除好友'), findsNothing);
  });

  testWidgets('error stays on screen and only dismiss clears it', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareRelationActionBar(
          relation: FlareRelationState.none,
          capabilities: all,
          error: '对方拒绝接收好友申请',
          onAction: (_) {},
          onDismissError: () => dismissed++,
        ),
      ),
    ));
    expect(find.text('对方拒绝接收好友申请'), findsOneWidget);
    // The bar keeps working while the reason is on screen.
    expect(find.text('添加好友'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(dismissed, 1);
    expect(find.text('对方拒绝接收好友申请'), findsOneWidget);
  });

  testWidgets('no capability shows the empty text, not a blank bar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FlareRelationActionBar(relation: FlareRelationState.none)),
    ));
    expect(find.text('暂无可用操作'), findsOneWidget);
  });
}
