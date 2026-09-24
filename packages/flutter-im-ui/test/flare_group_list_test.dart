import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('group rows work without a host Material ancestor', (
    tester,
  ) async {
    const group = FlareGroupSummary(
      id: 'group-1',
      name: '跨端群聊',
      memberCount: 3,
    );
    FlareGroupSummary? selected;

    // MaterialApp supplies theme/directionality but the home itself has no
    // Material paint surface. This matches the Cupertino-style Flutter hosts
    // that previously threw "No Material widget found" when a row appeared.
    await tester.pumpWidget(
      MaterialApp(
        home: FlareGroupList(
          items: const [group],
          onSelect: (value) => selected = value,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text(group.name));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(selected, same(group));
  });
}
