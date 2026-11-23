import 'package:flutter/material.dart';

import '../primitives/flare_presence_dot.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// Presence state shown as a corner dot on [FlareAvatar].
///
/// The neutral spec models this as the string union
/// `'online' | 'offline' | 'busy' | 'away'`; Dart uses an enum (native idiom).
enum FlarePresence { online, offline, busy, away }

/// Round user avatar with an image, or deterministic initials fallback, and an
/// optional presence dot. Spec: General/Avatar (`FlareAvatar`).
///
/// With [onTap] the avatar is a button named by [displayName], with a touch target of
/// at least [FlareSizes.touchTarget] however small the avatar is drawn — the way an
/// avatar opens a profile from a header.
class FlareAvatar extends StatelessWidget {
  const FlareAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.size = FlareSizes.avatarSize,
    this.presence,
    this.onTap,
    this.semanticLabel,
    this.group = false,
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

  /// A group's avatar: a people mark in the corner, in place of the presence dot a
  /// group never has (Vue `FlareAvatar` `group`).
  final bool group;

  /// Opens whatever this avatar stands for (usually the person's profile).
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    // Seed by the stable display name (not the id, which varies by surface — peer
    // id vs conversation id vs sender id) so a person is one colour everywhere:
    // list, chat header, message bubbles.
    final tint = seedTint(
      displayName.isNotEmpty ? displayName : userId,
      FlareColors.of(context),
    );
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.$1,
        shape: BoxShape.circle,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
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

    if (group) {
      // The avatar's palette inverted, ringed in the surface colour so it stands off any
      // tint or photo; the filled two-person glyph, since an outlined one at this size is a smudge.
      final mark = (size * 0.45).roundToDouble();
      return _tappable(
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: mark,
                  height: mark,
                  decoration: BoxDecoration(
                    color: tint.$2,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.bgPrimary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.people,
                    size: (mark * 0.5).roundToDouble(),
                    color: tint.$1,
                    semanticLabel: FlareStrings.of(context).displayNameGroup,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (presence == null) return _tappable(avatar);

    final dot = size * 0.28;
    return _tappable(
      SizedBox(
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
      ),
    );
  }

  /// The avatar as a named button when the host gave it something to open, with a
  /// target that reaches past a small avatar; otherwise exactly what it was.
  Widget _tappable(Widget child) {
    if (onTap == null) return child;
    return Semantics(
      button: true,
      container: true,
      // The initials are decoration once the avatar is a control: it is named by the person.
      excludeSemantics: true,
      label: semanticLabel ?? displayName,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: FlareSizes.touchTarget,
            minHeight: FlareSizes.touchTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }

  /// The name's first character, as the Vue `FlareAvatar` draws it ("Lab Bob"
  /// → "L", "群签到" → "群").
  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  /// Soft pastel identity — matches the reference app (avatarPastelForKey): a
  /// tinted surface + dark initials reads more premium than a saturated solid
  /// and stays legible in both themes. Returns (background, foreground).
  /// 身份色板来自 token 真源(`colors.avatarTint.*`),四端同值**并且有暗色**。
  /// 原来是六组写死的浅色:暗色下头像会当作一块浅色马卡龙糊在深色表面上。
  /// 顺序是契约的一部分(按种子哈希取模选色),按真源里的插入序。
  static (Color, Color) seedTint(String seed, FlareColors colors) {
    final pairs = <(Color, Color)>[
      (colors.avatarTintBlueBg, colors.avatarTintBlueFg),
      (colors.avatarTintPurpleBg, colors.avatarTintPurpleFg),
      (colors.avatarTintPinkBg, colors.avatarTintPinkFg),
      (colors.avatarTintGreenBg, colors.avatarTintGreenFg),
      (colors.avatarTintAmberBg, colors.avatarTintAmberFg),
      (colors.avatarTintSlateBg, colors.avatarTintSlateFg),
    ];
    return pairs[flareAvatarTintIndex(seed)];
  }
}

/// The palette slot for [seed], the Vue kit's `avatarTint`
/// (`shared/avatar-tint.ts`) to the bit, so one name is one colour on every
/// kit: JS `hash = code + ((hash << 5) - hash)` over the seed's code points
/// (each one's first UTF-16 unit), the shift on `ToInt32(hash)` while the sum
/// stays a double; a blank seed hashes `"user"`; slot `abs(hash) % 6`.
int flareAvatarTintIndex(String seed) {
  var hash = 0.0;
  for (final rune in (seed.trim().isEmpty ? 'user' : seed).runes) {
    final unit = rune > 0xFFFF ? 0xD800 + ((rune - 0x10000) >> 10) : rune;
    final int32 = (hash.truncate() & 0xFFFFFFFF).toSigned(32);
    hash = unit + (((int32 << 5) & 0xFFFFFFFF).toSigned(32) - hash);
  }
  return (hash.abs() % 6).toInt();
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
