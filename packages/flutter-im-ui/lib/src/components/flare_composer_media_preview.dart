import 'package:flutter/material.dart';

import '../models/directory_data.dart' show FlareButtonVariant;
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon_button.dart';
import 'flare_media_upload.dart';
import 'flare_storage_usage.dart';
import 'flare_textarea.dart';

/// Contents of a composer's attachment confirmation dialog or sheet.
class FlareComposerMediaPreview extends StatelessWidget {
  const FlareComposerMediaPreview({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onCancel,
    required this.onSend,
    this.onPreview,
    this.captionPlaceholder,
    this.caption = '',
    this.onCaptionChanged,
    this.notice,
    this.error,
    this.sendKey,
  });

  final List<FlareMediaUploadItem> items;
  final ValueChanged<String> onRemove;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final ValueChanged<String>? onPreview;
  final String? captionPlaceholder;
  final String caption;
  final ValueChanged<String>? onCaptionChanged;
  final Widget? notice;
  final Widget? error;
  final Key? sendKey;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notice != null) ...[
          notice!,
          const SizedBox(height: FlareSizes.spacingSm),
        ],
        if (items.length == 1)
          _single(context, items.single)
        else if (items.isNotEmpty)
          FlareMediaUpload(
            title: strings.composerImagePreview,
            items: items,
            statusText: '',
            pickLabel: strings.pluginFileChoose,
            removeLabel: strings.pluginFileRemove,
            showPicker: false,
            onRemove: onRemove,
            onPreview: onPreview,
          ),
        if (captionPlaceholder != null && items.isNotEmpty) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          FlareTextarea(
            value: caption,
            placeholder: captionPlaceholder,
            semanticLabel: captionPlaceholder,
            rows: 2,
            maxRows: 4,
            onChanged: onCaptionChanged,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: FlareSizes.spacingSm),
          error!,
        ],
        const SizedBox(height: FlareSizes.spacingMd),
        Divider(height: 1, color: FlareColors.of(context).borderSecondary),
        const SizedBox(height: FlareSizes.spacingMd),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: FlareSizes.spacingSm,
          runSpacing: FlareSizes.spacingSm,
          children: [
            FlareButton(
              label: strings.cancel,
              variant: FlareButtonVariant.secondary,
              onPressed: onCancel,
            ),
            FlareButton(
              key: sendKey,
              label: strings.send,
              disabled: items.isEmpty,
              onPressed: onSend,
            ),
          ],
        ),
      ],
    );
  }

  Widget _single(BuildContext context, FlareMediaUploadItem item) {
    final colors = FlareColors.of(context);
    final size = formatBytes(item.sizeBytes);
    final image = item.image;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border.all(color: colors.borderSecondary),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              if (image != null)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: InkWell(
                    onTap: onPreview == null ? null : () => onPreview!(item.id),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.37,
                      ),
                      child: Image(
                        image: image,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox(height: 44),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 44),
              FlareIconButton(
                icon: 'close',
                semanticLabel: FlareStrings.of(context).pluginFileRemove,
                onPressed: () => onRemove(item.id),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                if (size != null) ...[
                  const SizedBox(width: FlareSizes.spacingSm),
                  Text(size, style: TextStyle(color: colors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
