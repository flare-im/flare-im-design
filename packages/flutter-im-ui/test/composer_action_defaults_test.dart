import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The "+" panel's built-in features and the plugin glyph fallback: the same
// ids, order, glyphs and labels on every platform (contract `composerActions`).
Widget _host(Widget child, {FlareStrings strings = const FlareStrings()}) =>
    MaterialApp(
      home: FlareStringsScope(
        strings: strings,
        child: Scaffold(body: child),
      ),
    );

List<IconData?> _glyphs(WidgetTester tester) => tester
    .widgetList<Icon>(
      find.descendant(
        of: find.byType(FlareComposerActionPanel),
        matching: find.byType(Icon),
      ),
    )
    .map((icon) => icon.icon)
    .toList();

void main() {
  test('the default set is the built-in features, in panel order', () {
    const defaults = FlareComposerActionPanel.defaultActions;
    expect(defaults.map((a) => a.id), [
      'image',
      'camera',
      'video',
      'file',
      'voice',
      'location',
      'card',
    ]);
    expect(defaults.map((a) => a.icon), [
      'image',
      'camera',
      'video',
      'file',
      'mic',
      'location',
      'card',
    ]);
    // Polls come from the poll plugin now.
    expect(defaults.any((a) => a.id == 'poll'), isFalse);
    for (final action in defaults) {
      expect(action.kind, FlareComposerActionKind.feature);
      expect(action.label, isNull, reason: action.id);
      expect(flareIconNames, contains(action.icon));
    }
    expect(defaults.any((a) => a.id == 'contact'), isFalse);
  });

  test('every built-in id is labelled by the kit in Chinese and English', () {
    String labels(FlareStrings strings) => FlareComposerActionPanel
        .defaultActions
        .map((a) => a.resolveLabel(strings))
        .join(',');
    expect(labels(const FlareStrings()), '图片,拍摄,视频,文件,语音,位置,名片');
    expect(
      labels(flareStringsEnglish),
      'Photo,Camera,Video,File,Voice,Location,Contact card',
    );
  });

  test('an icon name the registry does not know falls back to plugin', () {
    const known = FlareComposerAction(
      id: 'plugin:flare.redpacket.send',
      label: '红包',
      icon: 'red-packet',
      kind: FlareComposerActionKind.plugin,
    );
    const unknown = FlareComposerAction(
      id: 'plugin:acme.form',
      label: '表单',
      icon: 'clipboard-form',
      kind: FlareComposerActionKind.plugin,
    );
    const blank = FlareComposerAction(
      id: 'plugin:acme.vote',
      label: '投票插件',
      icon: '',
      kind: FlareComposerActionKind.plugin,
    );
    expect(known.resolvedIcon, 'red-packet');
    expect(unknown.resolvedIcon, flareComposerPluginIcon);
    expect(blank.resolvedIcon, 'plugin');
    // The same rule for a feature: a registry name draws itself, any other
    // name the plugin glyph.
    const feature = FlareComposerAction(id: 'file', icon: 'folder');
    expect(feature.kind, isNull);
    expect(feature.resolvedIcon, 'folder');
    const typo = FlareComposerAction(id: 'file', icon: 'folder-open');
    expect(typo.resolvedIcon, 'plugin');
  });

  testWidgets('the default panel draws the registry glyphs in order', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const FlareComposerActionPanel()));
    expect(_glyphs(tester), [
      flareIconMap['image'],
      flareIconMap['camera'],
      flareIconMap['video'],
      flareIconMap['file'],
      flareIconMap['mic'],
      flareIconMap['location'],
      flareIconMap['card'],
    ]);
    expect(find.text('投票'), findsNothing);
    for (final label in ['图片', '拍摄', '视频', '文件', '语音', '位置', '名片']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('plugin tiles follow the features and draw the plugin glyph', (
    tester,
  ) async {
    FlareComposerAction? picked;
    await tester.pumpWidget(
      _host(
        FlareComposerActionPanel(
          actions: const [
            FlareComposerAction(id: 'image', icon: 'image', order: 10),
            FlareComposerAction(id: 'poll', icon: 'poll', order: 60),
            FlareComposerAction(
              id: 'plugin:flare.redpacket.send',
              label: '红包',
              icon: 'red-packet',
              kind: FlareComposerActionKind.plugin,
              order: 100,
            ),
            FlareComposerAction(
              id: 'plugin:acme.form',
              label: '表单',
              icon: 'clipboard-form',
              kind: FlareComposerActionKind.plugin,
              order: 110,
            ),
          ],
          onAction: (action) => picked = action,
        ),
      ),
    );
    expect(_glyphs(tester), [
      flareIconMap['image'],
      flareIconMap['poll'],
      flareKitRedPacket,
      Icons.extension_outlined,
    ]);
    expect(find.text('图片'), findsOneWidget);
    expect(find.text('投票'), findsOneWidget);
    await tester.tap(find.text('表单'));
    expect(picked?.id, 'plugin:acme.form');
    expect(picked?.kind, FlareComposerActionKind.plugin);
  });
}
