import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> composer(String? conversationType) {
  final raw =
      (jsonDecode(
                File(
                  '../../spec/financial-presentation-vectors.json',
                ).readAsStringSync(),
              )['composer']
              as Map)
          .cast<String, Object?>();
  final props = (raw['presentation'] as Map)['props'] as Map;
  if (conversationType == null) {
    props.remove('conversationType');
  } else {
    props['conversationType'] = conversationType;
  }
  return raw;
}

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Widget pageHost(Widget child) => MaterialApp(home: Scaffold(body: child));

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const bob = FlarePluginMember(userId: 'group-bob', name: 'Bob');

void main() {
  testWidgets(
    'single chat offers only normal and always sends one share with an empty recipient array',
    (tester) async {
      tall(tester);
      final calls = <FlarePluginActionPayload>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(composer('single')),
            onAction: (_, value) => calls.add(value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final form = tester.widget<FlareRedPacketComposer>(
        find.byType(FlareRedPacketComposer),
      );
      expect(form.kinds, [FlareRedPacketKind.normal]);
      expect(
        find.byKey(const ValueKey('flare-red-packet-recipient-choose')),
        findsNothing,
      );
      form.onSubmit!();
      expect(calls.single.formValues?['kind'], 'normal');
      expect(calls.single.formValues?['shareCount'], 1);
      expect(calls.single.formValues?['designatedUserIds'], <String>[]);
      expect(calls.single.formValues!.containsKey('designatedUserId'), isFalse);
    },
  );

  testWidgets(
    'an unknown conversation type locks the composer and cannot emit a submission',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(composer(null)),
            onAction: (_, _) => calls++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final form = tester.widget<FlareRedPacketComposer>(
        find.byType(FlareRedPacketComposer),
      );
      expect(form.kinds, isEmpty);
      expect(form.locked, isTrue);
      form.onSubmit!();
      expect(calls, 0);
    },
  );

  testWidgets(
    'group exclusive chooses one visible server result, preserves it across queries, and clears explicitly',
    (tester) async {
      tall(tester);
      final raw = FlarePluginPageViewModel.fromJson(composer('group'));
      final calls = <FlarePluginPageActionPayload>[];
      final queries = <String>[];
      var members = <FlarePluginMember>[];
      var loading = false;
      String? error;
      var retries = 0;
      late StateSetter update;
      await tester.pumpWidget(
        pageHost(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return FlarePluginPage(
                page: const FlarePluginPageRef(
                  pluginId: 'flare.redpacket',
                  page: 'compose',
                ),
                view: raw,
                members: members,
                membersLoading: loading,
                membersError: error,
                onMemberSearch: (query) {
                  queries.add(query);
                  update(() {
                    loading = true;
                    error = null;
                  });
                },
                onMembersRetry: () => retries++,
                onAction: (_, value) => calls.add(value),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      FlareRedPacketComposer form() => tester.widget<FlareRedPacketComposer>(
        find.byType(FlareRedPacketComposer),
      );
      expect(form().kinds.toSet(), FlareRedPacketKind.values.toSet());
      form().onKindChange!(FlareRedPacketKind.exclusive);
      await tester.pumpAndSettle();
      expect(
        find.byType(FlareInput),
        findsNothing,
        reason: 'a recipient id is never a text field',
      );
      form().onSubmit!();
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(
        find.byKey(const ValueKey('flare-red-packet-recipient-required')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-red-packet-recipient-choose')),
      );
      await tester.pump();
      await tester.pump();
      expect(queries, ['']);
      expect(
        tester
            .widget<FlareContactPicker>(find.byType(FlareContactPicker))
            .multiple,
        isFalse,
      );
      expect(find.text(const FlareStrings().contactPickerEmpty), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      update(() {
        loading = false;
        error = 'Members unavailable';
      });
      await tester.pumpAndSettle();
      expect(find.text('Members unavailable'), findsOneWidget);
      await tester.tap(find.text(const FlareStrings().retry));
      await tester.pumpAndSettle();
      expect(retries, 1);
      update(() {
        error = null;
        members = [bob];
      });
      await tester.pumpAndSettle();
      final stalePick = tester
          .widget<FlareContactPicker>(find.byType(FlareContactPicker))
          .onSelect!;
      update(() {
        loading = true;
      });
      await tester.pump();
      await tester.pump();
      stalePick([
        const FlareContactPickerEntry(userId: 'group-bob', name: 'Bob'),
      ]);
      await tester.pump();
      expect(
        find.byType(FlareContactPicker),
        findsOneWidget,
        reason:
            'a previous callback cannot choose while a new result is pending',
      );
      update(() {
        loading = false;
      });
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(FlareSearchBar),
          matching: find.byType(EditableText),
        ),
        'exact-user-id',
      );
      await tester.pump();
      await tester.pump();
      expect(queries.last, 'exact-user-id');
      update(() {
        loading = false;
        members = [bob];
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('flare-contact-picker-group-bob')),
        findsOneWidget,
        reason: 'server matches are not filtered again by local name matching',
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-contact-picker-group-bob')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareContactPicker), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('flare-red-packet-recipient-name')),
            )
            .data,
        'Bob',
      );
      update(() {
        members = [];
      });
      await tester.pumpAndSettle();
      expect(
        find.text('Bob'),
        findsOneWidget,
        reason: 'a later partial query does not mean this member left',
      );
      form().onSubmit!();
      expect(calls.single.formValues?['designatedUserIds'], ['group-bob']);
      expect(calls.single.formValues?['shareCount'], 1);
      await tester.tap(
        find.byKey(const ValueKey('flare-red-packet-recipient-choose')),
      );
      await tester.pump();
      await tester.pump();
      tester
          .widget<FlareContactPicker>(find.byType(FlareContactPicker))
          .onCancel!();
      await tester.pumpAndSettle();
      expect(
        find.text('Bob'),
        findsOneWidget,
        reason: 'cancel preserves the prior choice',
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-red-packet-recipient-clear')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('flare-red-packet-recipient-name')),
        findsNothing,
      );
      form().onSubmit!();
      expect(
        calls.length,
        1,
        reason: 'cleared exclusive recipient cannot submit',
      );
      expect(tester.takeException(), isNull);
    },
  );

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
  testWidgets(
    'an authoritative member revision clears only the recipient and cancels an old picker',
    (tester) async {
      tall(tester);
      final view = FlarePluginViewModel.fromJson(composer('group'));
      var revision = 0;
      var members = <FlarePluginMember>[bob];
      late StateSetter update;
      var sent = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return FlarePluginView(
                view: view,
                members: members,
                membersRevision: revision,
                onMemberSearch: (_) {},
                onAction: (_, _) => sent++,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      FlareRedPacketComposer form() => tester.widget<FlareRedPacketComposer>(
        find.byType(FlareRedPacketComposer),
      );
      form().onKindChange!(FlareRedPacketKind.exclusive);
      form().onAmountChange!('2.50');
      form().onGreetingChange!('Keep this greeting');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('flare-red-packet-recipient-choose')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('flare-contact-picker-group-bob')),
      );
      await tester.pumpAndSettle();
      update(() => members = []);
      await tester.pumpAndSettle();
      expect(
        find.text('Bob'),
        findsOneWidget,
        reason: 'ordinary query results are partial',
      );
      update(() => members = [bob]);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('flare-red-packet-recipient-choose')),
      );
      await tester.pumpAndSettle();
      final stale = tester
          .widget<FlareContactPicker>(find.byType(FlareContactPicker))
          .onSelect!;
      update(() => revision++);
      await tester.pumpAndSettle();
      expect(find.byType(FlareContactPicker), findsNothing);
      stale([const FlareContactPickerEntry(userId: 'group-bob', name: 'Bob')]);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('flare-red-packet-recipient-name')),
        findsNothing,
      );
      expect(form().amount, '2.50');
      expect(form().greeting, 'Keep this greeting');
      form().onSubmit!();
      expect(sent, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
