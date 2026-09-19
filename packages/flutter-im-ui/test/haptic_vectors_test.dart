import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared haptics table (`spec/haptic-vectors.json`) is the one rule three kits follow for the tick a
/// gesture gives when it crosses the line where letting go starts to mean something else: one tick per
/// change of state, in both directions, never per frame.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final table =
      jsonDecode(File('../../spec/haptic-vectors.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  test('the table still carries its cases', () {
    expect(cases.length, greaterThanOrEqualTo(8));
  });

  for (final vector in cases) {
    final id = vector['id'] as String;
    test('haptic run: $id', () {
      final states = (vector['states'] as List).cast<bool>();
      var ticks = 0;
      for (var i = 1; i < states.length; i++) {
        if (flareHapticCrossed(was: states[i - 1], now: states[i])) ticks += 1;
      }
      expect(
        ticks,
        (vector['expected'] as Map)['ticks'],
        reason: '$id: ${vector['why']}',
      );
    });
  }

  /// The rule above is arithmetic; this is the tick actually leaving the kit. A swipe past the arming
  /// distance must reach the platform once — the one place in this program where a haptic can be proven
  /// rather than described.
  testWidgets('a swipe that arms asks the platform for exactly one tick', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareMessageList(
            currentUserId: 'me',
            messages: [
              FlareMessageData(
                id: 'm1',
                senderId: 'ann',
                senderName: 'Ann',
                content: FlareTextContent('第一条'),
              ),
            ],
            onSwipeReply: (_) {},
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('第一条')));
    // The move that crosses the touch slop starts the drag; travel counts from there.
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(calls, isEmpty, reason: 'still short of the arming distance');

    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(calls, ['HapticFeedbackType.selectionClick']);

    // Held past the line, not a drum.
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(calls, hasLength(1));

    // Back out of the armed zone: letting go means something else again.
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(calls, hasLength(2));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
