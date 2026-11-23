import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'OTP sends only an explicit action and remains cancellable while busy',
    (tester) async {
      var sends = 0, submits = 0, cancels = 0;
      final edits = <String>[];
      Widget sheet({bool busy = false, int cooldown = 0}) => MaterialApp(
        home: Scaffold(
          body: FlareReauthSheet(
            destinations: const [
              FlareReauthDestination(id: 'opaque', label: 'a•••@example.test'),
            ],
            selectedId: 'opaque',
            code: '',
            canSend: true,
            canSubmit: true,
            sending: busy,
            resendInSeconds: cooldown,
            onSelectDestination: (_) {},
            onCodeChange: edits.add,
            onSend: () => sends++,
            onSubmit: () => submits++,
            onCancel: () => cancels++,
          ),
        ),
      );
      final strings = FlareStrings();
      await tester.pumpWidget(sheet());
      await tester.enterText(find.byType(TextField), '123456');
      expect(edits.last, '123456');
      await tester.tap(
        find.widgetWithText(FlareButton, strings.reauthSendCode),
      );
      await tester.tap(find.widgetWithText(FlareButton, strings.confirm));
      expect(sends, 1);
      expect(submits, 1);
      await tester.pumpWidget(sheet(busy: true, cooldown: 20));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(
          FlareButton,
          strings.reauthResendIn.replaceAll('{seconds}', '20'),
        ),
      );
      await tester.tap(find.widgetWithText(FlareButton, strings.confirm));
      expect(sends, 1);
      expect(submits, 1);
      await tester.tap(find.widgetWithText(FlareButton, strings.cancel));
      expect(cancels, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
