import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1360.0]) {
    testWidgets('group directory long names fit at $width', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: FlareScreen(
            title: 'Groups',
            contentMaxWidth: FlareSizes.directoryContentMaxWidth,
            scroll: false,
            onBack: () {},
            child: FlareGroupList(
              items: const [
                FlareGroupSummary(
                  id: 'g',
                  name:
                      'A very long group name that must never overflow the page — 长群名长群名长群名',
                  memberCount: 200,
                ),
              ],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.text('Groups'));
      final style = DefaultTextStyle.of(
        tester.element(find.text('Groups')),
      ).style.merge(title.style);
      expect(style.decoration, TextDecoration.none);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        tester.getSize(find.byType(FlareGroupList)).width,
        lessThanOrEqualTo(FlareSizes.directoryContentMaxWidth),
      );
    });
  }
}
