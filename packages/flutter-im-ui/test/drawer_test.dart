import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pumpHost(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
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

void main() {
  testWidgets('drawer: full height at the inline end, the kit sheet width', (
    tester,
  ) async {
    final context = await _pumpHost(tester, const Size(1360, 900));
    final result = FlareBottomSheet.show<String>(
      context,
      presentation: FlareSheetPresentation.drawer,
      builder: (_) => const Text('群信息'),
    );
    await tester.pumpAndSettle();

    final panel = tester.getRect(
      find
          .ancestor(of: find.text('群信息'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(panel.right, 1360);
    expect(panel.width, FlareSizes.componentSheetWidth);
    expect(panel.top, 0);
    expect(panel.bottom, 900);

    // The scrim beside it closes it without a value.
    await tester.tapAt(const Offset(200, 450));
    await tester.pumpAndSettle();
    expect(find.text('群信息'), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('drawer: never wider than a narrow window', (tester) async {
    final context = await _pumpHost(tester, const Size(360, 780));
    FlareBottomSheet.show<void>(
      context,
      presentation: FlareSheetPresentation.drawer,
      builder: (_) => const Text('好友资料'),
    );
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find
          .ancestor(of: find.text('好友资料'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(panel.width, 360);
  });

  testWidgets('sheet stays the default presentation', (tester) async {
    final context = await _pumpHost(tester, const Size(402, 874));
    FlareBottomSheet.show<void>(context, builder: (_) => const Text('选项'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
