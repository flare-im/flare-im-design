import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

ConversationRowData _row(
  String id,
  String title, {
  int unread = 0,
  bool pinned = false,
  bool muted = false,
  bool mentioned = false,
  String? draft,
  String preview = 'hi there',
}) {
  return ConversationRowData(
    id: id,
    title: title,
    preview: preview,
    timestampLabel: '14:32',
    unreadCount: unread,
    pinned: pinned,
    muted: muted,
    mentioned: mentioned,
    draftPreview: draft,
  );
}

void main() {
  group('FlareConversationRow', () {
    testWidgets('shows title, time and preview', (tester) async {
      await tester.pumpWidget(
        _host(FlareConversationRow(item: _row('c1', 'Team Flare'))),
      );
      expect(find.text('Team Flare'), findsOneWidget);
      expect(find.text('14:32'), findsOneWidget);
      expect(find.textContaining('hi there'), findsOneWidget);
    });

    testWidgets('renders unread badge, caps at 99+', (tester) async {
      await tester.pumpWidget(
        _host(FlareConversationRow(item: _row('c1', 'A', unread: 120))),
      );
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('draft takes precedence over preview', (tester) async {
      await tester.pumpWidget(
        _host(FlareConversationRow(item: _row('c1', 'A', draft: 'wip'))),
      );
      expect(find.textContaining('Draft'), findsOneWidget);
      expect(find.textContaining('wip'), findsOneWidget);
    });

    testWidgets('muted shows the mute glyph', (tester) async {
      await tester.pumpWidget(
        _host(FlareConversationRow(item: _row('c1', 'A', muted: true))),
      );
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    testWidgets('tap raises onSelect', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(FlareConversationRow(
          item: _row('c1', 'Alpha'),
          onSelect: () => tapped = true,
        )),
      );
      await tester.tap(find.text('Alpha'));
      expect(tapped, isTrue);
    });

    testWidgets('previewSpansBuilder replaces the plain preview body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(FlareConversationRow(
          item: _row('c1', 'A', preview: 'plain text'),
          previewSpansBuilder: (context, base) => [
            const WidgetSpan(child: Icon(Icons.emoji_emotions, size: 12)),
            const TextSpan(text: 'rich body'),
          ],
        )),
      );
      expect(find.byIcon(Icons.emoji_emotions), findsOneWidget);
      expect(find.textContaining('rich body'), findsOneWidget);
      expect(find.textContaining('plain text'), findsNothing);
    });

    testWidgets('previewSpansBuilder is ignored while a draft exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(FlareConversationRow(
          item: _row('c1', 'A', draft: 'wip'),
          previewSpansBuilder: (context, base) =>
              const [TextSpan(text: 'should not show')],
        )),
      );
      expect(find.textContaining('wip'), findsOneWidget);
      expect(find.textContaining('should not show'), findsNothing);
    });
  });

  group('FlareConversationList', () {
    testWidgets('empty shows placeholder', (tester) async {
      await tester.pumpWidget(_host(const FlareConversationList(items: [])));
      expect(find.text('No conversations'), findsOneWidget);
    });

    testWidgets('loading with no items shows spinner', (tester) async {
      await tester.pumpWidget(
        _host(const FlareConversationList(items: [], loading: true)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders rows and marks the active one', (tester) async {
      await tester.pumpWidget(_host(FlareConversationList(
        items: [_row('c1', 'One'), _row('c2', 'Two')],
        activeId: 'c2',
      )));
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('selecting a row reports the item', (tester) async {
      ConversationRowData? picked;
      await tester.pumpWidget(_host(FlareConversationList(
        items: [_row('c1', 'One'), _row('c2', 'Two')],
        onSelect: (item) => picked = item,
      )));
      await tester.tap(find.text('Two'));
      expect(picked?.id, 'c2');
    });
  });

  group('FlareConversationSliverList', () {
    Widget sliverHost(Widget sliver) =>
        _host(CustomScrollView(slivers: [sliver]));

    testWidgets('builds one row per id via rowBuilder', (tester) async {
      final built = <String>[];
      await tester.pumpWidget(sliverHost(FlareConversationSliverList(
        ids: const ['a', 'b'],
        rowBuilder: (context, id) {
          built.add(id);
          return SizedBox(height: 40, child: Text('row-$id'));
        },
      )));
      expect(built, ['a', 'b']);
      expect(find.text('row-a'), findsOneWidget);
      expect(find.text('row-b'), findsOneWidget);
    });

    testWidgets('empty ids show the host placeholder', (tester) async {
      await tester.pumpWidget(sliverHost(FlareConversationSliverList(
        ids: const [],
        emptyPlaceholder: const Text('nothing here'),
        rowBuilder: (context, id) => const SizedBox.shrink(),
      )));
      expect(find.text('nothing here'), findsOneWidget);
    });

    testWidgets('empty + loading shows a spinner, not the placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(sliverHost(FlareConversationSliverList(
        ids: const [],
        loading: true,
        emptyPlaceholder: const Text('nothing here'),
        rowBuilder: (context, id) => const SizedBox.shrink(),
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('nothing here'), findsNothing);
    });
  });
}
