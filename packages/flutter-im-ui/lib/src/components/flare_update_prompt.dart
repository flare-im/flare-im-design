import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/directory_data.dart';
import '../models/update_prompt.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_modal.dart';
import 'flare_progress_bar.dart';
import 'flare_screen.dart';
import 'flare_storage_usage.dart' show formatBytes;

/// The update prompt: the SDK's update status in as plain values, the kit's
/// words, progress and actions out, and every action back to the host. Spec:
/// Feedback/UpdatePrompt (`FlareUpdatePrompt`).
///
/// What shows when is [flareUpdatePrompt]'s call
/// (`spec/update-prompt-vectors.json`, the same in every kit). The widget holds
/// no SDK and never closes itself. An action is drawn only when the host passes
/// its handler. The title and the message are announced when they change,
/// politely, or assertively on a forced prompt; the percent is not re-announced.
///
/// This is the prompt's content: in the fullscreen form it brings its own
/// [FlareScreen] page. Put it on screen with [FlareUpdatePromptPresenter].
class FlareUpdatePrompt extends StatefulWidget {
  const FlareUpdatePrompt({
    super.key,
    required this.form,
    this.version,
    this.notes = const [],
    this.reason,
    this.sizeBytes,
    this.mandatory = false,
    this.state,
    this.progress,
    this.errorCode,
    this.retryable = true,
    this.fallbackTarget = FlareUpdateFallbackTarget.website,
    this.canContinueReadOnly = false,
    this.onUpdate,
    this.onLater,
    this.onSkip,
    this.onRetry,
    this.onFallback,
    this.onContinueReadOnly,
  });

  /// `UpdateStatus.prompt`.
  final FlareUpdatePromptForm form;

  /// `UpdateStatus.release?.version`; blank draws no version line.
  final String? version;

  /// `UpdateStatus.release.notes`, already in the reader's language.
  final List<String> notes;

  /// `UpdateStatus.blockReason`, already in the reader's language: a forced
  /// offer says it in place of its fixed words.
  final String? reason;

  /// `UpdateStatus.release.sizeBytes`; null on a store update.
  final int? sizeBytes;

  /// `UpdateStatus.release.mandatory`: nothing here can postpone it.
  final bool mandatory;

  /// `UpdateStatus.state`.
  final String? state;

  /// `UpdateStatus.progress`, as it arrives.
  final FlareUpdateProgress? progress;

  /// `UpdateStatus.error.code`.
  final String? errorCode;

  /// `UpdateStatus.error.retryable`.
  final bool retryable;

  /// Where the fallback goes: the website on a direct install, the app store
  /// otherwise.
  final FlareUpdateFallbackTarget fallbackTarget;

  /// A forced prompt may step aside into read-only browsing.
  final bool canContinueReadOnly;

  /// Update now, continue on a metered network, or restart to finish.
  final VoidCallback? onUpdate;

  /// Put it off, or send the download to the background. The scrim, the swipe
  /// and platform back ask for this too.
  final VoidCallback? onLater;

  /// Skip this version (`update.skip`).
  final VoidCallback? onSkip;

  /// Try the failed step again.
  final VoidCallback? onRetry;

  /// Open the website or the app store.
  final VoidCallback? onFallback;

  /// Step aside into read-only browsing.
  final VoidCallback? onContinueReadOnly;

  FlareUpdatePromptModel get _model => flareUpdatePrompt(
    form: form,
    mandatory: mandatory,
    state: state,
    progress: progress,
    errorCode: errorCode,
    retryable: retryable,
    sizeBytes: sizeBytes,
    canContinueReadOnly: canContinueReadOnly,
    reason: reason,
  );

  /// Whether the scrim, the swipe and platform back may ask for later.
  bool get dismissible => _model.dismissible && onLater != null;

