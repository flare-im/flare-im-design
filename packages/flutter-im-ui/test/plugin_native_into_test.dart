import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final List<Map<String, Object?>> vectors = [
  for (final c
      in ((jsonDecode(
                File(
                  '../../spec/plugin-native-into-vectors.json',
                ).readAsStringSync(),
              )
              as Map)['cases']
          as List))
    (c as Map).cast<String, Object?>(),
];

Widget host(Widget body) => MaterialApp(
  home: FlareStringsScope(
    strings: flareStringsEnglish,
    child: Scaffold(
      body: SizedBox(height: 900, child: SingleChildScrollView(child: body)),
    ),
  ),
);

final Map<String, Object?> identity = {
  'available': true,
  'title': 'Identity',
  'fields': const [],
  'inputs': [
    {
      'id': 'front',
      'kind': 'document',
      'label': 'Front',
      'required': true,
      'side': 'front',
      'file': {
        'accept': ['image/jpeg'],
        'maxBytes': 1048576,
      },
    },
  ],
  'actions': [
    {
      'id': 'scan',
      'label': 'Scan',
      'target': {
        'kind': 'native',
        'capability': 'documentCapture',
        'params': {'side': 'front'},
        'into': 'front',
      },
    },
    {
      'id': 'submit',
      'label': 'Submit',
      'style': 'primary',
      'form': ['front'],
      'target': {'kind': 'operation', 'operation': 'example.submit'},
    },
  ],
};

void main() {
  test('a native target runs through the input it names (vectors)', () {
    for (final c in vectors) {
      final raw = (c['input'] as Map).cast<String, Object?>();
      final input = FlarePluginInput(
        id: raw['id'] as String,
        kind: FlarePluginInputKind.values.byName(raw['kind'] as String),
        label: '',
      );
      final target = switch (c['target']) {
        final Map<Object?, Object?> t => FlarePluginActionTarget.fromJson(
          t.cast<String, Object?>(),
        ),
        _ => null,
      };
      expect(flarePluginNativeIntoKey(target, input), c['key'], reason: '$c');
    }
  });

  test('actions carry their target', () {
    final view = FlarePluginViewModel.fromJson(identity);
    final scan = view.actions.firstWhere((a) => a.id == 'scan');
    expect(scan.target?.kind, 'native');
    expect(scan.target?.capability, 'documentCapture');
    expect(scan.target?.into, 'front');
    expect(scan.target?.params, {'side': 'front'});
  });

  testWidgets(
    'a page scan action fills the inline document input instead of going out',
    (tester) async {
      final sent = <String>[];
      final files = <FlarePluginFileAction>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(identity),
            inlineFormActionId: 'submit',
            onAction: (id, _) => sent.add(id),
            onFileAction: files.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('flare-plugin-action-scan')));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(files.map((a) => (a.action, a.inputId)), [
        (FlarePluginFileActionKind.choose, 'front'),
      ]);
      expect(files.single.scope, isNotEmpty);
    },
  );
}
