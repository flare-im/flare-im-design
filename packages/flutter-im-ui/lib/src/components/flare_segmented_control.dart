import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_tokens.dart';

/// Compact equal-width segmented selector (分段选择器) — mutually-exclusive
/// [options]; the selected segment is surfaced on a raised chip. Emits the
/// chosen index via [onSelect]. Spec: General/SegmentedControl.
///
/// A tab list (§4.7): one focus stop; ←/→ move the selection in reading
/// order (wrapping), Home/End jump to the ends — Vue's roving tablist.
class FlareSegmentedControl extends StatefulWidget {
  const FlareSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    this.onSelect,
    this.accent,
  });

  final List<String> options;
  final int selectedIndex;
  final void Function(int index)? onSelect;

  /// Colour of the selected segment's label; the brand colour when null.
  final Color? accent;

  @override
  State<FlareSegmentedControl> createState() => _FlareSegmentedControlState();
}

class _FlareSegmentedControlState extends State<FlareSegmentedControl> {
  bool _focused = false;

  /// The segment the keyboard stands on: the selected one, else the first.
  int get _current =>
      widget.selectedIndex >= 0 && widget.selectedIndex < widget.options.length
      ? widget.selectedIndex
      : 0;

  void _select(int index) {
    final count = widget.options.length;
    if (count == 0) return;
    final next = (index + count) % count;
    if (next != widget.selectedIndex) widget.onSelect?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final onSelect = widget.onSelect;
    final enabled = onSelect != null && widget.options.isNotEmpty;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _select(_current + (rtl ? 1 : -1)),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _select(_current + (rtl ? -1 : 1)),
        const SingleActivator(LogicalKeyboardKey.home): () => _select(0),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            _select(widget.options.length - 1),
      },
      child: FocusableActionDetector(
        enabled: enabled,
        // The tabs speak for themselves; the focus stop is keyboard only.
        includeFocusSemantics: false,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          // A tab bar with no tabs fails Flutter's role check.
          role: widget.options.isEmpty ? null : SemanticsRole.tabBar,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              border: Border.all(color: colors.borderPrimary),
            ),
            child: Row(
              children: List.generate(widget.options.length, (i) {
                final active = i == widget.selectedIndex;
                return Expanded(
                  // One tab of a tablist: its state read with its words.
                  child: Semantics(
                    container: true,
                    role: SemanticsRole.tab,
                    button: true,
                    selected: active,
                    enabled: onSelect != null,
                    inMutuallyExclusiveGroup: true,
                    label: widget.options[i],
                    excludeSemantics: true,
                    onTap: onSelect == null ? null : () => onSelect(i),
                    child: GestureDetector(
                      onTap: () => onSelect?.call(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: still ? Duration.zero : FlareMotion.fast,
                        curve: FlareMotion.fastCurve,
                        constraints: const BoxConstraints(
                          minHeight: FlareSizes.touchTarget,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: FlareSizes.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: active ? colors.bgPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            FlareSizes.radiusMd,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        // The keyboard's place: a ring that does not move
                        // the label.
                        foregroundDecoration: _focused && i == _current
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  FlareSizes.radiusMd,
                                ),
                                border: Border.all(
                                  color: colors.borderSelected,
                                  width: FlareSizes.componentFocusRingWidth,
                                ),
                              )
                            : null,
                        child: Text(
                          widget.options[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active
                                ? widget.accent ?? colors.primary
                                : colors.textSecondary,
                            fontSize: FlareSizes.fontSizeLg,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
