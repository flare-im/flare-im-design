/// One-line summary of a message — what a conversation row, the composer's
/// reply strip and a bubble's quote block say about a message that is not
/// plain text.
///
/// The rule is shared with the other three kits and written down in
/// `spec/message-preview-vectors.json`; Vue implements it in
/// `utils/messagePreview.ts`. The words all come from [FlareStrings]
/// (`preview*`), never from an application: an app that writes its own
/// "[消息]" drifts from the other platforms the moment one of them changes.
library;

import 'dart:ui' show PlatformDispatcher;

import '../emoji_sticker/flare_emoji_sticker_catalog.dart';
import '../tokens/flare_strings.dart';
import 'markdown_preview.dart';
import 'message_content.dart';
import 'message_data.dart';

/// The one-line summary of [content] in the host's words.
///
/// Content that carries its own words (a text body, an image description, a
/// link title, a task title, a quoted preview…) is summarised by those words;
/// content that carries none falls back to its `preview*` term, with the
/// `…Named` variant when there is a name and the `…Count` variant when what
/// matters is how many.
///
/// A message with nothing readable summarises as the empty string — a
/// conversation row may then show nothing at all. Callers that must not show a
/// blank line (a reply strip, a quote block) use [flareReplyTargetFor], which
/// falls back to [FlareStrings.previewMessage].
String flareMessagePreviewText(
  FlareMessageContent? content,
  FlareStrings strings, {
  String? locale,
}) {
  switch (content) {
    case null:
      return '';
    case FlareTextContent c:
      // Markdown first, then the pack keys — the order Vue reads a preview in, so a line that is both
      // marked up and full of pack tokens comes out the same on every platform.
      return FlareEmojiStickerCatalog.instance.localizePackKeysInText(
        flareMarkdownToPlainText(c.text.trim(), strings),
        locale: locale ?? PlatformDispatcher.instance.locale.toLanguageTag(),
      );
    case FlareRichTextContent c:
      // The core's flat text, after the title when there is one — Vue's reading of a document
      // whose Markdown source it does not have.
      return _or(
        [
          c.title.trim(),
          c.plainText.trim(),
        ].where((part) => part.isNotEmpty).join(' '),
        strings.previewRichText,
      );
    case FlareImageContent c:
      // A motion image is a "[动图]", never a "[图片]" — even when described.
      if (c.animated) return strings.previewGif;
      return _or(c.alt, strings.previewImage);
    case FlareImageGroupContent c:
      // An album says how many it carries; one with none says only what it is.
      return c.images.isEmpty
          ? strings.previewImageGroup
          : strings.previewImageGroupCount(c.images.length);
    case FlareVideoContent _:
      return strings.previewVideo;
    case FlareAudioContent _:
      return strings.previewAudio;
    case FlareFileContent c:
      return _named(c.name, strings.previewFileNamed, strings.previewFile);
    case FlareLocationContent c:
      return _named(
        c.name.trim().isEmpty ? c.address : c.name,
        strings.previewLocationNamed,
        strings.previewLocation,
      );
    case FlareCardContent c:
      return _named(c.title, strings.previewCardNamed, strings.previewCard);
    case FlareStickerContent _:
      return strings.previewSticker;
    case FlareEmojiContent c:
      // A pack key is not a word: a row reads the pack's name in the reader's
      // language (`emoji-locales.json`, the same file in all four kits), and
      // falls back to the key itself only for a key the table does not know.
      final packKey = c.emoji.trim();
      final packLabel = packKey.isEmpty
          ? ''
          : FlareEmojiStickerCatalog.instance.emojiLabel(
              packKey,
              // No locale from the caller: read the one the device is in, the way Vue reads
              // `navigator.language`. A test passes its own, so it stays deterministic.
              locale:
                  locale ?? PlatformDispatcher.instance.locale.toLanguageTag(),
            );
      return _or(c.label, _or(packLabel, strings.previewEmoji));
    case FlareLinkCardContent c:
      return _or(c.title, strings.previewLink);
    case FlarePollContent _:
      return strings.previewVote;
    case FlareTaskContent c:
      return _or(c.title, strings.previewTask);
    case FlareCalendarContent c:
      return _or(c.title, strings.previewSchedule);
    case FlareMiniAppContent c:
      return _or(c.title, strings.previewMiniProgram);
    case FlareAnnouncementContent c:
      return _or(
        c.title.trim().isEmpty ? c.body : c.title,
        strings.previewAnnouncement,
      );
    case FlareNotificationContent c:
      return _or(c.text, strings.previewSystem);
    case FlarePlaceholderContent c:
      return _or(c.label, strings.previewPlaceholder);
    case FlareGenericContent c:
      return _genericPreview(c, strings);
    // A product content type the kit does not know: nothing readable to show.
    default:
      return '';
  }
}

