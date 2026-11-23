import '../tokens/flare_tokens.dart';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../tokens/flare_strings.dart';

/// Plugin host capability components — pure rules shared by
/// [FlareCapabilityConsent], [FlareDocumentCapture] and
/// [FlarePaymentConfirmation] (spec/capability-ui-vectors.json;
/// docs/design/plugin-client-hot-delivery.md 7).
///
/// The kit draws what the engine asks the host (`plugin.capability_request`:
/// consent, captureDocument, confirmPayment). It never runs a request itself:
/// the host listens, shows the component, and answers the engine with what the
/// component hands back.

/// The viewer's answer to a consent prompt.
enum FlareCapabilityConsentDecision { once, always, deny }

/// What the host answers the engine's consent request with
/// (`plugin.capability_complete` result): `{decision: "once" | "always" |
/// "deny"}`. The engine keeps only "always"; "once" lets this request through
/// and keeps nothing, so the host never revokes anything to emulate it.
Map<String, Object?> flareCapabilityConsentAnswer(
  FlareCapabilityConsentDecision decision,
) => {'decision': decision.name};

/// The FlareStrings field naming what a plugin asks to use; an unknown
/// capability is the generic line, never its raw name.
String flareCapabilityLabelKey(
  String capability,
  Map<String, Object?>? params,
) => switch (capability) {
  'documentCapture' => 'capabilityDocumentCapture',
  'paymentConfirmation' => 'capabilityPaymentConfirmation',
  'locationOnce' =>
    params?['precision'] == 'fine'
        ? 'capabilityLocationFine'
        : 'capabilityLocationCoarse',
  'camera' => 'capabilityCamera',
  'microphone' => 'capabilityMicrophone',
  'rtcSession' => 'capabilityRtcSession',
  _ => 'capabilityGeneric',
};

/// The text of [flareCapabilityLabelKey] in [strings].
String flareCapabilityLabel(
  FlareStrings strings,
  String capability,
  Map<String, Object?>? params,
) => switch (flareCapabilityLabelKey(capability, params)) {
  'capabilityDocumentCapture' => strings.capabilityDocumentCapture,
  'capabilityPaymentConfirmation' => strings.capabilityPaymentConfirmation,
  'capabilityLocationFine' => strings.capabilityLocationFine,
  'capabilityLocationCoarse' => strings.capabilityLocationCoarse,
  'capabilityCamera' => strings.capabilityCamera,
  'capabilityMicrophone' => strings.capabilityMicrophone,
  'capabilityRtcSession' => strings.capabilityRtcSession,
  _ => strings.capabilityGeneric,
};

/// Whether the consent offers "Always allow": a one-time location is
/// confirmed every time.
bool flareCapabilityConsentAllowsAlways(String capability) =>
    capability != 'locationOnce';

// ── payment confirmation ─────────────────────────────────────────────────

/// The order the engine hands the host (`confirmPayment.order`).
class FlarePaymentOrder {
  const FlarePaymentOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.payee,
    required this.title,
    required this.expiresAtMs,
    this.operation,
  });

  /// The engine's `order` map; null when a required field is missing.
  static FlarePaymentOrder? fromJson(Map<String, Object?> json) {
    final orderId = json['orderId'], amount = json['amount'];
    final currency = json['currency'], expires = json['expiresAtMs'];
    if (orderId is! String || amount is! String || currency is! String) {
      return null;
    }
    if (expires is! num) return null;
    return FlarePaymentOrder(
      orderId: orderId,
      amount: amount,
      currency: currency,
      payee: json['payee'] is String ? json['payee'] as String : '',
      title: json['title'] is String ? json['title'] as String : '',
      expiresAtMs: expires.toInt(),
      operation: json['operation'] is String
          ? json['operation'] as String
          : null,
    );
  }

  final String orderId;

  /// Decimal string, up to 18 fraction digits.
  final String amount;
  final String currency;
  final String payee;
  final String title;

  /// Server clock.
  final int expiresAtMs;

  /// The plugin's transient operation; the kit never reads it.
  final String? operation;
}

/// The currency symbols the kit writes before an amount (R10); any other
/// code goes after the number ("3 LABPOINT"). One table for every amount.
const Map<String, String> flareCurrencyPrefix = {
  'CNY': '¥',
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'JPY': 'JP¥',
  'HKD': r'HK$',
};
final _plainDecimal = RegExp(r'^(\d+)(?:\.(\d{1,18}))?$');

