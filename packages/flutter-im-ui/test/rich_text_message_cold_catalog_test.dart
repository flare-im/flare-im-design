import 'dart:convert';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The emoji catalog is a process-wide singleton and rich_text_message_test.dart
// preloads it, which hid this: a rich body whose only emoji are `[key]` tokens
// inside a text run never asked for the catalog, so with a cold catalog — the
// state a real app opens a conversation in — the tokens stayed words. This file
// is its own isolate and never calls ensureLoaded().
void main() {
  testWidgets('a text token alone loads the catalog and then draws inline', (
    tester,
  ) async {
    expect(FlareEmojiStickerCatalog.instance.isLoaded, isFalse);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareRichTextMessage(
            docJson: jsonEncode({
              'type': 'doc',
              'version': 2,
              'children': [
                {
                  'type': 'paragraph',
                  'children': [
                    {'type': 'text', 'text': '[alien] hi'},
                  ],
                },
              ],
            }),
          ),
        ),
      ),
    );
    // The asset bundle reads for real: let it finish outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump();
    expect(FlareEmojiStickerCatalog.instance.isLoaded, isTrue);
    expect(find.byType(FlareStaticImage), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '[alien]',
      ),
      findsOneWidget,
    );
  });
}
