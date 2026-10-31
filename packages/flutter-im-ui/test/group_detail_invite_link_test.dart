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
  capabilities: FlareGroupCapabilities(canInvite: true),
);

void main() {
  testWidgets('the open invite link sheet follows the code the host fetches '
      'after it opened', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? code;
    var loading = false;
    late StateSetter setHost;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHost = setState;
              return FlareGroupDetail(
                model: _model,
                inviteCode: code,
                loadingInviteLink: loading,
                // The host starts fetching when the sheet opens.
                onEnsureInviteLink: () => setHost(() => loading = true),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.ancestor(
      of: find.text(_labels.inviteLink),
      matching: find.byType(FlareSettingsRow),
    );
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(row);
    await tester.pump();
    await tester.pump();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
      reason: 'the fetch the sheet started shows as loading',
    );

    setHost(() {
      loading = false;
      code = 'NEWCODE';
    });
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('NEWCODE')),
      findsOneWidget,
    );
    expect(find.text(_labels.cannotGenerate), findsNothing);
    expect(find.text(_labels.copyCode), findsOneWidget);
  });
}
