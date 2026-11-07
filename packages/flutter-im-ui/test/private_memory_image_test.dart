import 'dart:convert';
import 'dart:typed_data';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _syntheticPng =
    'iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAIAAAAt/+nTAAAATklEQVR4nO3PUQkAIBTAwBfOcGYxpSH8OITBAtxm7fN1wwUNaEEDWtCAFjSgBQ1oQQNa0IAWNKAFDWhBA1rQgBY0oAUNaEEDWtCAFjx2ASsgsKacX5PvAAAAAElFTkSuQmCC';

Widget host(Uint8List bytes) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 120,
      height: 80,
      child: FlarePrivateMemoryImage(
        bytes: bytes,
        maxPixelSize: 16,
        semanticLabel: 'Synthetic private image',
        errorBuilder: (_) => const Text('Image unavailable'),
      ),
    ),
  ),
);

Future<RawImage> decoded(WidgetTester tester) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    final images = tester.widgetList<RawImage>(find.byType(RawImage));
    if (images.isNotEmpty && images.first.image != null) return images.first;
  }
  throw TestFailure('The synthetic memory image did not decode');
}

void main() {
  testWidgets('private frames preserve aspect and are disposed without cache', (
    tester,
  ) async {
    final bytes = base64Decode(_syntheticPng);
    await tester.pumpWidget(host(bytes));
    final first = (await decoded(tester)).image!;
    expect(first.width, lessThanOrEqualTo(16));
    expect(first.height, lessThanOrEqualTo(16));
    expect(first.width / first.height, 2);
    expect(find.byType(Image), findsNothing);

    await tester.pumpWidget(host(Uint8List.fromList(bytes)));
    final replacement = (await decoded(tester)).image!;
    expect(identical(first, replacement), isFalse);
    expect(first.debugDisposed, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(replacement.debugDisposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid memory content shows the controlled error presentation',
    (tester) async {
      await tester.pumpWidget(host(Uint8List(0)));
      for (var attempt = 0; attempt < 30; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (find.text('Image unavailable').evaluate().isNotEmpty) break;
      }
      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.byType(RawImage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
