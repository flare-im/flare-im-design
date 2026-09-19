import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// An icon-only control: a named button at least [FlareSizes.touchTarget]
/// square that draws [child] — the glyph and whatever surface it sits on —
/// exactly as given.
///
/// [label] is required and is also the tooltip, so a kit component cannot
/// build a tappable glyph that a screen reader has no name for. [toggled],
/// [checked], [selected] and [expanded] expose the state the glyph shows; a
/// control with [checked] is announced as a checkbox (or, with
/// [inMutuallyExclusiveGroup], a radio) rather than a button. The control takes
/// keyboard focus and activates on Enter / Space. [child] is drawn at
/// [alignment] inside the touch target and stays out of the semantics tree.
///
/// Internal: not exported from the package.
class FlareIconControl extends StatelessWidget {
  const FlareIconControl({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.toggled,
    this.checked,
    this.selected,
    this.expanded,
    this.inMutuallyExclusiveGroup,
    this.tooltip = true,
    this.alignment = Alignment.center,
  });

  /// The accessible name: what happens when the control is activated.
  final String label;
  final VoidCallback? onTap;

  /// What the control shows, usually a glyph on its own surface.
  final Widget child;

  /// A disabled control, or one without [onTap], is announced as disabled.
  final bool enabled;
  final bool? toggled;
  final bool? checked;
  final bool? selected;
  final bool? expanded;
  final bool? inMutuallyExclusiveGroup;

  /// Show [label] as a tooltip on hover / long press.
  final bool tooltip;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    Widget control = Semantics(
      container: true,
      button: checked == null,
      enabled: active,
      toggled: toggled,
      checked: checked,
      selected: selected,
      expanded: expanded,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      label: label,
      child: FocusableActionDetector(
        enabled: active,
        mouseCursor: active
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: active ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: FlareSizes.touchTarget,
              minHeight: FlareSizes.touchTarget,
            ),
            child: Align(
              alignment: alignment,
              widthFactor: 1,
              heightFactor: 1,
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      ),
    );
    if (tooltip) {
      control = Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: control,
      );
    }
    return control;
  }
}
