import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/utils/pinyin_initials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-044 (K7, finished in Round 12): Chinese names index by the pinyin initial
// of their first character from the generated table of every BMP hanzi, Latin
// names by letter (accented, full-width and styled forms included), the rest
// under "#" last; the host's indexKey wins. The table is generated from the same
// pinyin collation the Vue kit reads at runtime, so the two agree character for
// character. The name tables are ported from the Vue kit's
// packages/vue-im-ui/src/utils/contactIndex.test.ts.

String _letter(String name, [String? indexKey]) =>
    flareContactLetter(FlareContact(id: name, name: name, indexKey: indexKey));

void main() {
  group('flareContactLetter', () {
    test('indexes Chinese names by the pinyin initial of the first character '
        '(the Vue table)', () {
      const names = {
        '林夏': 'L', '周屿': 'Z', '产品设计组': 'C', '苏晚晴': 'S', '何川': 'H', //
        '陈默': 'C', '唐果': 'T', '徐知远': 'X', '家人': 'J', '欧阳明月': 'O', //
        '陆遥': 'L', '顾南': 'G', '秦朗': 'Q', '王': 'W', '吕': 'L', '罗': 'L', //
        '龙': 'L', '邓': 'D', '丁': 'D', '戴': 'D', '艾': 'A', '恩': 'E', //
        '冯': 'F', '孔': 'K', '马': 'M', '牛': 'N', '彭': 'P', '任': 'R', //
        '谭': 'T', '夏': 'X', '叶': 'Y', '郑': 'Z', '霖': 'L',
      };
      for (final entry in names.entries) {
        expect(_letter(entry.key), entry.value, reason: entry.key);
      }
    });

    test('indexes the characters the GB2312 table used to miss', () {
      // 梓 琪 苒 珩 婧 are GB2312 level 2 and 玥 is not in GB2312 at all, so all
      // six went under "#" until the table covered every BMP hanzi. These are
      // the letters Vue reads from the engine's collation.
      const names = {'梓': 'Z', '琪': 'Q', '苒': 'R', '珩': 'H', '玥': 'Y', '婧': 'J'};
      for (final entry in names.entries) {
        expect(_letter(entry.key), entry.value, reason: entry.key);
      }
    });

    test('a polyphonic character takes the collation\'s reading, the same one '
        'on all four kits', () {
      // 曾 used to be Z here and C everywhere else, because GB2312 files it
      // under zēng and the collation reads céng. One table, one answer; a host
      // that knows the surname is Zēng passes indexKey.
      expect(_letter('曾一'), 'C');
      expect(_letter('曾一', 'Zeng'), 'Z');
      expect(_letter('长江'), 'Z');
      expect([_letter('单'), _letter('解'), _letter('仇')], ['D', 'J', 'C']);
    });

    test('indexes Latin names by their first letter, accents and full width '
        'included', () {
      expect(_letter(' alice'), 'A');
      expect(_letter('Émile'), 'E');
      expect(_letter('ｗｅｉ'), 'W');
      expect(_letter('𝓐𝓵𝓲𝓬𝓮'), 'A', reason: 'styled letters');
      expect(_letter('Ⓑob'), 'B');
    });

    test('puts digits, symbols and emoji under #, and honours the host\'s '
        'index key', () {
      expect(_letter('1号机'), '#');
      expect(_letter('😀 Pat'), '#');
      expect(_letter(''), '#');
      expect(_letter('曾一', 'Zeng'), 'Z');
      expect(_letter('Anyone', '?'), '#');
      // A key is read as letters, never looked up as hanzi (as on Vue).
      expect(_letter('Anyone', '张'), '#');
    });
  });

  group('the generated pinyin table', () {
    test('covers every BMP hanzi in pinyin order with the 23 boundaries', () {
      int position(String character) =>
          flarePinyinPosition(character.codeUnitAt(0));
      String? initial(String character) =>
          flarePinyinInitial(character.codeUnitAt(0));

      // U+4E00..U+9FFF, 20992 characters: 吖 sorts first, 鿼 last.
      expect(position('吖'), 0);
      expect(position('鿼'), 20991);
      expect(position('梓'), isNot(-1), reason: 'GB2312 level 2');
      expect(position('玥'), isNot(-1), reason: 'outside GB2312');
      expect(position('A'), -1);
      expect(position('㐀'), -1, reason: 'CJK extension A is outside the block');
      expect(initial('吖'), 'A');
      expect(initial('鿼'), 'Z');
      expect(initial('A'), isNull);

      // Each letter's first character, and the character just before it, which
      // still carries the letter before. The first characters are the same 23
      // boundaries the Vue kit compares against at runtime.
      const boundaries = {
        '八': ('B', '丷'), '嚓': ('C', '簿'), '哒': ('D', '咑'), //
        '妸': ('E', '鵽'), '发': ('F', '樲'), '旮': ('G', '酜'), //
        '哈': ('H', '過'), '讥': ('J', '丌'), '咔': ('K', '攟'), //
        '垃': ('L', '鬠'), '妈': ('M', '呣'), '拏': ('N', '鞪'), //
        '喔': ('O', '糯'), '妑': ('P', '慪'), '七': ('Q', '巭'), //
        '呥': ('R', '裠'), '仨': ('S', '鶸'), '他': ('T', '蜶'), //
        '穵': ('W', '屲'), '夕': ('X', '錻'), '丫': ('Y', '鑂'), //
        '帀': ('Z', '繧'),
      };
      const letters = 'ABCDEFGHJKLMNOPQRSTWXYZ';
      var last = 0;
      for (final MapEntry(key: first, value: (letter, before))
          in boundaries.entries) {
        expect(position(first), greaterThan(last), reason: 'monotonic');
        last = position(first);
        expect(position(before), position(first) - 1, reason: before);
        expect(initial(first), letter, reason: first);
        expect(
          initial(before),
          letters[letters.indexOf(letter) - 1],
          reason: before,
        );
      }
    });
  });

  group('contact ordering', () {
    test('orders letters A to Z with # last, and names in pinyin order', () {
      expect(['#', 'Z', 'A', 'L']..sort(flareCompareContactLetters), [
        'A',
        'L',
        'Z',
        '#',
      ]);
      expect(['陆遥', '林夏', '李']..sort(flareCompareContactNames), [
        '李',
        '林夏',
        '陆遥',
      ]);
    });

    test('mixed names follow the pinyin collation\'s groups', () {
      // Symbols, then digits, then hanzi, then Latin, as the engine's zh
      // collation orders them; a shorter name that starts a longer one first.
      final names = ['Adam', '艾伦', '1号机', '_x', '阿', 'alice', '李白', '李']
        ..sort(flareCompareContactNames);
      expect(names, ['_x', '1号机', '阿', '艾伦', '李', '李白', 'Adam', 'alice']);
      expect(flareCompareContactNames('adam', 'Adam'), lessThan(0));
      // Full-width digits sort with their value.
      expect(flareCompareContactNames('２号', '10号'), greaterThan(0));
      expect(flareCompareContactNames('１号', '2号'), lessThan(0));
    });

    testWidgets('the list groups A to Z with "#" last and names in pinyin '
        'order within a letter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareContactList(
              items: const [
                FlareContact(id: '1', name: '123 Studio'),
                FlareContact(id: '2', name: '周六'),
                FlareContact(id: '3', name: 'Zoe'),
                FlareContact(id: '4', name: 'Adam'),
                FlareContact(id: '5', name: '张三'),
                FlareContact(id: '6', name: '艾伦'),
                FlareContact(id: '7', name: '梓涵'),
              ],
            ),
          ),
        ),
      );
      final headers = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SliverPersistentHeader),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(headers, ['A', 'Z', '#']);
      double top(String name) => tester.getTopLeft(find.text(name)).dy;
      // A: 艾伦 before Adam; Z: 张三 (zhang) before 周六 (zhou) before 梓涵 (zi),
      // then the Latin name. 梓 is GB2312 level 2, so it used to sit under "#".
      expect(top('艾伦'), lessThan(top('Adam')));
      expect(top('Adam'), lessThan(top('张三')));
      expect(top('张三'), lessThan(top('周六')));
      expect(top('周六'), lessThan(top('梓涵')));
      expect(top('梓涵'), lessThan(top('Zoe')));
      // "#": what is left is the digit name.
      expect(top('Zoe'), lessThan(top('123 Studio')));
    });
  });
}
