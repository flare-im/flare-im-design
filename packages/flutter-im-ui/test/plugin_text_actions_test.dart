import 'dart:io';
import 'dart:ui' as ui;
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

FlarePluginViewModel specimen({bool actions = true}) => FlarePluginViewModel.fromJson({
  'available': true, 'title': '接龙', 'detail': true,
  'blocks': [{'kind': 'text', 'text': '周五下午茶，一起点点心'}],
  'actions': actions ? [
    {'id': 'join', 'label': '参与接龙', 'style': 'primary'},
    {'id': 'end', 'label': '结束接龙', 'style': 'danger'},
  ] : [],
});
Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light, fontFamily: 'CardReview'),
  home: Scaffold(body: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Align(alignment: Alignment.topCenter, child: child))),
);
Finder keyButton(String id) => find.byKey(ValueKey('flare-plugin-action-$id'));
BoxDecoration surface(WidgetTester tester, Finder button) => tester.widget<AnimatedContainer>(
  find.descendant(of: button, matching: find.byType(AnimatedContainer))).decoration! as BoxDecoration;

void main() {
  for (final dark in [false, true]) {
    testWidgets('text hover and keyboard focus stay undecorated in ${dark ? 'dark' : 'light'}', (tester) async {
      final strategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
      var calls = 0;
      await tester.pumpWidget(host(FlareButton(label: 'Run', appearance: FlareButtonAppearance.text,
        variant: FlareButtonVariant.secondary, onPressed: () => calls++), dark: dark));
      final button = find.byType(FlareButton);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(button));
      await tester.pumpAndSettle();
      expect(surface(tester, button).border!.top.color, Colors.transparent);
      expect(surface(tester, button).color, Colors.transparent);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(surface(tester, button).border!.top.color, Colors.transparent);
      expect(surface(tester, button).color!.a, greaterThan(0));
      expect(tester.widget<Text>(find.text('Run')).style!.decoration, TextDecoration.none);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, 1);
      await mouse.removePointer();
    });
  }
  testWidgets('details shares the action row and dispatches only the requested callback', (tester) async {
    String? invoked;
    var details = 0;
    await tester.pumpWidget(host(SizedBox(width: 390, child: FlarePluginView(view: specimen(),
      onAction: (id, _) => invoked = id, onOpenDetail: () => details++))));
    await tester.pumpAndSettle();
    final join = tester.getRect(keyButton('join'));
    final end = tester.getRect(keyButton('end'));
    final detail = tester.getRect(find.byKey(FlarePluginView.detailKey));
    expect(detail.center.dy, closeTo(join.center.dy, 1));
    expect(join.overlaps(end), isFalse);
    expect(end.overlaps(detail), isFalse);
    for (final rect in [join, end, detail]) { expect(rect.height, greaterThanOrEqualTo(48)); expect(rect.width, greaterThanOrEqualTo(48)); }
    await tester.tap(keyButton('join'));
    expect(invoked, 'join');
    await tester.tap(find.byKey(FlarePluginView.detailKey));
    expect(details, 1);
    expect(invoked, 'join');
  });
  testWidgets('without footer actions details stays in the header', (tester) async {
    await tester.pumpWidget(host(FlarePluginView(view: specimen(actions: false), onOpenDetail: () {})));
    final title = tester.getRect(find.text('接龙'));
    final detail = tester.getRect(find.byKey(FlarePluginView.detailKey));
    expect(detail.center.dy, closeTo(title.center.dy, 1));
  });
  testWidgets('narrow dark large text wraps without overlapping or losing disabled state', (tester) async {
    tester.view.physicalSize = const Size(220, 900); tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);
    await tester.pumpWidget(host(FlarePluginView(view: specimen(), busy: true, onAction: (_, _) {}, onOpenDetail: () {}), dark: true, scale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final detail = tester.getRect(find.byKey(FlarePluginView.detailKey));
    for (final id in ['join', 'end']) {
      final rect = tester.getRect(keyButton(id));
      expect(rect.overlaps(detail), isFalse);
      expect(rect.left, greaterThanOrEqualTo(0)); expect(rect.right, lessThanOrEqualTo(220));
      expect(tester.widget<FlareButton>(keyButton(id)).disabled, isTrue);
    }
  });
  if (Platform.environment['FLARE_CARD_SCREENSHOTS'] case final output?) {
    for (final dark in [false, true]) {
      testWidgets('capture compact card ${dark ? 'dark' : 'light'}', (tester) async {
        tester.view.physicalSize = const Size(390, 400); tester.view.devicePixelRatio = 1; addTearDown(tester.view.reset);
        await tester.runAsync(() async {
          final font = Platform.environment['FLARE_CARD_FONT'];
          if (font != null) await (FontLoader('CardReview')..addFont(File(font).readAsBytes().then((b) => ByteData.sublistView(b)))).load();
          final icons = Platform.environment['FLARE_CARD_ICONS'];
          if (icons != null) await (FontLoader('MaterialIcons')..addFont(File(icons).readAsBytes().then((b) => ByteData.sublistView(b)))).load();
        });
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: key, child: host(Padding(padding: const EdgeInsets.all(20),
          child: FlarePluginView(view: specimen(), onAction: (_, _) {}, onOpenDetail: () {})), dark: dark)));
        await tester.pumpAndSettle();
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(); final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/flutter-card-${dark ? 'dark' : 'light'}.png').writeAsBytes(bytes!.buffer.asUint8List()); image.dispose();
        });
      });
    }
  }
}
