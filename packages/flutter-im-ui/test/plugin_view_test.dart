import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PluginView v2, PluginForm and PluginDetailSheet against the shared
/// spec/plugin-view-vectors.json (the Vue, SwiftUI and Compose kits read the
/// same file).
final Map<String, dynamic> vectors =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-view-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final int nowMs = vectors['nowMs'] as int;
final Map<String, dynamic> users = vectors['users'] as Map<String, dynamic>;
final List<Map<String, dynamic>> views = [
  for (final v in vectors['views'] as List) v as Map<String, dynamic>,
];

Map<String, Object?> viewJson(String id) =>
    (views.firstWhere((v) => v['id'] == id)['view'] as Map)
        .cast<String, Object?>();
FlarePluginViewModel viewOf(String id) =>
    FlarePluginViewModel.fromJson(viewJson(id));

/// The vectors' users without their avatar URLs: the test binding answers
/// every HTTP request with 400.
FlarePluginUser? resolveUser(String id) {
  final user = users[id] as Map<String, dynamic>?;
  return user == null ? null : FlarePluginUser(name: user['name'] as String);
}

const zh = FlareStrings();

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(child: Center(child: child)),
  ),
);

List<FlarePluginInput> formInputs() => [
  for (final i in (vectors['form'] as Map)['inputs'] as List)
    FlarePluginInput.fromJson((i as Map).cast<String, Object?>())!,
];

/// Texts under a finder, in order.
List<String> textsIn(WidgetTester tester, Finder scope) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(of: scope, matching: find.byType(Text)),
  ))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];

