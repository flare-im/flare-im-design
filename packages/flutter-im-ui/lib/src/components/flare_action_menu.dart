import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_bottom_sheet.dart';

/// One entry of a [FlareActionMenu], in the kit's action vocabulary — the
/// fields `FlareConversationHeaderAction` carries — so a header action and a
/// host's own menu entry describe themselves the same way.
/// Spec: General/ActionMenu (`FlareActionItem`).
@immutable
class FlareActionItem {
  const FlareActionItem({
    required this.id,
    required this.label,
    this.icon,
    this.group,
    this.visible = true,
    this.enabled = true,
    this.badge,
    this.accessibilityLabel,
    this.disabledReason,
    this.pressed,
    this.danger = false,
  });

  /// Stable id, reported when the item is selected.
  final String id;
  final String label;

  /// A semantic kit icon name (`search`, `share`, `delete` …), resolved through
  /// the same map as `FlareConversationHeaderAction.icon`. A name the map does
  /// not know draws no glyph.
  final String? icon;

  /// A separator is drawn where the group changes; hosts put destructive items
  /// in a group of their own.
  final String? group;

  /// False leaves the item out entirely, before grouping.
  final bool visible;

  /// False draws the item and announces it disabled; it never reports.
  final bool enabled;

  /// Compact trailing text, such as a count.
  final String? badge;

  /// Replaces [label] as the item's accessible name.
  final String? accessibilityLabel;

  /// Why a disabled item is disabled: its second line, read with it.
  final String? disabledReason;

  /// Non-null makes the item checkable: a trailing check when true, and the
  /// checked state exposed to assistive technology.
  final bool? pressed;

  /// Destructive: the label and icon use the error text colour.
  final bool danger;

  @override
  bool operator ==(Object other) =>
      other is FlareActionItem &&
      other.id == id &&
      other.label == label &&
      other.icon == icon &&
      other.group == group &&
      other.visible == visible &&
      other.enabled == enabled &&
      other.badge == badge &&
      other.accessibilityLabel == accessibilityLabel &&
      other.disabledReason == disabledReason &&
      other.pressed == pressed &&
      other.danger == danger;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    icon,
    group,
    visible,
    enabled,
    badge,
    accessibilityLabel,
    disabledReason,
    pressed,
    danger,
  );
}

/// How a [FlareActionMenu] appears. [auto] is the kit bottom sheet, titled with
/// the menu's label, where the platform presents contextual layers as sheets
/// (`FlarePlatformCapabilities.bottomSheet`, phone form factors), and a menu
/// anchored to its trigger everywhere else. Without an installed platform
/// adapter, `FlarePlatformCapabilities.detect` decides from the window width.
enum FlareActionMenuPresentation { auto, anchored, sheet }

/// A small menu of actions — the "new", "add" and "more" menus of an IM app.
/// One item model, one grouping rule and one selection rule on every platform
/// (spec General/ActionMenu):
///
/// * host order is kept; a separator opens each new [FlareActionItem.group];
/// * selecting an enabled item closes the menu first, then reports its id; a
///   disabled item is shown and announced, and never reports;
/// * the menu is named by [label] and opens with focus on its first enabled
///   item; the arrow keys move between enabled items (Home and End jump);
///   Escape, system back or a tap outside close it and focus returns to the
///   trigger;
/// * a menu with no visible item never opens.
///
/// [builder] draws the trigger and wires `open` to it; code that opens a menu
/// on its own uses [show].
class FlareActionMenu extends StatelessWidget {
  const FlareActionMenu({
    super.key,
    required this.items,
    required this.label,
    required this.onSelected,
    required this.builder,
    this.presentation = FlareActionMenuPresentation.auto,
  });

  final List<FlareActionItem> items;

  /// The menu's accessible name, and the sheet title on phones.
  final String label;

  /// Receives the selected item's id once the menu has closed.
  final ValueChanged<String> onSelected;

  /// Builds the trigger; call `open` from its onPressed.
  final Widget Function(BuildContext context, VoidCallback open) builder;

  final FlareActionMenuPresentation presentation;

