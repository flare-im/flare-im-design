import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../models/workspace_layout.dart';

// The shell contract (FR-095): a shell measures its own box and hands the mode
// down, keeps each destination it has shown, and steps its phone navigation
// aside while the active destination shows a page beyond its root.

/// The responsive mode the nearest shell resolved from its own box. A pane
/// frame inside a shell takes this mode; one outside any shell resolves its own.
class FlareShellScope extends InheritedWidget {
  const FlareShellScope({
    super.key,
    required this.responsiveMode,
    required super.child,
  });

  final FlareApplicationResponsiveMode responsiveMode;

  /// The mode of the shell [context] is inside, or null outside any shell.
  static FlareApplicationResponsiveMode? responsiveModeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<FlareShellScope>()
      ?.responsiveMode;

  @override
  bool updateShouldNotify(FlareShellScope oldWidget) =>
      oldWidget.responsiveMode != responsiveMode;
}

/// A shell destination's count of pages beyond its root. Internal: the shell
/// owns the count and places one of these around each destination.
class FlareDestinationScope extends InheritedWidget {
  const FlareDestinationScope({
    super.key,
    required this.depth,
    required super.child,
  });

  final ValueNotifier<int> depth;

  static ValueNotifier<int>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FlareDestinationScope>()?.depth;

  @override
  bool updateShouldNotify(FlareDestinationScope oldWidget) =>
      oldWidget.depth != depth;
}

/// While [active] is true, [child] is a page beyond the root of the destination
/// it is shown in: a detail, a sub-page, a chat that took the list's place. The
/// shell hides its phone navigation while the active destination has one. Kit
/// pages declare themselves (FlareScreen with a back action, a pane frame
/// showing a pane other than its root); a page the host draws itself wraps
/// itself in this. Outside a shell it does nothing.
class FlareDestinationDepth extends StatefulWidget {
  const FlareDestinationDepth({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<FlareDestinationDepth> createState() => _FlareDestinationDepthState();
}

class _FlareDestinationDepthState extends State<FlareDestinationDepth> {
  ValueNotifier<int>? _registry;
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = FlareDestinationScope.maybeOf(context);
    if (registry != _registry) {
      _leave();
      _registry = registry;
    }
    _sync();
  }

  @override
  void didUpdateWidget(FlareDestinationDepth oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }

  void _sync() {
    if (widget.active && !_entered && _registry != null) {
      _entered = true;
      _change(_registry!, 1);
    } else if (!widget.active && _entered) {
      _leave();
    }
  }

  void _leave() {
    if (!_entered) return;
    _entered = false;
    final registry = _registry;
    if (registry != null) _change(registry, -1);
  }

  // After the frame: the count is read by the shell, which rebuilds on it, and
  // a rebuild may not start while this frame is building or unmounting.
  static void _change(ValueNotifier<int> registry, int delta) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      registry.value += delta;
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
