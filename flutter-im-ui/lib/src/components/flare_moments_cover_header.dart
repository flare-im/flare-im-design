import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// The Moments profile header: a tall cover photo (tap → [onEditCover]) with a
/// top-right 换封面 affordance, and the user's name / signature rendered in white
/// over the cover's lower scrim (legible on any cover image). A rounded-square
/// avatar (tap → [onAvatar]) overhangs the cover's bottom edge — soft shadow,
/// no white frame. Spec: Moments/CoverHeader (`FlareMomentsCoverHeader`).
class FlareMomentsCoverHeader extends StatelessWidget {
  const FlareMomentsCoverHeader({
    super.key,
    required this.userId,
    required this.name,
    this.coverUrl,
    this.avatarUrl,
    this.signature,
    this.onEditCover,
    this.onAvatar,
  });

  final String userId;
  final String name;
  final String? coverUrl;
  final String? avatarUrl;
  final String? signature;
  final VoidCallback? onEditCover;
  final VoidCallback? onAvatar;

  static const double _coverHeight = 240;
  static const double _avatarSize = 66;
  // How far the avatar overhangs the cover's bottom edge.
  static const double _overhang = 24;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingLg),
      child: SizedBox(
        height: _coverHeight + _overhang,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Cover photo + scrim + 换封面 affordance ──────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _coverHeight,
              child: GestureDetector(
                onTap: onEditCover,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasCover)
                      Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gradient(),
                      )
                    else
                      _gradient(),
                    // Bottom scrim so name + signature stay legible over any cover.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x6B0F0C19)],
                          stops: [0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: _EditCoverPill(),
                    ),
                  ],
                ),
              ),
            ),
            // ── Name / signature (white, over scrim) + overhanging avatar ────
            Positioned(
              left: FlareSizes.spacingLg,
              right: FlareSizes.spacingLg,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Padding(
                      // Lift the text so it sits over the cover's dark scrim.
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0x73000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (signature != null && signature!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              signature!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xE0FFFFFF),
                                shadows: [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  GestureDetector(
                    onTap: onAvatar,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: BoxDecoration(
                        // No white frame — a soft shadow lifts the rounded square.
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4715131C),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FlareAvatar(
                          userId: userId,
                          displayName: name,
                          avatarUrl: avatarUrl,
                          size: _avatarSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradient() {
    // Aurora — a deep violet light source rather than a flat two-stop gradient.
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1F7A), Color(0xFF7C3AED), Color(0xFFA78BFA)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// The 换封面 pill floated top-right of the cover, clear of the avatar.
class _EditCoverPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x520F0C19),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.photo_camera_outlined, size: 13, color: Color(0xEBFFFFFF)),
          SizedBox(width: 4),
          Text(
            'Edit cover',
            style: TextStyle(fontSize: 12, color: Color(0xEBFFFFFF)),
          ),
        ],
      ),
    );
  }
}
