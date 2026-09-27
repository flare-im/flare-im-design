import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  testWidgets(
    'current device cannot be revoked; stale media cannot be opened',
    (tester) async {
      var ids = <String>[];
      await tester.pumpWidget(
        host(
          FlareDeviceSessions(
            items: const [
              FlareDeviceSessionEntry(
                id: 'self',
                title: '本机',
                detail: '当前会话',
                current: true,
                actions: [FlareSceneAction(id: 'revoke', label: '退出')],
              ),
              FlareDeviceSessionEntry(
                id: 'other',
                title: '其他设备',
                detail: '会话',
                actions: [FlareSceneAction(id: 'revoke', label: '退出')],
              ),
            ],
            onAction: (id, a) => ids.add(id),
          ),
        ),
      );
      expect(find.text('退出'), findsOneWidget);
      await tester.tap(find.text('退出'));
      expect(ids, ['other']);
      await tester.pumpWidget(
        host(
          FlareMediaCenter(
            items: const [
              FlareMediaEntry(
                id: 'file',
                title: '文件',
                detail: '地址过期',
                kind: FlareMediaKind.file,
                availability: FlareMediaAvailability.expired,
                actions: [
                  FlareSceneAction(id: 'open', label: '打开'),
                  FlareSceneAction(id: 'refresh', label: '更新地址'),
                ],
              ),
            ],
            onAction: (id, a) => ids.add(a),
          ),
        ),
      );
      expect(find.text('打开'), findsNothing);
      await tester.tap(find.text('更新地址'));
      expect(ids.last, 'refresh');
    },
  );
  testWidgets('permission gate hides optional UI and disables preferences', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareCapabilityBoundary(
          state: FlareCapabilityState.denied,
          text: '无权限',
          child: Text('插件内容'),
        ),
      ),
    );
    expect(find.text('插件内容'), findsNothing);
    expect(find.text('无权限'), findsOneWidget);
    await tester.pumpWidget(
      host(
        FlareNotificationPreferences(
          items: const [
            FlareNotificationPreference(
              id: 'preview',
              title: '预览',
              detail: '正文',
              value: true,
              enabled: true,
            ),
          ],
          permission: FlareCapabilityState.denied,
          permissionText: '无权限',
          onChange: (_, __) => fail('must stay disabled'),
        ),
      ),
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNull,
    );
  });
  testWidgets('small screen large text and busy confirmation remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: FlareDangerConfirm(
              title: '移除成员',
              description: '确认移除这个成员的访问权限',
              target: '很长的成员名称和具体操作对象',
              error: '操作失败，可以重试',
              busy: true,
              onConfirm: () => fail('busy'),
              onCancel: () => fail('busy'),
            ),
          ),
        ),
      ),
    );
    final buttons = tester.widgetList<FlareButton>(find.byType(FlareButton));
    expect(buttons, hasLength(2));
    for (final b in buttons) {
      expect(b.disabled, isTrue);
    }
    expect(
      tester
          .widget<FlareButton>(find.widgetWithText(FlareButton, '确定'))
          .loading,
      isTrue,
    );
    // Standing alone it carries its own heading; the error is announced.
    expect(find.text('移除成员'), findsOneWidget);
    expect(find.text('操作失败，可以重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'show confirms, runs the action busy, and keeps a failure open for retry',
    (tester) async {
      var attempts = 0;
      Future<bool>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => result = FlareDangerConfirm.show(
                  context,
                  title: '删除消息',
                  description: '只删除本机上的这条消息',
                  target: '你好',
                  confirmText: '删除',
                  action: () async {
                    attempts++;
                    if (attempts == 1) throw StateError('网络不可用');
                  },
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(find.textContaining('网络不可用'), findsOneWidget);
      expect(find.text('删除消息'), findsOneWidget);
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(find.text('删除消息'), findsNothing);
      expect(await result, isTrue);
      expect(attempts, 2);
    },
  );

  testWidgets('show resolves false on cancel without running the action', (
    tester,
  ) async {
    var ran = false;
    Future<bool>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => result = FlareDangerConfirm.show(
                context,
                title: '撤回消息',
                description: '撤回后对方将看不到这条消息',
                action: () async => ran = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(ran, isFalse);
  });

  group('FlareDangerConfirm.show on the adaptive surface', () {
    Future<BuildContext> host(WidgetTester tester, Size size) async {
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

    testWidgets('a phone gets a sheet; nothing closes it while the action '
        'runs, and it resolves true once the action succeeds', (tester) async {
      final context = await host(tester, const Size(402, 874));
      final pending = Completer<void>();
      final result = FlareDangerConfirm.show(
        context,
        title: '删除消息',
        description: '只删除本机上的这条消息',
        target: '你好',
        confirmText: '删除',
        action: () => pending.future,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(FlareDangerConfirm), findsOneWidget);
      // The surface carries the title once; the body does not repeat it.
      expect(find.text('删除消息'), findsOneWidget);
      await tester.tap(find.text('删除'));
      await tester.pump();

      await tester.drag(find.text('只删除本机上的这条消息'), const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(FlareDangerConfirm), findsOneWidget);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(FlareDangerConfirm), findsNothing);
      expect(await result, isTrue);
    });

    testWidgets('a wide window gets a Modal; dismissing it is a cancel', (
      tester,
    ) async {
      final context = await host(tester, const Size(1280, 800));
      final result = FlareDangerConfirm.show(
        context,
        title: '清空缓存',
        description: '缓存的图片与文件会被删除',
      );
      await tester.pumpAndSettle();
      expect(
        find.ancestor(
          of: find.byType(FlareDangerConfirm),
          matching: find.byType(FlareModal),
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(FlareDangerConfirm), findsNothing);
      expect(await result, isFalse);
    });

    testWidgets('confirm and cancel default to the strings table', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FlareStringsScope(
            strings: flareStringsEnglish,
            child: Scaffold(
              body: FlareDangerConfirm(
                title: 'Remove member',
                description: 'They lose access to the group.',
                target: 'Bob',
              ),
            ),
          ),
        ),
      );
      expect(find.widgetWithText(FlareButton, 'Cancel'), findsOneWidget);
      expect(
        find.widgetWithText(FlareButton, flareStringsEnglish.confirm),
        findsOneWidget,
      );
    });
  });
}