void main() {
  setUp(() => flarePluginNowMs = () => nowMs);
  tearDown(
    () => flarePluginNowMs = () => DateTime.now().millisecondsSinceEpoch,
  );

  group('rules', () {
    test('time blocks', () {
      for (final v in vectors['time'] as List) {
        final c = v as Map<String, dynamic>;
        final offset = c['utcOffsetMinutes'] as int;
        expect(
          flarePluginTimeText(
            c['atMs'] as int,
            c['endMs'] as int?,
            nowMs,
            zh,
            utcOffsetMinutes: offset,
          ),
          c['zh'],
          reason: c['name'] as String,
        );
        expect(
          flarePluginTimeText(
            c['atMs'] as int,
            c['endMs'] as int?,
            nowMs,
            flareStringsEnglish,
            utcOffsetMinutes: offset,
          ),
          c['en'],
          reason: c['name'] as String,
        );
      }
    });

    test('countdown', () {
      for (final v in vectors['countdown'] as List) {
        final c = v as Map<String, dynamic>;
        final got = flarePluginCountdown(
          c['atMs'] as int,
          c['nowMs'] as int,
          zh,
        );
        expect(got.text, c['zh'], reason: c['name'] as String);
        expect(got.refreshMs, c['refreshMs'], reason: c['name'] as String);
        expect(
          flarePluginCountdown(
            c['atMs'] as int,
            c['nowMs'] as int,
            flareStringsEnglish,
          ).text,
          c['en'],
        );
      }
    });

    test('fallback names', () {
      for (final v in vectors['fallbackNames'] as List) {
        expect(
          flarePluginFallbackName((v as Map)['userId'] as String),
          v['name'],
        );
      }
    });

    test('form check, submitted values and issue texts', () {
      final inputs = formInputs();
      final form = vectors['form'] as Map<String, dynamic>;
      for (final v in form['cases'] as List) {
        final c = v as Map<String, dynamic>;
        final draft = flarePluginDraft(
          inputs,
          (c['values'] as Map).cast<String, Object?>(),
        );
        expect(
          [
            for (final e in flarePluginCheckForm(inputs, draft))
              {'input': e.input, 'issue': e.issue.name},
          ],
          c['clientErrors'],
          reason: c['name'] as String,
        );
        if (c['submitted'] != null) {
          expect(
            jsonEncode(flarePluginFormValues(inputs, draft)),
            jsonEncode(c['submitted']),
            reason: c['name'] as String,
          );
        }
      }
      for (final v in form['hostErrors'] as List) {
        final e = FlarePluginFormError.fromJson(
          ((v as Map)['error'] as Map).cast<String, Object?>(),
        )!;
        final input = inputs.firstWhere((i) => i.id == e.input);
        expect(flarePluginIssueText(e.issue, input, zh), v['zh']);
        expect(
          flarePluginIssueText(e.issue, input, flareStringsEnglish),
          v['en'],
        );
      }
    });

    test('views parsed twice from the same JSON are equal', () {
      expect(viewOf('task'), viewOf('task'));
      expect(viewOf('task') == viewOf('schedule'), isFalse);
    });
  });

  group('render facts', () {
    for (final vector in views.where(
      (v) => (v['platforms'] as List).contains('flutter'),
    )) {
      testWidgets('renders ${vector['id']}', (tester) async {
        final view = FlarePluginViewModel.fromJson(
          (vector['view'] as Map).cast<String, Object?>(),
        );
        await tester.pumpWidget(
          host(
            FlarePluginView(
              view: view,
              resolveUser: resolveUser,
              onAction: (_, _) {},
            ),
          ),
        );
        final facts = vector['expect'] as Map<String, dynamic>;
        expect(find.text(facts['title'] as String), findsWidgets);
        for (final f in facts['fields'] as List) {
          expect(find.text((f as Map)['value'] as String), findsOneWidget);
        }
        final blocks = facts['blocks'] as List;
        for (var i = 0; i < blocks.length; i += 1) {
          final fact = blocks[i] as Map<String, dynamic>;
          final scope = find.byKey(ValueKey('flare-plugin-block-$i'));
          expect(scope, findsOneWidget, reason: '${vector['id']} block $i');
          final texts = textsIn(tester, scope);
          switch (fact['kind']) {
            case 'text':
              expect(texts.first, fact['text']);
            case 'fields':
              for (final f in fact['fields'] as List) {
                expect(texts, containsAll([(f as Map)['label'], f['value']]));
              }
            case 'choices':
              final options = fact['options'] as List;
              final source =
                  (view.blocks[i] as FlarePluginChoicesBlock).options;
              for (var o = 0; o < options.length; o += 1) {
                final of = options[o] as Map<String, dynamic>;
                final row = find.byKey(
                  ValueKey('flare-plugin-option-${source[o].index}'),
                );
                final rowTexts = textsIn(tester, row);
                expect(rowTexts, contains(of['label']));
                final boxes =
                    fact['interactive'] == true && fact['multiple'] == true;
                if (!boxes) {
                  expect(
                    find
                        .descendant(
                          of: row,
                          matching: find.byKey(
                            const ValueKey('flare-plugin-option-check'),
                          ),
                        )
                        .evaluate()
                        .isNotEmpty,
                    of['selected'],
                    reason: '${of['label']} selected',
                  );
                }
                expect(
                  find
                      .descendant(of: row, matching: find.byType(InkWell))
                      .evaluate()
                      .isNotEmpty,
                  fact['interactive'],
                  reason: '${of['label']} tappable',
                );
                if (of['percentText'] != null) {
                  expect(
                    rowTexts,
                    containsAll([of['percentText'], of['votesText']]),
                  );
                  final bar = tester.widget<FractionallySizedBox>(
                    find.descendant(
                      of: row,
                      matching: find.byKey(
                        const ValueKey('flare-plugin-option-bar'),
                      ),
                    ),
                  );
                  expect(bar.widthFactor, (of['bar'] as int) / 100);
                } else {
                  expect(
                    find.descendant(
                      of: row,
                      matching: find.byKey(
                        const ValueKey('flare-plugin-option-bar'),
                      ),
                    ),
                    findsNothing,
                  );
                }
              }
              final submit = find.descendant(
                of: scope,
                matching: find.byKey(
                  const ValueKey('flare-plugin-choices-submit'),
                ),
              );
              final submitFact = fact['submit'] as Map<String, dynamic>?;
              expect(submit.evaluate().isNotEmpty, submitFact != null);
              if (submitFact != null) {
                expect(
                  tester.widget<FlareButton>(submit).label,
                  submitFact['label'],
                );
                expect(
                  tester.widget<FlareButton>(submit).disabled,
                  !(submitFact['enabled'] as bool),
                );
              }
              final footer = find.descendant(
                of: scope,
                matching: find.byKey(
                  const ValueKey('flare-plugin-choices-footer'),
                ),
              );
              expect(
                footer.evaluate().isEmpty
                    ? null
                    : tester.widget<Text>(footer).data,
                fact['footer'],
              );
            case 'entries':
              for (final r in fact['rows'] as List) {
                final row = r as Map<String, dynamic>;
                expect(texts, contains(row['text']));
                if (row['name'] != null) expect(texts, contains(row['name']));
                if (row['number'] != null)
                  expect(texts, contains('${row['number']}.'));
              }
              if (fact['seeAll'] != null)
                expect(texts, contains(fact['seeAll']));
              if (fact['empty'] != null) expect(texts, contains(fact['empty']));
            case 'people':
              for (final g in fact['groups'] as List) {
                final group = g as Map<String, dynamic>;
                expect(
                  texts,
                  containsAll([group['label'], group['countText']]),
                );
                for (final id in group['avatars'] as List) {
                  expect(
                    find.byKey(ValueKey('flare-plugin-person-$id')),
                    findsWidgets,
                  );
                }
              }
            case 'status':
              expect(texts, contains(fact['text']));
              if (fact['label'] != null) expect(texts, contains(fact['label']));
            case 'progress':
              expect(texts, contains(fact['text']));
              final fill = tester.widget<FractionallySizedBox>(
                find.descendant(
                  of: scope,
                  matching: find.byKey(
                    const ValueKey('flare-plugin-progress-fill'),
                  ),
                ),
              );
              expect(fill.widthFactor, (fact['percent'] as int) / 100);
            case 'time':
              final block = view.blocks[i] as FlarePluginTimeBlock;
              final device = flarePluginTimeText(
                block.atMs,
                block.endMs,
                nowMs,
                zh,
              );
              expect(
                tester
                    .widget<Text>(
                      find.descendant(
                        of: scope,
                        matching: find.byKey(
                          const ValueKey('flare-plugin-time'),
                        ),
                      ),
                    )
                    .data,
                device,
              );
              if (DateTime.fromMillisecondsSinceEpoch(
                    block.atMs,
                  ).timeZoneOffset.inMinutes ==
                  480)
                expect(device, fact['text']);
              final countdown = find.descendant(
                of: scope,
                matching: find.byKey(const ValueKey('flare-plugin-countdown')),
              );
              expect(
                countdown.evaluate().isEmpty
                    ? null
                    : tester.widget<Text>(countdown).data,
                fact['countdown'],
              );
            case 'divider':
              expect(
                find.descendant(of: scope, matching: find.byType(Divider)),
                findsOneWidget,
              );
            case 'note':
              expect(texts, [fact['text']]);
          }
        }
        for (final a in facts['actions'] as List) {
          final action = a as Map<String, dynamic>;
          final key = tester.widget<FlareButton>(
            find.byKey(ValueKey('flare-plugin-action-${action['id']}')),
          );
          expect(key.label, action['label']);
          expect(key.variant.name, action['variant']);
        }
        if (facts['bodyHidden'] == true)
          expect(find.byType(FlareButton), findsNothing);
      });
    }
  });

  group('optimistic choices', () {
    for (final scenario in vectors['optimistic'] as List) {
      final s = scenario as Map<String, dynamic>;
      testWidgets(s['name'] as String, (tester) async {
        final calls = <(String, FlarePluginActionPayload)>[];
        var view = viewOf(s['view'] as String);
        String? busy;
        String? error;
        var settle = 0;
        late StateSetter rebuild;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FlarePluginView(
                  view: view,
                  busyActionId: busy,
                  error: error,
                  settleToken: settle,
                  onAction: (id, payload) => calls.add((id, payload)),
                );
              },
            ),
          ),
        );
        final choices = view.blocks.whereType<FlarePluginChoicesBlock>().first;
        List<int> shown() {
          final multi =
              choices.multiple &&
              find
                  .byKey(const ValueKey('flare-plugin-choices-submit'))
                  .evaluate()
                  .isNotEmpty;
          return [
            for (final o in choices.options)
              if (multi
                  ? (tester
                                    .widget<Container>(
                                      find
                                          .descendant(
                                            of: find.byKey(
                                              ValueKey(
                                                'flare-plugin-option-${o.index}',
                                              ),
                                            ),
                                            matching: find.byType(Container),
                                          )
                                          .first,
                                    )
                                    .decoration
                                as BoxDecoration)
                            .color !=
                        null
                  : find
                        .descendant(
                          of: find.byKey(
                            ValueKey('flare-plugin-option-${o.index}'),
                          ),
                          matching: find.byKey(
                            const ValueKey('flare-plugin-option-check'),
                          ),
                        )
                        .evaluate()
                        .isNotEmpty)
                o.index,
          ];
        }

        for (final st in s['steps'] as List) {
          final step = st as Map<String, dynamic>;
          final tap = step['tap'] ?? step['toggle'];
          if (tap != null) {
            await tester.tap(find.byKey(ValueKey('flare-plugin-option-$tap')));
            await tester.pump();
          }
          if (step['submit'] == true) {
            await tester.tap(
              find.byKey(const ValueKey('flare-plugin-choices-submit')),
            );
            await tester.pump();
          }
          final hostStep = step['host'] as Map<String, dynamic>?;
          if (hostStep != null) {
            rebuild(() {
              if (hostStep.containsKey('busyActionId'))
                busy = hostStep['busyActionId'] as String?;
              if (hostStep['error'] != null)
                error = hostStep['error'] as String;
              if (hostStep['settleToken'] != null)
                settle = hostStep['settleToken'] as int;
              if (hostStep['view'] != null)
                view = viewOf(hostStep['view'] as String);
            });
            await tester.pump();
          }
          final emit = step['emit'] as Map<String, dynamic>?;
          if (emit != null) {
            expect(calls.last.$1, emit['actionId']);
            expect(
              jsonEncode(calls.last.$2.toJson()),
              jsonEncode(emit['payload']),
            );
          }
          if (step['selected'] != null)
            expect(shown(), step['selected'], reason: jsonEncode(step));
          if (step['interactive'] != null) {
            expect(
              find
                  .descendant(
                    of: find.byKey(
                      ValueKey(
                        'flare-plugin-option-${choices.options.first.index}',
                      ),
                    ),
                    matching: find.byType(InkWell),
                  )
                  .evaluate()
                  .isNotEmpty,
              step['interactive'],
            );
          }
          if (step['submitEnabled'] != null) {
            expect(
              tester
                  .widget<FlareButton>(
                    find.byKey(const ValueKey('flare-plugin-choices-submit')),
                  )
                  .disabled,
              !(step['submitEnabled'] as bool),
            );
          }
        }
      });
    }
  });

  testWidgets(
    'names people from a late answer, or the id\'s last 4 characters',
    (tester) async {
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: viewOf('task'),
            resolveUser: (id) async =>
                id == 'u_bob0002' ? const FlarePluginUser(name: 'Bobby') : null,
          ),
        ),
      );
      expect(
        tester
            .widget<FlareAvatar>(
              find.byKey(const ValueKey('flare-plugin-person-u_dave9876')),
            )
            .displayName,
        '9876',
      );
      await tester.pump();
      expect(
        tester
            .widget<FlareAvatar>(
              find.byKey(const ValueKey('flare-plugin-person-u_bob0002')),
            )
            .displayName,
        'Bobby',
      );
    },
  );

  testWidgets(
    'counts down every second in the last hour and stops when closed',
    (tester) async {
      var now = nowMs;
      flarePluginNowMs = () => now;
      final view = FlarePluginViewModel.fromJson({
        'available': true,
        'title': 't',
        'fields': <Object?>[],
        'actions': <Object?>[],
        'blocks': [
          {'kind': 'time', 'atMs': nowMs + 3600000 + 30000, 'countdown': true},
        ],
      });
      await tester.pumpWidget(host(FlarePluginView(view: view)));
      String countdown() => tester
          .widget<Text>(find.byKey(const ValueKey('flare-plugin-countdown')))
          .data!;
      expect(countdown(), '剩余 1 小时');
      now += 60000;
      await tester.pump(const Duration(seconds: 60));
      expect(countdown(), '剩余 59:30');
      now += 1000;
      await tester.pump(const Duration(seconds: 1));
      expect(countdown(), '剩余 59:29');
      now += 3569000;
      await tester.pump(const Duration(seconds: 1));
      expect(countdown(), '已截止');
      await tester.pump(const Duration(minutes: 5));
      expect(countdown(), '已截止');
    },
  );

  testWidgets('expands collapsed text', (tester) async {
    await tester.pumpWidget(
      host(FlarePluginView(view: viewOf('announcement'))),
    );
    expect(find.text('展开'), findsOneWidget);
    await tester.tap(find.text('展开'));
    await tester.pump();
    expect(find.text('收起'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('flare-plugin-text')))
          .maxLines,
      isNull,
    );
  });

  testWidgets('confirms first, then hands the action over', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: viewOf('poll-open-single'),
          onAction: (id, _) => calls.add(id),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('flare-plugin-action-close')));
    await tester.pumpAndSettle();
    expect(find.text('结束后不能再投票，确定结束吗？'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tester.tap(find.byKey(const ValueKey('flare-plugin-action-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FlareButton, '结束投票').last);
    await tester.pumpAndSettle();
    expect(calls, ['close']);
  });

  testWidgets(
    'collects a form on the sheet, keeps it on errors and closes when the host is done',
    (tester) async {
      final calls = <FlarePluginActionPayload>[];
      String? busy;
      var errors = <FlarePluginFormError>[];
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlarePluginView(
                view: viewOf('solitaire-more'),
                busyActionId: busy,
                formErrors: errors,
                onAction: (_, payload) => calls.add(payload),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('flare-plugin-action-join')));
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      await tester.pump();
      expect(find.text('必填'), findsOneWidget);
      expect(calls, isEmpty);
      await tester.enterText(
        find.descendant(
          of: find.byType(FlarePluginForm),
          matching: find.byType(EditableText),
        ),
        '《小王子》',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      await tester.pump();
      expect(calls.single.formValues, {'line': '《小王子》'});
      rebuild(() => busy = 'join');
      await tester.pump();
      rebuild(() {
        busy = null;
        errors = [
          const FlarePluginFormError(
            input: 'line',
            issue: FlarePluginFormIssue.duplicateItem,
          ),
        ];
      });
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsOneWidget);
      expect(find.text('不能重复'), findsOneWidget);
      rebuild(() => errors = []);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      rebuild(() => busy = 'join');
      await tester.pump();
      rebuild(() => busy = null);
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsNothing);
    },
  );

  group('settleToken', () {
    // Opens [action]'s form on [view], fills its first field and submits.
    Future<_SettleHostState> submitted(
      WidgetTester tester, {
      FlarePluginViewModel? view,
      String action = 'join',
      String text = '《小王子》',
      Future<void> Function()? before,
    }) async {
      await tester.pumpWidget(
        host(_SettleHost(view: view ?? viewOf('solitaire-more'))),
      );
      final state = tester.state<_SettleHostState>(find.byType(_SettleHost));
      if (before != null) {
        await before();
      } else {
        await tester.tap(find.byKey(ValueKey('flare-plugin-action-$action')));
      }
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(FlarePluginForm),
              matching: find.byType(EditableText),
            )
            .first,
        text,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      await tester.pump();
      expect(state.calls, hasLength(1));
      return state;
    }

    testWidgets(
      'closes a submitted form on a settle without errors, though busy never showed',
      (tester) async {
        final host = await submitted(tester);
        // Busy set and cleared within one frame: the fallback sees nothing.
        host.update(() => host.busy = 'join');
        host.update(() => host.busy = null);
        await tester.pumpAndSettle();
        expect(find.byType(FlarePluginForm), findsOneWidget);
        host.update(() => host.settle += 1);
        await tester.pumpAndSettle();
        expect(find.byType(FlarePluginForm), findsNothing);
      },
    );

    testWidgets('keeps the form open with the host\'s form errors', (
      tester,
    ) async {
      final host = await submitted(tester);
      host.update(() {
        host.errors = const [
          FlarePluginFormError(
            input: 'line',
            issue: FlarePluginFormIssue.duplicateItem,
          ),
        ];
        host.settle += 1;
      });
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsOneWidget);
      expect(find.text('不能重复'), findsOneWidget);
    });

    testWidgets(
      'keeps the form open with the host\'s error and shows it there',
      (tester) async {
        final host = await submitted(tester);
        host.update(() {
          host.error = '网络异常，请重试';
          host.settle += 1;
        });
        await tester.pumpAndSettle();
        expect(find.byType(FlarePluginForm), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(FlarePluginForm),
            matching: find.text('网络异常，请重试'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sends the carried selection with the form and reverts it on form errors',
      (tester) async {
        final base = viewOf('poll-open-single');
        final choices = base.blocks.whereType<FlarePluginChoicesBlock>().first;
        final json =
            jsonDecode(jsonEncode(viewJson('poll-open-single')))
                as Map<String, dynamic>;
        json['inputs'] = [
          {'id': 'note', 'kind': 'text', 'label': '备注', 'required': true},
        ];
        for (final block in json['blocks'] as List) {
          final b = block as Map<String, dynamic>;
          if (b['kind'] == 'choices') {
            (b['action'] as Map<String, dynamic>)['form'] = ['note'];
          }
        }
        final view = FlarePluginViewModel.fromJson(json);
        bool checked(int index) => find
            .descendant(
              of: find.byKey(ValueKey('flare-plugin-option-$index')),
              matching: find.byKey(const ValueKey('flare-plugin-option-check')),
            )
            .evaluate()
            .isNotEmpty;
        final host = await submitted(
          tester,
          view: view,
          text: '去年也是这里',
          before: () => tester.tap(
            find.byKey(
              ValueKey('flare-plugin-option-${choices.options[1].index}'),
            ),
          ),
        );
        expect(host.calls.single.selection, [1]);
        expect(host.calls.single.formValues, {'note': '去年也是这里'});
        expect(checked(1), isTrue);
        host.update(() {
          host.errors = const [
            FlarePluginFormError(
              input: 'note',
              issue: FlarePluginFormIssue.tooLong,
            ),
          ];
          host.settle += 1;
        });
        await tester.pumpAndSettle();
        expect(checked(1), isFalse);
        expect(find.byType(FlarePluginForm), findsOneWidget);
      },
    );
  });

  testWidgets('pads an embedded view with the sheet insets only when asked', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(FlarePluginView(view: viewOf('task'), embedded: true)),
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-inset-sheet')),
      findsNothing,
    );
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: viewOf('task'),
          embedded: true,
          inset: FlarePluginViewInset.sheet,
        ),
      ),
    );
    final inset = tester.widget<Padding>(
      find.byKey(const ValueKey('flare-plugin-inset-sheet')),
    );
    expect(
      inset.padding,
      const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingLg,
        FlareSizes.spacingXl,
      ),
    );
    // A card shell kept in a sheet: the insets go around it, and the shell
    // keeps its own padding.
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: viewOf('task'),
          inset: FlarePluginViewInset.sheet,
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('flare-plugin-inset-sheet')),
        matching: find.byKey(const ValueKey('flare-plugin-card')),
      ),
      findsOneWidget,
    );
  });

  test('inset paddings follow the table (insets)', () {
    double side(Object? token) => switch (token) {
      'md' => FlareSizes.spacingMd,
      'lg' => FlareSizes.spacingLg,
      'xl' => FlareSizes.spacingXl,
      null => 0,
      _ => throw ArgumentError('$token'),
    };
    final table = (vectors['insets'] as Map).cast<String, Object?>();
    expect(table.keys.toSet(), {
      for (final v in FlarePluginViewInset.values) v.name,
    });
    for (final value in FlarePluginViewInset.values) {
      final sides = (table[value.name] as Map).cast<String, Object?>();
      expect(
        flarePluginViewInsetPadding(value),
        EdgeInsets.fromLTRB(
          side(sides['sides']),
          side(sides['top']),
          side(sides['sides']),
          side(sides['bottom']),
        ),
        reason: value.name,
      );
    }
  });

  testWidgets(
    'keeps the inset on an unavailable view, embedded (its title as a line) '
    'or in its shell',
    (tester) async {
      for (final inset in [
        FlarePluginViewInset.sheet,
        FlarePluginViewInset.sheetTop,
      ]) {
        await tester.pumpWidget(
          host(
            FlarePluginView(
              view: viewOf('unavailable'),
              embedded: true,
              inset: inset,
            ),
          ),
        );
        final padding = find.byKey(
          ValueKey('flare-plugin-inset-${inset.name}'),
        );
        expect(
          tester.widget<Padding>(padding).padding,
          flarePluginViewInsetPadding(inset),
        );
        final line = find.descendant(
          of: padding,
          matching: find.byKey(
            const ValueKey('flare-plugin-unavailable-title'),
          ),
        );
        expect(tester.widget<Text>(line).data, '投票（已失效）');
        expect(find.text('投票'), findsNothing, reason: 'no actions');

        // A host that keeps the shell for an unavailable view.
        await tester.pumpWidget(
          host(FlarePluginView(view: viewOf('unavailable'), inset: inset)),
        );
        expect(
          find.descendant(
            of: find.byKey(ValueKey('flare-plugin-inset-${inset.name}')),
            matching: find.byKey(const ValueKey('flare-plugin-card')),
          ),
          findsOneWidget,
        );
      }
      // An available embedded view has no such line.
      await tester.pumpWidget(
        host(FlarePluginView(view: viewOf('task'), embedded: true)),
      );
      expect(
        find.byKey(const ValueKey('flare-plugin-unavailable-title')),
        findsNothing,
      );
    },
  );

  group('view details key (detailKey)', () {
    for (final scenario in [
      for (final c in vectors['detailKey'] as List)
        if (((c as Map)['platforms'] as List).contains('flutter'))
          c.cast<String, Object?>(),
    ]) {
      testWidgets(scenario['name'] as String, (tester) async {
        final json = {...viewJson(scenario['view'] as String)};
        if (scenario['detail'] case final bool detail) json['detail'] = detail;
        var opened = 0;
        await tester.pumpWidget(
          host(
            FlarePluginView(
              view: FlarePluginViewModel.fromJson(json),
              embedded: scenario['embedded'] as bool? ?? false,
              busy: scenario['busy'] as bool? ?? false,
              busyActionId: scenario['busyActionId'] as String?,
              resolveUser: resolveUser,
              onAction: (_, _) {},
              onOpenDetail: scenario['handler'] == false
                  ? null
                  : () => opened += 1,
            ),
          ),
        );
        final expected = (scenario['expect'] as Map).cast<String, Object?>();
        final key = find.byKey(FlarePluginView.detailKey);
        final fact = expected['key'] as Map?;
        expect(key, fact == null ? findsNothing : findsOneWidget);
        if (fact != null) {
          final button = tester.widget<FlareButton>(key);
          expect(button.label, fact['label']);
          expect(button.disabled, !(fact['enabled'] as bool));
          expect(button.variant, FlareButtonVariant.quiet);
          expect(button.size, FlareControlSize.sm);
          expect(button.block, isTrue);
          // Under the action keys.
          final view = FlarePluginViewModel.fromJson(json);
          for (final action in view.actions) {
            expect(
              tester.getTopLeft(key).dy,
              greaterThan(
                tester
                    .getTopLeft(
                      find.byKey(ValueKey('flare-plugin-action-${action.id}')),
                    )
                    .dy,
              ),
            );
          }
        }
        if (expected.containsKey('seeAll')) {
          final seeAll = expected['seeAll'] as String?;
          if (seeAll == null) {
            expect(find.textContaining('查看全部'), findsNothing);
          } else {
            expect(find.text(seeAll), findsOneWidget);
          }
        }
        if (expected['opens'] == true) {
          await tester.tap(key);
          expect(opened, 1);
        }
      });
    }
  });

  testWidgets('drops the shell when embedded and shows the icon otherwise', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(FlarePluginView(view: viewOf('task'), icon: 'poll')),
    );
    expect(find.byKey(const ValueKey('flare-plugin-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('flare-plugin-icon')), findsOneWidget);
    await tester.pumpWidget(
      host(FlarePluginView(view: viewOf('task'), embedded: true)),
    );
    expect(find.byKey(const ValueKey('flare-plugin-card')), findsNothing);
    expect(find.text('整理 Q4 需求文档'), findsNothing);
  });

  testWidgets('keeps the card within the card width token and the parent', (
    tester,
  ) async {
    for (final width in [240.0, 600.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: FlarePluginView(view: viewOf('announcement')),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('flare-plugin-card'))).width,
        width < FlareSizes.componentRichCardWidth
            ? width
            : FlareSizes.componentRichCardWidth,
      );
    }
  });

  group('FlarePluginForm', () {
    final form = vectors['form'] as Map<String, dynamic>;
    Widget formHost({
      Map<String, Object?>? values,
      List<FlarePluginFormError> errors = const [],
      ValueChanged<Map<String, Object?>>? onSubmit,
    }) => MaterialApp(
      home: Scaffold(
        body: FlarePluginForm(
          inputs: formInputs(),
          values: values,
          errors: errors,
          members: const [
            FlarePluginMember(userId: 'u_alice01', name: 'Alice'),
            FlarePluginMember(userId: 'u_carol003', name: 'Carol'),
          ],
          onSubmit: onSubmit,
        ),
      ),
    );
    Finder field(String id) => find.byKey(ValueKey('flare-plugin-input-$id'));
    String? errorOf(WidgetTester tester, String id) {
      final f = tester.widget<FlareFormField>(
        find.descendant(of: field(id), matching: find.byType(FlareFormField)),
      );
      return f.error;
    }

    testWidgets('quiet until a submit attempt, then the client check', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final submitted = <Map<String, Object?>>[];
      await tester.pumpWidget(formHost(onSubmit: submitted.add));
      for (final input in formInputs()) {
        expect(errorOf(tester, input.id), isNull);
      }
      final counters = (form['initial'] as Map)['counters'] as Map;
      for (final entry in counters.entries) {
        expect(
          tester
              .widget<FlareFormField>(
                find.descendant(
                  of: field(entry.key as String),
                  matching: find.byType(FlareFormField),
                ),
              )
              .hint,
          entry.value,
        );
      }
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      await tester.pump();
      expect(submitted, isEmpty);
      final empty =
          (form['cases'] as List).firstWhere((c) => c['name'] == 'empty')
              as Map;
      for (final input in formInputs()) {
        final has = (empty['clientErrors'] as List).any(
          (e) => e['input'] == input.id,
        );
        expect(errorOf(tester, input.id), has ? '必填' : null, reason: input.id);
      }
    });

    testWidgets('submits the cleaned values', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final c in (form['cases'] as List).where(
        (c) => c['submitted'] != null,
      )) {
        final submitted = <Map<String, Object?>>[];
        await tester.pumpWidget(
          formHost(
            values: (c['values'] as Map).cast<String, Object?>(),
            onSubmit: submitted.add,
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('flare-plugin-form-submit')),
        );
        await tester.pump();
        expect(
          jsonEncode(submitted.single),
          jsonEncode(c['submitted']),
          reason: c['name'] as String,
        );
      }
    });

    testWidgets('shows the host errors until the input is edited', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final valid =
          (form['cases'] as List).firstWhere((c) => c['name'] == 'valid')
              as Map;
      final errors = [
        for (final e in form['hostErrors'] as List)
          FlarePluginFormError.fromJson(
            ((e as Map)['error'] as Map).cast<String, Object?>(),
          )!,
      ];
      await tester.pumpWidget(
        formHost(
          values: (valid['values'] as Map).cast<String, Object?>(),
          errors: errors,
        ),
      );
      for (final entry in (form['shownPerInput'] as Map).entries) {
        expect(
          errorOf(tester, entry.key as String),
          entry.value,
          reason: entry.key as String,
        );
      }
      await tester.enterText(
        find.descendant(
          of: field('title'),
          matching: find.byType(EditableText),
        ),
        '新的标题',
      );
      await tester.pump();
      expect(errorOf(tester, 'title'), isNull);
      expect(errorOf(tester, 'limit'), '超出范围');
    });

    testWidgets('adds and removes option rows inside their limits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(formHost());
      final initial = (form['initial'] as Map)['options'] as Map;
      Finder rows() => find.descendant(
        of: field('options'),
        matching: find.byType(FlareInput),
      );
      expect(rows(), findsNWidgets(initial['rows'] as int));
      expect(
        tester
            .widget<FlareIconButton>(
              find.byKey(const ValueKey('flare-plugin-option-remove-0')),
            )
            .disabled,
        !(initial['canRemove'] as bool),
      );
      for (var i = 0; i < 5; i += 1) {
        await tester.tap(find.byKey(const ValueKey('flare-plugin-option-add')));
        await tester.pump();
      }
      expect(rows(), findsNWidgets(5));
      expect(
        tester
            .widget<FlareButton>(
              find.byKey(const ValueKey('flare-plugin-option-add')),
            )
            .disabled,
        isTrue,
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-option-remove-0')),
      );
      await tester.pump();
      expect(rows(), findsNWidgets(4));
    });

    testWidgets('picks one member through the contact picker when max is 1', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(formHost());
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-members-choose-owner')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlareContactPicker), findsOneWidget);
      await tester.tap(find.text('Carol').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('flare-plugin-members-owner')),
            )
            .data,
        'Carol',
      );
    });
  });

  group('FlarePluginDetailSheet', () {
    testWidgets('loading, error with retry, then the embedded detail view', (
      tester,
    ) async {
      var retries = 0;
      Widget sheet({
        bool loading = false,
        String? error,
        FlarePluginViewModel? view,
      }) => host(
        FlarePluginDetailSheet(
          title: '周末读书会报名',
          loading: loading,
          error: error,
          view: view,
          resolveUser: resolveUser,
          onRetry: () => retries += 1,
        ),
      );
      await tester.pumpWidget(sheet(loading: true));
      expect(find.byKey(FlarePluginDetailSheet.loadingKey), findsOneWidget);
      await tester.pumpWidget(sheet(error: '加载失败，请稍后再试'));
      expect(find.byKey(FlarePluginDetailSheet.errorKey), findsOneWidget);
      expect(find.text('加载失败，请稍后再试'), findsOneWidget);
      await tester.tap(find.text('重试'));
      expect(retries, 1);
      await tester.pumpWidget(sheet(view: viewOf('solitaire-more')));
      expect(find.byType(FlarePluginView), findsOneWidget);
      expect(
        tester.widget<FlarePluginView>(find.byType(FlarePluginView)).embedded,
        isTrue,
      );
      expect(find.text('《三体》'), findsOneWidget);
    });

    testWidgets(
      'hands the action error, form errors, members and settle token to the embedded view',
      (tester) async {
        const members = [FlarePluginMember(userId: 'u_alice01', name: 'Alice')];
        const errors = [
          FlarePluginFormError(
            input: 'line',
            issue: FlarePluginFormIssue.duplicateItem,
          ),
        ];
        await tester.pumpWidget(
          host(
            FlarePluginDetailSheet(
              view: viewOf('solitaire-more'),
              busyActionId: 'join',
              actionError: '提交失败',
              formErrors: errors,
              members: members,
              settleToken: 3,
            ),
          ),
        );
        final view = tester.widget<FlarePluginView>(
          find.byType(FlarePluginView),
        );
        expect(view.busyActionId, 'join');
        expect(view.error, '提交失败');
        expect(view.formErrors, errors);
        expect(view.members, members);
        expect(view.settleToken, 3);
        // The action's failure shows inside the sheet; it stays loaded.
        expect(find.text('提交失败'), findsOneWidget);
        expect(find.byKey(FlarePluginDetailSheet.errorKey), findsNothing);
      },
    );
  });

  group('FlarePluginDetailSheet paging (detailPaging)', () {
    for (final c in vectors['detailPaging'] as List) {
      final scenario = c as Map<String, dynamic>;
      testWidgets(scenario['name'] as String, (tester) async {
        final pages = <String>[];
        final base = viewJson(scenario['view'] as String);
        FlarePluginViewModel viewWith(Object? cursor) =>
            FlarePluginViewModel.fromJson({
              ...base,
              if (cursor != null) 'nextCursor': cursor,
            });
        var view = viewWith(scenario['nextCursor']);
        var loadingMore = scenario['loadingMore'] as bool;
        String? actionError;
        late StateSetter rebuild;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FlarePluginDetailSheet(
                  view: view,
                  loadingMore: loadingMore,
                  actionError: actionError,
                  onLoadMore: pages.add,
                );
              },
            ),
          ),
        );
        final key = find.byKey(FlarePluginDetailSheet.loadMoreKey);
        void check(Map<String, dynamic> fact, int before) {
          if (fact['loadMore'] != null) {
            expect(
              key.evaluate().isNotEmpty,
              fact['loadMore'],
              reason: 'load more shown',
            );
          }
          if (fact['enabled'] != null) {
            expect(
              tester.widget<FlareButton>(key).disabled,
              !(fact['enabled'] as bool),
            );
          }
          if (fact['spinning'] != null) {
            expect(tester.widget<FlareButton>(key).loading, fact['spinning']);
          }
          if (fact.containsKey('emit')) {
            final emit = fact['emit'];
            expect(pages.sublist(before), emit == null ? isEmpty : [emit]);
          }
        }

        final initial = Map<String, dynamic>.of(
          scenario['expect'] as Map<String, dynamic>,
        );
        final initialEmit = initial.remove('emit');
        check(initial, 0);
        if ((scenario['expect'] as Map).containsKey('emit')) {
          await tester.ensureVisible(key);
          await tester.tap(key, warnIfMissed: false);
          await tester.pump();
          expect(pages, initialEmit == null ? isEmpty : [initialEmit]);
        }
        for (final st in (scenario['steps'] as List?) ?? const []) {
          final step = st as Map<String, dynamic>;
          final before = pages.length;
          if (step['tap'] == true) {
            await tester.ensureVisible(key);
            await tester.tap(key, warnIfMissed: false);
            await tester.pump();
          }
          final hostStep = step['host'] as Map<String, dynamic>?;
          if (hostStep != null) {
            rebuild(() {
              if (hostStep.containsKey('nextCursor'))
                view = viewWith(hostStep['nextCursor']);
              if (hostStep['actionError'] != null)
                actionError = hostStep['actionError'] as String;
              if (hostStep['loadingMore'] != null)
                loadingMore = hostStep['loadingMore'] as bool;
            });
            await tester.pump();
          }
          check(step, before);
        }
      });
    }

    testWidgets('a settle forgets the asked page, so it can be asked again', (
      tester,
    ) async {
      final pages = <String>[];
      var settle = 0;
      late StateSetter rebuild;
      final view = FlarePluginViewModel.fromJson({
        ...viewJson('solitaire-more'),
        'nextCursor': 'page-2',
      });
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlarePluginDetailSheet(
                view: view,
                settleToken: settle,
                onLoadMore: pages.add,
              );
            },
          ),
        ),
      );
      final key = find.byKey(FlarePluginDetailSheet.loadMoreKey);
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      expect(tester.widget<FlareButton>(key).disabled, isTrue);
      rebuild(() => settle += 1);
      await tester.pump();
      expect(tester.widget<FlareButton>(key).disabled, isFalse);
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
      expect(pages, ['page-2', 'page-2']);
    });
  });
}

/// A host that owns the settle inputs of a card, for the settleToken tests.
class _SettleHost extends StatefulWidget {
  const _SettleHost({required this.view});
  final FlarePluginViewModel view;

  @override
  State<_SettleHost> createState() => _SettleHostState();
}

class _SettleHostState extends State<_SettleHost> {
  final calls = <FlarePluginActionPayload>[];
  String? busy;
  String? error;
  List<FlarePluginFormError> errors = const [];
  int settle = 0;

  void update(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => FlarePluginView(
    view: widget.view,
    busyActionId: busy,
    error: error,
    formErrors: errors,
    settleToken: settle,
    onAction: (_, payload) => calls.add(payload),
  );
}
