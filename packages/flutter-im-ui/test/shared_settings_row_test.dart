import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  testWidgets('row and switch activate once; disabled row never activates', (
    tester,
  ) async {
    var changes = 0;
    Future<void> mount({bool disabled = false}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareSettingsRow(
            item: FlareSettingsItem(
              key: 'mute',
              label: 'Mute',
              kind: FlareSettingKind.toggle,
              disabled: disabled,
            ),
            onToggle: (_, value) {
              expect(value, isTrue);
              changes++;
            },
          ),
        ),
      ),
    );
    await mount();
    await tester.tap(find.text('Mute'));
    expect(changes, 1);
    await tester.tapAt(tester.getCenter(find.byType(Switch)));
    expect(changes, 2);
    await mount(disabled: true);
    await tester.tap(find.text('Mute'));
    await tester.tapAt(tester.getCenter(find.byType(Switch)));
    expect(changes, 2);
    expect(tester.takeException(), isNull);
  });
}
