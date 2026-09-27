import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// On a phone the header is the chat page's Scaffold app bar, and nothing else
/// pads the top: it must keep its controls below the status bar / notch itself.
void main() {
  testWidgets('as an app bar it keeps its controls below the top safe area', (
    tester,
  ) async {
    const topInset = 47.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(402, 874),
            padding: EdgeInsets.only(top: topInset, bottom: 34),
          ),
          child: Scaffold(
            appBar: FlareConversationHeader(
              identity: const FlareConversationIdentity(id: 'u1', title: '验证甲'),
              showBack: true,
              onBack: () {},
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );

    final back = tester.getRect(find.byType(IconButton).first);
    expect(back.top, greaterThanOrEqualTo(topInset));
    final title = tester.getRect(find.text('验证甲'));
    expect(title.top, greaterThanOrEqualTo(topInset));
    // The bar's surface still reaches the top edge (no gap above it).
    final bar = tester.getRect(find.byType(FlareConversationHeader));
    expect(bar.top, 0);
    expect(bar.height, topInset + FlareSizes.headerHeight);
  });

  testWidgets(
    'without a top inset (desktop pane) it is exactly the bar height',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const FlareConversationHeader(
              identity: FlareConversationIdentity(id: 'g1', title: '手工测试群'),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(FlareConversationHeader));
      expect(bar.height, FlareSizes.headerHeight);
    },
  );
}
