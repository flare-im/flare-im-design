import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Widget child, {
  FlareStrings strings = const FlareStrings(),
  bool reduceMotion = false,
}) => MaterialApp(
  home: FlareStringsScope(
    strings: strings,
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  final events = <String>[];
  setUp(events.clear);

  FlareRedPacketOpenSheet sheet({
    FlareRedPacketOpenState state = FlareRedPacketOpenState.ready,
    String? message,
    String? kindLabel,
    bool closable = true,
  }) => FlareRedPacketOpenSheet(
    senderName: '小明',
    blessing: '恭喜发财，大吉大利',
    kindLabel: kindLabel,
    state: state,
    message: message,
    onOpen: () => events.add('open'),
    onViewDetails: () => events.add('viewDetails'),
    onClose: closable ? () => events.add('close') : null,
  );

  final coin = find.byKey(FlareRedPacketOpenSheet.coinKey);

  testWidgets('ready offers 開 under the sender and the blessing', (
    tester,
  ) async {
    await tester.pumpWidget(host(sheet(kindLabel: '拼手气红包')));
    expect(find.text('小明的红包'), findsOneWidget);
    expect(find.text('拼手气红包'), findsOneWidget);
    expect(find.text('恭喜发财，大吉大利'), findsOneWidget);
    expect(find.text('開'), findsOneWidget);
    expect(find.text('查看领取详情'), findsNothing);
    await tester.tap(coin);
    expect(events, ['open']);
  });

  testWidgets('the coin sits on the seam of the flap', (tester) async {
    await tester.pumpWidget(host(sheet()));
    final coinRect = tester.getRect(coin);
    final blessing = tester.getRect(find.text('恭喜发财，大吉大利'));
    expect(coinRect.top, greaterThan(blessing.bottom));
    expect(coinRect.width, FlareSizes.componentRedPacketOpenButtonSize);
  });

  testWidgets('opening flips the coin and refuses a second press', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(sheet(state: FlareRedPacketOpenState.opening)),
    );
    await tester.pump(const Duration(milliseconds: 225));
    final transform = tester.widget<Transform>(
      find.ancestor(of: coin, matching: find.byType(Transform)).first,
    );
    expect(transform.transform.storage[0], isNot(closeTo(1, 0.01)));
    await tester.tap(coin, warnIfMissed: false);
    expect(events, isEmpty);
    // Back to ready: the coin stops face-on.
    await tester.pumpWidget(host(sheet()));
    final settled = tester.widget<Transform>(
      find.ancestor(of: coin, matching: find.byType(Transform)).first,
    );
    expect(settled.transform.storage[0], closeTo(1, 0.0001));
  });

  testWidgets('reduced motion spins on the coin instead of flipping it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(sheet(state: FlareRedPacketOpenState.opening), reduceMotion: true),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.descendant(
        of: coin,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text('開'), findsNothing);
    final transform = tester.widget<Transform>(
      find.ancestor(of: coin, matching: find.byType(Transform)).first,
    );
    expect(transform.transform.storage[0], closeTo(1, 0.0001));
  });

  for (final entry in [
    (FlareRedPacketOpenState.finished, '手慢了，红包派完了'),
    (FlareRedPacketOpenState.expired, '红包已过期'),
    (FlareRedPacketOpenState.refunded, '红包已退回'),
  ]) {
    testWidgets('${entry.$1.name} says why and links to the details', (
      tester,
    ) async {
      await tester.pumpWidget(host(sheet(state: entry.$1)));
      expect(coin, findsNothing);
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('恭喜发财，大吉大利'), findsNothing);
      await tester.tap(find.text('查看领取详情'));
      expect(events, ['viewDetails']);
    });

    testWidgets('${entry.$1.name} without canViewDetails has no details key', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FlareRedPacketOpenSheet(
            senderName: '小明',
            blessing: '恭喜发财，大吉大利',
            state: entry.$1,
            canViewDetails: false,
            onViewDetails: () => events.add('viewDetails'),
          ),
        ),
      );
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('查看领取详情'), findsNothing);
    });
  }

  testWidgets(
    'refunded reads the refunded notice in English, or the host text',
    (tester) async {
      await tester.pumpWidget(
        host(
          sheet(state: FlareRedPacketOpenState.refunded),
          strings: flareStringsEnglish,
        ),
      );
      // §4.5 copy.
      expect(find.text('Returned to sender'), findsOneWidget);
      expect(coin, findsNothing);
      await tester.pumpWidget(
        host(sheet(state: FlareRedPacketOpenState.refunded, message: '已退回钱包')),
      );
      expect(find.text('已退回钱包'), findsOneWidget);
    },
  );

  testWidgets('notEligible says why and never offers the details', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(sheet(state: FlareRedPacketOpenState.notEligible)),
    );
    expect(coin, findsNothing);
    expect(find.text('你不能领取这个红包'), findsOneWidget);
    // The server returns no amounts or records to a non-designated viewer.
    expect(find.text('查看领取详情'), findsNothing);
  });

  testWidgets('a host notice replaces the default copy', (tester) async {
    await tester.pumpWidget(
      host(
        sheet(state: FlareRedPacketOpenState.notEligible, message: '仅 TA 可领取'),
      ),
    );
    expect(find.text('仅 TA 可领取'), findsOneWidget);
    expect(find.text('你不能领取这个红包'), findsNothing);
    final notice = tester.widget<Text>(find.text('仅 TA 可领取'));
    expect(notice.maxLines, 3);
    expect(notice.style!.height, FlareSizes.lineHeightNormal);
  });

  testWidgets('an error keeps 開 for a retry and says what failed', (
    tester,
  ) async {
    await tester.pumpWidget(host(sheet(state: FlareRedPacketOpenState.error)));
    // §4.5 copy.
    expect(find.text('没有领到，请重试'), findsOneWidget);
    final error = tester.widget<Text>(find.text('没有领到，请重试'));
    expect(error.maxLines, 3);
    expect(error.style!.height, FlareSizes.lineHeightNormal);
    expect(find.text('恭喜发财，大吉大利'), findsOneWidget);
    await tester.tap(coin);
    expect(events, ['open']);
  });

  testWidgets('reviewOnError: the error key reads 查看结果 and views details', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareRedPacketOpenSheet(
          senderName: '小明',
          blessing: '恭喜发财，大吉大利',
          state: FlareRedPacketOpenState.error,
          reviewOnError: true,
          onOpen: () => events.add('open'),
          onViewDetails: () => events.add('viewDetails'),
          onClose: () => events.add('close'),
        ),
      ),
    );
    expect(coin, findsNothing);
    expect(find.text('查看领取详情'), findsNothing);
    await tester.tap(find.text('查看结果'));
    expect(events, ['viewDetails']);
  });

  testWidgets('scrim, close control and Escape close; the envelope does not', (
    tester,
  ) async {
    await tester.pumpWidget(host(sheet()));
    await tester.tap(find.text('恭喜发财，大吉大利'));
    expect(events, isEmpty);
    await tester.tapAt(const Offset(8, 8));
    await tester.tap(find.byType(FlareIconButton));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(events, ['close', 'close', 'close']);
  });

  testWidgets('the 36 close key sits in the envelope top trailing corner', (
    tester,
  ) async {
    await tester.pumpWidget(host(sheet()));
    final close = find.byType(FlareIconButton);
    expect(
      tester.widget<FlareIconButton>(close).customSize,
      FlareSizes.componentRedPacketCloseSize,
    );
    expect(tester.widget<FlareIconButton>(close).semanticLabel, '关闭');
    expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
    final title = find.text('小明的红包');
    expect(tester.getCenter(close).dy, lessThan(tester.getCenter(title).dy));
    expect(tester.getCenter(close).dx, greaterThan(tester.getCenter(title).dx));
    expect(tester.getCenter(close).dy, lessThan(tester.getCenter(coin).dy));
  });

  testWidgets('nothing closes it while it opens', (tester) async {
    await tester.pumpWidget(
      host(sheet(state: FlareRedPacketOpenState.opening), reduceMotion: true),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.tap(find.byType(FlareIconButton), warnIfMissed: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(events, isEmpty);
    expect(
      tester.widget<FlareIconButton>(find.byType(FlareIconButton)).disabled,
      isTrue,
    );
  });

  testWidgets(
    '§4.5 type: 56 sender, 15/600 title, 20/600 blessing on two lines',
    (tester) async {
      await tester.pumpWidget(host(sheet()));
      expect(
        tester.widget<FlareAvatar>(find.byType(FlareAvatar)).size,
        FlareSizes.componentRedPacketDetailAvatarSize,
      );
      final title = tester.widget<Text>(find.text('小明的红包'));
      expect(title.style!.fontSize, FlareSizes.fontSizeXl);
      expect(title.style!.fontWeight, FontWeight.w600);
      final blessing = tester.widget<Text>(find.text('恭喜发财，大吉大利'));
      expect(blessing.style!.fontSize, FlareSizes.fontSize4xl);
      expect(blessing.maxLines, 2);
    },
  );

  testWidgets('show() puts it on a route; back and Escape go through onClose', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    var closed = 0;
    final route = FlareRedPacketOpenSheet.show<void>(
      context,
      builder: (routeContext) => FlareRedPacketOpenSheet(
        senderName: '小明',
        blessing: '恭喜发财',
        onClose: () {
          closed += 1;
          Navigator.of(routeContext).pop();
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('小明的红包'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await route;
    expect(closed, 1);
    expect(find.text('小明的红包'), findsNothing);
  });

  testWidgets('without onClose the scrim pops its route', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    FlareRedPacketOpenSheet.show<void>(
      context,
      builder: (_) =>
          const FlareRedPacketOpenSheet(senderName: '小明', blessing: '恭喜发财'),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('小明的红包'), findsNothing);
  });

  testWidgets('English sets the word smaller and names the coin', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host(sheet(), strings: flareStringsEnglish));
      expect(find.text('Red packet from 小明'), findsOneWidget);
      final word = tester.widget<Text>(find.text('Open'));
      expect(word.style!.fontSize, FlareSizes.fontSize3xl);
      expect(find.bySemanticsLabel('Open'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('fits a $width-wide window with large text', (tester) async {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 760),
              textScaler: const TextScaler.linear(1.8),
            ),
            child: Scaffold(
              body: sheet(
                state: FlareRedPacketOpenState.finished,
                kindLabel: '拼手气红包',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final envelope = tester.getRect(find.text('小明的红包'));
      expect(envelope.left, greaterThanOrEqualTo(0));
      expect(envelope.right, lessThanOrEqualTo(width));
    });
  }

  testWidgets('§4.5 Enter or Space on the focused 開 opens it', (tester) async {
    await tester.pumpWidget(host(sheet()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(events, ['open', 'open']);
  });
}
