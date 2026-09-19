import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const groups = [
  FlareCommandPaletteGroup(
    id: 'message',
    label: 'Message',
    commands: [
      FlareCommandPaletteCommand(id: 'reply', label: 'Reply'),
      FlareCommandPaletteCommand(id: 'copy', label: 'Copy'),
      FlareCommandPaletteCommand(id: 'delete', label: 'Delete', disabled: true),
    ],
  ),
];

Widget host({
  bool busy = false,
  ValueChanged<FlareCommandPaletteCommand>? onInvoke,
  VoidCallback? onClose,
}) => MaterialApp(
  home: FlareCommandPalette(
    open: true,
    query: '',
    groups: groups,
    label: 'Commands',
    placeholder: 'Find',
    emptyText: 'None',
    busy: busy,
    onQueryChange: (_) {},
    onInvoke: onInvoke ?? (_) {},
    onClose: onClose ?? () {},
  ),
);

void main() {
  testWidgets('initial open focuses search and keyboard invokes selection', (
    tester,
  ) async {
    String? invoked;
    await tester.pumpWidget(host(onInvoke: (command) => invoked = command.id));
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(invoked, 'copy');
  });

  testWidgets('busy and disabled commands never invoke, Escape closes', (
    tester,
  ) async {
    var invokes = 0;
    var closes = 0;
    await tester.pumpWidget(
      host(busy: true, onInvoke: (_) => invokes++, onClose: () => closes++),
    );
    await tester.tap(find.text('Delete'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(invokes, 0);
    expect(closes, 1);
  });
}
