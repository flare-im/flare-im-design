import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';
import 'flare_call_view.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// Group (multi-party) call on the dark call stage — participant grid,
/// speaking highlight, mute / camera badges. Spec: Call/GroupCallView
/// (`FlareGroupCallView`), docs/plugin-experience.md §3.4.
///
/// The grid (§12.16, up to 12): 1 full, 2 side by side, 3 two over one
/// centred, 4 2×2, 5–6 3×2 (PC) or 2×3 (phone), 7–9 3×3, 10–12 4×3 (PC) or
/// 3×4 (phone). Tapping a tile makes it the main view with the others in a
/// strip below; tapping it again restores the grid. The header counts only
/// those who joined. A failed call swaps the control bar for Close
/// ([onHangup]) and Call again ([onRecover]), as [FlareCallView] does.
class FlareGroupCallView extends StatefulWidget {
  const FlareGroupCallView({
    super.key,
    required this.participants,
    required this.mode,
    required this.state,
    this.title,
    this.durationLabel,
    this.joinedText,
    this.statusDetail,
    this.recoveryText,
    this.onRecover,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.speakerPicker = false,
    this.controlsDisabled = false,
    this.encrypted = false,
    this.onPickDevices,
    this.onHangup,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
    this.onMinimize,
    this.onAddMember,
    this.tileBuilder,
    this.onStartVideo,
    this.onSelectParticipant,
    this.onClose,
  });

  final List<FlareCallParticipant> participants;
  final FlareCallMode mode;

  /// The call's state — the same [FlareCallState] as [FlareCallView].
  final FlareCallState state;
  final String? title;
  final String? durationLabel;

  /// 已加入人数与状态的文案，如 `(3, '已接通') => '3 joined · 已接通'`。
  final String Function(int count, String status)? joinedText;

  /// Host text under the status line (a failure reason, the reconnecting note).
  final String? statusDetail;

  /// The Call again key's label in the failed state (`callRedial` when null).
  final String? recoveryText;

  /// Call again, in the failed state.
  final VoidCallback? onRecover;
  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final bool speakerPicker;

  /// No media session yet: every control but hang-up is disabled.
  final bool controlsDisabled;

  /// Shows the lock and `callEncrypted` in the header.
  final bool encrypted;
  final ValueChanged<BuildContext>? onPickDevices;

  /// Hangs up; in the failed state it is the Close key unless [onClose] is
  /// given.
  final VoidCallback? onHangup;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onMinimize;

  /// Invite-to-call; forwarded to the control bar when supplied.
  final VoidCallback? onAddMember;

  /// Asks the host to turn the audio call into a video call; forwarded to the
  /// control bar, which draws its "switch to video" key in an audio call.
  final VoidCallback? onStartVideo;

  /// Host renders a participant's video. Asked only for a tile that shows
  /// video (a video call, the camera on); that tile, when this returns null,
  /// and every other tile show the avatar.
  final Widget? Function(FlareCallParticipant participant)? tileBuilder;

  /// Told when a tile is tapped (its participant id). The kit itself makes it
  /// the main view, or brings the grid back when it already was.
  final ValueChanged<String>? onSelectParticipant;

  /// The failed call's Close key; null falls back to [onHangup].
  final VoidCallback? onClose;

  @override
  State<FlareGroupCallView> createState() => _FlareGroupCallViewState();
}

class _FlareGroupCallViewState extends State<FlareGroupCallView> {
  String? _selected;

  static int _cols(int n, bool phone) => n <= 1
      ? 1
      : n <= 4
      ? 2
      : n <= 6
      ? (phone ? 2 : 3)
      : n <= 9 || phone
      ? 3
      : 4;

  String _statusOf(FlareStrings strings) => switch (widget.state) {
    FlareCallState.reconnecting => strings.callReconnecting,
    FlareCallState.failed => widget.statusDetail ?? strings.callFailed,
    FlareCallState.ended => callEndedText(strings, widget.durationLabel),
    FlareCallState.connected => widget.durationLabel ?? strings.callConnected,
    FlareCallState.ringing => strings.callRinging,
    FlareCallState.calling => strings.callCalling,
  };

  @override
  void didUpdateWidget(FlareGroupCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The enlarged participant left: back to the grid, and staying there if
    // they come back.
    if (_selected != null &&
        !widget.participants.any((p) => p.id == _selected)) {
      _selected = null;
    }
  }

