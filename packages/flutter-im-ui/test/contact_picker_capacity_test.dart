import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  testWidgets(
    'at the limit unchosen rows disable but chosen rows can be removed',
    (tester) async {
      List<FlareContactPickerEntry>? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareContactPicker(
              multiple: true,
              maxSelected: 2,
              groups: const [
                FlareContactPickerGroup(
                  id: 'groupMembers',
                  entries: [
                    FlareContactPickerEntry(userId: 'a', name: 'Alice'),
                    FlareContactPickerEntry(userId: 'b', name: 'Bob'),
                    FlareContactPickerEntry(userId: 'c', name: 'Carol'),
                  ],
                ),
              ],
              onSelect: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alice'));
      await tester.pump();
      await tester.tap(find.text('Bob'));
      await tester.pump();
      await tester.tap(find.text('Carol'));
      await tester.pump();
      expect(find.text('确定 (2/2)'), findsOneWidget);
      await tester.tap(find.text('Alice'));
      await tester.pump();
      await tester.tap(find.text('Carol'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('flare-contact-picker-confirm')),
      );
      await tester.pump();
      expect(selected!.map((p) => p.userId), ['b', 'c']);
      expect(tester.takeException(), isNull);
    },
  );
}
