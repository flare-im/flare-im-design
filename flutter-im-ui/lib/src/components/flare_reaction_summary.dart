import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Reaction summary — a row of emoji-count pills under a message plus an add
/// pill. Spec: Message/ReactionSummary (`FlareReactionSummary`).
class FlareReactionSummary extends StatelessWidget {
  const FlareReactionSummary({
    super.key,
    required this.reactions,
    this.hideAdd = false,
    this.onToggle,
    this.onAdd,
  });

  final List<FlareReactionGroup> reactions;
  final bool hideAdd;
  final void Function(String emoji)? onToggle;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    if (reactions.isEmpty && hideAdd) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in reactions) _pill(colors, r),
        if (!hideAdd) _addPill(colors),
      ],
    );
  }

  Widget _pill(FlareColors colors, FlareReactionGroup r) {
    final active = r.reactedBySelf;
    return GestureDetector(
      onTap: () => onToggle?.call(r.emoji),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active ? colors.bgSelected : colors.bgSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? colors.primary : colors.borderPrimary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.emoji, style: const TextStyle(fontSize: FlareSizes.fontSizeLg)),
            const SizedBox(width: 4),
            Text('${r.count}',
                style: TextStyle(
                    color: active ? colors.primary : colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _addPill(FlareColors colors) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: Icon(Icons.emoji_emotions_outlined, size: 15, color: colors.textTertiary),
      ),
    );
  }
}
