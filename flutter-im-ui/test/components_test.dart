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
        _host(const FlareAvatar(
          userId: 'u1',
          displayName: 'Ivy',
          presence: FlarePresence.online,
        )),
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

  testWidgets('FlareTimeStamp renders its label', (tester) async {
    await tester.pumpWidget(_host(const FlareTimeStamp(label: '刚刚')));
    expect(find.text('刚刚'), findsOneWidget);
  });

  group('FlareMessageStatus', () {
    testWidgets('read shows the double-tick', (tester) async {
      await tester.pumpWidget(
        _host(const FlareMessageStatus(
          status: FlareMessageDeliveryStatus.read,
        )),
      );
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('failed shows the error glyph', (tester) async {
      await tester.pumpWidget(
        _host(const FlareMessageStatus(
          status: FlareMessageDeliveryStatus.failed,
        )),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('pending shows a spinner', (tester) async {
      await tester.pumpWidget(
        _host(const FlareMessageStatus(
          status: FlareMessageDeliveryStatus.pending,
        )),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('FlareColors.of switches on brightness', (tester) async {
    expect(FlareColors.of(Brightness.light).bgPrimary,
        isNot(FlareColors.of(Brightness.dark).bgPrimary));
  });
}
