import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  testWidgets('video header stays above picture and controls stay at bottom', (
    tester,
  ) async {
    for (final size in [const Size(720, 600), const Size(320, 640)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareCallView(
              peerName: 'Peer',
              mode: FlareCallMode.video,
              state: FlareCallState.connected,
              durationLabel: '01:02',
              videoContent: const ColoredBox(color: Colors.black),
              localVideoContent: const ColoredBox(color: Colors.blue),
              onToggleMute: () {},
              onHangup: () {},
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.text('Peer')).dy, lessThan(80));
      expect(
        tester.getBottomLeft(find.byType(FlareCallControls)).dy,
        greaterThan(size.height - 40),
      );
      expect(
        tester.getTopLeft(find.byType(FlareCallControls)).dy,
        greaterThan(size.height / 2),
      );
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('device choices open above their button and select directly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(720, 600));
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FlareCallControls(
              mode: FlareCallMode.audio,
              speakerPicker: true,
              onPickDevices: (anchor) => FlareCallDevicePicker.showAnchored(
                anchor,
                builder: (_) => FlareCallDevicePicker(
                  permission: FlareCapabilityState.available,
                  permissionText: '',
                  groups: const [
                    FlareCallDeviceGroup(
                      kind: FlareCallDeviceKind.microphone,
                      label: 'Microphone',
                      selectedId: 'a',
                      devices: [
                        FlareCallDevice(id: 'a', label: 'Built-in'),
                        FlareCallDevice(id: 'b', label: 'USB'),
                      ],
                    ),
                  ],
                  onSelect: (_, id) => chosen = id,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final speaker = find.byTooltip('扬声器');
    final top = tester.getTopLeft(speaker).dy;
    await tester.tap(speaker);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(FlareCallDevicePicker)).dy,
      lessThan(top),
    );
    await tester.tap(find.text('USB'));
    expect(chosen, 'b');
    await tester.tapAt(const Offset(16, 16));
    await tester.pumpAndSettle();
    expect(find.byType(FlareCallDevicePicker), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
