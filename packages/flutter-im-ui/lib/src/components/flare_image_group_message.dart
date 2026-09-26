import 'package:flutter/material.dart';

import '../models/image_group_layout.dart';
import '../models/message_content.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'flare_media_image.dart';

/// image group — an album: square tiles laid out by the shared rule
/// (`spec/image-group-layout-vectors.json`), the last drawn tile covered with
/// `+N` when the album holds more images than tiles, and the album's
/// [description] under them.
///
/// Presentational: a tile calls [onOpen] with its image's index — the covered
/// tile opens its own image — and the host decides what opens (one image, or
/// the conversation's gallery). Every tile is a button named with its position
/// in the album; without [onOpen] the tiles are pictures only.
class FlareImageGroupMessage extends StatelessWidget {
  const FlareImageGroupMessage({
    super.key,
    required this.images,
    this.description = '',
    this.self = false,
    this.width = 240,
    this.onOpen,
  });

  final List<FlareImageContent> images;
  final String description;
  final bool self;
  final double width;
  final ValueChanged<int>? onOpen;

  @override
  Widget build(BuildContext context) {
    final count = images.length;
    if (count == 0) return const SizedBox.shrink();
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final layout = flareImageGroupLayout(count);
    const gap = FlareSizes.spacingXs;
    final side = (width - gap * (layout.columns - 1)) / layout.columns;
    final rows = <Widget>[];
    for (var start = 0; start < layout.visible; start += layout.columns) {
      final end = (start + layout.columns).clamp(0, layout.visible);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [
            for (var index = start; index < end; index++)
              _tile(index, side, layout, colors, strings),
          ],
        ),
      );
    }
    final text = description.trim();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: strings.messageImageGroupLabel(count),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: FlareSizes.spacing2xs,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: gap,
                children: rows,
              ),
            ),
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: self
                      ? colors.messageOutgoingForeground
                      : colors.messageIncomingForeground,
                  fontSize: FlareSizes.fontSizeMd,
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    int index,
    double side,
    FlareImageGroupLayout layout,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final image = images[index];
    final src = (image.thumbnailUrl ?? '').trim().isNotEmpty
        ? image.thumbnailUrl!
        : image.url;
    final placeholder = ColoredBox(
      color: colors.bgTertiary,
      child: Center(child: FlareIcon('image', color: colors.textTertiary)),
    );
    final covered = layout.covers(index);
    final open = onOpen;
    return SizedBox(
      width: side,
      height: side,
      child: Semantics(
        container: true,
        button: open != null,
        label: covered
            ? strings.messageImageGroupItemMore(
                index + 1,
                images.length,
                layout.more,
              )
            : strings.messageImageGroupItem(index + 1, images.length),
        excludeSemantics: true,
        onTap: open == null ? null : () => open(index),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open == null ? null : () => open(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              flareMediaImage(
                src,
                placeholder: placeholder,
                gaplessPlayback: true,
              ),
              if (covered)
                ColoredBox(
                  color: const Color(0x73000000),
                  child: Center(
                    child: Text(
                      '+${layout.more}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: FlareSizes.fontSize2xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
