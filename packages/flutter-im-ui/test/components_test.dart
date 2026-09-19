import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('FlareAvatar', () {
    testWidgets('renders initials when no image', (tester) async {
      await tester.pumpWidget(
        _host(const FlareAvatar(userId: 'u1', displayName: 'Henry Ford')),
      );
      expect(find.text('HF'), findsOneWidget);
    });

    testWidgets('shows a presence dot when presence is set', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareAvatar(
            userId: 'u1',
            displayName: 'Ivy',
            presence: FlarePresence.online,
          ),
        ),
      );
      // avatar container + presence dot container
      expect(find.byType(Container), findsNWidgets(2));
    });

    testWidgets('falls back to ? for a blank name', (tester) async {
      await tester.pumpWidget(
        _host(const FlareAvatar(userId: 'u1', displayName: '   ')),
      );
      expect(find.text('?'), findsOneWidget);
    });
  });

  testWidgets('FlareDatePill renders its label', (tester) async {
    await tester.pumpWidget(_host(const FlareDatePill(label: '今天')));
    expect(find.text('今天'), findsOneWidget);
  });

  group('FlareMessageStatus', () {
    testWidgets('read shows the double-tick', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageStatus(status: FlareMessageDeliveryStatus.read),
        ),
      );
      expect(find.byKey(FlareMessageStatus.doubleCheckKey), findsOneWidget);
      expect(
        find.bySemanticsLabel(const FlareStrings().messageRead),
        findsOneWidget,
      );
    });

    testWidgets('failed shows the error glyph', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageStatus(status: FlareMessageDeliveryStatus.failed),
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('pending shows a static clock', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageStatus(status: FlareMessageDeliveryStatus.pending),
        ),
      );
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('sending shows subtle progress', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageStatus(status: FlareMessageDeliveryStatus.sending),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('pending uses a static semantic state with reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(
            body: FlareMessageStatus(
              status: FlareMessageDeliveryStatus.pending,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('failed + onResend is a tappable retry control', (
      tester,
    ) async {
      var resent = 0;
      await tester.pumpWidget(
        _host(
          FlareMessageStatus(
            status: FlareMessageDeliveryStatus.failed,
            onResend: () => resent++,
          ),
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '${const FlareStrings().messageFailed}, ${const FlareStrings().retry}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.error_outline));
      expect(resent, 1);
    });

    testWidgets('without onResend the failed glyph is inert', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageStatus(status: FlareMessageDeliveryStatus.failed),
        ),
      );
      expect(find.byType(GestureDetector), findsNothing);
      expect(
        find.bySemanticsLabel(const FlareStrings().messageFailed),
        findsOneWidget,
      );
    });

    testWidgets('onResend is ignored for non-failed states', (tester) async {
      var resent = 0;
      await tester.pumpWidget(
        _host(
          FlareMessageStatus(
            status: FlareMessageDeliveryStatus.sent,
            onResend: () => resent++,
          ),
        ),
      );
      expect(resent, 0);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  testWidgets(
    'FlareMessageMeta composes time, mutation, ephemeral and receipt',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageMeta(
            timestamp: '14:32',
            edited: true,
            ephemeral: FlareMessageEphemeralState.burnAfterRead,
            status: FlareMessageDeliveryStatus.delivered,
          ),
        ),
      );
      expect(find.text('14:32 · 已编辑 · 阅后即焚'), findsOneWidget);
      expect(find.byKey(FlareMessageStatus.doubleCheckKey), findsOneWidget);
    },
  );

  group('FlareToast', () {
    testWidgets('shows a close button only when onClose is given', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const FlareToast(message: 'saved')));
      expect(find.text('saved'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('close button fires onClose', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        _host(
          FlareToast(
            message: 'saved',
            actionLabel: 'Undo',
            onAction: () {},
            onClose: () => closed++,
          ),
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.bySemanticsLabel(const FlareStrings().close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, 1);
      // the inline action is still there next to the close button
      expect(find.text('Undo'), findsOneWidget);
    });
  });

  testWidgets('FlareColors.of switches on brightness', (tester) async {
    expect(
      FlareColors.of(Brightness.light).bgPrimary,
      isNot(FlareColors.of(Brightness.dark).bgPrimary),
    );
  });

  test(
    'all brands expose distinct message semantics and support overrides',
    () {
      final outgoing = FlareBrandTheme.values
          .map(
            (brand) => FlareColors.resolve(
              Brightness.light,
              brand: brand,
            ).messageOutgoingBackground,
          )
          .toSet();
      final read = FlareBrandTheme.values
          .map(
            (brand) => FlareColors.resolve(
              Brightness.light,
              brand: brand,
            ).messageStatusRead,
          )
          .toSet();
      expect(outgoing, hasLength(FlareBrandTheme.values.length));
      expect(read, hasLength(FlareBrandTheme.values.length));

      const customPrimary = Color(0xFF0057B8);
      final custom = FlareColors.oceanLight.copyWith(primary: customPrimary);
      expect(custom.primary, customPrimary);
      expect(
        custom.messageOutgoingBackground,
        FlareColors.oceanLight.messageOutgoingBackground,
      );
    },
  );

  group('FlareFilterTabs', () {
    const options = [
      FlareFilterTabOption(value: 'all', label: 'All'),
      FlareFilterTabOption(value: 'unread', label: 'Unread', badge: 3),
      FlareFilterTabOption(value: 'mention', label: 'Mentions'),
    ];

    testWidgets('renders every option label and the badge', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareFilterTabs(options: options, selected: 'all', onSelect: (_) {}),
        ),
      );
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Mentions'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping an option reports its value', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          FlareFilterTabs(
            options: options,
            selected: 'all',
            onSelect: (value) => picked = value,
          ),
        ),
      );
      await tester.tap(find.text('Mentions'));
      expect(picked, 'mention');
    });

    testWidgets('honours a custom content padding', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareFilterTabs(
            options: options,
            selected: 'all',
            onSelect: (_) {},
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          ),
        ),
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scroll.padding,
        const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      );
    });
  });

  group('FlareEmptyState', () {
    testWidgets('loading renders a spinner in place of the icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareEmptyState(title: 'Loading', icon: 'chats', loading: true),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(flareIconMap['chats']!), findsNothing);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('renders the glyph when not loading', (tester) async {
      await tester.pumpWidget(
        _host(const FlareEmptyState(title: 'Empty', icon: 'chats')),
      );
      expect(find.byIcon(flareIconMap['chats']!), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('onTap fires when the card is tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(FlareEmptyState(title: 'Tap me', onTap: () => tapped += 1)),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, 1);
    });

    testWidgets('iconWidget replaces the default glyph', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareEmptyState(
            title: 'Custom',
            icon: 'chats',
            iconWidget: Icon(Icons.rocket_launch),
          ),
        ),
      );
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
      expect(find.byIcon(flareIconMap['chats']!), findsNothing);
    });

    testWidgets('actions put the host controls under the text, in one row', (
      tester,
    ) async {
      var invited = 0;
      await tester.pumpWidget(
        _host(
          FlareEmptyState(
            title: '还没有联系人',
            actions: [
              OutlinedButton(
                onPressed: () => invited += 1,
                child: const Text('邀请同事'),
              ),
              const OutlinedButton(onPressed: null, child: Text('扫一扫')),
            ],
          ),
        ),
      );
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('邀请同事'), findsOneWidget);
      await tester.tap(find.text('邀请同事'));
      expect(invited, 1);
    });

    testWidgets('no actions, no row: an empty list takes no space', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const FlareEmptyState(title: 'Empty')));
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('actionText and actions can both be there', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareEmptyState(
            title: 'Empty',
            actionText: '重试',
            actions: [OutlinedButton(onPressed: null, child: Text('邀请同事'))],
          ),
        ),
      );
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('邀请同事'), findsOneWidget);
    });
  });

  group('FlareIconButton', () {
    testWidgets('tintColor overrides the glyph color', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareIconButton(
            icon: 'search',
            semanticLabel: 'search',
            tintColor: const Color(0xFF123456),
            onPressed: () {},
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.search));
      expect(icon.color, const Color(0xFF123456));
    });

    testWidgets('backgroundColor overrides the container color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareIconButton(
            icon: 'add',
            semanticLabel: 'add',
            backgroundColor: const Color(0xFF00FF00),
            onPressed: () {},
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF00FF00));
    });

    testWidgets('customSize sets the side and derived glyph size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareIconButton(
            icon: 'close',
            semanticLabel: 'close',
            customSize: 48,
            onPressed: () {},
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(container.constraints?.maxWidth, 48);
      final icon = tester.widget<Icon>(find.byIcon(Icons.close));
      // round(48 * 0.46) = round(22.08) = 22
      expect(icon.size, 22);
    });
  });

  group('FlareEmptyState', () {
    testWidgets('tone:error tints the title with the error color and shows '
        'a long description', (tester) async {
      const longDescription =
          'Failed to load: connection reset by peer while fetching '
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa '
          'the remote endpoint after several retries and a very long token '
          'thatdoesnotcontainanyspacesandmustwrapgracefullyacrossmultiplelines.';
      await tester.pumpWidget(
        _host(
          const FlareEmptyState(
            title: 'Something went wrong',
            description: longDescription,
            tone: FlareEmptyStateTone.error,
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text(longDescription), findsOneWidget);

      final errorColor = FlareColors.of(Brightness.light).error;
      final titleText = tester.widget<Text>(find.text('Something went wrong'));
      expect(titleText.style?.color, errorColor);
    });
  });

  group('FlareSettingsList select kind', () {
    testWidgets('select rows show a check only on the selected item', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareSettingsList(
            sections: const [
              FlareSettingsSection(
                items: [
                  FlareSettingsItem(
                    key: 'zh',
                    label: '简体中文',
                    kind: FlareSettingKind.select,
                    value: true,
                  ),
                  FlareSettingsItem(
                    key: 'en',
                    label: 'English',
                    kind: FlareSettingKind.select,
                    value: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping a select row reports its item', (tester) async {
      FlareSettingsItem? picked;
      await tester.pumpWidget(
        _host(
          FlareSettingsList(
            sections: const [
              FlareSettingsSection(
                items: [
                  FlareSettingsItem(
                    key: 'en',
                    label: 'English',
                    kind: FlareSettingKind.select,
                    value: false,
                  ),
                ],
              ),
            ],
            onSelect: (item) => picked = item,
          ),
        ),
      );
      await tester.tap(find.text('English'));
      expect(picked?.key, 'en');
    });
  });
}
