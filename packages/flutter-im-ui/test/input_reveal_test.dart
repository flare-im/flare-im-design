import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-045: the masked field owns its unmask key, so no app has to build one beside it. The key is named
// by the kit, only a single-line enabled secure field offers it, and pressing it really unmasks the value.

const _strings = FlareStrings();

Widget _host(Widget field) => FlareStringsScope(
  strings: _strings,
  child: MaterialApp(
    home: FlareTheme(
      mode: FlareThemeMode.light,
      child: Scaffold(body: Center(child: field)),
    ),
  ),
);

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void main() {
  testWidgets('credential inputs expose distinct accessible field names', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final account = TextEditingController();
    final password = TextEditingController();
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            FlareInput(controller: account, semanticLabel: 'Account'),
            FlareInput(
              controller: password,
              semanticLabel: 'Password',
              secure: true,
            ),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Account'), findsOneWidget);
    expect(find.bySemanticsLabel('Password'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'sandbox-user');
    await tester.enterText(find.byType(TextField).at(1), 'test-password');
    expect(account.text, 'sandbox-user');
    expect(password.text, 'test-password');
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isTrue,
    );
    semantics.dispose();
  });
  testWidgets('the key unmasks the value and renames itself', (tester) async {
    await tester.pumpWidget(
      _host(
        FlareInput(
          controller: TextEditingController(text: 'hunter2'),
          secure: true,
          revealable: true,
        ),
      ),
    );

    expect(_field(tester).obscureText, isTrue);
    expect(find.bySemanticsLabel(_strings.inputReveal), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(_strings.inputReveal));
    await tester.pumpAndSettle();

    expect(
      _field(tester).obscureText,
      isFalse,
      reason: 'the value is readable',
    );
    expect(find.bySemanticsLabel(_strings.inputHide), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(_strings.inputHide));
    await tester.pumpAndSettle();

    expect(
      _field(tester).obscureText,
      isTrue,
      reason: 'pressing it again masks the value',
    );
  });

  testWidgets('only a single-line enabled secure field offers the key', (
    tester,
  ) async {
    for (final field in <FlareInput>[
      const FlareInput(secure: true),
      const FlareInput(revealable: true),
      const FlareInput(secure: true, revealable: true, multiline: true),
      const FlareInput(secure: true, revealable: true, disabled: true),
    ]) {
      await tester.pumpWidget(_host(field));
      expect(
        find.bySemanticsLabel(_strings.inputReveal),
        findsNothing,
        reason:
            'secure=${field.secure} revealable=${field.revealable} '
            'multiline=${field.multiline} disabled=${field.disabled}',
      );
    }
  });
}
