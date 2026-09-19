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

  test('availability matches the shared table', () {
    expect(cases.length, greaterThanOrEqualTo(8));
    for (final c in cases) {
      final available = messageBatchActionsAvailable(
        _ids(c['selected'] as int),
        _capabilities((c['capabilities'] as List).cast<String>()),
        c['busy'] as bool,
      );
      expect(
        available.map((a) => a.name).toList(),
        (c['available'] as List).cast<String>(),
        reason: c['id'] as String,
      );
    }
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
