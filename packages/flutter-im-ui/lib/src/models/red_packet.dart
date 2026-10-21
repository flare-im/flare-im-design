import 'package:flutter/services.dart';

/// What the current viewer sees on a red packet card: saturated while
/// [unopened], dimmed in the other three (spec RedPacketCard `state`).
enum FlareRedPacketState { unopened, claimed, finished, expired }

/// Phase of `FlareRedPacketOpenSheet` (spec RedPacketOpenSheet `state`).
/// [opening] flips the 開 coin while the host claims; [finished], [expired]
/// and [notEligible] say why nothing opens; [error] offers 開 again.
enum FlareRedPacketOpenState {
  ready,
  opening,
  finished,
  expired,
  notEligible,
  error,
}

/// Packet kinds a host can offer in `FlareRedPacketComposer`; a 1:1
/// conversation only has [normal].
enum FlareRedPacketKind { lucky, normal, exclusive }

/// One row of `FlareRedPacketDetail`'s claim list. Time and amount arrive
/// formatted by the host; [best] marks the largest share of a finished lucky
/// packet, as the plugin decided it.
class FlareRedPacketClaim {
  const FlareRedPacketClaim({
    required this.id,
    required this.name,
    this.avatar,
    required this.time,
    required this.amount,
    this.best = false,
  });

  final String id;
  final String name;
  final String? avatar;
  final String time;
  final String amount;
  final bool best;
}

const int _fullWidthZero = 0xFF10;
const Set<String> _decimalPoints = {'.', '．', '。'};

String? _asciiDigit(String ch) {
  final code = ch.codeUnitAt(0);
  if (code >= 0x30 && code <= 0x39) return ch;
  if (code >= _fullWidthZero && code <= _fullWidthZero + 9) {
    return String.fromCharCode(0x30 + code - _fullWidthZero);
  }
  return null;
}

/// Format-only filter for the composer's amount field: digits and one decimal
/// point with at most two decimals, leading zeros folded
/// (`spec/red-packet-vectors.json` → amountInput). Range checks are the host's.
String flareRedPacketAmount(String raw) {
  final out = StringBuffer();
  var point = false;
  var decimals = 0;
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final digit = _asciiDigit(ch);
    if (digit != null) {
      if (point) {
        if (decimals >= 2) continue;
        decimals += 1;
      }
      out.write(digit);
    } else if (_decimalPoints.contains(ch) && !point) {
      point = true;
      out.write(out.isEmpty ? '0.' : '.');
    }
  }
  return out.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
}

/// Digits only, at most three, as a number; empty is 0
/// (`spec/red-packet-vectors.json` → countInput).
int flareRedPacketCount(String raw) {
  final digits = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final digit = _asciiDigit(ch);
    if (digit == null ||
        digits.length >= 3 ||
        (digit == '0' && digits.isEmpty)) {
      continue;
    }
    digits.write(digit);
  }
  return digits.isEmpty ? 0 : int.parse(digits.toString());
}

/// [flareRedPacketAmount] as a field formatter. The caret goes to the end of
/// the filtered text: it is a short numeric field, and a filtered edit has no
/// stable position to keep.
class FlareRedPacketAmountFormatter extends TextInputFormatter {
  const FlareRedPacketAmountFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _filtered(newValue, flareRedPacketAmount(newValue.text));
}

/// [flareRedPacketCount] as a field formatter; zero shows as an empty field.
class FlareRedPacketCountFormatter extends TextInputFormatter {
  const FlareRedPacketCountFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final count = flareRedPacketCount(newValue.text);
    return _filtered(newValue, count > 0 ? '$count' : '');
  }
}

TextEditingValue _filtered(TextEditingValue value, String text) {
  if (text == value.text) return value;
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
