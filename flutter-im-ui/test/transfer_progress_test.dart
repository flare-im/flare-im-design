import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  test('unknown progress stays unknown and terminal state is complete', () {
    expect(FlareTransferState.transferring.normalizedProgress(null), isNull);
    expect(FlareTransferState.transferring.normalizedProgress(double.nan), isNull);
    expect(FlareTransferState.transferring.normalizedProgress(0), 0);
    expect(FlareTransferState.transferring.normalizedProgress(2), 1);
    expect(FlareTransferState.completed.normalizedProgress(null), 1);
  });
  for (final state in FlareTransferState.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$state small phone text=$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        FlareTransferAction? picked;
        final labels = {for (final a in FlareTransferAction.values) a: a.name};
        Future<void> render(bool busy) => tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: Scaffold(body: SingleChildScrollView(child: FlareTransferProgress(
            name: '项目文档-长文件名-Quarterly-Report.pdf', state: state, statusText: '等待网络恢复，请稍后再试',
            actionLabels: labels, busy: busy, onAction: (a) => picked = a,
          ))),
        ));
        await render(false);
        expect(tester.takeException(), isNull);
        final expected = switch (state) {
          FlareTransferState.queued => ['cancel'],
          FlareTransferState.transferring => ['pause', 'cancel'],
          FlareTransferState.paused => ['resume', 'cancel'],
          FlareTransferState.failed || FlareTransferState.cancelled => ['retry'],
          FlareTransferState.completed => ['open'],
        };
        expect(find.byType(TextButton), findsNWidgets(expected.length));
        for (final label in expected) {
          final button = find.widgetWithText(TextButton, label);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          await tester.tap(button);
          expect(picked?.name, label);
        }
        picked = null;
        await render(true);
        for (final button in tester.widgetList<TextButton>(find.byType(TextButton))) expect(button.onPressed, isNull);
        expect(picked, isNull);
      });
    }
  }
  testWidgets('missing capabilities expose no operation', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlareTransferProgress(name: 'file', state: FlareTransferState.failed, statusText: 'failed', onAction: (_) {}))));
    expect(find.byType(TextButton), findsNothing);
  });
  testWidgets('status banner respects reduced motion and long action labels', (tester) async {
    tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: TextScaler.linear(2)), child: child!),
      home: Scaffold(body: FlareStatusBanner(text: '网络连接中断，正在尝试重新连接', pulse: true, actionText: '检查网络设置', onAction: () => tapped = true))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final button = find.byType(TextButton);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button); expect(tapped, isTrue);
  });
}