/// The amount as the confirmation draws it: the currency's symbol (or the
/// code after the number), the integer part grouped by three, the fraction
/// exactly as written. Never a double. Null: not a plain non-negative decimal.
String? flarePaymentAmountText(String amount, String currency) {
  final match = _plainDecimal.firstMatch(amount);
  if (match == null) return null;
  final digits = match.group(1)!;
  final whole = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) whole.write(',');
    whole.write(digits[i]);
  }
  final fraction = match.group(2);
  final number = fraction == null ? '$whole' : '$whole.$fraction';
  final code = currency.trim().toUpperCase();
  final prefix = flareCurrencyPrefix[code];
  if (prefix != null) return '$prefix$number';
  return code.isEmpty ? number : '$number $code';
}

/// What is left of an order: whole seconds rounded up, mm:ss under an hour,
/// h:mm:ss from an hour on.
({String text, bool expired}) flarePaymentCountdown(int remainingMs) {
  if (remainingMs <= 0) return (text: '00:00', expired: true);
  final total = (remainingMs + 999) ~/ 1000;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return (
    text: hours > 0
        ? '$hours:${two(minutes)}:${two(seconds)}'
        : '${two(minutes)}:${two(seconds)}',
    expired: false,
  );
}

// ── document capture ──────────────────────────────────────────────────────

/// Which side of a document the capture takes.
enum FlareDocumentSide { front, back, holding }

/// The viewfinder frame's width over height: an ID-1 card for front and back,
/// 3:4 portrait for holding.
double flareDocumentFrameAspect(FlareDocumentSide side) =>
    side == FlareDocumentSide.holding
    ? 0.75
    : FlareSizes.componentDocumentFrameRatio;

/// The (longest edge, JPEG quality 0..1) steps the kit tries until the photo
/// fits; none fits: too large.
const List<(int, double)> flareDocumentCompressionPlan = [
  (2048, 0.86),
  (2048, 0.72),
  (2048, 0.58),
  (1600, 0.72),
  (1600, 0.58),
  (1280, 0.58),
  (1024, 0.5),
];

String flareDocumentFileName(FlareDocumentSide side) =>
    'document-${side.name}.jpg';

/// Whether an accept list takes the kit's JPEG (an empty list takes anything).
bool flareDocumentAcceptsJpeg(List<String>? accept) {
  if (accept == null || accept.isEmpty) return true;
  return accept.any((type) {
    final t = type.trim().toLowerCase();
    return t == 'image/jpeg' || t == 'image/*' || t == '*/*';
  });
}

/// One segment before the scan: its bytes `[start, end)` from its 0xFF, and
/// whether it may stay.
class _JpegSegment {
  const _JpegSegment(this.start, this.end, this.allowed);
  final int start;
  final int end;
  final bool allowed;
}

/// The segments before the scan and the scan's offset; null when [bytes] are
/// not a well-formed JPEG header.
(List<_JpegSegment>, int)? _jpegSegments(List<int> bytes) {
  int at(int i) => i < bytes.length ? bytes[i] & 0xFF : -1;
  bool startsWith(int from, String text) {
    if (from + text.length > bytes.length) return false;
    for (var i = 0; i < text.length; i++) {
      if (at(from + i) != text.codeUnitAt(i)) return false;
    }
    return true;
  }

  if (bytes.length < 4 || at(0) != 0xFF || at(1) != 0xD8) return null;
  final segments = <_JpegSegment>[];
  var i = 2;
  while (true) {
    if (at(i) != 0xFF) return null;
    // 0xFF fill bytes may come before a marker.
    while (at(i + 1) == 0xFF) {
      i++;
    }
    final marker = at(i + 1);
    if (marker < 0) return null;
    if (marker == 0xDA) return (segments, i);
    if (i + 4 > bytes.length) return null;
    final length = (at(i + 2) << 8) | at(i + 3);
    if (length < 2 || i + 2 + length > bytes.length) return null;
    final bool allowed;
    if (marker == 0xE0) {
      allowed = startsWith(i + 4, 'JFIF\u0000');
    } else if (marker == 0xE2) {
      allowed = startsWith(i + 4, 'ICC_PROFILE\u0000');
    } else if (marker == 0xEE) {
      allowed = startsWith(i + 4, 'Adobe');
    } else {
      allowed =
          marker == 0xDB ||
          marker == 0xC4 ||
          marker == 0xCC ||
          marker == 0xDD ||
          (marker >= 0xC0 && marker <= 0xCF && marker != 0xC8);
    }
    segments.add(_JpegSegment(i, i + 2 + length, allowed));
    i += 2 + length;
  }
}

