import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/content_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// In a moment, people and comments are controls only when the host does
// something with them, and the moments cover without an image stays quiet.

const _strings = FlareStrings();

const _moment = FlareMoment(
  id: 'm1',
  author: FlareMomentAuthor(id: 'u_lin', name: '林夏'),
  text: '周末去爬山',
  time: '10 分钟前',
  likes: [
    FlareMomentLike(id: 'u_zhou', name: '周屿'),
    FlareMomentLike(id: 'u_su', name: '苏晚晴'),
  ],
  comments: [
    FlareMomentComment(
      id: 'c1',
      author: FlareMomentAuthor(id: 'u_he', name: '何川'),
      text: '带上我',
    ),
    FlareMomentComment(
      id: 'c2',
      author: FlareMomentAuthor(id: 'u_lin', name: '林夏'),
      text: '好',
      replyToName: '何川',
    ),
  ],
);

Widget _host(Widget child, {FlareStrings strings = _strings}) =>
    FlareStringsScope(
      strings: strings,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 390, child: child),
          ),
        ),
      ),
    );

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('people and comments are plain text when nothing handles them', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(FlareMomentCard(moment: _moment, onLike: () {})),
    );

    expect(find.byType(FlareContentControl), findsNothing);
    expect(find.bySemanticsLabel('回复 何川：带上我'), findsNothing);
    expect(find.text('周屿, 苏晚晴'), findsOneWidget);
    expect(find.textContaining('带上我', findRichText: true), findsOneWidget);
    // The reply line reads through FlareStrings, never a literal.
    expect(find.textContaining(' 回复 ', findRichText: true), findsOneWidget);

    final colors = FlareColors.of(tester.element(find.text('周屿, 苏晚晴')));
    expect(_colorOf(tester, '林夏'), colors.primaryText);
    expect(_colorOf(tester, '周屿, 苏晚晴'), colors.primaryText);
    // The avatar's initial repeats the name and is never announced.
    expect(find.bySemanticsLabel('林'), findsNothing);
    handle.dispose();
  });

  testWidgets('the author, each liker and each comment are named controls', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMomentCard(
          moment: _moment,
          onSelectAuthor: (id) => events.add('author $id'),
          onSelectLiker: (id) => events.add('liker $id'),
          onSelectComment: (comment) => events.add('comment ${comment.id}'),
        ),
      ),
    );

    for (final name in ['林夏', '周屿', '苏晚晴']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(name)),
        isSemantics(isButton: true, hasTapAction: true),
        reason: name,
      );
    }
    final row = find.bySemanticsLabel('回复 何川：带上我');
    expect(row, findsOneWidget);
    expect(
      tester.getSemantics(row),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('回复 林夏：好'), findsOneWidget);
    expect(find.bySemanticsLabel('林'), findsNothing);

    // The author's name line (the first 林夏 text) is the author control.
    await tester.tap(find.text('林夏').first);
    await tester.tap(find.text('苏晚晴'));
    await tester.tap(row);
    // Inside a comment control, the author's name opens the author.
    await tester.tap(find.text('何川').first);
    // The avatar is a pointer shortcut to the author.
    await tester.tap(find.byType(FlareAvatar));
    expect(events, [
      'author u_lin',
      'liker u_su',
      'comment c1',
      'author u_he',
      'author u_lin',
    ]);

    // From the keyboard the author name is the first stop: it shows the focus
    // ring and Enter opens the author.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final colors = FlareColors.of(tester.element(find.text('苏晚晴')));
    final rings = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FlareContentControl),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      rings.where(
        (box) =>
            (box.decoration as BoxDecoration).border ==
            Border.all(color: colors.borderSelected, width: 2),
      ),
      hasLength(1),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(events.last, 'author u_lin');
    expect(events, hasLength(6));
    handle.dispose();
  });

  testWidgets('a comment author opens the author only inside a handled row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        FlareCommentThread(
          comments: _moment.comments,
          onSelect: (comment) => events.add('comment ${comment.id}'),
        ),
      ),
    );
    // Without select author the name is part of the row.
    await tester.tap(find.bySemanticsLabel('回复 何川：带上我'));
    expect(events, ['comment c1']);

    events.clear();
    await tester.pumpWidget(
      _host(
        FlareCommentThread(
          comments: _moment.comments,
          onSelectAuthor: (id) => events.add('author $id'),
        ),
      ),
    );
    // Without select comment there is no control at all.
    expect(find.byType(FlareContentControl), findsNothing);
    expect(find.bySemanticsLabel('回复 何川：带上我'), findsNothing);
    handle.dispose();
  });

  testWidgets('comment copy comes from FlareStrings', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        FlareCommentThread(comments: _moment.comments, onSelect: (_) {}),
        strings: _strings.copyWith(
          momentReplyTo: 'replying to',
          momentReplyToComment: (name, text) => 'Reply to $name: $text',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Reply to 何川: 带上我'), findsOneWidget);
    await tester.pumpWidget(
      _host(
        FlareCommentThread(comments: _moment.comments),
        strings: _strings.copyWith(momentReplyTo: 'replying to'),
      ),
    );
    expect(
      find.textContaining('林夏 replying to 何川', findRichText: true),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('without a cover image the header is a quiet neutral band', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const FlareMomentsCoverHeader(
          userId: 'u_lin',
          name: '林夏',
          signature: '保持好奇',
        ),
      ),
    );
    final colors = FlareColors.of(tester.element(find.text('林夏')));
    final band = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(FlareMomentsCoverHeader),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(band.color, colors.bgTertiary);
    final gradients = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(FlareMomentsCoverHeader),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where((box) => (box.decoration as BoxDecoration).gradient != null);
    expect(gradients, isEmpty, reason: 'no brand gradient or scrim');
    final name = tester.widget<Text>(find.text('林夏')).style!;
    expect(name.color, colors.textPrimary);
    expect(name.shadows, isNull);
    final signature = tester.widget<Text>(find.text('保持好奇')).style!;
    expect(signature.color, colors.textSecondary);
    expect(signature.shadows, isNull);
    final header = tester.getSize(find.byType(FlareMomentsCoverHeader));
    expect(header.height, lessThan(240));
    // Nothing to change without callbacks: no cover control, pill or avatar
    // control.
    expect(find.text(_strings.changeCover), findsNothing);
    expect(find.bySemanticsLabel(_strings.changeCover), findsNothing);
    expect(find.byType(FlareContentControl), findsNothing);
    handle.dispose();
  });

  testWidgets('the cover and avatar are controls with their callbacks', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMomentsCoverHeader(
          userId: 'u_lin',
          name: '林夏',
          onEditCover: () => events.add('cover'),
          onAvatar: () => events.add('avatar'),
        ),
      ),
    );
    final cover = find.bySemanticsLabel(_strings.changeCover);
    expect(cover, findsOneWidget);
    expect(
      tester.getSemantics(cover),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.text(_strings.changeCover), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(FlareAvatar)),
      isSemantics(isButton: true, hasTapAction: true, label: '林夏'),
    );
    await tester.tap(find.text(_strings.changeCover));
    await tester.tap(find.byType(FlareAvatar));
    expect(events, ['cover', 'avatar']);
    handle.dispose();
  });

  testWidgets('with a cover image the name keeps the white, shadowed look', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FlareMomentsCoverHeader(
          userId: 'u_lin',
          name: '林夏',
          coverUrl: 'https://example.com/cover.png',
        ),
      ),
    );
    final name = tester.widget<Text>(find.text('林夏')).style!;
    expect(name.color, Colors.white);
    expect(name.shadows, isNotEmpty);
    expect(
      tester.getSize(find.byType(FlareMomentsCoverHeader)).height,
      greaterThan(240),
    );
  });
}
