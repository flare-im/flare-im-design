import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)));

/// `onTyping` means "the person edited the text", not "the text changed". The difference is invisible
/// until a host drives a typing signal from it: the composer's own clear after a send would then read as
/// someone typing, and so would every text the host puts back — the original of a send that failed, for
/// one. Vue has drawn this line since it had a composer (`user-input`); R7 drew it on the other three.
void main() {
  testWidgets('the clear after a send is not an edit by the person', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final edits = <String>[];
    await tester.pumpWidget(
      _host(FlareComposer(controller: controller, onTyping: edits.add, onSend: (_) => true)),
    );

    await tester.tap(find.byType(ExtendedTextField));
    await tester.pump();
    tester.testTextInput.enterText('hello');
    await tester.pump();
    expect(edits, ['hello']);

    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pumpAndSettle();
    expect(controller.text, '', reason: 'the send clears the composer');
    expect(edits, ['hello'], reason: 'and says nothing about it');
  });

  testWidgets('changing conversation clears without reporting an edit', (tester) async {
    final edits = <String>[];
    await tester.pumpWidget(_host(FlareComposer(conversationKey: 'c1', onTyping: edits.add, onSend: (_) => true)));
    await tester.tap(find.byType(ExtendedTextField));
    await tester.pump();
    tester.testTextInput.enterText('hello');
    await tester.pump();
    expect(edits, ['hello']);

    await tester.pumpWidget(_host(FlareComposer(conversationKey: 'c2', onTyping: edits.add, onSend: (_) => true)));
    await tester.pump();
    expect(edits, ['hello']);
  });

  testWidgets('tapping into a composer that already holds a draft is not typing', (tester) async {
    final controller = TextEditingController(text: 'a draft from last time');
    addTearDown(controller.dispose);
    final edits = <String>[];
    await tester.pumpWidget(_host(FlareComposer(controller: controller, onTyping: edits.add, onSend: (_) => true)));

    await tester.tap(find.byType(ExtendedTextField));
    await tester.pump();
    // The caret moved; the text did not. A controller notifies for both.
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    expect(edits, isEmpty);
  });

  testWidgets('what the person types is reported, every time', (tester) async {
    final edits = <String>[];
    await tester.pumpWidget(_host(FlareComposer(onTyping: edits.add, onSend: (_) => true)));
    await tester.tap(find.byType(ExtendedTextField));
    await tester.pump();
    tester.testTextInput.enterText('h');
    await tester.pump();
    tester.testTextInput.enterText('hi');
    await tester.pump();
    tester.testTextInput.enterText('');
    await tester.pump();
    expect(edits, ['h', 'hi', '']);
  });
}
