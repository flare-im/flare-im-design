import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-057: a failed refresh over rows worth keeping does not wipe what someone was reading.

void main() {
  test('presentation matches the shared table', () {
    final table =
        jsonDecode(
              File(
                '${Directory.current.path}/../../spec/view-state-vectors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cases = (table['cases'] as List).cast<Map<String, dynamic>>();
    expect(cases.length, greaterThanOrEqualTo(10));
    for (final c in cases) {
      final status = FlareViewStatus.values.firstWhere(
        (s) => s.name == c['status'] as String,
      );
      expect(
        flareViewPresentation(status, c['stale'] as bool).name,
        c['presentation'] as String,
        reason: c['id'] as String,
      );
    }
  });
}
