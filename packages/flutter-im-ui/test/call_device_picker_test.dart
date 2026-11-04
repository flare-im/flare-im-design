import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  test('device inventory discards missing and duplicate IDs', () {
    const group = FlareCallDeviceGroup(
      kind: FlareCallDeviceKind.microphone,
      label: 'Microphone',
      devices: [
        FlareCallDevice(id: '', label: 'Empty'),
        FlareCallDevice(id: 'a', label: 'First'),
        FlareCallDevice(id: 'a', label: 'Duplicate'),
      ],
    );
    expect(group.uniqueDevices.map((d) => d.label), ['First']);
  });
  testWidgets('removed selection is empty and denied or busy cannot switch', (
    tester,
  ) async {
    Widget host(FlareCapabilityState permission, bool busy) => MaterialApp(
      home: Scaffold(
        body: FlareCallDevicePicker(
          permission: permission,
          permissionText: 'Permission',
          groups: [
            FlareCallDeviceGroup(
              kind: FlareCallDeviceKind.microphone,
              label: 'Microphone',
              selectedId: 'removed',
              busy: busy,
              devices: const [FlareCallDevice(id: 'usb', label: 'USB')],
            ),
          ],
          onSelect: (_, __) => fail('no automatic device selection'),
        ),
      ),
    );
    await tester.pumpWidget(host(FlareCapabilityState.denied, false));
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    await tester.pumpWidget(host(FlareCapabilityState.available, true));
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
