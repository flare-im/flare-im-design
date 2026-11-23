import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_plugin_form.dart';

/// A protected media block (spec Message/PluginView, protected-media): private
/// material read one item at a time. Nothing is fetched until the viewer
/// asks; a block that declares a reason input first asks why, the owner's own
/// page reads with one tap. The host runs the read ([onRead]) and hands the
/// address back in [states]. The picture is held in memory only (the image
/// cache, never a file) and offers no save or share menu.
class FlarePluginProtectedMediaView extends StatelessWidget {
  const FlarePluginProtectedMediaView({
    super.key,
    required this.block,
    this.states = const {},
    this.busy = false,
    this.onRead,
  });

  final FlarePluginProtectedMediaBlock block;
  final Map<String, FlarePluginProtectedMediaState> states;
  final bool busy;
  final ValueChanged<FlarePluginProtectedMediaRead>? onRead;

  Future<void> _request(
    BuildContext context,
    FlarePluginProtectedItem item,
  ) async {
    final action = block.action;
    if (action == null || onRead == null || busy) return;
    var reason = '';
    if (block.asksReason) {
      final strings = FlareStrings.of(context);
      final values = await FlareBottomSheet.show<Map<String, Object?>>(
        context,
        title: action.label,
        builder: (sheet) => FlarePluginForm(
          inputs: [
            FlarePluginInput(
              id: 'reason',
              kind: FlarePluginInputKind.textarea,
              label: strings.pluginProtectedMediaReason,
              required: true,
              maxLength: 160,
            ),
          ],
          submitLabel: action.label,
          onSubmit: (v) => Navigator.of(sheet).pop(v),
          onCancel: () => Navigator.of(sheet).pop(),
        ),
      );
      final typed = values?['reason'];
      reason = typed is String ? typed.trim() : '';
      if (reason.isEmpty) return;
    }
    onRead!(
      FlarePluginProtectedMediaRead(
        action: action,
        item: item,
        reason: reason,
        urlPath: block.urlPath,
        formValues: {
          block.inputName: item.id,
          if (block.asksReason) block.reasonInput!: reason,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final secondary = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareSizes.fontSizeSm,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (block.label != null && block.label!.isNotEmpty) ...[
          Text(
            block.label!,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareSizes.fontSizeMd,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: FlareSizes.spacingXs),
        ],
        if (block.items.isEmpty)
          Text(block.emptyText ?? strings.pluginViewEmpty, style: secondary)
        else if (!block.asksReason) ...[
          // §6.1: the owner's own documents are 16:10 tiles, veiled until
          // tapped; a read picture opens under them.
          Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingSm,
            children: [
              for (final item in block.items)
                _thumb(context, item, colors, strings),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          for (final item in block.items)
            if (flarePluginProtectedMediaSource(states[item.id]?.url) != null ||
                states[item.id]?.error != null) ...[
              _item(context, item, colors, strings),
              const SizedBox(height: FlareSizes.spacingSm),
            ],
        ] else
          for (final item in block.items) ...[
            _item(context, item, colors, strings),
            const SizedBox(height: FlareSizes.spacingSm),
          ],
        Text(
          block.asksReason
              ? strings.pluginProtectedMediaNotice
              : strings.pluginProtectedMediaOwnNotice,
          style: secondary,
        ),
      ],
    );
  }

  Widget _thumb(
    BuildContext context,
    FlarePluginProtectedItem item,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final state = states[item.id];
    final ready = block.action != null && onRead != null && !busy;
    return Semantics(
      button: true,
      enabled: ready,
      label: strings.pluginProtectedMediaTapToView.replaceAll(
        '{label}',
        item.label,
      ),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: ValueKey('flare-protected-media-read-${item.id}'),
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            onTap: ready && state?.loading != true
                ? () => _request(context, item)
                : null,
            child: Container(
              width: FlareSizes.componentDocumentThumbHeight * 16 / 10,
              height: FlareSizes.componentDocumentThumbHeight,
              constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTargetMin,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.bgTertiary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              ),
              child: state?.loading == true
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FlareIcon('eye', size: 16, color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: FlareSizes.spacing2xs),
          SizedBox(
            width: FlareSizes.componentDocumentThumbHeight * 16 / 10,
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareTextRoles.caption.fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    FlarePluginProtectedItem item,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final state = states[item.id];
    final source = flarePluginProtectedMediaSource(state?.url);
    return Column(
      key: ValueKey('flare-protected-media-${item.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
            if (block.action != null && source == null)
              FlareButton(
                key: ValueKey('flare-protected-media-read-${item.id}'),
                size: FlareControlSize.sm,
                variant: FlareButtonVariant.secondary,
                label: block.asksReason
                    ? block.action!.label
                    : strings.pluginProtectedMediaView,
                loading: state?.loading == true,
                disabled: busy || onRead == null || state?.loading == true,
                onPressed: () => _request(context, item),
              ),
          ],
        ),
        if (source != null) ...[
          const SizedBox(height: FlareSizes.spacingXs),
          if (item.isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: FlareSizes.componentRichCardWidth,
                ),
                child: _ProtectedImage(
                  key: ValueKey('flare-protected-media-image-${item.id}'),
                  source: source,
                  label: item.label,
                ),
              ),
            )
          else
            Text(
              strings.pluginProtectedMediaNotPreviewable,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
        ],
        if (state?.error != null) ...[
          const SizedBox(height: FlareSizes.spacingXs),
          Semantics(
            liveRegion: true,
            child: Text(
              state!.error!,
              key: ValueKey('flare-protected-media-error-${item.id}'),
              style: TextStyle(
                color: colors.errorText,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The picture, from memory only: a data:image is decoded in place, an https
/// address goes through the in-memory image cache (Flutter writes network
/// images to no file), and the entry is evicted when the picture goes away.
class _ProtectedImage extends StatefulWidget {
  const _ProtectedImage({super.key, required this.source, required this.label});
  final Uri source;
  final String label;

  @override
  State<_ProtectedImage> createState() => _ProtectedImageState();
}

class _ProtectedImageState extends State<_ProtectedImage> {
  late ImageProvider _provider = _of(widget.source);

  static ImageProvider _of(Uri source) => source.scheme == 'data'
      ? MemoryImage(source.data!.contentAsBytes())
      : NetworkImage(source.toString());

  @override
  void didUpdateWidget(_ProtectedImage old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) {
      _provider.evict();
      _provider = _of(widget.source);
    }
  }

  @override
  void dispose() {
    _provider.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    return Image(
      image: _provider,
      fit: BoxFit.contain,
      semanticLabel: widget.label,
      errorBuilder: (context, _, _) => Text(
        strings.pluginProtectedMediaUnavailable,
        style: TextStyle(
          color: FlareColors.of(context).errorText,
          fontSize: FlareSizes.fontSizeSm,
        ),
      ),
    );
  }
}
