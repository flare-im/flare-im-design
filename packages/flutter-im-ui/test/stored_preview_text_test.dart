import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core stores a conversation's last-message summary as a token
/// (`preview_storage.rs`); the row must read it, not show '' for every picture.
void main() {
  const s = FlareStrings();
  String read(String raw, {String Function(String)? events}) =>
      flareStoredPreviewText(raw, s, locale: 'zh-CN', systemEventText: events);

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
    expect(
      read(
        '{"k":"im.preview.system","a":{"ek":"group.member_left"}}',
        events: (key) => key == 'group.member_left' ? '有成员退出了群聊' : '',
      ),
      '有成员退出了群聊',
    );
    expect(read('{"k":"im.preview.system","a":{"ek":"x.y"}}'), s.previewSystem);
  });

  test('a token the kit does not know shows nothing, never raw JSON', () {
    expect(read('{"k":"im.preview.from_the_future","a":{"t":"x"}}'), '');
    expect(read(''), '');
  });
}
