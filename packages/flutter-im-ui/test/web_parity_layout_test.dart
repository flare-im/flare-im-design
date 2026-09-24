import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void main() {
  testWidgets('quiet inbox filters match the compact Web strip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          child: FlareFilterTabs(
            appearance: FlareFilterTabsAppearance.quiet,
            padding: EdgeInsets.zero,
            options: const [
              FlareFilterTabOption(value: 'all', label: '全部'),
              FlareFilterTabOption(value: 'unread', label: '未读', badge: 4),
              FlareFilterTabOption(value: 'mentioned', label: '@我'),
            ],
            selected: 'all',
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(FlareFilterTabs));
    expect(size.width, 320);
    expect(size.height, lessThanOrEqualTo(34));
  });

  testWidgets('a non-mobile shell uses the Web 72px conversation row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FlareShellScope(
          responsiveMode: FlareApplicationResponsiveMode.tablet,
          child: SizedBox(
            width: 320,
            child: FlareConversationRow(
              item: ConversationRowData(
                id: 'room',
                title: 'Room',
                preview: 'Latest message',
                timestampLabel: '18:49',
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(FlareConversationRow)).height,
      FlareSizes.sessionItemHeight,
    );
  });
}
