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

  final around = table['around'] as Map<String, dynamic>;
  final aroundCases = (around['cases'] as List).cast<Map<String, dynamic>>();

  test('the trip around a message settles as many times as the table says', () {
    expect(around['settleAttempts'], flareLocateSettleAttempts);
    expect(aroundCases.length, greaterThanOrEqualTo(13));
  });

  for (final vector in aroundCases) {
    final id = vector['id'] as String;
    test('locate around: $id', () async {
      final anchorMap = vector['anchor'] as Map<String, dynamic>;
      final anchor = FlareLocateAnchor(
        messageId: anchorMap['messageId'] as String,
        seq: anchorMap['seq'] as int?,
      );
      final loaded = vector['loaded'] as bool;
      final answer = vector['openAnswer'] as String?;
      final key = (answer ?? '').trim();
      final drawnFrom = vector['drawnFromShow'] as int;
      final cancelAfterShows = vector['cancelAfterShows'] as int?;
      final cancelAfterOpen = vector['cancelAfterOpen'] == true;
      var opens = 0;
      var opened = false;
      final asked = <String>[];
      final handed = <FlareLocateAnchor>[];
      final outcome = await flareLocateMessageAround(
        anchor: anchor,
        showInList: (askedId) {
          asked.add(askedId);
          if (loaded && askedId == anchor.messageId) return true;
          return opened &&
              key.isNotEmpty &&
              askedId == key &&
              asked.length >= drawnFrom;
        },
        openAround: (given) {
          opens += 1;
          handed.add(given);
          opened = true;
          return answer;
        },
        settle: () {},
        isCurrent: () =>
            (cancelAfterShows == null || asked.length < cancelAfterShows) &&
            !(cancelAfterOpen && opened),
      );
      final expected = vector['expected'] as Map<String, dynamic>;
      expect(outcome.name, expected['outcome'], reason: '$id outcome');
      expect(opens, expected['openCalls'], reason: '$id opens');
      expect(asked.length, expected['showCalls'], reason: '$id asks');
      expect(asked, expected['askedIds'], reason: '$id asked ids');
      for (final given in handed) {
        expect(given, anchor, reason: '$id anchor handed over');
      }
    });
  }
}