/// Whether [bytes] are a JPEG with nothing but image data before its scan: an
/// APP0 JFIF header, an APP2 ICC profile, the APP14 Adobe segment, tables and
/// the frame header (0xFF fill allowed). Exif or XMP, MPF, IPTC, comments and
/// any other segment, a truncated header or no scan fail. The engine's own
/// rule (jpeg_is_stripped).
bool flareJpegIsStripped(List<int> bytes) {
  final parsed = _jpegSegments(bytes);
  return parsed != null && parsed.$1.every((segment) => segment.allowed);
}

/// The JPEG with only the segments [flareJpegIsStripped] allows before its
/// scan (and no fill bytes); the scan and what follows stay as they are.
/// Bytes that are not a well-formed JPEG header come back unchanged.
Uint8List flareJpegStrippingMetadata(List<int> bytes) {
  final parsed = _jpegSegments(bytes);
  if (parsed == null) return Uint8List.fromList(bytes);
  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  for (final segment in parsed.$1) {
    if (segment.allowed) out.add(bytes.sublist(segment.start, segment.end));
  }
  out.add(bytes.sublist(parsed.$2));
  return out.takeBytes();
}

/// The photo the capture hands the host: `captureDocument`'s `{file}`.
class FlareCapturedDocument {
  const FlareCapturedDocument({
    required this.fileName,
    required this.bytes,
    this.contentType = 'image/jpeg',
  });
  final String fileName;
  final String contentType;
  final Uint8List bytes;

  /// The engine's `{file}` shape (bytes as a number list).
  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'contentType': contentType,
    'bytes': bytes.toList(),
  };
}

enum FlareDocumentProcessError { tooLarge, failed, notAccepted }

class FlareDocumentProcessException implements Exception {
  const FlareDocumentProcessException(this.error);
  final FlareDocumentProcessError error;
  @override
  String toString() => 'FlareDocumentProcessException(${error.name})';
}

/// Re-encodes [photo] to a JPEG that fits [maxBytes], off the UI isolate: the
/// EXIF orientation is baked into the pixels, the metadata is dropped, then
/// the picture is scaled and encoded along [flareDocumentCompressionPlan], so
/// nothing of the original file (EXIF, GPS, maker notes, thumbnails) survives.
/// Throws [FlareDocumentProcessException].
Future<FlareCapturedDocument> flareProcessDocumentPhoto(
  Uint8List photo,
  FlareDocumentSide side, {
  required int maxBytes,
  List<String>? accept,
}) async {
  if (!flareDocumentAcceptsJpeg(accept)) {
    throw const FlareDocumentProcessException(
      FlareDocumentProcessError.notAccepted,
    );
  }
  final out = await Isolate.run(() => _encodeDocument(photo, maxBytes));
  if (out == null) {
    throw const FlareDocumentProcessException(
      FlareDocumentProcessError.tooLarge,
    );
  }
  // The image package writes no metadata once the EXIF data is cleared; whatever
  // an encoder might add besides image data goes all the same.
  final clean = flareJpegStrippingMetadata(out);
  if (!flareJpegIsStripped(clean)) {
    throw const FlareDocumentProcessException(FlareDocumentProcessError.failed);
  }
  return FlareCapturedDocument(
    fileName: flareDocumentFileName(side),
    bytes: clean,
  );
}

/// Null: no step fits. Empty: the photo could not be decoded.
Uint8List? _encodeDocument(Uint8List photo, int maxBytes) {
  final decoded = img.decodeImage(photo);
  if (decoded == null) return Uint8List(0);
  final upright = img.bakeOrientation(decoded);
  upright.exif = img.ExifData();
  for (final (edge, quality) in flareDocumentCompressionPlan) {
    final longest = upright.width > upright.height
        ? upright.width
        : upright.height;
    final scaled = longest > edge
        ? img.copyResize(
            upright,
            width: upright.width >= upright.height ? edge : null,
            height: upright.width < upright.height ? edge : null,
            interpolation: img.Interpolation.average,
          )
        : upright;
    scaled.exif = img.ExifData();
    final bytes = img.encodeJpg(scaled, quality: (quality * 100).round());
    if (bytes.length <= maxBytes) return bytes;
  }
  return null;
}