  /// Presents the menu and completes with the selected id, or null when dismissed.
  /// `anchor` is the trigger's global rect (anchored) and is ignored for a sheet.
  ///
  /// Without an `anchor` the menu anchors to [context]'s own box. When no item
  /// is visible nothing is shown and the future completes with null at once.
  /// The items are read once, when the menu opens.
  static Future<String?> show(
    BuildContext context, {
    required List<FlareActionItem> items,
    required String label,
    Rect? anchor,
    FlareActionMenuPresentation presentation = FlareActionMenuPresentation.auto,
  }) {
    final visible = [
      for (final item in items)
        if (item.visible) item,
    ];
    if (visible.isEmpty) return Future<String?>.value();
    final capabilities = _capabilitiesOf(context);
    final sheet = switch (presentation) {
      FlareActionMenuPresentation.sheet => true,
      FlareActionMenuPresentation.anchored => false,
      FlareActionMenuPresentation.auto => capabilities.bottomSheet,
    };
    // Routes are built under the navigator, above any FlareTheme the trigger
    // sits in: carry it over so the menu keeps the trigger's brand and mode.
    final flareTheme = FlareTheme.maybeOf(context);
    Widget themed(Widget child) => flareTheme == null
        ? child
        : FlareTheme(
            brand: flareTheme.brand,
            mode: flareTheme.mode,
            colors: flareTheme.colors,
            child: child,
          );
    // Opened from a key (Enter or Space on the trigger): the first item's
    // focus is drawn at once. Opened by a click it is drawn from the first key
    // press, as a browser's :focus-visible would.
    final byKeyboard = HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty;
    if (sheet) {
      return FlareBottomSheet.show<String>(
        context,
        title: label,
        builder: (_) => themed(
          _ActionMenuPanel(
            items: visible,
            label: label,
            sheet: true,
            touch: true,
            byKeyboard: byKeyboard,
          ),
        ),
      );
    }
    final navigator = Navigator.of(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push<String>(
      _ActionMenuRoute(
        anchor: _overlayRect(navigator, anchor ?? _globalRect(context)),
        barrierLabel: FlareStrings.of(context).close,
        reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
        builder: (_) => themes.wrap(
          themed(
            _ActionMenuPanel(
              items: visible,
              label: label,
              sheet: false,
              touch: capabilities.pointer != FlarePointerKind.fine,
              byKeyboard: byKeyboard,
            ),
          ),
        ),
      ),
    );
  }

  /// The installed adapter's capabilities; without one, the kit's detection
  /// applied to the real window width, which the fallback adapter cannot see.
  static FlarePlatformCapabilities _capabilitiesOf(BuildContext context) =>
      FlarePlatform.maybeOf(context)?.capabilities ??
      FlarePlatformCapabilities.detect(
        width: MediaQuery.maybeSizeOf(context)?.width,
      );

  static Rect? _globalRect(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// [global] in the coordinate space of the overlay the menu route draws in.
  static Rect? _overlayRect(NavigatorState navigator, Rect? global) {
    if (global == null) return null;
    final overlay = navigator.overlay?.context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return global;
    return Rect.fromPoints(
      overlay.globalToLocal(global.topLeft),
      overlay.globalToLocal(global.bottomRight),
    );
  }

  Future<void> _open(BuildContext context) async {
    final current = context.widget;
    final menu = current is FlareActionMenu ? current : this;
    final id = await show(
      context,
      items: menu.items,
      label: menu.label,
      anchor: _globalRect(context),
      presentation: menu.presentation,
    );
    if (id == null || !context.mounted) return;
    // The trigger may have rebuilt while the menu was open: report to the
    // handler it has now.
    final latest = context.widget;
    (latest is FlareActionMenu ? latest : menu).onSelected(id);
  }

  @override
  Widget build(BuildContext context) => builder(context, () => _open(context));
}

/// The anchored presentation: no scrim, closed by a tap outside, Escape or
/// system back; focus stays inside while it is open.
class _ActionMenuRoute extends PopupRoute<String> {
  _ActionMenuRoute({
    required this.anchor,
    required this.barrierLabel,
    required this.reduceMotion,
    required this.builder,
  }) : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  final Rect? anchor;
  final bool reduceMotion;
  final WidgetBuilder builder;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : FlareMotion.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return CustomSingleChildLayout(
      delegate: _AnchoredMenuLayout(
        anchor: anchor,
        safe: EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          math.max(padding.bottom, keyboard),
        ),
        textDirection: Directionality.of(context),
      ),
      child: Builder(builder: builder),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: animation.drive(CurveTween(curve: FlareMotion.fastCurve)),
    child: child,
  );
}

/// Places the menu at its trigger: aligned to the trigger's end edge, below it,
/// or above it when only there it fits; always inside the safe area.
class _AnchoredMenuLayout extends SingleChildLayoutDelegate {
  _AnchoredMenuLayout({
    required this.anchor,
    required this.safe,
    required this.textDirection,
  });

