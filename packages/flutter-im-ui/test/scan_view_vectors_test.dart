import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  final table = jsonDecode(File('../../spec/scan-view-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  for (final vector in table['markerBounds'] as List) {
    test(vector['name'] as String, () {
      final bounds = flareScanMarkerBounds((vector['corners'] as List).map((point) => FlareScanPoint((point['x'] as num).toDouble(), (point['y'] as num).toDouble())));
      final actual = {'left': bounds.left, 'top': bounds.top, 'width': bounds.width, 'height': bounds.height};
      for (final entry in (vector['expect'] as Map).entries) { expect(actual[entry.key], closeTo((entry.value as num).toDouble(), 0.000001)); }
    });
  }
  for (final vector in table['pluginRefresh'] as List) {
    test(vector['name'] as String, () {
      expect(flarePluginMayRefresh(visible: vector['visible'] as bool, foreground: vector['foreground'] as bool, loading: vector['loading'] as bool, refreshing: vector['refreshing'] as bool, busy: vector['busy'] as bool, interaction: vector['interaction'] as bool), vector['expect']);
    });
  }
}
