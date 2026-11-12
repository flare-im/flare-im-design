import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The visual gate of the plugin vocabulary 2 blocks and the upgrade notice
/// (docs/plugin-components.md; the web kit's page is
/// website/resources/plugin-blocks-regression.md). Each platform keeps its own
/// baseline, as core_components_golden_test.dart explains.
String _golden(String name) => 'baselines/${Platform.operatingSystem}/$name';

final int _at = DateTime.utc(2025, 1, 14, 6).millisecondsSinceEpoch;

Map<String, Object?> _op(String id, String label, [String? style]) => {
  'id': id,
  'label': label,
  if (style != null) 'style': style,
};

FlarePluginViewModel get _blocks => FlarePluginViewModel.fromJson({
  'available': true,
  'title': '本周看板',
  'blocks': [
    {
      'kind': 'hero',
      'label': '可用余额',
      'value': '¥128.60',
      'amount': true,
      'subtitle': '托管中 ¥6.00',
      'tone': 'brand',
      'actions': [_op('recharge', '充值', 'primary'), _op('withdraw', '提现')],
    },
    {
      'kind': 'stats',
      'items': [
        {
          'label': '进行中',
          'value': '12',
          'trend': {'text': '+3', 'direction': 'up'},
        },
        {
          'label': '成员',
          'value': '12345',
          'format': {'kind': 'count', 'count': 12345},
          'tone': 'success',
        },
        {
          'label': '用时',
          'value': '7500000 ms',
          'format': {'kind': 'duration', 'ms': 7500000},
        },
      ],
    },
    {
      'kind': 'banner',
      'tone': 'warning',
      'text': '为保障资金安全，请先完成实名认证。',
      'action': _op('verify', '去认证'),
    },
    {
      'kind': 'section',
      'label': '趋势',
      'blocks': [
        {
          'kind': 'chart',
          'chartKind': 'bar',
          'series': [
            {
              'label': '完成',
              'points': [
                for (final (i, v) in [3, 5, 2, 8, 6].indexed)
                  {'label': 'D${i + 1}', 'value': v, 'text': '$v'},
              ],
            },
            {
              'label': '新增',
              'points': [
                for (final (i, v) in [4, 2, 6, 3, 5].indexed)
                  {'label': 'D${i + 1}', 'value': v, 'text': '$v'},
              ],
            },
          ],
        },
        {
          'kind': 'chart',
          'chartKind': 'donut',
          'series': [
            {
              'points': [
                {'label': 'Ivy', 'value': 12, 'text': '12'},
                {'label': '周屿', 'value': 9, 'text': '9'},
                {'label': 'Leo', 'value': 7, 'text': '7'},
              ],
            },
          ],
        },
      ],
    },
    {
      'kind': 'steps',
      'items': [
        {'label': '提交资料', 'state': 'done'},
        {'label': '人工审核', 'state': 'current'},
        {'label': '补充材料', 'state': 'failed'},
        {'label': '完成', 'state': 'pending'},
      ],
    },
    {'kind': 'image', 'asset': 'cover.png', 'aspect': '16:9', 'alt': '封面'},
    {
      'kind': 'timeline',
      'items': [
        {
          'atMs': _at,
          'title': '收到红包 +¥2.30',
          'detail': 'Ivy Chen',
          'status': {'text': '已入账', 'tone': 'success'},
        },
        {'atMs': _at - 86400000, 'title': '发出红包 -¥10.00'},
      ],
    },
  ],
});

final _placeholder = FlarePluginViewModel.fromJson({
  'available': false,
  'unavailableReason': 'upgrade_required',
  'minBuild': 41020,
  'title': '任务看板',
});

void main() {
  testWidgets('plugin vocabulary 2 blocks remain visually stable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    flarePluginNowMs = () => _at + 3600000;
    addTearDown(() => flarePluginNowMs = FlareServerClock.nowMs);
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlarePluginView(view: _blocks, onAction: (_, _) {}),
                  const SizedBox(height: 16),
                  FlarePluginView(
                    view: _placeholder,
                    upgradeStatus: const FlarePluginUpgradeStatus(
                      available: true,
                      build: 41020,
                    ),
                    onUpdate: () {},
                  ),
                  const SizedBox(height: 16),
                  FlarePluginView(
                    view: _placeholder,
                    upgradeStatus: const FlarePluginUpgradeStatus(
                      available: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FlarePluginUpgradeNotice(
                    variant: FlarePluginUpgradeVariant.entry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile(_golden('plugin_blocks.png')),
    );
  });
}
