import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rich composer adapter API is available from the package entry point',
    () {
      const formatting = RichComposerFormatting(
        inlineStyles: {RichComposerInlineStyle.bold},
      );

      expect(
        RichComposerMarkdownSerializer.serialize('Flare', formatting),
        '**Flare**',
      );
      expect(ComposerInlineTextField, isNotNull);
    },
  );
}
