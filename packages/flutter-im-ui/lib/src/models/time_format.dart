/// Locale-aware clock and day labels for message and conversation rows.
///
/// The kit carries no date-formatting dependency, so the conventions come from
/// a compact table: which languages and regions read a 12-hour clock, and the
/// order and separator of numeric dates. A locale the table does not list
/// reads a 24-hour clock and day/month/year. Labels use the local time zone.
/// `locale` is a language tag such as `zh-CN`, `en_US` or `zh-Hant-TW`.
abstract final class FlareTimeFormat {
  /// Hour and minute: `09:05` in 24-hour locales, `9:05 AM` in 12-hour ones.
  static String messageTime(DateTime time, {required String locale}) {
    final local = time.toLocal();
    final minute = _two(local.minute);
    final style = _LocaleStyle.of(locale);
    if (style.meridiem == _Meridiem.none) return '${_two(local.hour)}:$minute';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final pm = local.hour >= 12;
    return switch (style.meridiem) {
      _Meridiem.korean => '${pm ? '오후' : '오전'} $hour:$minute',
      _Meridiem.chinese => '${pm ? '下午' : '上午'}$hour:$minute',
      _ => '$hour:$minute ${pm ? 'PM' : 'AM'}',
    };
  }

  /// The conversation list stamp relative to [now]: the clock on the same
  /// calendar day, [yesterday] on the previous one, numeric month and day
  /// within the year, numeric year, month and day before it.
  static String conversationTime(
    DateTime time, {
    required String yesterday,
    required String locale,
    DateTime? now,
  }) {
    final local = time.toLocal();
    final current = (now ?? DateTime.now()).toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(current.year, current.month, current.day);
    if (day == today) return messageTime(local, locale: locale);
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return yesterday;
    }
    final style = _LocaleStyle.of(locale);
    return local.year == current.year
        ? style.monthDay(local.month, local.day)
        : style.date(local.year, local.month, local.day);
  }

  /// The label of a timeline date separator relative to [now]: [today] on the
  /// same calendar day, [yesterday] on the previous one, numeric month and
  /// day within the year, numeric year, month and day before it. Every bubble
  /// already shows its own time, so a separator names the day only.
  static String timelineDate(
    DateTime time, {
    required String today,
    required String yesterday,
    required String locale,
    DateTime? now,
  }) {
    final local = time.toLocal();
    final current = (now ?? DateTime.now()).toLocal();
    if (sameDay(local, current)) return today;
    if (sameDay(
      local,
      DateTime(current.year, current.month, current.day - 1),
    )) {
      return yesterday;
    }
    final style = _LocaleStyle.of(locale);
    return local.year == current.year
        ? style.monthDay(local.month, local.day)
        : style.date(local.year, local.month, local.day);
  }

  /// Whether [a] and [b] fall on the same local calendar day, compared on
  /// numeric fields.
  static bool sameDay(DateTime a, DateTime b) {
    final left = a.toLocal();
    final right = b.toLocal();
    return left.day == right.day &&
        left.month == right.month &&
        left.year == right.year;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

enum _Meridiem { none, english, korean, chinese }

enum _DateOrder { ymd, mdy, dmy }

class _LocaleStyle {
  const _LocaleStyle(this.order, this.separator, this.meridiem);

  final _DateOrder order;

  /// `. ` marks the Korean / Hungarian form, which also closes with a dot.
  final String separator;
  final _Meridiem meridiem;

  static const _englishTwelveHourRegions = {
    'US',
    'CA',
    'AU',
    'NZ',
    'IN',
    'PH',
    'PK',
    'MY',
    'SG',
  };
  static const _dottedLanguages = {
    'de',
    'ru',
    'pl',
    'uk',
    'cs',
    'sk',
    'fi',
    'nb',
    'no',
    'nn',
    'da',
    'tr',
    'ro',
    'hr',
    'sr',
    'sl',
    'bg',
    'lv',
    'et',
  };

  static final Map<String, _LocaleStyle> _cache = {};

  /// The style for [locale], parsed once per tag: timeline rows ask for a
  /// label each.
  static _LocaleStyle of(String locale) =>
      _cache[locale] ??= _LocaleStyle.parse(locale);

  factory _LocaleStyle.parse(String locale) {
    final parts = locale
        .replaceAll('_', '-')
        .split('-')
        .where((part) => part.isNotEmpty)
        .toList();
    final language = parts.isEmpty ? '' : parts.first.toLowerCase();
    String? script;
    String? region;
    for (final part in parts.skip(1)) {
      if (part.length == 4) {
        script ??= part.toLowerCase();
      } else if (part.length == 2 || int.tryParse(part) != null) {
        region ??= part.toUpperCase();
      }
    }
    switch (language) {
      case 'zh':
        final traditional =
            script == 'hant' ||
            (script == null && {'TW', 'HK', 'MO'}.contains(region));
        return _LocaleStyle(
          _DateOrder.ymd,
          '/',
          traditional ? _Meridiem.chinese : _Meridiem.none,
        );
      case 'ja':
        return const _LocaleStyle(_DateOrder.ymd, '/', _Meridiem.none);
      case 'ko':
        return const _LocaleStyle(_DateOrder.ymd, '. ', _Meridiem.korean);
      case 'hu':
        return const _LocaleStyle(_DateOrder.ymd, '. ', _Meridiem.none);
      case 'en':
        final twelveHour =
            region == null || _englishTwelveHourRegions.contains(region);
        return _LocaleStyle(
          region == null || region == 'US' || region == 'PH'
              ? _DateOrder.mdy
              : _DateOrder.dmy,
          '/',
          twelveHour ? _Meridiem.english : _Meridiem.none,
        );
      case 'nl':
        return const _LocaleStyle(_DateOrder.dmy, '-', _Meridiem.none);
    }
    return _dottedLanguages.contains(language)
        ? const _LocaleStyle(_DateOrder.dmy, '.', _Meridiem.none)
        : const _LocaleStyle(_DateOrder.dmy, '/', _Meridiem.none);
  }

  String monthDay(int month, int day) => _join(switch (order) {
    _DateOrder.dmy => [day, month],
    _ => [month, day],
  });

  String date(int year, int month, int day) => _join(switch (order) {
    _DateOrder.ymd => [year, month, day],
    _DateOrder.mdy => [month, day, year],
    _DateOrder.dmy => [day, month, year],
  });

  String _join(List<int> fields) {
    final text = fields.join(separator);
    return separator == '. ' ? '$text.' : text;
  }
}
