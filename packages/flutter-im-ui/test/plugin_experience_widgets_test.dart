import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The new kit pieces of docs/plugin-experience.md: FlareResultView,
/// FlareDocumentSlot, the status card, the references fold, a disabled
/// reason, the compact empty state, the dismissible banner and the shaped
/// skeletons.
const zh = FlareStrings();

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

FlarePluginViewModel view(Map<String, Object?> json) =>
    FlarePluginViewModel.fromJson({'available': true, 'title': '', ...json});

void main() {
  testWidgets('result view: tone icon, title, amount, details, done', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      host(
        FlareResultView(
          title: '转账成功',
          tone: FlarePluginTone.success,
          amount: '¥99.00',
          description: '已转入对方钱包',
          details: const [FlarePluginField(label: '收款方', value: '周屿')],
          onDone: () => done++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('转账成功'), findsOneWidget);
    expect(find.text('¥99.00'), findsOneWidget);
    expect(find.text('周屿'), findsOneWidget);
    expect(find.text(zh.pluginViewDone), findsOneWidget);
    final icon = tester.widget<FlareIcon>(
      find.descendant(
        of: find.byType(FlarePluginToneIcon),
        matching: find.byType(FlareIcon),
      ),
    );
    expect(icon.name, 'success');
    await tester.tap(find.byKey(FlareResultView.doneKey));
    expect(done, 1);
  });

  testWidgets('document slot: empty captures, failed retries, one button', (
    tester,
  ) async {
    final calls = <String>[];
    Widget slot(FlareDocumentSlotState state) => host(
      SizedBox(
        width: 200,
        child: FlareDocumentSlot(
          label: '证件正面',
          side: FlarePluginDocumentSide.front,
          state: state,
          progress: 40,
          onCapture: () => calls.add('capture'),
          onRetry: () => calls.add('retry'),
        ),
      ),
    );
    await tester.pumpWidget(slot(FlareDocumentSlotState.empty));
    expect(find.text(zh.documentSlotTapToCapture), findsOneWidget);
    // 16:10, never under component.documentSlotHeight.
    final size = tester.getSize(
      find.byKey(const ValueKey('flare-document-slot-tap')),
    );
    expect(
      size.height,
      greaterThanOrEqualTo(FlareSizes.componentDocumentSlotHeight),
    );
    await tester.tap(find.byType(FlareDocumentSlot));
    await tester.pumpWidget(slot(FlareDocumentSlotState.failed));
    expect(find.text(zh.documentSlotUploadFailed), findsOneWidget);
    await tester.tap(find.byType(FlareDocumentSlot));
    expect(calls, ['capture', 'retry']);
    await tester.pumpWidget(slot(FlareDocumentSlotState.uploading));
    expect(find.text('40%'), findsOneWidget);
    await tester.pumpWidget(slot(FlareDocumentSlotState.captured));
    expect(find.text(zh.documentCaptureRetake), findsOneWidget);
  });

  testWidgets('a steps-first view with a toned field draws the status card '
      'once', (tester) async {
    await tester.pumpWidget(
      host(
        FlarePluginView(
          embedded: true,
          actionLayout: FlarePluginActionLayout.roles,
          onAction: (_, _) {},
          view: view({
            'fields': [
              {'label': '状态', 'value': '未实名认证', 'tone': 'neutral'},
            ],
            'blocks': [
              {
                'kind': 'steps',
                'items': [
                  {'label': '填写资料', 'state': 'current'},
                  {'label': '核对资料', 'state': 'pending'},
                ],
              },
              {'kind': 'note', 'text': '完成认证后可使用钱包与红包'},
            ],
            'actions': [
              {
                'id': 'apply',
                'label': '开始认证',
                'style': 'primary',
                'target': {'kind': 'page', 'page': 'apply'},
              },
            ],
          }),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-status-card')),
      findsOneWidget,
    );
    expect(find.text('未实名认证'), findsOneWidget);
    expect(find.text('完成认证后可使用钱包与红包'), findsOneWidget);
    expect(find.text('开始认证'), findsOneWidget);
  });

  testWidgets('reference fields fold under References with copy keys', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await tester.pumpWidget(
      host(
        FlarePluginView(
          embedded: true,
          view: view({
            'fields': [
              {'label': '金额', 'value': '¥99.00'},
              {
                'label': '资金单',
                'value': 'fo_123',
                'format': {'kind': 'reference', 'id': 'fo_123'},
              },
            ],
          }),
        ),
      ),
    );
    expect(find.text('fo_123'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('flare-plugin-references-toggle')),
    );
    await tester.pump();
    expect(find.text('fo_123'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flare-plugin-copy-资金单')));
    expect(copied, ['fo_123']);
  });

  testWidgets('a disabled reason disables the key and is written under it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlarePluginView(
          embedded: true,
          actionLayout: FlarePluginActionLayout.roles,
          onAction: (_, _) {},
          view: view({
            'fields': [
              {'label': '扣款', 'value': '¥1.00'},
            ],
            'actions': [
              {
                'id': 'pay',
                'label': '确认并支付',
                'style': 'primary',
                'disabledReason': '余额不足',
                'target': {'kind': 'operation', 'operation': 'pay'},
              },
            ],
          }),
        ),
      ),
    );
    expect(
      tester
          .widget<FlareButton>(
            find.byKey(const ValueKey('flare-plugin-action-pay')),
          )
          .disabled,
      isTrue,
    );
    expect(find.text('余额不足'), findsOneWidget);
  });

  testWidgets('compact empty state, dismissible banner, shaped skeletons', (
    tester,
  ) async {
    var dismissed = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            const FlareEmptyState(title: '暂无记录', icon: 'clock', compact: true),
            FlareStatusBanner(
              text: '余额不足',
              tone: FlareStatusTone.danger,
              dismissible: true,
              onDismiss: () => dismissed++,
            ),
            for (final variant in [
              FlareSkeletonVariant.card,
              FlareSkeletonVariant.list,
              FlareSkeletonVariant.form,
            ])
              FlareSkeleton(variant: variant, rows: 2, still: true),
          ],
        ),
      ),
    );
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(FlareEmptyState),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.size, 32);
    await tester.tap(find.byKey(const ValueKey('flare-status-banner-dismiss')));
    expect(dismissed, 1);
  });
}
