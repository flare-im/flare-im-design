import 'dart:convert';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1×1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  testWidgets(
    'a picture still loading shows the placeholder, not an empty hole',
    (tester) async {
      final src = 'data:image/png;base64,${base64Encode(_png)}';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FlareImageMessage(src: src, width: 240, height: 180),
            ),
          ),
        ),
      );
      // First frame: the bytes are not decoded yet.
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);

      // Once decoded the picture replaces the placeholder.
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(_png),
          tester.element(find.byType(FlareImageMessage)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    },
  );
}
