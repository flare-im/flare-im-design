import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon.dart';

/// Controlled transfer state. The host owns picking, validation and transport.
enum FlareImageUploadState { empty, selected, uploading, uploaded, failed }

/// A compact image-upload slot shared by forms on phones and desktop.
///
/// [preview] is supplied by the host, for example an image picked in the current
/// session. The component never fetches or persists a file. An uploaded item can
/// remain a labelled placeholder when its private image is unavailable.
///
/// The image region chooses a file; the optional compact action can upload or
/// retry it. Hosts own those intents. Completed materials are read-only; the
/// component invents no remove/replace actions. Text is localized by the host.
class FlareImageUploadSlot extends StatelessWidget {
  const FlareImageUploadSlot({
    super.key,
    required this.title,
    required this.statusText,
    this.state = FlareImageUploadState.empty,
    this.pickLabel,
    this.actionLabel,
    this.preview,
    this.icon = 'camera',
    this.disabled = false,
    this.onChoose,
    this.onAction,
    this.previewLabel,
    this.previewLoading = false,
    this.progress,
    this.previewHeight,
    this.previewDisabled = false,
    this.onPreview,
  });

  final String title;
  final String statusText;
  final FlareImageUploadState state;
  final String? pickLabel;
  final String? actionLabel;
  final Widget? preview;
  final String icon;
  final bool disabled;
  final VoidCallback? onChoose;
  final VoidCallback? onAction;

  /// An independent read-only action for an uploaded item. Upload [disabled]
  /// does not disable viewing; hosts control that through [previewDisabled].
  final String? previewLabel;
  final bool previewLoading;

  /// Host-reported percentage; null keeps indeterminate progress.
  final double? progress;

  /// Optional compact media-region height; null preserves the photo-slot aspect ratio.
  final double? previewHeight;
  final bool previewDisabled;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final readOnly =
        state == FlareImageUploadState.uploaded ||
        state == FlareImageUploadState.uploading;
    final canChoose = !disabled && !readOnly && onChoose != null;
    final canAct = !disabled && !readOnly && onAction != null;
    final viewLabel = previewLabel?.trim();
    final previewMode =
        state == FlareImageUploadState.uploaded &&
        viewLabel != null &&
        viewLabel.isNotEmpty;
    final canPreview =
        previewMode && !previewLoading && !previewDisabled && onPreview != null;
    final regionEnabled = previewMode ? canPreview : canChoose;
    final regionAction = previewMode
        ? (canPreview ? onPreview : null)
        : (canChoose ? onChoose : null);
    final tone = switch (state) {
      FlareImageUploadState.uploaded => colors.successText,
      FlareImageUploadState.failed => colors.errorText,
      FlareImageUploadState.uploading => colors.primaryText,
      FlareImageUploadState.selected => colors.primaryText,
      FlareImageUploadState.empty => colors.textSecondary,
    };
    final statusIcon = switch (state) {
      FlareImageUploadState.uploaded => 'check',
      FlareImageUploadState.failed => 'refresh',
      FlareImageUploadState.uploading => 'clock',
      FlareImageUploadState.selected => 'image',
      FlareImageUploadState.empty => 'add',
    };
    final border = state == FlareImageUploadState.failed
        ? colors.error.withValues(alpha: 0.6)
        : colors.borderPrimary;
    final radius = BorderRadius.circular(FlareSizes.radiusCard);
    final choose = previewMode ? viewLabel : pickLabel?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: FlareSizes.fontSizeMd,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        Material(
          color: colors.bgPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: [
                  title,
                  statusText,
                  if ((previewMode || canChoose) && choose != null) choose,
                ].join(', '),
                value: previewLoading ? strings.loading : null,
                liveRegion: previewLoading,
                button: previewMode || (onChoose != null && !readOnly),
                enabled: regionEnabled,
                onTap: regionAction,
                excludeSemantics: true,
                child: InkWell(
                  onTap: regionAction,
                  focusColor: colors.primary.withValues(alpha: 0.12),
                  hoverColor: colors.primary.withValues(alpha: 0.05),
                  child: SizedBox(
                    height: previewHeight,
                    child: AspectRatio(
                      aspectRatio: 1.6,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!previewLoading || preview != null)
                            Padding(
                              padding: const EdgeInsets.all(
                                FlareSizes.spacingMd,
                              ),
                              child:
                                  preview ??
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FlareIcon(
                                          previewMode
                                              ? 'image'
                                              : state ==
                                                    FlareImageUploadState
                                                        .uploaded
                                              ? 'check'
                                              : icon,
                                          size: FlareSizes.iconSizeXl,
                                          color:
                                              state ==
                                                  FlareImageUploadState.uploaded
                                              ? colors.successText
                                              : colors.textTertiary,
                                        ),
                                        if ((previewMode || canChoose) &&
                                            choose != null &&
                                            choose.isNotEmpty) ...[
                                          const SizedBox(
                                            height: FlareSizes.spacingSm,
                                          ),
                                          Text(
                                            choose,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: FlareSizes.fontSizeSm,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                            ),
                          if (preview != null &&
                              (previewMode || canChoose) &&
                              choose != null &&
                              choose.isNotEmpty)
                            Positioned(
                              left: FlareSizes.spacingSm,
                              right: FlareSizes.spacingSm,
                              bottom: FlareSizes.spacingSm,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.bgPrimary.withValues(
                                      alpha: 0.94,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      FlareSizes.radiusMd,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: FlareSizes.spacingSm,
                                      vertical: FlareSizes.spacingXs,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FlareIcon(
                                          previewMode ? 'expand' : 'camera',
                                          size: FlareSizes.iconSizeSm,
                                        ),
                                        const SizedBox(
                                          width: FlareSizes.spacingXs,
                                        ),
                                        Flexible(
                                          child: Text(
                                            choose,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: FlareSizes.fontSizeSm,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (previewLoading)
                            Center(
                              child: CircularProgressIndicator(
                                color: colors.primary,
                                semanticsLabel: strings.loading,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (state == FlareImageUploadState.uploading || previewLoading)
                LinearProgressIndicator(
                  value:
                      previewLoading || progress == null || !progress!.isFinite
                      ? null
                      : progress!.clamp(0, 100).toDouble() / 100,
                  minHeight: FlareSizes.spacing3xs,
                  backgroundColor: colors.bgTertiary,
                  color: colors.primary,
                )
              else
                Divider(height: 1, color: colors.borderSecondary),
              Semantics(
                liveRegion:
                    state == FlareImageUploadState.uploading || previewLoading,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: FlareSizes.touchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd,
                      vertical: FlareSizes.spacing2sm,
                    ),
                    child: Row(
                      children: [
                        FlareIcon(
                          statusIcon,
                          size: FlareSizes.iconSizeSm,
                          color: tone,
                        ),
                        const SizedBox(width: FlareSizes.spacing2xs),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: tone,
                              fontSize: FlareSizes.fontSizeSm,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (actionLabel != null &&
                            onAction != null &&
                            !readOnly)
                          FlareButton(
                            label: actionLabel!,
                            variant: FlareButtonVariant.text,
                            size: FlareControlSize.sm,
                            maintainTouchTarget: true,
                            disabled: !canAct,
                            onPressed: onAction,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
