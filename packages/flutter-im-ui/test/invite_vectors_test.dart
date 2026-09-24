import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/src/models/invite_data.dart';
import 'package:flutter_test/flutter_test.dart';

// The shared invite table (spec/invite-vectors.json), run vector by vector so a
// rule that drifts on one platform reddens here and nowhere else.
void main() {
  final file = File('${Directory.current.path}/../../spec/invite-vectors.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> table(String key) =>
      (data[key] as List).cast<Map<String, dynamic>>();

  FlareInviteCodeMode mode(String? name) => switch (name) {
    'off' => FlareInviteCodeMode.off,
    'required' => FlareInviteCodeMode.required,
    _ => FlareInviteCodeMode.optional,
  };
  FlareInviteCodeCheckResult? result(Map<String, dynamic>? raw) => raw == null
      ? null
      : FlareInviteCodeCheckResult(
          valid: raw['valid'] as bool,
          inviterDisplayName: raw['inviterDisplayName'] as String?,
        );
  FlareReferralStats? stats(Map<String, dynamic>? raw) => raw == null
      ? null
      : FlareReferralStats(
          direct: raw['direct'] as int,
          l2: raw['l2'] as int,
          l3: raw['l3'] as int,
          total: raw['total'] as int,
        );

  group('normalize', () {
    for (final v in table('normalize')) {
      test(v['id'] as String, () {
        final length = (v['length'] as int?) ?? flareInviteCodeDefaultLength;
        final once = normalizeInviteCode(v['raw'] as String, length);
        expect(once, v['expected']);
        expect(normalizeInviteCode(once, length), once, reason: 'idempotent');
      });
    }
  });

  group('fieldState', () {
    for (final v in table('fieldState')) {
      test(v['id'] as String, () {
        final state = inviteCodeFieldState(
          mode: mode(v['mode'] as String?),
          value: v['value'] as String,
          checking: (v['checking'] as bool?) ?? false,
          checkResult: result(v['checkResult'] as Map<String, dynamic>?),
          error: v['error'] as String?,
          disabled: (v['disabled'] as bool?) ?? false,
        );
        expect(state.name, v['expected']);
      });
    }
  });

  group('checkRequest', () {
    for (final v in table('checkRequest')) {
      test(v['id'] as String, () {
        expect(
          inviteCodeToCheck(
            value: v['value'] as String,
            length: (v['length'] as int?) ?? flareInviteCodeDefaultLength,
            mode: mode(v['mode'] as String?),
            disabled: (v['disabled'] as bool?) ?? false,
          ),
          v['expected'],
        );
      });
    }
  });

  group('depthRows', () {
    for (final v in table('depthRows')) {
      test(v['id'] as String, () {
        final rows = referralDepthRows(
          stats(v['stats'] as Map<String, dynamic>?),
          v['maxDepthShown'] as int,
        );
        expect(rows.map((r) => r.name).toList(), v['expected']);
      });
    }
  });

  group('regenerate', () {
    for (final v in table('regenerate')) {
      test(v['id'] as String, () {
        final a = regenerateAvailability(
          v['canRegenerate'] as bool,
          v['availableAt'] as int?,
          v['now'] as int,
        );
        final expected = v['expected'] as Map<String, dynamic>;
        expect(a.shown, expected['shown']);
        expect(a.enabled, expected['enabled']);
        final remaining = expected['remaining'] as Map<String, dynamic>?;
        if (remaining == null) {
          expect(a.remaining, isNull);
        } else {
          expect(a.remaining!.unit.name, remaining['unit']);
          expect(a.remaining!.count, remaining['count']);
        }
      });
    }
  });

  group('joinedDate', () {
    for (final v in table('joinedDate')) {
      test(v['id'] as String, () {
        expect(
          formatInviteJoinedDate(v['year'] as int, v['month'] as int, v['day'] as int),
          v['expected'],
        );
      });
    }
  });
}
