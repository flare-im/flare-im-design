import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_overlay.dart';

/// The edge a [FlareDrawer] docks to, in inline terms (mirrored under RTL).
enum FlareDrawerPlacement { end, start }

/// A full-height panel over the kit scrim for long-lived secondary content
/// beside the main view — conversation, group and contact details, settings
/// stacks. Spec: Overlay/Drawer (`FlareDrawer`).
///
/// On wide layouts it is a drawer; on the phone form factor the same content
/// is a page ([FlareDrawer.showAdaptive] picks, and the host's own layout fact
/// — a single-pane window — wins over the form factor).
///
/// Header row: [back?] [title] … [actions] [close?]; there is no header row
/// when there is no visible title, no actions, no back and no close (page
/// content that brings its own header). [label] names the drawer when there is
/// no visible title, falling back to `FlareStrings.drawerLabel`. [footer]
/// stays at the bottom.
///
/// Escape and the platform back emit [onBack] when [showBack], and close the
/// drawer otherwise; neither does anything while not [dismissible], and the
/// close control is disabled then. The panel is [width] wide (default
/// [FlareSizes.componentSheetWidth]), clamped so a strip of scrim at least a
/// touch target wide always remains.
///
/// The widget docks itself at its edge, so a host that presents it in its own
/// route gets the same panel; [FlareDrawer.show] owns the route, the token
/// scrim, the slide and a nested navigator for pages pushed inside.
class FlareDrawer extends StatelessWidget {
  const FlareDrawer({
    super.key,
    this.title,
    this.titleHidden = false,
    this.label,
    this.placement = FlareDrawerPlacement.end,
    this.width,
    this.dismissible = true,
    this.showClose = true,
    this.showBack = false,
    this.onClose,
    this.onBack,
    this.actions = const [],
    this.footer,
    required this.child,
  });

  /// The header, also the drawer's accessible name.
  final String? title;

  /// Use [title] as the accessible name only, without drawing the heading.
  final bool titleHidden;

  /// The accessible name when there is no visible title.
  final String? label;
  final FlareDrawerPlacement placement;

  /// Panel width in logical pixels; defaults to
  /// [FlareSizes.componentSheetWidth].
  final double? width;
  final bool dismissible;
  final bool showClose;

  /// Draws a leading back control; Escape and back then emit [onBack].
  final bool showBack;

  /// Closes the drawer; defaults to popping the route the drawer is on.
  final VoidCallback? onClose;
  final VoidCallback? onBack;

  /// Controls at the header's trailing edge, before the close control.
  final List<Widget> actions;

  /// Content that stays at the bottom of the panel.
  final Widget? footer;
  final Widget child;

