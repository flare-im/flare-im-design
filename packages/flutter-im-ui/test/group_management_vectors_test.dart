import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared group management table (`spec/group-management-vectors.json`):
/// the kit maps the host's answers — the viewer's capabilities and each
/// member's actions — to the entries they name, and decides nothing itself.
/// Vue (`group-permissions.test.ts`), SwiftUI and Compose run the same table.
void main() {
  final table =
      jsonDecode(
            File('../../spec/group-management-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  bool on(Map<String, dynamic>? map, String key) => map?[key] == true;

  FlareGroupCapabilities capabilities(Map<String, dynamic> raw) =>
      FlareGroupCapabilities(
        canManageInfo: on(raw, 'canManageInfo'),
        canManageJoinSettings: on(raw, 'canManageJoinSettings'),
        canManageJoinRequests: on(raw, 'canManageJoinRequests'),
        canInvite: on(raw, 'canInvite'),
        canDissolve: on(raw, 'canDissolve'),
      );

  FlareMemberActions? actions(Map<String, dynamic>? raw) => raw == null
      ? null
      : FlareMemberActions(
          canRemove: on(raw, 'canRemove'),
          canMute: on(raw, 'canMute'),
          canChangeRole: on(raw, 'canChangeRole'),
          canTransferOwner: on(raw, 'canTransferOwner'),
        );

  FlareGroupMemberRole role(String name) =>
      FlareGroupMemberRole.values.byName(name);

  List<FlareMemberRoleActionEntry> entries(List<dynamic> raw) => [
    for (final e in raw.cast<Map<String, dynamic>>())
      FlareMemberRoleActionEntry(
        FlareMemberRoleAction.values.byName(e['action'] as String),
        danger: e['danger'] as bool,
      ),
  ];

  test('keeps the shared display order', () {
    expect(
      FlareGroupManagementEntry.values.map((e) => e.id).toList(),
      table['entryOrder'],
    );
  });

  test('maps each capability to the entries it names, and nothing else', () {
    final cases = (table['entries'] as List).cast<Map<String, dynamic>>();
    expect(cases.length, greaterThanOrEqualTo(8));
    for (final vector in cases) {
      final got = groupManagementEntries(
        capabilities(vector['capabilities'] as Map<String, dynamic>),
      ).map((e) => e.id).toList();
      expect(got, vector['expected'], reason: vector['id'] as String);
    }
  });

  test('labels each member action from the host answer and the state', () {
    for (final vector
        in (table['memberActions'] as List).cast<Map<String, dynamic>>()) {
      final member = vector['member'] as Map<String, dynamic>;
      final got = memberRoleActions(
        role(member['role'] as String),
        member['muted'] as bool,
        actions(vector['actions'] as Map<String, dynamic>?),
      );
      expect(
        got,
        entries(vector['expected'] as List),
        reason: vector['id'] as String,
      );
    }
  });

  test('opens the detail member sheet only with what the host allows', () {
    for (final vector
        in (table['detailSheet'] as List).cast<Map<String, dynamic>>()) {
      final raw = vector['model'] as Map<String, dynamic>;
      final model = FlareGroupDetailModel(
        groupId: 'g',
        name: 'g',
        memberCount: 0,
        ownerId: raw['ownerId'] as String,
        adminIds: (raw['adminIds'] as List).cast<String>(),
        mutedIds: (raw['mutedIds'] as List).cast<String>(),
        memberActions: {
          for (final MapEntry(:key, :value)
              in (raw['memberActions'] as Map<String, dynamic>).entries)
            key: actions(value as Map<String, dynamic>)!,
        },
      );
      expect(
        groupDetailMemberActions(model, vector['memberId'] as String),
        entries(vector['expected'] as List),
        reason: vector['id'] as String,
      );
    }
  });

  test('a permission matrix row is editable exactly when its entry is '
      'offered', () {
    for (final vector
        in (table['entries'] as List).cast<Map<String, dynamic>>()) {
      final expected = (vector['expected'] as List).cast<String>();
      final rows = groupPermissionRows(
        const FlareGroupPermissionSettings(),
        capabilities(vector['capabilities'] as Map<String, dynamic>),
      );
      expect(
        rows.where((r) => r.editable).map((r) => r.key.name).toList(),
        [
          for (final key in FlareGroupPermissionKey.values)
            if (expected.contains(key.name)) key.name,
        ],
        reason: vector['id'] as String,
      );
    }
  });
}