  VoidCallback? _handler(FlareUpdatePromptAction action) => switch (action) {
    FlareUpdatePromptAction.update ||
    FlareUpdatePromptAction.continueDownload ||
    FlareUpdatePromptAction.restart => onUpdate,
    FlareUpdatePromptAction.retry => onRetry,
    FlareUpdatePromptAction.fallback => onFallback,
    FlareUpdatePromptAction.later ||
    FlareUpdatePromptAction.background => onLater,
    FlareUpdatePromptAction.skip => onSkip,
    FlareUpdatePromptAction.continueReadOnly => onContinueReadOnly,
  };

  @override
  State<FlareUpdatePrompt> createState() => _FlareUpdatePromptState();
}

class _FlareUpdatePromptState extends State<FlareUpdatePrompt> {
  String? _announced;

  void _announce(String message, FlareUpdatePromptLive live) {
    if (message == _announced) return;
    _announced = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
        assertiveness: live == FlareUpdatePromptLive.assertive
            ? Assertiveness.assertive
            : Assertiveness.polite,
      );
    });
  }

  FlareButtonVariant _variant(FlareUpdatePromptAction action, int index) {
    if (index == 0) return FlareButtonVariant.primary;
    return action == FlareUpdatePromptAction.fallback ||
            action == FlareUpdatePromptAction.continueReadOnly
        ? FlareButtonVariant.secondary
        : FlareButtonVariant.quiet;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final model = widget._model;
    final size = formatBytes(widget.sizeBytes);
    final title = flareUpdateTitleLabel(model.title, strings);
    final message = model.message == null
        ? null
        : flareUpdateMessageLabel(
            model.message!,
            strings,
            size: size,
            reason: widget.reason,
          );
    _announce(message == null ? title : '$title $message', model.live);

    final version = flareUpdateVersionShown(widget.version)
        ? '${strings.updatePromptVersion} ${widget.version}'
        : null;
    final caption = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareTextRoles.caption.fontSize,
      height: FlareTextRoles.caption.lineHeight,
    );
    final body = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareTextRoles.body.fontSize,
      height: FlareTextRoles.body.lineHeight,
    );
    final bar = model.progress;
    final percent = bar?.percent;
    final received = formatBytes(widget.progress?.received);
    final total = formatBytes(widget.progress?.total);
    final progressText = percent == null
        ? null
        : received != null && total != null
        ? '$percent% · $received / $total'
        : '$percent%';
    final actions = [
      for (final action in model.actions)
        if (widget._handler(action) != null) action,
    ];

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FlareSizes.spacingLg,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FlareSizes.spacingXs,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeXl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (version != null)
              Text(size == null ? version : '$version · $size', style: caption),
          ],
        ),
        if (message != null) Text(message, style: body),
        if (bar != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FlareSizes.spacingXs,
            children: [
              FlareProgressBar(
                value: bar.value,
                indeterminate: bar.value == null,
                label: title,
              ),
              if (progressText != null) Text(progressText, style: caption),
            ],
          ),
        if (model.notes && widget.notes.isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FlareSizes.spacingXs,
            children: [
              Semantics(
                header: true,
                child: Text(
                  strings.updatePromptNotes,
                  style: body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final note in widget.notes) Text('• $note', style: body),
            ],
          ),
        if (actions.isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FlareSizes.spacingSm,
            children: [
              for (var i = 0; i < actions.length; i++)
                FlareButton(
                  key: ValueKey(actions[i]),
                  label: flareUpdateActionLabel(
                    actions[i],
                    strings,
                    fallbackTarget: widget.fallbackTarget,
                  ),
                  variant: _variant(actions[i], i),
                  size: FlareControlSize.lg,
                  block: true,
                  onPressed: widget._handler(actions[i]),
                ),
            ],
          ),
      ],
    );

    if (widget.form == FlareUpdatePromptForm.fullscreen) {
      return FlareScreen(
        surface: FlareScreenSurface.surface,
        padded: true,
        contentMaxWidth: FlareSizes.componentSheetDialogWidth,
        child: content,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: content,
    );
  }
}

