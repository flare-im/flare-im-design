import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared queue table (`spec/in-app-notification-vectors.json`): items fed
/// in, what shows and waits out, and when the visible banner's time starts
/// over. The Vue, SwiftUI and Compose kits run the same file.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/in-app-notification-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  FlareInAppNotification item(String text) {
    final parts = text.split('/');
    return FlareInAppNotification(
      collapseId: parts[0],
      conversationId: parts[0].substring(2),
      title: parts[0],
      body: parts[1],
    );
  }

  String? written(FlareInAppNotification? entry) =>
      entry == null ? null : '${entry.collapseId}/${entry.body}';

  test('keeps the table limits', () {
    final limits = table['limits'] as Map<String, dynamic>;
    expect(inAppNotificationDuration.inMilliseconds, limits['durationMs']);
    expect(inAppNotificationPendingLimit, limits['pendingLimit']);
  });

  for (final vector
      in (table['cases'] as List).cast<Map<String, dynamic>>()) {
    test(vector['name'], () {
      final presenter = FlareInAppNotifications();
      final steps = (vector['steps'] as List).cast<Map<String, dynamic>>();
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final before = presenter.revision;
        switch (step['op']) {
          case 'present':
            presenter.present(item(step['item'] as String));
          case 'dismiss':
            presenter.dismiss();
          case 'clear':
            presenter.clear((step['collapseIds'] as List).cast<String>());
          case 'clearAll':
            presenter.clearAll();
        }
        final where = '${vector['name']} step ${i + 1}';
        expect(written(presenter.current), step['current'], reason: where);
        expect(
          presenter.pending.map(written).toList(),
          (step['pending'] as List).cast<String>(),
          reason: where,
        );
        expect(presenter.revision != before, step['restart'], reason: where);
      }
    });
  }

  const alice = FlareInAppNotification(
    collapseId: 'c:a',
    conversationId: 'a',
    messageId: 'm1',
    title: 'Alice',
    body: 'are you free?',
    count: 3,
    channel: FlareInAppNotificationChannel.mentions,
  );
  const bob = FlareInAppNotification(
    collapseId: 'c:b',
    conversationId: 'b',
    title: 'Bob',
    body: 'lunch',
  );

  test('reads the label, the title, the tag, the count and the body', () {
    expect(
      alice.spoken(flareStringsEnglish),
      'New message, Alice, [Mention], [3 messages], are you free?',
    );
    expect(
      alice.spoken(const FlareStrings()),
      '新消息, Alice, [有人@我], [3条], are you free?',
    );
    expect(bob.spoken(flareStringsEnglish), 'New message, Bob, lunch');
  });

  Widget app(FlareInAppNotifications notifications, {
    void Function(String, String?)? onOpen,
  }) => MaterialApp(
    builder: (context, child) => FlareInAppNotificationHost(
      notifications: notifications,
      onOpen: onOpen,
      child: child!,
    ),
    home: const Scaffold(body: SizedBox.expand()),
  );

  testWidgets('shows the banner with its tag and count', (tester) async {
    final notifications = FlareInAppNotifications();
    await tester.pumpWidget(app(notifications));
    notifications.present(alice);
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('[有人@我]', findRichText: true), findsOneWidget);
    expect(find.textContaining('[3条]', findRichText: true), findsOneWidget);
    await tester.pump(inAppNotificationDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('dismisses after the kit time and shows the next one', (
    tester,
  ) async {
    final notifications = FlareInAppNotifications();
    await tester.pumpWidget(app(notifications));
    notifications
      ..present(alice)
      ..present(bob);
    // The time runs from the moment the banner shows.
    await tester.pump();
    await tester.pump(
      inAppNotificationDuration - const Duration(milliseconds: 1),
    );
    expect(notifications.current?.collapseId, 'c:a');
    await tester.pump(const Duration(milliseconds: 1));
    expect(notifications.current?.collapseId, 'c:b');
    await tester.pumpAndSettle();
    await tester.pump(inAppNotificationDuration);
    await tester.pumpAndSettle();
    expect(notifications.current, isNull);
  });

  testWidgets('a finger on the banner stops the time', (tester) async {
    final notifications = FlareInAppNotifications();
    await tester.pumpWidget(app(notifications));
    notifications.present(alice);
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Alice')),
    );
    await tester.pump(inAppNotificationDuration * 2);
    expect(notifications.current?.collapseId, 'c:a');
    // Lifting without a tap (a cancelled touch) starts the time over.
    await gesture.cancel();
    await tester.pump(inAppNotificationDuration);
    await tester.pumpAndSettle();
    expect(notifications.current, isNull);
  });

  testWidgets('a tap opens the conversation and takes the banner away', (
    tester,
  ) async {
    final opened = <String?>[];
    final notifications = FlareInAppNotifications();
    await tester.pumpWidget(
      app(notifications, onOpen: (c, m) => opened.addAll([c, m])),
    );
    notifications.present(alice);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(opened, ['a', 'm1']);
    expect(notifications.current, isNull);
  });

  testWidgets('a swipe up dismisses', (tester) async {
    final notifications = FlareInAppNotifications();
    await tester.pumpWidget(app(notifications));
    notifications.present(alice);
    await tester.pumpAndSettle();
    await tester.drag(find.text('Alice'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(notifications.current, isNull);
  });
}
