import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared locate table (`spec/locate-orchestration-vectors.json`) is the one trip four kits make when a
/// quote names a message that is not loaded. Each case scripts a run; the expectations count the whole trip,
/// so a kit that asks or pages a different number of times fails even when it lands on the same answer.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/locate-orchestration-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  test('the table is the budget this kit was built with', () {
    expect(table['maxPages'], flareLocateMaxPages);
    expect(table['settleAttempts'], flareLocateSettleAttempts);
    expect(cases.length, greaterThanOrEqualTo(13));
  });

  for (final vector in cases) {
    final id = vector['id'] as String;
    test('locate run: $id', () async {
      var pages = 0;
      var shows = 0;
      final historyPages = vector['historyPages'] as int;
      final foundAfterPages = vector['foundAfterPages'] as int?;
      final failAtPage = vector['failAtPage'] as int?;
      final cancelAfterShows = vector['cancelAfterShows'] as int?;
      final visibleFrom = vector['visibleFromShow'] as int? ?? 1;
      final outcome = await flareLocateMessage(
        isCurrent: () => cancelAfterShows == null || shows < cancelAfterShows,
        showInList: () {
          shows += 1;
          if (foundAfterPages == null) return false;
          return pages >= foundAfterPages && shows >= visibleFrom;
        },
        hasOlder: () => pages < historyPages,
        readOlder: () {
          pages += 1;
          return failAtPage == null || pages != failAtPage;
        },
        settle: () {},
      );
      final expected = vector['expected'] as Map<String, dynamic>;
      expect(outcome.name, expected['outcome'], reason: '$id outcome');
      expect(pages, expected['pagesRead'], reason: '$id pages read');
      expect(shows, expected['showCalls'], reason: '$id asks');
    });
  }
}
