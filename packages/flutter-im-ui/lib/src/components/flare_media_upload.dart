import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import '../models/directory_data.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_image_upload_slot.dart';
import 'icon_control.dart';

/// One picked file in a [FlareMediaUpload].
@immutable
class FlareMediaUploadItem {
  const FlareMediaUploadItem({
    required this.id,
    required this.name,
    required this.state,
    required this.statusText,
    this.image,
    this.sizeBytes,
    this.disabled = false,
  });

  final String id;
  final String name;
  final FlareImageUploadState state;

  /// What this file's state means in the host's words (waiting / uploading /
  /// uploaded / the failure).
  final String statusText;

  /// The host's preview: a picked local file, or the uploaded address.
  final ImageProvider? image;
  final int? sizeBytes;
  final bool disabled;
}

/// A controlled grid of picked images, each with its own transfer state, and
/// an add tile — the moment composer's photos. Spec: Media/MediaUpload
/// (`FlareMediaUpload`, images layout), the Vue kit's component of the same
/// name.
///
/// The host owns the picker ([onPick]), the transfers and the previews; the
/// grid never starts an upload. Three columns; the count `n / max` sits by the
/// title. A failed tile offers [onRetry]; any tile but an uploading one can be
/// removed ([onRemove]); a tile with an image opens [onPreview]. The add tile
/// shows while [showPicker], not [disabled] and below [maxCount].
class FlareMediaUpload extends StatelessWidget {
  const FlareMediaUpload({
    super.key,
    required this.title,
    required this.items,
    required this.statusText,
    required this.pickLabel,
    this.maxCount,
    this.disabled = false,
    this.showPicker = true,
    this.retryLabel,
    this.removeLabel,
    this.previewLabel,
    this.onPick,
    this.onRetry,
    this.onRemove,
    this.onPreview,
  });

  final String title;
  final List<FlareMediaUploadItem> items;
  final String statusText;
  final String pickLabel;
  final int? maxCount;
  final bool disabled;
  final bool showPicker;
  final String? retryLabel;
  final String? removeLabel;
  final String? previewLabel;
  final VoidCallback? onPick;
  final ValueChanged<String>? onRetry;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final max = maxCount;
    final full = max != null && items.length >= max;
    final canPick = showPicker && !disabled && !full && onPick != null;
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vue images layout: the title and the hint are the group's name and
          // the add key's tooltip, not drawn lines; only the count shows.
          if (max != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                '${items.length} / $max',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: FlareSizes.spacingSm),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: FlareSizes.componentMediaImageMaxWidth,
              ),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: FlareSizes.spacingSm,
                crossAxisSpacing: FlareSizes.spacingSm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final item in items) _tile(context, colors, item),
                  if (canPick) _add(context, colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _add(BuildContext context, FlareColors colors) => FlareIconControl(
    label: '$pickLabel: $title',
    onTap: onPick,
    child: Tooltip(
      message: statusText,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: SizedBox.expand(
          child: Center(child: FlareIcon('add', color: colors.textSecondary)),
        ),
      ),
    ),
  );

  Widget _tile(
    BuildContext context,
    FlareColors colors,
    FlareMediaUploadItem item,
  ) {
    final strings = FlareStrings.of(context);
    final locked = disabled || item.disabled;
    final failed = item.state == FlareImageUploadState.failed;
    final uploading = item.state == FlareImageUploadState.uploading;
    final image = item.image;
    final preview = onPreview;
    final canPreview = !locked && image != null && preview != null;
    final remove = onRemove;
    final retry = onRetry;
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          button: canPreview,
          enabled: canPreview,
          label:
              '${previewLabel ?? strings.pluginFilePreview}: ${item.name}, ${item.statusText}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: canPreview ? () => preview(item.id) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  border: failed
                      ? Border.all(color: colors.error.withValues(alpha: 0.6))
                      : null,
                ),
                child: image == null
                    ? const Center(child: FlareIcon('image'))
                    : Image(
                        image: image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Center(child: FlareIcon('image')),
                      ),
              ),
            ),
          ),
        ),
        if (uploading || failed)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(FlareSizes.spacingXs),
              color: colors.scrim,
              child: failed && retry != null && !locked
                  ? FlareButton(
                      size: FlareControlSize.sm,
                      variant: FlareButtonVariant.secondary,
                      label: retryLabel ?? strings.retry,
                      onPressed: () => retry(item.id),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (uploading)
                          const SizedBox.square(
                            dimension: FlareSizes.iconSizeSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        const SizedBox(width: FlareSizes.spacingXs),
                        Flexible(
                          child: Text(
                            item.statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: FlareSizes.fontSizeXs,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        if (!uploading && !locked && remove != null)
          Positioned(
            top: 0,
            right: 0,
            child: FlareIconControl(
              label: '${removeLabel ?? strings.pluginFileRemove}: ${item.name}',
              onTap: () => remove(item.id),
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0x8C111318),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FlareIcon(
                    'close',
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
