import 'package:flutter/widgets.dart';

/// Which row is marked after a jump, and the clock the mark reads.
///
/// The list owns both and hands them down; a bubble takes the mark only when it
/// is the marked one. The clock is a [Listenable] rather than a value, so a
/// running mark rebuilds one row's decoration per frame instead of every built
/// row in the viewport.
class FlareLocateHighlightScope extends InheritedWidget {
  const FlareLocateHighlightScope({
    super.key,
    required this.messageId,
    required this.elapsedMs,
    required this.reduceMotion,
    required super.child,
  });

  /// The row wearing the mark, or null when nothing is marked. One at a time:
  /// two marked rows would say the jump landed twice.
  final String? messageId;

  /// Milliseconds since the list started moving towards that row.
  final Animation<double> elapsedMs;

  final bool reduceMotion;

  static FlareLocateHighlightScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlareLocateHighlightScope>();

  @override
  bool updateShouldNotify(FlareLocateHighlightScope oldWidget) =>
      messageId != oldWidget.messageId ||
      elapsedMs != oldWidget.elapsedMs ||
      reduceMotion != oldWidget.reduceMotion;
}