  final Rect? anchor;
  final EdgeInsets safe;
  final TextDirection textDirection;

  static const double _margin = FlareSizes.spacingSm;
  static const double _gap = FlareSizes.spacingXs;

  Rect _bounds(Size size) {
    final left = safe.left + _margin;
    final top = safe.top + _margin;
    return Rect.fromLTRB(
      left,
      top,
      math.max(left, size.width - safe.right - _margin),
      math.max(top, size.height - safe.bottom - _margin),
    );
  }

  static double _below(Rect bounds, Rect anchor) =>
      bounds.bottom - anchor.bottom - _gap;

  static double _above(Rect bounds, Rect anchor) =>
      anchor.top - _gap - bounds.top;

  static double _clamp(double value, double low, double high) =>
      value < low ? low : (value > high ? math.max(low, high) : value);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final bounds = _bounds(constraints.biggest);
    var height = bounds.height;
    final anchor = this.anchor;
    if (anchor != null) {
      final side = math.max(_below(bounds, anchor), _above(bounds, anchor));
      // Beside the trigger whenever a row fits there; over it otherwise.
      if (side >= FlareSizes.touchTarget) height = math.min(height, side);
    }
    return BoxConstraints.loose(Size(bounds.width, height));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bounds = _bounds(size);
    final anchor = this.anchor;
    if (anchor == null) {
      return Offset(
        _clamp(
          bounds.center.dx - childSize.width / 2,
          bounds.left,
          bounds.right - childSize.width,
        ),
        _clamp(
          bounds.center.dy - childSize.height / 2,
          bounds.top,
          bounds.bottom - childSize.height,
        ),
      );
    }
    final below = _below(bounds, anchor);
    final above = _above(bounds, anchor);
    final placeBelow =
        childSize.height <= below ||
        (childSize.height > above && below >= above);
    final x = textDirection == TextDirection.rtl
        ? anchor.left
        : anchor.right - childSize.width;
    final y = placeBelow
        ? anchor.bottom + _gap
        : anchor.top - _gap - childSize.height;
    return Offset(
      _clamp(x, bounds.left, bounds.right - childSize.width),
      _clamp(y, bounds.top, bounds.bottom - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_AnchoredMenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      safe != oldDelegate.safe ||
      textDirection != oldDelegate.textDirection;
}

/// The drawn menu, shared by both presentations: a named menu whose enabled
/// items take focus in turn, with a separator where the group changes.
class _ActionMenuPanel extends StatefulWidget {
  const _ActionMenuPanel({
    required this.items,
    required this.label,
    required this.sheet,
    required this.touch,
    required this.byKeyboard,
  });

  /// The visible items, in host order.
  final List<FlareActionItem> items;
  final String label;
  final bool sheet;

  /// Rows take the full touch target (always in a sheet).
  final bool touch;

  /// The menu was opened from a key, so focus is drawn from the start.
  final bool byKeyboard;

  @override
  State<_ActionMenuPanel> createState() => _ActionMenuPanelState();
}

class _ActionMenuPanelState extends State<_ActionMenuPanel> {
  /// Whether focus is drawn: from a keyboard open, or the first key press.
  late bool _keyboard = widget.byKeyboard;

  late final List<FocusNode> _nodes = [
    for (final item in widget.items)
      FocusNode(
        debugLabel: 'FlareActionMenu ${item.id}',
        canRequestFocus: item.enabled,
        skipTraversal: !item.enabled,
      ),
  ];

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  List<int> get _enabled => [
    for (var i = 0; i < widget.items.length; i++)
      if (widget.items[i].enabled) i,
  ];

  void _focus(int index, {required bool forward}) {
    final node = _nodes[index];
    node.requestFocus();
    final itemContext = node.context;
    if (itemContext == null) return;
    Scrollable.ensureVisible(
      itemContext,
      alignmentPolicy: forward
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  void _step(int delta) {
    final enabled = _enabled;
    if (enabled.isEmpty) return;
    final at = enabled.indexWhere((index) => _nodes[index].hasPrimaryFocus);
    final next = at < 0
        ? (delta > 0 ? 0 : enabled.length - 1)
        : (at + delta) % enabled.length;
    _focus(enabled[next], forward: delta > 0);
  }

  void _jump({required bool first}) {
    final enabled = _enabled;
    if (enabled.isEmpty) return;
    _focus(first ? enabled.first : enabled.last, forward: !first);
  }

  void _select(FlareActionItem item) {
    // A disabled item never reports; a menu already closing takes no second pick.
    if (!item.enabled || ModalRoute.isCurrentOf(context) == false) return;
    Navigator.of(context).pop(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final items = widget.items;
    final iconColumn = items.any((item) => flareActionIcon(item.icon) != null);
    final firstEnabled = items.indexWhere((item) => item.enabled);
    final entries = <Widget>[];
    String? group;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.group != null && item.group != group) {
        if (entries.isNotEmpty) {
          entries.add(_ActionMenuSeparator(sheet: widget.sheet));
        }
        group = item.group;
      }
      entries.add(
        _ActionMenuRow(
          item: item,
          focusNode: _nodes[i],
          autofocus: i == firstEnabled,
          iconColumn: iconColumn,
          sheet: widget.sheet,
          touch: widget.touch,
          showFocus: _keyboard,
          onSelect: () => _select(item),
        ),
      );
    }
    final menu = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.home): () =>
            _jump(first: true),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            _jump(first: false),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        // Sees every key an item receives, before the bindings above act on it.
        onKeyEvent: (_, event) {
          if (!_keyboard && event is KeyDownEvent) {
            setState(() => _keyboard = true);
          }
          return KeyEventResult.ignored;
        },
        child: Semantics(
          container: true,
          role: SemanticsRole.menu,
          // A sheet already scopes and names its route with its title.
          scopesRoute: widget.sheet ? null : true,
          namesRoute: widget.sheet ? null : true,
          explicitChildNodes: true,
          label: widget.label,
          child: SingleChildScrollView(
            padding: widget.sheet
                ? const EdgeInsets.only(bottom: FlareSizes.spacingSm)
                : const EdgeInsets.all(FlareSizes.spacingXs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: entries,
            ),
          ),
        ),
      ),
    );
    if (widget.sheet) return menu;
    final radius = BorderRadius.circular(FlareSizes.radiusLg);
    // 12em to 22em of the menu's own text, so the width follows text scaling.
    final em = MediaQuery.textScalerOf(context).scale(FlareSizes.fontSizeLg);
    return ConstrainedBox(
      // 内容定宽，只夹住两头。8em/20em = 14px 基准下的 112/280，与 Android / iOS / Vue
      // 同一组数；原来的 12em/22em 让两三个两字动作也撑出半屏宽。
      constraints: BoxConstraints(minWidth: 8 * em, maxWidth: 20 * em),
      child: IntrinsicWidth(
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bgElevated,
              border: Border.all(color: colors.borderPrimary),
              borderRadius: radius,
              boxShadow: FlareShadows.of(_brightnessOf(context)).lg,
            ),
            child: ClipRRect(borderRadius: radius, child: menu),
          ),
        ),
      ),
    );
  }

  /// The brightness [FlareColors.of] resolves for [context].
  static Brightness _brightnessOf(BuildContext context) {
    final mode = FlareTheme.maybeOf(context)?.mode ?? FlareThemeMode.system;
    return flareThemeIsDark(mode, systemDark: flareSystemDark(context)) ? Brightness.dark : Brightness.light;
  }
}

