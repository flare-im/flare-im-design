import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Size size, Widget modal) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: modal)));
  await tester.pumpAndSettle();
}

Rect _box(WidgetTester tester) => tester.getRect(
  find
      .descendant(of: find.byType(FlareModal), matching: find.byType(Container))
      .first,
);

Finder get _close => find.byWidgetPredicate(
  (widget) => widget is FlareIconButton && widget.icon == 'close',
);

void main() {
  testWidgets('centered at the kit dialog width', (tester) async {
    await _pump(
      tester,
      const Size(1280, 800),
      const FlareModal(title: '标题', child: Text('正文')),
    );
    final box = _box(tester);
    expect(box.width, FlareSizes.componentSheetDialogWidth);
    expect(box.center.dx, closeTo(640, 1));
    expect(box.center.dy, closeTo(400, 1));
  });

  testWidgets('clamped to the window minus the page gutters', (tester) async {
    await _pump(
      tester,
      const Size(320, 700),
      const FlareModal(width: 720, title: '标题', child: Text('正文')),
    );
    expect(_box(tester).width, 320 - 2 * FlareSizes.spacingXl);
  });

  testWidgets('fill takes the whole height cap; a non-scrolling body owns '
      'its scrolling', (tester) async {
    await _pump(
      tester,
      const Size(1280, 800),
      FlareModal(
        title: '搜索',
        width: 720,
        maxHeight: 500,
        fill: true,
        scrollable: false,
        child: ListView(
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 40, child: Text('结果 $i')),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final box = _box(tester);
    expect(box.width, 720);
    expect(box.height, 500);
  });

  testWidgets('the footer is a trailing row wide and a stacked column on a '
      'phone, primary on top', (tester) async {
    Widget modal() => FlareModal(
      title: '删除',
      footer: [
        FlareButton(label: '取消', onPressed: () {}),
        FlareButton(label: '删除', onPressed: () {}),
      ],
      child: const Text('正文'),
    );
    await _pump(tester, const Size(1280, 800), modal());
    var cancel = tester.getRect(find.widgetWithText(FlareButton, '取消'));
    var confirm = tester.getRect(find.widgetWithText(FlareButton, '删除'));
    expect(cancel.top, confirm.top);
    expect(confirm.left, greaterThan(cancel.right));
    expect(
      confirm.right,
      closeTo(_box(tester).right - FlareSizes.spacingXl, 1),
    );

    await _pump(tester, const Size(402, 874), modal());
    cancel = tester.getRect(find.widgetWithText(FlareButton, '取消'));
    confirm = tester.getRect(find.widgetWithText(FlareButton, '删除'));
    expect(confirm.bottom, lessThanOrEqualTo(cancel.top));
    expect(confirm.width, cancel.width);
  });

  testWidgets('busy disables the close control and blocks back', (
    tester,
  ) async {
    var closed = 0;
    await _pump(
      tester,
      const Size(1280, 800),
      FlareModal(
        title: '保存中',
        busy: true,
        onClose: () => closed++,
        child: const Text('正文'),
      ),
    );
    expect(tester.widget<FlareIconButton>(_close).disabled, isTrue);
    await tester.tap(_close);
    expect(closed, 0);
  });

  testWidgets('showClose false draws no close; the close control reports', (
    tester,
  ) async {
    var closed = 0;
    await _pump(
      tester,
      const Size(1280, 800),
      FlareModal(
        title: '标题',
        onClose: () => closed++,
        actions: [TextButton(onPressed: () {}, child: const Text('编辑'))],
        child: const Text('正文'),
      ),
    );
    expect(find.text('编辑'), findsOneWidget);
    await tester.tap(_close);
    expect(closed, 1);

    await _pump(
      tester,
      const Size(1280, 800),
      const FlareModal(title: '标题', showClose: false, child: Text('正文')),
    );
    expect(_close, findsNothing);
  });

  testWidgets('without a visible title the label, or the strings table, '
      'names it', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const Size(1280, 800),
      const FlareModal(label: '全局搜索', showClose: false, child: Text('正文')),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('全局搜索')),
      isSemantics(label: '全局搜索', namesRoute: true),
    );

    await _pump(
      tester,
      const Size(1280, 800),
      const FlareModal(showClose: false, child: Text('正文')),
    );
    expect(
      find.bySemanticsLabel(const FlareStrings().modalLabel),
      findsOneWidget,
    );

    await _pump(
      tester,
      const Size(1280, 800),
      const FlareModal(title: '隐藏标题', titleHidden: true, child: Text('正文')),
    );
    expect(find.text('隐藏标题'), findsNothing);
    expect(find.bySemanticsLabel('隐藏标题'), findsOneWidget);
    semantics.dispose();
  });
}
