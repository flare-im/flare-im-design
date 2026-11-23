import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_resolved_presentation.dart'
    show flareHasResolvedPresentation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The red packet product pages (docs/plugin-experience.md §4, §11): the
/// `redPacket.compose` / `redPacket.detail` renderers map to the kit
/// components through [flareRedPacketComposePlan] / [flareRedPacketDetailPlan]
/// — never the plugin id — and fall back to the generic document whenever the
/// mapping refuses. Mirrors the web composition's cases.

Map<String, Object?> composeJson({
  Map<String, Object?> bound = const {'submit': 'prepare'},
  Map<String, Object?> props = const {},
  List<Map<String, Object?>>? actions,
}) => {
  'available': true,
  'title': '发红包',
  'actions':
      actions ??
      [
        {
          'id': 'prepare',
          'label': '塞钱进红包',
          'form': [
            'kind',
            'amount',
            'shareCount',
            'greeting',
            'designatedUserIds',
          ],
        },
      ],
  'inputs': [
    {
      'id': 'kind',
      'kind': 'select',
      'label': '类型',
      'required': true,
      'default': 'normal',
      'choices': [
        {'value': 'normal', 'label': '普通'},
        {'value': 'lucky', 'label': '拼手气'},
        {'value': 'exclusive', 'label': '专属'},
      ],
    },
    {
      'id': 'amount',
      'kind': 'money',
      'label': '金额',
      'required': true,
      'money': {'currency': 'CNY', 'scale': 2, 'min': '0.01', 'max': '10.00'},
    },
    {
      'id': 'shareCount',
      'kind': 'number',
      'label': '份数',
      'required': true,
      'min': 1,
      'max': 100,
      'default': 1,
    },
    {
      'id': 'greeting',
      'kind': 'text',
      'label': '祝福语',
      'required': true,
      'maxLength': 128,
      'default': '恭喜发财，大吉大利',
    },
    {
      'id': 'designatedUserIds',
      'kind': 'members',
      'label': '收件人',
      'required': true,
      'min': 1,
      'max': 1,
      'showWhen': {
        'field': 'kind',
        'anyOf': ['exclusive'],
      },
    },
  ],
  'presentation': {
    'renderer': 'redPacket.compose',
    'props': props,
    'actions': bound,
  },
};

Map<String, Object?> detailsJson([Map<String, Object?> extra = const {}]) => {
  'viewerRole': 'eligible',
  'status': 'open',
  'kind': 'normal',
  'greeting': '祝福',
  'currency': 'CNY',
  'currencyExponent': 2,
  'claimedCount': 0,
  'shareCount': 1,
  'createdAtMs': 1000,
  'expiresAtMs': 100000,
  'claimsListed': false,
  ...extra,
};

Map<String, Object?> detailJson({
  Map<String, Object?>? details,
  Map<String, Object?> journal = const {},
  List<Map<String, Object?>> actions = const [
    {'id': 'claim', 'label': '领取红包'},
  ],
  Map<String, Object?> bound = const {'claim': 'claim'},
  List<Object?> claims = const [],
}) => {
  'available': true,
  'title': '红包详情',
  'actions': actions,
  'presentation': {
    'renderer': 'redPacket.detail',
    'props': {
      'details': details ?? detailsJson(),
      'claims': claims,
      'senderId': 'sender',
      'journal': journal,
    },
    'actions': bound,
  },
};

Map<String, Object?> reviewJson({
  Map<String, Object?> journal = const {},
  Map<String, Object?> bound = const {'submit': 'commit'},
  List<Map<String, Object?>> actions = const [
    {'id': 'commit', 'label': '发送红包'},
    {'id': 'recovery', 'label': '查看待确认操作'},
  ],
}) => {
  'available': true,
  'title': '发送已授权红包',
  'actions': actions,
  'blocks': [
    {'kind': 'note', 'text': '发送结果未知时请处理原操作，勿新建红包重复扣款。', 'tone': 'warning'},
  ],
  'presentation': {
    'renderer': 'redPacket.review',
    'props': {
      'amount': '8.88',
      'currency': 'CNY',
      'kind': 'lucky',
      'shareCount': 3,
      'blessing': '恭喜发财',
      'journal': journal,
    },
    'actions': bound,
  },
};

