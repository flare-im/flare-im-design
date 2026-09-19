import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-056: one conversation-kind vocabulary for every kit and every component.

void main() {
  test('the kit enum is the shared vocabulary', () {
    final vocabulary =
        jsonDecode(
              File(
                '${Directory.current.path}/../../spec/conversation-kind.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(
      FlareConversationKind.values.map((kind) => kind.name).toList(),
      (vocabulary['kinds'] as List).cast<String>(),
    );
  });
}
