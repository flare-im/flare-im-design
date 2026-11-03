import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/directory_data.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Compact reaction pills with separate touch slots and an optional trailing
/// message timestamp/receipt. The footer can wrap without separating the
/// first reaction line from the message surface.
class FlareReactionSummary extends StatelessWidget {
  const FlareReactionSummary({
    super.key,
    required this.reactions,
    this.hideAdd = false,
    this.onToggle,
    this.onAdd,
    this.trailing,
    this.trailingOnOwnLine = false,
    this.alignEnd = false,
  });

  final List<FlareReactionGroup> reactions;
  final bool hideAdd;
  final void Function(String emoji)? onToggle;
  final VoidCallback? onAdd;
  final Widget? trailing;
  final bool trailingOnOwnLine;
  final bool alignEnd;

  static const double _pillHeight = 22;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final touch = !flareCapabilitiesOf(context).hover;
    final children = [
      for (final reaction in reactions)
        _pill(
          context,
          colors,
          touch: touch,
          label: '${reaction.emoji} ${reaction.count}',
          selected: reaction.reactedBySelf,
          button: onToggle != null,
          onPressed: onToggle == null ? null : () => onToggle!(reaction.emoji),
        ),
      if (!hideAdd)
        _pill(
          context,
          colors,
          touch: touch,
          label: FlareStrings.of(context).addReaction,
          button: true,
          onPressed: onAdd,
          icon: flareIconGlyph('reaction'),
        ),
    ];
    return _ReactionFlow(
      alignEnd: alignEnd,
      direction: Directionality.of(context),
      hasTrailing: trailing != null,
      trailingOnOwnLine: trailingOnOwnLine,
      children: [...children, if (trailing != null) trailing!],
    );
  }

  Widget _pill(
    BuildContext context,
    FlareColors colors, {
    required bool touch,
    required String label,
    required bool button,
    required VoidCallback? onPressed,
    bool? selected,
    IconData? icon,
  }) {
    final active = selected == true;
    final foreground = button && onPressed == null
        ? colors.textDisabled
        : active
        ? colors.primaryText
        : colors.textSecondary;
    final pill = Container(
      constraints: BoxConstraints(
        minWidth: touch ? FlareSizes.touchTargetMin : _pillHeight,
        minHeight: _pillHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacing2xs),
      decoration: BoxDecoration(
        color: active
            ? colors.messageReactionSelected
            : colors.messageReactionBackground,
        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
      ),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: icon == null
            ? Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                ),
              )
            : Icon(icon, size: FlareSizes.iconSizeSm, color: foreground),
      ),
    );
    return MergeSemantics(
      child: Semantics(
        label: label,
        selected: selected,
        child: !button
            ? ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: touch ? FlareSizes.touchTargetMin : _pillHeight,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    widthFactor: 1,
                    heightFactor: 1,
                    child: pill,
                  ),
                ),
              )
            : TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                  minimumSize: Size.square(
                    touch ? FlareSizes.touchTargetMin : _pillHeight,
                  ),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.topCenter,
                  foregroundColor: foreground,
                  shape: const StadiumBorder(),
                ),
                child: ExcludeSemantics(child: pill),
              ),
      ),
    );
  }
}

class _ReactionFlow extends MultiChildRenderObjectWidget {
  const _ReactionFlow({
    required this.alignEnd,
    required this.direction,
    required this.hasTrailing,
    required this.trailingOnOwnLine,
    required super.children,
  });

  final bool alignEnd;
  final TextDirection direction;
  final bool hasTrailing;
  final bool trailingOnOwnLine;

  @override
  _RenderReactionFlow createRenderObject(BuildContext context) =>
      _RenderReactionFlow()
        ..configure(alignEnd, direction, hasTrailing, trailingOnOwnLine);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReactionFlow renderObject,
  ) {
    renderObject.configure(alignEnd, direction, hasTrailing, trailingOnOwnLine);
  }
}

class _ReactionFlowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderReactionFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ReactionFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ReactionFlowParentData> {
  bool _alignEnd = false;
  TextDirection _direction = TextDirection.ltr;
  bool _hasTrailing = false;
  bool _trailingOnOwnLine = false;

