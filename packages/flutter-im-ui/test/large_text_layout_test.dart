import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Round 5 Batch 1 smoke: at twice the text size these surfaces overflowed
// (recording bar while cancelling by 63 px, voice player by 26 px, group call
// by 82 px, the date sheet at 800x600 by 15 px). Text never shrinks to fit:
// waveforms thin out, labels wrap, and a view scrolls when nothing else can
// give.

const _strings = FlareStrings();

Widget _host(Widget child, TextDirection direction, {double scale = 2}) =>
    MaterialApp(
      builder: (context, content) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(textDirection: direction, child: content!),
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Future<void> _expectNoOverflow(
  WidgetTester tester,
  Widget child,
  String reason, {
  Size view = const Size(320, 1600),
}) async {
  tester.view.physicalSize = view;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  for (final direction in TextDirection.values) {
    await tester.pumpWidget(_host(child, direction));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: '$reason $direction');
  }
}

List<FlareCallParticipant> _people(int count) => [
  for (var i = 0; i < count; i++)
    FlareCallParticipant(id: 'p$i', name: 'Person $i', isSelf: i == 0),
];

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('recording bar while cancelling fits at 2x (w$width)', (
      tester,
    ) async {
      await _expectNoOverflow(
        tester,
        FlareVoiceRecordingBar(
          durationLabel: '0:07',
          cancelling: true,
          onCancel: () {},
        ),
        'recording cancel',
        view: Size(width, 1600),
      );
      // The label keeps all of its text.
      expect(find.text(_strings.releaseToCancel), findsOneWidget);
    });

    testWidgets('voice player fits at 2x (w$width)', (tester) async {
      await _expectNoOverflow(
        tester,
        FlareVoicePlayer(
          durationLabel: '0:07',
          transcript: 'hello',
          transcriptOpen: true,
          onToggle: () {},
          onToggleTranscript: () {},
        ),
        'voice player',
        view: Size(width, 1600),
      );
      expect(find.text(_strings.hideTranscript), findsOneWidget);
    });

    testWidgets('group call fits a short box at 2x (w$width)', (tester) async {
      for (final count in [0, 3, 9]) {
        await _expectNoOverflow(
          tester,
          SizedBox(
            height: 300,
            child: FlareGroupCallView(
              participants: _people(count),
              mode: FlareCallMode.video,
              state: 'connected',
              onMinimize: () {},
              onHangup: () {},
            ),
          ),
          'group call with $count',
          view: Size(width, 1600),
        );
      }
      // Hang up is still there to reach by scrolling.
      expect(find.byTooltip(_strings.hangUp), findsOneWidget);
    });
  }

  testWidgets(
    'group call keeps the grid between header and keys when it fits',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: FlareGroupCallView(
            participants: _people(4),
            mode: FlareCallMode.audio,
            state: 'connected',
            onHangup: () {},
          ),
        ),
      );
      final grid = tester.getRect(find.byType(GridView));
      final hangUp = tester.getRect(find.byTooltip(_strings.hangUp));
      // The keys sit at the bottom of the screen and the grid fills the rest.
      expect(hangUp.bottom, lessThanOrEqualTo(844));
      expect(hangUp.bottom, greaterThan(844 - 140));
      expect(grid.bottom, lessThanOrEqualTo(hangUp.top));
      expect(grid.height, greaterThan(400));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('date sheet scrolls instead of overflowing at 800x600 and 2x', (
    tester,
  ) async {
    for (final size in const [Size(800, 600), Size(320, 640), Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, content) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: content!,
          ),
          home: Scaffold(
            body: Center(
              child: FlareDatePicker(value: '2026-09-15', onChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.tap(find.text('2026-09-15'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      // The footer is reachable.
      await tester.dragUntilVisible(
        find.text(_strings.today),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -80),
      );
      expect(find.text(_strings.today), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
