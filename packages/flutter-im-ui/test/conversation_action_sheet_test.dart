import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_conversation_action_sheet.dart';
import 'package:flare_im_ui/src/tokens/flare_strings.dart';

void main() {
  const base = FlareConversationActionSnapshot(id: 'c1', title: '设计评审');
  const all = FlareConversationActionCapabilities(
    pin: true,
    mute: true,
    markRead: true,
    archive: true,
    hide: true,
    delete: true,
  );
  const every = FlareConversationActionCapabilities(
    pin: true,
    mute: true,
    markRead: true,
    markUnread: true,
    archive: true,
    hide: true,
    clearHistory: true,
    delete: true,
  );
  List<FlareConversationAction> ids(
    FlareConversationActionSnapshot c,
    FlareConversationActionCapabilities caps,
  ) => conversationActions(c, caps).map((e) => e.action).toList();

  group('conversationActions', () {
    test('nothing without capabilities', () {
      expect(ids(base, const FlareConversationActionCapabilities()), isEmpty);
    });
    test('each capability reveals exactly its action', () {
      expect(ids(base, const FlareConversationActionCapabilities(pin: true)), [
        FlareConversationAction.pin,
      ]);
      expect(ids(base, const FlareConversationActionCapabilities(mute: true)), [
        FlareConversationAction.mute,
      ]);
      expect(
        ids(base, const FlareConversationActionCapabilities(archive: true)),
        [FlareConversationAction.archive],
      );
      expect(ids(base, const FlareConversationActionCapabilities(hide: true)), [
        FlareConversationAction.hide,
      ]);
      expect(
        ids(
          base,
          const FlareConversationActionCapabilities(clearHistory: true),
        ),
        [FlareConversationAction.clearHistory],
      );
      expect(
        ids(base, const FlareConversationActionCapabilities(delete: true)),
        [FlareConversationAction.delete],
      );
    });
    test('inverts pin/mute/archive by state', () {
      expect(
        ids(
          const FlareConversationActionSnapshot(
            id: 'c',
            title: 't',
            pinned: true,
          ),
          const FlareConversationActionCapabilities(pin: true),
        ),
        [FlareConversationAction.unpin],
      );
      expect(
        ids(
          const FlareConversationActionSnapshot(
            id: 'c',
            title: 't',
            muted: true,
          ),
          const FlareConversationActionCapabilities(mute: true),
        ),
        [FlareConversationAction.unmute],
      );
      expect(
        ids(
          const FlareConversationActionSnapshot(
            id: 'c',
            title: 't',
            archived: true,
          ),
          const FlareConversationActionCapabilities(archive: true),
        ),
        [FlareConversationAction.unarchive],
      );
    });
    test('markRead only when unread > 0', () {
      expect(
        ids(base, const FlareConversationActionCapabilities(markRead: true)),
        isEmpty,
      );
      expect(
        ids(
          const FlareConversationActionSnapshot(
            id: 'c',
            title: 't',
            unreadCount: 3,
          ),
          const FlareConversationActionCapabilities(markRead: true),
        ),
        [FlareConversationAction.markRead],
      );
    });
    test('offers markUnread only when nothing is unread', () {
      const unread = FlareConversationActionSnapshot(
        id: 'c',
        title: 't',
        unreadCount: 3,
      );
      const both = FlareConversationActionCapabilities(
        markRead: true,
        markUnread: true,
      );
      expect(ids(base, both), [FlareConversationAction.markUnread]);
      expect(ids(unread, both), [FlareConversationAction.markRead]);
      expect(
        ids(
          unread,
          const FlareConversationActionCapabilities(markUnread: true),
        ),
        isEmpty,
      );
    });
    test('stable order, clearHistory then delete last and danger', () {
      final entries = conversationActions(
        const FlareConversationActionSnapshot(
          id: 'c',
          title: 't',
          unreadCount: 2,
        ),
        const FlareConversationActionCapabilities(
          pin: true,
          mute: true,
          markRead: true,
          archive: true,
          hide: true,
          clearHistory: true,
          delete: true,
        ),
      );
      expect(entries.map((e) => e.action).toList(), [
        FlareConversationAction.pin,
        FlareConversationAction.mute,
        FlareConversationAction.markRead,
        FlareConversationAction.archive,
        FlareConversationAction.hide,
        FlareConversationAction.clearHistory,
        FlareConversationAction.delete,
      ]);
      expect(entries.where((e) => e.danger).map((e) => e.action), [
        FlareConversationAction.clearHistory,
        FlareConversationAction.delete,
      ]);
      expect(entries.last.danger, isTrue);
    });
    test('full order with every capability', () {
      expect(ids(base, every), [
        FlareConversationAction.pin,
        FlareConversationAction.mute,
        FlareConversationAction.markUnread,
        FlareConversationAction.archive,
        FlareConversationAction.hide,
        FlareConversationAction.clearHistory,
        FlareConversationAction.delete,
      ]);
    });
  });

  testWidgets('renders labels, emits action, busy disables', (tester) async {
    final received = <String>[];
    Widget build({bool busy = false}) => MaterialApp(
      home: Scaffold(
        body: FlareConversationActionSheet(
          conversation: const FlareConversationActionSnapshot(
            id: 'c1',
            title: '设计评审',
            pinned: true,
            unreadCount: 1,
          ),
          capabilities: all,
          busy: busy,
          onAction: (id, a) => received.add('$id/${a.name}'),
        ),
      ),
    );
    await tester.pumpWidget(build());
    expect(find.text('取消置顶'), findsOneWidget);
    expect(find.text('标为已读'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('置顶'), findsNothing);

    await tester.tap(find.text('删除'));
    await tester.pump();
    expect(received, ['c1/delete']);

    await tester.pumpWidget(build(busy: true));
    await tester.tap(find.text('取消置顶'));
    await tester.pump();
    expect(received, ['c1/delete']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mark-unread and clear-history read the strings table and emit their ids',
    (tester) async {
      final received = <String>[];
      Widget build(FlareStrings strings) => FlareStringsScope(
        strings: strings,
        child: MaterialApp(
          home: Scaffold(
            body: FlareConversationActionSheet(
              conversation: base,
              capabilities: every,
              onAction: (id, a) => received.add('$id/${a.name}'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(const FlareStrings()));
      expect(find.text('标为未读'), findsOneWidget);
      expect(find.text('清空本地记录'), findsOneWidget);
      expect(find.text('标为已读'), findsNothing);
      // The danger group is drawn after the primary group, clear history first.
      expect(
        tester.getTopLeft(find.text('清空本地记录')).dy,
        lessThan(tester.getTopLeft(find.text('删除')).dy),
      );
      expect(
        tester.getTopLeft(find.text('隐藏')).dy,
        lessThan(tester.getTopLeft(find.text('清空本地记录')).dy),
      );

      await tester.tap(find.text('标为未读'));
      await tester.tap(find.text('清空本地记录'));
      await tester.pump();
      expect(received, ['c1/markUnread', 'c1/clearHistory']);

      await tester.pumpWidget(
        build(
          const FlareStrings().copyWith(
            conversationActionSheetMarkUnread: 'Mark as unread',
            conversationActionSheetClearHistory: 'Clear local history',
          ),
        ),
      );
      expect(find.text('Mark as unread'), findsOneWidget);
      expect(find.text('Clear local history'), findsOneWidget);
    },
  );

  testWidgets('empty capabilities show the empty text, not a blank menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FlareConversationActionSheet(conversation: base)),
      ),
    );
    expect(find.text('暂无可用操作'), findsOneWidget);
  });
}
