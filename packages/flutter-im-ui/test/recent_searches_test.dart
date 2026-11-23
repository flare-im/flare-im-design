import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Recent searches: the rule for keeping the list is the kit's, the same as the
// Vue kit's `flareRememberSearch`; the widget draws it and reports pick and
// clear, and draws nothing without items.

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('flareRememberSearch', () {
    test('puts the trimmed term first and drops an exact repeat', () {
      expect(flareRememberSearch(['b', 'a'], '  a '), ['a', 'b']);
      expect(flareRememberSearch(['a', 'b'], 'c'), ['c', 'a', 'b']);
    });

    test('a blank term changes nothing', () {
      expect(flareRememberSearch(['a'], '   '), ['a']);
    });

    test('the oldest fall off past the cap', () {
      expect(flareRememberSearch(['c', 'b', 'a'], 'd', max: 3), [
        'd',
        'c',
        'b',
      ]);
      expect(flareRememberSearch(['a'], 'b', max: 0), isEmpty);
    });
  });

  testWidgets('draws nothing without items', (tester) async {
    await tester.pumpWidget(_host(const FlareRecentSearches(items: [])));
    expect(find.text(const FlareStrings().recentSearchesTitle), findsNothing);
  });

  testWidgets('a term searches again and the clear key forgets them all', (
    tester,
  ) async {
    final picked = <String>[];
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        FlareRecentSearches(
          items: const ['发版', 'Alice'],
          onPick: picked.add,
          onClear: () => cleared++,
        ),
      ),
    );
    expect(find.text(const FlareStrings().recentSearchesTitle), findsOneWidget);
    await tester.tap(find.text('Alice'));
    expect(picked, ['Alice']);
    await tester.tap(find.byKey(const ValueKey('flare-recent-searches-clear')));
    expect(cleared, 1);
  });

  testWidgets('every row is at least a touch target tall', (tester) async {
    await tester.pumpWidget(
      _host(FlareRecentSearches(items: const ['a'], onPick: (_) {})),
    );
    final row = tester.getRect(
      find.byKey(const ValueKey('flare-recent-search-0')),
    );
    expect(row.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
  });
}
