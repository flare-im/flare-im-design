import 'package:flutter/material.dart';

import '../primitives/flare_presence_dot.dart';
import '../tokens/flare_tokens.dart';

/// Presence state shown as a corner dot on [FlareAvatar].
///
/// The neutral spec models this as the string union
/// `'online' | 'offline' | 'busy' | 'away'`; Dart uses an enum (native idiom).
enum FlarePresence { online, offline, busy, away }

/// Round user avatar with an image, or deterministic initials fallback, and an
/// optional presence dot. Spec: General/Avatar (`FlareAvatar`).
class FlareAvatar extends StatelessWidget {
  const FlareAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.size = FlareSizes.avatarSize,
    this.presence,
  });

  /// Stable identity — seeds the fallback background colour.
  final String userId;

  /// Human name — source of the initials fallback.
  final String displayName;

  /// Optional avatar image URL; when absent/empty, initials are shown.
  final String? avatarUrl;

  /// Diameter in logical pixels. Defaults to the layout avatar token.
  final double size;

  /// Optional presence indicator.
  final FlarePresence? presence;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    // Seed by the stable display name (not the id, which varies by surface — peer
    // id vs conversation id vs sender id) so a person is one colour everywhere:
    // list, chat header, message bubbles.
    final tint = _seedTint(displayName.isNotEmpty ? displayName : userId);
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.$1,
        shape: BoxShape.circle,
        image: hasImage
            ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              _initials(displayName),
              style: TextStyle(
                color: tint.$2,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    if (presence == null) return avatar;

    final dot = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: FlarePresenceDot(
              color: flarePresenceColor(colors, presence!),
              size: dot,
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Soft pastel identity — matches the reference app (avatarPastelForKey): a
  /// tinted surface + dark initials reads more premium than a saturated solid
  /// and stays legible in both themes. Returns (background, foreground).
  static (Color, Color) _seedTint(String seed) {
    const pairs = <(Color, Color)>[
      (Color(0xFFDBEAFE), Color(0xFF1D4ED8)), // blue
      (Color(0xFFE9D5FF), Color(0xFF6D28D9)), // purple
      (Color(0xFFFBCFE8), Color(0xFFBE185D)), // pink
      (Color(0xFFD1FAE5), Color(0xFF047857)), // green
      (Color(0xFFFEF3C7), Color(0xFFB45309)), // amber
      (Color(0xFFE5E7EB), Color(0xFF374151)), // slate
    ];
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return pairs[hash % pairs.length];
  }
}

/// Maps a presence to its token colour. Public so rows/cards can drive a
/// [FlarePresenceDot] with the same semantics as the avatar.
Color flarePresenceColor(FlareColors colors, FlarePresence presence) {
  switch (presence) {
    case FlarePresence.online:
      return colors.success;
    case FlarePresence.busy:
      return colors.error;
    case FlarePresence.away:
      return colors.warning;
    case FlarePresence.offline:
      return colors.textTertiary;
  }
}