  /// Shows [builder]'s content in a drawer over the kit scrim, on the root
  /// navigator, and resolves with the value its root page pops (null when it
  /// is dismissed without one).
  ///
  /// With [navigable] (the default) the content is the root page of a nested
  /// navigator: pages it pushes with `Navigator.of(context).push` open inside
  /// the drawer, Escape and the platform back go back one page at a time, and
  /// popping the root page closes the drawer with its result. A tap on the
  /// scrim closes the whole stack: the pages above the root are dropped and
  /// the root page is asked to pop, so a root page that answers its own pop
  /// (a `PopScope` that pops with a "changed" flag) still delivers its result.
  /// Navigable content brings its own header, so [showClose] defaults to false
  /// there; [label] names the drawer.
  ///
  /// [dismissible] false keeps the drawer open against the scrim, the close
  /// control, and Escape or back on the root page. Motion is skipped when the
  /// platform asks for reduced motion.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    bool titleHidden = false,
    String? label,
    FlareDrawerPlacement placement = FlareDrawerPlacement.end,
    double? width,
    bool dismissible = true,
    bool? showClose,
    bool navigable = true,
    required WidgetBuilder builder,
  }) {
    final scopes = flareOverlayScopes(context);
    final duration = flareReduceMotion(context)
        ? Duration.zero
        : FlareMotion.normal;
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: duration,
      pageBuilder: (routeContext, animation, _) => scopes(
        _FlareDrawerHost<T>(
          animation: animation,
          duration: duration,
          title: title,
          titleHidden: titleHidden,
          label: label,
          placement: placement,
          width: width,
          dismissible: dismissible,
          showClose: showClose ?? !navigable,
          navigable: navigable,
          builder: builder,
        ),
      ),
    );
  }

  /// Shows secondary content where it belongs on this layout: a page pushed
  /// onto the current navigator, or a drawer ([show]).
  ///
  /// [asPage] is the host's own layout fact — a single-pane window pushes
  /// pages — and wins when given; otherwise the phone form factor
  /// (`flareCapabilitiesOf(context).bottomSheet`) pushes a page and anything
  /// wider opens a drawer. Called from inside a navigable drawer it pushes the
  /// page onto that drawer's navigator instead of stacking a second drawer.
  static Future<T?> showAdaptive<T>(
    BuildContext context, {
    bool? asPage,
    String? title,
    bool titleHidden = false,
    String? label,
    FlareDrawerPlacement placement = FlareDrawerPlacement.end,
    double? width,
    bool dismissible = true,
    bool? showClose,
    bool navigable = true,
    required WidgetBuilder builder,
  }) {
    final enclosing = _FlareDrawerScope.maybeOf(context);
    final nested = enclosing?.navigatorKey.currentState;
    if (nested != null) {
      return nested.push<T>(MaterialPageRoute<T>(builder: builder));
    }
    if (asPage ?? flareCapabilitiesOf(context).bottomSheet) {
      return Navigator.of(
        context,
      ).push<T>(MaterialPageRoute<T>(builder: builder));
    }
    return show<T>(
      context,
      title: title,
      titleHidden: titleHidden,
      label: label,
      placement: placement,
      width: width,
      dismissible: dismissible,
      showClose: showClose,
      navigable: navigable,
      builder: builder,
    );
  }

  void _requestDismiss(BuildContext context) {
    final override = _FlareDrawerDismissOverride.maybeOf(context);
    if (override != null) {
      override();
      return;
    }
    if (!dismissible) return;
    if (showBack) {
      onBack?.call();
      return;
    }
    _close(context);
  }

  void _close(BuildContext context) {
    final onClose = this.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final title = this.title;
    final named = title != null && title.isNotEmpty;
    final visibleTitle = named && !titleHidden ? title : null;
    final name = named ? title : (label ?? strings.drawerLabel);
    final hasHeader =
        visibleTitle != null || actions.isNotEmpty || showClose || showBack;
    final panelWidth = math.min(
      width ?? FlareSizes.componentSheetWidth,
      math.max(0.0, media.size.width - FlareSizes.touchTarget),
    );
    final end = placement == FlareDrawerPlacement.end;
    const corner = Radius.circular(FlareSizes.radiusXl);
    final footer = this.footer;

    Widget panel = Container(
      width: panelWidth,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: end
            ? const BorderRadiusDirectional.horizontal(start: corner)
            : const BorderRadiusDirectional.horizontal(end: corner),
        boxShadow: flareOverlayShadow(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: FlareOverlaySurface(
          kind: FlareOverlayKind.drawer,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasHeader)
                  FlareOverlayHeader(
                    title: visibleTitle,
                    actions: actions,
                    showClose: showClose,
                    closeEnabled: dismissible,
                    onClose: () => _close(context),
                    onBack: showBack ? () => onBack?.call() : null,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      showBack ? FlareSizes.spacingXs : FlareSizes.spacingLg,
                      FlareSizes.spacingSm,
                      FlareSizes.spacingSm,
                      FlareSizes.spacingSm,
                    ),
                  ),
                Expanded(child: child),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );

    final animation = _FlareDrawerRouteAnimation.maybeOf(context);
    if (animation != null) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final fromRight = end != rtl;
      panel = SlideTransition(
        position:
            Tween<Offset>(
              begin: Offset(fromRight ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: FlareMotion.normalCurve,
              ),
            ),
        child: panel,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestDismiss(context);
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape):
              _FlareDrawerDismissIntent(),
        },
        child: Actions(
          actions: {
            _FlareDrawerDismissIntent:
                CallbackAction<_FlareDrawerDismissIntent>(
                  onInvoke: (_) {
                    _requestDismiss(context);
                    return null;
                  },
                ),
          },
          child: Align(
            alignment: end
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              namesRoute: visibleTitle == null ? true : null,
              label: visibleTitle == null ? name : null,
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlareDrawerDismissIntent extends Intent {
  const _FlareDrawerDismissIntent();
}

/// Escape and the platform back on a drawer that [FlareDrawer.show] hosts go
/// to the host (one page back in its navigator), not to the frame's own
/// close / back rule.
class _FlareDrawerDismissOverride extends InheritedWidget {
  const _FlareDrawerDismissOverride({
    required this.onDismissRequest,
    required super.child,
  });

  final VoidCallback onDismissRequest;

  static VoidCallback? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<_FlareDrawerDismissOverride>()
      ?.onDismissRequest;

  @override
  bool updateShouldNotify(_FlareDrawerDismissOverride oldWidget) =>
      onDismissRequest != oldWidget.onDismissRequest;
}

/// The presenting route's animation, which slides the panel (not the whole
/// window) in from its edge.
class _FlareDrawerRouteAnimation extends InheritedWidget {
  const _FlareDrawerRouteAnimation({
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_FlareDrawerRouteAnimation>()
      ?.animation;

  @override
  bool updateShouldNotify(_FlareDrawerRouteAnimation oldWidget) =>
      animation != oldWidget.animation;
}

/// Lets [FlareDrawer.showAdaptive] find the navigable drawer it is called
/// from, to push onto its navigator.
class _FlareDrawerScope extends InheritedWidget {
  const _FlareDrawerScope({required this.navigatorKey, required super.child});

  final GlobalKey<NavigatorState> navigatorKey;

  static _FlareDrawerScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_FlareDrawerScope>();

  @override
  bool updateShouldNotify(_FlareDrawerScope oldWidget) =>
      navigatorKey != oldWidget.navigatorKey;
}

/// What [FlareDrawer.show] puts on its route: the scrim, the panel, and — for
/// navigable content — the nested navigator whose root page is the content.
class _FlareDrawerHost<T> extends StatefulWidget {
  const _FlareDrawerHost({
    super.key,
    required this.animation,
    required this.duration,
    required this.title,
    required this.titleHidden,
    required this.label,
    required this.placement,
    required this.width,
    required this.dismissible,
    required this.showClose,
    required this.navigable,
    required this.builder,
  });

  final Animation<double> animation;
  final Duration duration;
  final String? title;
  final bool titleHidden;
  final String? label;
  final FlareDrawerPlacement placement;
  final double? width;
  final bool dismissible;
  final bool showClose;
  final bool navigable;
  final WidgetBuilder builder;

  @override
  State<_FlareDrawerHost<T>> createState() => _FlareDrawerHostState<T>();
}

class _FlareDrawerHostState<T> extends State<_FlareDrawerHost<T>> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// Under the root page, so popping the root page is an ordinary pop the
  /// page's own PopScope can answer; never shown.
  late final Route<void> _base = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  /// The content. It is on screen from the drawer's first frame (an initial
  /// route, not a push after the first frame), and it stays drawn while the
  /// drawer slides out after it popped.
  late final Route<T> _page = PageRouteBuilder<T>(
    pageBuilder: (pageContext, _, _) => widget.builder(pageContext),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.navigable) _page.popped.then(_closeOuter);
  }

  /// Closes the drawer's own route with [result] — unless it is gone already
  /// (a host `popUntil` may have removed it) — without popping whatever may
  /// sit above it.
  void _closeOuter(T? result) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop(result);
    } else {
      navigator.removeRoute(route, result);
    }
  }

  /// Escape and the platform back: one page back inside the drawer; on the
  /// root page that closes the drawer, unless it is not dismissible.
  void _back() {
    if (!widget.navigable) {
      if (widget.dismissible) _closeOuter(null);
      return;
    }
    final nested = _navigatorKey.currentState;
    if (nested == null) return;
    if (_page.isCurrent && !widget.dismissible) return;
    nested.maybePop();
  }

  /// The scrim and the close control: drop every page above the root, then
  /// ask the root page to pop so its own result survives.
  void _closeAll() {
    if (!widget.dismissible) return;
    if (!widget.navigable) {
      _closeOuter(null);
      return;
    }
    final nested = _navigatorKey.currentState;
    if (nested == null) return;
    if (!_page.isActive) {
      _closeOuter(null);
      return;
    }
    nested.popUntil((route) => route == _page);
    nested.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final content = widget.navigable
        ? _FlareDrawerScope(
            navigatorKey: _navigatorKey,
            child: Navigator(
              key: _navigatorKey,
              onGenerateInitialRoutes: (_, _) => [_base, _page],
            ),
          )
        : Builder(builder: widget.builder);
    return _FlareDrawerRouteAnimation(
      animation: widget.animation,
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: widget.animation,
              child: widget.dismissible
                  ? Semantics(
                      label: MaterialLocalizations.of(
                        context,
                      ).modalBarrierDismissLabel,
                      button: true,
                      onTap: _closeAll,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeAll,
                        child: ColoredBox(color: colors.scrim),
                      ),
                    )
                  : ExcludeSemantics(child: ColoredBox(color: colors.scrim)),
            ),
          ),
          _FlareDrawerDismissOverride(
            onDismissRequest: _back,
            child: Focus(
              autofocus: true,
              skipTraversal: true,
              child: FlareDrawer(
                title: widget.title,
                titleHidden: widget.titleHidden,
                label: widget.label,
                placement: widget.placement,
                width: widget.width,
                dismissible: widget.dismissible,
                showClose: widget.showClose,
                onClose: _closeAll,
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
