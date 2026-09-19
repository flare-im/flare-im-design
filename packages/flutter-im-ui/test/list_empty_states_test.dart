import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Round 5 Batch 2b follow-up: the conversation and contact lists say they are
// empty in the strings table's words (Vue: 暂无会话 / 暂无联系人), so a host
// that changes the language changes them too.

Widget _host(Widget child, {FlareStrings? strings}) => MaterialApp(
  home: Scaffold(
    body: strings == null
        ? child
        : FlareStringsScope(strings: strings, child: child),
  ),
);

void main() {
  testWidgets('an empty conversation list and contact list use the strings '
      'table', (tester) async {
    await tester.pumpWidget(_host(const FlareConversationList(items: [])));
    expect(find.text('暂无会话'), findsOneWidget);

    await tester.pumpWidget(_host(const FlareContactList(items: [])));
    expect(find.text('暂无联系人'), findsOneWidget);
  });

  testWidgets('a host override changes the empty text', (tester) async {
    final english = const FlareStrings().copyWith(
      noConversations: 'No conversations',
      noContacts: 'No contacts yet',
    );
    await tester.pumpWidget(
      _host(const FlareConversationList(items: []), strings: english),
    );
    expect(find.text('No conversations'), findsOneWidget);

    await tester.pumpWidget(
      _host(const FlareContactList(items: []), strings: english),
    );
    expect(find.text('No contacts yet'), findsOneWidget);
  });
}
