import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Image grid — a chat-message gallery of up to [max] thumbnails laid out in a
/// balanced 1–3 column grid. A single image renders larger (contain); when more
/// than [max] images are supplied the last visible tile shows a "+N" overflow
/// scrim. Spec: Message/ImageGrid (`FlareImageGrid`).
class FlareImageGrid extends StatelessWidget {
  const FlareImageGrid({
    super.key,
    required this.images,
    this.max = 9,
    this.onOpen,
  });

  final List<FlareGridImage> images;
  final int max;
  final void Function(int index)? onOpen;

  int _columns(int n) {
    if (n <= 1) return 1;
    if (n == 4) return 2;
    if (n <= 3) return n;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final visible = images.take(max).toList();
    final visibleCount = visible.length;
    final overflow = images.length - visibleCount;

    if (visibleCount == 0) return const SizedBox.shrink();

    if (visibleCount == 1) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220, maxHeight: 260),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          child: _cell(colors, visible[0], 0,
              overflow: 0, single: true),
        ),
      );
    }

    final columns = _columns(visibleCount);
    final width = columns * 84.0 + (columns - 1) * 4.0;
    return SizedBox(
      width: width,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < visibleCount; i++)
            _cell(
              colors,
              visible[i],
              i,
              overflow: i == visibleCount - 1 ? overflow : 0,
              single: false,
            ),
        ],
      ),
    );
  }

  Widget _cell(
    FlareColors colors,
    FlareGridImage image,
    int index, {
    required int overflow,
    required bool single,
  }) {
    final url = image.url;
    Widget content = url != null && url.isNotEmpty
        ? Image.network(
            url,
            fit: single ? BoxFit.contain : BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(color: colors.bgSecondary),
          )
        : ColoredBox(color: colors.bgSecondary);

    if (overflow > 0) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Container(
            color: const Color(0x99000000),
            alignment: Alignment.center,
            child: Text(
              '+$overflow',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final cell = GestureDetector(
      onTap: onOpen == null ? null : () => onOpen!(index),
      behavior: HitTestBehavior.opaque,
      child: content,
    );

    if (single) return cell;

    return SizedBox(
      width: 84,
      height: 84,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        child: cell,
      ),
    );
  }
}
