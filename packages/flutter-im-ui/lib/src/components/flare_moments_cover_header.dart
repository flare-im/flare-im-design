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
/// the image's lower scrim and the round avatar overhangs it on a ring of the
/// page ground. Without one the header is a compact identity row on the page
/// ground over a hairline, the name and signature in the normal text colours
/// (Vue `.flare-moments-cover--empty`). The cover photo is a control named
/// [FlareStrings.changeCover] only with [onEditCover] (without a photo a quiet
/// 换封面 word ends the row), and the avatar only with [onAvatar].
class FlareMomentsCoverHeader extends StatelessWidget {
  const FlareMomentsCoverHeader({
    super.key,
    required this.userId,
    required this.name,
    this.coverUrl,
    this.coverImage,
    this.avatarUrl,
    this.signature,
    this.onEditCover,
    this.onAvatar,
  });

  final String userId;
  final String name;
  final String? coverUrl;

  /// A cover the host already holds (a picked local image); wins over
  /// [coverUrl].
  final ImageProvider? coverImage;
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
  // How far the avatar overhangs the cover's bottom edge.
  static const double _overhang = 24;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final hasCover =
        coverImage != null || (coverUrl != null && coverUrl!.isNotEmpty);
    final coverHeight = hasCover ? _coverHeight : _emptyCoverHeight;
    if (!hasCover) return _compactIdentity(context, colors, strings);

    Widget cover = Stack(
      fit: StackFit.expand,
      children: [
        if (hasCover) ...[
          Image(
            image: coverImage ?? NetworkImage(coverUrl!),
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

    Widget avatar = _avatar(colors, 56);
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
                              fontSize: 18,
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
  /// the page ground, sized by its content. The change-cover affordance has
  /// no photo to sit on top of, so it ends the row instead of floating over a
  /// blank band.
  Widget _compactIdentity(
    BuildContext context,
    FlareColors colors,
    FlareStrings strings,
  ) {
    Widget avatar = _avatar(colors, 48);
    avatar = onAvatar == null
        ? ExcludeSemantics(child: avatar)
        : FlareContentControl(label: name, onTap: onAvatar!, child: avatar);

    // Vue `.flare-moments-cover__hint`: a quiet word that ends the row.
    Widget? hint;
    if (onEditCover != null) {
      hint = Semantics(
        button: true,
        child: InkWell(
          onTap: onEditCover,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: FlareSizes.touchTarget,
              minHeight: FlareSizes.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingSm,
                  vertical: FlareSizes.spacingXs,
                ),
                child: Text(
                  strings.changeCover,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeSm,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border(bottom: BorderSide(color: colors.borderSecondary)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
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
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (signature != null && signature!.isNotEmpty) ...[
                    const SizedBox(height: 5),
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
            if (hint != null) ...[
              const SizedBox(width: FlareSizes.spacingMd),
              hint,
            ],
          ],
        ),
      ),
    );
  }

  /// The round avatar with a 2px ring of the page ground.
  Widget _avatar(FlareColors colors, double size) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: colors.bgPrimary, spreadRadius: 2)],
    ),
    child: FlareAvatar(
      userId: userId,
      displayName: name,
      avatarUrl: avatarUrl,
      size: size,
    ),
  );

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
