import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlarePluginPageViewModel aligned(String layout) =>
    FlarePluginPageViewModel.fromJson({
      'available': true,
      'title': 'Aligned page',
      'data': {'opaque': 'original'},
      'fields': layout == 'ledger'
          ? [
              {'label': 'Overview', 'value': '42.00'},
            ]
          : [],
      'blocks': [
        {
          'kind': 'status',
          'label': 'Attention',
          'text': 'Visible warning',
          'tone': 'warning',
        },
        {'kind': 'note', 'text': 'Visible danger', 'tone': 'danger'},
        {'kind': 'status', 'text': 'Ordinary information', 'tone': 'info'},
        {'kind': 'note', 'text': 'Ordinary neutral', 'tone': 'neutral'},
        {'kind': 'status', 'text': '   ', 'tone': 'danger'},
        {
          'kind': 'rows',
          'columns': [
            {'label': 'Balance'},
            {'label': 'Wallet'},
            {'label': 'Asset'},
            {'label': 'State'},
          ],
          'rows': [
            for (final id in ['first', 'second'])
              {
                'key': id,
                'cells': [
                  {'text': id == 'first' ? '1000.00' : '88.50'},
                  {'text': '$id wallet'},
                  {'text': 'CNY · cash'},
                  {'text': 'Available'},
                ],
              },
          ],
        },
      ],
      'presentation': {
        'renderer': 'account',
        'props': {
          'layout': layout,
          'summaryTitle': 'Flow summary',
          'sectionTitle': layout == 'ledger'
              ? 'Ledger heading'
              : 'Wallet cards',
          'stepLabel': 'Step one',
          'description': 'Page description',
          'contextLabel': 'Scoped context',
        },
      },
    });

