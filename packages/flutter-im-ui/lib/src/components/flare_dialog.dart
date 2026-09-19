import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_input.dart';

/// Shared dialog surface. Present it with [FlareDialog.show], which owns the
/// route, barrier, focus trapping and back navigation. Contents and actions
/// are composed kit controls; business callbacks stay outside.
class FlareDialog extends StatelessWidget {
  const FlareDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.busy = false,
  });
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final bool busy;

  /// Shows what [builder] returns — a [FlareDialog], or another self-contained
  /// kit card, which gets the Material ancestor its fields need — as a modal
  /// dialog and resolves with the value it pops (null when dismissed).
  /// [dismissible] false blocks the barrier and the back gesture. Motion is
  /// skipped when the platform asks for reduced motion.
  static Future<T?> show<T>(
    BuildContext context, {
    bool dismissible = true,
    required WidgetBuilder builder,
  }) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      animationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
      builder: (_) => PopScope(
        canPop: dismissible,
        child: Material(
          type: MaterialType.transparency,
          child: Builder(builder: builder),
        ),
      ),
    );
  }

  /// Asks for one value — a remark, a group name, a comment — in a dialog
  /// with a field, confirm and cancel. Resolves with the trimmed value once it
  /// is confirmed and [onSubmit], when given, has succeeded; null when
  /// cancelled or dismissed.
  ///
  /// While [onSubmit] runs the dialog is busy: the field and the buttons are
  /// disabled and neither the barrier nor back closes it. A failure keeps the
  /// dialog open with the error under the field and the draft as typed, so
  /// confirming again retries. Confirm waits for a non-blank value unless
  /// [allowEmpty] (clearing a remark, for example). [confirmText] and
  /// [cancelText] default to the strings table's 确定 and 取消.
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
    Future<void> Function(String value)? onSubmit,
  }) {
    return show<String>(
      context,
      builder: (_) => _FlarePrompt(
        title: title,
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return PopScope(
      canPop: !busy,
      child: Dialog(
        backgroundColor: colors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
          side: BorderSide(color: colors.borderPrimary),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeXl,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    child: title,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingLg),
                Flexible(
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeLg,
                        color: colors.textSecondary,
                      ),
                      child: content,
                    ),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: FlareSizes.spacingXl),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: FlareSizes.spacingSm,
                    runSpacing: FlareSizes.spacingSm,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dialog [FlareDialog.prompt] presents: it owns the draft, the busy state
/// while the host's submit runs, and the error that keeps the dialog open.
class _FlarePrompt extends StatefulWidget {
  const _FlarePrompt({
    required this.title,
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

  final String title;
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
      _busy = true;
      _error = null;
    });
    try {
      await submit(value);
      if (mounted) Navigator.of(context).pop(value);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
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
    return FlareDialog(
      busy: _busy,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null && message.isNotEmpty) ...[
            Text(message),
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
        ],
      ),
      actions: [
        FlareButton(
          label: widget.cancelText ?? strings.cancel,
          variant: FlareButtonVariant.text,
          size: FlareControlSize.lg,
          disabled: _busy,
          onPressed: () => Navigator.of(context).pop(),
        ),
        FlareButton(
          label: widget.confirmText ?? strings.confirm,
          size: FlareControlSize.lg,
          loading: _busy,
          disabled: !_canConfirm,
          onPressed: _confirm,
        ),
      ],
    );
  }
}
