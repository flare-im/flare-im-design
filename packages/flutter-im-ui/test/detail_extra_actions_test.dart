import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-046: a report action lived outside the kit's detail pages. The host declares it now and the
// kit draws it in place, reporting the id back.

const _strings = FlareStrings();

Widget _host(Widget child) => FlareStringsScope(
  strings: _strings,
  child: MaterialApp(
    home: FlareTheme(mode: FlareThemeMode.light, child: Scaffold(body: child)),
  ),
);

void main() {
  testWidgets('a contact detail draws host actions and reports the id', (tester) async {
    final reported = <String>[];
    await tester.pumpWidget(
      _host(
        FlareContactDetail(
          contact: const FlareContact(id: 'u1', name: 'Ada Chen'),
          extraActions: const [
            FlareDetailExtraAction(id: 'report', label: '举报', danger: true),
            FlareDetailExtraAction(id: 'share', label: '分享名片'),
          ],
          onExtraAction: reported.add,
        ),
      ),
    );

    expect(find.text('举报'), findsOneWidget);
    expect(find.text('分享名片'), findsOneWidget);
    await tester.tap(find.text('举报'));
    await tester.pump();
    expect(reported, ['report']);
  });

  testWidgets('a contact detail without them draws no footer at all', (tester) async {
    await tester.pumpWidget(
      _host(
        const FlareContactDetail(contact: FlareContact(id: 'u1', name: 'Ada Chen')),
      ),
    );
    expect(find.text('举报'), findsNothing);
  });
}
