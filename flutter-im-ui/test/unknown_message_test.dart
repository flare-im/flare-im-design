import 'package:flare_im_ui/src/components/flare_unknown_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const hint = '当前版本无法显示这条消息';
const unsupported = '不支持的消息类型';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  test('summary wins as the body', () {
    final p = unknownMessagePresentation(
        contentType: 'flare.poll.v2',
        summary: '[投票] 周会时间',
        hint: hint,
        unsupportedText: unsupported);
    expect(p.body, '[投票] 周会时间');
    expect(p.hasSummary, isTrue);
  });

  test('blank summary falls back to the hint', () {
    final p = unknownMessagePresentation(
        summary: '   ', hint: hint, unsupportedText: unsupported);
    expect(p.body, hint);
    expect(p.hasSummary, isFalse);
  });

  test('title uses the label, else the generic wording', () {
    expect(
        unknownMessagePresentation(label: '投票', hint: hint, unsupportedText: unsupported).title,
        '投票');
    expect(
        unknownMessagePresentation(label: '  ', hint: hint, unsupportedText: unsupported).title,
        unsupported);
  });

  test('raw type stays diagnostic, never the body', () {
    final p = unknownMessagePresentation(
        contentType: 'flare.poll.v2', hint: hint, unsupportedText: unsupported);
    expect(p.diagnostic, 'flare.poll.v2');
    expect(p.body, hint);
  });

  test('missing or blank type yields no diagnostic', () {
    expect(unknownMessagePresentation(hint: hint, unsupportedText: unsupported).diagnostic, '');
    expect(
        unknownMessagePresentation(contentType: '  ', hint: hint, unsupportedText: unsupported)
            .diagnostic,
        '');
  });

  test('every input is trimmed', () {
    final p = unknownMessagePresentation(
        contentType: ' x.y ',
        label: ' 投票 ',
        summary: ' hi ',
        hint: hint,
        unsupportedText: unsupported);
    expect([p.title, p.body, p.diagnostic], ['投票', 'hi', 'x.y']);
  });

  testWidgets('renders the human placeholder and the type as diagnostic',
      (tester) async {
    await tester.pumpWidget(
        _host(const FlareUnknownMessage(contentType: 'flare.poll.v2')));
    expect(find.text(unsupported), findsOneWidget);
    expect(find.text(hint), findsOneWidget);
    expect(find.text('flare.poll.v2'), findsOneWidget);
  });

  testWidgets('offers no action without a handler', (tester) async {
    await tester.pumpWidget(_host(
        const FlareUnknownMessage(contentType: 'x.y', actionText: '了解详情')));
    expect(find.text('了解详情'), findsNothing);
  });

  testWidgets('dispatches the host action when handled', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(FlareUnknownMessage(
        contentType: 'x.y', actionText: '了解详情', onAction: () => tapped = true)));
    await tester.tap(find.text('了解详情'));
    expect(tapped, isTrue);
  });
}