  void configure(
    bool end,
    TextDirection direction,
    bool trailing,
    bool ownLine,
  ) {
    if ((_alignEnd, _direction, _hasTrailing, _trailingOnOwnLine) ==
        (end, direction, trailing, ownLine))
      return;
    _alignEnd = end;
    _direction = direction;
    _hasTrailing = trailing;
    _trailingOnOwnLine = ownLine;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ReactionFlowParentData) {
      child.parentData = _ReactionFlowParentData();
    }
  }

  static const _gap = FlareSizes.spacingXs;
  static const _metaGap = FlareSizes.spacingSm;

  Size _layout(BoxConstraints limits, {required bool dry}) {
    final loose = BoxConstraints(maxWidth: limits.maxWidth);
    final entries = <(RenderBox, Size)>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (!dry) child.layout(loose, parentUsesSize: true);
      entries.add((child, dry ? child.getDryLayout(loose) : child.size));
    }
    if (entries.isEmpty) return limits.smallest;

    final trailing = _hasTrailing ? entries.removeLast() : null;
    final trailingWidth = trailing?.$2.width ?? 0;
    final reactionWidth =
        entries.fold<double>(0, (sum, entry) => sum + entry.$2.width) +
        _gap * math.max(0, entries.length - 1);
    // With a message surface as our minimum, prefer its width. Short text
    // bubbles may grow the footer enough for two chips and the metadata.
    final shortRow =
        entries.take(2).fold<double>(0, (sum, entry) => sum + entry.$2.width) +
        (entries.length > 1 ? _gap : 0);
    final preferred = limits.minWidth == 0
        ? reactionWidth + (trailing == null ? 0 : _metaGap + trailingWidth)
        : math.max(
            limits.minWidth,
            shortRow +
                (_trailingOnOwnLine || trailing == null
                    ? 0
                    : _metaGap + trailingWidth),
          );
    final widest = entries.fold<double>(
      trailingWidth,
      (width, entry) => math.max(width, entry.$2.width),
    );
    final width = limits.constrainWidth(math.max(widest, preferred));

    var top = 0.0;
    var runWidth = 0.0;
    var runHeight = 0.0;
    final run = <(RenderBox, Size)>[];

    void position((RenderBox, Size) entry, double logicalX, double y) {
      if (dry) return;
      final (child, childSize) = entry;
      final x = _direction == TextDirection.ltr
          ? logicalX
          : width - logicalX - childSize.width;
      (child.parentData! as _ReactionFlowParentData).offset = Offset(x, y);
    }

    void finishRun({(RenderBox, Size)? meta}) {
      final metaWidth = meta?.$2.width ?? 0;
      final reserved = meta == null || run.isEmpty ? 0 : _metaGap + metaWidth;
      var x = _alignEnd ? math.max(0.0, width - reserved - runWidth) : 0.0;
      for (final entry in run) {
        position(entry, x, top);
        x += entry.$2.width + _gap;
      }
      if (meta != null) {
        // Align with the painted pill, not the centre of its taller touch slot.
        final offset = run.isEmpty
            ? 0.0
            : math.max(
                0.0,
                (FlareReactionSummary._pillHeight - meta.$2.height) / 2,
              );
        position(meta, width - metaWidth, top + offset);
        runHeight = math.max(runHeight, meta.$2.height + offset);
      }
      top += runHeight;
      run.clear();
      runWidth = 0;
      runHeight = 0;
    }

    for (final entry in entries) {
      if (run.isNotEmpty && runWidth + _gap + entry.$2.width > width) {
        finishRun();
        top += _gap;
      }
      runWidth += (run.isEmpty ? 0 : _gap) + entry.$2.width;
      runHeight = math.max(runHeight, entry.$2.height);
      run.add(entry);
    }
    if (trailing != null &&
        run.isNotEmpty &&
        (_trailingOnOwnLine || runWidth + _metaGap + trailingWidth > width)) {
      finishRun();
      top += _gap;
    }
    finishRun(meta: trailing);
    return limits.constrain(Size(width, top));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
