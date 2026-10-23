import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FlarePluginPage (spec Message/PluginPage) against the shared
/// spec/plugin-view-vectors.json — pageViews, pageActions, pagePaging and
/// pageFilters (the Vue, SwiftUI and Compose kits read the same file) — and
/// the page's own behaviour: header with back, pull to refresh, load more
/// asked once per cursor, the unavailable states.
final Map<String, dynamic> vectors =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-view-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final int nowMs = vectors['nowMs'] as int;
final int utcOffsetMinutes = vectors['utcOffsetMinutes'] as int;
final List<Map<String, dynamic>> pageViews = [
  for (final v in vectors['pageViews'] as List) v as Map<String, dynamic>,
];

Map<String, dynamic> pageCase(String id) =>
    pageViews.firstWhere((v) => v['id'] == id);
FlarePluginPageViewModel pageView(String id) =>
    FlarePluginPageViewModel.fromJson(
      (pageCase(id)['view'] as Map).cast<String, Object?>(),
    );
FlarePluginPageRef pageRef(String id) {
  final page = pageCase(id)['page'] as Map;
  return FlarePluginPageRef(
    pluginId: page['pluginId'] as String,
    page: page['page'] as String,
  );
}

Map<String, Object?> filtersOf(Object? json) =>
    (json as Map? ?? const {}).cast<String, Object?>();

const zh = FlareStrings();

Widget host(Widget page) => MaterialApp(home: Scaffold(body: page));

/// A tall surface: a whole page fits, so every key is on screen to tap.
void tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The kit tag's ink of a tone (rules.badge), in the light theme.
Color toneInk(String tone) => switch (tone) {
  'info' => FlareColors.light.infoText,
  'success' => FlareColors.light.successText,
  'warning' => FlareColors.light.warningText,
  'danger' => FlareColors.light.errorText,
  _ => FlareColors.light.textSecondary,
};

String? textAt(WidgetTester tester, String key) {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).data;
}

/// The row keys a rows list draws, in order.
List<String> drawnRowKeys(WidgetTester tester) => [
  for (final element
      in find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'flare-plugin-row:',
                ),
          )
          .evaluate())
    (element.widget.key! as ValueKey<String>).value.substring(
      'flare-plugin-row:'.length,
    ),
];

/// The labels of the filter tabs of [inputId], and the selected one's label.
(List<String>, String) tabsOf(WidgetTester tester, String inputId) {
  final tabs = tester.widget<FlareFilterTabs>(
    find.byKey(FlarePluginPage.filterKey(inputId)),
  );
  return (
    [for (final o in tabs.options) o.label],
    tabs.options.firstWhere((o) => o.value == tabs.selected).label,
  );
}

/// The danger confirmation's keys.
Finder confirmKey(FlareButtonVariant variant) => find.descendant(
  of: find.byType(FlareDangerConfirm),
  matching: find.byWidgetPredicate(
    (w) => w is FlareButton && w.variant == variant,
  ),
);

FlarePluginPageViewModel wallet({String? cursor}) =>
    FlarePluginPageViewModel.fromJson({
      'available': true,
      'title': '钱包',
      'fields': [
        {'label': '可用余额', 'value': '¥12.00'},
      ],
      'blocks': [
        {
          'kind': 'entries',
          'numbered': false,
          'total': 2,
          'more': false,
          'items': [
            {'index': 1, 'text': '收到红包 +¥2.30'},
            {'index': 2, 'text': '发出红包 -¥10.00'},
          ],
        },
      ],
      'nextCursor': ?cursor,
      'data': {'currency': 'CNY'},
    });

const walletRef = FlarePluginPageRef(
  pluginId: 'flare.redpacket',
  page: 'flare.redpacket.wallet',
);

