import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_input.dart';
import 'flare_modal.dart';
import 'flare_overlay.dart';

/// How a [FlareBottomSheet] appears (spec `presentation`).
enum FlareSheetPresentation {
  /// A bottom sheet on the phone form factor
  /// (`flareCapabilitiesOf(context).bottomSheet`); anywhere else the content
  /// is handed to a centered FlareModal. Resolved once when the sheet opens.
  auto,

  /// Always a bottom sheet.
  sheet,
}

/// Sheet content that draws its own header row (a title with Cancel, say).
///
/// On a [FlareBottomSheet] with `fill` whose child — or what
/// [FlareBottomSheet.show]'s builder returns — implements this, the sheet
/// keeps its title as the accessible name only, so the heading is not drawn
/// twice. `FlareLocationPicker` and `FlareContactPicker` implement it. Without
/// `fill` it changes nothing. Spec: BottomSheet notes ("Fill mode").
abstract interface class FlareSheetOwnHeader {}

/// The kit's surface for short, focused tasks — a confirm, a form, a picker,
/// a prompt. Spec: Overlay/BottomSheet (`FlareBottomSheet`).
///
/// On the phone form factor it is a bottom sheet: drag handle, optional
/// centered [title], [child] and the bottom safe area, lifted above the
/// keyboard. With [FlareSheetPresentation.auto] (the default) anywhere else it
/// hands the same content to a FlareModal — the centered form of the overlay
/// family — with the title leading and no close control, so hosts write one
/// sheet body for every form factor. Either way the surface caps its height at
/// [maxHeight] and hands [child] bounded loose constraints: the content owns
/// its scrolling.
///
/// Present it with [FlareBottomSheet.show], which owns the route, the scrim,
/// drag and dismissal, so hosts never build a sheet route of their own.
/// Long-lived secondary content belongs in FlareDrawer, not here.
///
/// With [fill] the surface takes its whole height cap and [child] fills what
/// is left under the handle (and the title) — content with its own header
/// that needs a definite height (a location or contact picker) goes straight
/// in, with no fixed-height wrapper; a child that is a [FlareSheetOwnHeader]
/// then keeps [title] as the accessible name only.
class FlareBottomSheet extends StatelessWidget {
  const FlareBottomSheet({
    super.key,
    this.title,
    this.titleHidden = false,
    this.maxHeight,
    this.presentation = FlareSheetPresentation.auto,
    this.fill = false,
    required this.child,
  });

  /// The header, also the surface's accessible name: centered on a sheet,
  /// leading when handed to a FlareModal.
  final String? title;

  /// Use [title] as the accessible name only, without drawing the heading
  /// (an action panel whose every row is already a whole action).
  final bool titleHidden;

  /// Height cap in logical pixels; defaults to 72% of the height left after
  /// the keyboard and the safe areas.
  final double? maxHeight;

  /// Sheet on the phone form factor and a FlareModal elsewhere (`auto`), or
  /// always a sheet. A FlareBottomSheet that [show] built keeps what [show]
  /// resolved when it opened.
  final FlareSheetPresentation presentation;

  /// Fixed-height mode: the surface takes its whole cap ([maxHeight], else
  /// 72% of the available height) and [child] fills the rest and owns its
  /// scrolling. Handed to a FlareModal it is the modal's `fill`.
  final bool fill;
  final Widget child;

  /// The child draws its own header: in fill mode the title is not drawn.
  bool get _contentOwnsHeader => fill && child is FlareSheetOwnHeader;
  bool get _headingHidden => titleHidden || _contentOwnsHeader;

