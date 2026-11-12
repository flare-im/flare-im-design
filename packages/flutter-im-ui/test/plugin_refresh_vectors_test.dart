import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  final table = jsonDecode(File('../../spec/plugin-refresh-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  for (final vector in table['pluginRefresh'] as List) {
    test(vector['name'] as String, () {
      expect(flarePluginMayRefresh(visible: vector['visible'] as bool, foreground: vector['foreground'] as bool, loading: vector['loading'] as bool, refreshing: vector['refreshing'] as bool, busy: vector['busy'] as bool, interaction: vector['interaction'] as bool), vector['expect']);
    });
  }
}
