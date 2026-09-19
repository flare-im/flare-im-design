import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared summary table (`spec/message-preview-vectors.json`) is what a
/// conversation row, a reply strip and a bubble's quote say about a message.
/// Vue is the reference implementation; the three native kits read the same
/// file. A case's `fields` become this platform's content object: `text` at the
/// root, everything else in the type's own payload, and `count` becomes that
/// many items in the list the type carries.
///
/// Flutter's content model names some of those payload fields differently —
/// an image's description is `alt`, a location's title is `name` — and the
/// types it has no body for (forward, album, quote) are [FlareGenericContent]
/// tagged with the wire type, counted by `itemCount`. That map is the whole of
/// the platform difference; the rule itself is shared.
void main() {
  // The emoji cases read the pack names the kit ships (`emoji-locales.json`), so
  // the catalog is loaded from the package's own assets — the same path the app
  // takes, not a stand-in.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => FlareEmojiStickerCatalog.instance.ensureLoaded());

  final vectors =
      jsonDecode(
            File('../../spec/message-preview-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (vectors['cases'] as List).cast<Map<String, dynamic>>();

  // The kit ships Chinese defaults; an English host overrides the same fields.
  // Both tables come from one place, so a case is asserted in two locales
  // without the summary rule knowing which locale it is in.
  const zh = FlareStrings();
  final en = zh.copyWith(
    previewMessage: '[Message]',
    previewGif: '[GIF]',
    previewImage: '[Image]',
    previewVideo: '[Video]',
    previewAudio: '[Voice]',
    previewFile: '[File]',
    previewFileNamed: (name) => '[File] $name',
    previewLocation: '[Location]',
    previewLocationNamed: (label) => '[Location] $label',
    previewCard: '[Contact]',
    previewCardNamed: (label) => '[Contact] $label',
    previewSticker: '[Sticker]',
    previewQuote: '[Quote]',
    previewLink: '[Link]',
    previewForward: '[Forward]',
    previewForwardCount: (count) => '[Forward] $count messages',
    previewImageGroup: '[Album]',
    previewImageGroupCount: (count) => '[Album] $count',
    previewSystem: '[System]',
    previewEmoji: '[Emoji]',
    previewRichText: '[Rich text]',
    previewMiniProgram: '[Mini Program]',
    previewVote: '[Poll]',
    previewTask: '[Task]',
    previewAnnouncement: '[Announcement]',
  );
  final strings = {'zh-CN': zh, 'en-US': en};

  for (final vector in cases) {
    final id = vector['id'] as String;
    final fields = (vector['fields'] as Map).cast<String, dynamic>();
    final expected = (vector['expected'] as Map).cast<String, dynamic>();
    final replyExpected = (vector['replyExpected'] as Map?)
        ?.cast<String, dynamic>();
    for (final locale in strings.keys) {
      test('$id reads the same in $locale', () {
        final table = strings[locale]!;
        final content = _contentFor(vector['kind'] as String, fields);
        expect(
          flareMessagePreviewText(content, table, locale: locale),
          expected[locale],
          reason: 'summary of $id',
        );
        // What a reply strip or a quote shows: the summary, or the shared
        // fallback when the message has nothing readable to summarise.
        expect(
          flareReplyTargetFor(_message(content), table, locale: locale).summary,
          replyExpected?[locale] ?? expected[locale],
          reason: 'reply fallback of $id',
        );
      });
    }
  }

  test('a reply target names the sender and the core id it locates', () {
    final target = flareReplyTargetFor(
      _message(FlareTextContent('明天见'), id: 'm7', sender: '阿妮'),
      const FlareStrings(),
    );
    expect(target.senderName, '阿妮');
    expect(target.summary, '明天见');
    expect(target.messageId, 'm7', reason: 'the row id is the core id here');

    // A row the core knows by another id — a message this device sent: the
    // strip carries the core's id, the one meaning `messageId` has.
    final selfSent = flareReplyTargetFor(
      _message(FlareTextContent('明天见'), id: 'c7', serverId: 's7'),
      const FlareStrings(),
    );
    expect(selfSent.messageId, 's7');
  });

  test('every case in the shared table is covered', () {
    expect(cases, isNotEmpty);
    expect(vectors['fallbackKey'], 'preview.message');
    expect(const FlareStrings().previewMessage, '[消息]');
  });

  // The shared table does not reach every content type the kit models. These
  // are the rest of the vocabulary: each term is what its type falls back to,
  // so no word in the table is unreachable and none is written twice.
  group('terms the shared table does not reach', () {
    const s = FlareStrings();
    String summary(FlareMessageContent content) =>
        flareMessagePreviewText(content, s);

    /// Content the kit has no body for, tagged with its wire type.
    FlareMessageContent generic(
      String type, {
      String label = '',
      int count = 0,
    }) =>
        FlareGenericContent(contentType: type, label: label, itemCount: count);

    test('a type with nothing to say falls back to its own term', () {
      expect(summary(const FlareEmojiContent('')), s.previewEmoji);
      expect(summary(generic('forward')), s.previewForward);
      expect(summary(generic('quote')), s.previewQuote);
      expect(
        summary(const FlareRichTextContent(docJson: '')),
        s.previewRichText,
      );
      expect(summary(generic('notification')), s.previewNotification);
      expect(
        summary(const FlareCalendarContent(id: '', title: '')),
        s.previewSchedule,
      );
      expect(
        summary(const FlareMiniAppContent(appId: '', title: '')),
        s.previewMiniProgram,
      );
      expect(summary(generic('mini_program')), s.previewMiniProgram);
      expect(summary(const FlarePlaceholderContent('')), s.previewPlaceholder);
      expect(summary(generic('custom')), s.previewCustom);
      expect(summary(generic('saga')), s.previewUnknown);
    });

    test('a system line reads as what it says, else as the system word', () {
      expect(summary(const FlareNotificationContent('')), s.previewSystem);
      expect(summary(const FlareNotificationContent(' 群主已变更 ')), '群主已变更');
      expect(summary(generic('system')), s.previewSystem);
    });

    test('a forwarded bundle of one reads as that one message', () {
      expect(summary(generic('forward', label: '明天见')), '明天见');
      expect(
        summary(generic('forward', label: '明天见', count: 1)),
        '明天见',
        reason: 'one forwarded message is not a count',
      );
      expect(summary(generic('forward', count: 2)), s.previewForwardCount(2));
    });

    test('an album says what it is when it carries nothing', () {
      // "[多图] 0 张" reads as a defect; the shared table says an empty album is
      // named, not counted (`image-group-empty`).
      expect(
        summary(const FlareImageGroupContent(images: [])),
        s.previewImageGroup,
      );
      expect(
        summary(
          const FlareImageGroupContent(
            images: [
              FlareImageContent(url: ''),
              FlareImageContent(url: ''),
            ],
          ),
        ),
        s.previewImageGroupCount(2),
      );
    });
  });
}

FlareMessageData _message(
  FlareMessageContent content, {
  String id = 'm1',
  String? serverId,
  String sender = 'Bob',
}) => FlareMessageData(
  id: id,
  serverId: serverId,
  senderId: sender,
  senderName: sender,
  content: content,
);

/// One vector case as this platform's content object.
FlareMessageContent _contentFor(String kind, Map<String, dynamic> fields) {
  final count = fields['count'] as int? ?? 0;
  switch (kind) {
    case 'text':
      return FlareTextContent(fields['text'] as String? ?? '');
    case 'image':
      return FlareImageContent(
        url: '',
        // `description` in the shared table is this model's `alt`.
        alt: fields['description'] as String?,
        animated: fields['animated'] as bool? ?? false,
      );
    case 'image_group':
      return FlareImageGroupContent(
        images: List.filled(count, const FlareImageContent(url: '')),
      );
    case 'video':
      return const FlareVideoContent(url: '');
    case 'audio':
      return const FlareAudioContent(url: '');
    case 'file':
      return FlareFileContent(
        name: fields['fileName'] as String? ?? '',
        url: '',
      );
    case 'location':
      // `title` in the shared table is this model's `name`.
      return FlareLocationContent(name: fields['title'] as String? ?? '');
    case 'card':
      return FlareCardContent(title: fields['title'] as String? ?? '');
    case 'sticker':
      return const FlareStickerContent(url: '');
    case 'link_card':
      return FlareLinkCardContent(
        url: '',
        title: fields['title'] as String? ?? '',
      );
    case 'forward':
      return FlareGenericContent(
        contentType: 'forward',
        label: '',
        itemCount: count,
      );
    case 'vote':
      return FlarePollContent(id: '', title: fields['title'] as String? ?? '');
    case 'task':
      return FlareTaskContent(id: '', title: fields['title'] as String? ?? '');
    case 'announcement':
      return FlareAnnouncementContent(
        id: '',
        title: fields['title'] as String? ?? '',
      );
    case 'quote':
      // A quote has no kit body; its one line is the quoted row's summary.
      return FlareGenericContent(
        contentType: 'quote',
        label: fields['quotedTextPreview'] as String? ?? '',
      );
    case 'emoji':
      return FlareEmojiContent(fields['key'] as String? ?? '');
    case 'rich_text':
      return FlareRichTextContent(
        docJson: '',
        plainText: fields['plainText'] as String? ?? '',
      );
    case 'mini_program':
      return FlareMiniAppContent(
        appId: '',
        title: fields['title'] as String? ?? '',
      );
    case 'system':
      return FlareNotificationContent(fields['text'] as String? ?? '');
    default:
      fail('vector kind "$kind" has no content object on Flutter');
  }
}
