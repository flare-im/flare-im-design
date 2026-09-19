import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Canonical reaction controls with keyboard, touch and selected semantics.
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
    final colors = FlareColors.of(context);
    if (reactions.isEmpty && hideAdd) return const SizedBox.shrink();
    return Wrap(
      spacing: FlareSizes.spacing2xs,
      runSpacing: FlareSizes.spacing2xs,
      children: [
        for (final reaction in reactions)
          // A pill is a button only when the host toggles reactions; otherwise it is a
          // label, so assistive technology does not announce a control that does nothing.
          if (onToggle == null)
            _label(
              colors,
              label: '${reaction.emoji} ${reaction.count}',
              selected: reaction.reactedBySelf,
            )
          else
            _button(
              colors,
              label: '${reaction.emoji} ${reaction.count}',
              selected: reaction.reactedBySelf,
              onPressed: () => onToggle!(reaction.emoji),
              child: Text('${reaction.emoji} ${reaction.count}'),
            ),
        if (!hideAdd)
          _button(
            colors,
            label: FlareStrings.of(context).addReaction,
            onPressed: onAdd,
            child: Icon(
              flareIconGlyph('reaction'),
              size: FlareSizes.fontSize3xl,
            ),
          ),
      ],
    );
  }

  Widget _label(
    FlareColors colors, {
    required String label,
    required bool selected,
  }) {
    return Semantics(
      label: label,
      selected: selected,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: FlareSizes.touchTarget,
            minHeight: FlareSizes.touchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingSm),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected
                ? colors.messageReactionSelected
                : colors.messageReactionBackground,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: selected ? colors.primary : colors.borderPrimary,
              ),
              borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.primary : colors.textSecondary,
              fontSize: FlareSizes.fontSizeSm,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(
    FlareColors colors, {
    required String label,
    required Widget child,
    required VoidCallback? onPressed,
    bool? selected,
  }) {
    final active = selected == true;
    return MergeSemantics(
      child: Semantics(
        label: label,
        selected: selected,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(
              FlareSizes.touchTarget,
              FlareSizes.touchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingSm,
            ),
            foregroundColor: active ? colors.primary : colors.textSecondary,
            disabledForegroundColor: colors.textDisabled,
            backgroundColor: active
                ? colors.messageReactionSelected
                : colors.messageReactionBackground,
            side: BorderSide(
              color: active ? colors.primary : colors.borderPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
            ),
            textStyle: const TextStyle(
              fontSize: FlareSizes.fontSizeSm,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: ExcludeSemantics(child: child),
        ),
      ),
    );
  }
}
