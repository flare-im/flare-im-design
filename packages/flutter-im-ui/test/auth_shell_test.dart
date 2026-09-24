import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile auth shell fills the safe body from the top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlareAuthShell(
            product: 'Flare',
            tagline: 'Safe and reliable',
            title: 'Sign in',
            subtitle: 'Welcome back',
            child: Text('Form'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Flare'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Flare')).dy, lessThan(100));
  });
}