/// Puts a [FlareUpdatePrompt] on screen while [open]: the kit's bottom sheet,
/// its modal, or a page over the whole window, by the prompt's form.
///
/// This is what Vue's `open` and SwiftUI's `isPresented` are on the other kits.
/// It goes under the app's `Navigator`, around a page: the route sits on the
/// root navigator, so the page it wraps does not matter. A new [prompt] updates
/// the open route in place; a different form replaces the route. The scrim, the
/// swipe and platform back call the prompt's `onLater` and leave the route up:
/// [open] stays the host's, and the host sets it false to close.
class FlareUpdatePromptPresenter extends StatefulWidget {
  const FlareUpdatePromptPresenter({
    super.key,
    required this.open,
    required this.prompt,
    required this.child,
  });

  final bool open;
  final FlareUpdatePrompt prompt;
  final Widget child;

  @override
  State<FlareUpdatePromptPresenter> createState() =>
      _FlareUpdatePromptPresenterState();
}

class _FlareUpdatePromptPresenterState
    extends State<FlareUpdatePromptPresenter> {
  late final ValueNotifier<FlareUpdatePrompt> _current = ValueNotifier(
    widget.prompt,
  );

  /// Always passed: a sheet that may close by drag pops past the guard below.
  final ValueNotifier<bool> _neverBusy = ValueNotifier(false);
  Route<dynamic>? _route;
  FlareUpdatePromptForm? _form;

  @override
  void initState() {
    super.initState();
    _afterFrame();
  }

  @override
  void didUpdateWidget(FlareUpdatePromptPresenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _afterFrame();
  }

  @override
  void dispose() {
    // The navigator cannot change while the tree is being finalized.
    final current = _current;
    final neverBusy = _neverBusy;
    final route = _route;
    _route = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeRoute(route);
      current.dispose();
      neverBusy.dispose();
    });
    super.dispose();
  }

  /// Routes change after the frame: the navigator cannot change during a build.
  void _afterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  void _sync() {
    _current.value = widget.prompt;
    if (!widget.open || _form != widget.prompt.form) {
      _closeRoute(_route);
      _route = null;
    }
    if (widget.open && _route == null) _show();
  }

  void _show() {
    final navigator = Navigator.of(context, rootNavigator: true);
    final prompt = widget.prompt;
    final title = flareUpdateTitleLabel(
      prompt._model.title,
      FlareStrings.of(context),
    );
    Widget live(BuildContext _) => ValueListenableBuilder<FlareUpdatePrompt>(
      valueListenable: _current,
      builder: (_, current, _) => _guarded(current),
    );
    final Future<void> gone = switch (prompt.form) {
      FlareUpdatePromptForm.sheet => FlareBottomSheet.show<void>(
        context,
        title: title,
        titleHidden: true,
        busy: _neverBusy,
        builder: live,
      ),
      FlareUpdatePromptForm.modal => FlareModal.show<void>(
        context,
        label: title,
        showClose: false,
        scrollable: false,
        builder: live,
      ),
      FlareUpdatePromptForm.fullscreen => FlareModal.show<void>(
        context,
        label: title,
        dismissible: false,
        framed: false,
        fullscreen: true,
        builder: live,
      ),
    };
    final route = _top(navigator);
    _route = route;
    _form = prompt.form;
    gone.whenComplete(() {
      if (identical(_route, route)) _route = null;
    });
  }

  /// The route the show call just pushed: nothing is popped, the walk stops at
  /// the top.
  Route<dynamic>? _top(NavigatorState navigator) {
    Route<dynamic>? top;
    navigator.popUntil((route) {
      top = route;
      return true;
    });
    return top;
  }

  void _closeRoute(Route<dynamic>? route) {
    if (route == null || !route.isActive) return;
    if (route.isCurrent) {
      route.navigator?.pop();
    } else {
      route.navigator?.removeRoute(route);
    }
  }

  /// The route never pops itself: the scrim, the swipe and platform back become
  /// `onLater`, and the host answers by closing.
  Widget _guarded(FlareUpdatePrompt prompt) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && prompt.dismissible) prompt.onLater?.call();
    },
    child: prompt,
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
