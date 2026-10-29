import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The one-to-one call screen shows the peer's microphone and speaking the way
// a group tile does, and draws the host's camera as the corner preview; a
// group tile asks the host for video only where the camera is on.

const _strings = FlareStrings();

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 390, height: 844, child: child)),
);

FlareCallView _view({
  FlareCallMode mode = FlareCallMode.audio,
  bool peerMuted = false,
  bool peerSpeaking = false,
  Widget? localVideoContent,
}) => FlareCallView(
  peerName: '周屿',
  mode: mode,
  state: FlareCallState.connected,
  durationLabel: '01:02',
  peerMuted: peerMuted,
  peerSpeaking: peerSpeaking,
  localVideoContent: localVideoContent,
);

/// Whether the avatar wears the speaking ring.
bool _ringed(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(
          of: find.byType(FlareAvatar),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  final shadows = (box.decoration as BoxDecoration).boxShadow;
  return shadows != null && shadows.isNotEmpty;
}

void main() {
  testWidgets('a muted peer wears a named badge, an open one none', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_view(peerMuted: true)));
    expect(find.bySemanticsLabel(_strings.callPeerMuted), findsOneWidget);
    await tester.pumpWidget(_host(_view()));
    expect(find.bySemanticsLabel(_strings.callPeerMuted), findsNothing);
    handle.dispose();
  });

  testWidgets('the speaking ring, never while the peer is muted', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_view(peerSpeaking: true)));
    expect(_ringed(tester), isTrue);
    await tester.pumpWidget(_host(_view(peerSpeaking: true, peerMuted: true)));
    expect(_ringed(tester), isFalse);
    await tester.pumpWidget(_host(_view()));
    expect(_ringed(tester), isFalse);
  });

  testWidgets('the corner preview: video calls only, 3:4 at the token width', (
    tester,
  ) async {
    const mine = Key('mine');
    await tester.pumpWidget(
      _host(
        _view(
          mode: FlareCallMode.video,
          localVideoContent: const SizedBox.expand(key: mine),
        ),
      ),
    );
    final size = tester.getSize(find.byKey(mine));
    expect(size.width, FlareSizes.componentCallPreviewWidth);
    expect(size.height, FlareSizes.componentCallPreviewWidth * 4 / 3);
    // Top trailing corner, with the peer block starting below it.
    final rect = tester.getRect(find.byKey(mine));
    expect(rect.right, 390 - FlareSizes.spacingLg);
    expect(
      tester.getRect(find.byType(FlareAvatar)).top,
      greaterThanOrEqualTo(rect.bottom),
    );

    await tester.pumpWidget(
      _host(_view(localVideoContent: const SizedBox.expand(key: mine))),
    );
    expect(find.byKey(mine), findsNothing);
  });

  testWidgets('group tiles ask for video only where the camera is on', (
    tester,
  ) async {
    final asked = <String>[];
    await tester.pumpWidget(
      _host(
        FlareGroupCallView(
          mode: FlareCallMode.video,
          state: FlareCallState.connected,
          participants: const [
            FlareCallParticipant(id: 'a', name: 'A', muted: true),
            FlareCallParticipant(id: 'b', name: 'B', cameraOff: true),
            FlareCallParticipant(id: 'c', name: 'C'),
          ],
          tileBuilder: (p) {
            asked.add(p.id);
            // No stream for c yet: the kit shows the avatar.
            return p.id == 'a'
                ? const ColoredBox(key: Key('stream-a'), color: Colors.red)
                : null;
          },
        ),
      ),
    );
    expect(asked, ['a', 'c']);
    expect(find.byType(FlareAvatar), findsNWidgets(2));
    // The stream fills its tile and the name tag stays drawn over it.
    final stream = tester.getRect(find.byKey(const Key('stream-a')));
    expect(
      stream.contains(tester.getCenter(find.text('A'))),
      isTrue,
      reason: 'the name sits on the video',
    );
  });

  testWidgets('group tiles never ask for video in an audio call', (
    tester,
  ) async {
    final asked = <String>[];
    await tester.pumpWidget(
      _host(
        FlareGroupCallView(
          mode: FlareCallMode.audio,
          state: FlareCallState.connected,
          participants: const [FlareCallParticipant(id: 'a', name: 'A')],
          tileBuilder: (p) {
            asked.add(p.id);
            return const ColoredBox(color: Colors.red);
          },
        ),
      ),
    );
    expect(asked, isEmpty);
    expect(find.byType(FlareAvatar), findsOneWidget);
  });
}
