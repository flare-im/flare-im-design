import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// DoD 32 —— spec/security-boundary.json 的向量表。每条恶意向量都是攻击者能塞进
// 消息里的字符串;四端跑同一批 id,tooling/check-security-boundary.mjs 会在某一端
// 不再验某条时报红。
void main() {
  const hostile = <String, String>{
    'javascript.plain': 'javascript:alert(1)',
    'javascript.uppercase': 'JaVaScRiPt:alert(1)',
    'javascript.leadingSpace': '   javascript:alert(1)',
    'javascript.embeddedTab': 'java\tscript:alert(1)',
    'javascript.embeddedNewline': 'java\nscript:alert(1)',
    'data.html': 'data:text/html,<script>alert(1)</script>',
    'data.base64':
        'data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==',
    'vbscript': 'vbscript:msgbox(1)',
    'file': 'file:///etc/passwd',
    'blob': 'blob:https://evil.example/9b2d',
    'about': 'about:blank',
    'empty': '',
    'whitespace': '   ',
    'notAUrl': 'just some text',
  };

  const allowed = <String, String>{
    'http': 'http://example.com/path?q=1',
    'https': 'https://example.com/path#anchor',
    'schemeless': 'example.com/path',
    'schemelessWithPort': 'example.com:8443/path',
  };

  test('每条恶意向量都被拒', () {
    hostile.forEach((id, input) {
      expect(safeExternalUrl(input), isNull, reason: id);
      expect(isSafeExternalUrl(input), isFalse, reason: id);
    });
  });

  test('普通网址放行', () {
    allowed.forEach((id, input) {
      expect(isSafeExternalUrl(input), isTrue, reason: id);
    });
  });

  test('不带 scheme 的按 https 读,带 scheme 的绝不被救', () {
    expect(safeExternalUrl('example.com'), 'https://example.com');
    expect(safeExternalUrl('javascript:alert(1)'), isNull);
  });

  test('null 不抛异常', () {
    expect(safeExternalUrl(null), isNull);
    expect(isSafeExternalUrl(null), isFalse);
  });
}