  /// Shows what [builder] returns in a kit sheet and resolves with the value
  /// the sheet pops (null when dismissed).
  ///
  /// [presentation] [FlareSheetPresentation.auto] (the default) is resolved
  /// here, once: a bottom sheet on the phone form factor, a centered FlareModal
  /// elsewhere; it stays that way until the sheet closes.
  ///
  /// [dismissible] false blocks the scrim, drag, Escape and back for the whole
  /// life of the sheet. [busy] locks it live while an operation owns it: while
  /// the listenable is true, the scrim, Escape and back do nothing. A sheet
  /// that can become busy never closes by drag (Material's drag-to-close pops
  /// the route directly, past any pop guard), so the lock cannot be bypassed.
  ///
  /// The route sits on the root navigator, so a sheet opened from a page
  /// inside a FlareDrawer covers the window. Motion is skipped when the
  /// platform asks for reduced motion.
  ///
  /// [fill] makes the surface take its whole cap and hands what [builder]
  /// returns the rest of the height; when that widget is a
  /// [FlareSheetOwnHeader] the title is the accessible name only.
  ///
  /// [builder] runs once unless [listenable] is given: then it runs again
  /// every time [listenable] notifies, so content that takes changing host
  /// state — a picker's `sending` read from a `ValueNotifier` — stays current
  /// without a builder of the host's own around it. In fill mode the sheet
  /// looks at what each rebuild returns, so a [FlareSheetOwnHeader] keeps the
  /// title as the accessible name only. Pass the same notifier as [busy] to
  /// lock the sheet while it is true.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    bool titleHidden = false,
    bool dismissible = true,
    ValueListenable<bool>? busy,
    double? maxHeight,
    FlareSheetPresentation presentation = FlareSheetPresentation.auto,
    bool fill = false,
    Listenable? listenable,
    required WidgetBuilder builder,
  }) {
    final asModal =
        presentation == FlareSheetPresentation.auto &&
        !flareCapabilitiesOf(context).bottomSheet;
    final resolved = asModal
        ? FlareSheetPresentation.auto
        : FlareSheetPresentation.sheet;
    Widget sheet(Widget child) => FlareBottomSheet(
      title: title,
      titleHidden: titleHidden,
      maxHeight: maxHeight,
      presentation: resolved,
      fill: fill,
      child: child,
    );
    // In fill mode the sheet has to see the content itself to know whether
    // it brings its own header, so the builder runs just above the sheet.
    Widget content(BuildContext inner) =>
        fill ? sheet(builder(inner)) : sheet(Builder(builder: builder));
    Widget frame(BuildContext routeContext) => FlareSheetResolution(
      asModal: asModal,
      dismissible: dismissible,
      busy: busy,
      child: listenable == null
          ? Builder(builder: content)
          : ListenableBuilder(
              listenable: listenable,
              builder: (inner, _) => content(inner),
            ),
    );
    if (asModal) {
      return FlareModal.show<T>(
        context,
        dismissible: dismissible,
        framed: false,
        builder: frame,
      );
    }
    final scopes = flareOverlayScopes(context);
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible && busy == null,
      backgroundColor: Colors.transparent,
      barrierColor: FlareColors.of(context).scrim,
      elevation: 0,
      constraints: const BoxConstraints(maxWidth: FlareSizes.bubbleMaxWidth),
      sheetAnimationStyle: flareReduceMotion(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (routeContext) => scopes(
        _PopGuard(
          dismissible: dismissible,
          busy: busy,
          child: frame(routeContext),
        ),
      ),
    );
  }

  /// Asks for one value — a remark, a group name, a comment — with a field,
  /// confirm and cancel, on the sheet surface (a FlareModal off the phone form
  /// factor). Resolves with the trimmed value once it is confirmed and
  /// [onSubmit], when given, has succeeded; null when cancelled or dismissed.
  ///
  /// While [onSubmit] runs the prompt is busy: the field and the buttons are
  /// disabled and neither the scrim, drag, Escape nor back closes it. A
  /// failure keeps it open with the error under the field and the draft as
  /// typed, so confirming again retries. Confirm waits for a non-blank value
  /// unless [allowEmpty] (clearing a remark, for example). [confirmText] and
  /// [cancelText] default to the strings table's confirm and cancel.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? message,
    String initialValue = '',
    String? placeholder,
    int? maxLength,
    bool multiline = false,
    bool allowEmpty = false,
    String? confirmText,
    String? cancelText,
    FlareSheetPresentation presentation = FlareSheetPresentation.auto,
    Future<void> Function(String value)? onSubmit,
  }) async {
    final busy = ValueNotifier<bool>(false);
    try {
      return await show<String>(
        context,
        title: title,
        busy: busy,
        presentation: presentation,
        builder: (_) => _FlarePrompt(
          busy: busy,
          message: message,
          initialValue: initialValue,
          placeholder: placeholder,
          maxLength: maxLength,
          multiline: multiline,
          allowEmpty: allowEmpty,
          confirmText: confirmText,
          cancelText: cancelText,
          onSubmit: onSubmit,
        ),
      );
    } finally {
      busy.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolution = FlareSheetResolution.maybeOf(context);
    final asModal =
        resolution?.asModal ??
        (presentation == FlareSheetPresentation.auto &&
            !flareCapabilitiesOf(context).bottomSheet);
    if (!asModal) return _sheet(context);
    final busy = resolution?.busy;
    final dismissible = resolution?.dismissible ?? true;
    final title = this.title;
    final headed = title != null && title.isNotEmpty && !_headingHidden;
    // Without a header row the content would start at the box's edge; the
    // sheet's handle gives it that room, so the Modal form keeps it.
    final body = headed
        ? child
        : Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingXl),
            child: child,
          );
    Widget modal(bool isBusy) => FlareModal(
      title: title,
      titleHidden: _headingHidden,
      maxHeight: maxHeight,
      fill: fill,
      dismissible: dismissible,
      busy: isBusy,
      showClose: false,
      scrollable: false,
      child: body,
    );
    if (busy == null) return modal(false);
    return ValueListenableBuilder<bool>(
      valueListenable: busy,
      builder: (_, isBusy, _) => modal(isBusy),
    );
  }

  Widget _sheet(BuildContext context) {
    final colors = FlareColors.of(context);
    final title = this.title;
    final named = title != null && title.isNotEmpty;
    final cap = maxHeight ?? flareOverlayDefaultMaxHeight(context);
    final headingHidden = _headingHidden;
    Widget frame = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FlareSizes.radius2xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          // Fill mode takes the whole cap (never more than the route allows).
          constraints: fill
              ? BoxConstraints.tightFor(height: cap)
              : BoxConstraints(maxHeight: cap),
          child: FlareOverlaySurface(
            kind: FlareOverlayKind.sheet,
            child: Column(
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: FlareSizes.spacingSm,
                    ),
                    width: FlareSizes.iconSizeXl,
                    height: FlareSizes.spacingXs,
                    decoration: BoxDecoration(
                      color: colors.borderHover,
                      borderRadius: BorderRadius.circular(
                        FlareSizes.radiusFull,
                      ),
                    ),
                  ),
                ),
                if (named && !headingHidden)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FlareSizes.spacingLg,
                      0,
                      FlareSizes.spacingLg,
                      FlareSizes.spacingSm,
                    ),
                    child: Semantics(
                      header: true,
                      namesRoute: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        // 面板名比它里面的每一行都轻一档 —— 说明这块界面「是什么」的那行字
                        // 不该盖过界面里的内容。iOS / Android / web 手机档都是 13/500/tertiary,
                        // 这份从前写的是 15/600/primary,同一个 prop 在四端落在两个层级上。
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeMd,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (fill) Expanded(child: child) else Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
    if (named && headingHidden) {
      frame = Semantics(
        container: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: title,
        child: frame,
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: frame,
    );
  }
}

