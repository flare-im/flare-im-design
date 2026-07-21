import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// The Moments profile header: a tall cover photo (tap → [onEditCover]) with the
/// user's name / signature and a rounded-square avatar (tap → [onAvatar])
/// overhanging its bottom-right edge. Spec: Moments/CoverHeader
/// (`FlareMomentsCoverHeader`).
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

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onEditCover,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 240,
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
                  Positioned(
                    right: 14,
                    bottom: 40,
                    child: Text(
                      'Edit cover',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0x59000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (signature != null && signature!.isNotEmpty) ...[
                            const SizedBox(height: FlareSizes.spacingXs),
                            Text(
                              signature!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
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
                        color: colors.bgPrimary,
                        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
                        border: Border.all(color: colors.bgPrimary, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3315131C),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: FlareAvatar(
                          userId: userId,
                          displayName: name,
                          avatarUrl: avatarUrl,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
