import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  testWidgets('call actions wrap at 320 and remain reachable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var ended = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(body: FlareCallControls(onHangup: () => ended++)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.widgetList<IconButton>(find.byType(IconButton)).first.onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Hang up'));
    expect(ended, 1);
    for (final element in find.byType(IconButton).evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.width, greaterThanOrEqualTo(48));
    }
  });
  testWidgets('failed call exposes recovery and keeps hangup reachable', (
    tester,
  ) async {
    var recovered = 0;
    var ended = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareCallView(
            peerName: 'Peer',
            mode: FlareCallMode.audio,
            state: FlareCallState.failed,
            recoveryText: 'Reconnect',
            onRecover: () => recovered++,
            onHangup: () => ended++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Reconnect'));
    await tester.tap(find.byTooltip('Hang up'));
    expect(recovered, 1);
    expect(ended, 1);
    expect(tester.takeException(), isNull);
  });
}