Widget frame(Widget child) => MaterialApp(home: Scaffold(body: child));
Widget page(FlarePluginPageViewModel view) => FlarePluginPage(
  page: const FlarePluginPageRef(pluginId: 'fixture', page: 'aligned'),
  view: view,
  onBack: () {},
);
void size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'safe area adds to header and body gutters instead of replacing them',
    (tester) async {
      size(tester, 1360);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      await tester.pumpWidget(
        frame(
          FlarePluginPage(
            page: const FlarePluginPageRef(
              pluginId: 'fixture',
              page: 'safe-area',
            ),
            title: 'Safe page',
            onBack: () {},
            view: FlarePluginPageViewModel.fromJson({
              'available': true,
              'fields': [
                {'label': 'Field', 'value': 'Value'},
              ],
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = find
          .ancestor(of: find.text('Safe page'), matching: find.byType(Row))
          .first;
      expect(tester.getTopLeft(header).dy, 32);
      expect(tester.getBottomLeft(find.byType(SingleChildScrollView)).dy, 1566);
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .padding,
        const EdgeInsets.fromLTRB(16, 12, 16, 20),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'page and screen explicit unbounded or invalid widths stay finite',
    (tester) async {
      size(tester, 1360);
      for (final width in [null, -1.0, 0.0, double.nan, double.infinity]) {
        await tester.pumpWidget(
          frame(
            FlarePluginPage(
              page: const FlarePluginPageRef(
                pluginId: 'fixture',
                page: 'width',
              ),
              title: 'Unbounded page',
              contentMaxWidth: width,
              view: FlarePluginPageViewModel.fromJson({'available': true}),
            ),
          ),
        );
        await tester.pump();
        final row = find
            .ancestor(
              of: find.text('Unbounded page'),
              matching: find.byType(Row),
            )
            .first;
        expect(tester.getSize(row).width, 1336);
        expect(tester.getSize(row).height, 48);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        frame(const FlareScreen(title: 'Default screen', child: SizedBox())),
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('Default screen'),
                    matching: find.byType(Row),
                  )
                  .first,
            )
            .width,
        1336,
      );
    },
  );

  testWidgets('all page states share the focused header and reading column', (
    tester,
  ) async {
    size(tester, 1360);
    for (final state in [
      'loading',
      'error',
      'unavailable',
      'document',
      'account',
    ]) {
      await tester.pumpWidget(
        frame(
          FlarePluginPage(
            page: const FlarePluginPageRef(pluginId: 'fixture', page: 'states'),
            title: 'State page',
            onBack: () {},
            loading: state == 'loading',
            error: state == 'error' ? 'Read failed' : null,
            view: state == 'unavailable'
                ? FlarePluginPageViewModel.fromJson({'available': false})
                : state == 'document'
                ? FlarePluginPageViewModel.fromJson({
                    'available': true,
                    'fields': [
                      {'label': 'Field', 'value': 'Value'},
                    ],
                  })
                : state == 'account'
                ? aligned('wallet')
                : null,
          ),
        ),
      );
      await tester.pump();
      final title = find.text(
        state == 'account' ? 'Aligned page' : 'State page',
      );
      final header = find.ancestor(of: title, matching: find.byType(Row)).first;
      expect(tester.getSize(header).width, 856, reason: state);
      expect(
        tester.getSize(header).height,
        greaterThanOrEqualTo(48),
        reason: state,
      );
      final back = find.byType(IconButton).first;
      expect(tester.getSize(back), const Size(48, 48));
      expect(tester.getTopLeft(title).dx - tester.getTopRight(back).dx, 8);
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: back, matching: find.byType(Icon)),
            )
            .size,
        20,
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      expect(scroll.padding, const EdgeInsets.fromLTRB(16, 12, 16, 20));
      expect(tester.takeException(), isNull, reason: state);
    }
  });

  for (final layout in ['wallet', 'ledger']) {
    testWidgets(
      '$layout keeps urgent status outside the collapsed information once',
      (tester) async {
        size(tester, 390);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(frame(page(aligned(layout))));
        await tester.pumpAndSettle();
        expect(find.text('Visible warning'), findsOneWidget);
        expect(find.text('Visible danger'), findsOneWidget);
        expect(find.text('Ordinary information'), findsNothing);
        final toggle = find.byKey(const ValueKey('flare-account-information'));
        expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
        expect(
          tester
              .getSemantics(
                find.text(
                  layout == 'wallet' ? 'Wallet cards' : 'Ledger heading',
                ),
              )
              .flagsCollection
              .isHeader,
          isTrue,
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text('Visible warning'), findsOneWidget);
        expect(find.text('Visible danger'), findsOneWidget);
        expect(find.text('Ordinary information'), findsOneWidget);
        expect(find.text('Ordinary neutral'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'ledger intro leads with primary context and does not duplicate description',
    (tester) async {
      size(tester, 390);
      await tester.pumpWidget(frame(page(aligned('ledger'))));
      await tester.pumpAndSettle();
      final context = find.text('Scoped context'),
          description = find.text('Page description');
      expect(description, findsOneWidget);
      expect(
        tester.getBottomLeft(context).dy + 8,
        closeTo(tester.getTopLeft(description).dy, 0.1),
      );
      expect(
        tester.getTopLeft(context).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('flare-account-summary')))
              .dy,
        ),
      );
      final text = tester.widget<Text>(context);
      expect(text.style!.fontSize, 13);
      expect(text.style!.fontWeight, FontWeight.w500);
    },
  );

  testWidgets(
    'flow groups step summary and description at eight then twelve to receipt',
    (tester) async {
      size(tester, 390);
      await tester.pumpWidget(frame(page(aligned('flow'))));
      await tester.pumpAndSettle();
      final step = find.text('Step one'),
          summary = find.text('Flow summary'),
          description = find.text('Page description');
      expect(summary, findsOneWidget);
      expect(
        tester.getBottomLeft(step).dy + 8,
        closeTo(tester.getTopLeft(summary).dy, 0.1),
      );
      expect(
        tester.getBottomLeft(summary).dy + 8,
        closeTo(tester.getTopLeft(description).dy, 0.1),
      );
      expect(
        tester.getBottomLeft(description).dy + 12,
        closeTo(
          tester
              .getTopLeft(find.byKey(const ValueKey('flare-account-receipt')))
              .dy,
          0.1,
        ),
      );
    },
  );
}
