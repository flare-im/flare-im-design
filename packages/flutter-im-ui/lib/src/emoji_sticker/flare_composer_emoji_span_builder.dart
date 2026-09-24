import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import 'flare_emoji_sticker_catalog.dart';
import 'flare_static_asset_image.dart';

/// Renders protocol emoji tokens such as `[alien]` as their bundled image in
/// editable composer fields while preserving the raw token in the controller.
///
/// The protocol value remains suitable for drafts, typing signals, clipboard
/// operations and sending. Only the editable presentation changes.
class FlareComposerEmojiSpanBuilder extends SpecialTextSpanBuilder {
  FlareComposerEmojiSpanBuilder({this.delegate, this.locale});

  final SpecialTextSpanBuilder? delegate;
  final String? locale;

  @override
  SpecialText? createSpecialText(
    String flag, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
    required int index,
  }) {
    if (isStart(flag, _FlareComposerEmojiText.openingToken)) {
      return _FlareComposerEmojiText(
        textStyle,
        locale: locale,
        start: index - (_FlareComposerEmojiText.openingToken.length - 1),
      );
    }
    return delegate?.createSpecialText(
      flag,
      textStyle: textStyle,
      onTap: onTap,
      index: index,
    );
  }
}

class _FlareComposerEmojiText extends SpecialText {
  _FlareComposerEmojiText(
    TextStyle? textStyle, {
    required this.start,
    this.locale,
  }) : super(openingToken, closingToken, textStyle);

  static const String openingToken = '[';
  static const String closingToken = ']';

  final int start;
  final String? locale;

  @override
  InlineSpan finishText() {
    final token = toString();
    final key = getContent().trim();
    final catalog = FlareEmojiStickerCatalog.instance;
    if (!catalog.hasEmojiKey(key)) {
      return TextSpan(text: token, style: textStyle);
    }

    final fontSize = textStyle?.fontSize ?? 15;
    final size = (fontSize * 1.72).clamp(24.0, 28.0);
    return ExtendedWidgetSpan(
      actualText: token,
      child: Semantics(
        image: true,
        label: catalog.emojiBracketLabel(key, locale: locale),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: SizedBox.square(
            dimension: size,
            child: FlareStaticImage(
              image: catalog.emojiImageProvider(key, staticPreview: true),
            ),
          ),
        ),
      ),
      alignment: PlaceholderAlignment.middle,
      start: start,
    );
  }
}
