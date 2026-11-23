import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_strings.dart';
import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_input.dart';
import 'flare_status_banner.dart';
import 'icon_control.dart';

/// A standalone card, or the full-height editor of a page or a drawer.
enum FlareMomentComposerLayout { card, page }

/// The moment composer card: a cancel/post header, a multi-line text field, a
/// 4-column image grid with removable thumbnails and an add tile, and
/// location / visibility rows. Post is disabled until there is text or at least
/// one image. Spec: Moments/Composer (`FlareMomentComposer`).
///
/// [FlareMomentComposerLayout.page] fills its box: the header stays on top,
/// the field takes focus and grows from three to eight lines, and the rest
/// scrolls. [submitError] (the host's publish failure) shows above the field
/// with Retry. [images] replaces the built-in grid (a `FlareMediaUpload`
/// with per-file states). With [onLocationChanged] the location row edits in
/// place: Enter or ✓ keeps it, Escape or ✕ leaves it; posting keeps an open
/// edit first.
class FlareMomentComposer extends StatefulWidget {
  const FlareMomentComposer({
    super.key,
    this.layout = FlareMomentComposerLayout.card,
    this.submitError,
    this.imagesSlot,
    this.onLocationChanged,
    this.locationPlaceholder,
    this.images = const [],
    this.maxImages = 9,
    this.location,
    this.visibility,
    this.busy = false,
    this.onSubmit,
    this.onCancel,
    this.onAddImage,
    this.onRemoveImage,
    this.onPickLocation,
    this.onPickVisibility,
    this.placeholder = '这一刻的想法…',
    this.cancelLabel = '取消',
    this.postLabel = '发表',
    this.locationLabel = '所在位置',
    this.visibilityLabel = '谁可以看',
  });

  final List<String> images;
  final int maxImages;
  final String? location;
  final String? visibility;
  final bool busy;
  final void Function(String text)? onSubmit;
  final VoidCallback? onCancel;
  final VoidCallback? onAddImage;
  final void Function(int index)? onRemoveImage;
  final VoidCallback? onPickLocation;
  final VoidCallback? onPickVisibility;
  final String placeholder;
  final String cancelLabel;
  final String postLabel;
  final String locationLabel;
  final String visibilityLabel;
  final FlareMomentComposerLayout layout;
  final String? submitError;

  /// Replaces the built-in thumbnail grid.
  final Widget? imagesSlot;

  /// Edits the location in place and reports the trimmed value.
  final ValueChanged<String>? onLocationChanged;

  /// The in-place location field's hint; [locationLabel] when null.
  final String? locationPlaceholder;

  @override
  State<FlareMomentComposer> createState() => _FlareMomentComposerState();
}

class _FlareMomentComposerState extends State<FlareMomentComposer> {
  final _controller = TextEditingController();
  final _location = TextEditingController();
  final _locationRow = FocusNode(debugLabel: 'moment location');
  bool _editingLocation = false;

