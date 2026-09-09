import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_conversation_workspace.dart';
import 'package:flare_im_ui/src/components/flare_responsive_layout.dart';
import 'package:flare_im_ui/src/components/flare_skeleton.dart';
import 'package:flare_im_ui/src/components/flare_status_banner.dart';

void main() {
  group('paneRender', () {
    test('maps every declared status', () {
      expect(
        FlareWorkspacePaneStatus.values
            .map((s) => paneRender(FlareWorkspacePaneState(status: s)))
            .toList(),
        [
          FlareWorkspacePaneRender.content,
          FlareWorkspacePaneRender.skeleton,
          FlareWorkspacePaneRender.empty,
          FlareWorkspacePaneRender.failure,
        ],
      );
    });

    test('degrades a missing state / default status to the host content', () {
      expect(paneRender(null), FlareWorkspacePaneRender.content);
      expect(paneRender(const FlareWorkspacePaneState()),
          FlareWorkspacePaneRender.content);
      expect(paneRender(const FlareWorkspacePaneState(message: '只有文案')),
          FlareWorkspacePaneRender.content);
    });

    test('loading never resolves to empty', () {
      expect(
        paneRender(const FlareWorkspacePaneState(
            status: FlareWorkspacePaneStatus.loading)),
        isNot(FlareWorkspacePaneRender.empty),
      );
    });
  });

  group('paneRetryVisible', () {
    test('needs failure + non-blank label + host handler, all three', () {
      for (final status in FlareWorkspacePaneStatus.values) {
        for (final label in <String?>[null, '', '   ', '重试']) {
          for (final hasRetry in [false, true]) {
            final expected = status == FlareWorkspacePaneStatus.failure &&
                label == '重试' &&
                hasRetry;
            expect(
              paneRetryVisible(
                  FlareWorkspacePaneState(status: status, actionLabel: label),
                  hasRetry),
              expected,
              reason: 'status=$status label=$label hasRetry=$hasRetry',
            );
          }
        }
      }
    });

    test('a failure without a handler or without a label shows reason only', () {
      const failed = FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '网络中断',
          actionLabel: '重试');
      expect(paneRender(failed), FlareWorkspacePaneRender.failure);
      expect(paneRetryVisible(failed, false), isFalse);
      expect(
        paneRetryVisible(
            const FlareWorkspacePaneState(
                status: FlareWorkspacePaneStatus.failure, message: '网络中断'),
            true),
        isFalse,
      );
      expect(paneRetryVisible(null, true), isFalse);
    });
  });

  group('pane independence', () {
    test('a failing pane leaves the loaded and loading panes untouched', () {
      const list = FlareWorkspacePaneState();
      const chat = FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '消息加载失败',
          actionLabel: '重试');
      const detail =
          FlareWorkspacePaneState(status: FlareWorkspacePaneStatus.loading);
      expect(paneRender(list), FlareWorkspacePaneRender.content);
      expect(paneRender(chat), FlareWorkspacePaneRender.failure);
      expect(paneRender(detail), FlareWorkspacePaneRender.skeleton);
      expect(paneRetryVisible(list, true), isFalse);
      expect(paneRetryVisible(chat, true), isTrue);
      expect(paneRetryVisible(detail, true), isFalse);
    });
  });

  group('workspaceBannerVisible', () {
    test('hides a missing, blank or whitespace-only banner', () {
      expect(workspaceBannerVisible(null), isFalse);
      expect(workspaceBannerVisible(const FlareWorkspaceBanner(message: '')),
          isFalse);
      expect(workspaceBannerVisible(const FlareWorkspaceBanner(message: '   ')),
          isFalse);
      expect(
          workspaceBannerVisible(const FlareWorkspaceBanner(message: '\n\t ')),
          isFalse);
    });

    test('shows a banner with a real message and coexists with pane state', () {
      const banner = FlareWorkspaceBanner(
          message: '离线，显示的是缓存内容', tone: FlareWorkspaceBannerTone.warning);
      expect(workspaceBannerVisible(banner), isTrue);
      expect(paneRender(const FlareWorkspacePaneState()),
          FlareWorkspacePaneRender.content);
    });
  });

  group('workspaceBannerActionVisible', () {
    test('needs a visible banner + non-blank label + host handler', () {
      const withLabel =
          FlareWorkspaceBanner(message: '离线', actionLabel: '重连');
      expect(workspaceBannerActionVisible(withLabel, true), isTrue);
      expect(workspaceBannerActionVisible(withLabel, false), isFalse);
      expect(
          workspaceBannerActionVisible(
              const FlareWorkspaceBanner(message: '离线', actionLabel: '  '),
              true),
          isFalse);
      expect(
          workspaceBannerActionVisible(
              const FlareWorkspaceBanner(message: '离线'), true),
          isFalse);
      expect(
          workspaceBannerActionVisible(
              const FlareWorkspaceBanner(message: '  ', actionLabel: '重连'),
              true),
          isFalse);
      expect(workspaceBannerActionVisible(null, true), isFalse);
    });
  });

  test('workspaceBannerTone maps error onto danger and defaults to info', () {
    expect(
      FlareWorkspaceBannerTone.values.map(workspaceBannerTone).toList(),
      [
        FlareStatusTone.info,
        FlareStatusTone.warning,
        FlareStatusTone.danger,
        FlareStatusTone.success,
      ],
    );
    expect(workspaceBannerTone(null), FlareStatusTone.info);
  });

  test('paneSkeletonVariant gives rows / bubbles / card per pane', () {
    expect(
      FlareWorkspacePaneKey.values.map(paneSkeletonVariant).toList(),
      [
        FlareSkeletonVariant.conversation,
        FlareSkeletonVariant.message,
        FlareSkeletonVariant.profile,
      ],
    );
  });

  Widget host({
    FlareWorkspacePaneState listState = const FlareWorkspacePaneState(),
    FlareWorkspacePaneState chatState = const FlareWorkspacePaneState(),
    FlareWorkspaceBanner? banner,
    ValueChanged<FlareWorkspacePaneKey>? onRetry,
    VoidCallback? onBannerAction,
    Size size = const Size(1000, 700),
  }) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: FlareConversationWorkspace(
                list: const Text('会话列表内容'),
                chat: const Text('时间线内容'),
                listState: listState,
                chatState: chatState,
                banner: banner,
                onRetry: onRetry,
                onBannerAction: onBannerAction,
              ),
            ),
          ),
        ),
      );

  testWidgets('loading renders a skeleton, not an empty list', (tester) async {
    await tester.pumpWidget(host(
      listState: const FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.loading),
    ));
    await tester.pump();
    expect(find.text('会话列表内容'), findsNothing);
    expect(find.byType(FlareSkeleton), findsOneWidget);
    expect(find.text('正在加载会话列表'), findsNothing); // semantics label, not a Text
    final semantics = tester.getSemantics(find.byType(FlareSkeleton).first);
    expect(semantics, isNotNull);
  });

  testWidgets('failure names the reason and retries only with label + handler',
      (tester) async {
    var retried = <FlareWorkspacePaneKey>[];
    await tester.pumpWidget(host(
      chatState: const FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '消息加载失败，网络中断',
          actionLabel: '重试'),
      onRetry: retried.add,
    ));
    await tester.pump();
    expect(find.text('消息加载失败，网络中断'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, [FlareWorkspacePaneKey.chat]);

    // No handler → reason only, no button that cannot be serviced.
    await tester.pumpWidget(host(
      chatState: const FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '消息加载失败，网络中断',
          actionLabel: '重试'),
    ));
    await tester.pump();
    expect(find.text('消息加载失败，网络中断'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('a failing pane keeps the sibling pane content', (tester) async {
    await tester.pumpWidget(host(
      chatState: const FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure, message: '消息加载失败'),
    ));
    await tester.pump();
    expect(find.text('会话列表内容'), findsOneWidget);
    expect(find.text('时间线内容'), findsNothing);
    expect(find.text('消息加载失败'), findsOneWidget);
  });

  testWidgets('banner coexists with readable pane content', (tester) async {
    var actions = 0;
    await tester.pumpWidget(host(
      banner: const FlareWorkspaceBanner(
          message: '离线，显示的是缓存内容',
          tone: FlareWorkspaceBannerTone.warning,
          actionLabel: '重连'),
      onBannerAction: () => actions++,
    ));
    await tester.pump();
    expect(find.text('离线，显示的是缓存内容'), findsOneWidget);
    expect(find.text('会话列表内容'), findsOneWidget);
    await tester.tap(find.text('重连'));
    expect(actions, 1);
  });

  testWidgets('a blank banner message renders no banner strip', (tester) async {
    await tester.pumpWidget(host(
      banner: const FlareWorkspaceBanner(message: '   '),
    ));
    await tester.pump();
    expect(find.byType(FlareStatusBanner), findsNothing);
  });

  testWidgets('empty renders the message as the empty title', (tester) async {
    await tester.pumpWidget(host(
      listState: const FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.empty, message: '还没有会话'),
    ));
    await tester.pump();
    expect(find.text('还没有会话'), findsOneWidget);
    expect(find.text('会话列表内容'), findsNothing);
  });

  testWidgets('pane splitting stays with FlareResponsiveLayout',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.byType(FlareResponsiveLayout), findsOneWidget);
  });

  testWidgets('detail pane still renders its state when the host passed no detail slot',
      (tester) async {
    // The host has nothing to show yet — that is precisely when the failure
    // panel matters, so a null slot must not delete the pane.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareConversationWorkspace(
          list: const Text('list'),
          chat: const Text('chat'),
          activePane: FlarePane.detail,
          detailState: const FlareWorkspacePaneState(
              status: FlareWorkspacePaneStatus.failure, message: '详情加载失败了'),
        ),
      ),
    ));
    expect(find.text('详情加载失败了'), findsOneWidget);
  });
}
