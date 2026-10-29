import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared call record table (`spec/call-record-vectors.json`): the status
/// line, its tone and the one action, then the card that draws them.
void main() {
  final table =
      jsonDecode(File('../../spec/call-record-vectors.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();
  final durations = (table['duration'] as List).cast<Map<String, dynamic>>();

  T byName<T extends Enum>(List<T> values, String name) =>
      values.firstWhere((v) => v.name == name);
  T? maybe<T extends Enum>(List<T> values, Object? name) =>
      name == null ? null : byName(values, name as String);

  FlareCallRecordCard cardOf(
    Map<String, dynamic> input, {
    VoidCallback? onJoin,
    VoidCallback? onCallBack,
  }) => FlareCallRecordCard(
    media: byName(FlareCallMode.values, input['media'] as String),
    scope: byName(FlareCallRecordScope.values, input['scope'] as String),
    state: byName(FlareCallRecordState.values, input['state'] as String),
    endReason: maybe(FlareCallEndReason.values, input['endReason']),
    durationSeconds: input['durationSeconds'] as int?,
    joinedCount: input['joinedCount'] as int?,
    viewerIsInitiator: input['viewerIsInitiator'] as bool,
    canJoin: input['canJoin'] as bool,
    canCallBack: input['canCallBack'] as bool,
    disabled: input['disabled'] as bool? ?? false,
    busy: input['busy'] as bool? ?? false,
    onJoin: onJoin ?? () {},
    onCallBack: onCallBack ?? () {},
  );

  Widget host(Widget child, {FlareStrings strings = const FlareStrings()}) =>
      MaterialApp(
        home: FlareStringsScope(
          strings: strings,
          child: Scaffold(body: Center(child: child)),
        ),
      );

  test('formats a call length the way the table does', () {
    expect(durations.length, greaterThanOrEqualTo(10));
    for (final row in durations) {
      expect(
        flareCallDurationLabel(row['seconds'] as int),
        row['label'],
        reason: '${row['seconds']}',
      );
    }
  });

  test('derives status, tone, action and copy for every case', () {
    expect(cases.length, greaterThanOrEqualTo(30));
    for (final row in cases) {
      final id = row['id'] as String;
      final card = cardOf(row['input'] as Map<String, dynamic>);
      expect(card.status.name, row['status'], reason: id);
      expect(flareCallRecordTone(card.status).name, row['tone'], reason: id);
      expect(card.action?.name, row['action'], reason: id);
      final text = row['text'] as Map<String, dynamic>;
      expect(card.statusFor(const FlareStrings()), text['zh'], reason: id);
      expect(card.statusFor(flareStringsEnglish), text['en'], reason: id);
    }
  });

  testWidgets('draws every case: copy, action and whether it takes a tap', (
    tester,
  ) async {
    for (final row in cases) {
      final id = row['id'] as String;
      final card = cardOf(row['input'] as Map<String, dynamic>);
      await tester.pumpWidget(host(card));
      expect(
        find.text((row['text'] as Map<String, dynamic>)['zh'] as String),
        findsOneWidget,
        reason: id,
      );
      final action = find.byKey(FlareCallRecordCard.actionKey);
      expect(
        action,
        row['action'] == null ? findsNothing : findsOneWidget,
        reason: id,
      );
      if (row['action'] != null) {
        final button = tester.widget<FlareButton>(action);
        expect(button.loading, !(row['actionEnabled'] as bool), reason: id);
      }
    }
  });

  testWidgets('join and call back reach the host once, busy takes no tap', (
    tester,
  ) async {
    var joins = 0;
    var callBacks = 0;
    await tester.pumpWidget(
      host(
        FlareCallRecordCard(
          media: FlareCallMode.video,
          scope: FlareCallRecordScope.group,
          state: FlareCallRecordState.ongoing,
          joinedCount: 4,
          viewerIsInitiator: false,
          canJoin: true,
          canCallBack: false,
          onJoin: () => joins++,
          onCallBack: () => callBacks++,
        ),
      ),
    );
    expect(find.text('加入'), findsOneWidget);
    await tester.tap(find.byKey(FlareCallRecordCard.actionKey));
    expect((joins, callBacks), (1, 0));

    await tester.pumpWidget(
      host(
        FlareCallRecordCard(
          media: FlareCallMode.audio,
          scope: FlareCallRecordScope.single,
          state: FlareCallRecordState.ended,
          endReason: FlareCallEndReason.completed,
          durationSeconds: 75,
          viewerIsInitiator: true,
          canJoin: false,
          canCallBack: true,
          onJoin: () => joins++,
          onCallBack: () => callBacks++,
        ),
        strings: flareStringsEnglish,
      ),
    );
    expect(find.text('Duration 01:15'), findsOneWidget);
    expect(find.text('Call back'), findsOneWidget);
    await tester.tap(find.byKey(FlareCallRecordCard.actionKey));
    expect((joins, callBacks), (1, 1));

    await tester.pumpWidget(
      host(
        FlareCallRecordCard(
          media: FlareCallMode.audio,
          scope: FlareCallRecordScope.single,
          state: FlareCallRecordState.ended,
          endReason: FlareCallEndReason.missed,
          viewerIsInitiator: false,
          canJoin: false,
          canCallBack: true,
          busy: true,
          onCallBack: () => callBacks++,
        ),
      ),
    );
    await tester.tap(
      find.byKey(FlareCallRecordCard.actionKey),
      warnIfMissed: false,
    );
    expect(callBacks, 1);
  });

  testWidgets('names the media and the status, and paints a missed call in '
      'the danger tone', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const FlareCallRecordCard(
          media: FlareCallMode.audio,
          scope: FlareCallRecordScope.single,
          state: FlareCallRecordState.ended,
          endReason: FlareCallEndReason.missed,
          viewerIsInitiator: false,
          canJoin: false,
          canCallBack: false,
        ),
      ),
    );
    expect(find.bySemanticsLabel('语音通话'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('语音通话'));
    expect(node.value, '未接听');
    final context = tester.element(find.byType(FlareCallRecordCard));
    final colors = FlareColors.of(context);
    final status = tester.widget<Text>(find.text('未接听'));
    expect(status.style?.color, colors.errorText);
    final disc = tester.widget<Container>(
      find.byKey(FlareCallRecordCard.iconKey),
    );
    expect(
      (disc.decoration! as BoxDecoration).color,
      colors.error.withValues(alpha: FlareOpacity.tintWeak),
    );
    semantics.dispose();
  });

  testWidgets('keeps the record and drops the action when the plugin is '
      'unavailable', (tester) async {
    await tester.pumpWidget(
      host(
        const FlareCallRecordCard(
          media: FlareCallMode.audio,
          scope: FlareCallRecordScope.group,
          state: FlareCallRecordState.ongoing,
          joinedCount: 2,
          viewerIsInitiator: false,
          canJoin: true,
          canCallBack: true,
          disabled: true,
        ),
      ),
    );
    expect(find.text('群通话进行中 · 2 人'), findsOneWidget);
    expect(find.byKey(FlareCallRecordCard.actionKey), findsNothing);
  });

  testWidgets('is a card surface at the compact card width', (tester) async {
    await tester.pumpWidget(
      host(
        const FlareCallRecordCard(
          media: FlareCallMode.video,
          scope: FlareCallRecordScope.single,
          state: FlareCallRecordState.ringing,
          viewerIsInitiator: true,
          canJoin: false,
          canCallBack: false,
        ),
      ),
    );
    expect(find.byKey(FlareMessageCardShell.surfaceKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(FlareMessageCardShell.surfaceKey)).width,
      FlareSizes.componentRichCardCompactWidth,
    );
  });

  testWidgets('the 1:1 call view minimizes only when the host can', (
    tester,
  ) async {
    var minimized = 0;
    await tester.pumpWidget(
      host(
        const FlareCallView(
          peerName: 'Ada',
          mode: FlareCallMode.audio,
          state: FlareCallState.connected,
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(const FlareStrings().callMinimize),
      findsNothing,
    );

    await tester.pumpWidget(
      host(
        FlareCallView(
          peerName: 'Ada',
          mode: FlareCallMode.audio,
          state: FlareCallState.connected,
          onMinimize: () => minimized++,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(const FlareStrings().callMinimize));
    expect(minimized, 1);
  });

  testWidgets('the group call view reads the shared call state', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareGroupCallView(
          participants: [FlareCallParticipant(id: 'u1', name: 'Ada')],
          mode: FlareCallMode.audio,
          state: FlareCallState.reconnecting,
        ),
      ),
    );
    expect(
      find.textContaining(const FlareStrings().callReconnecting),
      findsOneWidget,
    );
  });
}
