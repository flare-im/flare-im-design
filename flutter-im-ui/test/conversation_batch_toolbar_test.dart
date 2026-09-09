import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_conversation_batch_toolbar.dart';

void main() {
  const caps = FlareConversationBatchCapabilities(markRead: true, mute: true, delete: true);

  group('batchActionsAvailable', () {
    test('canonical order, capability filtered', () {
      expect(batchActionsAvailable(['a', 'b'], caps, false),
          [FlareConversationBatchAction.markRead, FlareConversationBatchAction.mute, FlareConversationBatchAction.delete]);
      expect(batchActionsAvailable(['a'], const FlareConversationBatchCapabilities(delete: true, archive: true), false),
          [FlareConversationBatchAction.archive, FlareConversationBatchAction.delete]);
    });
    test('empty when nothing selected, busy, no capabilities or over the limit', () {
      expect(batchActionsAvailable([], caps, false), isEmpty);
      expect(batchActionsAvailable(['a'], caps, true), isEmpty);
      expect(batchActionsAvailable(['a'], const FlareConversationBatchCapabilities(), false), isEmpty);
      expect(batchActionsAvailable(['a'], null, false), isEmpty);
      expect(batchActionsAvailable(['a', 'b', 'c'], caps, false, 2), isEmpty);
      expect(batchActionsAvailable(['a', 'b'], caps, false, 2), hasLength(3));
      expect(batchActionsAvailable(['a', 'b', 'c'], caps, false, 0), hasLength(3));
    });
  });

  group('summarizeBatchResult', () {
    test('counts both outcomes and deduplicates retry ids', () {
      const result = FlareConversationBatchResult(succeeded: ['a', 'b'], failed: [
        FlareConversationBatchFailure(id: 'd', title: '设计群', reason: '无权限'),
        FlareConversationBatchFailure(id: 'd', title: '设计群', reason: '再次失败'),
        FlareConversationBatchFailure(id: '', title: '未知', reason: '无 ID'),
        FlareConversationBatchFailure(id: 'e', title: '客服', reason: '网络中断'),
      ]);
      final s = summarizeBatchResult(result);
      expect(s.succeededCount, 2);
      expect(s.failedCount, 4);
      expect(s.retryIds, ['d', 'e']);
    });
    test('zeros for null', () {
      final s = summarizeBatchResult(null);
      expect(s.succeededCount, 0);
      expect(s.failedCount, 0);
      expect(s.retryIds, isEmpty);
    });
  });

  testWidgets('empty selection disables actions and shows the empty hint', (tester) async {
    final actions = <FlareConversationBatchAction>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FlareConversationBatchToolbar(
                selectedIds: const [], capabilities: caps, onAction: (a, _) => actions.add(a), onClearSelection: () {}))));
    expect(find.text('请选择会话'), findsOneWidget);
    await tester.tap(find.text('标为已读'));
    await tester.pump();
    expect(actions, isEmpty);
  });

  testWidgets('320 wide: actions wrap, delete emits ids, partial failure expands and retries', (tester) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final emitted = <(FlareConversationBatchAction, List<String>)>[];
    final retries = <List<String>>[];
    var dismissed = 0;
    const result = FlareConversationBatchResult(succeeded: ['a', 'b'], failed: [
      FlareConversationBatchFailure(id: 'c', title: '设计评审群', reason: '无权限'),
      FlareConversationBatchFailure(id: 'd', title: '客服', reason: '网络中断'),
    ]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FlareConversationBatchToolbar(
      selectedIds: const ['a', 'b', 'c', 'd'],
      capabilities: caps,
      result: result,
      onAction: (a, ids) => emitted.add((a, ids)),
      onRetryFailed: retries.add,
      onClearSelection: () {},
      onDismissResult: () => dismissed++,
    ))));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('删除'));
    await tester.pump();
    expect(emitted.single.$1, FlareConversationBatchAction.delete);
    expect(emitted.single.$2, ['a', 'b', 'c', 'd']);
    expect(find.textContaining('2 项失败'), findsOneWidget);
    expect(find.textContaining('成功 2 项'), findsOneWidget);
    expect(find.text('无权限'), findsNothing);
    await tester.tap(find.text('查看详情'));
    await tester.pump();
    expect(find.text('无权限'), findsOneWidget);
    expect(find.text('客服'), findsOneWidget);
    await tester.tap(find.text('重试失败项 (2)'));
    await tester.pump();
    expect(retries, [
      ['c', 'd']
    ]);
    await tester.tap(find.bySemanticsLabel('关闭结果'));
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets('busy disables everything and over-limit shows the limit hint', (tester) async {
    final emitted = <FlareConversationBatchAction>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FlareConversationBatchToolbar(
                selectedIds: const ['a'], capabilities: caps, busy: true, onAction: (a, _) => emitted.add(a), onClearSelection: () {}))));
    expect(find.text('处理中'), findsOneWidget);
    await tester.tap(find.text('免打扰'));
    await tester.pump();
    expect(emitted, isEmpty);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FlareConversationBatchToolbar(
                selectedIds: const ['a', 'b', 'c'], capabilities: caps, maxSelection: 2, onAction: (a, _) => emitted.add(a)))));
    expect(find.text('最多可选 2 项'), findsOneWidget);
    await tester.tap(find.text('免打扰'));
    await tester.pump();
    expect(emitted, isEmpty);
  });
}
