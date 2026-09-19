import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_group_permission_matrix.dart';
import 'package:flare_im_ui/src/components/flare_switch.dart';
import 'package:flare_im_ui/src/models/directory_data.dart';
import 'package:flare_im_ui/src/tokens/flare_strings.dart';

void main() {
  const settings = FlareGroupPermissionSettings(
    muteAll: false,
    onlyAdminCanAtAll: true,
    onlyAdminCanPin: false,
    shareCardPermission: true,
    joinPolicy: FlareGroupJoinPolicy.approval,
  );
  FlareGroupPermissionRow rowFor(
    List<FlareGroupPermissionRow> rows,
    FlareGroupPermissionKey key,
  ) => rows.firstWhere((r) => r.key == key);

  group('groupPermissionRows', () {
    test('returns the five real backend keys in canonical order', () {
      expect(groupPermissionRows(settings, true).map((r) => r.key).toList(), [
        FlareGroupPermissionKey.joinPolicy,
        FlareGroupPermissionKey.muteAll,
        FlareGroupPermissionKey.onlyAdminCanAtAll,
        FlareGroupPermissionKey.onlyAdminCanPin,
        FlareGroupPermissionKey.shareCardPermission,
      ]);
    });

    test('joinPolicy is the only choice row and values carry through', () {
      final rows = groupPermissionRows(settings, true);
      expect(
        rows
            .where((r) => r.kind == FlareGroupPermissionRowKind.choice)
            .map((r) => r.key)
            .toList(),
        [FlareGroupPermissionKey.joinPolicy],
      );
      expect(
        rowFor(rows, FlareGroupPermissionKey.joinPolicy).joinPolicyValue,
        FlareGroupJoinPolicy.approval,
      );
      expect(rowFor(rows, FlareGroupPermissionKey.muteAll).boolValue, isFalse);
      expect(
        rowFor(rows, FlareGroupPermissionKey.onlyAdminCanAtAll).boolValue,
        isTrue,
      );
      expect(
        rowFor(rows, FlareGroupPermissionKey.shareCardPermission).boolValue,
        isTrue,
      );
    });

    test('editable follows canManage only — never busy, never an error', () {
      expect(
        groupPermissionRows(settings, false).every((r) => !r.editable),
        isTrue,
      );
      final rows = groupPermissionRows(
        settings,
        true,
        ['muteAll'],
        {'muteAll': '网络错误'},
      );
      expect(rows.every((r) => r.editable), isTrue);
    });

    test(
      'busy and error are per key, so a failure keeps its siblings usable',
      () {
        final rows = groupPermissionRows(
          settings,
          true,
          ['muteAll'],
          {'onlyAdminCanPin': '权限不足'},
        );
        expect(rows.where((r) => r.busy).map((r) => r.key).toList(), [
          FlareGroupPermissionKey.muteAll,
        ]);
        expect(rows.where((r) => r.error != null).map((r) => r.key).toList(), [
          FlareGroupPermissionKey.onlyAdminCanPin,
        ]);
        expect(
          rowFor(rows, FlareGroupPermissionKey.onlyAdminCanPin).error,
          '权限不足',
        );
      },
    );

    test('ignores unknown busy keys and empty inputs', () {
      final rows = groupPermissionRows(settings, true, [
        'nope',
        'muteAll',
        'muteAll',
      ]);
      expect(rows.where((r) => r.busy).map((r) => r.key).toList(), [
        FlareGroupPermissionKey.muteAll,
      ]);
      expect(
        groupPermissionRows(
          settings,
          true,
        ).every((r) => !r.busy && r.error == null),
        isTrue,
      );
    });

    test('keeps an error visible on a read-only panel', () {
      final row = rowFor(
        groupPermissionRows(settings, false, const [], {'muteAll': '你已不是管理员'}),
        FlareGroupPermissionKey.muteAll,
      );
      expect(row.editable, isFalse);
      expect(row.error, '你已不是管理员');
    });

    test('an unknown joinPolicy stays unknown rather than a guessed one', () {
      expect(const FlareGroupPermissionSettings().joinPolicy, isNull);
      final row = rowFor(
        groupPermissionRows(const FlareGroupPermissionSettings(), true),
        FlareGroupPermissionKey.joinPolicy,
      );
      expect(row.kind, FlareGroupPermissionRowKind.choice);
      expect(row.value, isNull);
      expect(row.joinPolicyValue, isNull);
      // A toggle row never reads as a policy.
      expect(
        rowFor(
          groupPermissionRows(settings, true),
          FlareGroupPermissionKey.muteAll,
        ).joinPolicyValue,
        isNull,
      );
    });
  });

  testWidgets('manager sees switches and choices, changes dispatch once', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlareGroupPermissionMatrix(
              settings: settings,
              canManage: true,
              onChange: (key, value) => changes.add('${key.name}=$value'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('全员禁言'), findsOneWidget);
    expect(find.text('需管理员审批'), findsOneWidget);

    await tester.tap(find.text('允许直接加入'));
    await tester.pump();
    expect(changes, ['joinPolicy=${FlareGroupJoinPolicy.open}']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only renders values, no switch, and still explains why', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlareGroupPermissionMatrix(
              settings: settings,
              canManage: false,
            ),
          ),
        ),
      ),
    );
    expect(find.text('仅群主和管理员可修改'), findsOneWidget);
    expect(find.text('需管理员审批'), findsOneWidget);
    expect(find.text('已开启'), findsWidgets);
    expect(find.byType(FlareSwitch), findsNothing);
  });

  testWidgets(
    'a per-row failure shows its reason and keeps other rows editable',
    (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlareGroupPermissionMatrix(
                settings: settings,
                canManage: true,
                busyKeys: const ['onlyAdminCanPin'],
                errors: const {'muteAll': '网络错误，请重试'},
                onChange: (key, value) => changes.add('${key.name}=$value'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('网络错误，请重试'), findsOneWidget);
      expect(find.text('提交中'), findsOneWidget);

      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(changes, ['muteAll=true']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'join choices show open, approval, invite; an unknown policy selects none',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const strings = FlareStrings();
      final changes = <Object>[];
      Widget matrix({required bool canManage}) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlareGroupPermissionMatrix(
              settings: const FlareGroupPermissionSettings(),
              canManage: canManage,
              onChange: (key, value) => changes.add(value),
            ),
          ),
        ),
      );

      await tester.pumpWidget(matrix(canManage: true));
      final choices = [
        strings.groupPermissionMatrixJoinOpen,
        strings.groupPermissionMatrixJoinApproval,
        strings.groupPermissionMatrixJoinInvite,
      ];
      final lefts = [
        for (final label in choices) tester.getTopLeft(find.text(label)).dx,
      ];
      expect(lefts, [...lefts]..sort(), reason: 'display order');
      for (final label in choices) {
        expect(
          tester.getSemantics(find.text(label)),
          isSemantics(hasCheckedState: true, isChecked: false),
        );
      }
      expect(
        find.text(strings.groupPermissionMatrixUnknownJoinPolicy),
        findsOneWidget,
      );

      await tester.tap(find.text(strings.groupPermissionMatrixJoinInvite));
      await tester.pump();
      expect(changes, [FlareGroupJoinPolicy.invite]);

      // Read-only, the unknown policy is said, not guessed.
      await tester.pumpWidget(matrix(canManage: false));
      expect(
        find.text(strings.groupPermissionMatrixUnknownJoinPolicy),
        findsOneWidget,
      );
      for (final label in choices) {
        expect(find.text(label), findsNothing);
      }
      semantics.dispose();
    },
  );
}