/// Blocks the scrim, Escape and back while the sheet is not dismissible or
/// while the host's busy flag is up. Material routes the scrim through
/// `Navigator.maybePop`, so this guard holds for it too.
class _PopGuard extends StatelessWidget {
  const _PopGuard({
    required this.dismissible,
    required this.busy,
    required this.child,
  });

  final bool dismissible;
  final ValueListenable<bool>? busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final busy = this.busy;
    if (busy == null) return PopScope(canPop: dismissible, child: child);
    return ValueListenableBuilder<bool>(
      valueListenable: busy,
      builder: (_, isBusy, child) =>
          PopScope(canPop: dismissible && !isBusy, child: child!),
      child: child,
    );
  }
}

/// The body [FlareBottomSheet.prompt] presents: it owns the draft, the busy
/// state while the host's submit runs (mirrored into the sheet's lock), and
/// the error that keeps the prompt open.
class _FlarePrompt extends StatefulWidget {
  const _FlarePrompt({
    required this.busy,
    required this.message,
    required this.initialValue,
    required this.placeholder,
    required this.maxLength,
    required this.multiline,
    required this.allowEmpty,
    required this.confirmText,
    required this.cancelText,
    required this.onSubmit,
  });

  final ValueNotifier<bool> busy;
  final String? message;
  final String initialValue;
  final String? placeholder;
  final int? maxLength;
  final bool multiline;
  final bool allowEmpty;
  final String? confirmText;
  final String? cancelText;
  final Future<void> Function(String value)? onSubmit;

  @override
  State<_FlarePrompt> createState() => _FlarePromptState();
}

class _FlarePromptState extends State<_FlarePrompt> {
  late final _draft = TextEditingController(text: widget.initialValue)
    ..addListener(_onDraft);
  bool _busy = false;
  String? _error;

  bool get _canConfirm =>
      !_busy && (widget.allowEmpty || _draft.text.trim().isNotEmpty);

  void _onDraft() => setState(() {});

  void _setBusy(bool value) {
    _busy = value;
    widget.busy.value = value;
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    final value = _draft.text.trim();
    final submit = widget.onSubmit;
    if (submit == null) {
      Navigator.of(context).pop(value);
      return;
    }
    setState(() {
      _setBusy(true);
      _error = null;
    });
    try {
      await submit(value);
      if (!mounted) return;
      _setBusy(false);
      Navigator.of(context).pop(value);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _setBusy(false);
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final message = widget.message;
    final error = _error;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingXs,
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null && message.isNotEmpty) ...[
            Text(
              message,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeLg,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
          ],
          FlareInput(
            controller: _draft,
            placeholder: widget.placeholder,
            maxLength: widget.maxLength,
            multiline: widget.multiline,
            autofocus: true,
            disabled: _busy,
            onSubmitted: widget.multiline ? null : (_) => _confirm(),
          ),
          if (error != null) ...[
            const SizedBox(height: FlareSizes.spacingSm),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(
                  color: colors.errorText,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
          ],
          const SizedBox(height: FlareSizes.spacingLg),
          Row(
            children: [
              Expanded(
                child: FlareButton(
                  label: widget.cancelText ?? strings.cancel,
                  variant: FlareButtonVariant.secondary,
                  size: FlareControlSize.lg,
                  block: true,
                  disabled: _busy,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: FlareButton(
                  label: widget.confirmText ?? strings.confirm,
                  size: FlareControlSize.lg,
                  block: true,
                  loading: _busy,
                  disabled: !_canConfirm,
                  onPressed: _confirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
