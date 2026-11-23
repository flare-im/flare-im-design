import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/plugin-experience.md §2 rules against the shared vector groups of
/// spec/plugin-view-vectors.json (actionRoles, statusValues, references,
/// blockBoundInputs, cardHeader, refreshKey, accountDerivation,
/// formPlacement, formCounter, selectOptions, actionDedupe, result,
/// pageStates, statusCard) and spec/plugin-refresh-vectors.json (afterAction,
/// afterReturn). The Vue, SwiftUI and Compose kits read the same files.
final Map<String, dynamic> vectors =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-view-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final Map<String, dynamic> refresh =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-refresh-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

List<Map<String, dynamic>> cases(String name) => [
  for (final c in vectors[name] as List)
    if (((c as Map)['platforms'] as List?)?.contains('flutter') ?? true)
      c.cast<String, dynamic>(),
];

/// A vector's view as the core SDK resolves it: available, untitled.
FlarePluginPageViewModel viewOf(Object? json) =>
    FlarePluginPageViewModel.fromJson({
      'available': true,
      'title': '',
      ...(json as Map).cast<String, Object?>(),
    });

List<String> ids(Iterable<FlarePluginAction> actions) => [
  for (final a in actions) a.id,
];

const zh = FlareStrings();

Widget host(Widget child, {Size size = const Size(390, 900)}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('actionRoles', () {
    for (final c in cases('actionRoles')) {
      test(c['name'] as String, () {
        final view = viewOf(c['view']);
        final places = flarePluginActionPlaces(
          view,
          embedded: c['embedded'] as bool,
          inlineFormActionId: c['inlineFormActionId'] as String?,
        );
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        expect(places.archetype.name, expected['archetype']);
        final want = (expected['places'] as Map).cast<String, dynamic>();
        final got = <String, Object?>{
          'quick': ids(places.quick),
          'bar': ids(places.bar),
          'barSecondary': ids(places.barSecondary),
          'header': ids(places.header),
          'commands': ids(places.commands),
          'more': ids(places.more),
          'danger': ids(places.danger),
          'footer': ids(places.footer),
          'menu': ids(places.menu),
        };
        for (final entry in got.entries) {
          if (want.containsKey(entry.key)) {
            expect(entry.value, want[entry.key], reason: entry.key);
          } else {
            expect(entry.value, isEmpty, reason: entry.key);
          }
        }
        if (want['list'] case final List list) {
          expect([
            for (final g in places.list)
              {'group': g.group, 'ids': ids(g.actions)},
          ], list);
        } else {
          expect(places.list, isEmpty);
        }
        final all = [...view.actions, ...view.menuActions];
        if (expected['roles'] case final Map roles) {
          for (final entry in roles.entries) {
            final action = all.firstWhere((a) => a.id == entry.key);
            expect(flarePluginActionRole(action).name, entry.value);
          }
        }
        if (expected['chevron'] case final List chevron) {
          expect([
            for (final g in places.list)
              for (final a in g.actions)
                if (flarePluginActionRole(a) ==
                    FlarePluginActionRole.destination)
                  a.id,
          ], chevron);
        }
      });
    }

    testWidgets('an overview page draws quick keys and grouped list cards', (
      tester,
    ) async {
      final c = cases('actionRoles').first;
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: const FlarePluginPageRef(pluginId: 'p', page: 'home'),
            view: viewOf(c['view']),
            appearance: FlarePluginPageAppearance.document,
            onAction: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flare-plugin-quick')), findsOneWidget);
      for (final id in ['recharge', 'withdraw']) {
        final key = tester.widget<FlareButton>(
          find.byKey(ValueKey('flare-plugin-action-$id')),
        );
        expect(key.variant, FlareButtonVariant.primary);
        expect(key.appearance, FlareButtonAppearance.standard);
      }
      expect(find.text(zh.pluginViewGroupCommon), findsOneWidget);
      expect(find.text(zh.pluginViewGroupRecords), findsOneWidget);
      // List rows are kit settings rows in primary text, never brand text.
      final row = find.descendant(
        of: find.byKey(const ValueKey('flare-plugin-action-history')),
        matching: find.byType(FlareSettingsRow),
      );
      expect(row, findsOneWidget);
    });
  });

  group('statusValues', () {
    for (final c in cases('statusValues')) {
      test(c['name'] as String, () {
        final item = (c['item'] as Map).cast<String, Object?>();
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        final (
          String text,
          FlarePluginTone? tone,
          bool unmapped,
        ) = switch (c['where']) {
          'field' => () {
            final f = FlarePluginField.fromJson(item);
            return (f.value, f.tone, f.unmapped);
          }(),
          'cell' => () {
            final rows =
                FlarePluginBlock.fromJson({
                      'kind': 'rows',
                      'columns': [
                        {'label': 's'},
                      ],
                      'rows': [
                        {
                          'key': 'r',
                          'cells': [item],
                        },
                      ],
                    })!
                    as FlarePluginRowsBlock;
            final cell = rows.rows.single.cells.single;
            return (cell.text, cell.tone, cell.unmapped);
          }(),
          'status' => () {
            final b =
                FlarePluginBlock.fromJson(item)! as FlarePluginStatusBlock;
            return (b.text, b.tone, b.unmapped);
          }(),
          _ => () {
            final b = FlarePluginBadge.fromJson(item)!;
            return (b.text, b.tone, b.unmapped);
          }(),
        };
        final drawsTag =
            c['where'] == 'status' ||
            c['where'] == 'badge' ||
            tone != null ||
            unmapped;
        expect(drawsTag ? 'tag' : 'text', expected['draw']);
        final words = flarePluginStatusText(
          text,
          unmapped: unmapped,
          strings: zh,
        );
        if (expected['unknown'] == true) {
          expect(words, zh.pluginViewUnknownStatus);
          expect(words, isNot(text));
        } else {
          expect(words, expected['text']);
        }
        if (expected['tone'] case final String want) {
          expect(unmapped ? 'neutral' : tone?.name, want);
        }
      });
    }

    testWidgets(
      'an unmapped field draws the unknown tag, never the raw value',
      (tester) async {
        await tester.pumpWidget(
          host(
            FlarePluginView(
              embedded: true,
              view: viewOf({
                'fields': [
                  {
                    'label': '状态',
                    'value': 'prepared',
                    'tone': 'neutral',
                    'unmapped': true,
                  },
                ],
              }),
            ),
          ),
        );
        expect(find.text('prepared'), findsNothing);
        expect(find.text(zh.pluginViewUnknownStatus), findsOneWidget);
        expect(find.byType(FlareTag), findsOneWidget);
      },
    );
  });

  group('references', () {
    for (final c in cases('references')) {
      test(c['name'] as String, () {
        final fields = [
          for (final f in c['fields'] as List)
            FlarePluginField.fromJson((f as Map).cast<String, Object?>()),
        ];
        final split = flarePluginReferenceSplit(fields);
        final expected = c['expect'] as Map;
        expect([for (final f in split.main) f.label], expected['main']);
        expect([
          for (final f in split.references) f.label,
        ], expected['references']);
      });
    }
  });

  group('blockBoundInputs', () {
    for (final c in cases('blockBoundInputs')) {
      test(c['name'] as String, () {
        final view = viewOf(c['view']);
        final expected = c['expect'] as Map;
        final bound = flarePluginBoundInputs(view);
        expect([
          for (final a in view.actions)
            if (!flarePluginIsBlockAction(a, bound))
              for (final i in flarePluginFormFields(view, a)) i.id,
        ], expected['formFields']);
        expect(
          ids(flarePluginTopLevelActions(view, embedded: true)),
          expected['topLevel'],
        );
        expect([
          for (final a in view.actions)
            if (flarePluginIsBlockAction(a, bound)) a.id,
        ], expected['blockActions']);
        expect(
          flarePluginPageInlineFormActionId(view, interactive: true),
          expected['inlineFormActionId'],
        );
      });
    }
  });

  group('cardHeader', () {
    for (final c in cases('cardHeader')) {
      testWidgets(c['name'] as String, (tester) async {
        final footer = c['footerActions'] as int;
        final menu = c['menuActions'] as int;
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 360,
              child: FlarePluginView(
                icon: 'chats',
                // A card view: a page view model never carries a detail.
                view: FlarePluginViewModel.fromJson({
                  'available': true,
                  'title': '接龙',
                  'detail': c['detail'],
                  'actions': [
                    for (var i = 0; i < footer; i++)
                      {'id': 'a$i', 'label': '动作$i'},
                  ],
                  'menuActions': [
                    for (var i = 0; i < menu; i++)
                      {'id': 'm$i', 'label': '菜单$i'},
                  ],
                }),
                onAction: (_, _) {},
                onOpenDetail: c['detail'] as bool ? () {} : null,
              ),
            ),
          ),
        );
        final expected = c['expect'] as Map;
        final title = tester.getRect(find.text('接龙'));
        final detail = find.byKey(FlarePluginView.detailKey);
        if ((expected['order'] as List).contains('detail')) {
          final rect = tester.getRect(detail);
          expect(rect.center.dy, closeTo(title.center.dy, 1));
          expect(rect.left, greaterThan(title.left));
          if ((expected['order'] as List).contains('more')) {
            expect(
              tester.getRect(find.byKey(FlarePluginView.menuKey)).left,
              greaterThan(rect.left),
            );
          }
        }
        if (expected['detailInFooter'] == true) {
          expect(tester.getRect(detail).top, greaterThan(title.bottom));
        }
      });
    }
  });

  group('refreshKey', () {
    for (final c in cases('refreshKey')) {
      test(c['name'] as String, () {
        expect(
          flarePluginShowsRefreshKey(
            viewOf(c['view']),
            inlineFormActionId: c['inlineFormActionId'] as String?,
          ),
          c['expect'],
        );
      });
    }
  });

  group('accountDerivation', () {
    for (final c in cases('accountDerivation')) {
      test(c['name'] as String, () {
        final appearance = switch (c['appearance']) {
          'document' => FlarePluginPageAppearance.document,
          'account' => FlarePluginPageAppearance.account,
          _ => null,
        };
        final derived =
            appearance ??
            (flarePluginDerivesAccount(viewOf(c['view']))
                ? FlarePluginPageAppearance.account
                : FlarePluginPageAppearance.document);
        expect(derived.name, c['expect']);
      });
    }
  });

  group('form', () {
    for (final c in cases('formPlacement')) {
      test('placement: ${c['name']}', () {
        expect(
          flarePluginFormPlacement([
            for (final kind in c['inputs'] as List)
              FlarePluginInputKind.values.byName(kind as String),
          ], inline: c['inline'] as bool).name,
          c['expect'],
        );
      });
    }
    for (final c in cases('formCounter')) {
      test('counter: ${c['name']}', () {
        expect(
          flarePluginShowsCounter(c['maxLength'] as int?, c['length'] as int),
          c['expect'],
        );
      });
    }
    for (final c in cases('selectOptions')) {
      test('select: ${c['name']}', () {
        final pick = flarePluginSelectControl(c['choices'] as int);
        final expected = c['expect'] as Map;
        expect(pick.control.name, expected['control']);
        expect(pick.disabled, expected['disabled']);
      });
    }

    testWidgets('a select without choices is a disabled select and holds the '
        'submit back', (tester) async {
      await tester.pumpWidget(
        host(
          FlarePluginForm(
            inputs: [
              FlarePluginInput.fromJson({
                'id': 'scheme',
                'kind': 'select',
                'label': '钱包方案',
                'required': true,
                'choices': <Object>[],
              })!,
            ],
            onSubmit: (_) {},
          ),
        ),
      );
      final select = tester.widget<FlareSelect>(find.byType(FlareSelect));
      expect(select.disabled, isTrue);
      expect(select.placeholder, zh.pluginViewNoOptions);
      expect(find.text(zh.pluginViewNoOptionsHelp), findsOneWidget);
      expect(
        tester
            .widget<FlareButton>(
              find.byKey(const ValueKey('flare-plugin-form-submit')),
            )
            .disabled,
        isTrue,
      );
    });

    testWidgets('≤ 4 choices draw choice cards', (tester) async {
      await tester.pumpWidget(
        host(
          FlarePluginForm(
            inputs: [
              FlarePluginInput.fromJson({
                'id': 'type',
                'kind': 'select',
                'label': '证件类型',
                'choices': [
                  for (final v in ['a', 'b', 'c']) {'value': v, 'label': v},
                ],
              })!,
            ],
          ),
        ),
      );
      expect(
        tester
            .widget<FlareRadioGroup>(find.byType(FlareRadioGroup))
            .optionLayout,
        FlareRadioOptionLayout.cards,
      );
    });
  });

  group('actionDedupe', () {
    for (final c in cases('actionDedupe')) {
      test(c['name'] as String, () {
        final actions = [
          for (final a in c['actions'] as List)
            FlarePluginAction.fromJson((a as Map).cast<String, Object?>()),
        ];
        expect(
          ids(flarePluginDedupeActions(actions)),
          (c['expect'] as Map)['drawn'],
        );
      });
    }
  });

  group('result', () {
    for (final c in cases('result')) {
      test(c['name'] as String, () {
        final block =
            FlarePluginBlock.fromJson(
                  (c['block'] as Map).cast<String, Object?>(),
                )!
                as FlarePluginResultBlock;
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        final tone = block.unmapped ? FlarePluginTone.neutral : block.tone;
        expect(flarePluginToneIcon(tone), expected['icon']);
        expect(tone.name, expected['tone']);
        expect(flarePluginResultPolls(block), expected['poll']);
        if (expected['poll'] == true) {
          expect(flarePluginResultPollMs, expected['pollMs']);
          expect(flarePluginResultPollForMs, expected['pollForMs']);
        }
        final title = flarePluginStatusText(
          block.title,
          unmapped: block.unmapped,
          strings: zh,
        );
        if (expected['unknown'] == true) {
          expect(title, zh.pluginViewUnknownStatus);
        } else {
          expect(title, expected['title']);
        }
        if (expected['announce'] case final String announce) {
          expect(
            [title, if (block.description != null) block.description].join(' '),
            announce,
          );
        }
      });
    }

    testWidgets('a result page draws the result view and its done key', (
      tester,
    ) async {
      var done = 0;
      final c = cases('result').first;
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: const FlarePluginPageRef(pluginId: 'p', page: 'result'),
            view: viewOf({
              'fields': [
                {'label': '收款方', 'value': '周屿'},
              ],
              'blocks': [c['block']],
            }),
            onRefresh: (_) {},
            onDone: () => done++,
            onAction: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareResultView), findsOneWidget);
      expect(find.text('转账成功'), findsOneWidget);
      expect(find.text('¥99.00'), findsOneWidget);
      // R1: a result page has no refresh key.
      expect(find.byKey(FlarePluginPage.refreshKey), findsNothing);
      await tester.tap(find.byKey(FlareResultView.doneKey));
      expect(done, 1);
    });
  });

  group('pageStates', () {
    for (final c in cases('pageStates')) {
      testWidgets(c['name'] as String, (tester) async {
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        final view = c['view'] == null ? null : viewOf(c['view']);
        final actions = <String>[];
        await tester.pumpWidget(
          host(
            FlarePluginPage(
              page: const FlarePluginPageRef(pluginId: 'p', page: 'x'),
              view: view,
              loading: c['loading'] as bool,
              error: c['error'] as String?,
              offline: c['offline'] as bool? ?? false,
              actionError: c['actionError'] as String?,
              appearance: FlarePluginPageAppearance.document,
              onRetry: () {},
              onAction: (id, _) => actions.add(id),
            ),
          ),
        );
        if (c['elapsedMs'] case final int elapsed) {
          await tester.pump(Duration(milliseconds: elapsed));
        }
        switch (expected['state']) {
          case 'blank':
            expect(find.byKey(FlarePluginPage.skeletonKey), findsNothing);
            expect(find.byType(CircularProgressIndicator), findsNothing);
          case 'skeleton':
            final skeleton = tester.widget<FlareSkeleton>(
              find.byKey(FlarePluginPage.skeletonKey),
            );
            expect(skeleton.rows, expected['rows']);
          case 'error':
            expect(find.text(zh.pluginViewLoadFailedTitle), findsOneWidget);
            expect(find.text(c['error'] as String), findsOneWidget);
            expect(find.byKey(FlarePluginPage.retryKey), findsOneWidget);
          default:
            if (expected['banner'] case final Map banner) {
              final text = banner['text'] == 'pluginView.offline'
                  ? zh.pluginViewOffline
                  : banner['text'] as String;
              final found = tester.widget<FlareStatusBanner>(
                find.ancestor(
                  of: find.text(text),
                  matching: find.byType(FlareStatusBanner),
                ),
              );
              expect(found.tone.name, banner['tone']);
              if (banner['dismissible'] == true) {
                expect(found.dismissible, isTrue);
                await tester.tap(
                  find.byKey(const ValueKey('flare-status-banner-dismiss')),
                );
                await tester.pump();
                expect(find.text(text), findsNothing);
              }
            }
            if (expected['actionsDisabled'] == true) {
              for (final button in tester.widgetList<FlareButton>(
                find.byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'flare-plugin-action-',
                      ),
                ),
              )) {
                expect(button.disabled, isTrue);
              }
              expect(find.text(zh.pluginViewAvailableOnline), findsWidgets);
            }
            if (expected['blockEmpty'] case final Map empty) {
              expect(find.text(empty['title'] as String), findsOneWidget);
              final key = find.descendant(
                of: find.byKey(FlarePluginView.rowsEmptyKey),
                matching: find.byKey(
                  ValueKey('flare-plugin-action-${empty['action']}'),
                ),
              );
              expect(key, findsOneWidget);
            }
        }
      });
    }
  });

  group('actionDisabled', () {
    for (final c in cases('actionDisabled')) {
      testWidgets(c['name'] as String, (tester) async {
        final ran = <String>[];
        await tester.pumpWidget(
          host(
            FlarePluginPage(
              page: const FlarePluginPageRef(pluginId: 'p', page: 'x'),
              view: viewOf({'actions': c['actions']}),
              appearance: FlarePluginPageAppearance.document,
              onAction: (id, _) => ran.add(id),
            ),
          ),
        );
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        final drawn = expected['drawn'] as List;
        final disabled = expected['disabled'] as List;
        for (final a in (c['declared'] as List).cast<Map>()) {
          final id = a['id'] as String;
          final key = find.byKey(ValueKey('flare-plugin-action-$id'));
          expect(key, drawn.contains(id) ? findsOneWidget : findsNothing);
          if (!drawn.contains(id)) continue;
          final off = switch (tester.widgetList(key).single) {
            FlareButton(:final disabled) => disabled,
            _ =>
              tester
                  .widget<FlareSettingsRow>(
                    find.descendant(
                      of: key,
                      matching: find.byType(FlareSettingsRow),
                    ),
                  )
                  .item
                  .disabled,
          };
          expect(off, disabled.contains(id), reason: id);
        }
        for (final entry in (expected['captions'] as Map).entries) {
          expect(find.text(entry.value as String), findsOneWidget);
        }
        for (final id in disabled) {
          await tester.tap(
            find.byKey(ValueKey('flare-plugin-action-$id')),
            warnIfMissed: false,
          );
        }
        expect(ran, isEmpty);
      });
    }
  });

  group('statusCard', () {
    for (final c in cases('statusCard')) {
      test(c['name'] as String, () {
        expect(flarePluginShowsStatusCard(viewOf(c['view'])), c['expect']);
      });
    }
  });

  group('refresh', () {
    for (final c in refresh['afterAction'] as List) {
      test('afterAction: ${c['name']}', () {
        final refreshes = flarePluginRefreshAfterAction(
          ok: c['settle'] == 'ok',
          visible: c['visible'] as bool,
        );
        expect(refreshes, (c['expect'] as Map)['refresh']);
        if (refreshes) {
          expect(
            flarePluginRefreshReasonName(FlarePluginRefreshReason.action),
            (c['expect'] as Map)['reason'],
          );
        }
      });
    }
    for (final c in refresh['afterReturn'] as List) {
      test('afterReturn: ${c['name']}', () {
        final got = flarePluginAfterReturn(
          c['event'] as String,
          origin: c['origin'] as bool? ?? false,
        );
        final expected = c['expect'] as Map;
        expect(got.refresh, expected['refresh']);
        expect(got.page, expected['page']);
        if (got.refresh) {
          expect(
            flarePluginRefreshReasonName(FlarePluginRefreshReason.returned),
            expected['reason'],
          );
        }
      });
    }

    for (final c in refresh['doneTarget'] as List) {
      test('doneTarget: ${c['name']}', () {
        expect(
          flarePluginDoneTarget([
            for (final page in c['stack'] as List) page as String,
          ]),
          (c['expect'] as Map)['target'],
        );
      });
    }

    testWidgets('a cleanly settled action asks for the page again', (
      tester,
    ) async {
      final reasons = <FlarePluginRefreshReason>[];
      Widget page(int token, {String? error}) => host(
        FlarePluginPage(
          page: const FlarePluginPageRef(pluginId: 'p', page: 'x'),
          view: viewOf({
            'fields': [
              {'label': '余额', 'value': '¥1.00'},
            ],
          }),
          settleToken: token,
          actionError: error,
          onRefresh: reasons.add,
          onAction: (_, _) {},
        ),
      );
      await tester.pumpWidget(page(0));
      await tester.pumpWidget(page(1, error: '余额不足'));
      await tester.pump();
      expect(reasons, isEmpty);
      await tester.pumpWidget(page(2));
      await tester.pump();
      expect(reasons, [FlarePluginRefreshReason.action]);
    });
  });
}