  @override
  void dispose() {
    _controller.dispose();
    _location.dispose();
    _locationRow.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _controller.text.trim().isNotEmpty || widget.images.isNotEmpty;

  void _editLocation() {
    if (widget.busy) return;
    if (widget.onLocationChanged == null) {
      widget.onPickLocation?.call();
      return;
    }
    _location.text = widget.location ?? '';
    setState(() => _editingLocation = true);
  }

  void _closeLocation() {
    setState(() => _editingLocation = false);
    _locationRow.requestFocus();
  }

  void _confirmLocation({bool restoreFocus = true}) {
    if (widget.busy || !_editingLocation) return;
    widget.onLocationChanged?.call(_location.text.trim());
    if (restoreFocus) {
      _closeLocation();
    } else {
      setState(() => _editingLocation = false);
    }
  }

  void _submit() {
    if (widget.busy || !_canPost) return;
    _confirmLocation(restoreFocus: false);
    widget.onSubmit?.call(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final canPost = _canPost && !widget.busy;
    if (widget.layout == FlareMomentComposerLayout.page) {
      return _page(colors, canPost);
    }

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915131C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(colors, canPost),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            minLines: 4,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: colors.textPrimary,
            ),
            decoration: _textDecoration(colors),
          ),
          ?_images(colors),
          _rows(colors),
        ],
      ),
    );
  }

  Widget? _images(FlareColors colors) {
    final slot = widget.imagesSlot;
    if (slot != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          FlareSizes.spacing2md,
          0,
          FlareSizes.spacing2md,
          12,
        ),
        child: slot,
      );
    }
    if (widget.images.isNotEmpty || widget.images.length < widget.maxImages) {
      return _grid(colors);
    }
    return null;
  }

  Widget _rows(FlareColors colors) {
    final strings = FlareStrings.of(context);
    final location = widget.location;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      child: Column(
        children: [
          if (_editingLocation)
            CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape):
                    _closeLocation,
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacing2md,
                  vertical: FlareSizes.spacingXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FlareInput(
                        controller: _location,
                        size: FlareControlSize.sm,
                        clearable: true,
                        autofocus: true,
                        disabled: widget.busy,
                        semanticLabel: strings.pickLocation,
                        placeholder:
                            widget.locationPlaceholder ?? widget.locationLabel,
                        onSubmitted: (_) => _confirmLocation(),
                      ),
                    ),
                    FlareIconButton(
                      icon: 'check',
                      size: FlareControlSize.sm,
                      semanticLabel: strings.confirm,
                      disabled: widget.busy,
                      onPressed: _confirmLocation,
                    ),
                    FlareIconButton(
                      icon: 'close',
                      size: FlareControlSize.sm,
                      semanticLabel: strings.cancel,
                      disabled: widget.busy,
                      onPressed: _closeLocation,
                    ),
                  ],
                ),
              ),
            )
          else
            Focus(
              focusNode: _locationRow,
              skipTraversal: true,
              child: _row(
                colors,
                Icons.location_on_outlined,
                location == null || location.isEmpty
                    ? widget.locationLabel
                    : location,
                widget.busy ||
                        (widget.onLocationChanged == null &&
                            widget.onPickLocation == null)
                    ? null
                    : _editLocation,
              ),
            ),
          Divider(height: 1, thickness: 1, color: colors.borderPrimary),
          _row(
            colors,
            Icons.public,
            widget.visibility ?? widget.visibilityLabel,
            widget.busy ? null : widget.onPickVisibility,
          ),
        ],
      ),
    );
  }

  /// The editor of a page or a drawer: the header on top, the rest scrolls.
  Widget _page(FlareColors colors, bool canPost) {
    final error = widget.submitError;
    return Material(
      color: colors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(colors, canPost),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null && error.isNotEmpty && !widget.busy)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FlareSizes.spacingLg,
                        FlareSizes.spacingMd,
                        FlareSizes.spacingLg,
                        0,
                      ),
                      child: FlareStatusBanner(
                        text: error,
                        tone: FlareStatusTone.danger,
                        dot: false,
                        actionText: _canPost
                            ? FlareStrings.of(context).retry
                            : null,
                        onAction: _submit,
                      ),
                    ),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !widget.busy,
                    onChanged: (_) => setState(() {}),
                    minLines: 3,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: colors.textPrimary,
                    ),
                    decoration: _textDecoration(colors),
                  ),
                  ?_images(colors),
                  _rows(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vue `__text`: the field pads itself, and focus is a 2px rule along its
  /// bottom edge.
  InputDecoration _textDecoration(FlareColors colors) => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.all(FlareSizes.spacing2md),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: colors.borderSelected, width: 2),
    ),
    hintText: widget.placeholder,
    hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
  );

  // Vue `__head`: a small ghost cancel key and a small primary post key.
  Widget _header(FlareColors colors, bool canPost) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacing2md,
        vertical: FlareSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FlareButton(
            variant: FlareButtonVariant.ghost,
            size: FlareControlSize.sm,
            label: widget.cancelLabel,
            disabled: widget.busy,
            onPressed: widget.onCancel,
          ),
          FlareButton(
            size: FlareControlSize.sm,
            label: widget.postLabel,
            disabled: !canPost,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _grid(FlareColors colors) {
    final tiles = <Widget>[
      for (var i = 0; i < widget.images.length; i++) _thumb(colors, i),
      if (widget.images.length < widget.maxImages) _addTile(colors),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacing2md,
        0,
        FlareSizes.spacing2md,
        12,
      ),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      ),
    );
  }

  Widget _thumb(FlareColors colors, int index) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  ColoredBox(color: colors.bgSecondary),
            ),
          ),
        ),
        // The disc keeps its corner; the touch target extends into the
        // thumbnail, which has no tap of its own.
        Positioned(
          top: 0,
          right: 0,
          child: FlareIconControl(
            label: FlareStrings.of(context).removeImage,
            onTap: widget.onRemoveImage == null
                ? null
                : () => widget.onRemoveImage!(index),
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
                child: const FlareIcon('close', size: 13, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addTile(FlareColors colors) {
    return FlareIconControl(
      label: FlareStrings.of(context).addImage,
      onTap: widget.onAddImage,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderHover),
          ),
          child: FlareIcon('add', size: 26, color: colors.textTertiary),
        ),
      ),
    );
  }

  Widget _row(
    FlareColors colors,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacing2md,
          vertical: 13,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
