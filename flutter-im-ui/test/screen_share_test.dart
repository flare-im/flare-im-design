import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_screen_share.dart';
import 'package:flare_im_ui/src/components/flare_status_banner.dart';

void main() {
  List<FlareScreenShareAction> shown(
    FlareScreenShareState state, {
    bool busy = false,
    bool all = true,
  }) {
    final a = screenShareActions(state,
        hasStart: all, hasStop: all, hasCancel: all, busy: busy);
    return FlareScreenShareAction.values.where(a.contains).toList();
  }

  const visible = <FlareScreenShareState, List<FlareScreenShareAction>>{
    FlareScreenShareState.idle: [FlareScreenShareAction.start],
    FlareScreenShareState.requesting: [FlareScreenShareAction.cancel],
    FlareScreenShareState.sharing: [FlareScreenShareAction.stop],
    FlareScreenShareState.viewing: [],
    FlareScreenShareState.unavailable: [],
  };

  test('every state exposes only state-appropriate actions', () {
    for (final state in FlareScreenShareState.values) {
      expect(shown(state), visible[state], reason: '$state');
    }
  });

  test('busy keeps buttons visible but disabled', () {
    for (final state in FlareScreenShareState.values) {
      expect(shown(state, busy: true), visible[state], reason: '$state busy');
      expect(
        screenShareActions(state,
                hasStart: true, hasStop: true, hasCancel: true, busy: true)
            .enabled,
        isFalse,
        reason: '$state busy',
      );
      expect(
        screenShareActions(state,
                hasStart: true, hasStop: true, hasCancel: true)
            .enabled,
        isTrue,
        reason: '$state idle-busy default',
      );
    }
  });

  test('missing host callbacks hide every action', () {
    for (final state in FlareScreenShareState.values) {
      expect(shown(state, all: false), isEmpty, reason: '$state no callbacks');
    }
  });

  test('a viewer can never stop, and an unavailable runtime offers nothing', () {
    final viewing = screenShareActions(FlareScreenShareState.viewing,
        hasStart: true, hasStop: true, hasCancel: true);
    expect(viewing.stop, isFalse);
    expect(viewing.start, isFalse);
    expect(
        screenShareActions(FlareScreenShareState.unavailable,
                hasStart: true, hasStop: true, hasCancel: true)
            .isEmpty,
        isTrue);
  });

  test('tone and icon per state', () {
    expect(screenShareTone(FlareScreenShareState.idle), FlareStatusTone.neutral);
    expect(screenShareTone(FlareScreenShareState.requesting),
        FlareStatusTone.warning);
    expect(
        screenShareTone(FlareScreenShareState.sharing), FlareStatusTone.success);
    expect(screenShareTone(FlareScreenShareState.viewing), FlareStatusTone.info);
    expect(screenShareTone(FlareScreenShareState.unavailable),
        FlareStatusTone.neutral);
    expect(
      FlareScreenShareState.values.map(screenShareIconName).toList(),
      ['devices', 'refresh', 'video', 'eye', 'block'],
    );
  });

  Widget host(FlareScreenShare child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  testWidgets('idle starts, sharing stops, busy blocks both', (tester) async {
    var starts = 0, stops = 0;
    await tester.pumpWidget(host(FlareScreenShare(
      state: FlareScreenShareState.idle,
      onStart: () => starts++,
      onStop: () => stops++,
      onCancel: () {},
    )));
    expect(find.text('未在共享'), findsOneWidget);
    expect(find.text('停止共享'), findsNothing);
    expect(find.text('取消请求'), findsNothing);
    await tester.tap(find.text('共享屏幕'));
    expect(starts, 1);

    await tester.pumpWidget(host(FlareScreenShare(
      state: FlareScreenShareState.sharing,
      sourceLabel: '整个屏幕',
      onStart: () => starts++,
      onStop: () => stops++,
    )));
    expect(find.text('正在共享屏幕'), findsOneWidget);
    expect(find.text('共享内容'), findsOneWidget);
    expect(find.text('整个屏幕'), findsOneWidget);
    expect(find.text('共享屏幕'), findsNothing);
    await tester.tap(find.text('停止共享'));
    expect(stops, 1);

    await tester.pumpWidget(host(FlareScreenShare(
      state: FlareScreenShareState.sharing,
      busy: true,
      onStop: () => stops++,
    )));
    expect(find.text('停止共享'), findsOneWidget);
    await tester.tap(find.text('停止共享'), warnIfMissed: false);
    expect(stops, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requesting shows progress and cancel; viewing and unavailable have no action',
      (tester) async {
    var cancels = 0;
    await tester.pumpWidget(host(FlareScreenShare(
      state: FlareScreenShareState.requesting,
      onStart: () {},
      onStop: () {},
      onCancel: () => cancels++,
    )));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('取消请求'));
    expect(cancels, 1);

    await tester.pumpWidget(host(FlareScreenShare(
      state: FlareScreenShareState.viewing,
      presenterName: '林可',
      detail: '上行带宽受限，画面已降帧',
      onStart: () {},
      onStop: () {},
      onCancel: () {},
    )));
    expect(find.text('正在观看共享'), findsOneWidget);
    expect(find.text('共享者'), findsOneWidget);
    expect(find.text('林可'), findsOneWidget);
    expect(find.text('上行带宽受限，画面已降帧'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);

    await tester.pumpWidget(host(FlareScreenShare(
      state: FlareScreenShareState.unavailable,
      detail: '当前浏览器不支持屏幕采集',
      onStart: () {},
      onStop: () {},
      onCancel: () {},
    )));
    expect(find.text('当前环境不支持屏幕共享'), findsOneWidget);
    expect(find.text('当前浏览器不支持屏幕采集'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
