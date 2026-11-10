import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallet_composition_test.dart' as review;

FlarePluginPageViewModel flowView({
  String? tone = 'warning',
  String formTitle = '填写申请信息',
  bool confirm = false,
  bool hiddenSubmit = false,
  String? unavailableDescription,
  List<Map<String, Object?>> blocks = const [],
}) => FlarePluginPageViewModel.fromJson({
  'available': true,
  'title': '资料申请',
  'fields': [
    {'label': '资产', 'value': 'CNY · 现金'},
    {'label': '可用金额', 'value': '1000.00'},
  ],
  'inputs': [
    {
      'id': 'destination',
      'kind': 'select',
      'label': '到账账户',
      'required': true,
      'choices': [
        {'value': 'opaque-account', 'label': '旅行账户 · CNY · 银行卡尾号 1234'},
      ],
    },
    {'id': 'amount', 'kind': 'text', 'label': '金额', 'required': true},
  ],
  'actions': [
    if (!hiddenSubmit)
      {
        'id': 'submit',
        'label': '提交申请',
        'style': 'primary',
        'form': ['destination', 'amount'],
        if (confirm) 'confirm': '核对后继续',
      },
  ],
  'blocks': blocks,
  'presentation': {
    'renderer': 'account',
    'props': {
      'layout': 'flow',
      'stepLabel': '第一步 · 填写资料',
      'description': '核对账户信息后提交申请。',
      'sectionTitle': '账户信息',
      'formTitle': formTitle,
      'formDescription': '请选择原有账户并填写准确金额。',
      if (unavailableDescription != null)
        'formUnavailableDescription': unavailableDescription,
      if (tone != null) ...{
        'resultTitle': '等待确认',
        'resultDescription': '处理结果尚未确认，请查看原申请记录。',
        'resultTone': tone,
      },
    },
    'actions': {'submit': 'submit'},
  },
});

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('flow form hierarchy fits $width', (tester) async {
      review.surface(tester, width);
      await review.fonts(tester);
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        review.host(
          RepaintBoundary(
            key: captureKey,
            child: review.page(flowView(), onAction: (_, _) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('填写申请信息'), findsOneWidget);
      expect(find.text('请选择原有账户并填写准确金额。'), findsOneWidget);
      final region = find.byKey(
        const ValueKey('flare-plugin-inline-form-region'),
      );
      expect(
        tester.getSize(region).width,
        lessThanOrEqualTo(FlareSizes.primaryPaneMaxWidth),
      );
      if (width > FlareSizes.directoryContentMaxWidth) {
        expect(
          tester
              .getSize(find.byKey(const ValueKey('flare-account-receipt')))
              .width,
          greaterThan(FlareSizes.primaryPaneMaxWidth),
        );
      }
      final form = find.byType(FlarePluginForm);
      expect(
        tester.getTopLeft(find.text('填写申请信息')).dy,
        lessThan(tester.getTopLeft(form).dy),
      );
      expect(
        find.byKey(const ValueKey('flare-plugin-form-submit')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await review.capture(
        tester,
        captureKey,
        'flutter-flow-presentation-${width.toInt()}',
      );
    });
  }

  testWidgets('result words and tone come only from declared presentation', (
    tester,
  ) async {
    for (final tone in FlareStatusTone.values) {
      await tester.pumpWidget(
        review.host(
          review.page(flowView(tone: tone.name), onAction: (_, _) {}),
        ),
      );
      final result = tester.widget<FlareStatusBanner>(
        find.byKey(const ValueKey('flare-account-result')),
      );
      expect(result.tone, tone);
      expect(result.text, contains('等待确认'));
      expect(result.text, contains('处理结果尚未确认'));
    }
    await tester.pumpWidget(
      review.host(review.page(flowView(tone: null), onAction: (_, _) {})),
    );
    expect(find.byKey(const ValueKey('flare-account-result')), findsNothing);
    await tester.pumpWidget(
      review.host(
        review.page(flowView(tone: 'unrecognized'), onAction: (_, _) {}),
      ),
    );
    expect(
      tester
          .widget<FlareStatusBanner>(
            find.byKey(const ValueKey('flare-account-result')),
          )
          .tone,
      FlareStatusTone.neutral,
    );
  });

  testWidgets('inline headings preserve draft, exact values and input order', (
    tester,
  ) async {
    review.surface(tester, 1440);
    String? tone;
    var heading = '填写申请信息';
    late StateSetter rebuild;
    final calls = <FlarePluginPageActionPayload>[];
    await tester.pumpWidget(
      review.host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return review.page(
              flowView(tone: tone, formTitle: heading),
              onAction: (_, payload) => calls.add(payload),
            );
          },
        ),
      ),
    );
    final form = tester.widget<FlarePluginForm>(find.byType(FlarePluginForm));
    expect(form.inputs.map((input) => input.id), ['destination', 'amount']);
    await tester.tap(find.text('旅行账户 · CNY · 银行卡尾号 1234'));
    final amount = find.descendant(
      of: find.byKey(const ValueKey('flare-plugin-input-amount')),
      matching: find.byType(TextField),
    );
    const exact = '10000000000000000000.00000001';
    await tester.enterText(amount, exact);
    rebuild(() {
      tone = 'info';
      heading = '继续填写申请信息';
    });
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(amount).controller!.text, exact);
    expect(find.text('继续填写申请信息'), findsOneWidget);
    final submit = find.byKey(const ValueKey('flare-plugin-form-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(calls.single.formValues, {
      'destination': 'opaque-account',
      'amount': exact,
    });
    expect(
      tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
      isTrue,
    );
  });

  testWidgets(
    'inline headings do not bypass missing-handler or confirm guards',
    (tester) async {
      final calls = <FlarePluginPageActionPayload>[];
      await tester.pumpWidget(review.host(review.page(flowView())));
      expect(find.text('填写申请信息'), findsNothing);
      expect(find.byType(FlarePluginForm), findsNothing);
      await tester.pumpWidget(
        review.host(
          review.page(
            flowView(confirm: true),
            onAction: (_, payload) => calls.add(payload),
          ),
        ),
      );
      expect(find.text('填写申请信息'), findsNothing);
      expect(find.byType(FlarePluginForm), findsNothing);
      expect(
        find.byKey(const ValueKey('flare-plugin-action-submit')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-action-submit')),
      );
      await tester.pumpAndSettle();
      expect(find.text('核对后继续'), findsOneWidget);
      expect(find.byType(FlarePluginForm), findsNothing);
      expect(calls, isEmpty);
      await tester.tap(find.widgetWithText(FlareButton, '取消').last);
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-action-submit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FlareButton, '提交申请').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).embedded,
        isFalse,
      );
      expect(calls, isEmpty);
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-cancel')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('undeclared inline form copy retains the original full width', (
    tester,
  ) async {
    review.surface(tester, 1440);
    String? title;
    String? description;
    late StateSetter rebuild;
    await tester.pumpWidget(
      review.host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return FlarePluginView(
              view: review.formView(),
              embedded: true,
              inlineFormActionId: 'submit',
              inlineFormTitle: title,
              inlineFormDescription: description,
              onAction: (_, _) {},
            );
          },
        ),
      ),
    );
    final form = find.byType(FlarePluginForm);
    expect(tester.getSize(form).width, 1440);
    final field = find.descendant(
      of: find.byKey(const ValueKey('flare-plugin-input-second')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'retained draft');
    rebuild(() {
      title = '  ';
      description = '\n ';
    });
    await tester.pumpAndSettle();
    expect(tester.getSize(form).width, 1440);
    expect(find.text('  '), findsNothing);
    expect(find.text('\n '), findsNothing);
    rebuild(() => title = 'New form title');
    await tester.pumpAndSettle();
    expect(tester.getSize(form).width, FlareSizes.primaryPaneMaxWidth);
    expect(tester.widget<TextField>(field).controller!.text, 'retained draft');
    expect(tester.getTopLeft(form).dx, 0);
  });

  testWidgets(
    'a declared form without authorized actions has a neutral explanation',
    (tester) async {
      await tester.pumpWidget(
        review.host(
          review.page(
            flowView(
              tone: null,
              hiddenSubmit: true,
              unavailableDescription: '当前暂时无法提交，请稍后查看。',
            ),
            onAction: (_, _) {},
          ),
        ),
      );
      final banner = tester.widget<FlareStatusBanner>(
        find.byKey(const ValueKey('flare-account-result')),
      );
      expect(banner.text, '当前暂时无法提交，请稍后查看。');
      expect(banner.tone, FlareStatusTone.neutral);
      expect(find.byType(FlarePluginForm), findsNothing);
      expect(
        find.byKey(const ValueKey('flare-plugin-action-submit')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'visible blocking statuses explain unavailable forms without duplicate copy',
    (tester) async {
      for (final tone in ['warning', 'danger']) {
        await tester.pumpWidget(
          review.host(
            review.page(
              flowView(
                tone: null,
                hiddenSubmit: true,
                unavailableDescription: '通用暂不可提交说明',
                blocks: [
                  {
                    'kind': 'status',
                    'label': '提交状态',
                    'text': '已声明的不可用原因',
                    'tone': tone,
                  },
                ],
              ),
              onAction: (_, _) {},
            ),
          ),
        );
        expect(find.text('已声明的不可用原因'), findsOneWidget);
        expect(find.text('通用暂不可提交说明'), findsNothing);
        expect(
          find.byKey(const ValueKey('flare-account-result')),
          findsNothing,
        );
        expect(find.byType(FlarePluginForm), findsNothing);
      }
    },
  );

  testWidgets(
    'ordinary statuses, blank blocking statuses and notes keep fallback copy',
    (tester) async {
      for (final block in <Map<String, Object?>>[
        for (final tone in ['info', 'neutral', 'success'])
          {'kind': 'status', 'text': '普通账户状态', 'tone': tone},
        {
          'kind': 'status',
          'label': '状态标签不是原因',
          'text': '  \n ',
          'tone': 'warning',
        },
        {'kind': 'note', 'text': '普通提示', 'tone': 'warning'},
      ]) {
        await tester.pumpWidget(
          review.host(
            review.page(
              flowView(
                tone: null,
                hiddenSubmit: true,
                unavailableDescription: '通用暂不可提交说明',
                blocks: [block],
              ),
              onAction: (_, _) {},
            ),
          ),
        );
        final banner = tester.widget<FlareStatusBanner>(
          find.byKey(const ValueKey('flare-account-result')),
        );
        expect(banner.text, '通用暂不可提交说明', reason: '$block');
        expect(banner.tone, FlareStatusTone.neutral, reason: '$block');
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'explicit results and guarded actions take precedence over fallback copy',
    (tester) async {
      for (final view in [
        flowView(
          hiddenSubmit: true,
          unavailableDescription: 'Do not infer a result',
        ),
        flowView(
          tone: null,
          confirm: true,
          unavailableDescription: 'Do not infer a result',
        ),
        flowView(
          tone: null,
          hiddenSubmit: true,
          formTitle: '  ',
          unavailableDescription: 'Do not infer a result',
        ),
      ]) {
        await tester.pumpWidget(
          review.host(review.page(view, onAction: (_, _) {})),
        );
        expect(find.text('Do not infer a result'), findsNothing);
      }
    },
  );

  testWidgets('long single-select names wrap at narrow enlarged text', (
    tester,
  ) async {
    review.surface(tester, 320);
    const label = '旅行账户 · 跨境银行非常长的中文账户名称 · CNY · 银行卡尾号 1234';
    await tester.pumpWidget(
      review.host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FlareRadioGroup(
              options: const [
                FlareSelectOption(value: 'account', label: label),
              ],
              value: '',
              vertical: true,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text(label), findsOneWidget);
    expect(tester.getSize(find.text(label)).height, greaterThan(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-select keyboard and disabled semantics follow handler', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final selected = <String>[];
    Widget radio({bool enabled = true}) => review.host(
      FlareRadioGroup(
        options: const [FlareSelectOption(value: 'opaque', label: '原账户')],
        value: '',
        onSelect: enabled ? selected.add : null,
      ),
    );
    await tester.pumpWidget(radio());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(selected, ['opaque', 'opaque']);
    await tester.pumpWidget(radio(enabled: false));
    expect(
      tester
          .getSemantics(find.text('原账户'))
          .flagsCollection
          .isEnabled
          .toBoolOrNull(),
      isFalse,
    );
    await tester.tap(find.text('原账户'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, ['opaque', 'opaque']);
    semantics.dispose();
  });
}
