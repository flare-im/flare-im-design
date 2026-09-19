import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final morning = DateTime(2026, 9, 14, 9, 5);
  final evening = DateTime(2026, 9, 14, 21, 40);
  final midnight = DateTime(2026, 9, 14, 0, 7);
  final noon = DateTime(2026, 9, 14, 12, 30);

  group('messageTime', () {
    test('24-hour locales use a two-digit hour', () {
      for (final locale in ['zh-CN', 'zh_Hans_CN', 'ja-JP', 'de-DE', 'en-GB']) {
        expect(
          FlareTimeFormat.messageTime(morning, locale: locale),
          '09:05',
          reason: locale,
        );
        expect(FlareTimeFormat.messageTime(evening, locale: locale), '21:40');
      }
    });

    test('12-hour locales mark the half of the day', () {
      expect(FlareTimeFormat.messageTime(morning, locale: 'en-US'), '9:05 AM');
      expect(FlareTimeFormat.messageTime(evening, locale: 'en_US'), '9:40 PM');
      expect(FlareTimeFormat.messageTime(midnight, locale: 'en'), '12:07 AM');
      expect(FlareTimeFormat.messageTime(noon, locale: 'en-AU'), '12:30 PM');
      expect(FlareTimeFormat.messageTime(evening, locale: 'ko-KR'), '오후 9:40');
      expect(FlareTimeFormat.messageTime(morning, locale: 'zh-TW'), '上午9:05');
      expect(
        FlareTimeFormat.messageTime(evening, locale: 'zh-Hant-HK'),
        '下午9:40',
      );
    });

    test('an unlisted locale reads a 24-hour clock', () {
      expect(FlareTimeFormat.messageTime(evening, locale: 'xx'), '21:40');
      expect(FlareTimeFormat.messageTime(evening, locale: ''), '21:40');
    });
  });

  group('conversationTime', () {
    final now = DateTime(2026, 9, 14, 18);
    String label(DateTime time, String locale, {DateTime? at}) =>
        FlareTimeFormat.conversationTime(
          time,
          yesterday: 'Yesterday',
          locale: locale,
          now: at ?? now,
        );

    test('the same calendar day shows the clock', () {
      expect(label(morning, 'zh-CN'), '09:05');
      expect(label(morning, 'en-US'), '9:05 AM');
    });

    test('the previous calendar day is yesterday, across months', () {
      expect(label(DateTime(2026, 9, 13, 23, 59), 'zh-CN'), 'Yesterday');
      expect(
        label(
          DateTime(2026, 8, 31, 8),
          'en-US',
          at: DateTime(2026, 9, 1, 0, 1),
        ),
        'Yesterday',
      );
      expect(
        label(DateTime(2025, 12, 31, 22), 'de-DE', at: DateTime(2026, 1, 1, 9)),
        'Yesterday',
      );
    });

    test('earlier this year is month and day in the locale order', () {
      final day = DateTime(2026, 3, 7, 10);
      expect(label(day, 'zh-CN'), '3/7');
      expect(label(day, 'ja-JP'), '3/7');
      expect(label(day, 'en-US'), '3/7');
      expect(label(day, 'en-GB'), '7/3');
      expect(label(day, 'fr-FR'), '7/3');
      expect(label(day, 'de-DE'), '7.3');
      expect(label(day, 'nl-NL'), '7-3');
      expect(label(day, 'ko-KR'), '3. 7.');
    });

    test('an earlier year adds the year', () {
      final day = DateTime(2024, 11, 2, 10);
      expect(label(day, 'zh-CN'), '2024/11/2');
      expect(label(day, 'en-US'), '11/2/2024');
      expect(label(day, 'en-GB'), '2/11/2024');
      expect(label(day, 'de-DE'), '2.11.2024');
      expect(label(day, 'ko-KR'), '2024. 11. 2.');
    });

    test('two days ago is a date, not yesterday', () {
      expect(label(DateTime(2026, 9, 12, 20), 'zh-CN'), '9/12');
    });
  });
}
