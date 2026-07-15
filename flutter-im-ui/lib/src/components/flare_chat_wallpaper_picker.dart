import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Parses a "#RRGGBB" / "#AARRGGBB" hex string to a [Color]. Returns null on
/// any parse failure (e.g. CSS gradients or malformed input).
Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (!value.startsWith('#')) return null;
  value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

/// Chat-wallpaper picker — a swatch grid for choosing a conversation
/// background: each swatch is a solid colour or an image, with the selected one
/// ringed and check-marked. Spec: Chat/WallpaperPicker (`FlareChatWallpaperPicker`).
class FlareChatWallpaperPicker extends StatelessWidget {
  const FlareChatWallpaperPicker({
    super.key,
    required this.options,
    this.selectedId,
    this.onSelect,
  });

  final List<FlareWallpaperOption> options;
  final String? selectedId;
  final void Function(String id)? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
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
          Text('Chat wallpaper',
              style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: FlareSizes.spacingMd),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3 / 4,
            children: [
              for (final option in options) _swatch(colors, option),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swatch(FlareColors colors, FlareWallpaperOption option) {
    final selected = option.id == selectedId;
    final imageUrl = option.imageUrl;
    final fill = _parseHexColor(option.color) ?? colors.bgSecondary;

    return GestureDetector(
      onTap: onSelect == null ? null : () => onSelect!(option.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: 2,
          ),
          image: imageUrl != null && imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: selected
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
