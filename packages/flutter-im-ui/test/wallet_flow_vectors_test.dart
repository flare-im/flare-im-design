import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wallet pages as plain blocks (spec/wallet-flow-vectors.json, the
/// resolved views the wallet contract draws): every block of every sample
/// reads, the balance hero can be hidden and the transaction list groups by
/// day.
void main() {
  final cases =
      (jsonDecode(
                File(
                  '${Directory.current.path}/../../spec/wallet-flow-vectors.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['cases']
          as List;

  List<FlarePluginBlock> flat(List<FlarePluginBlock> blocks) => [
    for (final block in blocks) ...[
      block,
      if (block is FlarePluginSectionBlock) ...block.blocks,
    ],
  ];

  test('every wallet sample reads whole', () {
    for (final raw in cases) {
      final sample = (raw as Map).cast<String, Object?>();
      final view = (sample['view'] as Map).cast<String, Object?>();
      final page = FlarePluginPageViewModel.fromJson(view);
      final id = '${sample['id']}/${sample['variant']}/${sample['locale']}';
      expect(
        page.blocks.length,
        (view['blocks'] as List? ?? const []).length,
        reason: id,
      );
      for (final block in flat(page.blocks)) {
        if (block is FlarePluginHeroBlock) {
          expect(block.maskable, isTrue, reason: '$id: the balance hides');
        }
        if (block is FlarePluginRowsBlock &&
            sample['page'] == 'flare.wallet.page.history') {
          expect(block.groupByDay, isTrue, reason: '$id: grouped by day');
        }
      }
    }
  });
}
