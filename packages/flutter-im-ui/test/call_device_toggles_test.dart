import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-104: a call device toggle is named by its device (麦克风, 摄像头, 扬声器) and
// is toggled while that device is on, so "on" means the same thing on every
// key; the dock's main button, which returns to the full call, is 返回通话.

const _strings = FlareStrings();

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: child),
  ),
);

SemanticsNode _named(WidgetTester tester, String name) {
  final byLabel = find.bySemanticsLabel(name);
  if (byLabel.evaluate().isNotEmpty) return tester.getSemantics(byLabel);
  return tester.getSemantics(find.byTooltip(name));
}

void main() {
  testWidgets('call controls: toggled means the device is on', (tester) async {
    final handle = tester.ensureSemantics();
    for (final (muted, cameraOn) in [(false, true), (true, false)]) {
      await tester.pumpWidget(
        _host(
          FlareCallControls(
            muted: muted,
            cameraOn: cameraOn,
            onToggleMute: () {},
            onToggleCamera: () {},
            onSwitchCamera: () {},
            onHangup: () {},
          ),
        ),
      );
      expect(
        _named(tester, _strings.microphone),
        isSemantics(hasToggledState: true, isToggled: !muted),
        reason: 'muted: $muted',
      );
      expect(
        _named(tester, _strings.camera),
        isSemantics(hasToggledState: true, isToggled: cameraOn),
        reason: 'cameraOn: $cameraOn',
      );
      // Flip and hang up are plain buttons, not toggles.
      expect(
        _named(tester, _strings.flipCamera),
        isSemantics(isButton: true, hasToggledState: false),
      );
      expect(
        _named(tester, _strings.hangUp),
        isSemantics(isButton: true, hasToggledState: false),
      );
    }
    for (final speakerOn in [false, true]) {
      await tester.pumpWidget(
        _host(
          FlareCallControls(
            mode: FlareCallMode.audio,
            speakerOn: speakerOn,
            onToggleSpeaker: () {},
          ),
        ),
      );
      expect(
        _named(tester, _strings.speaker),
        isSemantics(hasToggledState: true, isToggled: speakerOn),
      );
    }
    handle.dispose();
  });

  testWidgets('call dock: 返回通话, a microphone toggle and 挂断', (tester) async {
    final handle = tester.ensureSemantics();
    var expanded = 0, toggles = 0, hangups = 0;
    Widget dock({required bool muted}) => _host(
      FlareCallDock(
        title: 'Ivy',
        durationLabel: '02:14',
        muted: muted,
        onExpand: () => expanded++,
        onToggleMute: () => toggles++,
        onHangup: () => hangups++,
      ),
    );

    await tester.pumpWidget(dock(muted: false));
    final main = _named(tester, _strings.callReturn);
    expect(main, isSemantics(isButton: true, hasTapAction: true));
    expect(main.rect.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
    expect(
      _named(tester, _strings.microphone),
      isSemantics(isButton: true, hasToggledState: true, isToggled: true),
    );
    expect(
      _named(tester, _strings.hangUp),
      isSemantics(isButton: true, hasToggledState: false),
    );
    // The old 静音 name is gone: the key is named by its device.
    expect(find.bySemanticsLabel('静音'), findsNothing);

    await tester.pumpWidget(dock(muted: true));
    expect(
      _named(tester, _strings.microphone),
      isSemantics(hasToggledState: true, isToggled: false),
    );

    await tester.tap(find.bySemanticsLabel(_strings.callReturn));
    await tester.tap(find.bySemanticsLabel(_strings.microphone));
    await tester.tap(find.bySemanticsLabel(_strings.hangUp));
    expect((expanded, toggles, hangups), (1, 1, 1));
    handle.dispose();
  });
}
