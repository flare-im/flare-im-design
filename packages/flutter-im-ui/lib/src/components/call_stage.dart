import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/directory_data.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_call_controls.dart' show FlareCallMode;

// The dark call stage every call surface shares (docs/plugin-experience.md
// §3.0): the same in light and dark themes. Internal: not exported.

/// §7: the incoming halo breathes in 1.6 s (half of it each way).
const Duration callBreath = Duration(milliseconds: 800);

/// The phone form factor (< breakpoints.sm): calls go full screen and the
/// control bar puts hang-up on its own row.
bool callIsPhone(BuildContext context) =>
    flareCapabilitiesOf(context).bottomSheet;

/// The palette drawn on the stage: the host's dark colours, so warning, error
/// and the focus ring read on the dark stage in either theme.
FlareColors callStagePalette(BuildContext context) {
  final theme = FlareTheme.maybeOf(context);
  return theme?.darkColors ??
      FlareColors.resolve(
        Brightness.dark,
        brand: theme?.brand ?? FlareBrandTheme.violet,
      );
}

/// `color.call.stage` with the `stageTint` wash over its top 40%.
BoxDecoration callStageDecoration(FlareColors colors) => BoxDecoration(
  color: colors.callStage,
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [colors.callStageTint, colors.callStage],
    stops: const [0, .4],
  ),
);

/// `call.ended` with the duration, or without its ` · {duration}` tail.
String callEndedText(FlareStrings strings, String? duration) => duration == null
    ? strings.callEnded.replaceAll(RegExp(r'\s*·\s*\{duration\}'), '')
    : strings.callEnded.replaceAll('{duration}', duration);

// The ring is the solid `borderSelected` the kit's focus rule asks for
// (tooling/check-accessibility.mjs): `focusRing` is a translucent glow under 3:1.
/// A round focus ring for a round call key (2 wide, 3 outside
/// the disc), drawn while a descendant has keyboard focus. Never a square box.
class CallFocusRing extends StatefulWidget {
  const CallFocusRing({super.key, required this.diameter, required this.child});

  /// The disc the ring follows; the disc is centred in [child].
  final double diameter;
  final Widget child;

  @override
  State<CallFocusRing> createState() => _CallFocusRingState();
}

class _CallFocusRingState extends State<CallFocusRing> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onFocusChange: (focused) => setState(
      () => _shown =
          focused &&
          FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
    ),
    child: CustomPaint(
      foregroundPainter: _shown
          ? _RingPainter(
              // Deliberately not §3.2's focusRing: it is under 3:1 on the stage.
              callStagePalette(context).borderSelected,
              // §3.2: 2 wide, 3 out from the key's edge.
              widget.diameter / 2 +
                  FlareSizes.componentFocusRingOffset +
                  FlareSizes.componentFocusRingWidth / 2,
            )
          : null,
      child: widget.child,
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = FlareSizes.componentFocusRingWidth
      ..color = color,
  );

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.radius != radius;
}

/// The reconnecting dot (8, `color.warning`): it pulses, and holds still under
/// reduced motion.
class CallPulseDot extends StatefulWidget {
  const CallPulseDot({super.key, this.size = FlareSizes.spacingSm});
  final double size;

  @override
  State<CallPulseDot> createState() => _CallPulseDotState();
}

class _CallPulseDotState extends State<CallPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: callBreath,
    lowerBound: .4,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _pulse,
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: callStagePalette(context).warning,
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// A 2-wide ring [inset] outside [child] (an avatar) that breathes over 1.6 s
/// while [breathing]: the ringing halo, and the dock's connected ring. It holds
/// still under reduced motion and never changes [child]'s layout size.
class CallHalo extends StatefulWidget {
  const CallHalo({
    super.key,
    required this.color,
    required this.breathing,
    required this.child,
    this.inset = FlareSizes.spacingSm,
  });
  final Color color;
  final bool breathing;
  final double inset;
  final Widget child;

  @override
  State<CallHalo> createState() => _CallHaloState();
}

class _CallHaloState extends State<CallHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: callBreath,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.12,
  ).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CallHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!widget.breathing ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _breath
        ..stop()
        ..value = 0;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: -widget.inset,
        top: -widget.inset,
        right: -widget.inset,
        bottom: -widget.inset,
        child: ScaleTransition(
          scale: _scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 2),
            ),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

/// Announces [message] to screen readers when it appears or changes.
class CallAnnouncer extends StatefulWidget {
  const CallAnnouncer({super.key, required this.message, required this.child});
  final String? message;
  final Widget child;

  @override
  State<CallAnnouncer> createState() => _CallAnnouncerState();
}

class _CallAnnouncerState extends State<CallAnnouncer> {
  String? _announced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announce();
  }

  @override
  void didUpdateWidget(CallAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _announce();
  }

  void _announce() {
    final message = widget.message;
    if (message == _announced) return;
    _announced = message;
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The failed call's keys in place of the control bar (§3.3): Close
/// (secondary) and Call again (primary, phone / video glyph). Equal halves of
/// the width on phones, 160 each on PC. Drawn in the stage's dark palette.
class CallFailedKeys extends StatelessWidget {
  const CallFailedKeys({
    super.key,
    required this.mode,
    this.onClose,
    this.onRedial,
    this.redialText,
  });

  final FlareCallMode mode;
  final VoidCallback? onClose;

  /// Null leaves Call again out (the host cannot redial).
  final VoidCallback? onRedial;
  final String? redialText;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final phone = callIsPhone(context);
    Widget sized(Widget key) => phone
        ? Expanded(child: key)
        : SizedBox(
            width: FlareSizes.componentCallFailedActionWidth,
            child: key,
          );
    return FlareTheme(
      colors: callStagePalette(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          sized(
            FlareButton(
              label: strings.close,
              variant: FlareButtonVariant.secondary,
              size: FlareControlSize.lg,
              block: true,
              onPressed: onClose,
            ),
          ),
          if (onRedial != null) ...[
            const SizedBox(width: FlareSizes.spacingMd),
            sized(
              FlareButton(
                label: redialText ?? strings.callRedial,
                icon: mode == FlareCallMode.video ? 'video' : 'phone',
                size: FlareControlSize.lg,
                block: true,
                onPressed: onRedial,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Builds a call key whose disc darkens while hovered or pressed (§3.0:
/// `controlHover`, `hangupPressed`, `acceptPressed`). [builder] gets whether
/// the pointer is on it or holding it down.
class CallPressTint extends StatefulWidget {
  const CallPressTint({super.key, required this.builder});
  final Widget Function(bool active) builder;

  @override
  State<CallPressTint> createState() => _CallPressTintState();
}

class _CallPressTintState extends State<CallPressTint> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: widget.builder(_hover || _down),
    ),
  );
}

/// What a floating call window draws over the stage's top end (its expand
/// key): the stage keeps its own top bar clear of [end].
class CallWindowInsets extends InheritedWidget {
  const CallWindowInsets({super.key, required this.end, required super.child});
  final double end;

  static double endOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CallWindowInsets>()?.end ?? 0;

  @override
  bool updateShouldNotify(CallWindowInsets oldWidget) => end != oldWidget.end;
}
