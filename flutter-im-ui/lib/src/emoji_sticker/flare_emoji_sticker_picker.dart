import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_emoji_sticker_catalog.dart';
import 'flare_static_asset_image.dart';

/// Composer emoji-pack + sticker picker. One tab for the emoji pack plus one
/// per sticker pack; taps emit [onInsertEmoji] (a `key` to insert as `[key]`)
/// or [onSendSticker] (`packageId`, `stickerId`).
class FlareEmojiStickerPicker extends StatefulWidget {
  const FlareEmojiStickerPicker({
    super.key,
    this.onInsertEmoji,
    this.onSendSticker,
    this.emojiLabel = 'Emoji',
    this.height = 300,
  });

  final ValueChanged<String>? onInsertEmoji;
  final void Function(String packageId, String stickerId)? onSendSticker;
  final String emojiLabel;
  final double height;

  @override
  State<FlareEmojiStickerPicker> createState() => _FlareEmojiStickerPickerState();
}

class _FlareEmojiStickerPickerState extends State<FlareEmojiStickerPicker> {
  final FlareEmojiStickerCatalog _catalog = FlareEmojiStickerCatalog.instance;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _catalog.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    if (!_catalog.isLoaded) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final packs = _catalog.stickerPacks;
    final tabCount = 1 + packs.length;
    final tab = _tab.clamp(0, tabCount - 1);

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: tab == 0
                ? _emojiGrid(colors)
                : _stickerGrid(colors, packs[tab - 1]),
          ),
          _tabBar(colors, packs, tab),
        ],
      ),
    );
  }

  Widget _tabBar(FlareColors colors, List<FlareStickerPack> packs, int tab) {
    final labels = <String>[widget.emojiLabel, ...packs.map((p) => p.title)];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final selected = i == tab;
          return InkWell(
            onTap: () => setState(() => _tab = i),
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? colors.bgHover : Colors.transparent,
                borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emojiGrid(FlareColors colors) {
    final keys = _catalog.emojiKeys;
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 48,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        return _cell(
          colors,
          FlareEmojiStickerCatalog.emojiAssetPath(key),
          () => widget.onInsertEmoji?.call(key),
        );
      },
    );
  }

  Widget _stickerGrid(FlareColors colors, FlareStickerPack pack) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 84,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: pack.stickerIds.length,
      itemBuilder: (context, i) {
        final id = pack.stickerIds[i];
        return _cell(
          colors,
          FlareEmojiStickerCatalog.stickerAssetPath(stickerId: id, packageId: pack.id),
          () => widget.onSendSticker?.call(pack.id, id),
        );
      },
    );
  }

  Widget _cell(FlareColors colors, String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FlareStaticAssetImage(
          assetPath: assetPath,
          package: FlareEmojiStickerCatalog.package,
        ),
      ),
    );
  }
}
