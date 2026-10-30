import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-034: the message batch toolbar answers the same question the conversation one does — what may a
// host do with this selection right now. `spec/message-batch-vectors.json` is the answer, on four kits.

const _strings = FlareStrings();

FlareMessageBatchCapabilities _capabilities(List<String> names) =>
    FlareMessageBatchCapabilities(
      forwardEach: names.contains('forwardEach'),
      forwardMerged: names.contains('forwardMerged'),
      pin: names.contains('pin'),
      pinSelf: names.contains('pinSelf'),
      delete: names.contains('delete'),
    );

List<String> _ids(int count) =>
    List<String>.generate(count, (index) => 'm$index');

Widget _host(Widget child) => FlareStringsScope(
  strings: _strings,
  child: MaterialApp(
    home: FlareTheme(
      mode: FlareThemeMode.light,
      child: Scaffold(body: SizedBox(width: 600, child: child)),
    ),
  ),
);

void main() {
  final vectors =
      jsonDecode(
            File(
              '${Directory.current.path}/../../spec/message-batch-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (vectors['cases'] as List).cast<Map<String, dynamic>>();

  List<String> selection(Map<String, dynamic> c) =>
      (c['selectedIds'] as List?)?.cast<String>() ?? _ids(c['selected'] as int);
  Set<String> unforwardable(Map<String, dynamic> c) =>
      ((c['unforwardable'] as List?) ?? const []).cast<String>().toSet();

  test('availability matches the shared table', () {
    expect(cases.length, greaterThanOrEqualTo(14));
    for (final c in cases) {
      expect(selection(c).length, c['selected'], reason: c['id'] as String);
      final available = messageBatchActionsAvailable(
        selection(c),
        _capabilities((c['capabilities'] as List).cast<String>()),
        c['busy'] as bool,
        unforwardable(c),
      );
      expect(
        available.map((a) => a.name).toList(),
        (c['available'] as List).cast<String>(),
        reason: c['id'] as String,
      );
    }
  });

  test('the reported ids and the unforwardable count are the table\'s', () {
    final forward = cases.where((c) => c['reports'] != null).toList();
    expect(forward.length, greaterThanOrEqualTo(6));
    for (final c in forward) {
      for (final entry in (c['reports'] as Map).cast<String, List>().entries) {
        final action = FlareMessageBatchAction.values.byName(entry.key);
        expect(
          messageBatchActionIds(action, selection(c), unforwardable(c)),
          entry.value.cast<String>(),
          reason: '${c['id']} ${entry.key}',
        );
      }
      expect(
        messageBatchUnforwardableCount(selection(c), unforwardable(c)),
        c['unforwardableCount'],
        reason: c['id'] as String,
      );
    }
    expect(
      FlareMessageBatchAction.values
          .where((a) => a.forwards)
          .map((a) => a.name)
          .toList(),
      ((vectors['forward'] as Map)['actions'] as List).cast<String>(),
    );
  });

  testWidgets('the forward keys leave the unforwardable ids out and the meta '
      'says how many', (tester) async {
    final reported = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMessageBatchToolbar(
          selectedIds: const ['c', 'a', 'b'],
          unforwardableIds: const {'a', 'z'},
          total: 5,
          capabilities: const FlareMessageBatchCapabilities(
            forwardEach: true,
            forwardMerged: true,
            delete: true,
          ),
          onAction: (action, ids) =>
              reported.add('${action.name}:${ids.join(",")}'),
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(FlareMessageBatchToolbar.unforwardableKey))
          .data,
      '1 条不支持转发',
    );
    await tester.tap(find.text(_strings.forwardEach));
    await tester.tap(find.text(_strings.forwardMerged));
    await tester.tap(find.text(_strings.delete));
    await tester.pump();
    expect(reported, ['forwardEach:c,b', 'forwardMerged:c,b', 'delete:c,a,b']);

    reported.clear();
    await tester.pumpWidget(
      _host(
        FlareMessageBatchToolbar(
          selectedIds: const ['a', 'b'],
          unforwardableIds: const {'a'},
          total: 5,
          capabilities: const FlareMessageBatchCapabilities(
            forwardEach: true,
            forwardMerged: true,
          ),
          onAction: (action, ids) => reported.add(action.name),
        ),
      ),
    );
    await tester.tap(find.text(_strings.forwardMerged));
    await tester.tap(find.text(_strings.forwardEach));
    await tester.pump();
    expect(reported, [
      'forwardEach',
    ], reason: 'one forwardable id cannot merge');

    await tester.pumpWidget(
      _host(
        FlareMessageBatchToolbar(
          selectedIds: const ['a', 'b'],
          total: 5,
          capabilities: const FlareMessageBatchCapabilities(forwardEach: true),
        ),
      ),
    );
    expect(find.byKey(FlareMessageBatchToolbar.unforwardableKey), findsNothing);
  });

  test('the declared order and minimums are the table\'s', () {
    expect(
      FlareMessageBatchAction.values.map((a) => a.name).toList(),
      (vectors['order'] as List).cast<String>(),
    );
    expect(
      flareMessageBatchMinimumSelection.map((a, n) => MapEntry(a.name, n)),
      (vectors['minimumSelection'] as Map).cast<String, int>(),
    );
  });

  testWidgets('the toolbar reports one action with the ids it was given', (
    tester,
  ) async {
    final reported = <String>[];
    var selectedAll = 0, cleared = 0;
    await tester.pumpWidget(
      _host(
        FlareMessageBatchToolbar(
          selectedIds: const ['a', 'b'],
          total: 5,
          capabilities: const FlareMessageBatchCapabilities(
            forwardEach: true,
            forwardMerged: true,
            pin: true,
            pinSelf: true,
            delete: true,
          ),
          onAction: (action, ids) =>
              reported.add('${action.name}:${ids.join(",")}'),
          onSelectAll: () => selectedAll++,
          onClearSelection: () => cleared++,
        ),
      ),
    );

    await tester.tap(find.text(_strings.messageBatchPin));
    await tester.tap(find.text(_strings.forwardMerged));
    await tester.tap(find.text(_strings.selectAll));
    await tester.tap(find.text(_strings.messageBatchClear));
    await tester.pump();

    expect(reported, ['pin:a,b', 'forwardMerged:a,b']);
    expect(selectedAll, 1);
    expect(cleared, 1);
  });

  testWidgets(
    'only the declared actions are drawn, and a short selection cannot merge',
    (tester) async {
      final reported = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageBatchToolbar(
            selectedIds: const ['a'],
            total: 5,
            capabilities: const FlareMessageBatchCapabilities(
              forwardEach: true,
              forwardMerged: true,
            ),
            onAction: (action, ids) => reported.add(action.name),
          ),
        ),
      );

      expect(find.text(_strings.messageBatchPin), findsNothing);
      expect(find.text(_strings.delete), findsNothing);
      expect(find.text(_strings.forwardMerged), findsOneWidget);

      await tester.tap(find.text(_strings.forwardMerged));
      await tester.tap(find.text(_strings.forwardEach));
      await tester.pump();
      expect(reported, ['forwardEach'], reason: 'merging needs two');
    },
  );
}
