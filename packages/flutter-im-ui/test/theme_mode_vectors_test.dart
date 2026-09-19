import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared theme table (`spec/theme-mode-vectors.json`): the host holds the person's choice and the kit
/// resolves it. The same file is read by the Vue, SwiftUI and Compose tests.
void main() {
  final table = jsonDecode(File('../../spec/theme-mode-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  FlareThemeMode modeOf(String name) => FlareThemeMode.values.firstWhere((value) => value.name == name);

  test('the table covers every mode', () {
    expect(cases.length, FlareThemeMode.values.length * 2);
  });

  for (final vector in cases) {
    test('theme vector: ${vector['id']}', () {
      expect(
        flareThemeIsDark(modeOf(vector['mode'] as String), systemDark: vector['systemDark'] as bool),
        vector['dark'],
      );
    });
  }

  testWidgets('the colours a body draws follow the mode the host chose, not the platform', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late FlareColors underSystem;
    late FlareColors underDark;
    await tester.pumpWidget(MaterialApp(
      home: Column(children: [
        FlareTheme(child: Builder(builder: (context) {
          underSystem = FlareColors.of(context);
          return const SizedBox.shrink();
        })),
        FlareTheme(mode: FlareThemeMode.dark, child: Builder(builder: (context) {
          underDark = FlareColors.of(context);
          return const SizedBox.shrink();
        })),
      ]),
    ));
    expect(underSystem.bgPrimary, FlareColors.violetLight.bgPrimary);
    expect(underDark.bgPrimary, FlareColors.violetDark.bgPrimary);
  });

  testWidgets('system follows the app, which follows the platform, and the strings carry the three labels', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late FlareColors drawn;
    // The app resolves `system` the way every Flutter app does — light and dark themes with
    // `ThemeMode.system` — and the kit follows the theme it lands on.
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: FlareTheme(child: Builder(builder: (context) {
        drawn = FlareColors.of(context);
        return const SizedBox.shrink();
      })),
    ));
    expect(drawn.bgPrimary, FlareColors.violetDark.bgPrimary);
    const strings = FlareStrings();
    expect([strings.themeSystem, strings.themeLight, strings.themeDark], ['跟随系统', '浅色', '深色']);
  });
}
