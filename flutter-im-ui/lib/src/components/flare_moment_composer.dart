import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The moment composer card: a cancel/post header, a multi-line text field, a
/// 4-column image grid with removable thumbnails and an add tile, and
/// location / visibility rows. Post is disabled until there is text or at least
/// one image. Spec: Moments/Composer (`FlareMomentComposer`).
class FlareMomentComposer extends StatefulWidget {
  const FlareMomentComposer({
    super.key,
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

  @override
  State<FlareMomentComposer> createState() => _FlareMomentComposerState();
}

class _FlareMomentComposerState extends State<FlareMomentComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPost =>
      _controller.text.trim().isNotEmpty || widget.images.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final canPost = _canPost && !widget.busy;

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
          Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              minLines: 4,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
              ),
            ),
          ),
          if (widget.images.isNotEmpty ||
              widget.images.length < widget.maxImages)
            _grid(colors),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderPrimary)),
            ),
            child: Column(
              children: [
                _row(colors, Icons.location_on_outlined,
                    widget.location ?? widget.locationLabel, widget.onPickLocation),
                Divider(height: 1, thickness: 1, color: colors.borderPrimary),
                _row(colors, Icons.public,
                    widget.visibility ?? widget.visibilityLabel, widget.onPickVisibility),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(FlareColors colors, bool canPost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onCancel,
            behavior: HitTestBehavior.opaque,
            child: Text(
              widget.cancelLabel,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: canPost
                ? () => widget.onSubmit?.call(_controller.text.trim())
                : null,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: canPost ? 1 : 0.45,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                ),
                child: Text(
                  widget.postLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
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
              errorBuilder: (_, __, ___) => ColoredBox(color: colors.bgSecondary),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => widget.onRemoveImage?.call(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0x8C111318),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addTile(FlareColors colors) {
    return GestureDetector(
      onTap: widget.onAddImage,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderHover),
        ),
        child: Icon(Icons.add, size: 26, color: colors.textTertiary),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
