import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-100: moments privacy in words, not SDK codes.

void main() {
  test('the kit enums are the shared vocabulary', () {
    final vocabulary =
        jsonDecode(
              File(
                '${Directory.current.path}/../../spec/moments-privacy.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(
      FlareMomentVisibility.values.map((v) => v.name).toList(),
      (vocabulary['visibility'] as List).cast<String>(),
    );
    expect(
      FlareMomentAudienceMode.values.map((v) => v.name).toList(),
      (vocabulary['audienceMode'] as List).cast<String>(),
    );
    expect(
      FlareMomentHistoryRange.values.map((v) => v.name).toList(),
      (vocabulary['historyRange'] as List).cast<String>(),
    );
    expect(
      FlareMomentVisibility.values.where(flareMomentAudienceApplies).map((v) => v.name).toList(),
      ['friends', 'public'],
    );
  });
}
