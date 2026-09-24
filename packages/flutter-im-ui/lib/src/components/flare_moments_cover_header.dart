import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'content_control.dart';
import 'flare_avatar.dart';

/// The Moments profile header: a cover band with the user's name / signature
/// and a rounded-square avatar overhanging its bottom edge. Spec:
/// Moments/CoverHeader (`FlareMomentsCoverHeader`).
///
/// With a cover image the band is tall, the name and signature are white over
/// the image's lower scrim and the avatar lifts on a soft shadow. Without one
/// the header stays quiet: a short neutral band on the tertiary surface, no
/// brand gradient or scrim, and the name and signature in the normal text
/// colours. The cover is a control named [FlareStrings.changeCover] (with its
/// 换封面 pill) only with [onEditCover], and the avatar only with [onAvatar].
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
  // Without an image there is no band to reserve: the header is the identity row
  // itself. It used to reserve 140 and keep the photo geometry — the name right
  // aligned and pulled up onto where the scrim would be — but right alignment,
  // the overlap and the overhang only mean something with a photo under them,
  // so that left ~110 of empty band above a name glued to its bottom-right.
  static const double _emptyCoverHeight = 0;
  static const double _avatarSize = 66;
  // How far the avatar overhangs the cover's bottom edge.
  static const double _overhang = 24;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    final coverHeight = hasCover ? _coverHeight : _emptyCoverHeight;
    if (!hasCover) return _compactIdentity(context, colors, strings);

    Widget cover = Stack(
      fit: StackFit.expand,
      children: [
        if (hasCover) ...[
          Image.network(
            coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _gradient(colors),
          ),
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
        ] else
          ColoredBox(color: colors.bgTertiary),
        if (onEditCover != null)
          Positioned(
            right: 14,
            top: 14,
            child: _EditCoverPill(
              label: strings.changeCover,
              onImage: hasCover,
            ),
          ),
      ],
    );
    if (onEditCover != null) {
      cover = FlareContentControl(
        label: strings.changeCover,
        onTap: onEditCover!,
        insetRing: true,
        child: cover,
      );
    }

    Widget avatar = Container(
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
    );
    avatar = onAvatar == null
        // The name beside it already says who this is.
        ? ExcludeSemantics(child: avatar)
        : FlareContentControl(label: name, onTap: onAvatar!, child: avatar);

    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingLg),
      child: SizedBox(
        height: coverHeight + _overhang,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: coverHeight,
              child: cover,
            ),
            // ── Name / signature + overhanging avatar ────────────────────────
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
                      // Lift the text so it sits over the cover's lower part.
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
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: hasCover
                                  ? Colors.white
                                  : colors.textPrimary,
                              shadows: hasCover
                                  ? const [
                                      Shadow(
                                        color: Color(0x73000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          if (signature != null && signature!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              signature!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: hasCover
                                    ? const Color(0xE0FFFFFF)
                                    : colors.textSecondary,
                                shadows: hasCover
                                    ? const [
                                        Shadow(
                                          color: Color(0x66000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  avatar,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The no-cover header: avatar, then name and signature, in reading order on
  /// the tertiary surface, sized by its content. The change-cover affordance has
  /// no photo to sit on top of, so it ends the row instead of floating over a
  /// blank band.
  Widget _compactIdentity(
    BuildContext context,
    FlareColors colors,
    FlareStrings strings,
  ) {
    Widget avatar = Container(
      decoration: BoxDecoration(
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
    );
    avatar = onAvatar == null
        ? ExcludeSemantics(child: avatar)
        : FlareContentControl(label: name, onTap: onAvatar!, child: avatar);

    Widget? pill;
    if (onEditCover != null) {
      pill = FlareContentControl(
        label: strings.changeCover,
        onTap: onEditCover!,
        child: _EditCoverPill(label: strings.changeCover, onImage: false),
      );
    }

    return ColoredBox(
      color: colors.bgTertiary,
      child: Padding(
        padding: const EdgeInsets.all(FlareSizes.spacingMd),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (signature != null && signature!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      signature!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (pill != null) ...[
              const SizedBox(width: FlareSizes.spacingSm),
              pill,
            ],
          ],
        ),
      ),
    );
  }

  /// Shown when a cover image fails to load, keeping the image look.
  Widget _gradient(FlareColors colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryActive, colors.primary, colors.primaryHover],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// The 换封面 pill floated top-right of the cover, clear of the avatar: dark
/// glass over an image, a quiet elevated chip over the neutral band.
class _EditCoverPill extends StatelessWidget {
  const _EditCoverPill({required this.label, required this.onImage});

  final String label;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final foreground = onImage ? const Color(0xEBFFFFFF) : colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: onImage ? const Color(0x520F0C19) : colors.bgElevated,
        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
        border: onImage ? null : Border.all(color: colors.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_camera_outlined, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeSm,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