class _ActionMenuRow extends StatefulWidget {
  const _ActionMenuRow({
    required this.item,
    required this.focusNode,
    required this.autofocus,
    required this.iconColumn,
    required this.sheet,
    required this.touch,
    required this.showFocus,
    required this.onSelect,
  });

  final FlareActionItem item;
  final FocusNode focusNode;
  final bool autofocus;

  /// Some item in the menu has a glyph: keep the column so labels line up.
  final bool iconColumn;
  final bool sheet;
  final bool touch;

  /// The keyboard is in use: a focused row draws its ring.
  final bool showFocus;
  final VoidCallback onSelect;

  @override
  State<_ActionMenuRow> createState() => _ActionMenuRowState();
}

class _ActionMenuRowState extends State<_ActionMenuRow> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final item = widget.item;
    final enabled = item.enabled;
    final foreground = !enabled
        ? colors.textDisabled
        : item.danger
        ? colors.errorText
        : colors.textPrimary;
    final iconColor = !enabled
        ? colors.textDisabled
        : item.danger
        ? colors.errorText
        : colors.textSecondary;
    final glyph = flareActionIcon(item.icon);
    final reason = enabled || (item.disabledReason?.isEmpty ?? true)
        ? null
        : item.disabledReason;
    final badge = (item.badge?.isEmpty ?? true) ? null : item.badge;
    final name = item.accessibilityLabel ?? item.label;
    final ring = _focused && widget.showFocus ? colors.borderSelected : null;

    final content = Row(
      children: [
        if (widget.iconColumn) ...[
          SizedBox(
            width: FlareSizes.iconSizeMd,
            child: glyph == null
                ? null
                : Icon(glyph, size: FlareSizes.iconSizeMd, color: iconColor),
          ),
          const SizedBox(width: FlareSizes.spacingSm),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: FlareSizes.fontSizeLg,
                ),
              ),
              if (reason != null)
                Text(
                  reason,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: FlareSizes.spacingSm),
          Text(
            badge,
            style: TextStyle(
              color: enabled ? colors.textTertiary : colors.textDisabled,
              fontSize: FlareSizes.fontSizeSm,
            ),
          ),
        ],
        if (item.pressed == true) ...[
          const SizedBox(width: FlareSizes.spacingSm),
          Icon(
            Icons.check_rounded,
            size: FlareSizes.iconSizeMd,
            color: colors.primaryText,
          ),
        ],
      ],
    );

    return MergeSemantics(
      child: Semantics(
        role: item.pressed == null
            ? SemanticsRole.menuItem
            : SemanticsRole.menuItemCheckbox,
        button: true,
        enabled: enabled,
        checked: item.pressed,
        label: reason == null ? name : '$name\n$reason',
        value: badge,
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onSelect();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onSelect : null,
            onTapDown: enabled ? (_) => _press(true) : null,
            onTapUp: enabled ? (_) => _press(false) : null,
            onTapCancel: enabled ? () => _press(false) : null,
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.sheet || widget.touch
                      ? FlareSizes.touchTarget
                      : FlareSizes.touchTargetMin,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: enabled && (_hovered || _pressed)
                        ? colors.bgHover
                        : null,
                    borderRadius: widget.sheet
                        ? null
                        : BorderRadius.circular(FlareSizes.radiusMd),
                    border: ring == null
                        ? null
                        : Border.all(color: ring, width: 2),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.sheet
                          ? FlareSizes.spacingLg
                          : FlareSizes.spacingMd,
                      vertical: FlareSizes.spacingXs,
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionMenuSeparator extends StatelessWidget {
  const _ActionMenuSeparator({required this.sheet});

  final bool sheet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: FlareSizes.spacingXs,
        horizontal: sheet ? FlareSizes.spacingLg : FlareSizes.spacingSm,
      ),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: FlareColors.of(context).borderPrimary),
      ),
    );
  }
}
