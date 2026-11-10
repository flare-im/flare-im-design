import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_image_upload_slot.dart';

/// Controlled single-file surface. Picking, bytes, private previews and transfer
/// remain with the host. No URL is accepted or fetched by this component.
class FlareFileUpload extends StatelessWidget {
  const FlareFileUpload({
    super.key,
    required this.title,
    required this.state,
    this.fileName,
    this.progress,
    this.error,
    this.policyHint,
    this.preview = false,
    this.previewLoading = false,
    this.disabled = false,
    this.onChoose,
    this.onRetry,
    this.onCancel,
    this.onReplace,
    this.onRemove,
    this.onPreview,
  });
  final String title;
  final FlareImageUploadState state;
  final String? fileName, error, policyHint;
  final double? progress;
  final bool preview, previewLoading, disabled;
  final VoidCallback? onChoose,
      onRetry,
      onCancel,
      onReplace,
      onRemove,
      onPreview;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final status =
        error ??
        switch (state) {
          FlareImageUploadState.empty => policyHint ?? strings.pluginFileChoose,
          FlareImageUploadState.selected => strings.pluginFileSelected,
          FlareImageUploadState.uploading => strings.pluginFileUploading,
          FlareImageUploadState.uploaded => strings.pluginFileUploaded,
          FlareImageUploadState.failed => strings.pluginFileFailed,
        };
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
    final transferring =
        state == FlareImageUploadState.uploading ||
        state == FlareImageUploadState.selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlareImageUploadSlot(
          title: title,
          state: state,
          statusText: status,
          icon: 'file',
          pickLabel: strings.pluginFileChoose,
          progress: progress,
          previewHeight: FlareSizes.touchTargetMin * 2.5,
          disabled: disabled,
          onChoose: state == FlareImageUploadState.empty ? onChoose : onReplace,
          previewLabel: preview ? strings.pluginFilePreview : null,
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
        if (state != FlareImageUploadState.empty)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
            child: Wrap(
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingXs,
              children: [
                if (transferring) action(strings.cancel, onCancel),
                if (state == FlareImageUploadState.failed)
                  action(strings.retry, onRetry),
                if (state != FlareImageUploadState.uploading) ...[
                  action(strings.pluginFileReplace, onReplace),
                  action(strings.pluginFileRemove, onRemove, quiet: true),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
