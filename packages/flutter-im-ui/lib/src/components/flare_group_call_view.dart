import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// Group (multi-party) call — participant grid, speaking highlight,
/// mute / camera badges. Spec: Call/GroupCallView (`FlareGroupCallView`).
class FlareGroupCallView extends StatelessWidget {
  const FlareGroupCallView({
    super.key,
    required this.participants,
    required this.mode,
    required this.state,
    this.title,
    this.durationLabel,
    this.joinedText,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.onHangup,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
    this.onMinimize,
    this.onAddMember,
    this.tileBuilder,
  });

  final List<FlareCallParticipant> participants;
  final FlareCallMode mode;

  /// 'calling' | 'ringing' | 'connected' | 'reconnecting' | 'failed'
  final String state;
  final String? title;
  final String? durationLabel;

  /// 已加入人数与状态的文案，如 `(3, '已接通') => '3 joined · 已接通'`。
  final String Function(int count, String status)? joinedText;
  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final VoidCallback? onHangup;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onMinimize;

  /// Invite-to-call; forwarded to the control bar when supplied.
  final VoidCallback? onAddMember;

  /// Host injects each participant's video track; falls back to the avatar.
  final Widget Function(FlareCallParticipant participant)? tileBuilder;

  int get _cols {
    final n = participants.length;
    if (n <= 1) return 1;
    if (n <= 4) return 2;
    if (n <= 9) return 3;
    return 4;
  }

  String _statusOf(FlareStrings strings) {
    if (state == 'reconnecting') return strings.callReconnecting;
    if (state == 'failed') return strings.callFailed;
    if (state == 'connected') return durationLabel ?? strings.callConnected;
    if (state == 'ringing') return strings.callRinging;
    return strings.callCalling;
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final status = _statusOf(strings);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF18181B), Color(0xFF101012), Color(0xFF09090B)],
        ),
      ),
      // Header on top, the call keys at the bottom, the participant grid in
      // between. When large text leaves the grid less than a usable height,
      // the whole view scrolls instead of overflowing.
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: _GroupCallLayout(
            viewportHeight: viewport.maxHeight,
            minGridHeight: participants.isEmpty ? 0 : _minGridHeight,
            children: [
              Padding(
                // The minimize control is a full touch target around its
                // 36-point disc; the padding gives the difference back so the
                // disc stays put.
                padding: const EdgeInsets.fromLTRB(
                  14 - _targetInset,
                  14 - _targetInset,
                  14,
                  FlareSizes.spacingXs,
                ),
                child: Row(
                  children: [
                    _circleBtn('collapse', strings.callMinimize, onMinimize),
                    const SizedBox(width: FlareSizes.spacingMd - _targetInset),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title ?? strings.groupCall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            joinedText?.call(participants.length, status) ??
                                strings.joinedCount(
                                  participants.length,
                                  status,
                                ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GridView.count(
                crossAxisCount: _cols,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.86,
                children: participants
                    .map((p) => _tile(p, strings, colors))
                    .toList(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 36),
                child: FlareCallControls(
                  muted: muted,
                  cameraOn: cameraOn,
                  speakerOn: speakerOn,
                  mode: mode,
                  onToggleMute: onToggleMute,
                  onToggleCamera: onToggleCamera,
                  onToggleSpeaker: onToggleSpeaker,
                  onSwitchCamera: onSwitchCamera,
                  onHangup: onHangup,
                  onAddMember: onAddMember,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    FlareCallParticipant p,
    FlareStrings strings,
    FlareColors colors,
  ) {
    final content = tileBuilder != null
        ? tileBuilder!(p)
        : Center(
            child: FlareAvatar(
              userId: p.id,
              displayName: p.name,
              avatarUrl: p.avatarUrl,
              size: 56,
            ),
          );
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: p.isSelf
            ? colors.primary.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.speaking ? const Color(0xFF34D17F) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                if (p.muted)
                  _badge(
                    const FlareIcon('mic-off', color: Colors.white, size: 12),
                  )
                else if (p.cameraOff && mode == FlareCallMode.video)
                  _badge(
                    const FlareIcon(
                      'camera-off',
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                if (p.muted || (p.cameraOff && mode == FlareCallMode.video))
                  const SizedBox(width: 5),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.isSelf ? strings.selfSuffix(p.name) : p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(Widget icon) => Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(6),
    ),
    child: icon,
  );

  static const double _disc = 36;

  /// The least height the participant grid keeps before the view scrolls.
  static const double _minGridHeight = 120;

  /// How far a control's touch target reaches past its disc on each side.
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  Widget _circleBtn(String icon, String label, VoidCallback? onTap) =>
      FlareIconControl(
        label: label,
        onTap: onTap,
        child: Container(
          width: _disc,
          height: _disc,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: FlareIcon(
            icon,
            color: Colors.white,
            size: FlareSizes.iconSizeMd,
          ),
        ),
      );
}

/// Lays out the header, the participant grid and the call keys top to bottom:
/// the header and the keys at their own heights, the grid in the
/// [viewportHeight] left between them but never below [minGridHeight]. Taller
/// than the viewport only when that minimum does not fit, which is when the
/// enclosing scroll view starts to scroll.
class _GroupCallLayout extends MultiChildRenderObjectWidget {
  const _GroupCallLayout({
    required this.viewportHeight,
    required this.minGridHeight,
    required super.children,
  });

  final double viewportHeight;
  final double minGridHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroupCallLayout(viewportHeight, minGridHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGroupCallLayout renderObject,
  ) {
    renderObject
      ..viewportHeight = viewportHeight
      ..minGridHeight = minGridHeight;
  }
}

class _GroupCallParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderGroupCallLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupCallParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupCallParentData> {
  _RenderGroupCallLayout(this._viewportHeight, this._minGridHeight);

  double _viewportHeight;
  set viewportHeight(double value) {
    if (value == _viewportHeight) return;
    _viewportHeight = value;
    markNeedsLayout();
  }

  double _minGridHeight;
  set minGridHeight(double value) {
    if (value == _minGridHeight) return;
    _minGridHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupCallParentData) {
      child.parentData = _GroupCallParentData();
    }
  }

  /// Header, grid and keys heights for [width], laid out or measured by
  /// [size].
  (double, double, double) _heights(
    double width,
    Size Function(RenderBox child, BoxConstraints constraints) size,
  ) {
    final header = firstChild!;
    final grid = childAfter(header)!;
    final keys = childAfter(grid)!;
    final row = BoxConstraints.tightFor(width: width);
    final headerHeight = size(header, row).height;
    final keysHeight = size(keys, row).height;
    final available = _viewportHeight.isFinite ? _viewportHeight : 0.0;
    final gridHeight = math.max(
      _minGridHeight,
      available - headerHeight - keysHeight,
    );
    size(grid, BoxConstraints.tightFor(width: width, height: gridHeight));
    return (headerHeight, gridHeight, keysHeight);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final (header, grid, keys) = _heights(
      width,
      (child, childConstraints) => child.getDryLayout(childConstraints),
    );
    return constraints.constrain(Size(width, header + grid + keys));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final (header, grid, keys) = _heights(width, (child, childConstraints) {
      child.layout(childConstraints, parentUsesSize: true);
      return child.size;
    });
    final gridChild = childAfter(firstChild!)!;
    (gridChild.parentData! as _GroupCallParentData).offset = Offset(0, header);
    (lastChild!.parentData! as _GroupCallParentData).offset = Offset(
      0,
      header + grid,
    );
    size = constraints.constrain(Size(width, header + grid + keys));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
