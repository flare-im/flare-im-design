import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
);

void main() {
  group('FlareSearchBar entry mode', () {
    testWidgets('read-only with onActivate is one named button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpWidget(
        _host(
          FlareSearchBar(
            placeholder: 'Search chats',
            readOnly: true,
            onActivate: () => opened++,
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      final bar = find.bySemanticsLabel('Search chats');
      expect(
        tester.getSemantics(bar),
        isSemantics(isButton: true, hasTapAction: true, isTextField: false),
      );
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(FlareSizes.touchTarget),
      );
      await tester.tap(find.text('Search chats'));
      expect(opened, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(opened, 3);
      semantics.dispose();
    });

    testWidgets('read-only shows the value with no clear button', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'flare');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          FlareSearchBar(
            controller: controller,
            readOnly: true,
            onActivate: () {},
          ),
        ),
      );
      expect(find.text('flare'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('read-only without onActivate is display-only', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(const FlareSearchBar(readOnly: true)));
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      expect(
        tester.getSemantics(find.text(const FlareStrings().search)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      semantics.dispose();
    });
  });

  group('FlareContactItem / FlareContactList selection and trailing', () {
    testWidgets('a selectable row is a checkbox named after the contact', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final toggled = <String>[];
      var selected = 0;
      await tester.pumpWidget(
        _host(
          FlareContactList(
            indexed: false,
            items: const [
              FlareContact(id: 'u1', name: 'Ann', signature: 'Design'),
              FlareContact(id: 'u2', name: 'Bob'),
            ],
            selectable: true,
            selectedIds: const {'u2'},
            onToggleSelect: (contact) => toggled.add(contact.id),
            onSelect: (_) => selected++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ann')),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bob')),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      expect(tester.widgetList(find.byType(FlareCheckbox)).length, 2);
      await tester.tap(find.text('Ann'));
      await tester.tap(find.byType(FlareCheckbox).last);
      expect(toggled, ['u1', 'u2']);
      expect(selected, 0);
      semantics.dispose();
    });

    testWidgets('trailing controls stay separate from the row', (tester) async {
      final semantics = tester.ensureSemantics();
      final removed = <String>[];
      var opened = 0;
      await tester.pumpWidget(
        _host(
          FlareContactList(
            indexed: false,
            items: const [FlareContact(id: 'u1', name: 'Ann')],
            onSelect: (_) => opened++,
            trailingBuilder: (context, contact) => FlareButton(
              label: 'Remove',
              size: FlareControlSize.sm,
              onPressed: () => removed.add(contact.id),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Remove')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(find.text('Remove'));
      expect(removed, ['u1']);
      expect(opened, 0);
      await tester.tap(find.text('Ann'));
      expect(opened, 1);
      semantics.dispose();
    });

    testWidgets('a plain row keeps onSelect and shows no checkbox', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          FlareContactItem(
            item: const FlareContact(id: 'u1', name: 'Ann'),
            onSelect: () => opened++,
          ),
        ),
      );
      expect(find.byType(FlareCheckbox), findsNothing);
      await tester.tap(find.text('Ann'));
      expect(opened, 1);
    });
  });

  group('FlareNewFriendRequests direction', () {
    const incoming = FlareFriendRequest(id: 'r1', name: 'Ann', message: 'hi');
    const outgoing = FlareFriendRequest(
      id: 'r2',
      name: 'Bob',
      direction: FlareFriendRequestDirection.outgoing,
    );

    testWidgets('outgoing rows show pending and withdraw, not accept', (
      tester,
    ) async {
      const strings = FlareStrings();
      final withdrawn = <String>[];
      await tester.pumpWidget(
        _host(
          FlareNewFriendRequests(
            items: const [incoming, outgoing],
            onAccept: (_) {},
            onReject: (_) {},
            onWithdraw: (request) => withdrawn.add(request.id),
          ),
        ),
      );
      expect(find.text(strings.newFriendRequestsAccept), findsOneWidget);
      expect(find.text(strings.newFriendRequestsReject), findsOneWidget);
      expect(find.text(strings.newFriendRequestsPending), findsOneWidget);
      await tester.tap(find.text(strings.newFriendRequestsWithdraw));
      expect(withdrawn, ['r2']);
    });

    testWidgets('withdraw exists only with its handler', (tester) async {
      await tester.pumpWidget(
        _host(const FlareNewFriendRequests(items: [outgoing])),
      );
      expect(
        find.text(const FlareStrings().newFriendRequestsPending),
        findsOneWidget,
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('default labels come from the strings scope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlareStringsScope(
            strings: const FlareStrings().copyWith(
              newFriendRequestsEmpty: 'No requests',
              newFriendRequestsPending: 'Pending',
              newFriendRequestsWithdraw: 'Withdraw',
              newFriendRequestsAccept: 'Accept',
              newFriendRequestsReject: 'Decline',
            ),
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: FlareNewFriendRequests(
                      items: const [incoming, outgoing],
                      onWithdraw: (_) {},
                    ),
                  ),
                  const Expanded(child: FlareNewFriendRequests(items: [])),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in [
        'Pending',
        'Withdraw',
        'Accept',
        'Decline',
        'No requests',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });
}
