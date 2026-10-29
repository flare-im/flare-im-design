import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/action_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// An audio call can be switched to video: the call keys draw a "switch to
// video" key after the speaker when the host supplies onStartVideo, never in a
// video call; the one-to-one and the group call screens forward it.

const _strings = FlareStrings();

Widget _host(Widget child, {FlareStrings strings = _strings}) => MaterialApp(
  home: FlareStringsScope(
    strings: strings,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(width: 390, height: 844, child: child),
    ),
  ),
);

/// The keys' names, in display order.
List<String> _keys(WidgetTester tester) => tester
    .widgetList<IconButton>(find.byType(IconButton))
    .map((button) => button.tooltip ?? '')
    .toList();

void main() {
  testWidgets('sits after the speaker in an audio call and asks the host', (
    tester,
  ) async {
    var asked = 0;
    await tester.pumpWidget(
      _host(
        FlareCallControls(
          mode: FlareCallMode.audio,
          onToggleMute: () {},
          onToggleSpeaker: () {},
          onAddMember: () {},
          onHangup: () {},
          onStartVideo: () => asked++,
        ),
      ),
    );
    expect(_keys(tester), [
      _strings.microphone,
      _strings.speaker,
      _strings.callSwitchToVideo,
      _strings.addMember,
      _strings.hangUp,
    ]);
    // The video glyph, captioned by the strings table.
    final key = find.byTooltip(_strings.callSwitchToVideo);
    expect(
      find.descendant(of: key, matching: find.byIcon(flareIconGlyph('video'))),
      findsOneWidget,
    );
    expect(find.text(_strings.callSwitchToVideo), findsOneWidget);
    await tester.tap(key);
    expect(asked, 1);
  });

  testWidgets('is not drawn in a video call, nor without onStartVideo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(FlareCallControls(mode: FlareCallMode.video, onStartVideo: () {})),
    );
    expect(find.byTooltip(_strings.callSwitchToVideo), findsNothing);

    await tester.pumpWidget(
      _host(const FlareCallControls(mode: FlareCallMode.audio)),
    );
    expect(_keys(tester), [
      _strings.microphone,
      _strings.speaker,
      _strings.hangUp,
    ]);
  });

  testWidgets('is labelled from the host strings', (tester) async {
    await tester.pumpWidget(
      _host(
        FlareCallControls(mode: FlareCallMode.audio, onStartVideo: () {}),
        strings: flareStringsEnglish,
      ),
    );
    expect(flareStringsEnglish.callSwitchToVideo, 'Switch to video');
    expect(_strings.callSwitchToVideo, '切换到视频');
    expect(find.byTooltip('Switch to video'), findsOneWidget);
  });

  testWidgets('the call screens forward it in audio calls only', (
    tester,
  ) async {
    Widget oneToOne(FlareCallMode mode, VoidCallback onStartVideo) =>
        FlareCallView(
          peerName: '周屿',
          mode: mode,
          state: FlareCallState.connected,
          onStartVideo: onStartVideo,
        );
    Widget group(FlareCallMode mode, VoidCallback onStartVideo) =>
        FlareGroupCallView(
          participants: const [FlareCallParticipant(id: 'a', name: 'A')],
          mode: mode,
          state: FlareCallState.connected,
          onStartVideo: onStartVideo,
        );
    for (final screen in [oneToOne, group]) {
      var asked = 0;
      await tester.pumpWidget(
        _host(screen(FlareCallMode.audio, () => asked++)),
      );
      await tester.tap(find.byTooltip(_strings.callSwitchToVideo));
      expect(asked, 1);

      await tester.pumpWidget(_host(screen(FlareCallMode.video, () {})));
      expect(find.byTooltip(_strings.callSwitchToVideo), findsNothing);
    }
  });
}
