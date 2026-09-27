import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_overlay.dart';

/// A centered box over the kit scrim for a focused task — the centered form
/// of the overlay family. Spec: Overlay/Modal (`FlareModal`).
///
/// Header row: [title] … [actions] [close]; the title leads and names the
/// route, [label] names it when there is no visible title (falling back to
/// `FlareStrings.modalLabel`). The body scrolls inside the height cap unless
/// [scrollable] is false, which hands [child] bounded constraints and lets it
/// own its scrolling (lists, search results); a scrolling body is inset by the
/// page gutter, a non-scrolling one runs edge to edge. [footer] is the button
/// row: trailing on wide layouts, stacked full width (primary on top) on the
/// phone form factor.
///
/// While [busy], or when not [dismissible], every way of closing it — the
/// close control, the scrim, Escape and the platform back — is disabled.
///
/// The widget positions itself (centered, clear of the keyboard and the safe
/// areas), so a plain `showDialog(builder: (_) => FlareModal(...))` works too;
/// [FlareModal.show] owns the route, the token scrim and the motion.
///
/// FlareModal replaces the former `FlareDialog`: its `actions` became
/// [footer], `content` became [child], `maxWidth` became [width],
/// `contentScrollable` became [scrollable], `title` became a string, and
/// `FlareDialog.prompt` became `FlareBottomSheet.prompt`.
class FlareModal extends StatelessWidget {
  const FlareModal({
    super.key,
    this.title,
    this.titleHidden = false,
    this.label,
    this.width,
    this.maxHeight,
    this.fill = false,
    this.dismissible = true,
    this.showClose = true,
    this.busy = false,
    this.scrollable = true,
    this.onClose,
    this.actions = const [],
    this.footer = const [],
    required this.child,
  });

  /// The header, also the modal's accessible name.
  final String? title;

  /// Use [title] as the accessible name only, without drawing the heading.
  final bool titleHidden;

  /// The accessible name when there is no visible title.
  final String? label;

  /// Box width in logical pixels; defaults to
  /// [FlareSizes.componentSheetDialogWidth] and is clamped to the window minus
  /// twice [FlareSizes.spacingXl].
  final double? width;

  /// Height cap in logical pixels; defaults to 72% of the height left after the
  /// keyboard and the safe areas.
  final double? maxHeight;

  /// Take the whole [maxHeight] instead of fitting the content, so page-like
  /// content (global search) does not resize as results arrive.
  final bool fill;
  final bool dismissible;
  final bool showClose;
  final bool busy;
  final bool scrollable;

  /// Called by the close control; defaults to `Navigator.maybePop`.
  final VoidCallback? onClose;

  /// Controls at the header's trailing edge, before the close control.
  final List<Widget> actions;

  /// The button row under the body.
  final List<Widget> footer;
  final Widget child;

  /// Shows a modal over the kit scrim and resolves with the value it pops
  /// (null when dismissed). With [framed] (the default) the kit frames what
  /// [builder] returns in a FlareModal with the given header and footer; a
  /// builder that returns a [FlareModal] of its own — to hand its footer the
  /// route's context, or to drive [busy] — is shown as it is. [framed] false
  /// shows self-carded content (a kit card that brings its own surface) as it
  /// is, with the Material ancestor its fields need.
  ///
  /// [dismissible] false blocks the scrim, Escape and back. The route sits on
  /// the root navigator, so a modal opened inside a drawer covers the window.
  /// Motion is skipped when the platform asks for reduced motion.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    bool titleHidden = false,
    String? label,
    double? width,
    double? maxHeight,
    bool fill = false,
    bool dismissible = true,
    bool showClose = true,
    bool scrollable = true,
    List<Widget> actions = const [],
    List<Widget> footer = const [],
    bool framed = true,
    required WidgetBuilder builder,
  }) {
    final scopes = flareOverlayScopes(context);
    final colors = FlareColors.of(context);
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: dismissible,
      barrierColor: colors.scrim,
      animationStyle: flareReduceMotion(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (routeContext) {
        final content = builder(routeContext);
        final Widget body = !framed || content is FlareModal
            ? content
            : FlareModal(
                title: title,
                titleHidden: titleHidden,
                label: label,
                width: width,
                maxHeight: maxHeight,
                fill: fill,
                dismissible: dismissible,
                showClose: showClose,
                scrollable: scrollable,
                actions: actions,
                footer: footer,
                child: content,
              );
        return scopes(
          PopScope(
            canPop: dismissible,
            child: Material(type: MaterialType.transparency, child: body),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final locked = busy || !dismissible;
    final title = this.title;
    final visibleTitle = title != null && title.isNotEmpty && !titleHidden
        ? title
        : null;
    final name = (title != null && title.isNotEmpty)
        ? title
        : (label ?? strings.modalLabel);
    final gutter = media.size.width - 2 * FlareSizes.spacingXl;
    final boxWidth = math.min(
      width ?? FlareSizes.componentSheetDialogWidth,
      math.max(0.0, gutter),
    );
    final cap = maxHeight ?? flareOverlayDefaultMaxHeight(context);
    final hasHeader = visibleTitle != null || actions.isNotEmpty || showClose;

    final Widget body = scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              FlareSizes.spacingXl,
              hasHeader ? 0 : FlareSizes.spacingXl,
              FlareSizes.spacingXl,
              footer.isEmpty ? FlareSizes.spacingXl : 0,
            ),
            child: child,
          )
        : child;

    final surface = Container(
      width: boxWidth,
      height: fill ? cap : null,
      constraints: BoxConstraints(maxHeight: cap),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: flareOverlayShadow(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: FlareOverlaySurface(
          kind: FlareOverlayKind.modal,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: FlareSizes.fontSizeLg,
              color: colors.textSecondary,
            ),
            child: Column(
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasHeader)
                  FlareOverlayHeader(
                    title: visibleTitle,
                    actions: actions,
                    showClose: showClose,
                    closeEnabled: !locked,
                    onClose: onClose ?? () => Navigator.maybePop(context),
                    padding: EdgeInsetsDirectional.fromSTEB(
                      FlareSizes.spacingXl,
                      FlareSizes.spacingSm,
                      FlareSizes.spacingSm,
                      FlareSizes.spacingSm,
                    ),
                  ),
                if (fill) Expanded(child: body) else Flexible(child: body),
                if (footer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(FlareSizes.spacingXl),
                    child: _Footer(buttons: footer),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: !locked,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
          child: Center(
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              namesRoute: visibleTitle == null ? true : null,
              label: visibleTitle == null ? name : null,
              child: surface,
            ),
          ),
        ),
      ),
    );
  }
}

/// The footer's button row: trailing on wide layouts, stacked full width with
/// the primary (last) button on top on the phone form factor.
class _Footer extends StatelessWidget {
  const _Footer({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    if (flareCapabilitiesOf(context).bottomSheet) {
      final stacked = buttons.reversed.toList(growable: false);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stacked.length; i++) ...[
            if (i > 0) const SizedBox(height: FlareSizes.spacingSm),
            stacked[i],
          ],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: FlareSizes.spacingSm,
      runSpacing: FlareSizes.spacingSm,
      children: buttons,
    );
  }
}
