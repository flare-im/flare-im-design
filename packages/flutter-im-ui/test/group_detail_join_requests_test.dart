import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = FlareGroupDetailLabels();

const _model = FlareGroupDetailModel(
  groupId: 'g1',
  name: 'Team',
  memberCount: 1,
  members: [FlareContact(id: 'owner', name: 'Olivia')],
  ownerId: 'owner',
  capabilities: FlareGroupCapabilities(canManageJoinRequests: true),
);

const _ann = FlareGroupJoinRequestView(
  requestId: 'r1',
  applicantId: 'ann',
  applicantName: 'Ann',
);
const _ben = FlareGroupJoinRequestView(
  requestId: 'r2',
  applicantId: 'ben',
  applicantName: 'Ben',
);

void main() {
  testWidgets('the open join requests sheet follows the list the host loads '
      'and reloads', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var requests = <FlareGroupJoinRequestView>[];
    var loading = false;
    final answers = <String>[];
    late StateSetter setHost;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHost = setState;
              return FlareGroupDetail(
                model: _model,
                joinRequests: requests,
                loadingJoinRequests: loading,
                // The host starts loading when the sheet opens.
                onLoadJoinRequests: () => setHost(() => loading = true),
                onRespondRequest: (id, accept) => answers.add('$id $accept'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.ancestor(
      of: find.text(_labels.joinRequests),
      matching: find.byType(FlareSettingsRow),
    );
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text(_labels.loading)),
      findsOneWidget,
      reason: 'the load the sheet started shows as loading',
    );

    // The list arrives after the sheet opened.
    setHost(() {
      loading = false;
      requests = [_ann, _ben];
    });
    await tester.pumpAndSettle();
    expect(find.descendant(of: sheet, matching: find.text('Ann')), findsOne);
    expect(find.descendant(of: sheet, matching: find.text('Ben')), findsOne);

    // Answering keeps the row, its buttons off, until the host reloads.
    Finder approveOf(String name) => find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
      matching: find.widgetWithText(FlareButton, _labels.approve),
    );
    await tester.tap(approveOf('Ann'));
    await tester.pumpAndSettle();
    expect(answers, ['r1 true']);
    expect(tester.widget<FlareButton>(approveOf('Ann')).disabled, isTrue);
    await tester.tap(approveOf('Ann'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(answers, ['r1 true'], reason: 'one answer per request');

    // The host's reload drops the answered request.
    setHost(() => requests = [_ben]);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('Ann')),
      findsNothing,
    );
    expect(find.descendant(of: sheet, matching: find.text('Ben')), findsOne);

    // An answer that failed comes back usable when the host reloads it.
    await tester.tap(approveOf('Ben'));
    await tester.pumpAndSettle();
    expect(tester.widget<FlareButton>(approveOf('Ben')).disabled, isTrue);
    setHost(() => requests = [_ben]);
    await tester.pumpAndSettle();
    expect(tester.widget<FlareButton>(approveOf('Ben')).disabled, isFalse);
    expect(answers, ['r1 true', 'r2 true']);
  });
}
