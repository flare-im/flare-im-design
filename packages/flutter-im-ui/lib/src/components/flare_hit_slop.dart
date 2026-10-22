import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tokens/flare_tokens.dart';

/// A small control whose touch target is at least [minSize] square without
/// growing its layout — the 12-point retry glyph in a bubble's meta row, which
/// must stay 12 points tall but take a 48-point tap (spec MessageStatus,
/// `layout.touchTarget`).
///
/// Inside a [FlareHitSlopRegion] the control keeps its own size and the region
/// sends any tap within the [minSize] square centred on it to the control.
/// Without a region there is nobody to lend the room, so the control is laid
/// out [minSize] square itself, centred — the Material "padded" rule.
///
/// The semantics node covers the same square, so accessibility scanners see
/// the real target.
class FlareHitSlop extends SingleChildRenderObjectWidget {
  const FlareHitSlop({
    super.key,
    this.minSize = FlareSizes.touchTarget,
    required Widget super.child,
  });

  final double minSize;

  @override
  RenderFlareHitSlop createRenderObject(BuildContext context) =>
      RenderFlareHitSlop(minSize: minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFlareHitSlop renderObject,
  ) {
    renderObject.minSize = minSize;
  }
}

/// The area that lends its room to the [FlareHitSlop] controls inside it: a
/// message row, so the retry glyph at its trailing edge answers a tap anywhere
/// in its 48-point square, even where the square reaches past the bubble; and
/// the message list, so a key at the bottom of a row reaches into the gap
/// below it. The outermost region that holds the tap decides.
class FlareHitSlopRegion extends SingleChildRenderObjectWidget {
  const FlareHitSlopRegion({super.key, required Widget super.child});

  @override
  RenderFlareHitSlopRegion createRenderObject(BuildContext context) =>
      RenderFlareHitSlopRegion();
}

class RenderFlareHitSlopRegion extends RenderProxyBox {
  final Set<RenderFlareHitSlop> _targets = {};

  /// Whether a control other than [target] (or one that holds it) answers
  /// a tap at [position]: a gesture detector or a link. The lent square never
  /// takes a tap from another control — a card's own key, a link, the next
  /// row.
  bool _otherControlAt(Offset position, RenderFlareHitSlop target) {
    final probe = BoxHitTestResult();
    if (!super.hitTestChildren(probe, position: position)) return false;
    final holders = <RenderObject>{};
    for (RenderObject? node = target; node != null; node = node.parent) {
      holders.add(node);
    }
    return probe.path.any(
      (entry) =>
          (entry.target is RenderPointerListener &&
              !holders.contains(entry.target)) ||
          (entry.target is TextSpan &&
              (entry.target as TextSpan).recognizer != null),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final target in _targets) {
      if (!target.attached || !target.hasSize) continue;
      final toRegion = target.getTransformTo(this);
      final bounds = MatrixUtils.transformRect(
        toRegion,
        Offset.zero & target.size,
      );
      if (bounds.contains(position)) break;
      final square = Rect.fromCenter(
        center: bounds.center,
        width: math.max(bounds.width, target.minSize),
        height: math.max(bounds.height, target.minSize),
      );
      if (!square.contains(position)) continue;
      if (_otherControlAt(position, target)) break;
      final inverse = Matrix4.tryInvert(toRegion);
      if (inverse == null) continue;
      // The nearest point of the control itself: the control is hit as if the
      // tap had landed on its edge.
      final local = MatrixUtils.transformPoint(inverse, position);
      final clamped = Offset(
        local.dx.clamp(0, math.max(0, target.size.width - 0.01)),
        local.dy.clamp(0, math.max(0, target.size.height - 0.01)),
      );
      final hit = result.addWithRawTransform(
        transform: inverse,
        position: MatrixUtils.transformPoint(toRegion, clamped),
        hitTest: (result, transformed) =>
            target.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return super.hitTestChildren(result, position: position);
  }
}

class RenderFlareHitSlop extends RenderShiftedBox {
  RenderFlareHitSlop({required double minSize, RenderBox? child})
    : _minSize = minSize,
      super(child);

  double _minSize;
  double get minSize => _minSize;
  set minSize(double value) {
    if (value == _minSize) return;
    _minSize = value;
    markNeedsLayout();
  }

  /// Every region above the control: the outermost one that holds the tap
  /// decides, so a square that reaches past a message row into the list's
  /// gutter still answers.
  final List<RenderFlareHitSlopRegion> _regions = [];

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderObject? node = parent; node != null; node = node.parent) {
      if (node is RenderFlareHitSlopRegion) {
        _regions.add(node);
        node._targets.add(this);
      }
    }
  }

  @override
  void detach() {
    for (final region in _regions) {
      region._targets.remove(this);
    }
    _regions.clear();
    super.detach();
  }

  /// No region lends room: the control takes its square in the layout.
  bool get _padded => _regions.isEmpty;

  Size _sized(BoxConstraints constraints, Size childSize) => _padded
      ? constraints.constrain(
          Size(
            math.max(childSize.width, minSize),
            math.max(childSize.height, minSize),
          ),
        )
      : constraints.constrain(childSize);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    child.layout(
      _padded ? constraints.loosen() : constraints,
      parentUsesSize: true,
    );
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      (size - child.size) as Offset,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final childSize =
        child?.getDryLayout(_padded ? constraints.loosen() : constraints) ??
        Size.zero;
    return _sized(constraints, childSize);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: (child.parentData! as BoxParentData).offset,
      position: position,
      hitTest: (result, transformed) => child.hitTest(
        result,
        // A padded control answers anywhere in its square.
        position: Offset(
          transformed.dx.clamp(0, math.max(0, child.size.width - 0.01)),
          transformed.dy.clamp(0, math.max(0, child.size.height - 0.01)),
        ),
      ),
    );
  }

  @override
  Rect get semanticBounds {
    final own = Offset.zero & size;
    return Rect.fromCenter(
      center: own.center,
      width: math.max(own.width, minSize),
      height: math.max(own.height, minSize),
    );
  }
}