/// The summary of content the kit has no typed model for. [FlareGenericContent]
/// keeps the wire type, so the types whose summary is only a word or a count —
/// forwarded messages, an album, a quote, a system line — read the same as they
/// do on Vue without the kit modelling a body it cannot draw.
String _genericPreview(FlareGenericContent content, FlareStrings strings) {
  switch (content.contentType) {
    case 'forward':
      return content.itemCount > 1
          ? strings.previewForwardCount(content.itemCount)
          : _or(content.label, strings.previewForward);
    case 'quote':
      return _or(content.label, strings.previewQuote);
    case 'system':
      return _or(content.label, strings.previewSystem);
    case 'notification':
      return _or(content.label, strings.previewNotification);
    case 'mini_program':
    case 'miniProgram':
      return _or(content.label, strings.previewMiniProgram);
    case 'custom':
      return _or(content.label, strings.previewCustom);
    default:
      return _or(content.label, strings.previewUnknown);
  }
}

/// The reply target for [message]: who is quoted, the one-line summary of what
/// they said, and the core id the quote block locates — the row's
/// [FlareMessageData.serverId] when the core knows it by another id, its own id
/// otherwise. [FlareReplyTarget.messageId] means the same thing here as on a
/// quote that arrived from the core.
///
/// This is the one place a reply strip and a quote block get their words, so
/// they read the same on all four platforms — and never as a blank line: a
/// message that summarises as nothing shows [FlareStrings.previewMessage].
/// The same summary is what an application sends as the core's
/// `quotedTextPreview`.
/// What a reply strip, a bubble's quote or a screen-reader announcement says about [content]: its
/// summary, or the word for a message with nothing readable. Never blank, so none of those places is
/// ever an empty line. Same name and same rule as the Compose kit's.
String flareMessageReplySummary(
  FlareMessageContent? content,
  FlareStrings strings, {
  String? locale,
}) {
  final summary = flareMessagePreviewText(
    content,
    strings,
    locale: locale,
  ).trim();
  return summary.isEmpty ? strings.previewMessage : summary;
}

/// What a screen reader is told once a jump lands: which row it is, and what it says. The ring says the
/// same thing to everyone who can see it. The sender is named, or the word for a message whose sender is
/// unknown; the line is the one a reply strip would show, so a message reads the same wherever it is named.
String flareLocatedAnnouncement(
  FlareMessageData message,
  FlareStrings strings, {
  String? locale,
}) {
  final sender = message.senderName.trim();
  return strings.jumpedToMessage(
    sender.isEmpty ? strings.previewMessage : sender,
    flareMessageReplySummary(message.content, strings, locale: locale),
  );
}

FlareReplyTarget flareReplyTargetFor(
  FlareMessageData message,
  FlareStrings strings, {
  String? locale,
}) {
  final summary = flareMessagePreviewText(
    message.content,
    strings,
    locale: locale,
  ).trim();
  final coreId = message.serverId ?? '';
  return FlareReplyTarget(
    senderName: message.senderName,
    summary: summary.isEmpty ? strings.previewMessage : summary,
    messageId: coreId.isEmpty ? message.id : coreId,
  );
}

/// [value] once trimmed, or [fallback] when it has nothing in it.
String _or(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

/// The `…Named` term for [value], or the plain term when there is no name.
String _named(String value, String Function(String) named, String plain) {
  final text = value.trim();
  return text.isEmpty ? plain : named(text);
}
