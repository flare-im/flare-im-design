import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_permission_prompt.dart';
import 'package:flare_im_ui/src/tokens/flare_strings.dart';

void main() {
  group('FlareStrings defaults', () {
    test('plain strings are non-empty', () {
      const s = FlareStrings();
      final values = <String>[
        s.microphone,
        s.camera,
        s.hangUp,
        s.send,
        s.cancel,
        s.confirm,
        s.retry,
        s.noMessages,
        s.noContent,
        s.groupCall,
        s.callConnected,
        s.callFailed,
        s.permissionAllow,
        s.permissionStateDenied,
        s.permissionThisFeature,
      ];
      for (final v in values) {
        expect(v.trim(), isNotEmpty);
      }
    });

    test('formatted strings interpolate their arguments', () {
      const s = FlareStrings();
      expect(s.readTab(3), contains('3'));
      expect(s.unreadTab(0), contains('0'));
      expect(s.memberCount(7), contains('7'));
      expect(s.selectedCount(2), contains('2'));
      expect(s.viewAll(9), contains('9'));
      expect(s.pollOptionHint(1), contains('1'));
      expect(s.translatedBy('DeepL'), contains('DeepL'));
      expect(s.selfSuffix('Alice'), contains('Alice'));
      expect(s.joinedCount(4, '已接通'), allOf(contains('4'), contains('已接通')));
      expect(s.yearMonth(2026, 9), allOf(contains('2026'), contains('9')));
      expect(s.wordCharCount(2, 8), allOf(contains('2'), contains('8')));
      expect(s.newMessages(5), contains('5'));
      expect(s.newMessages(0), isNotEmpty);
      expect(s.permissionTitle('麦克风'), contains('麦克风'));
      expect(
        s.permissionDeniedDescription('发送语音消息', '使用麦克风'),
        allOf(contains('发送语音消息'), contains('使用麦克风')),
      );
    });

    test('copyWith replaces only the given fields', () {
      const base = FlareStrings();
      final patched = base.copyWith(
        send: 'Send',
        memberCount: (n) => '$n members',
      );
      expect(patched.send, 'Send');
      expect(patched.memberCount(3), '3 members');
      // untouched fields keep the defaults
      expect(patched.cancel, base.cancel);
      expect(patched.readTab(1), base.readTab(1));
    });
  });

  group('FlareStringsScope', () {
    testWidgets('returns defaults when there is no ancestor scope',
        (tester) async {
      late FlareStrings resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = FlareStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(resolved.send, const FlareStrings().send);
      expect(resolved.memberCount(2), const FlareStrings().memberCount(2));
    });

    testWidgets('an ancestor scope overrides the defaults', (tester) async {
      late FlareStrings resolved;
      await tester.pumpWidget(
        FlareStringsScope(
          strings: const FlareStrings().copyWith(
            send: 'Send',
            noMessages: 'No messages yet',
            memberCount: (n) => '$n members',
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                resolved = FlareStrings.of(context);
                return Text(resolved.noMessages);
              },
            ),
          ),
        ),
      );
      expect(resolved.send, 'Send');
      expect(resolved.memberCount(2), '2 members');
      expect(find.text('No messages yet'), findsOneWidget);
      // fields the host did not override still fall back to the kit defaults
      expect(resolved.cancel, const FlareStrings().cancel);
    });

    testWidgets('rebuilds dependents when the scope value changes',
        (tester) async {
      Widget build(FlareStrings strings) => FlareStringsScope(
            strings: strings,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Text(FlareStrings.of(context).send),
              ),
            ),
          );

      await tester.pumpWidget(build(const FlareStrings()));
      expect(find.text('发送'), findsOneWidget);

      await tester.pumpWidget(build(const FlareStrings().copyWith(send: 'Send')));
      await tester.pump();
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('发送'), findsNothing);
    });

    testWidgets('a component reads its copy from the ambient scope',
        (tester) async {
      await tester.pumpWidget(
        FlareStringsScope(
          strings: const FlareStrings().copyWith(
            microphone: 'Microphone',
            permissionTitle: (noun) => 'Need $noun',
            permissionStateDenied: 'Denied',
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: FlarePermissionPrompt(
                kind: FlarePermissionKind.microphone,
                state: FlarePermissionState.denied,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Need Microphone'), findsOneWidget);
      expect(find.text('Denied'), findsOneWidget);
    });
  });
}
