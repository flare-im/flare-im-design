import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _wide = Size(1360, 900);
const _phone = Size(402, 874);

Future<BuildContext> _pumpHost(
  WidgetTester tester,
  Size size, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Builder(
        builder: (context) {
          captured = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );
  return captured;
}

/// The drawer panel around [text]: the decorated box with the kit's panel
/// shadow.
Rect _panel(WidgetTester tester, String text) => tester.getRect(
  find
      .ancestor(
        of: find.text(text),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).boxShadow != null,
        ),
      )
      .first,
);

Finder _iconButton(String icon) => find.byWidgetPredicate(
  (widget) => widget is FlareIconButton && widget.icon == icon,
);

/// A root page that answers its own pop with a "changed" flag, like the
/// app's contact details.
class _RootPage extends StatelessWidget {
  const _RootPage({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) Navigator.of(context).pop(result);
    },
    child: Column(
      children: [
        const Text('资料'),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const Text('成员列表'))),
          child: const Text('查看成员'),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('full height at the inline end, the kit sheet width', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(context, builder: (_) => const Text('群信息'));
    await tester.pumpAndSettle();
    final panel = _panel(tester, '群信息');
    expect(panel.right, _wide.width);
    expect(panel.width, FlareSizes.componentSheetWidth);
    expect(panel.top, 0);
    expect(panel.bottom, _wide.height);
  });

  testWidgets('placement start docks at the inline start, mirrored in RTL', (
    tester,
  ) async {
    var context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(
      context,
      placement: FlareDrawerPlacement.start,
      builder: (_) => const Text('导航'),
    );
    await tester.pumpAndSettle();
    expect(_panel(tester, '导航').left, 0);

    context = await _pumpHost(tester, _wide, direction: TextDirection.rtl);
    FlareDrawer.show<void>(context, builder: (_) => const Text('详情'));
    await tester.pumpAndSettle();
    expect(_panel(tester, '详情').left, 0, reason: 'end is the left in RTL');
  });

  testWidgets('the width is clamped so a strip of scrim always remains', (
    tester,
  ) async {
    final context = await _pumpHost(tester, const Size(360, 780));
    FlareDrawer.show<void>(context, builder: (_) => const Text('好友资料'));
    await tester.pumpAndSettle();
    expect(_panel(tester, '好友资料').width, 360 - FlareSizes.touchTarget);

    await tester.tapAt(const Offset(10, 400));
    await tester.pumpAndSettle();
    expect(find.text('好友资料'), findsNothing);
  });

  testWidgets('the content is on screen from the first frame', (tester) async {
    final context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(context, builder: (_) => const Text('群信息'));
    await tester.pump();
    expect(find.text('群信息'), findsOneWidget);
  });

  testWidgets('the scrim closes the whole stack with the root page result', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _wide);
    final result = FlareDrawer.show<Object?>(
      context,
      label: '联系人详情',
      builder: (_) => const _RootPage(result: 'changed'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看成员'));
    await tester.pumpAndSettle();
    expect(find.text('成员列表'), findsOneWidget);

    await tester.tapAt(const Offset(200, 450));
    await tester.pumpAndSettle();
    expect(find.text('成员列表'), findsNothing);
    expect(find.text('资料'), findsNothing);
    expect(await result, 'changed');
  });

  testWidgets('back and Escape go back one page, then close the drawer', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _wide);
    final result = FlareDrawer.show<Object?>(
      context,
      builder: (_) => const _RootPage(result: 'changed'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看成员'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('成员列表'), findsNothing);
    expect(find.text('资料'), findsOneWidget, reason: 'still in the drawer');

    await tester.tap(find.text('查看成员'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('成员列表'), findsNothing);
    expect(find.text('资料'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('资料'), findsNothing);
    expect(await result, 'changed');
  });

  testWidgets('a drawer that is not dismissible stays on the root page', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(
      context,
      dismissible: false,
      builder: (_) => const Text('保存中'),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 450));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('保存中'), findsOneWidget);
  });

  testWidgets('the root page closes the drawer with what it pops', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _wide);
    final result = FlareDrawer.show<String>(
      context,
      builder: (pageContext) => TextButton(
        onPressed: () => Navigator.of(pageContext).pop('saved'),
        child: const Text('保存'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('保存'), findsNothing);
    expect(await result, 'saved');
  });

  testWidgets('a host popUntil that removes the drawer leaves the page alone', (
    tester,
  ) async {
    final context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(context, builder: (_) => const Text('群信息'));
    await tester.pumpAndSettle();
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(MaterialPageRoute<void>(builder: (_) => const Text('聊天')));
    await tester.pumpAndSettle();
    expect(find.text('群信息'), findsNothing);
    expect(find.text('聊天'), findsOneWidget);
  });

  testWidgets('a non-navigable drawer draws its header and close control', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final context = await _pumpHost(tester, _wide);
    final result = FlareDrawer.show<void>(
      context,
      title: '设置',
      navigable: false,
      builder: (_) => const Text('通知'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('设置')),
      isSemantics(isHeader: true, namesRoute: true),
    );
    await tester.tap(_iconButton('close'));
    await tester.pumpAndSettle();
    expect(find.text('通知'), findsNothing);
    await result;
    semantics.dispose();
  });

  testWidgets('without a title the label, or the strings table, names it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(context, builder: (_) => const Text('页面'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(const FlareStrings().drawerLabel),
      ),
      isSemantics(label: const FlareStrings().drawerLabel, namesRoute: true),
    );
    semantics.dispose();
  });

  testWidgets('the scrim is the kit scrim token', (tester) async {
    final context = await _pumpHost(tester, _wide);
    FlareDrawer.show<void>(context, builder: (_) => const Text('群信息'));
    await tester.pumpAndSettle();
    final scrim = FlareColors.of(context).scrim;
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((box) => box.color),
      contains(scrim),
    );
  });

  group('FlareDrawer.showAdaptive', () {
    testWidgets('a phone pushes a page', (tester) async {
      final context = await _pumpHost(tester, _phone);
      FlareDrawer.showAdaptive<void>(
        context,
        builder: (_) => const Scaffold(body: Text('群信息')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareDrawer), findsNothing);
      expect(tester.getRect(find.byType(Scaffold).last).width, _phone.width);
    });

    testWidgets('asPage — the host layout fact — wins over the form factor', (
      tester,
    ) async {
      final context = await _pumpHost(tester, _wide);
      FlareDrawer.showAdaptive<void>(
        context,
        asPage: true,
        builder: (_) => const Scaffold(body: Text('群信息')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareDrawer), findsNothing);
      expect(find.text('群信息'), findsOneWidget);

      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      FlareDrawer.showAdaptive<void>(
        context,
        asPage: false,
        builder: (_) => const Text('群资料'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareDrawer), findsOneWidget);
    });

    testWidgets('a wide window opens a drawer, and inside it pushes a page', (
      tester,
    ) async {
      final context = await _pumpHost(tester, _wide);
      final result = FlareDrawer.showAdaptive<void>(
        context,
        builder: (pageContext) => TextButton(
          onPressed: () => FlareDrawer.showAdaptive<void>(
            pageContext,
            builder: (_) => const Text('成员资料'),
          ),
          child: const Text('成员'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareDrawer), findsOneWidget);
      await tester.tap(find.text('成员'));
      await tester.pumpAndSettle();
      expect(find.byType(FlareDrawer), findsOneWidget, reason: 'not stacked');
      expect(
        find.ancestor(
          of: find.text('成员资料'),
          matching: find.byType(FlareDrawer),
        ),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('成员'), findsOneWidget);
      await tester.tapAt(const Offset(200, 450));
      await tester.pumpAndSettle();
      await result;
      expect(find.byType(FlareDrawer), findsNothing);
    });
  });

  group('FlareDrawer (host-driven)', () {
    testWidgets('showBack draws back; Escape and back emit it, not close', (
      tester,
    ) async {
      final events = <String>[];
      tester.view.physicalSize = _wide;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareDrawer(
              title: '隐私',
              showBack: true,
              onBack: () => events.add('back'),
              onClose: () => events.add('close'),
              actions: [TextButton(onPressed: () {}, child: const Text('编辑'))],
              footer: const Text('底部'),
              child: const Focus(autofocus: true, child: Text('内容')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('底部'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(_iconButton('back'));
      await tester.tap(_iconButton('close'));
      expect(events, ['back', 'back', 'back', 'close']);
    });
  });
}
