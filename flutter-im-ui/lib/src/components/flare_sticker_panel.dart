import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Sticker panel — a paged sticker picker with a recents pack, a 4-column
/// sticker grid, and a bottom pack rail. Prepends a synthetic "recent" pack
/// from [recents] when non-empty. Spec: Composer/StickerPanel
/// (`FlareStickerPanel`).
class FlareStickerPanel extends StatefulWidget {
  const FlareStickerPanel({
    super.key,
    required this.packs,
    this.recents = const [],
    this.onSelect,
    this.recentLabel = '最近',
    this.emptyText = '暂无贴纸',
  });

  final List<FlareStickerPack> packs;
  final List<FlareStickerItem> recents;
  final void Function(FlareStickerItem)? onSelect;
  final String recentLabel;
  final String emptyText;

  @override
  State<FlareStickerPanel> createState() => _FlareStickerPanelState();
}

class _FlareStickerPanelState extends State<FlareStickerPanel> {
  static const String _recentKey = '__recent';
  late String _activeKey;

  List<FlareStickerPack> get _railPacks => [
        if (widget.recents.isNotEmpty)
          FlareStickerPack(
            key: _recentKey,
            label: widget.recentLabel,
            coverEmoji: '🕘',
            stickers: widget.recents,
          ),
        ...widget.packs,
      ];

  @override
  void initState() {
    super.initState();
    final packs = _railPacks;
    _activeKey = packs.isNotEmpty ? packs.first.key : '';
  }

  FlareStickerPack? get _activePack {
    for (final p in _railPacks) {
      if (p.key == _activeKey) return p;
    }
    return _railPacks.isNotEmpty ? _railPacks.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final pack = _activePack;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pack != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                pack.label,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            height: 208,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: (pack == null || pack.stickers.isEmpty)
                ? Center(
                    child: Text(widget.emptyText,
                        style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm)),
                  )
                : GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final s in pack.stickers) _stickerCell(colors, s),
                    ],
                  ),
          ),
          _rail(colors),
        ],
      ),
    );
  }

  Widget _stickerCell(FlareColors colors, FlareStickerItem sticker) {
    final url = sticker.url;
    final content = url != null && url.isNotEmpty
        ? Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _placeholder(colors, sticker),
          )
        : _placeholder(colors, sticker);
    return GestureDetector(
      onTap: () => widget.onSelect?.call(sticker),
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }

  Widget _placeholder(FlareColors colors, FlareStickerItem sticker) {
    return Center(
      child: Text(
        sticker.placeholder ?? '🎨',
        style: const TextStyle(fontSize: 32),
      ),
    );
  }

  Widget _rail(FlareColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          for (final p in _railPacks) _railButton(colors, p),
        ],
      ),
    );
  }

  Widget _railButton(FlareColors colors, FlareStickerPack pack) {
    final active = _activeKey == pack.key;
    final isRecent = pack.key == _recentKey;
    Widget child;
    if (isRecent) {
      child = Icon(Icons.schedule,
          size: 18, color: active ? colors.primary : colors.textTertiary);
    } else if (pack.coverUrl != null && pack.coverUrl!.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
        child: Image.network(
          pack.coverUrl!,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Text(pack.coverEmoji ?? '🎨', style: const TextStyle(fontSize: 20)),
        ),
      );
    } else {
      child = Text(pack.coverEmoji ?? '🎨', style: const TextStyle(fontSize: 20));
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => setState(() => _activeKey = pack.key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.bgSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          ),
          child: child,
        ),
      ),
    );
  }
}