FlarePluginViewModel view(Map<String, Object?> json) =>
    FlarePluginViewModel.fromJson(json);

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

FlareRedPacketComposer composerOf(WidgetTester tester) =>
    tester.widget<FlareRedPacketComposer>(find.byType(FlareRedPacketComposer));

void main() {
  group('flareRedPacketReviewPlan', () {
    test('reads the bound submit and the packet facts', () {
      final plan = flareRedPacketReviewPlan(view(reviewJson()))!;
      expect(plan.action.id, 'commit');
      expect(plan.amount, '8.88');
      expect(plan.currency, 'CNY');
      expect(plan.kind, FlareRedPacketKind.lucky);
      expect(plan.shareCount, 3);
      expect(plan.blessing, '恭喜发财');
      expect(plan.ownedActionIds, ['commit']);
      expect(flareRedPacketPageDraws(view(reviewJson())), isTrue);
    });
    test('anything off draws the generic document', () {
      for (final json in [
        reviewJson(journal: {'commandId': 'c', 'known': false}),
        reviewJson(bound: const {}),
        reviewJson(
          actions: const [
            {
              'id': 'commit',
              'label': '发送红包',
              'form': ['x'],
            },
          ],
        ),
        reviewJson(
          actions: const [
            {'id': 'commit', 'label': '发送红包', 'confirm': '确定？'},
          ],
        ),
        {...reviewJson(), 'available': false},
        {
          ...reviewJson(),
          'presentation': {
            ...(reviewJson()['presentation'] as Map<String, Object?>),
            'renderer': 'redPacket.card',
          },
        },
      ]) {
        expect(flareRedPacketReviewPlan(view(json)), isNull, reason: '$json');
      }
      // The generic view then draws the document, not the review.
      expect(
        flareHasResolvedPresentation(
          view(reviewJson(journal: {'commandId': 'c', 'known': false})),
        ),
        isFalse,
      );
    });
  });

  group('FlareRedPacketPage review', () {
    testWidgets(
      'draws the review with its kind line and runs the bound submit; the rest stays below',
      (tester) async {
        tall(tester);
        final calls = <String>[];
        await tester.pumpWidget(
          host(
            FlareRedPacketPage(
              view: view(reviewJson()),
              onAction: (id, _) => calls.add(id),
            ),
          ),
        );
        final review = tester.widget<FlareRedPacketReview>(
          find.byType(FlareRedPacketReview),
        );
        expect(review.amount, '¥8.88');
        expect(review.kindLabel, '拼手气红包 · 3 个');
        expect(review.submitLabel, '发送红包');
        expect(find.text('发送结果未知时请处理原操作，勿新建红包重复扣款。'), findsOneWidget);
        expect(find.text('查看待确认操作'), findsOneWidget);
        await tester.tap(find.byKey(FlareRedPacketReview.submitKey));
        expect(calls, ['commit']);
      },
    );
    testWidgets('busy never sends again', (tester) async {
      tall(tester);
      var calls = 0;
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(reviewJson()),
            busyActionId: 'commit',
            onAction: (_, _) => calls++,
          ),
        ),
      );
      expect(
        tester
            .widget<FlareRedPacketReview>(find.byType(FlareRedPacketReview))
            .busy,
        isTrue,
      );
      tester
          .widget<FlareRedPacketReview>(find.byType(FlareRedPacketReview))
          .onSubmit!();
      expect(calls, 0);
    });
  });

  group('flareRedPacketComposePlan', () {
    test('reads the bound submit, its inputs and the offered kinds', () {
      final plan = flareRedPacketComposePlan(
        view(composeJson(props: {'maxRecipients': 4})),
      )!;
      expect(plan.action.id, 'prepare');
      expect(plan.inputs.map((i) => i.id), [
        'kind',
        'amount',
        'shareCount',
        'greeting',
        'designatedUserIds',
      ]);
      expect(plan.kinds, [
        FlareRedPacketKind.normal,
        FlareRedPacketKind.lucky,
        FlareRedPacketKind.exclusive,
      ]);
      expect(plan.currency, 'CNY');
      expect(plan.scale, 2);
      expect(plan.maxRecipients, 4);
      expect(plan.greetingDefault, '恭喜发财，大吉大利');
    });

    test('a direct conversation binds submitDirect with only normal', () {
      final plan = flareRedPacketComposePlan(
        view(
          composeJson(
            bound: {'submitDirect': 'prepareDirect'},
            actions: [
              {
                'id': 'prepareDirect',
                'label': '塞钱进红包',
                'form': ['amount', 'greeting'],
              },
            ],
          ),
        ),
      )!;
      expect(plan.action.id, 'prepareDirect');
      expect(plan.kinds, [FlareRedPacketKind.normal]);
    });

    test('anything off draws the generic document', () {
      Map<String, Object?> json() => composeJson();
      final cases = <String, Map<String, Object?>>{
        'another renderer': {
          ...json(),
          'presentation': {
            'renderer': 'redPacket.card',
            'props': {},
            'actions': {},
          },
        },
        'no presentation': {...json()}..remove('presentation'),
        'unavailable': {...json(), 'available': false},
        'payments unavailable (no bound submit)': composeJson(bound: {}),
        'an unknown original command': composeJson(
          props: {
            'journal': {'commandId': 'original', 'known': false},
          },
        ),
        'a confirm': composeJson(
          actions: [
            {
              'id': 'prepare',
              'label': 'x',
              'confirm': 'Sure?',
              'form': ['amount', 'greeting'],
            },
          ],
        ),
        'a native target': composeJson(
          actions: [
            {
              'id': 'prepare',
              'label': 'x',
              'target': {'kind': 'native', 'capability': 'camera'},
              'form': ['amount', 'greeting'],
            },
          ],
        ),
        'a missing input': composeJson(
          actions: [
            {
              'id': 'prepare',
              'label': 'x',
              'form': ['amount', 'greeting', 'nowhere'],
            },
          ],
        ),
        'no greeting': composeJson(
          actions: [
            {
              'id': 'prepare',
              'label': 'x',
              'form': ['amount'],
            },
          ],
        ),
      };
      for (final entry in cases.entries) {
        expect(
          flareRedPacketComposePlan(view(entry.value)),
          isNull,
          reason: entry.key,
        );
      }
      final unknownKind = composeJson();
      ((unknownKind['inputs'] as List).first as Map)['choices'] = [
        {'value': 'normal', 'label': '普通'},
        {'value': 'mystery', 'label': '?'},
      ];
      expect(flareRedPacketComposePlan(view(unknownKind)), isNull);
    });
  });

  group('flareRedPacketDetailPlan', () {
    test(
      'validates the details and reads claims, sender and bound actions',
      () {
        final plan = flareRedPacketDetailPlan(
          view(
            detailJson(
              details: detailsJson({
                'viewerRole': 'claimer',
                'status': 'completed',
                'myAmountMinor': '88',
                'completedInMs': 500,
                'designatedUserIds': ['bob'],
              }),
              actions: [
                {'id': 'claim', 'label': '领取红包'},
                {'id': 'wallet', 'label': '查看钱包'},
                {'id': 'cancel', 'label': '取消', 'confirm': 'Sure?'},
              ],
              bound: {'claim': 'claim', 'wallet': 'wallet'},
              claims: [
                {
                  'id': 'bob',
                  'amountMinor': '88',
                  'claimedAtMs': 2000,
                  'best': true,
                },
                {'id': 'bad', 'amountMinor': 'x', 'claimedAtMs': 2000},
                {'id': 7, 'amountMinor': '1', 'claimedAtMs': 2000},
              ],
              journal: {
                'known': false,
                'capabilityId': 'flare.redpacket.ui.claim',
              },
            ),
          ),
        )!;
        expect(plan.details.viewerRole, FlareRedPacketViewerRole.claimer);
        expect(plan.details.completedAtMs, 1500);
        expect(plan.claims.map((c) => c.id), ['bob']);
        expect(plan.claims.single.best, isTrue);
        expect(plan.senderId, 'sender');
        expect(plan.designatedUserIds, ['bob']);
        expect(plan.claimAction?.id, 'claim');
        expect(plan.walletAction?.id, 'wallet');
        expect(plan.ownedActionIds, ['claim', 'wallet']);
        expect(plan.paidClaimPending, isTrue);
      },
    );

    test('a claim with a confirm stays generic', () {
      final plan = flareRedPacketDetailPlan(
        view(
          detailJson(
            actions: [
              {'id': 'claim', 'label': '领取红包', 'confirm': 'Sure?'},
            ],
          ),
        ),
      )!;
      expect(plan.claimAction, isNull);
      expect(plan.ownedActionIds, isEmpty);
    });

    test('incomplete details draw the generic document', () {
      for (final bad in <Map<String, Object?>>[
        {'myAmountMinor': 'not-money'},
        {'viewerRole': 'stranger'},
        {'status': 'funding'},
        {'kind': 'mystery'},
        {'currency': ''},
        {'currencyExponent': 13},
        {'shareCount': -1},
        {'claimsListed': 'yes'},
      ]) {
        expect(
          flareRedPacketDetailPlan(view(detailJson(details: detailsJson(bad)))),
          isNull,
          reason: '$bad',
        );
      }
      expect(
        flareRedPacketDetailPlan(view(composeJson())),
        isNull,
        reason: 'another renderer',
      );
    });
  });

  group('FlareRedPacketPage compose', () {
    testWidgets(
      'exact totals, an over-limit group total is refused, then the bound submit carries the form values',
      (tester) async {
        tall(tester);
        final calls = <(String, FlarePluginActionPayload)>[];
        await tester.pumpWidget(
          host(
            FlareRedPacketPage(
              view: view(composeJson()),
              onAction: (id, payload) => calls.add((id, payload)),
            ),
          ),
        );
        composerOf(tester).onAmountChange!('6.00');
        await tester.pump();
        composerOf(tester).onCountChange!(2);
        await tester.pump();
        expect(composerOf(tester).total, '¥12.00');
        composerOf(tester).onSubmit!();
        await tester.pump();
        expect(calls, isEmpty);
        expect(composerOf(tester).errorField, FlareRedPacketField.amount);
        composerOf(tester).onAmountChange!('0.01');
        await tester.pump();
        composerOf(tester).onSubmit!();
        expect(calls.single.$1, 'prepare');
        expect(calls.single.$2.formValues, {
          'kind': 'normal',
          'amount': {'amount': '0.01', 'currency': 'CNY'},
          'shareCount': 2,
          'greeting': '恭喜发财，大吉大利',
        });
      },
    );

    testWidgets('a group shows its head count; a direct chat none', (
      tester,
    ) async {
      tall(tester);
      const members = [
        FlarePluginMember(userId: 'a', name: 'A'),
        FlarePluginMember(userId: 'b', name: 'B'),
        FlarePluginMember(userId: 'c', name: 'C'),
      ];
      // The host's group size (viewer included), never the member rows.
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(composeJson()),
            members: members,
            memberCount: 12,
          ),
        ),
      );
      expect(composerOf(tester).memberCount, 12);
      await tester.pumpWidget(
        host(FlareRedPacketPage(view: view(composeJson()), members: members)),
      );
      expect(composerOf(tester).memberCount, isNull);
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(
              composeJson(
                bound: {'submitDirect': 'prepareDirect'},
                actions: [
                  {
                    'id': 'prepareDirect',
                    'label': '塞钱进红包',
                    'form': ['amount', 'greeting'],
                  },
                ],
              ),
            ),
            members: members,
            memberCount: 2,
          ),
        ),
      );
      expect(composerOf(tester).memberCount, isNull);
    });

    testWidgets(
      'the draft survives the page reading itself again (back from the wallet)',
      (tester) async {
        tall(tester);
        Widget page() => host(FlareRedPacketPage(view: view(composeJson())));
        await tester.pumpWidget(page());
        composerOf(tester).onAmountChange!('0.66');
        composerOf(tester).onGreetingChange!('留着');
        await tester.pump();
        // R4 return: a new view of the same page arrives.
        await tester.pumpWidget(page());
        expect(composerOf(tester).amount, '0.66');
        expect(composerOf(tester).greeting, '留着');
      },
    );

    testWidgets('a quantity over the live limit stays on the form', (
      tester,
    ) async {
      tall(tester);
      var calls = 0;
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(composeJson(props: {'maxRecipients': 4})),
            onAction: (_, _) => calls++,
          ),
        ),
      );
      composerOf(tester).onAmountChange!('0.08');
      composerOf(tester).onCountChange!(8);
      await tester.pump();
      composerOf(tester).onSubmit!();
      await tester.pump();
      expect(calls, 0);
      expect(composerOf(tester).errorField, FlareRedPacketField.count);
      expect(composerOf(tester).error, '最多可发 4 个红包');
    });

    testWidgets('an exclusive packet without a recipient marks the recipient', (
      tester,
    ) async {
      tall(tester);
      var calls = 0;
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(composeJson()),
            onAction: (_, _) => calls++,
          ),
        ),
      );
      composerOf(tester).onKindChange!(FlareRedPacketKind.exclusive);
      composerOf(tester).onAmountChange!('1.00');
      await tester.pump();
      composerOf(tester).onSubmit!();
      await tester.pump();
      expect(calls, 0);
      expect(composerOf(tester).errorField, FlareRedPacketField.recipient);
      expect(composerOf(tester).error, '请选择发给谁');
    });

    testWidgets('busy never submits; a host error stays form-wide', (
      tester,
    ) async {
      tall(tester);
      var calls = 0;
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(composeJson()),
            busyActionId: 'prepare',
            error: '网络暂不可用',
            onAction: (_, _) => calls++,
          ),
        ),
      );
      composerOf(tester).onAmountChange!('0.01');
      await tester.pump();
      composerOf(tester).onSubmit!();
      await tester.pump();
      expect(calls, 0);
      expect(composerOf(tester).busy, isTrue);
      expect(composerOf(tester).errorField, FlareRedPacketField.form);
    });

    testWidgets('a direct conversation submits only amount and greeting', (
      tester,
    ) async {
      tall(tester);
      final calls = <FlarePluginActionPayload>[];
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(
              composeJson(
                bound: {'submitDirect': 'prepareDirect'},
                actions: [
                  {
                    'id': 'prepareDirect',
                    'label': '塞钱进红包',
                    'form': ['amount', 'greeting'],
                  },
                ],
              ),
            ),
            onAction: (_, payload) => calls.add(payload),
          ),
        ),
      );
      expect(composerOf(tester).kinds, [FlareRedPacketKind.normal]);
      composerOf(tester).onAmountChange!('0.01');
      await tester.pump();
      composerOf(tester).onSubmit!();
      expect(calls.single.formValues, {
        'amount': {'amount': '0.01', 'currency': 'CNY'},
        'greeting': '恭喜发财，大吉大利',
      });
    });
  });

  group('FlareRedPacketPage detail', () {
    testWidgets(
      'a claimable packet opens the sheet; 開 claims through the host',
      (tester) async {
        tall(tester);
        final calls = <String>[];
        await tester.pumpWidget(
          host(
            FlareRedPacketPage(
              view: view(detailJson()),
              nowMs: 5000,
              onAction: (id, _) => calls.add(id),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(FlareRedPacketDetail), findsOneWidget);
        expect(find.byType(FlareRedPacketOpenSheet), findsOneWidget);
        await tester.tap(find.byKey(FlareRedPacketOpenSheet.coinKey));
        expect(calls, ['claim']);
      },
    );

    testWidgets('while claiming the sheet opens and cannot close', (
      tester,
    ) async {
      tall(tester);
      var closed = 0;
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(detailJson()),
            busyActionId: 'claim',
            nowMs: 5000,
            onAction: (_, _) {},
            onBack: () => closed++,
          ),
        ),
      );
      await tester.pump();
      final sheet = tester.widget<FlareRedPacketOpenSheet>(
        find.byType(FlareRedPacketOpenSheet),
      );
      expect(sheet.state, FlareRedPacketOpenState.opening);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 0);
    });

    testWidgets(
      'a failed claim reviews the result by refreshing, without claiming again',
      (tester) async {
        tall(tester);
        var refreshes = 0;
        final calls = <String>[];
        await tester.pumpWidget(
          host(
            FlareRedPacketPage(
              view: view(detailJson()),
              error: '结果暂未确认',
              nowMs: 5000,
              onAction: (id, _) => calls.add(id),
              onRefresh: () => refreshes++,
            ),
          ),
        );
        await tester.pump();
        final sheet = tester.widget<FlareRedPacketOpenSheet>(
          find.byType(FlareRedPacketOpenSheet),
        );
        expect(sheet.reviewOnError, isTrue);
        expect(sheet.state, FlareRedPacketOpenState.error);
        sheet.onViewDetails!();
        await tester.pump();
        expect(refreshes, 1);
        expect(calls, isEmpty);
        expect(find.byType(FlareRedPacketOpenSheet), findsNothing);
        expect(find.byKey(FlareRedPacketPage.claimKey), findsOneWidget);
      },
    );

    testWidgets('a paid claim still unconfirmed warns instead of failing', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(
              detailJson(
                actions: const [],
                bound: const {},
                details: detailsJson({
                  'viewerRole': 'claimer',
                  'status': 'completed',
                  'claimedCount': 1,
                  'myAmountMinor': '1',
                  'claimsListed': true,
                }),
                journal: {
                  'known': false,
                  'commandId': 'original',
                  'capabilityId': 'flare.redpacket.ui.claim',
                },
              ),
            ),
            error: '结果暂未确认，请稍后查看',
            nowMs: 5000,
          ),
        ),
      );
      await tester.pump();
      final banner = tester.widget<FlareStatusBanner>(
        find.byType(FlareStatusBanner),
      );
      expect(banner.tone, FlareStatusTone.warning);
      expect(banner.text, const FlareStrings().packetClaimPendingReview);
      expect(find.byType(FlareRedPacketOpenSheet), findsNothing);
    });

    testWidgets('the bound wallet action opens the wallet from 已存入钱包', (
      tester,
    ) async {
      tall(tester);
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          FlareRedPacketPage(
            view: view(
              detailJson(
                actions: const [
                  {'id': 'wallet', 'label': '查看钱包'},
                  {'id': 'cancel', 'label': '取消'},
                ],
                bound: const {'wallet': 'wallet'},
                details: detailsJson({
                  'viewerRole': 'claimer',
                  'status': 'completed',
                  'myAmountMinor': '1',
                }),
              ),
            ),
            nowMs: 5000,
            onAction: (id, _) => calls.add(id),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(FlareRedPacketDetail.depositedKey));
      expect(calls, ['wallet']);
      // The unowned action stays in the generic list below.
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('查看钱包'), findsNothing);
    });
  });

  group('FlarePluginPage routes by renderer', () {
    FlarePluginPageViewModel pageView(Map<String, Object?> json) =>
        FlarePluginPageViewModel.fromJson(json);

    testWidgets('redPacket.compose draws the kit composer', (tester) async {
      tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlarePluginPage(
              page: const FlarePluginPageRef(
                pluginId: 'any.plugin',
                page: 'any.page',
              ),
              view: pageView(composeJson()),
              onAction: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlareRedPacketPage), findsOneWidget);
      expect(find.byType(FlareRedPacketComposer), findsOneWidget);
    });

    testWidgets('redPacket.review draws the kit review on the page', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlarePluginPage(
              page: const FlarePluginPageRef(
                pluginId: 'any.plugin',
                page: 'any.page',
              ),
              view: pageView(reviewJson()),
              onAction: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlareRedPacketReview), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlarePluginPage(
              page: const FlarePluginPageRef(
                pluginId: 'any.plugin',
                page: 'any.page',
              ),
              view: pageView(
                reviewJson(journal: {'commandId': 'c', 'known': false}),
              ),
              onAction: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlareRedPacketReview), findsNothing);
      expect(find.text('查看待确认操作'), findsOneWidget);
    });

    testWidgets('a refused mapping draws the generic document', (tester) async {
      tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlarePluginPage(
              page: const FlarePluginPageRef(
                pluginId: 'any.plugin',
                page: 'any.page',
              ),
              view: pageView(composeJson(bound: {})),
              onAction: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlareRedPacketPage), findsNothing);
      expect(find.byType(FlareRedPacketComposer), findsNothing);
    });
  });
}
