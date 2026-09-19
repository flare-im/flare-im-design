import 'dart:async';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Round 5 Batch 2b follow-up: with `submitEdit` the group edit prompt waits for
// the host's write (the Vue kit's `submitEdit(kind, value)`): busy while it
// runs, the error and the draft kept when it fails, closed once it succeeds.
// Without it the prompt closes and the `onUpdate…` callback reports the value.

const _labels = FlareGroupDetailLabels();

const _model = FlareGroupDetailModel(
  groupId: 'g1',
  name: 'Team',
  announcement: 'Ship on Friday',
  memberCount: 1,
  members: [FlareContact(id: 'me', name: 'Me')],
  ownerId: 'me',
  canManage: true,
  isOwner: true,
  myNickname: 'Captain',
);

Future<void> _pump(WidgetTester tester, Widget detail) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: detail)));
  await tester.pumpAndSettle();
}

Finder get _field => find.descendant(
  of: find.byType(FlareDialog),
  matching: find.byType(TextField),
);

Finder get _save => find.widgetWithText(FlareButton, _labels.save);

void main() {
  testWidgets('a failed write keeps the prompt with the error and the draft; '
      'a retry that succeeds closes it', (tester) async {
    final writes = <(FlareGroupEditKind, String)>[];
    final reported = <String>[];
    var failures = 1;
    Completer<void>? pending;
    await _pump(
      tester,
      FlareGroupDetail(
        model: _model,
        submitEdit: (kind, value) {
          writes.add((kind, value));
          if (failures-- > 0) return Future.error(StateError('Unavailable'));
          pending = Completer<void>();
          return pending!.future;
        },
        onUpdateName: reported.add,
      ),
    );
    await tester.tap(find.text(_labels.name));
    await tester.pumpAndSettle();
    await tester.enterText(_field, 'New team');
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.byType(FlareDialog), findsOneWidget);
    expect(find.textContaining('Unavailable'), findsOneWidget);
    expect(find.text('New team'), findsOneWidget, reason: 'the draft is kept');

    await tester.tap(_save);
    await tester.pump();
    expect(find.byType(FlareDialog), findsOneWidget, reason: 'busy writing');
    expect(tester.widget<FlareButton>(_save).loading, isTrue);
    pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(FlareDialog), findsNothing);
    expect(writes, [
      (FlareGroupEditKind.name, 'New team'),
      (FlareGroupEditKind.name, 'New team'),
    ]);
    expect(reported, isEmpty, reason: 'submitEdit replaces the callback');
  });

  testWidgets('the announcement and my nickname go through the same hook', (
    tester,
  ) async {
    final writes = <(FlareGroupEditKind, String)>[];
    await _pump(
      tester,
      FlareGroupDetail(
        model: _model,
        submitEdit: (kind, value) async => writes.add((kind, value)),
      ),
    );
    await tester.tap(find.text(_labels.announcement));
    await tester.pumpAndSettle();
    await tester.enterText(_field, 'Ship on Monday');
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();

    await tester.tap(find.text(_labels.myNickname));
    await tester.pumpAndSettle();
    await tester.enterText(_field, '');
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(writes, [
      (FlareGroupEditKind.announcement, 'Ship on Monday'),
      (FlareGroupEditKind.nickname, ''),
    ]);
  });

  testWidgets('without submitEdit the prompt closes and the callback reports', (
    tester,
  ) async {
    final reported = <String>[];
    await _pump(
      tester,
      FlareGroupDetail(model: _model, onUpdateMyNickname: reported.add),
    );
    await tester.tap(find.text(_labels.myNickname));
    await tester.pumpAndSettle();
    await tester.enterText(_field, 'Skipper');
    await tester.pump();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.byType(FlareDialog), findsNothing);
    expect(reported, ['Skipper']);
  });
}
