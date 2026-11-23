import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart';
import 'flare_call_controls.dart';
import 'flare_icon.dart';
import 'flare_overlay.dart';
import 'icon_control.dart';

/// The window a call sits in (docs/plugin-experience.md §3.1). On PC and
/// tablets a floating window over the scrim — audio
/// [FlareSizes.componentCallWindowAudioWidth] ×
/// [FlareSizes.componentCallWindowAudioHeight], video
/// [FlareSizes.componentCallWindowVideoWidth] ×
/// [FlareSizes.componentCallWindowVideoHeight], or the viewport less
/// 2 × spacing.xl and 90% high when [expanded] — so chat stays visible. Its
/// top 48 drags it around the viewport (not while expanded). On phones
/// (< breakpoints.sm) it is true full screen: no scrim margin, no corners, the
/// stage running under the system bars and no shadow; the floating window
/// has radius.xl and shadows.xl, keeps Tab inside itself, and with
/// [onExpandedChange] draws the expand / collapse key at its top end. The
/// scrim never minimizes. Escape never hangs up: while [expanded] it asks the
/// host to leave it ([onExpandedChange] with false), otherwise it does
/// nothing.
class FlareCallSurface extends StatefulWidget {
  const FlareCallSurface({
    super.key,
    required this.mode,
    required this.child,
    this.expanded = false,
    this.label,
    this.onMinimize,
    this.onExpandedChange,
  });
  final FlareCallMode mode;

  /// Controlled by the host; [onExpandedChange] asks it to change.
  final bool expanded;
  final ValueChanged<bool>? onExpandedChange;
  final String? label;

  /// Kept for hosts; the scrim no longer minimizes (§3.1) — the stage's own
  /// minimize key does.
  final VoidCallback? onMinimize;
  final Widget child;

  @override
  State<FlareCallSurface> createState() => _FlareCallSurfaceState();
}

class _FlareCallSurfaceState extends State<FlareCallSurface> {
  /// How far the window was dragged from the centre.
  Offset _offset = Offset.zero;

  /// The expand key's disc, inside a full touch target.
  static const double _disc = 36;
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  @override
  Widget build(BuildContext context) {
    // shortcut: crossing breakpoints.sm mid-call remounts the stage; give it a
    // GlobalKey if desktop windows get resized below 600 during calls.
    if (callIsPhone(context)) {
      // The dark stage runs under the status bar: its icons go light.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.label,
          child: SizedBox.expand(child: widget.child),
        ),
      );
    }
    final size = MediaQuery.sizeOf(context);
    final video = widget.mode == FlareCallMode.video;
    final expanded = widget.expanded;
    final width = expanded
        ? size.width - FlareSizes.spacingXl * 2
        : video
        ? FlareSizes.componentCallWindowVideoWidth
        : FlareSizes.componentCallWindowAudioWidth;
    final height = expanded
        ? size.height * .9
        : math.min(
            size.height - FlareSizes.spacingXl * 2,
            video
                ? FlareSizes.componentCallWindowVideoHeight
                : FlareSizes.componentCallWindowAudioHeight,
          );
    // The window stays inside the viewport however far it is dragged.
    final slack = Offset(
      math.max(0, (size.width - width) / 2 - FlareSizes.spacingXl),
      math.max(0, (size.height - height) / 2 - FlareSizes.spacingXl),
    );
    Offset clamp(Offset o) => Offset(
      o.dx.clamp(-slack.dx, slack.dx),
      o.dy.clamp(-slack.dy, slack.dy),
    );
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final onExpandedChange = widget.onExpandedChange;
    // §3.1: the PC top bar's expand / collapse key, at the window's top end.
    final expand = onExpandedChange == null
        ? null
        : PositionedDirectional(
            top: FlareSizes.spacingLg - _targetInset,
            end: FlareSizes.spacingLg - _targetInset,
            child: CallFocusRing(
              diameter: _disc,
              child: CallPressTint(
                builder: (active) => FlareIconControl(
                  label: expanded ? strings.collapse : strings.expand,
                  expanded: expanded,
                  onTap: () => onExpandedChange(!expanded),
                  child: Container(
                    width: _disc,
                    height: _disc,
                    decoration: BoxDecoration(
                      color: active
                          ? colors.callControlHover
                          : colors.callControl,
                      shape: BoxShape.circle,
                    ),
                    child: FlareIcon(
                      expanded ? 'collapse' : 'expand',
                      color: colors.callOnStage,
                      size: FlareSizes.iconSizeMd,
                    ),
                  ),
                ),
              ),
            ),
          );
    // Escape is the window's: it leaves expanded and never reaches a route
    // that would close the call.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (expanded) widget.onExpandedChange?.call(false);
        },
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ModalBarrier(color: colors.scrim, dismissible: false),
          ),
          // The window: radius.xl and shadows.xl (a FlareModal would bring
          // the overlay's lg shadow).
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              child: Center(
                child: Transform.translate(
                  offset: expanded ? Offset.zero : clamp(_offset),
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    namesRoute: true,
                    label: widget.label ?? strings.modalLabel,
                    child: Container(
                      width: math.min(
                        width,
                        math.max(0.0, size.width - FlareSizes.spacingXl * 2),
                      ),
                      height: height,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          FlareSizes.radiusXl,
                        ),
                        boxShadow: FlareShadows.of(
                          Theme.of(context).brightness,
                        ).xl,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: FlareOverlaySurface(
                          kind: FlareOverlayKind.modal,
                          // Tab cycles inside the window.
                          child: FocusScope(
                            autofocus: true,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CallWindowInsets(
                                  end: expand == null
                                      ? 0
                                      : _disc + FlareSizes.spacingXl,
                                  child: widget.child,
                                ),
                                // The drag area: translucent, so the keys under
                                // it still take taps; only a drag moves the
                                // window.
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: FlareSizes.touchTarget,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onPanUpdate: expanded
                                        ? null
                                        : (d) => setState(
                                            () => _offset = clamp(
                                              _offset + d.delta,
                                            ),
                                          ),
                                  ),
                                ),
                                ?expand,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
