import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A star rating — a row of [count] stars; tapping a star sets [value]. Filled
/// stars use the warning gold ([FlareColors.warning]); empty stars use
/// borderHover. [clearable] lets a re-tap on the current value clear to 0;
/// [readonly] and disabled make it non-interactive. Custom-built from Flare
/// tokens. Spec: Form/Rating.
class FlareRating extends StatefulWidget {
  const FlareRating({
    super.key,
    required this.value,
    this.count = 5,
    this.size = 24,
    this.readonly = false,
    this.clearable = false,
    this.disabled = false,
    this.onChanged,
  });

  final int value;

  /// Number of stars.
  final int count;

  /// Glyph size in px.
  final double size;

  /// Read-only display (no hover / tap).
  final bool readonly;
  final bool disabled;

  /// Allow tapping the current value again to clear to 0.
  final bool clearable;
  final void Function(int)? onChanged;

  @override
  State<FlareRating> createState() => _FlareRatingState();
}

class _FlareRatingState extends State<FlareRating> {
  int _hover = 0;

  bool get _interactive => !widget.disabled && !widget.readonly;

  void _pick(int n) {
    if (!_interactive) return;
    final next = widget.clearable && widget.value == n ? 0 : n;
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final active = _hover > 0 ? _hover : widget.value;

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.count, (i) {
          final n = i + 1;
          final on = n <= active;
          final star = MouseRegion(
            cursor: _interactive
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: _interactive ? (_) => setState(() => _hover = n) : null,
            onExit: _interactive ? (_) => setState(() => _hover = 0) : null,
            child: GestureDetector(
              onTap: _interactive ? () => _pick(n) : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  on ? Icons.star : Icons.star_border,
                  size: widget.size,
                  color: on ? colors.warning : colors.borderHover,
                ),
              ),
            ),
          );
          return star;
        }),
      ),
    );
  }
}
