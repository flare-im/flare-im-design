import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _moment = FlareMoment(
  id: 'm1',
  author: FlareMomentAuthor(id: 'alice', name: 'Alice — 很长的用户名称仍然完整换行显示'),
  text: '一条连续阅读的动态，不再用卡片嵌套卡片。\nLong text and emoji 🌿 stay readable.',
  time: '2026年10月18日 下午 12:30',
  likes: [
    FlareMomentLike(id: 'bob', name: 'Bob — 很长的点赞用户名称'),
    FlareMomentLike(id: 'carol', name: 'Carol'),
  ],
  comments: [
    FlareMomentComment(
      id: 'c1',
      author: FlareMomentAuthor(id: 'carol', name: 'Carol'),
      text: '长评论自然换行，内容和互动在同一个平面。',
    ),
  ],
);

Widget _host(Widget child, {bool dark = false, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );

BoxDecoration _surface(WidgetTester tester) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(FlareMomentCard),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

void main() {
  for (final width in [320.0, 390.0, 768.0, 1360.0]) {
    for (final dark in [false, true]) {
      testWidgets('continuous feed fits $width, dark=$dark, large text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var likes = 0, comments = 0;
        await tester.pumpWidget(
          _host(
            FlareMomentCard(
              moment: _moment,
              presentation: FlareMomentPresentation.feed,
              canDelete: true,
              onLike: () => likes++,
              onComment: () => comments++,
              onDelete: () {},
            ),
            dark: dark,
            scale: 1.3,
          ),
        );
        final colors = FlareColors.of(
          tester.element(find.byType(FlareMomentCard)),
        );
        expect(_surface(tester).color, colors.bgPrimary);
        expect(_surface(tester).borderRadius, isNull);
        expect(_surface(tester).boxShadow, isNull);
        expect(_surface(tester).border, isNotNull);
        // No nested dark social card, even when both likes and comments exist.
        final social = tester.widget<Container>(
          find
              .ancestor(
                of: find.byType(FlareCommentThread),
                matching: find.byType(Container),
              )
              .first,
        );
        final socialSurface = social.decoration! as BoxDecoration;
        expect(socialSurface.color, colors.bgPrimary);
        expect(socialSurface.borderRadius, isNull);
        expect(tester.takeException(), isNull);
        for (final label in [
          const FlareStrings().like,
          const FlareStrings().comment,
        ]) {
          await tester.tap(find.byTooltip(const FlareStrings().momentActions));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final action = find.widgetWithText(FlareButton, label);
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect((likes, comments), (1, 1));
      });
    }
  }

  testWidgets('isolated detail keeps the elevated card by default', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const FlareMomentCard(moment: _moment)));
    expect(_surface(tester).boxShadow, isNotEmpty);
    expect(_surface(tester).borderRadius, isNotNull);
  });

  testWidgets('unavailable feed actions remain disabled', (tester) async {
    await tester.pumpWidget(
      _host(
        const FlareMomentCard(
          moment: _moment,
          presentation: FlareMomentPresentation.feed,
        ),
      ),
    );
    await tester.tap(find.byTooltip(const FlareStrings().momentActions));
    await tester.pumpAndSettle();
    for (final label in [
      const FlareStrings().like,
      const FlareStrings().comment,
    ]) {
      final button = tester.widget<FlareButton>(
        find.widgetWithText(FlareButton, label),
      );
      expect(button.onPressed, isNull);
    }
  });
}
