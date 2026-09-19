import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// DoD 18 —— 四端共用的状态矩阵。Flutter 能真的把界面搭起来，所以这里连渲染一起验：
// loading 出骨架屏并对读屏播报、empty 出说明+下一步、failure 出原因+重试。
Future<void> pumpFrame(
  WidgetTester tester, {
  required FlareWorkspaceState state,
  ValueChanged<FlareWorkspacePane>? onRetry,
  ValueChanged<FlareWorkspacePane>? onEmptyAction,
  VoidCallback? onBannerAction,
}) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // No shell: the frame resolves a 1600 wide desktop from its own box.
        body: FlareWorkspaceFrame(
          state: state,
          hasDetail: true,
          onRetry: onRetry,
          onEmptyAction: onEmptyAction,
          onBannerAction: onBannerAction,
          primary: const Text('primary content'),
          content: const Text('content pane'),
          detail: const Text('detail content'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a ready frame shows the host content in all three panes', (
    tester,
  ) async {
    await pumpFrame(tester, state: const FlareWorkspaceState());
    expect(find.text('primary content'), findsOneWidget);
    expect(find.text('content pane'), findsOneWidget);
    expect(find.text('detail content'), findsOneWidget);
  });

  testWidgets('a loading pane shows a labelled skeleton, not a bare spinner', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpFrame(
      tester,
      state: const FlareWorkspaceState(
        content: FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.loading,
        ),
      ),
    );
    expect(find.text('content pane'), findsNothing);
    expect(find.byType(FlareSkeleton), findsWidgets);
    expect(find.bySemanticsLabel('正在加载'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an empty pane explains itself and offers the next step', (
    tester,
  ) async {
    var acted = 0;
    await pumpFrame(
      tester,
      state: const FlareWorkspaceState(
        content: FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.empty,
          message: '还没有设备',
          description: '在手机上登录后会出现在这里',
          actionLabel: '添加设备',
        ),
      ),
      onEmptyAction: (_) => acted++,
    );
    expect(find.text('还没有设备'), findsOneWidget);
    expect(find.text('在手机上登录后会出现在这里'), findsOneWidget);
    await tester.tap(find.text('添加设备'));
    expect(acted, 1);
  });

  testWidgets('a failure names the cause and offers a labelled retry', (
    tester,
  ) async {
    var retried = 0;
    await pumpFrame(
      tester,
      state: const FlareWorkspaceState(
        content: FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '网络不可用',
          actionLabel: '重试',
        ),
      ),
      onRetry: (_) => retried++,
    );
    expect(find.text('网络不可用'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, 1);
  });

  testWidgets('a failure without a host handler shows the reason only', (
    tester,
  ) async {
    await pumpFrame(
      tester,
      state: const FlareWorkspaceState(
        content: FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '网络不可用',
          actionLabel: '重试',
        ),
      ),
    );
    expect(find.text('网络不可用'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('the banner sits above panes that still read fine', (
    tester,
  ) async {
    var acted = 0;
    await pumpFrame(
      tester,
      state: const FlareWorkspaceState(
        banner: FlareWorkspaceBanner(
          message: '当前处于离线状态',
          tone: FlareWorkspaceBannerTone.warning,
          actionLabel: '重新连接',
        ),
      ),
      onBannerAction: () => acted++,
    );
    expect(find.text('当前处于离线状态'), findsOneWidget);
    expect(find.text('content pane'), findsOneWidget);
    await tester.tap(find.text('重新连接'));
    expect(acted, 1);
  });

  testWidgets('panes are independent: one failure never blanks the others', (
    tester,
  ) async {
    await pumpFrame(
      tester,
      state: const FlareWorkspaceState(
        primary: FlareWorkspacePaneState(
          status: FlareWorkspacePaneStatus.failure,
          message: '列表加载失败',
        ),
        detail: FlareWorkspacePaneState(status: FlareWorkspacePaneStatus.empty),
      ),
    );
    expect(find.text('列表加载失败'), findsOneWidget);
    expect(find.text('content pane'), findsOneWidget);
    expect(find.text('detail content'), findsNothing);
  });
}
