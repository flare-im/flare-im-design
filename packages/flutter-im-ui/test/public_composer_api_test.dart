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
      expect(
        RichComposerMarkdownSerializer.serialize(
          'Flare',
          const RichComposerFormatting(
            inlineStyles: {RichComposerInlineStyle.underline},
            blockStyle: RichComposerBlockStyle.heading,
            headingLevel: 3,
          ),
        ),
        '### <u>Flare</u>',
      );
      expect(
        const RichComposerFormatting().withHeadingLevel(6).headingLevel,
        6,
      );
      expect(ComposerInlineTextField, isNotNull);
    },
  );
}
