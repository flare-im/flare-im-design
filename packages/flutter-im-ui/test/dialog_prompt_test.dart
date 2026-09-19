import 'dart:async';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-092 (K2): one async single-value prompt next to the confirm presenter,
// with the busy state while the host's submit runs, an inline error that
// keeps the draft, and retry by confirming again.

const _strings = FlareStrings();

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return context;
}

Finder _button(String label) => find.widgetWithText(FlareButton, label);

void main() {
  testWidgets('confirm returns the trimmed value; cancel returns null', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    String? result = 'untouched';
    unawaited(
      FlareDialog.prompt(
        context,
        title: '修改备注',
        message: '只有你能看到备注。',
        initialValue: 'Ann',
        placeholder: '备注名',
        maxLength: 20,
      ).then((value) => result = value),
    );
    await tester.pumpAndSettle();
    expect(find.text('修改备注'), findsOneWidget);
    expect(find.text('只有你能看到备注。'), findsOneWidget);
    expect(find.text('Ann'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Ann Lee  ');
    await tester.pump();
    await tester.tap(_button(_strings.confirm));
    await tester.pumpAndSettle();
    expect(result, 'Ann Lee');
    expect(find.byType(FlareDialog), findsNothing);

    unawaited(
      FlareDialog.prompt(
        context,
        title: '修改备注',
      ).then((value) => result = value),
    );
    await tester.pumpAndSettle();
    await tester.tap(_button(_strings.cancel));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('a blank value cannot be confirmed unless empty is allowed', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    unawaited(FlareDialog.prompt(context, title: '群名称'));
    await tester.pumpAndSettle();
    FlareButton confirm() =>
        tester.widget<FlareButton>(_button(_strings.confirm));
    expect(confirm().disabled, isTrue);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(confirm().disabled, isTrue);
    await tester.enterText(find.byType(TextField), '发版群');
    await tester.pump();
    expect(confirm().disabled, isFalse);
    await tester.tap(_button(_strings.cancel));
    await tester.pumpAndSettle();

    String? cleared = 'untouched';
    unawaited(
      FlareDialog.prompt(
        context,
        title: '修改备注',
        initialValue: 'Ann',
        allowEmpty: true,
      ).then((value) => cleared = value),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(_button(_strings.confirm));
    await tester.pumpAndSettle();
    expect(cleared, '');
  });

  testWidgets('busy while submitting, an error keeps the draft, and '
      'confirming again retries', (tester) async {
    final context = await _pumpHost(tester);
    final submitted = <String>[];
    var pending = Completer<void>();
    String? result;
    unawaited(
      FlareDialog.prompt(
        context,
        title: '评论',
        confirmText: '发送',
        onSubmit: (value) {
          submitted.add(value);
          return pending.future;
        },
      ).then((value) => result = value),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '好看');
    await tester.pump();
    await tester.tap(_button('发送'));
    await tester.pump();
    expect(submitted, ['好看']);
    // Busy: nothing can be pressed or typed, and back does not close it.
    expect(tester.widget<FlareButton>(_button('发送')).loading, isTrue);
    expect(
      tester.widget<FlareButton>(_button(_strings.cancel)).disabled,
      isTrue,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(FlareDialog), findsOneWidget);

    pending.completeError(StateError('network down'));
    await tester.pumpAndSettle();
    expect(find.byType(FlareDialog), findsOneWidget);
    expect(find.textContaining('network down'), findsOneWidget);
    expect(find.text('好看'), findsOneWidget, reason: 'the draft is kept');
    expect(result, isNull);

    pending = Completer<void>()..complete();
    await tester.tap(_button('发送'));
    await tester.pumpAndSettle();
    expect(submitted, ['好看', '好看']);
    expect(find.byType(FlareDialog), findsNothing);
    expect(result, '好看');
  });
}
