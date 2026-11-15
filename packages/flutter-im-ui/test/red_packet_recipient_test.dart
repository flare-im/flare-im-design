import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const bob = FlarePluginMember(userId: 'group-bob', name: 'Bob');

void main() {
  testWidgets(
    'generic member form receives live search phases and retains its selected name on a partial result',
    (tester) async {
      tall(tester);
      final input = FlarePluginInput.fromJson({
        'id': 'designatedUserIds',
        'kind': 'members',
        'label': 'Recipient',
        'max': 1,
        'required': true,
      })!;
      late StateSetter update;
      var members = <FlarePluginMember>[];
      var loading = false;
      final queries = <String>[];
      final calls = <Map<String, Object?>>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return FlarePluginForm(
                inputs: [input],
                members: members,
                membersLoading: loading,
                onMemberSearch: (query) {
                  queries.add(query);
                  update(() => loading = true);
                },
                onSubmit: calls.add,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('flare-plugin-members-choose-designatedUserIds'),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(queries, ['']);
      update(() {
        loading = false;
        members = [bob];
      });
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('flare-contact-picker-group-bob')),
      );
      await tester.pumpAndSettle();
      update(() {
        members = [];
      });
      await tester.pumpAndSettle();
      expect(find.text('Bob'), findsOneWidget);
      await tester.tap(find.text(const FlareStrings().pluginViewSubmit));
      await tester.pumpAndSettle();
      expect(calls.single['designatedUserIds'], ['group-bob']);
      expect(tester.takeException(), isNull);
    },
  );
}
