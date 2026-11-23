import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_image_upload_slot.dart';

/// Controlled single-file surface. The host owns picking, validation, previews
/// and transfer. Action labels explicitly offer the corresponding intent.
class FlareFileUpload extends StatelessWidget {
  const FlareFileUpload({
    super.key,
    required this.title,
    required this.state,
    required this.statusText,
    this.fileName,
    this.progress,
    this.image = false,
    this.preview,
    this.previewLabel,
    this.previewLoading = false,
    this.disabled = false,
    this.onChoose,
    this.onUpload,
    this.onRetry,
    this.onCancel,
    this.onReplace,
    this.onRemove,
    this.onPreview,
    this.pickLabel,
    this.uploadLabel,
    this.replaceLabel,
    this.retryLabel,
    this.cancelLabel,
    this.removeLabel,
    this.icon,
  });
  final String title, statusText;
  final String? fileName,
      pickLabel,
      uploadLabel,
      replaceLabel,
      retryLabel,
      cancelLabel,
      removeLabel,
      previewLabel;
  final String? icon;
  final FlareImageUploadState state;
  final double? progress;
  final bool image, previewLoading, disabled;

  /// Host-owned local content; this component never fetches a preview URL.
  final Widget? preview;
  final VoidCallback? onChoose,
      onUpload,
      onRetry,
      onCancel,
      onReplace,
      onRemove,
      onPreview;

  @override
  Widget build(BuildContext context) {
    Widget action(String label, VoidCallback? callback, {bool quiet = false}) =>
        FlareButton(
          label: label,
          onPressed: callback,
          disabled: disabled || callback == null,
          variant: quiet
              ? FlareButtonVariant.text
              : FlareButtonVariant.secondary,
          size: FlareControlSize.sm,
        );
    final mutable =
        state != FlareImageUploadState.empty &&
        state != FlareImageUploadState.uploading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlareImageUploadSlot(
          title: title,
          state: state,
          statusText: statusText,
          icon: icon ?? (image ? 'camera' : 'file'),
          pickLabel: pickLabel,
          preview: image ? preview : null,
          progress: progress,
          previewHeight: FlareSizes.touchTargetMin * 2.5,
          disabled: disabled,
          onChoose: state == FlareImageUploadState.empty
              ? onChoose
              : replaceLabel == null
              ? null
              : onReplace,
          previewLabel: previewLabel,
          previewLoading: previewLoading,
          previewDisabled: disabled,
          onPreview: onPreview,
        ),
        if (fileName?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
            child: Text(
              fileName!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if ((state == FlareImageUploadState.uploading ||
                    state == FlareImageUploadState.selected) &&
                cancelLabel != null ||
            state == FlareImageUploadState.failed && retryLabel != null ||
            state == FlareImageUploadState.selected && uploadLabel != null ||
            mutable && (replaceLabel != null || removeLabel != null))
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
            child: Wrap(
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingXs,
              children: [
                if ((state == FlareImageUploadState.uploading ||
                        state == FlareImageUploadState.selected) &&
                    cancelLabel != null)
                  action(cancelLabel!, onCancel),
                if (state == FlareImageUploadState.failed && retryLabel != null)
                  action(retryLabel!, onRetry),
                if (state == FlareImageUploadState.selected &&
                    uploadLabel != null)
                  action(uploadLabel!, onUpload),
                if (mutable && replaceLabel != null)
                  action(replaceLabel!, onReplace),
                if (mutable && removeLabel != null)
                  action(removeLabel!, onRemove, quiet: true),
              ],
            ),
          ),
      ],
    );
  }
}