void main() {
  setUp(() => flarePluginNowMs = () => nowMs);
  tearDown(
    () => flarePluginNowMs = () => DateTime.now().millisecondsSinceEpoch,
  );

  group('render facts (pageViews)', () {
    for (final c in pageViews) {
      testWidgets('renders ${c['id']}', (tester) async {
        tallSurface(tester);
        final view = pageView(c['id'] as String);
        await tester.pumpWidget(
          host(
            FlarePluginPage(
              page: pageRef(c['id'] as String),
              title: c['title'] as String?,
              view: view,
              filters: filtersOf(c['filters']),
              onRefresh: () {},
              onRetry: () {},
              onLoadMore: (_) {},
              onFilter: (_) {},
              onAction: (_, _) {},
            ),
          ),
        );
        final facts = c['expect'] as Map<String, dynamic>;
        final id = c['id'] as String;
        expect(
          tester.widget<FlareScreen>(find.byType(FlareScreen)).title,
          facts['heading'],
        );
        final loaded = facts['state'] == 'loaded';
        expect(
          find.byType(FlarePluginView),
          loaded ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(FlarePluginPage.unavailableKey),
          facts['state'] == 'unavailable' ? findsOneWidget : findsNothing,
        );
        for (final f in facts['fields'] as List) {
          expect(find.text((f as Map)['value'] as String), findsOneWidget);
          expect(find.text(f['label'] as String), findsOneWidget);
        }

        final blocks = facts['blocks'] as List;
        for (var i = 0; i < blocks.length; i += 1) {
          final fact = blocks[i] as Map<String, dynamic>;
          final scope = find.byKey(ValueKey('flare-plugin-block-$i'));
          expect(scope, findsOneWidget, reason: '$id block $i');
          switch (fact['kind']) {
            case 'note':
              expect(
                tester
                    .widget<Text>(
                      find.descendant(of: scope, matching: find.byType(Text)),
                    )
                    .data,
                fact['text'],
              );
            case 'rows':
              expect(fact['layout'], 'list');
              final block = view.blocks[i] as FlarePluginRowsBlock;
              final items = (fact['items'] as List)
                  .cast<Map<String, dynamic>>();
              expect(drawnRowKeys(tester), [
                for (final item in items) item['key'],
              ]);
              for (final item in items) {
                final key = item['key'] as String;
                final row = block.rows.firstWhere((r) => r.key == key);
                final badge = item['badge'] as Map<String, dynamic>?;
                final badgeKey = find.byKey(
                  ValueKey('flare-plugin-row-badge:$key'),
                );
                if (badge == null) {
                  expect(badgeKey, findsNothing, reason: '$id $key badge');
                } else {
                  final tag = tester.widget<Text>(
                    find.descendant(of: badgeKey, matching: find.byType(Text)),
                  );
                  expect(tag.data, badge['text']);
                  expect(tag.style?.color, toneInk(badge['tone'] as String));
                  // The badge leads the first line.
                  expect(
                    tester.getTopLeft(badgeKey).dx <
                        tester
                            .getTopLeft(
                              find.byKey(
                                ValueKey('flare-plugin-row-primary:$key'),
                              ),
                            )
                            .dx,
                    isTrue,
                  );
                }
                expect(
                  textAt(tester, 'flare-plugin-row-primary:$key'),
                  item['primary'],
                );
                // The facts hold at the vectors' zone; the screen draws the
                // device's.
                final atFacts = flarePluginRowLines(
                  block,
                  row,
                  nowMs,
                  zh,
                  utcOffsetMinutes: utcOffsetMinutes,
                );
                expect(
                  atFacts.secondary,
                  item['secondary'],
                  reason: '$id $key',
                );
                expect(
                  textAt(tester, 'flare-plugin-row-secondary:$key'),
                  flarePluginRowLines(block, row, nowMs, zh).secondary,
                );
                final actions = (item['actions'] as List)
                    .cast<Map<String, dynamic>>();
                expect(
                  find.descendant(
                    of: find.byKey(FlarePluginView.rowKey(key)),
                    matching: find.byType(FlareButton),
                  ),
                  findsNWidgets(actions.length),
                );
                for (final a in actions) {
                  final button = tester.widget<FlareButton>(
                    find.byKey(
                      FlarePluginView.rowActionKey(key, a['id'] as String),
                    ),
                  );
                  expect(button.label, a['label']);
                  expect(button.variant.name, a['variant']);
                }
              }
              expect(textAt(tester, 'flare-plugin-rows-empty'), fact['empty']);
          }
        }

        final actions = (facts['actions'] as List).cast<Map<String, dynamic>>();
        final declared = [...view.actions, ...view.menuActions];
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is FlareButton &&
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'flare-plugin-action-',
                ),
          ),
          findsNWidgets(actions.length),
        );
        for (final a in actions) {
          final button = tester.widget<FlareButton>(
            find.byKey(ValueKey('flare-plugin-action-${a['id']}')),
          );
          expect(button.label, a['label']);
          expect(button.variant.name, a['variant']);
          final action = declared.firstWhere((d) => d.id == a['id']);
          expect(action.confirm, a['confirm']);
          expect(action.form.isNotEmpty, a['form']);
        }

        final filters = (facts['filters'] as List).cast<Map<String, dynamic>>();
        expect(find.byType(FlareFilterTabs), findsNWidgets(filters.length));
        for (final f in filters) {
          final input = f['input'] as String;
          final (tabs, selected) = tabsOf(tester, input);
          expect(tabs, f['tabs']);
          expect(selected, f['selected']);
          // Each row is named by its input's label.
          expect(
            find.ancestor(
              of: find.byKey(FlarePluginPage.filterKey(input)),
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.label == f['label'],
              ),
            ),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(FlarePluginPage.loadMoreKey),
          facts['loadMore'] == true ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(RefreshIndicator),
          facts['refresh'] == true ? findsOneWidget : findsNothing,
        );
        final empty = facts['empty'] as String?;
        expect(
          empty == null
              ? null
              : tester
                    .widget<FlareEmptyState>(
                      find.byKey(FlarePluginPage.unavailableKey),
                    )
                    .title,
          empty,
        );
        expect(
          find.byKey(FlarePluginPage.retryKey),
          facts['retry'] == true ? findsOneWidget : findsNothing,
        );
      });
    }
  });

  group('page actions (pageActions)', () {
    for (final scenario in vectors['pageActions'] as List) {
      final s = scenario as Map<String, dynamic>;
      testWidgets(s['name'] as String, (tester) async {
        tallSurface(tester);
        final id = s['view'] as String;
        final calls = <(String, FlarePluginPageActionPayload)>[];
        String? busyActionId;
        late StateSetter rebuild;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FlarePluginPage(
                  page: pageRef(id),
                  view: pageView(id),
                  filters: filtersOf(pageCase(id)['filters']),
                  busyActionId: busyActionId,
                  onAction: (actionId, payload) =>
                      calls.add((actionId, payload)),
                );
              },
            ),
          ),
        );
        // The row action keys on the page, by row key.
        Map<String, List<FlareButton>> rowKeys() {
          final keys = <String, List<FlareButton>>{};
          for (final row in drawnRowKeys(tester)) {
            keys[row] = tester
                .widgetList<FlareButton>(
                  find.descendant(
                    of: find.byKey(FlarePluginView.rowKey(row)),
                    matching: find.byType(FlareButton),
                  ),
                )
                .toList();
          }
          return keys;
        }

        var seen = 0;
        for (final st in s['steps'] as List) {
          final step = st as Map<String, dynamic>;
          final reason = jsonEncode(step);
          final tap = step['tap'] as Map<String, dynamic>?;
          if (tap != null) {
            final row = tap['row'] as String?;
            await tester.tap(
              row == null
                  ? find.byKey(ValueKey('flare-plugin-action-${tap['action']}'))
                  : find.byKey(
                      FlarePluginView.rowActionKey(
                        row,
                        tap['action'] as String,
                      ),
                    ),
            );
            await tester.pumpAndSettle();
          }
          final confirm = step['confirm'];
          if (confirm is String) {
            expect(find.text(confirm), findsOneWidget, reason: reason);
          } else if (confirm == true) {
            await tester.tap(confirmKey(FlareButtonVariant.danger));
            await tester.pumpAndSettle();
          }
          if (step['cancel'] == true) {
            await tester.tap(confirmKey(FlareButtonVariant.secondary));
            await tester.pumpAndSettle();
            expect(find.byType(FlareDangerConfirm), findsNothing);
          }
          final form = step['form'] as List?;
          if (form != null) {
            // The form collects the action's inputs, labelled.
            expect(
              [
                for (final field in tester.widgetList<FlareFormField>(
                  find.descendant(
                    of: find.byType(FlarePluginForm),
                    matching: find.byType(FlareFormField),
                  ),
                ))
                  field.label,
              ],
              form,
              reason: reason,
            );
          }
          final fill = step['fill'] as Map<String, dynamic>?;
          if (fill != null) {
            for (final entry in fill.entries) {
              await tester.enterText(
                find.descendant(
                  of: find.byKey(ValueKey('flare-plugin-input-${entry.key}')),
                  matching: find.byType(EditableText),
                ),
                entry.value as String,
              );
            }
            await tester.pump();
          }
          if (step['submit'] == true) {
            await tester.tap(
              find.byKey(const ValueKey('flare-plugin-form-submit')),
            );
            await tester.pump();
          }
          final hostStep = step['host'] as Map<String, dynamic>?;
          if (hostStep != null && hostStep.containsKey('busyActionId')) {
            rebuild(() => busyActionId = hostStep['busyActionId'] as String?);
            await tester.pump();
          }
          if (step['spinningRows'] != null) {
            expect(
              [
                for (final MapEntry(:key, :value) in rowKeys().entries)
                  if (value.any((button) => button.loading)) key,
              ],
              step['spinningRows'],
              reason: reason,
            );
          }
          if (step['rowKeysEnabled'] != null) {
            final buttons = rowKeys().values.expand((keys) => keys).toList();
            expect(buttons, isNotEmpty, reason: reason);
            for (final button in buttons) {
              expect(
                button.disabled,
                !(step['rowKeysEnabled'] as bool),
                reason: reason,
              );
            }
          }
          final emit = step['emit'] as Map<String, dynamic>?;
          if (emit == null) {
            expect(calls.length, seen, reason: reason);
          } else {
            expect(calls.length, seen + 1, reason: reason);
            expect(calls.last.$1, emit['actionId']);
            expect(calls.last.$2.toJson(), emit['payload'], reason: reason);
          }
          seen = calls.length;
        }
      });
    }
  });

  group('paging (pagePaging)', () {
    for (final scenario in vectors['pagePaging'] as List) {
      final s = scenario as Map<String, dynamic>;
      testWidgets(s['name'] as String, (tester) async {
        tallSurface(tester);
        final id = s['view'] as String;
        var view = pageView(id);
        String? actionError;
        var refreshing = false;
        final asked = <String>[];
        final calls = <(String, FlarePluginPageActionPayload)>[];
        late StateSetter rebuild;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FlarePluginPage(
                  page: pageRef(id),
                  view: view,
                  actionError: actionError,
                  refreshing: refreshing,
                  onLoadMore: asked.add,
                  onAction: (actionId, payload) =>
                      calls.add((actionId, payload)),
                );
              },
            ),
          ),
        );
        FlareButton loadMore() =>
            tester.widget<FlareButton>(find.byKey(FlarePluginPage.loadMoreKey));
        var askedBefore = 0;
        for (final st in s['steps'] as List) {
          final step = st as Map<String, dynamic>;
          final reason = jsonEncode(step);
          final tap = step['tap'];
          if (tap == 'loadMore') {
            await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
            await tester.pump();
          } else if (tap is Map) {
            await tester.tap(
              find.byKey(
                FlarePluginView.rowActionKey(
                  tap['row'] as String,
                  tap['action'] as String,
                ),
              ),
            );
            await tester.pumpAndSettle();
          }
          final hostStep = step['host'] as Map<String, dynamic>?;
          if (hostStep != null) {
            rebuild(() {
              if (hostStep['view'] case final Map<String, dynamic> json) {
                view = FlarePluginPageViewModel.fromJson(json);
              }
              if (hostStep.containsKey('actionError')) {
                actionError = hostStep['actionError'] as String?;
              }
              if (hostStep['refreshing'] case final bool next) {
                refreshing = next;
              }
            });
            await tester.pump();
          }
          if (step.containsKey('emit')) {
            final emit = step['emit'];
            if (emit == null) {
              expect(asked.length, askedBefore, reason: reason);
            } else if (emit is String) {
              expect(asked.length, askedBefore + 1, reason: reason);
              expect(asked.last, emit);
            } else if (emit is Map) {
              expect(calls.last.$1, emit['actionId']);
              expect(calls.last.$2.toJson(), emit['payload'], reason: reason);
            }
          }
          askedBefore = asked.length;
          if (step['spinning'] != null) {
            expect(loadMore().loading, step['spinning'], reason: reason);
          }
          if (step['enabled'] != null) {
            expect(
              loadMore().disabled,
              !(step['enabled'] as bool),
              reason: reason,
            );
          }
          if (step['rowKeys'] != null) {
            expect(drawnRowKeys(tester), step['rowKeys'], reason: reason);
          }
          if (step['primaries'] != null) {
            expect(
              [
                for (final key in drawnRowKeys(tester))
                  textAt(tester, 'flare-plugin-row-primary:$key'),
              ],
              step['primaries'],
              reason: reason,
            );
          }
          if (step['loadMore'] != null) {
            expect(
              find.byKey(FlarePluginPage.loadMoreKey),
              step['loadMore'] == true ? findsOneWidget : findsNothing,
              reason: reason,
            );
          }
        }
      });
    }
  });

  group('filters (pageFilters)', () {
    for (final scenario in vectors['pageFilters'] as List) {
      final s = scenario as Map<String, dynamic>;
      testWidgets(s['name'] as String, (tester) async {
        tallSurface(tester);
        final id = s['view'] as String;
        var filters = filtersOf(s['filters']);
        var refreshing = false;
        var loadingMore = false;
        final emitted = <Map<String, Object?>>[];
        late StateSetter rebuild;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FlarePluginPage(
                  page: pageRef(id),
                  view: pageView(id),
                  filters: filters,
                  refreshing: refreshing,
                  loadingMore: loadingMore,
                  onRefresh: () {},
                  onFilter: emitted.add,
                );
              },
            ),
          ),
        );
        var seen = 0;
        for (final st in s['steps'] as List) {
          final step = st as Map<String, dynamic>;
          final reason = jsonEncode(step);
          final tabs = step['tabs'] as Map<String, dynamic>?;
          if (tabs != null) {
            expect(
              find.byType(FlareFilterTabs),
              findsNWidgets(tabs.length),
              reason: reason,
            );
            for (final entry in tabs.entries) {
              expect(tabsOf(tester, entry.key).$1, entry.value, reason: reason);
            }
          }
          final choose = step['choose'] as Map<String, dynamic>?;
          if (choose != null) {
            await tester.tap(
              find.descendant(
                of: find.byKey(
                  FlarePluginPage.filterKey(choose['input'] as String),
                ),
                matching: find.text(choose['tab'] as String),
              ),
            );
            await tester.pump();
          }
          final hostStep = step['host'] as Map<String, dynamic>?;
          if (hostStep != null) {
            rebuild(() {
              if (hostStep.containsKey('filters')) {
                filters = filtersOf(hostStep['filters']);
              }
              if (hostStep['refreshing'] is bool) {
                refreshing = hostStep['refreshing'] as bool;
              }
              if (hostStep['loadingMore'] is bool) {
                loadingMore = hostStep['loadingMore'] as bool;
              }
            });
            await tester.pump();
          }
          if (step.containsKey('emit')) {
            final emit = step['emit'] as Map<String, dynamic>?;
            if (emit == null) {
              expect(emitted.length, seen, reason: reason);
            } else {
              expect(emitted.length, seen + 1, reason: reason);
              expect(emitted.last, emit, reason: reason);
            }
          }
          seen = emitted.length;
          final selected = step['selected'] as Map<String, dynamic>?;
          if (selected != null) {
            for (final entry in selected.entries) {
              expect(tabsOf(tester, entry.key).$2, entry.value, reason: reason);
            }
          }
          if (step['enabled'] != null) {
            for (final tabs in tester.widgetList<FlareFilterTabs>(
              find.byType(FlareFilterTabs),
            )) {
              expect(tabs.enabled, step['enabled'], reason: reason);
            }
          }
        }
      });
    }

    testWidgets('a tab chosen while the page refreshes asks for nothing', (
      tester,
    ) async {
      tallSurface(tester);
      final emitted = <Map<String, Object?>>[];
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: pageRef('wallet'),
            view: pageView('wallet'),
            refreshing: true,
            onFilter: emitted.add,
          ),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(FlarePluginPage.filterKey('kind')),
          matching: find.text('收到'),
        ),
      );
      await tester.pump();
      expect(emitted, isEmpty);
    });
  });

  group('page states', () {
    testWidgets('the first load spins; a failure offers a retry', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        host(const FlarePluginPage(page: walletRef, title: '钱包')),
      );
      expect(find.byKey(FlarePluginPage.loadingKey), findsOneWidget);
      expect(find.text('钱包'), findsOneWidget);
      // A retry under way spins even while the failure is still known.
      await tester.pumpWidget(
        host(
          const FlarePluginPage(
            page: walletRef,
            title: '钱包',
            loading: true,
            error: '加载失败',
          ),
        ),
      );
      expect(find.byKey(FlarePluginPage.loadingKey), findsOneWidget);
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: walletRef,
            title: '钱包',
            error: '加载失败',
            onRetry: () => retries++,
          ),
        ),
      );
      expect(find.byKey(FlarePluginPage.errorKey), findsOneWidget);
      await tester.tap(find.byKey(FlarePluginPage.retryKey));
      expect(retries, 1);
    });

    testWidgets('an unreachable catalog can be asked again; nothing else '
        'shows on an unavailable page', (tester) async {
      var retries = 0;
      var refreshes = 0;
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: walletRef,
            title: '钱包',
            view: pageView('unavailable-catalog-unreachable'),
            onRetry: () => retries++,
            onRefresh: () => refreshes++,
          ),
        ),
      );
      await tester.tap(find.byKey(FlarePluginPage.retryKey));
      expect(retries, 1);
      expect(find.byType(RefreshIndicator), findsNothing);
      expect(find.byType(FlarePluginView), findsNothing);
      expect(refreshes, 0);
    });

    testWidgets(
      'an unavailable page has no refresh key on pointer devices either',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        await tester.pumpWidget(
          host(
            FlarePluginPage(
              page: walletRef,
              title: '钱包',
              view: pageView('unavailable-disabled'),
              onRefresh: () {},
            ),
          ),
        );
        expect(find.byKey(FlarePluginPage.refreshKey), findsNothing);
        expect(find.text('插件已停用'), findsOneWidget);
      },
    );

    testWidgets('a failed refresh keeps the view under a danger banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: walletRef,
            view: wallet(),
            error: '刷新失败',
            onRefresh: () {},
          ),
        ),
      );
      expect(
        tester
            .widget<FlareStatusBanner>(find.byKey(FlarePluginPage.bannerKey))
            .text,
        '刷新失败',
      );
      expect(find.text('¥12.00'), findsOneWidget);
    });

    testWidgets(
      'the view is drawn embedded under the page title and back key',
      (tester) async {
        var backs = 0;
        await tester.pumpWidget(
          host(
            FlarePluginPage(
              page: walletRef,
              view: wallet(),
              onBack: () => backs++,
            ),
          ),
        );
        expect(find.text('钱包'), findsOneWidget);
        expect(find.text('¥12.00'), findsOneWidget);
        expect(find.text('收到红包 +¥2.30'), findsOneWidget);
        final view = tester.widget<FlarePluginView>(
          find.byType(FlarePluginView),
        );
        expect(view.embedded, isTrue);
        // No card shell: the page is the surface.
        expect(find.byKey(const ValueKey('flare-plugin-card')), findsNothing);
        await tester.tap(find.byIcon(Icons.arrow_back));
        expect(backs, 1);
        // Nothing the view does not declare: no load more on the last page,
        // and no filters without a rows block.
        expect(find.byKey(FlarePluginPage.loadMoreKey), findsNothing);
        expect(find.byType(FlareFilterTabs), findsNothing);
      },
    );
  });

  group('page behaviour', () {
    testWidgets('load more asks once per cursor and again after it settles', (
      tester,
    ) async {
      final asked = <String>[];
      Widget page({bool loadingMore = false, String cursor = 'c1'}) => host(
        FlarePluginPage(
          page: walletRef,
          view: wallet(cursor: cursor),
          loadingMore: loadingMore,
          onLoadMore: asked.add,
        ),
      );
      await tester.pumpWidget(page());
      await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
      await tester.pump();
      await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
      expect(asked, ['c1']);
      await tester.pumpWidget(page(loadingMore: true));
      await tester.pumpWidget(page());
      await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
      expect(asked, ['c1', 'c1']);
      await tester.pumpWidget(page(cursor: 'c2'));
      await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
      expect(asked, ['c1', 'c1', 'c2']);
    });

    testWidgets('a pull refreshes until the host says it is done', (
      tester,
    ) async {
      var refreshes = 0;
      var refreshing = false;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return FlarePluginPage(
                page: walletRef,
                view: wallet(),
                refreshing: refreshing,
                onRefresh: () => setState(() {
                  refreshes++;
                  refreshing = true;
                }),
              );
            },
          ),
        ),
      );
      await tester.fling(find.text('¥12.00'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(refreshes, 1);
      // The indicator stays while the host's refresh runs…
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      // …and goes once it is done.
      update(() => refreshing = false);
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets(
      'pointer devices get a refresh key in the header',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        var refreshes = 0;
        await tester.pumpWidget(
          host(
            FlarePluginPage(
              page: walletRef,
              view: wallet(),
              onRefresh: () => refreshes++,
            ),
          ),
        );
        await tester.tap(find.byKey(FlarePluginPage.refreshKey));
        expect(refreshes, 1);
      },
    );

    testWidgets('a choices submit on the page carries the page, its data '
        'and the selection, within the cap', (tester) async {
      tallSurface(tester);
      final poll =
          ((vectors['views'] as List).firstWhere(
                    (v) => v['id'] == 'poll-max-selections',
                  )
                  as Map)['view']
              as Map;
      final calls = <(String, FlarePluginPageActionPayload)>[];
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: const FlarePluginPageRef(
              pluginId: 'x.poll',
              page: 'x.poll.mine',
            ),
            view: FlarePluginPageViewModel.fromJson({
              ...poll.cast<String, Object?>(),
              'data': {'pollId': 'p1'},
            }),
            onAction: (id, payload) => calls.add((id, payload)),
          ),
        ),
      );
      for (final option in [0, 2, 3]) {
        await tester.tap(find.byKey(ValueKey('flare-plugin-option-$option')));
        await tester.pump();
      }
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-choices-submit')),
      );
      await tester.pump();
      expect(calls.single.$1, 'vote');
      expect(calls.single.$2.toJson(), {
        'page': {'pluginId': 'x.poll', 'page': 'x.poll.mine'},
        'data': {'pollId': 'p1'},
        'selection': [0, 2],
      });
    });

    testWidgets('a row action spins only on its own row', (tester) async {
      tallSurface(tester);
      Widget page(String? busy) => host(
        FlarePluginPage(
          page: pageRef('wallet'),
          view: pageView('wallet'),
          busyActionId: busy,
          onAction: (_, _) {},
        ),
      );
      await tester.pumpWidget(page(null));
      await tester.tap(find.byKey(FlarePluginView.rowActionKey('l2', 'open')));
      await tester.pump();
      await tester.pumpWidget(page('open'));
      FlareButton key(String row) => tester.widget<FlareButton>(
        find.byKey(FlarePluginView.rowActionKey(row, 'open')),
      );
      expect(key('l2').loading, isTrue);
      expect(key('l1').loading, isFalse);
      expect(key('l1').disabled, isTrue);
    });
  });
}
