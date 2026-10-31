import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core stores a conversation's last-message summary as a token
/// (`preview_storage.rs`); the row must read it, not show '' for every picture.
void main() {
  // The emoji token reads the pack names the kit ships (`emoji-locales.json`).
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => FlareEmojiStickerCatalog.instance.ensureLoaded());

  const s = FlareStrings();
  String read(String raw, {String Function(String)? events}) =>
      flareStoredPreviewText(raw, s, locale: 'zh-CN', systemEventText: events);

  /// The shared table's `stored` list: each token exactly as the core writes it
  /// and the line it reads as — the same file Vue and the other two kits read.
  group('shared stored preview vectors', () {
    final vectors =
        jsonDecode(
              File(
                '../../spec/message-preview-vectors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final stored = (vectors['stored'] as List).cast<Map<String, dynamic>>();
    final strings = {'zh-CN': s, 'en-US': flareStringsEnglish};

    test('covers the tokens the core writes', () {
      expect(stored.length, greaterThanOrEqualTo(40));
    });
    for (final vector in stored) {
      final expected = (vector['expected'] as Map).cast<String, dynamic>();
      for (final locale in strings.keys) {
        test('${vector['id']} reads the same in $locale', () {
          expect(
            flareStoredPreviewText(
              vector['token'] as String,
              strings[locale]!,
              locale: locale,
            ),
            expected[locale],
          );
        });
      }
    }
  });

  test('media tokens read as their preview terms', () {
    expect(read('{"k":"im.preview.image","a":{}}'), s.previewImage);
    expect(read('{"k":"im.preview.image","a":{"m":true}}'), s.previewGif);
    expect(read('{"k":"im.preview.image","a":{"d":"周末爬山"}}'), '周末爬山');
    expect(read('{"k":"im.preview.video"}'), s.previewVideo);
    expect(read('{"k":"im.preview.audio","a":{}}'), s.previewAudio);
    expect(
      read('{"k":"im.preview.image_group","a":{"n":3}}'),
      s.previewImageGroup,
    );
  });

  test('a file names itself', () {
    expect(
      read('{"k":"im.preview.file","a":{"n":"连调测试.txt"}}'),
      s.previewFileNamed('连调测试.txt'),
    );
    expect(read('{"k":"im.preview.file","a":{}}'), s.previewFile);
  });

  test('text, plain history and system lines', () {
    expect(read('{"k":"im.preview.user_text","a":{"t":"明天见"}}'), '明天见');
    expect(read('明天见'), '明天见');
    expect(read('{"k":"im.preview.system","a":{"fb":"群聊已创建"}}'), '群聊已创建');
    expect(read('{"k":"im.preview.system","a":{"ek":"x.y"}}'), s.previewSystem);
  });

  test('a host names its own events first, the kit the rest', () {
    String host(String key) => key == 'shop.order_paid' ? '订单已支付' : '';
    expect(
      read(
        '{"k":"im.preview.system","a":{"ek":"shop.order_paid"}}',
        events: host,
      ),
      '订单已支付',
    );
    expect(
      read(
        '{"k":"im.preview.system","a":{"ek":"group.member_left"}}',
        events: host,
      ),
      s.systemEventGroupMemberLeft,
    );
    // The server's words still win over any name for the event.
    expect(
      read(
        '{"k":"im.preview.system","a":{"ek":"shop.order_paid","fb":"已付款"}}',
        events: host,
      ),
      '已付款',
    );
  });

  test('a token the kit does not know shows nothing, never raw JSON', () {
    expect(read('{"k":"im.preview.from_the_future","a":{"t":"x"}}'), '');
    expect(read(''), '');
  });
}
