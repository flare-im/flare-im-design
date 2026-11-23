import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

const _strings = FlareStrings();

/// Editing a sent message and a conversation that takes no messages: the Vue
/// composer's `editing` / `editPreview` / `clear-edit` and `statusHint`.
void main() {
  testWidgets('an edit shows its strip instead of the reply, saves from the '
      'send key and closes from the strip', (tester) async {
    final controller = TextEditingController(text: 'fixed text');
    addTearDown(controller.dispose);
    final sent = <String>[];
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        FlareComposer(
          controller: controller,
          editing: true,
          editPreview: 'original text',
          replyTo: const FlareReplyTarget(
            messageId: 'm1',
            senderName: 'Ann',
            summary: 'quoted',
          ),
          onClearEdit: () => cleared++,
          onSend: (text) {
            sent.add(text);
            return true;
          },
        ),
      ),
    );

    expect(find.text(_strings.composerEditingMessage), findsOneWidget);
    expect(find.text('original text'), findsOneWidget);
    expect(
      find.text('quoted'),
      findsNothing,
      reason: 'the edit owns the strip',
    );
    expect(find.byTooltip(_strings.composerSaveEdit), findsOneWidget);
    expect(find.byTooltip(_strings.composerRichText), findsNothing);

    await tester.tap(find.byTooltip(_strings.composerSaveEdit));
    await tester.pumpAndSettle();
    expect(sent, ['fixed text']);
    expect(controller.text, '', reason: 'a saved edit clears like a send');

    await tester.tap(find.bySemanticsLabel(_strings.composerCancelEdit));
    await tester.pump();
    expect(cleared, 1);
  });

  testWidgets('without an edit the composer is the plain one', (tester) async {
    await tester.pumpWidget(_host(FlareComposer(onSend: (_) => true)));
    expect(find.text(_strings.composerEditingMessage), findsNothing);
    expect(find.byTooltip(_strings.send), findsOneWidget);
    expect(
      tester
          .widget<ExtendedTextField>(find.byType(ExtendedTextField))
          .decoration
          ?.hintText,
      _strings.composerPlaceholder,
    );
  });

  testWidgets('an edit falls back to the field text and its own placeholder', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'typed');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        FlareComposer(
          controller: controller,
          editing: true,
          onSend: (_) => true,
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('composer-edit-strip')),
        matching: find.text('typed'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ExtendedTextField>(find.byType(ExtendedTextField))
          .decoration
          ?.hintText,
      _strings.composerEditingPlaceholder,
    );
  });

  testWidgets('a status hint says why the conversation takes no messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FlareComposer(
          disabled: true,
          statusHint: 'You can no longer post here',
        ),
      ),
    );
    expect(find.byKey(const ValueKey('composer-status-hint')), findsOneWidget);
    expect(find.text('You can no longer post here'), findsOneWidget);
    expect(
      tester.widget<ExtendedTextField>(find.byType(ExtendedTextField)).enabled,
      isFalse,
    );

    await tester.pumpWidget(_host(const FlareComposer(statusHint: '  ')));
    expect(find.byKey(const ValueKey('composer-status-hint')), findsNothing);
  });
}
