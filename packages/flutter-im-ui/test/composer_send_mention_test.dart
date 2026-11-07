import 'dart:async';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

const _members = [
  FlareMentionCandidate(id: 'u1', name: 'Ann'),
  FlareMentionCandidate(id: 'u2', name: 'Bob'),
];

Future<void> _type(WidgetTester tester, String text) async {
  tester.testTextInput.enterText(text);
  await tester.pump();
}

void main() {
  group('FlareComposer send result', () {
    testWidgets('a pending send shows busy, ignores repeats, clears on true', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);
      final pending = Completer<bool>();
      final sent = <String>[];
      var replyCleared = 0;
      await tester.pumpWidget(
        _host(
          FlareComposer(
            controller: controller,
            replyTo: const FlareReplyTarget(senderName: 'Bob', summary: 'hey'),
            onCancelReply: () => replyCleared++,
            onSend: (text) {
              sent.add(text);
              return pending.future;
            },
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();
      expect(sent, ['hello']);
      expect(
        find.descendant(
          of: find.byType(FlareComposerSendButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(const FlareStrings().messageSending),
        findsOneWidget,
      );
      await tester.tap(find.byType(FlareComposerSendButton));
      await tester.pump();
      expect(sent, ['hello'], reason: 'repeat sends wait for the first');
      expect(controller.text, 'hello');

      pending.complete(true);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(replyCleared, 1);
      expect(find.byIcon(Icons.send_outlined), findsOneWidget);
    });

    testWidgets('false, or an error, keeps the text and the reply', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var replyCleared = 0;
      late FutureOr<bool> Function(String) outcome;
      await tester.pumpWidget(
        _host(
          FlareComposer(
            controller: controller,
            replyTo: const FlareReplyTarget(senderName: 'Bob', summary: 'hey'),
            onCancelReply: () => replyCleared++,
            onSend: (text) => outcome(text),
          ),
        ),
      );
      final failures = <FutureOr<bool> Function(String)>[
        (_) => false,
        (_) async => false,
        (_) => throw StateError('offline'),
        (_) async => throw StateError('offline'),
      ];
      for (final failure in failures) {
        outcome = failure;
        controller.text = 'keep me';
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send_outlined));
        await tester.pump();
        await tester.pump();
        expect(controller.text, 'keep me');
        expect(find.byIcon(Icons.send_outlined), findsOneWidget);
      }
      expect(replyCleared, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('text typed while the send is on its way stays', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'first');
      addTearDown(controller.dispose);
      final pending = Completer<bool>();
      await tester.pumpWidget(
        _host(
          FlareComposer(controller: controller, onSend: (_) => pending.future),
        ),
      );
      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();
      controller.text = 'first and more';
      pending.complete(true);
      await tester.pump();
      expect(controller.text, 'first and more');
    });

    testWidgets('busy stays still under reduced motion', (tester) async {
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);
      final pending = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(
                body: FlareComposer(
                  controller: controller,
                  onSend: (_) => pending.future,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      pending.complete(false);
      await tester.pump();
    });
  });

  group('FlareComposer mentions', () {
    Future<TextEditingController> pumpComposer(
      WidgetTester tester, {
      List<FlareMentionCandidate> candidates = _members,
    }) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          FlareComposer(
            controller: controller,
            mentionCandidates: candidates,
            onSend: (_) => true,
          ),
        ),
      );
      await tester.tap(find.byType(ExtendedTextField));
      await tester.pump();
      return controller;
    }

    testWidgets('a typed "@" keeps the editor focused and filters candidates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = await pumpComposer(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      await tester.pump();
      await _type(tester, 'hi ');
      await _type(tester, 'hi @');
      await tester.pumpAndSettle();
      final picker = find.byType(FlareMentionPicker);
      expect(picker, findsOneWidget);
      expect(find.byType(FlareBottomSheet), findsNothing);
      final editor = tester.widget<ExtendedTextField>(
        find.byType(ExtendedTextField),
      );
      expect(editor.focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      await _type(tester, 'hi @An');
      await tester.pumpAndSettle();
      expect(find.text('Ann'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await tester.tap(find.text('Ann'));
      await tester.pumpAndSettle();
      expect(find.byType(FlareMentionPicker), findsNothing);
      expect(controller.text, 'hi @Ann ');
      expect(controller.selection.baseOffset, 'hi @Ann '.length);
      expect(editor.focusNode!.hasFocus, isTrue);
    });

    testWidgets('closing the picker leaves the "@"', (tester) async {
      final controller = await pumpComposer(tester);
      await _type(tester, '@');
      await tester.pumpAndSettle();
      expect(find.byType(FlareMentionPicker), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(FlareMentionPicker), findsNothing);
      expect(controller.text, '@');
    });

    testWidgets('the open picker updates its roster and rejects a stale pick', (
      tester,
    ) async {
      const everyone = FlareMentionCandidate(
        id: '__all__',
        name: 'Everyone in the group',
        isEveryone: true,
      );
      final candidates = ValueNotifier<List<FlareMentionCandidate>>([
        everyone,
        ..._members,
      ]);
      final controller = TextEditingController();
      addTearDown(candidates.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder(
            valueListenable: candidates,
            builder: (_, visible, _) => FlareComposer(
              controller: controller,
              mentionCandidates: visible,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ExtendedTextField));
      await _type(tester, '@');
      await tester.pumpAndSettle();
      final picker = find.byType(FlareMentionPicker);
      expect(find.text('Everyone in the group'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      final oldSelection = tester.widget<FlareMentionPicker>(picker).onSelect!;

      candidates.value = [_members.first];
      await tester.pumpAndSettle();
      expect(picker, findsOneWidget);
      expect(find.text('Ann'), findsOneWidget);
      expect(find.text('Everyone in the group'), findsNothing);
      expect(find.text('Bob'), findsNothing);

      oldSelection(_members.last);
      await tester.pumpAndSettle();
      expect(controller.text, '@');

      await tester.tap(find.text('Ann'));
      await tester.pumpAndSettle();
      expect(controller.text, '@Ann ');
    });

    testWidgets('an "@" inside a word or without candidates stays text', (
      tester,
    ) async {
      final controller = await pumpComposer(tester);
      await _type(tester, 'mail');
      await _type(tester, 'mail@');
      await tester.pumpAndSettle();
      expect(find.byType(FlareMentionPicker), findsNothing);
      expect(controller.text, 'mail@');

      final plain = await pumpComposer(tester, candidates: const []);
      await _type(tester, '@');
      await tester.pumpAndSettle();
      expect(find.byType(FlareMentionPicker), findsNothing);
      expect(plain.text, '@');
    });

    testWidgets('the mention tool picks into the caret, or types "@"', (
      tester,
    ) async {
      final controller = await pumpComposer(tester);
      await _type(tester, 'ping ');
      await tester.tap(find.byIcon(flareIconMap['mention']!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();
      expect(controller.text, 'ping @Bob ');

      final plain = await pumpComposer(tester, candidates: const []);
      await tester.tap(find.byIcon(flareIconMap['mention']!));
      await tester.pumpAndSettle();
      expect(find.byType(FlareMentionPicker), findsNothing);
      expect(plain.text, '@');
    });
  });
}
