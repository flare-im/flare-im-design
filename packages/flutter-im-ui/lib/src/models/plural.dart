import 'package:flutter/widgets.dart';

import '../tokens/flare_strings.dart';

/// Plural forms of the kit's count copy.
///
/// Count strings carry the CLDR `one` and `other` forms: the `other` form is
/// the field itself (`pluginViewVotes`), the `one` form its `…One` sibling
/// (`pluginViewVotesOne`). The kit picks `one` when the locale's CLDR cardinal
/// category for the non-negative integer count is `one`, else `other` — few,
/// many, two and zero fall back to `other`. Flutter ships no plural rules for
/// arbitrary locales, so the rule is a table (the same table on every native
/// kit, `spec/plural-vectors.json`):
///
/// - never `one`: zh, ja, ko, th, vi, id, ms, yue, lo, my, km;
/// - `one` when n is 0 or 1: fr, pt (Brazil and every region but Portugal),
///   hi, bn, fa, gu, kn, am, zu;
/// - `one` when n % 10 = 1 and n % 100 ≠ 11: ru, uk, be, hr, sr, bs;
/// - `one` when n = 1: every other language, pt-PT included.
///
/// [locale] is a language tag (`en-US`, `pt_PT`, `zh-Hant-TW`); null reads as
/// the default family (n = 1).
bool flarePluralIsOne(int count, String? locale) {
  final n = count < 0 ? -count : count;
  return switch (_flarePluralFamily(locale)) {
    _FlarePluralFamily.none => false,
    _FlarePluralFamily.is1 => n == 1,
    _FlarePluralFamily.is0or1 => n == 0 || n == 1,
    _FlarePluralFamily.mod10is1 => n % 10 == 1 && n % 100 != 11,
  };
}

/// [one] when [count] takes the `one` form in [locale], else [other]; then
/// `{count}` (and `{n}`) in the chosen form is replaced by [count].
String flarePlural(int count, String one, String other, String? locale) {
  final form = flarePluralIsOne(count, locale) ? one : other;
  return form.replaceAll('{count}', '$count').replaceAll('{n}', '$count');
}

/// The locale the kit's count copy is chosen in: [override] when the host
/// passes one, else the app's `Localizations` locale, else the platform's.
String flareCopyLocaleOf(BuildContext context, [String? override]) =>
    override ??
    Localizations.maybeLocaleOf(context)?.toLanguageTag() ??
    WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();

/// The kit's count copy with its plural form chosen for a locale
/// ([flarePlural]).
extension FlarePluralStrings on FlareStrings {
  /// "N 票" / "1 vote" — a choice's count, a group's count.
  String pluginViewVotesCount(int count, String? locale) =>
      flarePlural(count, pluginViewVotesOne, pluginViewVotes, locale);

  /// "N 人" / "1 person" — an invite's count.
  String myInviteCountOnlyCount(int count, String? locale) =>
      flarePlural(count, myInviteCountOnlyOne, myInviteCountOnly, locale);

  /// "共 N 条消息" / "1 message in total" — a merged forward's subtitle.
  String forwardRecordTotalCount(int count, String? locale) =>
      flarePlural(count, forwardRecordTotalOne, forwardRecordTotal, locale);

  /// "还有 N 条消息…" / "1 more message…" — a merged forward's overflow line.
  String forwardRecordMoreCount(int count, String? locale) =>
      flarePlural(count, forwardRecordMoreOne, forwardRecordMore, locale);

  /// "N 条不支持转发" / "1 message can't be forwarded" — the batch toolbar's
  /// count of selected messages the forward keys leave out.
  String messageBatchUnforwardableCount(int count, String? locale) =>
      flarePlural(
        count,
        messageBatchUnforwardableOne,
        messageBatchUnforwardable,
        locale,
      );
}

enum _FlarePluralFamily { none, is1, is0or1, mod10is1 }

const Set<String> _none = {
  'zh',
  'ja',
  'ko',
  'th',
  'vi',
  'id',
  'ms',
  'yue',
  'lo',
  'my',
  'km',
};
const Set<String> _is0or1 = {
  'fr',
  'pt',
  'hi',
  'bn',
  'fa',
  'gu',
  'kn',
  'am',
  'zu',
};
const Set<String> _mod10is1 = {'ru', 'uk', 'be', 'hr', 'sr', 'bs'};

_FlarePluralFamily _flarePluralFamily(String? locale) {
  final parts = (locale ?? '')
      .trim()
      .toLowerCase()
      .split(RegExp('[-_]'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return _FlarePluralFamily.is1;
  final language = parts.first;
  // Portugal's Portuguese counts like English; every other region like Brazil.
  if (language == 'pt' && parts.skip(1).contains('pt')) {
    return _FlarePluralFamily.is1;
  }
  if (_none.contains(language)) return _FlarePluralFamily.none;
  if (_is0or1.contains(language)) return _FlarePluralFamily.is0or1;
  if (_mod10is1.contains(language)) return _FlarePluralFamily.mod10is1;
  return _FlarePluralFamily.is1;
}
