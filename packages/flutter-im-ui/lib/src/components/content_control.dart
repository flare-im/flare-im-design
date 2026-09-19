import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Content that acts as a button — a person's name in a moment, a comment the
/// reader replies to, the moments cover. It is announced as a button named by
/// its text (or by [label], which then replaces what [child] would read), takes
/// keyboard focus with the kit's focus ring, activates on tap, Enter or Space,
/// and shows the click cursor.
///
/// It keeps the size of what it draws, so a name can stay on its line of text
/// the way a link does in a sentence; the host decides whether the content is
/// a control at all by passing a callback or not.
///
/// Internal: not exported from the package.
class FlareContentControl extends StatefulWidget {
  const FlareContentControl({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.insetRing = false,
  });

  final VoidCallback onTap;
  final Widget child;

  /// The accessible name when it is not the text [child] shows.
  final String? label;

  /// Draw the focus ring inside the content — for an edge-to-edge surface
  /// whose outside would be off screen.
  final bool insetRing;

  @override
  State<FlareContentControl> createState() => _FlareContentControlState();
}

class _FlareContentControlState extends State<FlareContentControl> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: widget.label,
      excludeSemantics: widget.label != null,
      // Declared here: a label replaces what the child would announce, and
      // with it the child's own tap action.
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              // The ring sits just outside the content so it never covers it,
              // or just inside an edge-to-edge surface.
              if (_focused)
                Positioned.fill(
                  left: widget.insetRing ? 0 : -2,
                  top: widget.insetRing ? 0 : -2,
                  right: widget.insetRing ? 0 : -2,
                  bottom: widget.insetRing ? 0 : -2,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.borderSelected,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          FlareSizes.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
