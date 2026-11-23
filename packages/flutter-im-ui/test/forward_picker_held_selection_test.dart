import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _targets = [
  FlareForwardTarget(id: 'a', name: 'Ann'),
  FlareForwardTarget(id: 'b', name: 'Bo'),
  FlareForwardTarget(id: 'c', name: 'Cy'),
];

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// The host holds the choice (the Vue kit's `v-model`): after a forward that
/// reached some of the chats, only the ones still waiting stay chosen; while
/// it forwards (`busy`) nothing in the picker takes a tap.
void main() {
  testWidgets('starts from the host\'s choice and takes a new one', (
    tester,
  ) async {
    final confirmed = <List<String>>[];
    final changes = <List<String>>[];
    Widget picker(List<String> selected, {bool busy = false}) => _host(
      FlareForwardPicker(
        targets: _targets,
        selected: selected,
        busy: busy,
        onConfirm: confirmed.add,
        onSelectionChanged: changes.add,
      ),
    );

    await tester.pumpWidget(picker(const ['a', 'b', 'gone']));
    await tester.tap(find.text(const FlareStrings().send));
    await tester.pump();
    expect(confirmed.single, ['a', 'b'], reason: 'an id not on offer drops');

    // A partial failure: the host keeps the chat that did not get it.
    await tester.pumpWidget(picker(const ['b']));
    await tester.tap(find.text('Cy'));
    await tester.pump();
    expect(changes.last, ['b', 'c']);
    await tester.tap(find.text(const FlareStrings().send));
    await tester.pump();
    expect(confirmed.last, ['b', 'c']);
  });

  testWidgets('a busy picker shows progress and takes no taps', (tester) async {
    final confirmed = <List<String>>[];
    var closes = 0;
    await tester.pumpWidget(
      _host(
        FlareForwardPicker(
          targets: _targets,
          selected: const ['a'],
          busy: true,
          onConfirm: confirmed.add,
          onClose: () => closes++,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('flare-forward-picker-busy')),
      findsOneWidget,
    );
    await tester.tap(find.text('Bo'));
    await tester.tap(find.text(const FlareStrings().send));
    await tester.tap(find.bySemanticsLabel(const FlareStrings().close));
    await tester.pump();
    expect(confirmed, isEmpty);
    expect(closes, 0);
  });
}