  void _tap(String id) {
    setState(() => _selected = _selected == id ? null : id);
    widget.onSelectParticipant?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final phone = callIsPhone(context);
    final status = _statusOf(strings);
    final ended = w.state == FlareCallState.ended;
    final minimize = w.onMinimize != null;
    // People still being called are on the grid but have not joined.
    final joined = w.participants.where((p) => !p.calling).length;
    final detail = w.statusDetail?.trim();
    final participants = w.participants;
    final selected = participants.length < 2
        ? null
        : participants.where((p) => p.id == _selected).firstOrNull;
    final gap = phone ? FlareSizes.spacingXs : FlareSizes.spacingSm;
    const gridPadding = EdgeInsets.fromLTRB(
      FlareSizes.spacingMd,
      FlareSizes.spacingXs,
      FlareSizes.spacingMd,
      FlareSizes.spacingMd,
    );
    final grid = selected == null
        ? GridView(
            gridDelegate: _CallGridDelegate(
              columns: _cols(participants.length, phone),
              count: participants.length,
              gap: gap,
            ),
            padding: gridPadding,
            children: participants
                .map((p) => _tile(p, strings, colors))
                .toList(),
          )
        : Padding(
            padding: gridPadding,
            child: Column(
              children: [
                Expanded(child: _tile(selected, strings, colors)),
                SizedBox(height: gap),
                SizedBox(
                  height: FlareSizes.componentCallStripTileHeight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in participants)
                        if (p.id != selected.id)
                          Padding(
                            padding: EdgeInsetsDirectional.only(end: gap),
                            child: SizedBox(
                              width: FlareSizes.componentCallStripTileHeight,
                              child: _tile(p, strings, colors),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
    return DecoratedBox(
      decoration: callStageDecoration(colors),
      // Header on top, the call keys at the bottom, the participant grid in
      // between. When large text leaves the grid less than a usable height,
      // the whole view scrolls instead of overflowing. The backdrop runs
      // under the system bars; the content stays inside them.
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: _GroupCallLayout(
              viewportHeight: viewport.maxHeight,
              minGridHeight: participants.isEmpty ? 0 : _minGridHeight,
              children: [
                Padding(
                  // The minimize control is a full touch target around its
                  // 36-point disc; the padding gives the difference back so the
                  // disc stays put. Without onMinimize it is not drawn. The
                  // end clears the floating window's expand key.
                  padding: EdgeInsetsDirectional.fromSTEB(
                    FlareSizes.spacing2md - (minimize ? _targetInset : 0),
                    FlareSizes.spacing2md - (minimize ? _targetInset : 0),
                    FlareSizes.spacing2md + CallWindowInsets.endOf(context),
                    FlareSizes.spacingXs,
                  ),
                  child: Row(
                    children: [
                      if (minimize) ...[
                        _circleBtn(
                          colors,
                          'collapse',
                          strings.callMinimize,
                          w.onMinimize,
                        ),
                        const SizedBox(
                          width: FlareSizes.spacingMd - _targetInset,
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              w.title ?? strings.groupCall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.callOnStage,
                                fontSize: FlareSizes.fontSizeXl,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // The state is announced when it changes; the
                            // running duration never is.
                            CallAnnouncer(
                              message: w.state == FlareCallState.connected
                                  ? strings.callConnected
                                  : status,
                              child: Row(
                                children: [
                                  if (w.state ==
                                      FlareCallState.reconnecting) ...[
                                    const CallPulseDot(),
                                    const SizedBox(width: FlareSizes.spacingXs),
                                  ],
                                  Flexible(
                                    child: Text(
                                      w.joinedText?.call(joined, status) ??
                                          strings.joinedCount(joined, status),
                                      style: TextStyle(
                                        color: w.state == FlareCallState.failed
                                            ? colors.callErrorText
                                            : colors.callOnStageSecondary,
                                        fontSize: FlareSizes.fontSizeMd,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (detail != null &&
                                detail.isNotEmpty &&
                                detail != status)
                              Text(
                                detail,
                                style: TextStyle(
                                  color: colors.callOnStageSecondary,
                                  fontSize: FlareSizes.fontSizeSm,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (w.encrypted) ...[
                        const SizedBox(width: FlareSizes.spacingSm),
                        FlareIcon(
                          'lock',
                          size: FlareSizes.iconSizeSm,
                          color: colors.callOnStageSecondary,
                        ),
                        const SizedBox(width: FlareSizes.spacingXs),
                        Flexible(
                          child: Text(
                            strings.callEncrypted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.callOnStageSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                grid,
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FlareSizes.spacingMd,
                    FlareSizes.spacingMd,
                    FlareSizes.spacingMd,
                    FlareSizes.spacing2xl,
                  ),
                  child: w.state == FlareCallState.failed
                      ? CallFailedKeys(
                          mode: w.mode,
                          onClose: w.onClose ?? w.onHangup,
                          onRedial: w.onRecover,
                          redialText: w.recoveryText,
                        )
                      : FlareCallControls(
                          muted: w.muted,
                          cameraOn: w.cameraOn,
                          speakerOn: w.speakerOn,
                          speakerPicker: w.speakerPicker,
                          onPickDevices: w.onPickDevices,
                          mode: w.mode,
                          disabled: w.controlsDisabled || ended,
                          onToggleMute: w.onToggleMute,
                          onToggleCamera: w.onToggleCamera,
                          onToggleSpeaker: w.onToggleSpeaker,
                          onSwitchCamera: w.onSwitchCamera,
                          onHangup: ended ? null : w.onHangup,
                          onAddMember: w.onAddMember,
                          onStartVideo: w.onStartVideo,
                        ),
                ),
              ],
            ),
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
    final videoCall = widget.mode == FlareCallMode.video;
    final video = videoCall && !p.cameraOff && !p.calling
        ? widget.tileBuilder?.call(p)
        : null;
    final avatar = FlareAvatar(
      userId: p.id,
      displayName: p.name,
      avatarUrl: p.avatarUrl,
      size: FlareSizes.componentCallTileAvatar,
    );
    final content =
        video ??
        Center(
          // Still being called: the avatar at half strength over 呼叫中….
          child: p.calling
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(opacity: FlareOpacity.disabled, child: avatar),
                    const SizedBox(height: FlareSizes.spacingXs),
                    Text(
                      strings.callCalling,
                      style: TextStyle(
                        color: colors.callOnStageSecondary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
                  ],
                )
              : avatar,
        );
    final badge = p.muted
        ? 'mic-off'
        : p.cameraOff && videoCall
        ? 'camera-off'
        : null;
    final radius = BorderRadius.circular(FlareSizes.radiusCard);
    final Widget tile = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colors.callTile,
        borderRadius: radius,
        border: Border.all(
          color: p.speaking ? colors.callSpeaking : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          PositionedDirectional(
            start: FlareSizes.spacingSm,
            end: FlareSizes.spacingSm,
            bottom: FlareSizes.spacingSm,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacing2xs,
                      vertical: FlareSizes.spacing3xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.callChip,
                      borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (badge != null) ...[
                          FlareIcon(
                            badge,
                            color: colors.callOnStage,
                            size: FlareSizes.fontSizeSm,
                          ),
                          const SizedBox(width: FlareSizes.spacingXs),
                        ],
                        Flexible(
                          child: Text(
                            p.isSelf ? strings.callYou : p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.callOnStage,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (widget.participants.length < 2) return tile;
    // A button named by its tile's name tag; selected while it is the main view.
    return Semantics(
      container: true,
      button: true,
      selected: _selected == p.id,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: () => _tap(p.id),
          child: tile,
        ),
      ),
    );
  }

  static const double _disc = 36;

  /// The least height the participant grid keeps before the view scrolls.
  static const double _minGridHeight = 120;

  /// How far a control's touch target reaches past its disc on each side.
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  Widget _circleBtn(
    FlareColors colors,
    String icon,
    String label,
    VoidCallback? onTap,
  ) => CallFocusRing(
    diameter: _disc,
    child: FlareIconControl(
      label: label,
      onTap: onTap,
      child: Container(
        width: _disc,
        height: _disc,
        decoration: BoxDecoration(
          color: colors.callControl,
          shape: BoxShape.circle,
        ),
        child: FlareIcon(
          icon,
          color: colors.callOnStage,
          size: FlareSizes.iconSizeMd,
        ),
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

/// Fit conference rows into the bounded stage; short stages remain scrollable.
/// A last row that is not full is centred (3 people: two over one).
class _CallGridDelegate extends SliverGridDelegate {
  const _CallGridDelegate({
    required this.columns,
    required this.count,
    required this.gap,
  });
  final int columns;
  final int count;
  final double gap;
  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final rows = math.max(1, (count / columns).ceil());
    final width = math.max(
      0.0,
      (constraints.crossAxisExtent - gap * (columns - 1)) / columns,
    );
    final height = math.max(
      FlareSizes.componentCallStripTileHeight,
      (constraints.viewportMainAxisExtent -
              FlareSizes.spacingXs -
              FlareSizes.spacingMd -
              gap * (rows - 1)) /
          rows,
    );
    return _CentredLastRowLayout(
      count: count,
      crossAxisCount: columns,
      mainAxisStride: height + gap,
      crossAxisStride: width + gap,
      childMainAxisExtent: height,
      childCrossAxisExtent: width,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(covariant _CallGridDelegate oldDelegate) =>
      oldDelegate.columns != columns ||
      oldDelegate.count != count ||
      oldDelegate.gap != gap;
}

class _CentredLastRowLayout extends SliverGridRegularTileLayout {
  const _CentredLastRowLayout({
    required this.count,
    required super.crossAxisCount,
    required super.mainAxisStride,
    required super.crossAxisStride,
    required super.childMainAxisExtent,
    required super.childCrossAxisExtent,
    required super.reverseCrossAxis,
  });

  final int count;

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final geometry = super.getGeometryForChildIndex(index);
    final lastRow = (count - 1) ~/ crossAxisCount * crossAxisCount;
    final missing = crossAxisCount - (count - lastRow);
    if (index < lastRow || missing == 0) return geometry;
    final shift = missing * crossAxisStride / 2;
    return SliverGridGeometry(
      scrollOffset: geometry.scrollOffset,
      crossAxisOffset:
          geometry.crossAxisOffset + (reverseCrossAxis ? -shift : shift),
      mainAxisExtent: geometry.mainAxisExtent,
      crossAxisExtent: geometry.crossAxisExtent,
    );
  }
}
