import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import '../utils/latin_letters.dart';
import '../utils/pinyin_initials.dart';
import 'flare_avatar.dart';
import 'flare_checkbox.dart';

/// Directory row — avatar, name, signature, presence.
/// Spec: Contacts/ContactItem (`FlareContactItem`).
///
/// [selectable] turns the row into a checkbox for pickers: a leading
/// [FlareCheckbox] shows [selected], tapping the row calls [onToggleSelect]
/// instead of [onSelect], and the row is announced as a checkbox named after
/// the contact. [trailing] sits at the row end; its controls keep their own
/// focus and their taps stay with them.
class FlareContactItem extends StatelessWidget {
  const FlareContactItem({
    super.key,
    required this.item,
    this.showPresence = true,
    this.onSelect,
    this.selectable = false,
    this.selected = false,
    this.onToggleSelect,
    this.trailing,
  });

  final FlareContact item;
  final bool showPresence;
  final VoidCallback? onSelect;
  final bool selectable;
  final bool selected;
  final VoidCallback? onToggleSelect;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    Widget identity = Row(
      children: [
        if (selectable) ...[
          // The row is the control; the box only shows its state.
          IgnorePointer(child: FlareCheckbox(value: selected)),
          const SizedBox(width: FlareSizes.spacingMd),
        ],
        FlareAvatar(
          userId: item.id,
          displayName: item.name,
          avatarUrl: item.avatarUrl,
          size: 40,
          presence: showPresence ? item.presence : null,
        ),
        const SizedBox(width: FlareSizes.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeLg,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.signature != null && item.signature!.isNotEmpty)
                Text(
                  item.signature!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (selectable) {
      identity = Semantics(
        container: true,
        checked: selected,
        label: item.name,
        onTap: onToggleSelect,
        excludeSemantics: true,
        child: identity,
      );
    }
    return InkWell(
      onTap: selectable ? onToggleSelect : onSelect,
      // A selectable row announces itself through the checkbox node above.
      excludeFromSemantics: selectable,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd,
          vertical: FlareSizes.spacingSm,
        ),
        child: Row(
          children: [
            Expanded(child: identity),
            if (trailing != null) ...[
              const SizedBox(width: FlareSizes.spacingSm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Derives the A-Z index letter for a contact, as the Vue kit's
/// `contactIndexLetter` does: the host's [FlareContact.indexKey] when it gives
/// one, otherwise the name.
///
/// - A Latin first letter is its letter, accented, full-width and styled forms
///   included (É, Ｗ, 𝐀).
/// - A Chinese name without a key indexes by the pinyin initial of its first
///   character, from the GB2312 level-1 table (3755 common hanzi). A
///   polyphonic character takes its GB2312 reading (曾 under Z, 长 under C);
///   pass `indexKey` for another reading.
/// - Everything else, a hanzi outside the table included, goes under "#".
String flareContactLetter(FlareContact c) {
  final key = c.indexKey;
  final source = (key ?? c.name).trim();
  if (source.isEmpty) return flareContactIndexOther;
  final first = source.runes.first;
  final latin = flareLatinLetter(first);
  if (latin != null) return latin;
  if (key == null) return flarePinyinInitial(first) ?? flareContactIndexOther;
  return flareContactIndexOther;
}

/// The index group for names that start with no Latin letter; it sorts last.
const flareContactIndexOther = '#';

/// Index letters in list order: A to Z, then "#".
int flareCompareContactLetters(String left, String right) {
  if (left == right) return 0;
  if (left == flareContactIndexOther) return 1;
  if (right == flareContactIndexOther) return -1;
  return left.compareTo(right);
}

/// Orders two contact names the way a contact list sorts them within an
/// index letter, character by character: symbols and punctuation first, then
/// digits, then hanzi in pinyin order (their GB2312 level-1 position; other
/// hanzi after those, by code point), then Latin letters (accented, full-width
/// and styled forms with their base letter), then other scripts. A name that
/// starts another comes first; names that differ only in form put lower case
/// before upper case and plain letters before other forms.
int flareCompareContactNames(String left, String right) {
  final a = left.trim().runes.toList();
  final b = right.trim().runes.toList();
  final shared = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < shared; i++) {
    final order = _nameRuneKey(a[i]).compareTo(_nameRuneKey(b[i]));
    if (order != 0) return order;
  }
  if (a.length != b.length) return a.length.compareTo(b.length);
  for (var i = 0; i < shared; i++) {
    final form = _formRank(a[i]).compareTo(_formRank(b[i]));
    if (form != 0) return form;
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

final _decimalDigit = RegExp(r'^\p{Nd}$', unicode: true);
final _letter = RegExp(r'^\p{L}$', unicode: true);

/// A character's place in [flareCompareContactNames]: its group in the top
/// bits, its order within the group below.
int _nameRuneKey(int rune) {
  const group = 1 << 24;
  final latin = flareLatinLetter(rune);
  if (latin != null) return 3 * group + latin.codeUnitAt(0);
  final position = flarePinyinPosition(rune);
  if (position >= 0) return 2 * group + position;
  if (_isHan(rune)) return 2 * group + 0x10000 + rune;
  final text = String.fromCharCode(rune);
  if (_decimalDigit.hasMatch(text)) {
    // 0-9 and full-width ０-９ by value; digits of other scripts after them.
    final value = rune >= 0x30 && rune <= 0x39
        ? rune - 0x30
        : rune >= 0xFF10 && rune <= 0xFF19
        ? rune - 0xFF10
        : 10 + rune;
    return group + value;
  }
  if (_letter.hasMatch(text)) return 4 * group + rune;
  return rune;
}

bool _isHan(int rune) =>
    (rune >= 0x3400 && rune <= 0x4DBF) ||
    (rune >= 0x4E00 && rune <= 0x9FFF) ||
    (rune >= 0xF900 && rune <= 0xFAFF) ||
    (rune >= 0x20000 && rune <= 0x3FFFF);

/// Lower case, then upper case, then every other form of the same letter.
int _formRank(int rune) => rune >= 0x61 && rune <= 0x7A
    ? 0
    : rune >= 0x41 && rune <= 0x5A
    ? 1
    : 2;
